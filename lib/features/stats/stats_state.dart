import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

class StatsState {
  const StatsState({
    this.totalUnlockViaProblem = 0,
    this.todayCount = 0,
    this.thisWeekCount = 0,
    this.currentStreakDays = 0,
  });

  factory StatsState.fromHistory({
    required int totalUnlockViaProblem,
    required List<String> history,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final weekStart = reference.subtract(const Duration(days: 7));
    final solvedDays = <DateTime>{};
    var todayCount = 0;
    var thisWeek = 0;

    for (final raw in history) {
      final ms = int.tryParse(raw);
      if (ms == null) continue;
      final solvedAt = DateTime.fromMillisecondsSinceEpoch(ms);
      final solvedDay = DateTime(solvedAt.year, solvedAt.month, solvedAt.day);
      solvedDays.add(solvedDay);
      if (solvedDay == today) todayCount++;
      if (solvedAt.isAfter(weekStart)) thisWeek++;
    }

    var streak = 0;
    var cursor = solvedDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (solvedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StatsState(
      totalUnlockViaProblem: totalUnlockViaProblem,
      todayCount: todayCount,
      thisWeekCount: thisWeek,
      currentStreakDays: streak,
    );
  }

  final int totalUnlockViaProblem;
  final int todayCount;
  final int thisWeekCount;
  final int currentStreakDays;

  double get dailyAverageThisWeek => thisWeekCount / 7;
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier();
});

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier() : super(const StatsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt(StorageKeys.unlockViaProblemCount) ?? 0;
    final history =
        prefs.getStringList(StorageKeys.unlockViaProblemHistory) ?? [];
    state = StatsState.fromHistory(
      totalUnlockViaProblem: total,
      history: history,
    );
  }

  Future<void> recordUnlockViaProblem() async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(StorageKeys.unlockViaProblemCount) ?? 0) + 1;
    final history =
        prefs.getStringList(StorageKeys.unlockViaProblemHistory) ?? [];
    history.add(DateTime.now().millisecondsSinceEpoch.toString());
    while (history.length > 365) {
      history.removeAt(0);
    }
    await prefs.setInt(StorageKeys.unlockViaProblemCount, total);
    await prefs.setStringList(StorageKeys.unlockViaProblemHistory, history);
    state = StatsState.fromHistory(
      totalUnlockViaProblem: total,
      history: history,
    );
  }
}
