import 'package:flutter_test/flutter_test.dart';

import 'package:wonderkid/main.dart';

void main() {
  testWidgets('home screen shows the Wonderkid menu', (tester) async {
    await tester.pumpWidget(const WonderkidApp());

    expect(find.text('WONDERKID'), findsOneWidget);
    expect(find.text('YENİ KARİYER'), findsOneWidget);
    expect(find.text('AYARLAR'), findsOneWidget);
    expect(find.text('KARİYERE DEVAM ET'), findsNothing);
  });

  testWidgets('continue button appears when a save exists', (tester) async {
    await tester.pumpWidget(
      const WonderkidApp(home: HomeScreen(hasSavedCareer: true)),
    );

    expect(find.text('KARİYERE DEVAM ET'), findsOneWidget);
  });
}
