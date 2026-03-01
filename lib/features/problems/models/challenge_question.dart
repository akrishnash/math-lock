/// Input type for the challenge screen.
enum ChallengeInputKind {
  numeric,
  multipleChoice,
}

/// A single challenge question (math, geography, etc.).
class ChallengeQuestion {
  const ChallengeQuestion({
    required this.prompt,
    required this.correctAnswer,
    this.inputKind = ChallengeInputKind.numeric,
    this.options = const [],
  });

  final String prompt;
  final String correctAnswer;
  final ChallengeInputKind inputKind;
  final List<String> options;
}
