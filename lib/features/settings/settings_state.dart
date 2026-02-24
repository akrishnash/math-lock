import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

enum ProblemType { integration, linear }

enum ProblemDifficulty { easy, medium }

class SettingsState {
  const SettingsState({
    this.sessionDurationMinutes = 120,
    this.rewardDurationMinutes = 10,
    this.problemType = ProblemType.linear,
    this.problemDifficulty = ProblemDifficulty.easy,
  });

  final int sessionDurationMinutes;
  final int rewardDurationMinutes;
  final ProblemType problemType;
  final ProblemDifficulty problemDifficulty;

  SettingsState copyWith({
    int? sessionDurationMinutes,
    int? rewardDurationMinutes,
    ProblemType? problemType,
    ProblemDifficulty? problemDifficulty,
  }) =>
      SettingsState(
        sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
        rewardDurationMinutes: rewardDurationMinutes ?? this.rewardDurationMinutes,
        problemType: problemType ?? this.problemType,
        problemDifficulty: problemDifficulty ?? this.problemDifficulty,
      );
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      sessionDurationMinutes:
          prefs.getInt(StorageKeys.sessionDurationMinutes) ?? 120,
      rewardDurationMinutes:
          prefs.getInt(StorageKeys.rewardDurationMinutes) ?? 10,
      problemType: _parseProblemType(
          prefs.getString(StorageKeys.problemType) ?? 'linear'),
      problemDifficulty: _parseDifficulty(
          prefs.getString(StorageKeys.problemDifficulty) ?? 'easy'),
    );
  }

  ProblemType _parseProblemType(String v) {
    switch (v) {
      case 'integration':
        return ProblemType.integration;
      default:
        return ProblemType.linear;
    }
  }

  ProblemDifficulty _parseDifficulty(String v) {
    switch (v) {
      case 'medium':
        return ProblemDifficulty.medium;
      default:
        return ProblemDifficulty.easy;
    }
  }

  Future<void> setSessionDurationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.sessionDurationMinutes, minutes);
    state = state.copyWith(sessionDurationMinutes: minutes);
  }

  Future<void> setRewardDurationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.rewardDurationMinutes, minutes);
    state = state.copyWith(rewardDurationMinutes: minutes);
  }

  Future<void> setProblemType(ProblemType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        StorageKeys.problemType,
        type == ProblemType.integration ? 'integration' : 'linear');
    state = state.copyWith(problemType: type);
  }

  Future<void> setProblemDifficulty(ProblemDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        StorageKeys.problemDifficulty,
        difficulty == ProblemDifficulty.medium ? 'medium' : 'easy');
    state = state.copyWith(problemDifficulty: difficulty);
  }
}
