# Google Sign-In setup (Earn Your Screen)

If **Sign in with Google** fails or you're setting it up for the first time, complete these steps.

## 1. Firebase project and Android app

1. Go to [Firebase Console](https://console.firebase.google.com) and create or open a project.
2. Add an Android app with package name: **`com.earnyourscreen.app`**.
3. Download **google-services.json** and replace the file at:
   - **`android/app/google-services.json`** (overwrite the placeholder).

## 2. Add your SHA-1 to Firebase

Google Sign-In needs your app’s SHA-1 in Firebase.

**Debug SHA-1:**

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
```

Password: `android`

In Firebase: **Project settings → Your apps → Android app → Add fingerprint** → add both SHA-1 and SHA-256 from the keytool output.

## 3. Enable Google sign-in

In Firebase: **Authentication → Sign-in method → Google → Enable** and save.

## 4. Web client ID (required on Android)

1. In Firebase: **Project settings → General**.
2. Under **Your apps**, add a **Web app** if you don’t have one (nickname e.g. “Earn Your Screen Web”).
3. Copy the **Web client ID** (OAuth 2.0 Client ID, type “Web application”).
4. In the project, open **`lib/features/auth/auth_config.dart`** and set:

```dart
static const String? webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
```

Replace `YOUR_WEB_CLIENT_ID` with the value from Firebase (e.g. `123456789-xxxxx.apps.googleusercontent.com`).

## 5. Rebuild

```bash
flutter clean
flutter pub get
./scripts/build_install.sh
```

Then try **Sign in with Google** again. If it still fails, the error text on the login screen points to the missing step (SHA-1, Web client ID, or google-services.json).
