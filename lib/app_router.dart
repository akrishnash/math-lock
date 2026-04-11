import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/storage_keys.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/problems/problem_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/zen/app_picker_screen.dart';
import 'features/zen/home_screen.dart';
import 'features/zen/intervention_screen.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

GoRouter createRouter(WidgetRef ref, {String initialLocation = '/'}) {
  final authRefresh = _AuthRefreshNotifier();
  ref.listen(authStateProvider, (previous, next) => authRefresh.refresh());
  ref.listen(authSkippedProvider, (previous, next) => authRefresh.refresh());

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authRefresh,
    redirect: (context, state) async {
      final authAsync = ref.read(authStateProvider);
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
      final location = state.matchedLocation;
      final isLogin = location == '/login';
      final isOnboarding = location == '/onboarding';
      // Allow without auth: login, intervention, challenge, block; and / so home can
      // handle pending unlock intent before deciding where to send the user.
      final isAuthOptional = isLogin || location == '/' || location == '/intervention' || location == '/challenge' || location == '/block';
      return authAsync.when(
        data: (user) {
          if (!onboardingCompleted) {
            if (isOnboarding) return null;
            return '/onboarding';
          }
          if (isOnboarding) {
            return user == null ? '/login' : '/';
          }
          if (user != null) return null;
          if (isAuthOptional) return null;
          return '/login';
        },
        loading: () => (!onboardingCompleted && !isOnboarding) ? '/onboarding' : null,
        error: (error, stack) => (!onboardingCompleted && !isOnboarding) ? '/onboarding' : null,
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: '/app-picker',
        builder: (context, state) => const AppPickerScreen(),
      ),
      GoRoute(
        path: '/block',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final remaining = extra['remainingSeconds'];
          final reward = extra['rewardMinutes'];
          final timesUp = extra['timesUp'] == true;
          final args = InterventionScreenArgs(
            packageName: extra['packageName'] as String? ?? '',
            appLabel: extra['appLabel'] as String? ?? 'App',
            remainingSeconds: (remaining is int)
                ? remaining
                : (remaining is num ? remaining.toInt() : 0),
            rewardMinutes: (reward is int) ? reward : (reward is num ? reward.toInt() : 10),
            timesUp: timesUp,
          );
          return InterventionScreen(args: args);
        },
      ),
      GoRoute(
        path: '/intervention',
        builder: (context, state) {
          final args = state.extra as InterventionScreenArgs?;
          return InterventionScreen(args: args);
        },
      ),
      GoRoute(
        path: '/challenge',
        builder: (context, state) {
          final args = state.extra as ProblemScreenArgs?;
          return ProblemScreen(args: args);
        },
      ),
      GoRoute(
        path: '/problem',
        builder: (context, state) {
          final args = state.extra as ProblemScreenArgs?;
          return ProblemScreen(args: args);
        },
      ),
    ],
  );
}
