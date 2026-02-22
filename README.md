# Math Lock

Focus timer app that blocks distractions. Set a duration, select apps to lock, and during lockdown the only way to “unlock” early is by solving math problems (with a +5 min penalty for wrong answers). Built from the [Math-Lock App Design](https://www.figma.com/make/jSNAvWf4l17aMKRzBbcUXL/Math-Lock-App-Design) in Figma.

## Design

Exact implementation of the Figma design with:

- **Dashboard** — Set lock duration (hours/minutes), choose apps to block (TikTok, Instagram, Reddit, YouTube), initiate lockdown
- **Intervention** — Countdown screen shown during lockdown; “I’m desperate” opens math challenge
- **Math Challenge** — Solve a math problem for 60s access; wrong answers add 5 minutes

**Design system:** Brutalist theme — black (#000), acid green (#39FF14), off-white (#F0F0F0), Space Mono + Inter

## Run locally

```bash
npm install
npx expo start
```

Press `i` for iOS Simulator, `a` for Android emulator, or scan the QR code with Expo Go.

## App blocking (Android only)

When you enable TikTok, Instagram, Reddit, or YouTube as "apps to block" and start a lockdown, Math Lock will:

1. **Request Usage Access** — On first use, you’ll be asked to enable Usage Access for Math Lock in Settings.
2. **Monitor in foreground** — A foreground service runs while the lockdown is active.
3. **Intercept blocked apps** — If you open a blocked app (e.g. Instagram), Math Lock will open over it and show the "NICE TRY." intervention screen.

**Note:** This uses the Usage Access API and only works in a development/production build (`eas build` or `npx expo run:android`), not in Expo Go.

**If blocking still doesn't work:**
1. **Battery optimization** — Some devices kill background services. Go to Settings → Apps → Math Lock → Battery → set to "Unrestricted" or "Don't optimize". Or tap the Settings icon in the app (when available) to open battery settings.
2. **Usage Access** — Confirm Math Lock has "Permit usage access" in Settings → Apps → Special app access → Usage access.
3. **Manufacturer settings** — On Xiaomi, Oppo, etc., you may need to allow "Autostart" or add Math Lock to "Protected apps" so the service isn't killed.

## Screen pinning (full focus mode)

To keep only Math Lock on screen during the timer:

1. Start a lockdown.
2. On Android, open Recents (square button) and tap the app icon on the Math Lock card.
3. Choose **Pin app**. The device will stay on Math Lock until you unpin.

## Build for Android

```bash
eas login
eas build --platform android --profile production
```

## Publish to Play Store

See [Expo Submit Docs](https://docs.expo.dev/submit/android/). You need a Google Play Developer account and one manual upload before using `eas submit`.
