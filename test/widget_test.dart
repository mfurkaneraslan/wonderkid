import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderkid/create_career_screen.dart';
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

  testWidgets('new career opens player creation screen', (tester) async {
    await tester.pumpWidget(const WonderkidApp());

    await tester.tap(find.text('YENİ KARİYER'));
    await tester.pumpAndSettle();

    expect(find.text('OYUNCUNU OLUŞTUR'), findsNothing);
    expect(find.text('Ad'), findsOneWidget);
    expect(find.text('Uyruk'), findsOneWidget);
    expect(find.text('Forma No'), findsOneWidget);
    expect(find.text('OYUNCU ADI'), findsNothing);
    expect(find.byKey(const Key('playerNameField')), findsOneWidget);
    expect(find.byKey(const Key('nationalityField')), findsOneWidget);
    expect(find.byKey(const Key('shirtNumberField')), findsOneWidget);
    expect(find.byType(CreateCareerScreen), findsOneWidget);
  });

  testWidgets('shirt number selector offers numbers from 1 to 99', (
    tester,
  ) async {
    await tester.pumpWidget(const WonderkidApp(home: CreateCareerScreen()));

    await tester.tap(find.byKey(const Key('shirtNumberField')));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('99'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('99'), findsOneWidget);
  });

  testWidgets('pitch contains and highlights every requested position', (
    tester,
  ) async {
    await tester.pumpWidget(const WonderkidApp(home: CreateCareerScreen()));

    const positions = [
      'GK',
      'LB',
      'CB',
      'RB',
      'CDM',
      'CM',
      'CAM',
      'LM',
      'RM',
      'RW',
      'LW',
      'ST',
    ];

    for (final position in positions) {
      expect(find.byKey(Key('position_$position')), findsOneWidget);
    }

    final striker = find.byKey(const Key('position_ST'));
    await tester.ensureVisible(striker);
    await tester.tap(striker);
    await tester.pumpAndSettle();

    expect(find.text('ST'), findsNWidgets(2));
  });

  testWidgets('completed player form opens three club offers', (tester) async {
    await tester.pumpWidget(const WonderkidApp(home: CreateCareerScreen()));

    await tester.enterText(
      find.byKey(const Key('playerNameField')),
      'Furkan Eraslan',
    );
    await tester.tap(find.byKey(const Key('nationalityField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Türkiye').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shirtNumberField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();
    final striker = find.byKey(const Key('position_ST'));
    await tester.ensureVisible(striker);
    await tester.tap(striker);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('continueButton')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.text('KULÜP TEKLİFLERİ'), findsOneWidget);
    expect(find.text('3 kulüp seni kadrosuna katmak istiyor.'), findsOneWidget);
    expect(find.byKey(const Key('acceptOfferButton')), findsOneWidget);
  });
}
