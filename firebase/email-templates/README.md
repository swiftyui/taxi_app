# HambaGo Firebase Authentication emails

Firebase Authentication email templates are configured in Firebase Console;
the Firebase CLI does not deploy them from `firebase.json`.

## Email address verification

1. Open **Firebase Console → Authentication → Templates**.
2. Select **Email address verification**.
3. Set the sender name to `HambaGo`.
4. Set the subject to `Verify your HambaGo email`.
5. Copy the complete contents of `verify-email.html` into the message editor.
6. Save the template and send a test verification email.

The template uses Firebase's `%EMAIL%`, `%LINK%`, and `%APP_NAME%`
placeholders. Do not replace `%LINK%` with a static URL.

For production, also configure a custom Authentication email domain in
Firebase so recipients see a HambaGo-owned sender and action-link domain
instead of `firebaseapp.com`.
