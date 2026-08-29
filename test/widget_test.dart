import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wonderkid/career/career_save_repository.dart';
import 'package:wonderkid/create_career_screen.dart';
import 'package:wonderkid/career/career_profile.dart';
import 'package:wonderkid/career/offer_generator.dart';
import 'package:wonderkid/career_dashboard_screen.dart';
import 'package:wonderkid/data/football_repository.dart';
import 'package:wonderkid/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen shows the Wonderkid menu', (tester) async {
    await tester.pumpWidget(const WonderkidApp());
    await tester.pumpAndSettle();

    expect(find.text('WONDERKID'), findsOneWidget);
    expect(find.text('YENİ KARİYER'), findsOneWidget);
    expect(find.text('AYARLAR'), findsOneWidget);
    expect(find.text('KARİYERE DEVAM ET'), findsNothing);
  });

  testWidgets('continue button appears when a save exists', (tester) async {
    final profile = CareerProfile.create(
      name: 'Furkan Eraslan',
      nationality: 'Türkiye',
      shirtNumber: 7,
      position: 'ST',
    );
    const club = CareerClub(
      id: 1,
      name: 'Wonderkid FC',
      rating: 72,
      playerCount: 25,
    );
    const opponent = CareerClub(
      id: 2,
      name: 'Rakip FC',
      rating: 70,
      playerCount: 25,
    );
    const league = CareerLeague(
      id: 68,
      name: 'Süper Lig',
      country: 'Türkiye',
      clubs: [club, opponent],
    );
    const offer = ClubOffer(
      club: club,
      league: league,
      competitors: [],
      role: 'Rotasyon',
      contractYears: 1,
      weeklySalaryEuro: 9000,
    );
    await tester.pumpWidget(
      WonderkidApp(
        home: HomeScreen(
          initialCareer: SavedCareer(profile: profile, offer: offer),
        ),
      ),
    );

    expect(find.text('KARİYERE DEVAM ET'), findsOneWidget);
    await tester.tap(find.text('KARİYERE DEVAM ET'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('careerDashboard')), findsOneWidget);
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

  testWidgets('third avatar is default and all six can be selected', (
    tester,
  ) async {
    await tester.pumpWidget(const WonderkidApp(home: CreateCareerScreen()));

    expect(find.byKey(const Key('selectedAvatar_3')), findsOneWidget);
    await tester.tap(find.byKey(const Key('avatarSelector')));
    await tester.pumpAndSettle();

    for (var avatarId = 1; avatarId <= 6; avatarId++) {
      expect(find.byKey(Key('avatarOption_$avatarId')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('avatarOption_5')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selectedAvatar_5')), findsOneWidget);
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

  testWidgets('completed player is confirmed before club offers', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();

    expect(find.text('OYUNCUNU ONAYLA'), findsOneWidget);
    expect(find.byKey(const Key('fcPlayerCard')), findsOneWidget);
    expect(find.byKey(const Key('cardOverall')), findsOneWidget);
    expect(find.byKey(const Key('cardPosition')), findsOneWidget);
    expect(find.text('PAC'), findsOneWidget);
    expect(find.text('SHO'), findsOneWidget);
    expect(find.text('PAS'), findsOneWidget);
    expect(find.text('DRI'), findsOneWidget);
    expect(find.text('DEF'), findsOneWidget);
    expect(find.text('PHY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmPlayerButton')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.text('KULÜP TEKLİFLERİ'), findsOneWidget);
    expect(find.text('3 kulüp seni kadrosuna katmak istiyor.'), findsOneWidget);
    expect(find.textContaining('forma rekabetini'), findsNothing);
    expect(find.text('1 yıl'), findsNWidgets(3));
    expect(find.textContaining('/ hafta'), findsNWidgets(3));
    expect(find.byKey(const Key('backFromOffersButton')), findsOneWidget);
    expect(find.byKey(const Key('acceptOfferButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('backFromOffersButton')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateCareerScreen), findsOneWidget);
  });

  testWidgets('career dashboard switches between all four tabs', (
    tester,
  ) async {
    final profile = CareerProfile.create(
      name: 'Furkan Eraslan',
      nationality: 'Türkiye',
      shirtNumber: 7,
      position: 'ST',
    );
    const club = CareerClub(
      id: 1,
      name: 'Wonderkid FC',
      rating: 72,
      playerCount: 25,
    );
    const opponent = CareerClub(
      id: 2,
      name: 'Rakip FC',
      rating: 71,
      playerCount: 25,
    );
    const league = CareerLeague(
      id: 68,
      name: 'Süper Lig',
      country: 'Türkiye',
      clubs: [club, opponent],
    );
    const offer = ClubOffer(
      club: club,
      league: league,
      competitors: [],
      role: 'Rotasyon',
      contractYears: 1,
      weeklySalaryEuro: 9000,
    );

    await tester.pumpWidget(
      WonderkidApp(
        home: CareerDashboardScreen(profile: profile, offer: offer),
      ),
    );

    expect(find.byKey(const Key('careerDashboard')), findsOneWidget);
    expect(find.text('KARİYER MERKEZİ'), findsOneWidget);
    expect(find.text('AĞUSTOS 2026'), findsOneWidget);
    expect(find.text('2026 • 1. HAFTA'), findsOneWidget);
    expect(find.text('SIRADAKİ MAÇ'), findsOneWidget);

    final fixtureButton = find.byKey(const Key('openFixtureButton'));
    await tester.ensureVisible(fixtureButton);
    await tester.pumpAndSettle();
    await tester.tap(fixtureButton);
    await tester.pumpAndSettle();
    expect(find.text('İLK YARI'), findsNothing);
    expect(find.text('İKİNCİ YARI'), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
    expect(find.text('Ev sahibi'), findsNothing);
    expect(find.text('Deplasman'), findsNothing);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trainingTab')));
    await tester.pumpAndSettle();
    expect(find.text('BU HAFTANIN PROGRAMI'), findsOneWidget);

    await tester.tap(find.byKey(const Key('teamTab')));
    await tester.pumpAndSettle();
    expect(find.text('FORMA REKABETİ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shopTab')));
    await tester.pumpAndSettle();
    expect(find.text('KATEGORİLER'), findsOneWidget);
  });
}
