import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/storage_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('Firebase.initializeApp failed: $e');
    debugPrintStack(stackTrace: st);
    // Add google-services.json (Android) and GoogleService-Info.plist (iOS)
    // from Firebase Console to enable Sign in with Google.
  }

  // Determine initial route before the app starts so the router never
  // briefly renders HomeScreen before redirecting.
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
  final initialRoute = onboardingCompleted ? '/' : '/onboarding';

  runApp(
    ProviderScope(
      child: MathLockApp(initialRoute: initialRoute),
    ),
  );
}
