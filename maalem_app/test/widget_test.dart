import 'package:flutter_test/flutter_test.dart';

import 'package:maalem_app/main.dart';

void main() {
  testWidgets('Maalem app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaalemApp());

    expect(find.byType(MaalemApp), findsOneWidget);
  });
}
