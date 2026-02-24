import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_lock/app.dart';

void main() {
  testWidgets('App loads with Zen Mode title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MathLockApp(),
      ),
    );
    expect(find.text('Zen Mode'), findsOneWidget);
  });
}
