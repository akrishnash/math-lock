import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

class StatsState {
  const StatsState({
    this.totalUnlockViaProblem = 0,
    this.thisWeekCount = 0,
  });

  final int totalUnlockViaProblem;
  final int thisWeekCount;
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
    final history = prefs.getStringList(StorageKeys.unlockViaProblemHistory) ?? [];
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = history
        .map((s) => int.tryParse(s) ?? 0)
        .where((ms) => DateTime.fromMillisecondsSinceEpoch(ms).isAfter(weekStart))
        .length;
    state = StatsState(totalUnlockViaProblem: total, thisWeekCount: thisWeek);
  }

  Future<void> recordUnlockViaProblem() async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(StorageKeys.unlockViaProblemCount) ?? 0) + 1;
    final history = prefs.getStringList(StorageKeys.unlockViaProblemHistory) ?? [];
    history.add(DateTime.now().millisecondsSinceEpoch.toString());
    while (history.length > 365) {
      history.removeAt(0);
    }
    await prefs.setInt(StorageKeys.unlockViaProblemCount, total);
    await prefs.setStringList(StorageKeys.unlockViaProblemHistory, history);
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = history
        .map((s) => int.tryParse(s) ?? 0)
        .where((ms) => DateTime.fromMillisecondsSinceEpoch(ms).isAfter(weekStart))
        .length;
    state = StatsState(totalUnlockViaProblem: total, thisWeekCount: thisWeek);
  }
}
