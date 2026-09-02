import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/career/career_profile.dart';
import 'package:wonderkid/career/fixture_generator.dart';
import 'package:wonderkid/career/offer_generator.dart';
import 'package:wonderkid/data/football_repository.dart';
import 'package:wonderkid/match/match_simulation.dart';
import 'package:wonderkid/match/match_simulation_screen.dart';

void main() {
  test(
    'match simulation is deterministic and creates a complete scoreline',
    () {
      final profile = CareerProfile.create(
        name: 'Furkan',
        nationality: 'Türkiye',
        shirtNumber: 7,
        position: 'LW',
      );
      const club = CareerClub(
        id: 1,
        name: 'Wonderkid FC',
        rating: 73,
        playerCount: 25,
      );
      const opponent = CareerClub(
        id: 2,
        name: 'Rakip FC',
        rating: 71,
        playerCount: 25,
      );
      const competitor = CareerPlayer(
        id: 10,
        shortName: 'Rakip Oyuncu',
        longName: 'Rakip Oyuncu',
        positions: ['LW'],
        overall: 72,
        potential: 75,
        age: 24,
        clubId: 1,
        clubName: 'Wonderkid FC',
        leagueId: 68,
        nationality: 'Türkiye',
        preferredFoot: 'Right',
        pace: 74,
        shooting: 68,
        passing: 69,
        dribbling: 73,
        defending: 40,
        physical: 65,
        gkDiving: null,
        gkHandling: null,
        gkKicking: null,
        gkPositioning: null,
        gkReflexes: null,
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
        competitors: [competitor],
        role: 'Rotasyon',
        contractYears: 1,
        weeklySalaryEuro: 9000,
      );
      final fixture = CareerFixtureMatch(
        week: 1,
        date: DateTime(2026, 8, 8),
        opponent: opponent,
        isHome: true,
        half: 1,
      );

      final first = CareerMatchEngine.generate(
        profile: profile,
        offer: offer,
        fixture: fixture,
        userClubPlayers: const [competitor],
        opponentPlayers: const [],
      );
      final second = CareerMatchEngine.generate(
        profile: profile,
        offer: offer,
        fixture: fixture,
        userClubPlayers: const [competitor],
        opponentPlayers: const [],
      );

      expect(first.homeGoals, second.homeGoals);
      expect(first.awayGoals, second.awayGoals);
      expect(first.squadStatus, second.squadStatus);
      expect(first.events.length, first.homeGoals + first.awayGoals);
      expect(first.playerShotsOnTarget, lessThanOrEqualTo(first.playerShots));
      expect(first.playerTurnovers, greaterThanOrEqualTo(0));
      expect(
        first.events.map((event) => event.minute),
        orderedEquals([...first.events.map((event) => event.minute)]..sort()),
      );
    },
  );

  testWidgets('match screen shows squad status and starts at zero', (
    tester,
  ) async {
    final profile = CareerProfile.create(
      name: 'Furkan',
      nationality: 'Türkiye',
      shirtNumber: 7,
      position: 'LW',
    );
    const club = CareerClub(
      id: 1,
      name: 'Wonderkid FC',
      rating: 73,
      playerCount: 25,
    );
    const opponent = CareerClub(
      id: 2,
      name: 'Rakip FC',
      rating: 71,
      playerCount: 25,
    );
    final fixture = CareerFixtureMatch(
      week: 1,
      date: DateTime(2026, 8, 8),
      opponent: opponent,
      isHome: true,
      half: 1,
    );
    final simulation = CareerMatchSimulation(
      fixture: fixture,
      homeClub: club,
      awayClub: opponent,
      homeGoals: 1,
      awayGoals: 0,
      events: const [
        CareerMatchEvent(minute: 24, isHomeGoal: true, scorer: 'Furkan'),
      ],
      squadStatus: PlayerSquadStatus.substitute,
      entryMinute: 3,
      exitMinute: 90,
      playerGoals: 1,
      playerAssists: 0,
      playerShots: 4,
      playerShotsOnTarget: 3,
      playerTurnovers: 6,
      playerRating: 7.8,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MatchSimulationScreen(
          profile: profile,
          leagueName: 'Süper Lig',
          simulation: simulation,
        ),
      ),
    );

    expect(find.byKey(const Key('matchSimulationScreen')), findsOneWidget);
    expect(find.text('MAÇ GÜNÜ'), findsOneWidget);
    expect(find.text('YEDEK'), findsOneWidget);
    expect(find.textContaining('3. dakikada'), findsNothing);
    expect(find.textContaining('Maça yedek başlayacaksın'), findsOneWidget);
    expect(find.text('0  -  0'), findsOneWidget);
    expect(find.text('MAÇI BAŞLAT'), findsOneWidget);

    await tester.tap(find.byKey(const Key('matchPrimaryButton')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.byKey(const Key('substitutionBanner')), findsOneWidget);
    expect(find.text('OYUNA GİRDİN!'), findsOneWidget);
    expect(find.text('OYUNDA'), findsOneWidget);

    for (var tick = 0; tick < 100; tick++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const Key('matchPerformanceSummary')), findsOneWidget);
    expect(find.byKey(const Key('playerMatchRating')), findsOneWidget);
    expect(find.text('GOL'), findsOneWidget);
    expect(find.text('ASİST'), findsOneWidget);
    expect(find.text('ŞUT'), findsOneWidget);
    expect(find.text('İSABETLİ ŞUT'), findsOneWidget);
    expect(find.text('TOP KAYBI'), findsOneWidget);
    expect(find.byKey(const Key('continueAfterMatchButton')), findsOneWidget);
  });
}
