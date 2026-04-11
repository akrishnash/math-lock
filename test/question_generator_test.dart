import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_lock/features/problems/models/challenge_question.dart';
import 'package:math_lock/features/problems/providers/question_providers.dart';
import 'package:math_lock/features/settings/settings_state.dart';

void main() {
  group('generateQuestion', () {
    const seed = 42;

    // All topic IDs currently in TopicRegistry (excluding 'logic' — not implemented).
    const topics = ['mixed', 'arithmetic', 'algebra', 'integration', 'geography'];

    for (final topic in topics) {
      for (final difficulty in ProblemDifficulty.values) {
        test('$topic / ${difficulty.name} produces a non-empty question', () {
          final q = generateQuestion(
            topicId: topic,
            difficulty: difficulty,
            random: Random(seed),
          );
          expect(q.prompt.isNotEmpty, isTrue,
              reason: 'prompt must not be empty');
          expect(q.correctAnswer.isNotEmpty, isTrue,
              reason: 'correctAnswer must not be empty');
        });
      }
    }

    test('geography generates multiple-choice with exactly 4 options', () {
      final q = generateQuestion(
        topicId: 'geography',
        difficulty: ProblemDifficulty.easy,
        random: Random(seed),
      );
      expect(q.inputKind, ChallengeInputKind.multipleChoice);
      expect(q.options.length, 4);
      expect(q.options.contains(q.correctAnswer), isTrue);
    });

    test('arithmetic answer is parseable as an integer', () {
      // Run several iterations to catch cases with non-integer solutions that
      // should be rejected by the generator's retry logic.
      for (var i = 0; i < 30; i++) {
        final q = generateQuestion(
          topicId: 'arithmetic',
          difficulty: ProblemDifficulty.easy,
          random: Random(i),
        );
        expect(
          int.tryParse(q.correctAnswer),
          isNotNull,
          reason: 'arithmetic answer "${q.correctAnswer}" must be a whole number',
        );
      }
    });

    test('integration answer is parseable as a number', () {
      for (var i = 0; i < 20; i++) {
        final q = generateQuestion(
          topicId: 'integration',
          difficulty: ProblemDifficulty.easy,
          random: Random(i),
        );
        expect(
          num.tryParse(q.correctAnswer),
          isNotNull,
          reason: 'integration answer "${q.correctAnswer}" must be numeric',
        );
      }
    });

    test('unknown topic falls back without throwing', () {
      expect(
        () => generateQuestion(
          topicId: 'logic', // not implemented yet
          difficulty: ProblemDifficulty.easy,
          random: Random(seed),
        ),
        returnsNormally,
      );
    });
  });
}
