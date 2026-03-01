#!/usr/bin/env bash
# Capture logs from the Earn Your Screen app on a connected Android device.
# Usage:
#   ./scripts/capture_logs.sh           # stream to terminal
#   ./scripts/capture_logs.sh -f        # stream and save to logs/ with timestamp
#   ./scripts/capture_logs.sh -f -n 50  # save last 50 lines then stream (optional -n)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE="com.earnyourscreen.app"
LOGS_DIR="$PROJECT_DIR/logs"
SAVE_FILE=""
TAIL_LINES=""

while getopts "fn:" opt; do
  case $opt in
    f) SAVE_FILE=1 ;;
    n) TAIL_LINES="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

if ! adb devices | grep -q 'device$'; then
  echo "No Android device/emulator found. Connect a device or start an emulator."
  exit 1
fi

# Flutter and app tag filters
LOG_FILTER="flutter:.*|flutter.*|math_lock|EarnYourScreen|ZenMonitor|ZenMode|com.earnyourscreen"

mkdir -p "$LOGS_DIR"

if [[ -n "$SAVE_FILE" ]]; then
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  LOG_PATH="$LOGS_DIR/earn_your_screen_${TIMESTAMP}.log"
  echo "Saving logs to $LOG_PATH (Ctrl+C to stop)"
  if [[ -n "$TAIL_LINES" ]]; then
    adb logcat -d -t "$TAIL_LINES" 2>/dev/null | grep -E "$LOG_FILTER" || true >> "$LOG_PATH"
    adb logcat -c 2>/dev/null || true
  fi
  adb logcat -v time "*:V" 2>/dev/null | grep -E "$LOG_FILTER" --line-buffered || true | tee -a "$LOG_PATH"
else
  echo "Streaming app logs (Ctrl+C to stop). Use -f to also save to logs/"
  adb logcat -v time "*:V" 2>/dev/null | grep -E "$LOG_FILTER" --line-buffered || true
fi
