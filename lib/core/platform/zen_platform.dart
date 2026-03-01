import 'dart:async';

import 'package:flutter/services.dart';

import '../models/app_info.dart';

/// Platform channel API for Zen mode: apps, permissions, monitoring, reward.
class ZenPlatform {
  ZenPlatform._();

  static const MethodChannel _channel = MethodChannel('com.earnyourscreen.app/zen');
  static const EventChannel _blockedAppChannel =
      EventChannel('com.earnyourscreen.app/blocked_app');

  /// Get list of installed launchable apps (package name + label).
  static Future<List<AppInfo>> getInstalledApps() async {
    final List<dynamic> raw =
        await _channel.invokeListMethod<dynamic>('getInstalledApps') ?? [];
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map((m) => AppInfo.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Open system screen to grant usage stats permission.
  static Future<void> openUsageAccessSettings() async {
    await _channel.invokeMethod('openUsageAccessSettings');
  }

  /// Returns true if usage stats permission is granted.
  static Future<bool> hasUsageStatsPermission() async {
    return (await _channel.invokeMethod<bool>('hasUsageStatsPermission')) ?? false;
  }

  /// Open system screen to grant overlay permission.
  static Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  /// Returns true if overlay permission is granted.
  static Future<bool> hasOverlayPermission() async {
    return (await _channel.invokeMethod<bool>('hasOverlayPermission')) ?? false;
  }

  /// Open system screen to grant notification listener permission.
  static Future<void> openNotificationListenerSettings() async {
    await _channel.invokeMethod('openNotificationListenerSettings');
  }

  /// Returns true if notification listener is enabled.
  static Future<bool> hasNotificationListenerPermission() async {
    return (await _channel.invokeMethod<bool>('hasNotificationListenerPermission')) ??
        false;
  }

  /// Start zen monitoring. If [fullLock] is true, locks entire phone (except calls).
  static Future<void> startZenMonitoring({
    required List<String> blockedPackageNames,
    required int sessionEndMillis,
    required bool allowReopenWithinWindow,
    bool fullLock = false,
  }) async {
    await _channel.invokeMethod('startZenMonitoring', {
      'blockedPackageNames': blockedPackageNames,
      'sessionEndMillis': sessionEndMillis,
      'allowReopenWithinWindow': allowReopenWithinWindow,
      'fullLock': fullLock,
    });
  }

  /// Stop zen monitoring and overlay.
  static Future<void> stopZenMonitoring() async {
    await _channel.invokeMethod('stopZenMonitoring');
  }

  /// Allow [packageName] to be used for [minutes]. Called after user solves problem.
  static Future<void> allowPackageForMinutes({
    required String packageName,
    required int minutes,
  }) async {
    await _channel.invokeMethod('allowPackageForMinutes', {
      'packageName': packageName,
      'minutes': minutes,
    });
  }

  /// Allow full phone unlock for [minutes] (used when lock mode is "full").
  static Future<void> allowFullUnlockForMinutes(int minutes) async {
    await _channel.invokeMethod('allowFullUnlockForMinutes', {'minutes': minutes});
  }

  /// Stream: when user opens a blocked app, emits map with 'packageName', 'remainingSeconds' (optional).
  static Stream<Map<dynamic, dynamic>> get blockedAppOpenedStream =>
      _blockedAppChannel.receiveBroadcastStream().map((e) => e as Map<dynamic, dynamic>);

  /// If the app was launched from overlay "Solve problem", returns the intent data once.
  static Future<Map<String, dynamic>?> getPendingUnlockIntent() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPendingUnlockIntent');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  /// Launch the app with [packageName] (e.g. after granting grace).
  static Future<void> launchApp(String packageName) async {
    if (packageName.isEmpty) return;
    await _channel.invokeMethod('launchApp', {'packageName': packageName});
  }
}
