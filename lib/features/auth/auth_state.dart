import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import 'auth_service.dart';

/// Current Firebase auth user; null when not signed in.
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

/// True when the user tapped "Skip" on login and can use the app without signing in.
final authSkippedProvider =
    StateNotifierProvider<AuthSkippedNotifier, bool>((ref) {
  return AuthSkippedNotifier();
});

class AuthSkippedNotifier extends StateNotifier<bool> {
  AuthSkippedNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(StorageKeys.authSkipped) ?? false;
  }

  Future<void> setSkipped(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.authSkipped, value);
    state = value;
  }
}
