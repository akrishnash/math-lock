const {
  withAndroidManifest,
  withMainApplication,
  withDangerousMod,
} = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const PACKAGE = 'com.mathlock.app';

function addPermissions(manifest) {
  const permissions = manifest['uses-permission'] || [];
  const existing = permissions.map((p) => p.$?.['android:name']).filter(Boolean);
  const toAdd = [
    'android.permission.PACKAGE_USAGE_STATS',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_SPECIAL_USE',
    'android.permission.POST_NOTIFICATIONS',
  ];
  toAdd.forEach((perm) => {
    if (!existing.includes(perm)) {
      permissions.push({ $: { 'android:name': perm } });
    }
  });
  manifest['uses-permission'] = permissions;
  return manifest;
}

function addService(manifest) {
  const app = manifest.application?.[0];
  if (!app?.service) app.service = [];
  const services = Array.isArray(app.service) ? app.service : [app.service];
  const hasBlocking = services.some(
    (s) => s.$?.['android:name'] === `${PACKAGE}.AppBlockingService`
  );
  if (!hasBlocking) {
    services.push({
      $: {
        'android:name': `${PACKAGE}.AppBlockingService`,
        'android:enabled': 'true',
        'android:exported': 'false',
        'android:foregroundServiceType': 'specialUse',
      },
    });
    app.service = services;
  }
  return manifest;
}

const APP_BLOCKING_MODULE = `package ${PACKAGE}

import android.content.Intent
import android.os.Build
import android.provider.Settings
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule

class AppBlockingModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "AppBlocking"

    @ReactMethod
    fun checkUsagePermission(promise: Promise) {
        val appOps = reactApplicationContext.getSystemService(android.app.AppOpsManager::class.java)
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                "android:get_usage_stats",
                android.os.Process.myUid(),
                reactApplicationContext.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                "android:get_usage_stats",
                android.os.Process.myUid(),
                reactApplicationContext.packageName
            )
        }
        promise.resolve(mode == android.app.AppOpsManager.MODE_ALLOWED)
    }

    @ReactMethod
    fun openUsageAccessSettings(promise: Promise) {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            reactApplicationContext.startActivity(intent)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    @ReactMethod
    fun openBatteryOptimizationSettings(promise: Promise) {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            } else {
                Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            reactApplicationContext.startActivity(intent)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    @ReactMethod
    fun startBlockingService(blockedPackages: ReadableArray, promise: Promise) {
        try {
            val prefs = reactApplicationContext.getSharedPreferences("AppBlocking", 0)
            val packages = mutableListOf<String>()
            for (i in 0 until blockedPackages.size()) {
                val pkg = blockedPackages.getString(i) ?: continue
                packages.add(pkg)
            }
            prefs.edit().putStringSet("blocked", packages.toSet()).apply()
            val intent = android.content.Intent(reactApplicationContext, AppBlockingService::class.java)
            intent.action = "START"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                reactApplicationContext.startForegroundService(intent)
            } else {
                reactApplicationContext.startService(intent)
            }
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    @ReactMethod
    fun stopBlockingService(promise: Promise) {
        try {
            val intent = android.content.Intent(reactApplicationContext, AppBlockingService::class.java)
            intent.action = "STOP"
            reactApplicationContext.startService(intent)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }
}
`;

const APP_BLOCKING_PACKAGE = `package ${PACKAGE}

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class AppBlockingPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        return listOf(AppBlockingModule(reactContext))
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}
`;

const APP_BLOCKING_SERVICE = `package ${PACKAGE}

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.app.usage.UsageStatsManager
import android.app.usage.UsageStats
import android.app.usage.UsageEvents
import java.util.*
import java.util.concurrent.TimeUnit

class AppBlockingService : Service() {

    private var running = true

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "STOP" -> {
                running = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
        }
        startForeground()
        Thread {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val prefs = getSharedPreferences("AppBlocking", 0)
            while (running) {
                try {
                    val blocked = prefs.getStringSet("blocked", emptySet()) ?: emptySet()
                    if (blocked.isNotEmpty()) {
                        val end = System.currentTimeMillis()
                        val start = end - TimeUnit.SECONDS.toMillis(3)
                        var foregroundPkg: String? = null
                        val events = usm.queryEvents(start, end)
                        val event = android.app.usage.UsageEvents.Event()
                        while (events.hasNextEvent()) {
                            events.getNextEvent(event)
                            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                                foregroundPkg = event.packageName
                            }
                        }
                        if (foregroundPkg == null) {
                            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, start, end)
                            var topTime = 0L
                            if (stats != null) {
                                for (s in stats) {
                                    if (s.lastTimeUsed > topTime) {
                                        topTime = s.lastTimeUsed
                                        foregroundPkg = s.packageName
                                    }
                                }
                            }
                        }
                        if (foregroundPkg != null && foregroundPkg != packageName && blocked.contains(foregroundPkg)) {
                            val launch = packageManager.getLaunchIntentForPackage(packageName)
                            launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            startActivity(launch)
                        }
                    }
                } catch (_: Exception) {}
                Thread.sleep(800)
            }
        }.start()
        return START_STICKY
    }

    private fun startForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "mathlock_blocking",
                "Math Lock",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.setShowBadge(false)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
            val notification = Notification.Builder(this, "mathlock_blocking")
                .setContentTitle("Math Lock")
                .setContentText("Blocking distracting apps")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .build()
            startForeground(1, notification)
        }
    }
}
`;

function withAppBlocking(config) {
  config = withAndroidManifest(config, (config) => {
    config.modResults.manifest = addPermissions(config.modResults.manifest);
    config.modResults.manifest = addService(config.modResults.manifest);
    return config;
  });

  config = withMainApplication(config, (config) => {
    let contents = config.modResults.contents;
    if (!contents.includes('AppBlockingPackage')) {
      contents = contents.replace(
        'PackageList(this).packages.apply {',
        'PackageList(this).packages.apply {\n              add(AppBlockingPackage())'
      );
    }
    config.modResults.contents = contents;
    return config;
  });

  config = withDangerousMod(config, [
    'android',
    async (config) => {
      const projectRoot = config.modRequest.platformProjectRoot;
      const pkgPath = path.join(
        projectRoot,
        'app',
        'src',
        'main',
        'java',
        'com',
        'mathlock',
        'app'
      );
      await fs.promises.mkdir(pkgPath, { recursive: true });
      await fs.promises.writeFile(
        path.join(pkgPath, 'AppBlockingModule.kt'),
        APP_BLOCKING_MODULE
      );
      await fs.promises.writeFile(
        path.join(pkgPath, 'AppBlockingPackage.kt'),
        APP_BLOCKING_PACKAGE
      );
      await fs.promises.writeFile(
        path.join(pkgPath, 'AppBlockingService.kt'),
        APP_BLOCKING_SERVICE
      );
      return config;
    },
  ]);

  return config;
}

module.exports = withAppBlocking;
