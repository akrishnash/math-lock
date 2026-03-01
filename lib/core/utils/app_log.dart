import 'package:flutter/foundation.dart';

/// Use "EarnYourScreen" or "earn_your_screen" in logcat to filter these.
void log(String page, String message) {
  debugPrint('[EarnYourScreen][$page] $message');
}

void logError(String page, String message, [Object? error, StackTrace? stack]) {
  debugPrint('[EarnYourScreen][$page] ERROR: $message');
  if (error != null) debugPrint('[EarnYourScreen][$page] $error');
  if (stack != null) debugPrint('[EarnYourScreen][$page] $stack');
}
