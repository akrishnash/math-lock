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

## Shut down all apps (full focus mode)

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
