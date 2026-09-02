import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/career/fixture_generator.dart';
import 'package:wonderkid/career/league_progress.dart';
import 'package:wonderkid/data/football_repository.dart';
import 'package:wonderkid/match/match_simulation.dart';

void main() {
  const userClub = CareerClub(
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
  const third = CareerClub(
    id: 3,
    name: 'Üçüncü FC',
    rating: 68,
    playerCount: 25,
  );
  const fourth = CareerClub(
    id: 4,
    name: 'Dördüncü FC',
    rating: 69,
    playerCount: 25,
  );
  const league = CareerLeague(
    id: 68,
    name: 'Süper Lig',
    country: 'Türkiye',
    clubs: [userClub, opponent, third, fourth],
  );

  test('simulates every club and builds a live table for the week', () {
    final fixture = CareerFixtureMatch(
      week: 1,
      date: DateTime(2026, 8, 8),
      opponent: opponent,
      isHome: true,
      half: 1,
    );
    final playerMatch = CareerMatchSimulation(
      fixture: fixture,
      homeClub: userClub,
      awayClub: opponent,
      homeGoals: 1,
      awayGoals: 0,
      events: const [],
      squadStatus: PlayerSquadStatus.starting,
      entryMinute: 1,
      exitMinute: 90,
      playerGoals: 0,
      playerAssists: 0,
      playerShots: 1,
      playerShotsOnTarget: 0,
      playerTurnovers: 2,
      playerRating: 6.8,
    );

    final results = CareerLeagueSimulator.simulateWeek(
      league: league,
      playerMatch: playerMatch,
      seed: 42,
    );
    final table = CareerLeagueSimulator.standings(
      league: league,
      results: results,
    );

    expect(results, hasLength(2));
    expect(table.every((standing) => standing.played == 1), isTrue);
    final userStanding = table.firstWhere(
      (standing) => standing.club.id == userClub.id,
    );
    expect(userStanding.points, 3);
    expect(userStanding.goalDifference, 1);
  });
}
