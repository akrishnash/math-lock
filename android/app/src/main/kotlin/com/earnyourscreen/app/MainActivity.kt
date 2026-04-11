package com.earnyourscreen.app

import android.util.Log
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

  private var blockedAppEventSink: EventChannel.EventSink? = null
  private val channelName = "com.earnyourscreen.app/zen"
  private val eventChannelName = "com.earnyourscreen.app/blocked_app"

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
          val allowReopenWithinWindow =
            call.argument<Boolean>("allowReopenWithinWindow") ?: false
          val fullLock = call.argument<Boolean>("fullLock") ?: false
          val rewardMinutes = (call.argument<Number>("rewardMinutes"))?.toInt() ?: 10
          ZenNotificationListenerService.setBlockedPackages(this, blocked.toSet())
          ZenMonitorService.start(
            this,
            blocked,
            sessionEndMillis,
            allowReopenWithinWindow,
            fullLock,
            rewardMinutes
          )
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
        "allowFullUnlockForMinutes" -> {
          val minutes = (call.argument<Number>("minutes"))?.toInt() ?: 0
          ZenMonitorService.allowFullUnlockForMinutes(this, minutes)
          result.success(null)
        }
        "getPendingUnlockIntent" -> {
          result.success(consumePendingUnlockIntent())
        }
        "launchApp" -> {
          val pkg = call.argument<String>("packageName") ?: ""
          try {
            val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
            if (launchIntent != null) {
              launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              startActivity(launchIntent)
              result.success(null)
            } else {
              result.error("NO_LAUNCHER", "No launcher intent for $pkg", null)
            }
          } catch (e: Exception) {
            result.error("ERROR", e.message, null)
          }
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
    WindowCompat.setDecorFitsSystemWindows(window, false)
    super.onCreate(savedInstanceState)
    Log.d(TAG, "onCreate intent extras: ${intent?.extras?.keySet()}")
    captureUnlockIntent(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    Log.d(TAG, "onNewIntent unlock_for_package=${intent.getStringExtra("unlock_for_package")}")
    captureUnlockIntent(intent)
  }

  private fun captureUnlockIntent(intent: Intent?) {
    val pkg = intent?.getStringExtra("unlock_for_package") ?: return
    Log.d(TAG, "captureUnlockIntent: pkg=$pkg timesUp=${intent.getBooleanExtra("times_up", false)}")
    pendingUnlockIntent = mapOf(
      "packageName" to pkg,
      "appLabel" to (intent.getStringExtra("unlock_app_label") ?: pkg),
      "remainingSeconds" to intent.getIntExtra("remaining_seconds", 0),
      "rewardMinutes" to intent.getIntExtra("reward_minutes", 10),
      "timesUp" to intent.getBooleanExtra("times_up", false)
    )
  }

  fun consumePendingUnlockIntent(): Map<String, Any>? {
    val p = pendingUnlockIntent
    pendingUnlockIntent = null
    Log.d(TAG, "consumePendingUnlockIntent: ${if (p != null) "pkg=${p["packageName"]}" else "null"}")
    return p
  }

  companion object {
    private const val TAG = "EarnYourScreen"
  }

  private fun getInstalledApps(): List<Map<String, Any>> {
    val pm = packageManager
    val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
    val resolveInfo = pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
    val socialKeys = listOf(
      "instagram",
      "facebook.katana",
      "facebook",
      "tiktok",
      "snapchat",
      "reddit",
      "youtube",
      "whatsapp",
      "telegram",
      "twitter",
      "x.com",
      "discord",
      "pinterest"
    )

    val filtered = resolveInfo.filter { info ->
      val pkg = info.activityInfo.packageName.lowercase()
      socialKeys.any { key -> pkg.contains(key) }
    }

    return filtered.map { info ->
      val pkg = info.activityInfo.packageName
      val label = info.loadLabel(pm)?.toString() ?: pkg
      val iconDrawable = info.loadIcon(pm)
      val iconBytes = drawableToPngBytes(iconDrawable)

      val map = mutableMapOf<String, Any>(
        "packageName" to pkg,
        "label" to label,
      )
      if (iconBytes != null) {
        map["icon"] = iconBytes
      }
      map
    }.sortedBy { (it["label"] as? String)?.lowercase() ?: "" }
  }

  private fun drawableToPngBytes(drawable: Drawable): ByteArray? {
    val bitmap: Bitmap = when (drawable) {
      is BitmapDrawable -> drawable.bitmap
      else -> {
        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 128
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 128
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        bmp
      }
    }
    val output = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
    return output.toByteArray()
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
