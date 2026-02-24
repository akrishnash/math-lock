package com.mathlock.math_lock

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.concurrent.ConcurrentHashMap

class ZenMonitorService : Service() {

  private val handler = Handler(Looper.getMainLooper())
  private var overlayView: View? = null
  private var windowManager: WindowManager? = null
  private var running = false
  private var blockedPackages: Set<String> = emptySet()
  private var sessionEndMillis: Long = 0
  private var currentBlockedPackage: String? = null
  private var appLabelByPackage: MutableMap<String, String> = mutableMapOf()

  private val pollRunnable = object : Runnable {
    override fun run() {
      if (!running) return
      checkForegroundApp()
      handler.postDelayed(this, POLL_INTERVAL_MS)
    }
  }

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onCreate() {
    super.onCreate()
    windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      ACTION_START -> {
        blockedPackages = (intent.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES) ?: emptyList()).toSet()
        sessionEndMillis = intent.getLongExtra(EXTRA_SESSION_END_MILLIS, 0L)
        startForeground(NOTIFICATION_ID, createNotification())
        running = true
        handler.post(pollRunnable)
      }
      ACTION_STOP -> {
        running = false
        handler.removeCallbacks(pollRunnable)
        hideOverlay()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
      }
    }
    return START_STICKY
  }

  private fun checkForegroundApp() {
    if (blockedPackages.isEmpty()) return
    if (System.currentTimeMillis() > sessionEndMillis) {
      stopSelf()
      return
    }
    val pkg = getForegroundPackage() ?: return
    if (pkg == packageName) return
    if (!blockedPackages.contains(pkg)) return
    // One-time unlock: if a reward is present for this package,
    // allow this foreground entry and consume the reward.
    val hadReward = rewardMap.remove(pkg) == true
    if (hadReward) return
    currentBlockedPackage = pkg
    showOverlay(pkg)
  }

  private fun getForegroundPackage(): String? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return null
    val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
    val now = System.currentTimeMillis()
    val events = usm.queryEvents(now - 5000, now + 1000)
    var lastPkg: String? = null
    val event = UsageEvents.Event()
    while (events.hasNextEvent()) {
      events.getNextEvent(event)
      if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
        lastPkg = event.packageName
      }
    }
    return lastPkg
  }

  private fun showOverlay(pkg: String) {
    if (overlayView != null) return
    val wm = windowManager ?: return
    val layoutParams = WindowManager.LayoutParams(
      WindowManager.LayoutParams.MATCH_PARENT,
      WindowManager.LayoutParams.MATCH_PARENT,
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
      else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
      WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
      android.graphics.PixelFormat.TRANSLUCENT
    ).apply {
      gravity = Gravity.TOP or Gravity.START
      x = 0
      y = 0
    }
    val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
    val view = inflater.inflate(R.layout.overlay_block, null)
    val title = view.findViewById<TextView>(R.id.overlay_title)
    val timeLeft = view.findViewById<TextView>(R.id.overlay_time_left)
    val btnSolve = view.findViewById<Button>(R.id.overlay_btn_solve)
    title.text = getString(R.string.overlay_app_locked, appLabelByPackage[pkg] ?: pkg)
    val remaining = ((sessionEndMillis - System.currentTimeMillis()) / 1000).toInt().coerceAtLeast(0)
    val min = remaining / 60
    val sec = remaining % 60
    timeLeft.text = getString(R.string.overlay_time_left_fmt, min, sec)
    btnSolve.setOnClickListener {
      hideOverlay()
      val i = Intent(this, MainActivity::class.java).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        putExtra("unlock_for_package", pkg)
        putExtra("unlock_app_label", appLabelByPackage[pkg] ?: pkg)
        putExtra("remaining_seconds", remaining)
        putExtra("reward_minutes", 10)
      }
      startActivity(i)
    }
    wm.addView(view, layoutParams)
    overlayView = view
  }

  private fun hideOverlay() {
    overlayView?.let { v ->
      windowManager?.removeView(v)
      overlayView = null
    }
    currentBlockedPackage = null
  }

  private fun createNotification(): Notification {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "Zen Mode",
        NotificationManager.IMPORTANCE_LOW
      ).apply { setShowBadge(false) }
      (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
        .createNotificationChannel(channel)
    }
    val pending = PendingIntent.getActivity(
      this, 0,
      Intent(this, MainActivity::class.java),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("Zen mode active")
      .setContentText("Distracting apps are locked")
      .setSmallIcon(android.R.drawable.ic_lock_lock)
      .setContentIntent(pending)
      .setOngoing(true)
      .build()
  }

  override fun onDestroy() {
    running = false
    handler.removeCallbacks(pollRunnable)
    hideOverlay()
    super.onDestroy()
  }

  companion object {
    private const val ACTION_START = "com.mathlock.math_lock.START"
    private const val ACTION_STOP = "com.mathlock.math_lock.STOP"
    private const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"
    private const val EXTRA_SESSION_END_MILLIS = "session_end_millis"
    private const val NOTIFICATION_ID = 1001
    private const val CHANNEL_ID = "zen_mode"
    private const val POLL_INTERVAL_MS = 2000L

    fun start(context: Context, blockedPackages: List<String>, sessionEndMillis: Long) {
      val intent = Intent(context, ZenMonitorService::class.java).apply {
        action = ACTION_START
        putStringArrayListExtra(EXTRA_BLOCKED_PACKAGES, ArrayList(blockedPackages))
        putExtra(EXTRA_SESSION_END_MILLIS, sessionEndMillis)
      }
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(intent)
      } else {
        context.startService(intent)
      }
    }

    fun stop(context: Context) {
      context.stopService(Intent(context, ZenMonitorService::class.java))
    }

    fun allowPackageForMinutes(context: Context, packageName: String, minutes: Int) {
      // Treat reward as a one-time token: the next time this package
      // comes to the foreground, it will be allowed once.
      rewardMap[packageName] = true
    }

    private val rewardMap = ConcurrentHashMap<String, Boolean>()
  }
}
