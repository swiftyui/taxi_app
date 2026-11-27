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
firebase deploy --only firestore:rules
```

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
