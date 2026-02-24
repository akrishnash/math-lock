package com.mathlock.math_lock

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class ZenNotificationListenerService : NotificationListenerService() {

  override fun onNotificationPosted(sbn: StatusBarNotification?) {
    if (sbn == null) return
    val pkg = sbn.packageName ?: return
    if (pkg == packageName) return
    val blocked = getBlockedPackages()
    if (blocked.contains(pkg)) {
      try {
        cancelNotification(sbn.packageName, sbn.tag, sbn.id)
      } catch (_: Exception) {}
    }
  }

  private fun getBlockedPackages(): Set<String> {
    val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
    return prefs.getStringSet(KEY_BLOCKED_PACKAGES, emptySet()) ?: emptySet()
  }

  companion object {
    private const val PREFS_NAME = "zen_monitor"
    private const val KEY_BLOCKED_PACKAGES = "blocked_packages"

    fun isEnabled(context: android.content.Context): Boolean {
      val enabled = android.provider.Settings.Secure.getString(
        context.contentResolver,
        "enabled_notification_listeners"
      ) ?: return false
      return enabled.contains(context.packageName)
    }

    fun setBlockedPackages(context: android.content.Context, packages: Set<String>) {
      context.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        .edit()
        .putStringSet(KEY_BLOCKED_PACKAGES, packages)
        .apply()
    }
  }
}
