# Claude Agent Notes — Math Lock / Earn Your Screen

> This file is maintained by Claude Code as a working log.
> It exists so that any Claude instance on any machine can pick up exactly where the last session left off.

---

## Project Summary

**App name (branding):** Earn Your Screen  
**Package name:** `com.earnyourscreen.app`  
**Repo:** `https://github.com/akrishnash/math-lock.git`  
**Active branch:** `release/onboarding-v2-tide`  
**Main branch:** `main`  
**Platform:** Flutter (Android only, native MethodChannel for app-blocking)  
**State management:** Riverpod  
**Navigation:** GoRouter  
**Backend:** Firebase Auth (Google Sign-In)

### What the app does
Lets users block distracting apps during focus sessions. To unlock a blocked app, they must solve a math/geography problem. Wrong answers add penalty minutes; correct answers earn grace minutes.

---

## What Has Been Done (Session Log)

### Session — 2026-04-08

**Context:** App had 0 downloads after 1 month. Identified root causes: sign-in wall before value delivery, intimidating onboarding, no viral hook, neon-gaming aesthetic mismatched to anxious-user target audience.

**Reference material used:**  
Mobbin — TIDE iOS Onboarding (9 screenshots, stored at `mobin/TIDE_Onboarding/`)  
Key insight from TIDE: show value first, personalise second, sign-in last.

#### Files changed this session:

| File | What changed |
|------|-------------|
| `lib/features/onboarding/onboarding_screen.dart` | Complete rewrite — 5-step PageView flow |
| `lib/features/auth/login_screen.dart` | Stripped down to returning-user sign-in only |
| `lib/app_router.dart` | Already had correct new-user → onboarding redirect logic |

#### New onboarding flow (5 pages):

```
Page 0 — Welcome
  - App icon (lock + ∫ badge)
  - "EARN YOUR SCREEN" headline
  - "Block distracting apps. Solve a problem to earn access back."
  - 3-step "How it works" row (Block → Solve → Earn)
  - GET STARTED button

Page 1 — Goal  (what's your biggest distraction?)
  - 2×2 grid: Social Media / Video & Streaming / Work Distractions / Everything
  - NEXT button disabled until a card is selected

Page 2 — Topic  (what should challenge you?)
  - 2×2 grid: Mixed / Arithmetic / Calculus / Geography
  - Saves to settingsProvider.questionTopic

Page 3 — Difficulty
  - Two large cards: EASY (2x+3=9) / MEDIUM (7x−15=48)
  - Saves to settingsProvider.problemDifficulty
  - LOOKS GOOD button → saves both prefs, then advances to sign-in

Page 4 — Sign-in  (last!)
  - "You're all set." with green checkmark
  - 3 benefit rows (sync, stats backup, free)
  - Continue with Google button
  - "Continue without account" text link (skips sign-in, completes onboarding)
```

#### Login screen (returning users only):
- Shown only when a user who completed onboarding previously signs out and comes back
- "Welcome back." heading, Google sign-in, "Continue without account" skip link
- Old complex brand mark / feature pills removed

---

## What Still Needs to Be Done

### High priority (affects downloads / retention)

- [ ] **Streak system** — track consecutive days with at least one zen session  
  - Add `lastSessionDate` and `streakCount` to `StatsState` (in `lib/features/stats/stats_state.dart`)  
  - Show streak counter on Home screen prominently  
  - Trigger increment when `ZenPlatform.stopZenMonitoring()` is called after a completed session

- [ ] **Home screen quick presets** — one-tap session start  
  - Add 3 preset buttons: Study (2h) / Deep Work (4h) / Phone-Free Morning (6h)  
  - Currently user has to pick hours+minutes manually via scroll wheels

- [ ] **Intervention screen redesign**  
  - Show session progress bar (how far through the zen session they are)  
  - Make "I'll wait" / "Go back" button more prominent (choosing NOT to unlock should feel easy)  
  - Show today's problem count: "12 problems solved today"  
  - Show correct answer after wrong answer with explanation

- [ ] **Permission onboarding UX** (biggest drop-off point)  
  - Before starting first session, show a friendly step-by-step "Setup Guide" screen  
  - Currently 3 raw permission dialogs appear with no context  
  - Explain *why* each permission is needed in plain English with illustrations

