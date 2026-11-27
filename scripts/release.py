#!/usr/bin/env python3
"""Release the committed HambaGo source from a local Mac."""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
from urllib.error import HTTPError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
APP_ID = "com.vanzylarno.taxiApp"
EMAIL_TEMPLATE = Path("firebase/email-templates/verify-email.html")


class ReleaseError(Exception):
    pass


def options():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-number", required=True, type=int, help="unused store build number")
    parser.add_argument("--build-name", help="store version, defaults to pubspec.yaml")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--deploy", action="store_true", help="deploy Firebase and upload store builds")
    mode.add_argument("--build-only", action="store_true", help="create signed artifacts locally")
    parser.add_argument("--platform", choices=("both", "ios", "android"), default="both")
    parser.add_argument("--play-track", default="internal", help="Google Play track, default internal")
    parser.add_argument("--play-status", choices=("completed", "draft"), default="completed")
    parser.add_argument(
        "--auth-template",
        action="store_true",
        help="also deploy the verification email template using FIREBASE_AUTH_ACCESS_TOKEN",
    )
    args = parser.parse_args()
    if args.build_number <= 0:
        parser.error("--build-number must be positive")
    if args.auth_template and args.build_only:
        parser.error("--auth-template applies to Firebase deployment")
    return args


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def json_file(path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            return data
    except (OSError, ValueError):
        pass
    raise ReleaseError(f"Cannot read a JSON object from {path}.")


def firebase_project(source):
    config = json_file(source / "firebase.json")
    project = json_file(source / ".firebaserc")["projects"]["prod"]
    if not re.fullmatch(r"[a-z][a-z0-9-]+", project):
        raise ReleaseError("The Firebase prod alias must contain a project ID.")
    android = json_file(source / "android/app/google-services.json")
    with (source / "ios/Runner/GoogleService-Info.plist").open("rb") as file:
        ios = plistlib.load(file)
    platforms = config["flutter"]["platforms"]
    project_ids = (
        android["project_info"]["project_id"],
        ios["PROJECT_ID"],
        platforms["android"]["default"]["projectId"],
        platforms["ios"]["default"]["projectId"],
        platforms["dart"]["lib/firebase_options.dart"]["projectId"],
    )
    if any(value != project for value in project_ids):
        raise ReleaseError("The Firebase prod alias and mobile app configurations must agree.")
    dart_config = (source / "lib/firebase_options.dart").read_text(encoding="utf-8")
    if set(re.findall(r"""projectId:\s*['"]([^'"]+)['"]""", dart_config)) != {project}:
        raise ReleaseError("lib/firebase_options.dart must point to the Firebase prod project.")
    android_packages = [entry["client_info"]["android_client_info"]["package_name"]
                        for entry in android["client"]]
    if ios["BUNDLE_ID"] != APP_ID or APP_ID not in android_packages:
        raise ReleaseError(f"The mobile Firebase configs must include {APP_ID}.")

    for service in ("firestore", "storage", "database"):
        entries = config.get(service, [])
        for entry in entries if isinstance(entries, list) else [entries]:
            for key in ("rules", "indexes"):
                if key in entry and not (source / entry[key]).is_file():
                    raise ReleaseError(f"Missing Firebase {service} {key} file: {entry[key]}")
    return project


def release_version(source, args):
    if args.build_name:
        version = args.build_name
    else:
        pubspec = (source / "pubspec.yaml").read_text(encoding="utf-8")
        match = re.search(r"^version:\s*(\d+\.\d+\.\d+)(?:\+\d+)?\s*$", pubspec, re.M)
        if match is None:
            raise ReleaseError("Provide --build-name or set a version in pubspec.yaml.")
        version = match.group(1)
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ReleaseError("--build-name must have the form 1.0.0.")
    return version


def local_file(variable, default=None):
    value = os.environ.get(variable, default)
    if not value:
        raise ReleaseError(f"Set {variable} to a local file path.")
    path = Path(value).expanduser().resolve()
    if not path.is_file():
        raise ReleaseError(f"{variable} file does not exist: {path}")
    return path


def preflight(args, platforms):
    commands = ["flutter", "tar"]
    if "ios" in platforms:
        commands.extend(("xcodebuild", "pod"))
    if args.deploy:
        commands.extend(("firebase", "fastlane"))
    missing = [command for command in commands if not shutil.which(command)]
    if missing:
        raise ReleaseError("Missing local tools: " + ", ".join(missing))

    credentials = {}
    if "android" in platforms:
        credentials["signing"] = local_file(
            "HAMBA_ANDROID_KEY_PROPERTIES", ROOT / "android/key.properties"
        )
        if args.deploy:
            credentials["play"] = local_file("HAMBA_PLAY_JSON_KEY")
            key = json_file(credentials["play"])
            if key.get("type") != "service_account" or not key.get("private_key"):
                raise ReleaseError("HAMBA_PLAY_JSON_KEY must be a Google service account key.")
    if "ios" in platforms and args.deploy:
        credentials["apple"] = local_file("HAMBA_ASC_API_KEY_JSON")
        key = json_file(credentials["apple"])
        if not all(key.get(field) for field in ("key_id", "issuer_id", "key")):
            raise ReleaseError("HAMBA_ASC_API_KEY_JSON needs key_id, issuer_id, and key.")
    if args.auth_template and not os.environ.get("FIREBASE_AUTH_ACCESS_TOKEN"):
        raise ReleaseError("Set FIREBASE_AUTH_ACCESS_TOKEN to deploy the verification email template.")
    return credentials


def run_stage(name, command, cwd, output, env=None):
    log = output / f"{name}.log"
    print(f"Starting {name} ({log})", flush=True)
    with log.open("w", encoding="utf-8") as file:
        result = subprocess.run(
            command, cwd=cwd, env=env, stdin=subprocess.DEVNULL, stdout=file,
            stderr=subprocess.STDOUT,
        )
    if result.returncode:
        raise ReleaseError(f"{name} exited with status {result.returncode}. See {log}.")
    print(f"Finished {name}", flush=True)


def deploy_auth_template(project, source, access_token):
    template = {
        "senderDisplayName": "HambaGo",
        "subject": "Verify your HambaGo email",
        "body": (source / EMAIL_TEMPLATE).read_text(encoding="utf-8"),
        "bodyFormat": "HTML",
    }
    prefix = "notification.sendEmail.verifyEmailTemplate"
    mask = ",".join(f"{prefix}.{field}" for field in template)
    request = Request(
        f"https://identitytoolkit.googleapis.com/admin/v2/projects/{project}/config?updateMask={mask}",
        data=json.dumps({"notification": {"sendEmail": {"verifyEmailTemplate": template}}})
        .encode("utf-8"),
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "X-Goog-User-Project": project,
        },
        method="PATCH",
    )
    try:
        with urlopen(request, timeout=30):
            pass
    except HTTPError as error:
        raise ReleaseError(
            f"Firebase rejected the email template update (HTTP {error.code}). "
            "Check the token's Identity Platform permissions and template editing access."
        ) from None
    print("Finished Firebase verification email template", flush=True)


