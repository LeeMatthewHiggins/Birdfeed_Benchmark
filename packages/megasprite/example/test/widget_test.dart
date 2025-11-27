import 'package:atlas_creator/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtlasCreatorApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const AtlasCreatorApp());

    expect(find.text('Atlas Creator'), findsOneWidget);
  });
}
