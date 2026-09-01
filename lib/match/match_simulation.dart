import 'dart:math';

import '../career/career_profile.dart';
import '../career/fixture_generator.dart';
import '../career/offer_generator.dart';
import '../data/football_repository.dart';

enum PlayerSquadStatus { starting, substitute, out }

extension PlayerSquadStatusLabel on PlayerSquadStatus {
  String get label => switch (this) {
    PlayerSquadStatus.starting => 'İLK 11',
    PlayerSquadStatus.substitute => 'YEDEK',
    PlayerSquadStatus.out => 'KADRO DIŞI',
  };
}

class CareerMatchEvent {
  const CareerMatchEvent({
    required this.minute,
    required this.isHomeGoal,
    required this.scorer,
    this.assist,
  });

  final int minute;
  final bool isHomeGoal;
  final String scorer;
  final String? assist;
}

class CareerMatchSimulation {
  const CareerMatchSimulation({
    required this.fixture,
    required this.homeClub,
    required this.awayClub,
    required this.homeGoals,
    required this.awayGoals,
    required this.events,
    required this.squadStatus,
    required this.entryMinute,
    required this.exitMinute,
    required this.playerGoals,
    required this.playerAssists,
    required this.playerShots,
    required this.playerShotsOnTarget,
    required this.playerTurnovers,
    required this.playerRating,
  });

  final CareerFixtureMatch fixture;
  final CareerClub homeClub;
  final CareerClub awayClub;
  final int homeGoals;
  final int awayGoals;
  final List<CareerMatchEvent> events;
  final PlayerSquadStatus squadStatus;
  final int? entryMinute;
  final int? exitMinute;
  final int playerGoals;
  final int playerAssists;
  final int playerShots;
  final int playerShotsOnTarget;
  final int playerTurnovers;
  final double? playerRating;

  int get minutesPlayed {
    if (entryMinute == null || exitMinute == null) return 0;
    return max(0, exitMinute! - entryMinute! + 1);
  }
}

class CareerMatchEngine {
  static CareerMatchSimulation generate({
    required CareerProfile profile,
    required ClubOffer offer,
    required CareerFixtureMatch fixture,
    required List<CareerPlayer> userClubPlayers,
    required List<CareerPlayer> opponentPlayers,
  }) {
    final random = Random(profile.seed ^ fixture.week ^ offer.club.id);
    final squadStatus = _selectSquadStatus(profile, offer, random);
    final entryMinute = switch (squadStatus) {
      PlayerSquadStatus.starting => 1,
      PlayerSquadStatus.substitute => 55 + random.nextInt(21),
      PlayerSquadStatus.out => null,
    };
    final exitMinute = switch (squadStatus) {
      PlayerSquadStatus.starting =>
        random.nextDouble() < 0.32 ? 68 + random.nextInt(18) : 90,
      PlayerSquadStatus.substitute => 90,
      PlayerSquadStatus.out => null,
    };

    final homeClub = fixture.isHome ? offer.club : fixture.opponent;
    final awayClub = fixture.isHome ? fixture.opponent : offer.club;
    final ratingDiff = (homeClub.rating + 2.0) - awayClub.rating.toDouble();
    final homeGoals = _generateGoals(random, 1.35 + ratingDiff / 13);
    final awayGoals = _generateGoals(random, 1.15 - ratingDiff / 13);
    final events = <CareerMatchEvent>[];
    final occupiedMinutes = <int>{};

    void addGoals({required bool home, required int count}) {
      final isUserTeam = fixture.isHome == home;
      final roster = isUserTeam ? userClubPlayers : opponentPlayers;
      for (var index = 0; index < count; index++) {
        var minute = 4 + random.nextInt(86);
        while (occupiedMinutes.contains(minute)) {
          minute = 4 + random.nextInt(86);
        }
        occupiedMinutes.add(minute);

        final userOnPitch =
            isUserTeam &&
            entryMinute != null &&
            exitMinute != null &&
            minute >= entryMinute &&
            minute <= exitMinute;
        final userScores =
            userOnPitch &&
            random.nextDouble() < _playerGoalShare(profile.position);
        final scorer = userScores
            ? profile.name
            : _pickScorer(
                roster,
                random,
                fallback: home ? homeClub.name : awayClub.name,
              );

        String? assist;
        if (random.nextDouble() < 0.68) {
          final userAssists =
              userOnPitch &&
              !userScores &&
              random.nextDouble() < _playerAssistShare(profile.position);
          assist = userAssists
              ? profile.name
              : _pickAssistant(roster, random, scorer: scorer);
        }
        events.add(
          CareerMatchEvent(
            minute: minute,
            isHomeGoal: home,
            scorer: scorer,
            assist: assist,
          ),
        );
      }
    }

    addGoals(home: true, count: homeGoals);
    addGoals(home: false, count: awayGoals);
    events.sort((a, b) => a.minute.compareTo(b.minute));

    final playerGoals = events
        .where((event) => event.scorer == profile.name)
        .length;
    final playerAssists = events
        .where((event) => event.assist == profile.name)
        .length;
    final minutesPlayed = entryMinute == null || exitMinute == null
        ? 0
        : max(0, exitMinute - entryMinute + 1);
    final shotVolume = switch (profile.position) {
      'ST' => 4.2,
      'LW' || 'RW' => 3.4,
      'CAM' || 'LM' || 'RM' => 2.5,
      'CM' || 'CDM' => 1.7,
      'LB' || 'RB' || 'CB' => 0.8,
      _ => 0.15,
    };
    final playerShots = minutesPlayed == 0
        ? 0
        : max(
            playerGoals,
            (shotVolume * minutesPlayed / 90 + random.nextDouble() * 1.8)
                .round(),
          );
    final accuracy = (0.28 + profile.shooting / 180).clamp(0.32, 0.78);
    final playerShotsOnTarget = max(
      playerGoals,
      min(playerShots, (playerShots * accuracy).round()),
    );
    final turnoverBase = switch (profile.position) {
      'LW' || 'RW' || 'CAM' => 11.0,
      'ST' || 'LM' || 'RM' => 8.5,
      'CM' || 'CDM' => 7.0,
      'LB' || 'RB' => 6.0,
      'CB' => 4.0,
      _ => 2.0,
    };
    final playerTurnovers = minutesPlayed == 0
        ? 0
        : max(
            0,
            ((turnoverBase - profile.dribbling / 18) * minutesPlayed / 90 +
                    random.nextDouble() * 2.5)
                .round(),
          );
    final userGoals = fixture.isHome ? homeGoals : awayGoals;
    final opponentGoals = fixture.isHome ? awayGoals : homeGoals;
    final rating = squadStatus == PlayerSquadStatus.out
        ? null
        : (6.35 +
                  playerGoals * 1.05 +
                  playerAssists * 0.65 +
                  playerShotsOnTarget * 0.08 -
                  playerTurnovers * 0.025 +
                  (userGoals > opponentGoals
                      ? 0.35
                      : userGoals == opponentGoals
                      ? 0.05
                      : -0.25) +
                  random.nextDouble() * 0.55)
              .clamp(4.5, 10.0)
              .toDouble();

    return CareerMatchSimulation(
      fixture: fixture,
      homeClub: homeClub,
      awayClub: awayClub,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      events: List.unmodifiable(events),
      squadStatus: squadStatus,
      entryMinute: entryMinute,
      exitMinute: exitMinute,
      playerGoals: playerGoals,
      playerAssists: playerAssists,
      playerShots: playerShots,
      playerShotsOnTarget: playerShotsOnTarget,
      playerTurnovers: playerTurnovers,
      playerRating: rating,
    );
  }

