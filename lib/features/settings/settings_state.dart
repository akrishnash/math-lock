import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/theme/app_colors.dart';

enum ProblemType { integration, linear }

enum ProblemDifficulty { easy, medium }

/// Lock mode: block selected apps only, or lock entire phone (except calls).
enum LockMode { apps, full }

/// Accent color key for problem screen and UI.
typedef AccentColorKey = String; // 'pink' | 'cyan' | 'purple' | 'yellow' | 'green'

class SettingsState {
  const SettingsState({
    this.sessionDurationMinutes = 120,
    this.rewardDurationMinutes = 10,
    this.allowReopenWithinWindow = false,
    this.lockMode = LockMode.apps,
    this.problemType = ProblemType.linear,
    this.problemDifficulty = ProblemDifficulty.easy,
    this.penaltyMinutes = 5,
    this.accentColorKey = 'pink',
    this.enableSounds = false,
    this.enableVibration = true,
    this.questionTopic = 'mixed',
  });

  final int sessionDurationMinutes;
  final int rewardDurationMinutes;
  final bool allowReopenWithinWindow;
  final LockMode lockMode;
  final ProblemType problemType;
  final ProblemDifficulty problemDifficulty;
  final int penaltyMinutes;
  final String accentColorKey;
  final bool enableSounds;
  final bool enableVibration;
  final String questionTopic;

  Color get accentColor => AppColors.accentColors[accentColorKey] ?? AppColors.neonPink;

  SettingsState copyWith({
    int? sessionDurationMinutes,
    int? rewardDurationMinutes,
    bool? allowReopenWithinWindow,
    LockMode? lockMode,
    ProblemType? problemType,
    ProblemDifficulty? problemDifficulty,
    int? penaltyMinutes,
    String? accentColorKey,
    bool? enableSounds,
    bool? enableVibration,
    String? questionTopic,
  }) =>
      SettingsState(
        sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
        rewardDurationMinutes: rewardDurationMinutes ?? this.rewardDurationMinutes,
        allowReopenWithinWindow:
            allowReopenWithinWindow ?? this.allowReopenWithinWindow,
        lockMode: lockMode ?? this.lockMode,
        problemType: problemType ?? this.problemType,
        problemDifficulty: problemDifficulty ?? this.problemDifficulty,
        penaltyMinutes: penaltyMinutes ?? this.penaltyMinutes,
        accentColorKey: accentColorKey ?? this.accentColorKey,
        enableSounds: enableSounds ?? this.enableSounds,
        enableVibration: enableVibration ?? this.enableVibration,
        questionTopic: questionTopic ?? this.questionTopic,
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
      allowReopenWithinWindow:
          prefs.getBool(StorageKeys.allowReopenWithinWindow) ?? false,
      problemType: _parseProblemType(
          prefs.getString(StorageKeys.problemType) ?? 'linear'),
      problemDifficulty: _parseDifficulty(
          prefs.getString(StorageKeys.problemDifficulty) ?? 'easy'),
      penaltyMinutes: prefs.getInt(StorageKeys.penaltyMinutes) ?? 5,
      accentColorKey: prefs.getString(StorageKeys.accentColor) ?? 'pink',
      enableSounds: prefs.getBool(StorageKeys.enableSounds) ?? false,
      enableVibration: prefs.getBool(StorageKeys.enableVibration) ?? true,
      questionTopic: prefs.getString(StorageKeys.questionTopic) ?? 'mixed',
      lockMode: _parseLockMode(prefs.getString(StorageKeys.lockMode) ?? 'apps'),
    );
  }

  LockMode _parseLockMode(String v) {
    return v == 'full' ? LockMode.full : LockMode.apps;
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

  Future<void> setAllowReopenWithinWindow(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.allowReopenWithinWindow, value);
    state = state.copyWith(allowReopenWithinWindow: value);
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

  Future<void> setPenaltyMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.penaltyMinutes, minutes);
    state = state.copyWith(penaltyMinutes: minutes);
  }

  Future<void> setAccentColorKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.accentColor, key);
    state = state.copyWith(accentColorKey: key);
  }

  Future<void> setEnableSounds(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.enableSounds, value);
    state = state.copyWith(enableSounds: value);
  }

  Future<void> setEnableVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.enableVibration, value);
    state = state.copyWith(enableVibration: value);
  }

  Future<void> setQuestionTopic(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.questionTopic, topic);
    state = state.copyWith(questionTopic: topic);
  }

  Future<void> setLockMode(LockMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.lockMode, mode == LockMode.full ? 'full' : 'apps');
    state = state.copyWith(lockMode: mode);
  }
}
