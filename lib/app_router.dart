import 'package:go_router/go_router.dart';

import 'features/block_screen/block_screen.dart';
import 'features/problems/problem_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/zen/app_picker_screen.dart';
import 'features/zen/home_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
          return BlockScreen(
            packageName: extra['packageName'] as String? ?? '',
            appLabel: extra['appLabel'] as String? ?? 'App',
            remainingSeconds: (remaining is int)
                ? remaining
                : (remaining is num ? remaining.toInt() : 0),
            rewardMinutes: (reward is int) ? reward : (reward is num ? reward.toInt() : 10),
          );
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
