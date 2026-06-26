# Google OAuth Configuration Guide for CashTrack

## Problem

You're seeing authentication errors like:

- ❌ `Error 401: invalid_client`
- ❌ `The OAuth client was not found`
- ❌ `Access blocked: Authorization Error`
- ❌ `popup_closed` on web

This happens because the **Web Client ID is not configured** in your project.

---

## Solution: Configure OAuth for Web

### Step 1: Get Your Web Client ID from Firebase Console

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Select your project: **cashtrack-c130b**

2. **Navigate to Project Settings**
   - Click the gear icon ⚙️ (top left, next to "Project Overview")
   - Select **"Project settings"**

3. **Find Your Web Client ID**
   - Go to the **"Service accounts"** tab
   - Select **"Node.js"** from the dropdown (or any SDK option)
   - Copy the entire contents - you're looking for this block:
     ```json
     "web": [
       {
         "client_id": "YOUR_CLIENT_ID_HERE.apps.googleusercontent.com",
         ...
       }
     ]
     ```

   **Alternative method:**
   - Still in Project Settings, go to **"Your apps"** section
   - You should see your web app listed
   - The Web Client ID will be visible there (format: `XXXXX.apps.googleusercontent.com`)

### Step 2: Update web/index.html

1. **Open the file**: `web/index.html`

2. **Find this line** (around line 24):

   ```html
   <meta
     name="google-signin-client_id"
     content="68532369864-YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
   />
   ```

3. **Replace `YOUR_WEB_CLIENT_ID`** with your actual Web Client ID

   **Example:**

   ```html
   <meta
     name="google-signin-client_id"
     content="68532369864-a1b2c3d4e5f6g7h8i9j0.apps.googleusercontent.com"
   />
   ```

### Step 3: Enable Google Sign-In in Firebase Console

1. **Go to Firebase Console** → Your Project
2. **Left sidebar** → **Build** → **Authentication**
3. **Click "Sign-in method"** tab
4. **Enable** "Google" if it's not already enabled
5. **Save** any changes

### Step 4: Configure OAuth Consent Screen (if needed)

If you haven't set this up yet:

1. **Go to Google Cloud Console**: https://console.cloud.google.com
2. **Select your project** (should auto-link to `cashtrack-c130b`)
3. **Left sidebar** → **APIs & Services** → **OAuth consent screen**
4. **Select user type**: Choose "External" (for now, you can change to "Internal" later)
5. **Fill in app information**:
   - App name: `CashTrack`
   - User support email: Your email
   - Developer contact: Your email
6. **Save and Continue**
7. **Leave scopes as default** (email, profile, openid)
8. **Add test users** (add your Gmail account for testing)
9. **Save**

### Step 5: Test on Web

1. **Stop the running Flutter web app** (if any)
2. **Clear browser cache** (Ctrl+Shift+Delete)
3. **Run the app**:
   ```bash
   flutter run -d chrome
   ```
4. **Try Google Sign-In** - you should now see the Google popup instead of an error

---

## Local Dev Origin Fix

When running with `flutter run -d chrome`, Flutter often uses a dynamic localhost origin such as:

- `http://127.0.0.1:57682`
- `http://localhost:57682`

If this origin is not added to the Google Cloud OAuth client, you will get `origin_mismatch`.

### Fix for local development

1. Open Google Cloud Console: https://console.cloud.google.com/apis/credentials
2. Select your project
3. Edit the OAuth 2.0 Client ID used by your web app
4. Add the exact browser origin to **Authorized JavaScript origins**

**Example entries:**

- `http://127.0.0.1:57682`
- `http://localhost:57682`
- `http://localhost:5000`

> Tip: Use a fixed port to avoid origin mismatch later:
>
> ```bash
> flutter run -d chrome --web-port 5000
> ```
>
> Then add `http://localhost:5000` to Authorized JavaScript origins.

---

## Platform-Specific Notes

### 🌐 Web (Most Important)

- **Requires**: Web Client ID in `web/index.html`
- **Uses**: Google Identity Services API
- **Fix**: Complete the steps above

### 📱 Android

- **Requires**: SHA-1 fingerprint configured in Firebase Console
- **Status**: Usually auto-configured via Firebase CLI
- **If still failing**:
  ```bash
  flutter run -d <android-device>
  ```
  Look for SHA-1 in the error message and add it to Firebase Console

### 🍎 iOS

- **Requires**: Bundle ID configured in Firebase Console
- **Status**: Usually auto-configured
- **If still failing**:
  ```bash
  flutter run -d <ios-device>
  ```

---

## Testing by Platform

### Test on Web:

```bash
flutter run -d chrome
```

### Test on Android:

```bash
flutter run -d <device-id>
```

### Test on iOS:

```bash
flutter run -d <device-id>
```

---

## Troubleshooting

### Still getting `invalid_client` error?

1. ✅ Did you **copy the full client ID** (with `.apps.googleusercontent.com`)?
2. ✅ Did you **save** `web/index.html`?
3. ✅ Did you **clear browser cache** and reload?
4. ✅ Is Google Sign-In **enabled** in Firebase Auth?

### Still getting `popup_closed` error?

- This means the popup closed before authentication completed
- Usually caused by the client ID being wrong or missing
- Follow the steps above to verify your client ID

### Getting OAuth consent screen errors?

- You need to configure the OAuth consent screen first
- Follow **Step 4** above
- Add your test email to the test users list

---

## How It Works (Technical Details)

1. **You configure** the Web Client ID in `web/index.html`
2. **Google Identity Services** library (loaded from `https://accounts.google.com/gsi/client`) reads this meta tag
3. **Your app** calls `AuthService().signInWithGoogle()`
4. **google_sign_in_web plugin** uses the configured client ID to open a popup
5. **User authenticates** with Google and grants permission
6. **Access token** is sent back to your Flutter app
7. **Firebase** verifies the token and signs the user in

---

## Quick Checklist

- [ ] Found Web Client ID in Firebase Console
- [ ] Updated `web/index.html` with the client ID
- [ ] Google Sign-In is enabled in Firebase Authentication
- [ ] OAuth consent screen is configured
- [ ] Added my test email as a test user (if External)
- [ ] Cleared browser cache
- [ ] Reloaded the app
- [ ] Google Sign-In works! ✅

---

## Still Having Issues?

Check the **browser console** (F12 → Console tab) for detailed error messages:

- `[GSI_LOGGER]: ... error` messages will show what Google Identity Services found
- Look for messages about `client_id` or `invalid_client`

**Common messages:**

- `google.accounts.id.initialize() is called multiple times` → Normal, can ignore
- `popup_closed` → User closed the popup or auth failed
- `invalid_client` → Client ID is wrong or missing

---

## For Production

When deploying to production:

1. Create a **new OAuth consent screen** user type as "Internal"
2. Remove test users
3. Make sure your deployed domain is authorized in Google Console
4. Update environment-specific configurations as needed

---

**Need more help?** Check:

- [Google Identity Services docs](https://developers.google.com/identity/gsi/web)
- [Firebase Authentication guide](https://firebase.google.com/docs/auth)
- [google_sign_in_web migration guide](https://pub.dev/packages/google_sign_in_web)
