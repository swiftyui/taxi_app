# HambaGo

A new Flutter project.

## Firebase email templates

Branded Firebase Authentication templates and installation instructions are
kept in [`firebase/email-templates`](firebase/email-templates).

## Firestore features

Ride requests, driver accounts, and driver-created public routes use the
security rules in [`firestore.rules`](firestore.rules). Deploy these rules
before testing the features against the production Firebase project:

```sh
firebase deploy --only firestore:rules
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
