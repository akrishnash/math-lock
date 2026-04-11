# Earn Your Screen

A Flutter app for Android that puts a math (or geography) problem between you and your most distracting apps. Solve the problem to unlock the app for a configurable window. No solve, no access.

---

## How it works

1. **Onboarding** — set your goal, challenge topic, and difficulty in under a minute.
2. **Lock session** — choose a duration and the apps to block (or full-phone lock), then tap *Initiate Lockdown*.
3. **Blocked** — when you open a blocked app, an overlay appears. Solve the problem to earn a timed unlock window.
4. **Stats** — every unlock attempt is tracked so you can see your focus trends.

---

## Features

- Block specific apps or the entire phone
- Challenge topics: Mixed · Arithmetic · Algebra · Calculus · Geography
- Easy / Medium difficulty (harder = longer unlock friction)
- Configurable reward window (default 10 min) and session duration
- Google sign-in to sync stats across devices

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3 (Dart) |
| State | Riverpod 2 |
| Navigation | go\_router |
| Auth / sync | Firebase Auth + Google Sign-In |
| Native bridge | Custom `MethodChannel` (Android Kotlin) |
| Storage | SharedPreferences |
| Fonts | Google Fonts (Inter + Space Mono) |

---

## Getting started

### Prerequisites

- Flutter SDK ≥ 3.11
- Android Studio / Xcode (for device builds)
- A Firebase project with Android app configured

### Setup

```bash
git clone https://github.com/akrishnash/math-lock.git
cd math-lock
flutter pub get
```

Add your `google-services.json` from the Firebase Console to `android/app/`.

### Run

```bash
# Android (device or emulator)
flutter run

# Chrome (web preview — native blocking features disabled)
flutter run -d chrome
```

### Build release APK

```bash
bash scripts/build_release.sh
```

---

## Project structure

```
lib/
├── app.dart                  # MaterialApp + theme
├── app_router.dart           # go_router config
├── main.dart                 # entry point, initial route
├── core/
│   ├── constants/            # storage keys
│   ├── models/               # AppInfo
│   ├── platform/             # ZenPlatform (MethodChannel)
│   ├── theme/                # AppColors
│   └── utils/                # app_log
└── features/
    ├── auth/                 # Firebase auth, login screen
    ├── onboarding/           # 6-step onboarding flow
    ├── problems/             # math/geo challenge engine
    ├── settings/             # settings state + screen
    ├── stats/                # unlock history screen
    └── zen/                  # home, intervention, app-picker
```

---

## Android permissions required

| Permission | Purpose |
|---|---|
| Usage Stats | Detect when a blocked app is opened |
| Display Over Other Apps | Show the challenge overlay |
| Notification Listener | Hide notifications from blocked apps |

---

## License

MIT
