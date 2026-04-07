# Onboarding V2 Notes (TIDE-inspired)

Date: 2026-04-07  
Branch target: `release/onboarding-v2-tide`

## What Changed

1. Rebuilt onboarding as a 5-step flow in `PageView`:
- Welcome
- Goal
- Topic
- Difficulty
- Sign in (last step)

2. Added onboarding completion gating in router:
- New users are redirected to `/onboarding`.
- After onboarding is complete:
  - Signed-in users can go to `/`.
  - Signed-out users are sent to `/login` when they visit `/onboarding`.

3. Simplified login screen:
- `login_screen.dart` is now a returning-user sign-in screen only.

4. Persisted onboarding selections:
- Saves `question_topic`
- Saves `problem_difficulty`
- Saves `onboarding_completed`
- Saves `onboarding_goal` (new storage key)

## Files Updated

- `lib/features/onboarding/onboarding_screen.dart`
- `lib/app_router.dart`
- `lib/features/auth/login_screen.dart`
- `lib/core/constants/storage_keys.dart`

## Chrome Test Plan

Run:

```bash
flutter run -d chrome
```

Checklist:

1. Fresh user (clear shared prefs) should land on `/onboarding`.
2. Steps should progress in order and not skip sign-in page.
3. Choosing topic and difficulty should persist after finish.
4. "Continue with Google" on onboarding final step should sign in and go home.
5. "Continue without account" should still complete onboarding and go home.
6. Returning signed-out user with onboarding completed should see `/login` (not onboarding).
7. Returning signed-in user should reach `/` directly.

## Versioning Note

This rollout is published as a separate version branch:

- `release/onboarding-v2-tide`

