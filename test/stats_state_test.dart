import 'package:flutter_test/flutter_test.dart';
import 'package:math_lock/features/stats/stats_state.dart';

String _stamp(DateTime value) => value.millisecondsSinceEpoch.toString();

void main() {
  group('StatsState.fromHistory', () {
    test('counts today, this week, and streak ending today', () {
      final now = DateTime(2026, 4, 12, 10);
      final history = [
        _stamp(DateTime(2026, 4, 12, 9)),
        _stamp(DateTime(2026, 4, 12, 9, 30)),
        _stamp(DateTime(2026, 4, 11, 14)),
        _stamp(DateTime(2026, 4, 10, 8)),
        _stamp(DateTime(2026, 4, 1, 8)),
      ];

      final stats = StatsState.fromHistory(
        totalUnlockViaProblem: history.length,
        history: history,
        now: now,
      );

      expect(stats.todayCount, 2);
      expect(stats.thisWeekCount, 4);
      expect(stats.currentStreakDays, 3);
      expect(stats.dailyAverageThisWeek, closeTo(4 / 7, 0.001));
    });

    test('keeps streak alive when the most recent solve was yesterday', () {
      final now = DateTime(2026, 4, 12, 10);
      final history = [
        _stamp(DateTime(2026, 4, 11, 14)),
        _stamp(DateTime(2026, 4, 10, 8)),
      ];

      final stats = StatsState.fromHistory(
        totalUnlockViaProblem: history.length,
        history: history,
        now: now,
      );

      expect(stats.todayCount, 0);
      expect(stats.currentStreakDays, 2);
    });
  });
}
