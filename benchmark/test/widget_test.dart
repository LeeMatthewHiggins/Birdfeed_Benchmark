import 'package:flutter_test/flutter_test.dart';

import 'package:benchmark/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const RiveBenchmarkApp());
    expect(find.text('Rive Benchmark'), findsOneWidget);
  });
}
