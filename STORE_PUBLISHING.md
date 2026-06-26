# Store Publishing Guide

This project is a Flutter app and can be published to both Google Play Store and Apple App Store.

## Current app identifiers in this repo

- Android package name: `com.cashtrack.app`
- iOS bundle identifier: currently `com.example.cashtrack`
- Android Firebase package in `android/app/google-services.json`: `com.cashtrack.app`
- iOS Firebase bundle in `ios/Runner/GoogleService-Info.plist`: `com.example.cashtrack`

> Important: The iOS bundle identifier currently uses the default placeholder. For App Store publishing, change the iOS bundle ID to your real App Store App ID and use a matching `GoogleService-Info.plist`.

---

## 1. Prepare app metadata and signing

### Android

1. Confirm `applicationId` in `android/app/build.gradle.kts`:
   - `applicationId = "com.cashtrack.app"`
2. Make sure `android/app/google-services.json` matches the Android package name.
3. Create a release keystore and `key.properties` if not already present.
   - `key.properties` should contain:
     ```properties
     storePassword=YOUR_STORE_PASSWORD
     keyPassword=YOUR_KEY_PASSWORD
     keyAlias=YOUR_KEY_ALIAS
     storeFile=YOUR_KEY_FILE.jks
     ```
4. Keep the keystore file private and do not commit it to Git.

### iOS

1. Choose a real bundle identifier in App Store Connect, e.g. `com.cashtrack.app` or another unique ID.
2. Open `ios/Runner.xcodeproj` in Xcode and set `PRODUCT_BUNDLE_IDENTIFIER` to that same ID.
3. Replace `ios/Runner/GoogleService-Info.plist` with a plist downloaded from Firebase for the selected iOS bundle id.
4. Confirm `ios/Runner/Info.plist` uses `$(PRODUCT_BUNDLE_IDENTIFIER)`.
5. If you use Google sign-in on iOS, confirm the Firebase iOS app is configured and the `GoogleService-Info.plist` file is present.

---

## 2. Build release artifacts

### Android

Build a signed Android App Bundle for Play Store:

```bash
flutter build appbundle --release
```

The output will be in:

- `build/app/outputs/bundle/release/app-release.aab`

If you want an APK for testing or internal use:

```bash
flutter build apk --release
```

### iOS

If you have a macOS machine with Xcode installed:

```bash
flutter build ipa --release
```

Or archive from Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select a Generic iOS Device.
3. Product → Archive.
4. Export the build for App Store Connect.

---

## 3. Upload to stores

### Google Play Store

1. Create a Google Play Developer account.
2. Create a new app in Google Play Console.
3. Upload `app-release.aab`.
4. Fill app listing, content rating, data safety, and pricing/distribution.
5. Opt-in to app signing if required.
6. Submit for review.

### Apple App Store

1. Create an Apple Developer account.
2. Register your app identifier in App Store Connect.
3. Create an App Store Connect app record.
4. Upload the `.ipa` via Xcode Organizer or Transporter.
5. Fill out app metadata, privacy policy, age rating, and app review information.
6. Submit for review.

---

## 4. Important checks before publishing

- Make sure the app does not use any debug-only or local configuration.
- Confirm Firebase and Google sign-in settings are correct for the release package / bundle identifiers.
- Clear any placeholder package names or placeholder App IDs.
- Verify privacy policy and terms-of-service URLs, because these are required for App Store and Play Store.
- Ensure `firebase_options.dart` or app config does not refer to a wrong app ID.

---

## 5. Recommended next steps for this repo

1. Update the iOS bundle identifier from `com.example.cashtrack` to the real App Store ID.
2. Download and add the iOS `GoogleService-Info.plist` for that bundle ID.
3. Keep Android release keystore and `key.properties` secure.
4. Build a release `.aab` and a release `.ipa` and test them on actual devices.
5. Create store listings and upload.

If you want, I can also add a small release checklist to `README.md` or help you set the iOS bundle identifier to a chosen App Store ID.
