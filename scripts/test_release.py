import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import release


STUB = """#!/usr/bin/env python3
import os
from pathlib import Path
import plistlib
import sys
import time

command = Path(sys.argv[0]).name
args = sys.argv[1:]
cwd = Path.cwd()
events = Path(os.environ["RELEASE_TEST_EVENTS"])
if command == "firebase":
    assert args == ["deploy", "--project", "hambago-57327", "--non-interactive"]
    assert (cwd / "firestore.rules").is_file()
    assert (cwd / "storage.rules").is_file()
    if os.environ.get("FAIL_FIREBASE"):
        sys.exit(23)
    (events / "firebase").touch()
elif command == "flutter":
    platform = "ios" if args[1] == "ipa" else "android"
    if os.environ.get("EXPECT_FIREBASE"):
        assert (events / "firebase").is_file()
    assert cwd.name == platform
    assert args[args.index("--build-number") + 1] == "7"
    (events / (platform + "-build")).touch()
    other = "android" if platform == "ios" else "ios"
    deadline = time.monotonic() + 5
    while not (events / (other + "-build")).exists():
        assert time.monotonic() < deadline, "builds did not run in parallel"
        time.sleep(.01)
    if platform == "ios":
        with Path(args[args.index("--export-options-plist") + 1]).open("rb") as file:
            assert plistlib.load(file)["manageAppVersionAndBuildNumber"] is False
        artifact = cwd / "build/ios/ipa/Runner.ipa"
    else:
        assert Path(os.environ["HAMBA_ANDROID_KEY_PROPERTIES"]).is_file()
        artifact = cwd / "build/app/outputs/bundle/release/app-release.aab"
    artifact.parent.mkdir(parents=True)
    artifact.write_text(platform)
elif command == "fastlane":
    assert (events / "firebase").is_file()
    if args[0] == "pilot":
        marker = "ios-upload"
        assert args[1] == "upload"
        assert args[args.index("--skip_submission") + 1] == "true"
        assert Path(args[args.index("--ipa") + 1]).is_file()
    else:
        marker = "android-upload"
        assert args[0] == "supply"
        assert args[args.index("--track") + 1] == "internal"
        assert Path(args[args.index("--aab") + 1]).is_file()
        if os.environ.get("FAIL_ANDROID_UPLOAD"):
            sys.exit(24)
    (events / marker).touch()
"""


class ReleaseTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        directory = Path(temporary.name)
        self.repository = directory / "repo"
        bin_dir = directory / "bin"
        self.events = directory / "events"
        self.repository.mkdir()
        bin_dir.mkdir()
        self.events.mkdir()
        folders = (
            ".firebaserc", "firebase.json", "firestore.rules", "storage.rules",
            "pubspec.yaml", "android/app/google-services.json",
            "ios/Runner/GoogleService-Info.plist", "lib/firebase_options.dart",
            "scripts/release.py",
        )
        for name in folders:
            destination = self.repository / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(release.ROOT / name, destination)
        self.git("init", "-q")
        self.git("add", ".")
        self.git("-c", "user.name=Release Test", "-c", "user.email=test@example.test",
                 "commit", "-qm", "Release fixtures")
        for executable in ("firebase", "flutter", "fastlane", "xcodebuild", "pod"):
            path = bin_dir / executable
            path.write_text(STUB, encoding="utf-8")
            path.chmod(0o755)
        signing = directory / "key.properties"
        signing.touch()
        play = directory / "play.json"
        play.write_text(json.dumps({"type": "service_account", "private_key": "fixture"}))
        apple = directory / "apple.json"
        apple.write_text(json.dumps({"key_id": "fixture", "issuer_id": "fixture", "key": "fixture"}))
        self.env = {
            **os.environ,
            "PATH": str(bin_dir) + os.pathsep + os.environ["PATH"],
            "RELEASE_TEST_EVENTS": str(self.events),
            "HAMBA_ANDROID_KEY_PROPERTIES": str(signing),
            "HAMBA_PLAY_JSON_KEY": str(play),
            "HAMBA_ASC_API_KEY_JSON": str(apple),
        }

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.repository, check=True, capture_output=True)

    def pipeline(self, *args, **env):
        return subprocess.run(
            [sys.executable, "scripts/release.py", "--build-number", "7", *args],
            cwd=self.repository, env={**self.env, **env}, capture_output=True, text=True,
            timeout=20,
        )

    def event_names(self):
        return {path.name for path in self.events.iterdir()}

    def test_plan_has_no_builds_or_deployments(self):
        result = self.pipeline()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hambago-57327", result.stdout)
        self.assertEqual(self.event_names(), set())
        self.assertFalse((self.repository / "build").exists())

    def test_deploys_firebase_before_both_parallel_builds_and_uploads(self):
        result = self.pipeline("--deploy", EXPECT_FIREBASE="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.event_names(), {
            "firebase", "ios-build", "android-build", "ios-upload", "android-upload",
        })

    def test_firebase_failure_stops_both_builds(self):
        result = self.pipeline("--deploy", EXPECT_FIREBASE="1", FAIL_FIREBASE="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("firebase exited with status 23", result.stderr)
        self.assertEqual(self.event_names(), set())

    def test_failed_upload_leaves_both_artifacts_and_other_upload_intact(self):
        result = self.pipeline("--deploy", EXPECT_FIREBASE="1", FAIL_ANDROID_UPLOAD="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("android-upload exited with status 24", result.stderr)
        self.assertIn("ios-upload", self.event_names())
        artifacts = self.repository / "build/releases"
        self.assertEqual(len(list(artifacts.glob("*/HambaGo.aab"))), 1)
        self.assertEqual(len(list(artifacts.glob("*/HambaGo.ipa"))), 1)

    def test_build_only_has_no_firebase_or_upload_stage(self):
        result = self.pipeline("--build-only", HAMBA_PLAY_JSON_KEY="", HAMBA_ASC_API_KEY_JSON="")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.event_names(), {"ios-build", "android-build"})

    def test_template_patch_is_scoped_to_verification_email(self):
        with patch.object(release, "urlopen") as request:
            release.deploy_auth_template("hambago-57327", release.ROOT, "fixture-token")
        call = request.call_args.args[0]
        self.assertEqual(call.method, "PATCH")
        self.assertIn("/projects/hambago-57327/config?updateMask=", call.full_url)
        mask = call.full_url.split("updateMask=", 1)[1].split(",")
        self.assertEqual({key.rsplit(".", 1)[0] for key in mask},
                         {"notification.sendEmail.verifyEmailTemplate"})
        payload = json.loads(call.data)["notification"]["sendEmail"]["verifyEmailTemplate"]
        self.assertIn("%LINK%", payload["body"])
        self.assertEqual(payload["bodyFormat"], "HTML")


if __name__ == "__main__":
    unittest.main()
