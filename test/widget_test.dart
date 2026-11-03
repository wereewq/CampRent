import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camp_rent/main.dart';

void main() {
  testWidgets('CampRentApp запускается корректно', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(CampRentApp(prefs: prefs));
    expect(find.byType(CampRentApp), findsOneWidget);
  });
}