- [ ] **Shareable weekly stats card**  
  - "This week I solved 34 problems and saved 6h from doomscrolling"  
  - Exportable as image (use `screenshot` package or `RenderRepaintBoundary`)  
  - This is the viral loop the app currently has zero of

### Medium priority

- [ ] **Soften copy throughout** — "INITIATE LOCKDOWN" → "Start Session", etc.
- [ ] **Show correct answer on wrong** — currently just flashes red, user doesn't learn
- [ ] **Daily notification** — "Time for your focus session?" push via Firebase Cloud Messaging
- [ ] **Level / badge system** — Beginner → Scholar → Monk based on total sessions or streak

### Low priority / nice to have

- [ ] Tablet / landscape layout support
- [ ] Light theme option
- [ ] Export stats as CSV
- [ ] Advanced math topics (SAT prep, harder calculus) as optional unlock

---

## Architecture Reference

```
lib/
├── main.dart                    # Firebase init, ProviderScope
├── app.dart                     # Material3 dark theme
├── app_router.dart              # GoRouter — new users → /onboarding, returning → /login
│
├── core/
│   ├── constants/storage_keys.dart   # SharedPreferences keys
│   ├── theme/app_colors.dart         # Neon palette
│   └── platform/zen_platform.dart   # MethodChannel to Android native
│
└── features/
    ├── auth/
    │   ├── login_screen.dart         # Returning-user sign-in only
    │   ├── auth_service.dart         # Firebase/Google auth
    │   └── auth_state.dart           # authStateProvider, authSkippedProvider
    ├── onboarding/
    │   └── onboarding_screen.dart    # 5-step PageView (see above)
    ├── zen/
    │   ├── home_screen.dart          # Main hub
    │   ├── intervention_screen.dart  # Blocked-app interstitial
    │   ├── app_picker_screen.dart    # Multi-select app list
    │   └── zen_state.dart            # zenSessionProvider
    ├── problems/
    │   ├── problem_screen.dart       # Math/geography solver
    │   └── providers/question_providers.dart
    ├── settings/
    │   ├── settings_screen.dart
    │   └── settings_state.dart       # settingsProvider (11 fields)
    └── stats/
        ├── stats_screen.dart
        └── stats_state.dart          # statsProvider (total/weekly unlocks)
```

### Key providers

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateProvider` | `StreamProvider<User?>` | Firebase user stream |
| `authSkippedProvider` | `StateNotifierProvider<bool>` | Skip sign-in flag |
| `zenSessionProvider` | `StateNotifierProvider<ZenSessionState>` | Active session |
| `settingsProvider` | `StateNotifierProvider<SettingsState>` | All user prefs |
| `statsProvider` | `StateNotifierProvider<StatsState>` | Unlock history |

### Android native bridge (MethodChannel: `com.earnyourscreen.app/zen`)

Key methods: `startZenMonitoring`, `stopZenMonitoring`, `allowPackageForMinutes`,  
`allowFullUnlockForMinutes`, `getInstalledApps`, `getPendingUnlockIntent`

EventChannel: `com.earnyourscreen.app/blocked_app` — fires when user opens blocked app

---

## Design System

**Fonts:** Space Mono (headings/CTAs) + Inter (body)  
**Palette:** dark background `#0A0A0F`, surface `#16161D`, neonPink `#FF006E`,  
neonCyan `#00F5FF`, neonGreen `#39FF14`, neonPurple `#B537FF`, neonYellow `#FFFD60`  
**Style:** Sharp 90° corners on most elements, 2–4px borders, dark-only

---

## Reference Assets

`mobin/TIDE_Onboarding/` — 9 screenshots (TIDE iOS app from Mobbin) used as design reference  
`mobin/TIDE iOS Onboarding.zip` — original zip  
`docs/ONBOARDING_V2_NOTES.md` — earlier notes doc (kept for history)

---

## Testing the Onboarding Flow

```bash
# Normal run — new users will see onboarding
flutter run

# Force onboarding even if previously completed (for testing)
flutter run --dart-define=FORCE_ONBOARDING=true

# Reset onboarding via URL param (web/debug only)
# Navigate to /?resetOnboarding=1
```

---

## Git Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Stable, store-published builds |
| `release/onboarding-v2-tide` | Current active work (this branch) |

When ready to merge: PR from `release/onboarding-v2-tide` → `main`
