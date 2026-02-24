package com.mathlock.math_lock

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

  private var blockedAppEventSink: EventChannel.EventSink? = null
  private val channelName = "com.mathlock.math_lock/zen"
  private val eventChannelName = "com.mathlock.math_lock/blocked_app"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
      when (call.method) {
        "getInstalledApps" -> {
          try {
            val apps = getInstalledApps()
            result.success(apps)
          } catch (e: Exception) {
            result.error("ERROR", e.message, null)
          }
        }
        "openUsageAccessSettings" -> {
          startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
          result.success(null)
        }
        "hasUsageStatsPermission" -> {
          result.success(hasUsageStatsPermission())
        }
        "openOverlaySettings" -> {
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
              Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
              Uri.parse("package:$packageName")
            )
            startActivity(intent)
          }
          result.success(null)
        }
        "hasOverlayPermission" -> {
          result.success(hasOverlayPermission())
        }
        "openNotificationListenerSettings" -> {
          startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
          result.success(null)
        }
        "hasNotificationListenerPermission" -> {
          result.success(ZenNotificationListenerService.isEnabled(this))
        }
        "startZenMonitoring" -> {
          val blocked = call.argument<List<String>>("blockedPackageNames") ?: emptyList()
          val sessionEndMillis = (call.argument<Number>("sessionEndMillis"))?.toLong() ?: 0L
          ZenNotificationListenerService.setBlockedPackages(this, blocked.toSet())
          ZenMonitorService.start(this, blocked, sessionEndMillis)
          result.success(null)
        }
        "stopZenMonitoring" -> {
          ZenNotificationListenerService.setBlockedPackages(this, emptySet())
          ZenMonitorService.stop(this)
          result.success(null)
        }
        "allowPackageForMinutes" -> {
          val pkg = call.argument<String>("packageName") ?: ""
          val minutes = (call.argument<Number>("minutes"))?.toInt() ?: 0
          ZenMonitorService.allowPackageForMinutes(this, pkg, minutes)
          result.success(null)
        }
        "getPendingUnlockIntent" -> {
          result.success(consumePendingUnlockIntent())
        }
        else -> result.notImplemented()
      }
    }
    EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          blockedAppEventSink = events
        }
        override fun onCancel(arguments: Any?) {
          blockedAppEventSink = null
        }
      }
    )
  }

  private var pendingUnlockIntent: Map<String, Any>? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    captureUnlockIntent(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    captureUnlockIntent(intent)
  }

  private fun captureUnlockIntent(intent: Intent?) {
    val pkg = intent?.getStringExtra("unlock_for_package") ?: return
    pendingUnlockIntent = mapOf(
      "packageName" to pkg,
      "appLabel" to (intent.getStringExtra("unlock_app_label") ?: pkg),
      "remainingSeconds" to intent.getIntExtra("remaining_seconds", 0),
      "rewardMinutes" to intent.getIntExtra("reward_minutes", 10)
    )
  }

  fun consumePendingUnlockIntent(): Map<String, Any>? {
    val p = pendingUnlockIntent
    pendingUnlockIntent = null
    return p
  }

  private fun getInstalledApps(): List<Map<String, String>> {
    val pm = packageManager
    val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
    val resolveInfo = pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
    return resolveInfo.map { info ->
      mapOf(
        "packageName" to info.activityInfo.packageName,
        "label" to (info.loadLabel(pm)?.toString() ?: info.activityInfo.packageName)
      )
    }.sortedBy { it["label"]?.lowercase() ?: "" }
  }

  private fun hasUsageStatsPermission(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false
    val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return false
    val now = System.currentTimeMillis()
    val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 60000, now)
    return stats != null && stats.isNotEmpty()
  }

  private fun hasOverlayPermission(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
    return Settings.canDrawOverlays(this)
  }

}
