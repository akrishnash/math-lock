import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/models/app_info.dart';

/// Zen mode on/off and session end time (epoch ms). Null = zen off.
final zenSessionProvider = StateNotifierProvider<ZenSessionNotifier, ZenSessionState>((ref) {
  return ZenSessionNotifier();
});

class ZenSessionState {
  const ZenSessionState({
    this.sessionEndMillis,
    this.blockedPackages = const [],
  });

  final int? sessionEndMillis;
  final List<String> blockedPackages;

  bool get isZenOn => sessionEndMillis != null && sessionEndMillis! > DateTime.now().millisecondsSinceEpoch;

  ZenSessionState copyWith({
    int? sessionEndMillis,
    List<String>? blockedPackages,
  }) =>
      ZenSessionState(
        sessionEndMillis: sessionEndMillis ?? this.sessionEndMillis,
        blockedPackages: blockedPackages ?? this.blockedPackages,
      );
}

class ZenSessionNotifier extends StateNotifier<ZenSessionState> {
  ZenSessionNotifier() : super(const ZenSessionState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final end = prefs.getInt(StorageKeys.zenSessionEndMillis);
    final packages = prefs.getStringList(StorageKeys.blockedPackages) ?? [];
    state = state.copyWith(
      sessionEndMillis: end,
      blockedPackages: packages,
    );
  }

  Future<void> setBlockedPackages(List<String> packageNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(StorageKeys.blockedPackages, packageNames);
    state = state.copyWith(blockedPackages: packageNames);
  }

  Future<void> startZen({
    required int sessionDurationMinutes,
    required List<String> blockedPackageNames,
  }) async {
    final end = DateTime.now().add(Duration(minutes: sessionDurationMinutes));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.zenSessionEndMillis, end.millisecondsSinceEpoch);
    await prefs.setStringList(StorageKeys.blockedPackages, blockedPackageNames);
    state = state.copyWith(
      sessionEndMillis: end.millisecondsSinceEpoch,
      blockedPackages: blockedPackageNames,
    );
  }

  Future<void> stopZen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.zenSessionEndMillis);
    state = state.copyWith(sessionEndMillis: null);
  }
}

/// Selected app info list for picker (from getInstalledApps).
final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  // Will be implemented via ZenPlatform when channel is ready
  return [];
});
