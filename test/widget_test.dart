import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:donghua_player/main.dart';

void main() {
  testWidgets('App renders SearchScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DonghuaApp()));

    expect(find.text('DonghuaMobile'), findsOneWidget);
  });
}
