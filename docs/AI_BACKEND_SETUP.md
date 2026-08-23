# AI Backend Setup (Production)

For production, prefer the Firebase Cloud Function so you do not ship a Gemini
API key in the client. On the free plan, use client-side Gemini keys.

## 1) Install Firebase CLI and login

```bash
npm i -g firebase-tools
firebase login
firebase use cashtrack-838b3
```

## 2) Install function dependencies

```bash
cd functions
npm install
cd ..
```

## 3) Set Gemini key on server

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

Paste your Gemini API key when prompted.

## 4) Deploy function

```bash
firebase deploy --only functions
```

## 5) Run app normally

For production builds, no client key is needed.
The app calls `generateAiResponse` Cloud Function.

## Free plan: direct client calls

On the free plan, use client calls and pass the Gemini key via `--dart-define`:

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=YOUR_KEY
```
