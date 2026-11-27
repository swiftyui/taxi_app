# HambaGo

A new Flutter project.

## Firebase email templates

Branded Firebase Authentication templates and installation instructions are
kept in [`firebase/email-templates`](firebase/email-templates).

## Firestore features

Ride requests, driver accounts, driver-created public routes, favourite
routes, saved places, and private emergency contacts use the security rules
in [`firestore.rules`](firestore.rules). Deploy these rules before testing the
features against the production Firebase project:

```sh
firebase deploy --project prod --only firestore:rules
```

## Local deployments

Run the release pipeline on a Mac with Python 3, Flutter, the Android SDK
and JDK, Xcode, CocoaPods, the Firebase CLI, and Fastlane. Use a build number
higher than the ones already uploaded for both apps. The version defaults
to `pubspec.yaml` and can be set with `--build-name`.

```sh
python3 scripts/release.py --build-number 7
python3 scripts/release.py --build-number 7 --build-only
python3 scripts/release.py --build-number 7 --deploy
```

The first command prints the plan. Build-only creates signed artifacts using
local signing. Deploy applies everything configured for the Firebase CLI in
`firebase.json` to `hambago-57327` and waits for Firebase to succeed before
starting both mobile build-and-upload jobs in parallel. The current Firebase
targets are Firestore and Storage rules. Add any Firebase CLI–managed indexes
or other services to `firebase.json` to deploy them with the same command.

The pipeline releases the current Git commit. Commit tracked changes before
building or deploying. The two builds use separate copies of that commit.
Artifacts and the Firebase CLI, build, and upload logs are saved under
`build/releases/`.

### Local signing and store access

- **Firebase**. Run `firebase login` with an account allowed to deploy to
  `hambago-57327`, or configure Firebase CLI application default credentials.
- **Android signing**. Restore `android/key.properties` with the app's
  registered upload keystore, or set `HAMBA_ANDROID_KEY_PROPERTIES` to your
  local properties file. Set `storeFile` to the absolute keystore path. The
  properties file also needs `storePassword`, `keyAlias`, and `keyPassword`.
- **Google Play**. Set `HAMBA_PLAY_JSON_KEY` to the path of a service account
  key with release access to the HambaGo app. The default destination is
  the internal testing track. Set `--play-track` to select another track or
  `--play-status draft` to leave the release as a draft. For a new app, make
  the first upload in Play Console before using the publishing API.
  [Google Play publishing prerequisites](https://developers.google.com/android-publisher/edits/)
- **iOS signing**. Set up the Runner team in Xcode and make its Apple
  Distribution signing identity and provisioning available locally.
- **App Store Connect**. Set `HAMBA_ASC_API_KEY_JSON` to a Fastlane App Store
  Connect API key JSON file with `key_id`, `issuer_id`, and the private PEM
  contents in `key`. The pipeline uploads the IPA for TestFlight processing
  on the existing App Store Connect app record.

Keep local keys, signing passwords, and credentials outside source control.
If one platform fails, the other continues and its artifacts and logs are
kept. After checking which upload succeeded, rerun the failed platform with
`--platform ios` or `--platform android`. The retry reapplies the Firebase
phase. For example, `python3 scripts/release.py --build-number 7 --deploy
--platform android` retries Android.

### Firebase Authentication templates

To deploy the checked-in verification HTML with a release, add
`--auth-template` and supply an OAuth access token with Identity Platform
configuration access. For example, with the Google Cloud CLI:

```sh
FIREBASE_AUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)" \
  python3 scripts/release.py --build-number 7 --deploy --auth-template
```

This updates the verification email's sender name, subject, format, and
body. The existing [console setup](firebase/email-templates) is available
for projects that manage the template there. Console-only settings and
unversioned Firebase resources need their own configuration.

## Maps and open map data

HambaGo draws an app-owned [street style](assets/map/hambago-streets.json)
with `flutter_map` and OpenFreeMap vector tiles based on OpenStreetMap data.
The map can fall back to standard OpenStreetMap tiles if the vector source
cannot be loaded. Map display, destination search, and reverse geocoding do
not require an API key. Map screens credit OpenStreetMap and OpenMapTiles.
Public map services and Nominatim are subject to their providers'
usage policies and availability.

Live destination suggestions use [Photon](https://photon.komoot.io/) for
OpenStreetMap place lookup in South Africa. The app waits briefly after typing,
caches repeated lookups, and displays local suggestions while the request runs.
When available, the app sends Photon a city-scale location bias to find nearby
places and uses the device's more precise fix to rank the results locally.
Build with `--dart-define=HAMBA_PHOTON_URL=https://your-photon-host/api/` to point
to your own [Photon instance](https://github.com/komoot/photon). The public
instance limits heavy use.

## Journey safety

The Safety Toolkit uses the native share sheet for current journey details and
location. SOS opens a prefilled message to the user's primary emergency
contact, and emergency calling opens the phone app with South Africa's `112`
number. Mobile operating systems always require the user to confirm sending a
message or placing a call.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
