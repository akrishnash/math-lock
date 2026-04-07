class StorageKeys {
  StorageKeys._();

  static const String blockedPackages = 'blocked_packages';
  static const String zenSessionEndMillis = 'zen_session_end_millis';
  static const String sessionDurationMinutes = 'session_duration_minutes';
  static const String rewardDurationMinutes = 'reward_duration_minutes';
   static const String allowReopenWithinWindow =
      'allow_reopen_within_window'; // bool
  static const String problemType = 'problem_type'; // 'integration' | 'linear'
  static const String problemDifficulty = 'problem_difficulty'; // 'easy' | 'medium'
  static const String penaltyMinutes = 'penalty_minutes';
  static const String accentColor = 'accent_color'; // 'pink' | 'cyan' | 'purple' | 'yellow' | 'green'
  static const String enableSounds = 'enable_sounds';
  static const String enableVibration = 'enable_vibration';
  static const String questionTopic = 'question_topic'; // 'mixed' | 'arithmetic' | ...
  static const String lockMode = 'lock_mode'; // 'apps' | 'full'
  static const String unlockViaProblemCount = 'unlock_via_problem_count';
  static const String unlockViaProblemHistory = 'unlock_via_problem_history';
  static const String authSkipped = 'auth_skipped'; // bool: user chose "Skip" on login
  static const String onboardingCompleted = 'onboarding_completed'; // bool
  static const String onboardingGoal = 'onboarding_goal'; // 'focus' | 'discipline' | 'screen-time'
}
