import 'dart:math';

import '../../../core/data/geography_capitals.dart';
import '../models/challenge_question.dart';
import '../../settings/settings_state.dart';

/// Generates a challenge question for the given topic.
ChallengeQuestion generateQuestion({
  required String topicId,
  required ProblemDifficulty difficulty,
  required Random random,
}) {
  if (topicId == 'geography') {
    return _generateGeography(random);
  }
  return _generateMath(topicId, difficulty, random);
}

ChallengeQuestion _generateGeography(Random r) {
  final idx = r.nextInt(geographyCapitals.length);
  final entry = geographyCapitals[idx];
  final country = entry.key;
  final correct = entry.value;
  final wrongCapitals = geographyCapitals
      .where((e) => e.value != correct)
      .map((e) => e.value)
      .toList();
  wrongCapitals.shuffle(r);
  final wrong = wrongCapitals.take(3).toList();
  final options = [correct, ...wrong];
  options.shuffle(r);
  return ChallengeQuestion(
    prompt: 'What is the capital of $country?',
    correctAnswer: correct,
    inputKind: ChallengeInputKind.multipleChoice,
    options: options,
  );
}

ChallengeQuestion _generateMath(String topicId, ProblemDifficulty difficulty, Random r) {
  if (topicId == 'integration') {
    return _generateIntegrationQuestion(difficulty, r);
  }
  if (topicId == 'mixed') {
    return r.nextBool()
        ? _generateLinearQuestion('arithmetic', difficulty, r)
        : _generateIntegrationQuestion(difficulty, r);
  }
  return _generateLinearQuestion(topicId, difficulty, r);
}

ChallengeQuestion _generateLinearQuestion(String topicId, ProblemDifficulty difficulty, Random r) {
  int a, b, c;
  if (difficulty == ProblemDifficulty.easy) {
    a = r.nextInt(5) + 1;
    b = r.nextInt(10) - 5;
    c = r.nextInt(30) - 10;
  } else {
    a = r.nextInt(8) + 2;
    b = r.nextInt(20) - 10;
    c = r.nextInt(80) - 40;
  }
  final x = (c - b) / a;
  if (x != x.roundToDouble()) {
    return _generateLinearQuestion(topicId, difficulty, r);
  }
  final bStr = b >= 0 ? '+ $b' : '- ${-b}';
  final prompt = '${a}x $bStr = $c';
  final answer = ((c - b) / a).round();
  return ChallengeQuestion(
    prompt: prompt,
    correctAnswer: '$answer',
    inputKind: ChallengeInputKind.numeric,
  );
}

ChallengeQuestion _generateIntegrationQuestion(ProblemDifficulty difficulty, Random r) {
  int k, n, upper;
  if (difficulty == ProblemDifficulty.easy) {
    k = r.nextInt(3) + 1;
    n = 1;
    upper = r.nextInt(4) + 1;
  } else {
    k = r.nextInt(4) + 1;
    n = r.nextInt(2) + 1;
    upper = r.nextInt(5) + 1;
  }
  final answer = k * (pow(upper, n + 1) / (n + 1));
  final prompt = '∫ $k*x^$n dx from 0 to $upper';
  final answerStr = answer == answer.roundToDouble() ? '${answer.round()}' : answer.toString();
  return ChallengeQuestion(
    prompt: prompt,
    correctAnswer: answerStr,
    inputKind: ChallengeInputKind.numeric,
  );
}
