package com.earnyourscreen.app

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
import android.telephony.TelephonyManager
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

class ZenMonitorService : Service() {

  private val handler = Handler(Looper.getMainLooper())
  private var overlayView: View? = null
  private var fullLockOverlayView: View? = null
  private var graceTimerOverlayView: View? = null
  private var windowManager: WindowManager? = null
  private var running = false
  private var fullLock = false
  private var blockedPackages: Set<String> = emptySet()
  private var sessionEndMillis: Long = 0
  private var currentBlockedPackage: String? = null
  private var allowReopenWithinWindow: Boolean = false
  private var appLabelByPackage: MutableMap<String, String> = mutableMapOf()
  private var rewardMinutes: Int = 10

  private val pollRunnable = object : Runnable {
    override fun run() {
      if (!running) return
      if (fullLock) updateFullLockOverlay() else checkForegroundApp()
      handler.postDelayed(this, POLL_INTERVAL_MS)
    }
  }

  private val graceTimerRunnable = object : Runnable {
    override fun run() {
      if (!running) return
      updateGraceTimerOverlay()
      handler.postDelayed(this, 1000L)
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
        allowReopenWithinWindow = intent.getBooleanExtra("allow_reopen_within_window", false)
        fullLock = intent.getBooleanExtra(EXTRA_FULL_LOCK, false)
        rewardMinutes = intent.getIntExtra("reward_minutes", 10)
        // Resolve friendly app labels so the intervention screen shows "Instagram"
        // rather than "com.instagram.android".
        val pm = packageManager
        appLabelByPackage.clear()
        for (pkg in blockedPackages) {
          appLabelByPackage[pkg] = try {
            @Suppress("DEPRECATION")
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
          } catch (_: Exception) { pkg }
        }
        startForeground(NOTIFICATION_ID, createNotification())
        running = true
        handler.post(pollRunnable)
      }
      ACTION_STOP -> {
        running = false
        handler.removeCallbacks(pollRunnable)
        handler.removeCallbacks(graceTimerRunnable)
        hideFullLockOverlay()
        hideGraceTimerOverlay()
        hideOverlay()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
      }
    }
    return START_STICKY
  }

  private fun isInCall(): Boolean {
    return try {
      val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager ?: return false
      val state = tm.callState
      state == 1 || state == 2  // RINGING=1, OFF_HOOK=2
    } catch (e: Exception) {
      false
    }
  }

  private fun updateFullLockOverlay() {
    val now = System.currentTimeMillis()
    if (now > sessionEndMillis) {
      stopSelf()
      return
    }
    // When our app is in foreground (user tapped "Solve problem"), keep overlay hidden
    // so they can actually use the app to solve the problem.
    val fgPkg = getForegroundPackage()
    if (fgPkg == packageName) {
      hideFullLockOverlay()
      return
    }
    val graceEnd = fullLockGraceEndMillis.get()
    val inCall = isInCall()
    if (now < graceEnd || inCall) {
      hideFullLockOverlay()
      return
    }
    showFullLockOverlay()
  }

  private fun showFullLockOverlay() {
    if (fullLockOverlayView != null) return
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
    val view = inflater.inflate(R.layout.overlay_full_lock, null)
    val btnSolve = view.findViewById<Button>(R.id.overlay_full_btn_solve)
    btnSolve.setOnClickListener {
      hideFullLockOverlay()
      val remaining = ((sessionEndMillis - System.currentTimeMillis()) / 1000).toInt().coerceAtLeast(0)
      val i = Intent(this, MainActivity::class.java).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        putExtra("unlock_for_package", FULL_LOCK_PACKAGE)
        putExtra("unlock_app_label", "Phone")
        putExtra("remaining_seconds", remaining)
        putExtra("reward_minutes", rewardMinutes)
        putExtra("times_up", false)
      }
      startActivity(i)
    }
    wm.addView(view, layoutParams)
    fullLockOverlayView = view
  }

  private fun hideFullLockOverlay() {
    fullLockOverlayView?.let { v ->
      windowManager?.removeView(v)
      fullLockOverlayView = null
    }
  }

  private fun checkForegroundApp() {
    val now = System.currentTimeMillis()
    if (now > sessionEndMillis) {
      stopSelf()
      return
    }
    val pkg = getForegroundPackage() ?: run {
      hideGraceTimerOverlay()
      return
    }
    if (pkg == packageName) {
      hideGraceTimerOverlay()
      return
    }

    if (!blockedPackages.contains(pkg) && currentBlockedPackage != null) {
      if (!allowReopenWithinWindow) {
        rewardMap.remove(currentBlockedPackage!!)
      }
      currentBlockedPackage = null
      hideGraceTimerOverlay()
      return
    }

    if (!blockedPackages.contains(pkg)) {
      hideGraceTimerOverlay()
      return
    }

    val rewardEnd = rewardMap[pkg] ?: 0L
    var timesUp = false
    if (rewardEnd > 0L) {
      if (now < rewardEnd) {
        currentBlockedPackage = pkg
        showOrUpdateGraceTimerOverlay(pkg, rewardEnd)
        return
      } else {
        rewardMap.remove(pkg)
        timesUp = true
        hideGraceTimerOverlay()
      }
    }
    currentBlockedPackage = pkg
    launchMathLockForUnlock(pkg, timesUp)
  }

  private fun showOrUpdateGraceTimerOverlay(pkg: String, rewardEndMillis: Long) {
    val remainingSec = ((rewardEndMillis - System.currentTimeMillis()) / 1000).toInt().coerceAtLeast(0)
    if (remainingSec <= 0) {
      hideGraceTimerOverlay()
      rewardMap.remove(pkg)
      launchMathLockForUnlock(pkg, true)
      return
    }
    if (graceTimerOverlayView == null) {
      val wm = windowManager ?: return
      val layoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        android.graphics.PixelFormat.TRANSLUCENT
      ).apply {
        gravity = Gravity.BOTTOM or Gravity.END
        x = 24
        y = 120
      }
      val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
      val view = inflater.inflate(R.layout.overlay_grace_timer, null)
      wm.addView(view, layoutParams)
      graceTimerOverlayView = view
      handler.removeCallbacks(graceTimerRunnable)
      handler.post(graceTimerRunnable)
    }
    val tv = graceTimerOverlayView?.findViewById<TextView>(R.id.grace_timer_text)
    tv?.text = formatGraceTime(remainingSec)
  }

  private fun updateGraceTimerOverlay() {
    val pkg = currentBlockedPackage ?: run {
      hideGraceTimerOverlay()
      return
    }
    val rewardEnd = rewardMap[pkg] ?: run {
      hideGraceTimerOverlay()
      return
    }
    val now = System.currentTimeMillis()
    if (now >= rewardEnd) {
      hideGraceTimerOverlay()
      rewardMap.remove(pkg)
      launchMathLockForUnlock(pkg, true)
      return
    }
    val remainingSec = ((rewardEnd - now) / 1000).toInt().coerceAtLeast(0)
    graceTimerOverlayView?.findViewById<TextView>(R.id.grace_timer_text)?.text = formatGraceTime(remainingSec)
  }

  private fun formatGraceTime(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return "%d:%02d".format(m, s)
  }

  private fun hideGraceTimerOverlay() {
    handler.removeCallbacks(graceTimerRunnable)
    graceTimerOverlayView?.let { v ->
      windowManager?.removeView(v)
      graceTimerOverlayView = null
    }
  }

  private fun getForegroundPackage(): String? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return null
    val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
    val now = System.currentTimeMillis()
    val events = usm.queryEvents(now - 300_000, now + 1000)
    var lastPkg: String? = null
    var lastTime = 0L
    val event = UsageEvents.Event()
    while (events.hasNextEvent()) {
      events.getNextEvent(event)
      if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND && event.timeStamp > lastTime) {
        lastPkg = event.packageName
        lastTime = event.timeStamp
      }
    }
    return lastPkg
  }

  private fun launchMathLockForUnlock(pkg: String, timesUp: Boolean) {
    val remaining = ((sessionEndMillis - System.currentTimeMillis()) / 1000).toInt().coerceAtLeast(0)
    val i = Intent(this, MainActivity::class.java).apply {
      addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
      putExtra("unlock_for_package", pkg)
      putExtra("unlock_app_label", appLabelByPackage[pkg] ?: pkg)
      putExtra("remaining_seconds", remaining)
      putExtra("reward_minutes", rewardMinutes)
      putExtra("times_up", timesUp)
    }
    startActivity(i)
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
        "Earn Your Screen",
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
      .setContentTitle("Earn Your Screen active")
      .setContentText("Focus mode active")
      .setSmallIcon(android.R.drawable.ic_lock_lock)
      .setContentIntent(pending)
      .setOngoing(true)
      .build()
  }

  override fun onDestroy() {
    running = false
    handler.removeCallbacks(pollRunnable)
    handler.removeCallbacks(graceTimerRunnable)
    hideFullLockOverlay()
    hideGraceTimerOverlay()
    hideOverlay()
    // Remove the foreground notification explicitly. On Android 12+ (API 31+)
    // calling stopService() does not always auto-remove it without this call.
    try { stopForeground(STOP_FOREGROUND_REMOVE) } catch (_: Exception) {}
    super.onDestroy()
  }

  companion object {
    private const val ACTION_START = "com.earnyourscreen.app.START"
    private const val ACTION_STOP = "com.earnyourscreen.app.STOP"
    private const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"
    private const val EXTRA_SESSION_END_MILLIS = "session_end_millis"
    private const val EXTRA_FULL_LOCK = "full_lock"
    const val FULL_LOCK_PACKAGE = "_full"
    private const val NOTIFICATION_ID = 1001
    private const val CHANNEL_ID = "zen_mode"
    private const val POLL_INTERVAL_MS = 2000L

    private val fullLockGraceEndMillis = AtomicLong(0L)
    private val rewardMap = ConcurrentHashMap<String, Long>()

    fun start(
      context: Context,
      blockedPackages: List<String>,
      sessionEndMillis: Long,
      allowReopenWithinWindow: Boolean,
      fullLock: Boolean = false,
      rewardMinutes: Int = 10
    ) {
      val intent = Intent(context, ZenMonitorService::class.java).apply {
        action = ACTION_START
        putStringArrayListExtra(EXTRA_BLOCKED_PACKAGES, ArrayList(blockedPackages))
        putExtra(EXTRA_SESSION_END_MILLIS, sessionEndMillis)
        putExtra("allow_reopen_within_window", allowReopenWithinWindow)
        putExtra(EXTRA_FULL_LOCK, fullLock)
        putExtra("reward_minutes", rewardMinutes)
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
      val end = System.currentTimeMillis() + minutes * 60L * 1000L
      rewardMap[packageName] = end
    }

    fun allowFullUnlockForMinutes(context: Context, minutes: Int) {
      fullLockGraceEndMillis.set(System.currentTimeMillis() + minutes * 60L * 1000L)
    }
  }
}
