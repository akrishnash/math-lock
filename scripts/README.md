# Scripts

## build_install.sh

Build the app and install on the connected Android device.

```bash
./scripts/build_install.sh        # debug build (default)
./scripts/build_install.sh debug   # same
./scripts/build_install.sh release # release APK
```

Requires a device connected via USB with USB debugging enabled, or a running emulator.

## capture_logs.sh

Stream or capture device logs (filtered for the app).

```bash
./scripts/capture_logs.sh         # stream to terminal only
./scripts/capture_logs.sh -f      # stream and save to logs/earn_your_screen_YYYYMMDD_HHMMSS.log
./scripts/capture_logs.sh -f -n 100   # save last 100 lines, clear, then stream and append
```

Press Ctrl+C to stop. Logs are written under `logs/` when using `-f`.

**App page logs:** The app prints `[EarnYourScreen][PageName]` lines so you can confirm each screen:

- `[EarnYourScreen][Home]` – home (initState, checkPendingUnlockIntent, build, Turn off Zen)
- `[EarnYourScreen][Intervention]` – intervention screen (from overlay “Solve problem”)
- `[EarnYourScreen][Challenge]` – math challenge screen
- `[EarnYourScreen][Login]` – login screen

Android native logs use tag `EarnYourScreen` (onCreate, onNewIntent, captureUnlockIntent, consumePendingUnlockIntent). Filter with `EarnYourScreen` or `earn_your_screen` to see the full flow.
