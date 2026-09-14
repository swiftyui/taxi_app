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

## Google walking directions

Journey walking links use the Google Maps Routes API in `WALK` mode. Enable
the **Routes API** and billing for the same Google Cloud project as the Maps
SDK key configured by `googleMapsApiKey`. If Google cannot return a pedestrian
route, HambaGo keeps the connector as an explicitly labelled estimate.

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
