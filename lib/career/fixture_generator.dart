import 'dart:math';

import '../data/football_repository.dart';

class CareerFixtureMatch {
  const CareerFixtureMatch({
    required this.week,
    required this.date,
    required this.opponent,
    required this.isHome,
    required this.half,
  });

  final int week;
  final DateTime date;
  final CareerClub opponent;
  final bool isHome;
  final int half;
}

class CareerSeasonFixture {
  const CareerSeasonFixture({
    required this.seasonYear,
    required this.startDate,
    required this.matches,
    required this.firstHalfMatchCount,
  });

  final int seasonYear;
  final DateTime startDate;
  final List<CareerFixtureMatch> matches;
  final int firstHalfMatchCount;

  CareerFixtureMatch get nextMatch => matches.first;

  List<CareerFixtureMatch> get firstHalf =>
      matches.take(firstHalfMatchCount).toList(growable: false);

  List<CareerFixtureMatch> get secondHalf =>
      matches.skip(firstHalfMatchCount).toList(growable: false);
}

class CareerFixtureGenerator {
  static const seasonYear = 2026;
  static final seasonStartDate = DateTime(2026, 8, 8);

  static CareerSeasonFixture generate({
    required CareerLeague league,
    required CareerClub club,
    required int seed,
  }) {
    final opponents = league.clubs
        .where((candidate) => candidate.id != club.id)
        .toList(growable: true);

    if (opponents.isEmpty) {
      throw ArgumentError('Fikstür için ligde en az iki takım olmalı.');
    }

    final random = Random(seed ^ league.id ^ club.id);
    opponents.shuffle(random);
    final startsAtHome = random.nextBool();
    final firstHalf = <CareerFixtureMatch>[];

    for (var index = 0; index < opponents.length; index++) {
      final isHome = index.isEven ? startsAtHome : !startsAtHome;
      firstHalf.add(
        CareerFixtureMatch(
          week: index + 1,
          date: seasonStartDate.add(Duration(days: index * 7)),
          opponent: opponents[index],
          isHome: isHome,
          half: 1,
        ),
      );
    }

    final secondHalf = <CareerFixtureMatch>[];
    for (var index = 0; index < firstHalf.length; index++) {
      final firstLeg = firstHalf[index];
      final week = firstHalf.length + index + 1;
      secondHalf.add(
        CareerFixtureMatch(
          week: week,
          date: seasonStartDate.add(Duration(days: (week - 1) * 7)),
          opponent: firstLeg.opponent,
          isHome: !firstLeg.isHome,
          half: 2,
        ),
      );
    }

    return CareerSeasonFixture(
      seasonYear: seasonYear,
      startDate: seasonStartDate,
      matches: List.unmodifiable([...firstHalf, ...secondHalf]),
      firstHalfMatchCount: firstHalf.length,
    );
  }
}
