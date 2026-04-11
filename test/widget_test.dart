import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_lock/app.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MathLockApp(),
      ),
    );
    // A single pump is enough to verify the widget tree builds without errors.
    await tester.pump();
    // No specific text is asserted because the first visible screen depends on
    // SharedPreferences state which is not set in the test environment.
    expect(tester.takeException(), isNull);
  });
}
