import 'dart:math';

import '../data/football_repository.dart';
import '../match/match_simulation.dart';

class CareerLeagueMatchResult {
  const CareerLeagueMatchResult({
    required this.week,
    required this.homeClubId,
    required this.awayClubId,
    required this.homeGoals,
    required this.awayGoals,
  });

  factory CareerLeagueMatchResult.fromJson(Map<String, dynamic> json) {
    return CareerLeagueMatchResult(
      week: json['week'] as int,
      homeClubId: json['homeClubId'] as int,
      awayClubId: json['awayClubId'] as int,
      homeGoals: json['homeGoals'] as int,
      awayGoals: json['awayGoals'] as int,
    );
  }

  final int week;
  final int homeClubId;
  final int awayClubId;
  final int homeGoals;
  final int awayGoals;

  Map<String, dynamic> toJson() => {
    'week': week,
    'homeClubId': homeClubId,
    'awayClubId': awayClubId,
    'homeGoals': homeGoals,
    'awayGoals': awayGoals,
  };
}

class CareerStanding {
  const CareerStanding({
    required this.club,
    required this.played,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
  });

  final CareerClub club;
  final int played;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  int get goalDifference => goalsFor - goalsAgainst;
}

class CareerLeagueSimulator {
  static List<CareerLeagueMatchResult> simulateWeek({
    required CareerLeague league,
    required CareerMatchSimulation playerMatch,
    required int seed,
  }) {
    final week = playerMatch.fixture.week;
    final results = <CareerLeagueMatchResult>[
      CareerLeagueMatchResult(
        week: week,
        homeClubId: playerMatch.homeClub.id,
        awayClubId: playerMatch.awayClub.id,
        homeGoals: playerMatch.homeGoals,
        awayGoals: playerMatch.awayGoals,
      ),
    ];
    final remaining =
        league.clubs
            .where(
              (club) =>
                  club.id != playerMatch.homeClub.id &&
                  club.id != playerMatch.awayClub.id,
            )
            .toList(growable: true)
          ..sort((a, b) => a.id.compareTo(b.id));
    final pairingRandom = Random(seed ^ league.id ^ (week * 7919));
    remaining.shuffle(pairingRandom);

    for (var index = 0; index + 1 < remaining.length; index += 2) {
      final first = remaining[index];
      final second = remaining[index + 1];
      final home = pairingRandom.nextBool() ? first : second;
      final away = home.id == first.id ? second : first;
      final scoreRandom = Random(seed ^ week ^ home.id ^ (away.id * 31));
      final ratingDifference = (home.rating + 2) - away.rating;
      results.add(
        CareerLeagueMatchResult(
          week: week,
          homeClubId: home.id,
          awayClubId: away.id,
          homeGoals: _goals(scoreRandom, 1.3 + ratingDifference / 14),
          awayGoals: _goals(scoreRandom, 1.1 - ratingDifference / 14),
        ),
      );
    }
    return List.unmodifiable(results);
  }

  static List<CareerStanding> standings({
    required CareerLeague league,
    required List<CareerLeagueMatchResult> results,
  }) {
    final played = <int, int>{};
    final goalsFor = <int, int>{};
    final goalsAgainst = <int, int>{};
    final points = <int, int>{};

    for (final result in results) {
      played.update(result.homeClubId, (value) => value + 1, ifAbsent: () => 1);
      played.update(result.awayClubId, (value) => value + 1, ifAbsent: () => 1);
      goalsFor.update(
        result.homeClubId,
        (value) => value + result.homeGoals,
        ifAbsent: () => result.homeGoals,
      );
      goalsFor.update(
        result.awayClubId,
        (value) => value + result.awayGoals,
        ifAbsent: () => result.awayGoals,
      );
      goalsAgainst.update(
        result.homeClubId,
        (value) => value + result.awayGoals,
        ifAbsent: () => result.awayGoals,
      );
      goalsAgainst.update(
        result.awayClubId,
        (value) => value + result.homeGoals,
        ifAbsent: () => result.homeGoals,
      );
      if (result.homeGoals == result.awayGoals) {
        points.update(
          result.homeClubId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        points.update(
          result.awayClubId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      } else {
        final winnerId = result.homeGoals > result.awayGoals
            ? result.homeClubId
            : result.awayClubId;
        points.update(winnerId, (value) => value + 3, ifAbsent: () => 3);
      }
    }

    final table = league.clubs
        .map(
          (club) => CareerStanding(
            club: club,
            played: played[club.id] ?? 0,
            goalsFor: goalsFor[club.id] ?? 0,
            goalsAgainst: goalsAgainst[club.id] ?? 0,
            points: points[club.id] ?? 0,
          ),
        )
        .toList(growable: false);
    table.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byDifference = b.goalDifference.compareTo(a.goalDifference);
      if (byDifference != 0) return byDifference;
      final byGoals = b.goalsFor.compareTo(a.goalsFor);
      if (byGoals != 0) return byGoals;
      return a.club.name.compareTo(b.club.name);
    });
    return table;
  }

  static int _goals(Random random, double expectation) {
    final chance = expectation.clamp(0.25, 3.4) / 6;
    var goals = 0;
    for (var attempt = 0; attempt < 6; attempt++) {
      if (random.nextDouble() < chance) goals++;
    }
    return goals.clamp(0, 5);
  }
}
