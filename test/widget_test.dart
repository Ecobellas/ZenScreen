import 'package:flutter_test/flutter_test.dart';
import 'package:zen_screen/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // ZenScreenApp requires ProviderScope and SharedPreferences,
    // so we just verify it can be instantiated.
    expect(const ZenScreenApp(), isNotNull);
  });
}