  static PlayerSquadStatus _selectSquadStatus(
    CareerProfile profile,
    ClubOffer offer,
    Random random,
  ) {
    final difference = profile.overall - offer.strongestCompetitorOverall;
    final startingChance = (0.50 + difference * 0.04).clamp(0.12, 0.86);
    final roll = random.nextDouble();
    if (roll < startingChance) return PlayerSquadStatus.starting;
    final benchChance = (0.78 + difference * 0.018).clamp(0.48, 0.84);
    if (random.nextDouble() < benchChance) return PlayerSquadStatus.substitute;
    return PlayerSquadStatus.out;
  }

  static int _generateGoals(Random random, double expectation) {
    final probability = expectation.clamp(0.25, 3.4) / 6;
    var goals = 0;
    for (var chance = 0; chance < 6; chance++) {
      if (random.nextDouble() < probability) goals++;
    }
    return goals.clamp(0, 5);
  }

  static String _pickScorer(
    List<CareerPlayer> roster,
    Random random, {
    required String fallback,
  }) {
    final candidates = roster
        .where((player) {
          return player.positions.any(
            const {'ST', 'CF', 'LW', 'RW', 'CAM', 'LM', 'RM', 'CM'}.contains,
          );
        })
        .toList(growable: false);
    final source = candidates.isEmpty ? roster : candidates;
    return source.isEmpty
        ? '$fallback oyuncusu'
        : source[random.nextInt(source.length)].shortName;
  }

  static String? _pickAssistant(
    List<CareerPlayer> roster,
    Random random, {
    required String scorer,
  }) {
    final candidates = roster
        .where((player) => player.shortName != scorer)
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    return candidates[random.nextInt(candidates.length)].shortName;
  }

  static double _playerGoalShare(String position) => switch (position) {
    'ST' => 0.42,
    'LW' || 'RW' => 0.30,
    'CAM' || 'LM' || 'RM' => 0.21,
    'CM' || 'CDM' => 0.12,
    'LB' || 'RB' || 'CB' => 0.05,
    _ => 0.01,
  };

  static double _playerAssistShare(String position) => switch (position) {
    'CAM' || 'CM' || 'LM' || 'RM' => 0.34,
    'LW' || 'RW' => 0.29,
    'ST' => 0.19,
    'CDM' || 'LB' || 'RB' => 0.14,
    _ => 0.04,
  };
}
