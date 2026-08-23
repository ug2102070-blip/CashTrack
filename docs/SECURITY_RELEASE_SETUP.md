# Security and release setup

## One-time secret rotation

1. Revoke the AI provider key that was previously embedded in the mobile client.
2. Create a new provider key with the smallest available quota and IP/API restrictions.
3. Store it only in Firebase Secret Manager:

   ```powershell
   firebase functions:secrets:set GROQ_API_KEY
   firebase deploy --only functions,firestore:rules,storage
   ```

4. Remove the exposed value from Git history before making the repository public. Rotation is mandatory even after history cleanup.
5. Change the Android signing-key passwords because they were present in the old example file. Keep the new `key.properties` and `.jks` files outside Git.

## Firebase App Check

Register every production app in Firebase Console > App Check before enabling this release:

- Android: Play Integrity
- iOS: DeviceCheck (or App Attest after validation)
- Web: reCAPTCHA v3

For a web build, provide the public reCAPTCHA v3 site key at build time:

```powershell
flutter build web --release --dart-define=FIREBASE_APP_CHECK_WEB_RECAPTCHA_SITE_KEY=YOUR_PUBLIC_SITE_KEY
```

The Cloud Function has `enforceAppCheck: true`; requests without a valid token are intentionally rejected. Observe App Check metrics before enforcing App Check on Firestore and Storage in Firebase Console.

## GitHub Actions signing secrets

Configure these repository secrets to enable the signed Android release job:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded release `.jks`
- `ANDROID_KEYSTORE_PROPERTIES`: the full contents of `android/key.properties`, with `storeFile=release.jks`

The job does not publish artifacts. Distribution remains a deliberate, separate release action.

## Sync schema v2 rollout

Release the app with sync schema v2 before removing legacy snapshot writes.
On the first signed-in sync, the app copies the old `app_data/snapshot` records
into per-entity documents and writes `users/{uid}/sync/meta`. Keep the legacy
snapshot rule temporarily for users on older versions; remove it only after the
minimum supported app version has adopted v2.
