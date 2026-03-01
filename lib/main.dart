import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

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
  runApp(
    const ProviderScope(
      child: MathLockApp(),
    ),
  );
}