def extract_snapshot(archive, destination):
    destination.mkdir()
    subprocess.run(["tar", "-xf", str(archive), "-C", str(destination)], check=True)


def build_platform(platform, archive, scratch, output, version, args, credentials):
    source = scratch / platform
    extract_snapshot(archive, source)
    env = os.environ.copy()
    env.pop("FIREBASE_AUTH_ACCESS_TOKEN", None)
    env["FASTLANE_SKIP_UPDATE_CHECK"] = "1"
    env["FASTLANE_OPT_OUT_USAGE"] = "1"
    build_flags = ["--release", "--build-name", version, "--build-number", str(args.build_number)]

    if platform == "ios":
        export_options = source / "release-export.plist"
        with export_options.open("wb") as file:
            plistlib.dump({"method": "app-store-connect",
                           "manageAppVersionAndBuildNumber": False}, file)
        run_stage(
            "ios-build",
            ["flutter", "build", "ipa", *build_flags, "--export-options-plist", str(export_options)],
            source, output, env,
        )
        packages = list((source / "build/ios/ipa").glob("*.ipa"))
        if len(packages) != 1:
            raise ReleaseError(f"Expected one exported IPA, found {len(packages)}.")
        artifact = output / "HambaGo.ipa"
        shutil.copy2(packages[0], artifact)
        if args.deploy:
            run_stage(
                "ios-upload",
                ["fastlane", "pilot", "upload", "--ipa", str(artifact),
                 "--app_identifier", APP_ID, "--api_key_path", str(credentials["apple"]),
                 "--skip_submission", "true", "--skip_waiting_for_build_processing", "true"],
                source, output, env,
            )
    else:
        env["HAMBA_ANDROID_KEY_PROPERTIES"] = str(credentials["signing"])
        run_stage("android-build", ["flutter", "build", "appbundle", *build_flags], source, output, env)
        artifact = output / "HambaGo.aab"
        shutil.copy2(source / "build/app/outputs/bundle/release/app-release.aab", artifact)
        if args.deploy:
            run_stage(
                "android-upload",
                ["fastlane", "supply", "--aab", str(artifact), "--package_name", APP_ID,
                 "--json_key", str(credentials["play"]), "--track", args.play_track,
                 "--release_status", args.play_status, "--skip_upload_apk", "true",
                 "--skip_upload_metadata", "true", "--skip_upload_changelogs", "true",
                 "--skip_upload_images", "true", "--skip_upload_screenshots", "true"],
                source, output, env,
            )
    return artifact


