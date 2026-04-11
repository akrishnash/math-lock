/// Configuration for Google Sign-In with Firebase Auth.
///
/// For sign-in to work on Android you must:
/// 1. Replace android/app/google-services.json with your real file from
///    Firebase Console (Project settings → Your apps → Android).
/// 2. In Firebase Console → Project settings → Your apps → Android app,
///    add your SHA-1 (and SHA-256). Get debug SHA-1 with:
///    keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
///    (password: android)
/// 3. Enable Google sign-in: Authentication → Sign-in method → Google → Enable.
/// 4. Set [webClientId] below to your Web client ID from Firebase Console:
///    Project settings → General → Your apps → Web app → Web API Key / Client ID,
///    or create a Web app and copy the OAuth 2.0 Client ID (type "Web application").
abstract final class AuthConfig {
  /// OAuth 2.0 Web client ID from Firebase (required for Android + Firebase Auth).
  /// Leave null only for iOS or if you use a different setup.
  static const String webClientId = '908300702285-27olq4ng7nuarpjg42mni5t2hsleemod.apps.googleusercontent.com';
}
