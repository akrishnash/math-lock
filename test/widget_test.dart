import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_lock/app.dart';

void main() {
  testWidgets('App loads with PriorityFlow title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MathLockApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PRIORITYFLOW'), findsOneWidget);
  });
}