def main():
    args = options()
    revision = git("rev-parse", "HEAD")
    platforms = ("ios", "android") if args.platform == "both" else (args.platform,)
    if not (args.deploy or args.build_only):
        print(f"Plan from the checkout at {revision[:12]}: "
              f"HambaGo {release_version(ROOT, args)}+{args.build_number}")
        print(f"1. Deploy all Firebase CLI targets from firebase.json to {firebase_project(ROOT)}.")
        if args.auth_template:
            print("   Apply the Firebase verification email template.")
        print(f"2. Build {', '.join(platforms)} from isolated snapshots and upload to the stores.")
        if "android" in platforms:
            print(f"   Google Play: {args.play_track} ({args.play_status}).")
        if "ios" in platforms:
            print("   App Store Connect: upload for TestFlight processing.")
        print("Use --build-only to build locally or --deploy to run this release.")
        return 0

    if git("status", "--porcelain", "--untracked-files=no"):
        raise ReleaseError("Commit tracked changes before releasing so Firebase and both builds use the same source.")
    credentials = preflight(args, platforms)
    with tempfile.TemporaryDirectory(prefix="hambago-release-") as temporary:
        scratch = Path(temporary)
        archive = scratch / "source.tar"
        git("archive", "--format=tar", f"--output={archive}", revision)
        source = scratch / "firebase"
        extract_snapshot(archive, source)
        project = firebase_project(source)
        version = release_version(source, args)
        if args.auth_template and not (source / EMAIL_TEMPLATE).is_file():
            raise ReleaseError(f"Missing Firebase verification email template: {EMAIL_TEMPLATE}")

        releases = ROOT / "build/releases"
        releases.mkdir(parents=True, exist_ok=True)
        output = Path(tempfile.mkdtemp(prefix=f"{version}+{args.build_number}-{revision[:8]}-", dir=releases))
        print(f"HambaGo {version}+{args.build_number} from {revision[:12]}", flush=True)
        print(f"Artifacts and logs: {output}", flush=True)
        if args.deploy:
            print(f"Deploying Firebase project {project}", flush=True)
            env = os.environ.copy()
            auth_token = env.pop("FIREBASE_AUTH_ACCESS_TOKEN", None)
            run_stage(
                "firebase", ["firebase", "deploy", "--project", project, "--non-interactive"],
                source, output, env,
            )
            if args.auth_template:
                deploy_auth_template(project, source, auth_token)

        failed = False
        with ThreadPoolExecutor(max_workers=len(platforms)) as executor:
            jobs = {
                executor.submit(build_platform, platform, archive, scratch, output,
                                version, args, credentials): platform
                for platform in platforms
            }
            for job in as_completed(jobs):
                platform = jobs[job]
                try:
                    print(f"{platform}: {job.result()}", flush=True)
                except (ReleaseError, OSError, subprocess.CalledProcessError) as error:
                    print(f"{platform} failed: {error}", file=sys.stderr, flush=True)
                    failed = True
        return int(failed)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ReleaseError, OSError, KeyError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Release stopped: {error}", file=sys.stderr)
        sys.exit(1)
