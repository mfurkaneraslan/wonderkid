import 'dart:math';

import '../data/football_repository.dart';
import 'career_profile.dart';

class ClubOffer {
  const ClubOffer({
    required this.club,
    required this.league,
    required this.competitors,
    required this.role,
    required this.contractYears,
    required this.weeklySalaryEuro,
  });

  final CareerClub club;
  final CareerLeague league;
  final List<CareerPlayer> competitors;
  final String role;
  final int contractYears;
  final int weeklySalaryEuro;

  int get strongestCompetitorOverall => competitors.first.overall;
}

class CareerOfferEngine {
  static List<ClubOffer> generate({
    required FootballDataset dataset,
    required CareerProfile profile,
    int count = 3,
  }) {
    final random = Random(profile.seed);
    final playersByClub = <int, List<CareerPlayer>>{};
    for (final player in dataset.players) {
      playersByClub.putIfAbsent(player.clubId, () => []).add(player);
    }

    final candidatesByLeague = <int, List<_OfferCandidate>>{};
    for (final league in dataset.leagues) {
      for (final club in league.clubs) {
        if (club.rating > 78) continue;
        final competitors =
            (playersByClub[club.id] ?? const <CareerPlayer>[])
                .where((player) => _matchesPosition(player, profile.position))
                .toList()
              ..sort((a, b) => b.overall.compareTo(a.overall));
        if (competitors.isEmpty) continue;

        final topCompetitors = competitors.take(3).toList(growable: false);
        final gap = topCompetitors.first.overall - profile.overall;
        final opportunityScore =
            (gap - 8).abs() + (club.rating - 74).abs() * 0.25;
        candidatesByLeague
            .putIfAbsent(league.id, () => [])
            .add(
              _OfferCandidate(
                club: club,
                league: league,
                competitors: topCompetitors,
                opportunityScore: opportunityScore,
              ),
            );
      }
    }

    final preferredLeagueId = _countryLeagueId[profile.nationality];
    final leagueIds = candidatesByLeague.keys.toList()..shuffle(random);
    if (preferredLeagueId != null && leagueIds.remove(preferredLeagueId)) {
      leagueIds.insert(0, preferredLeagueId);
    }

    final offers = <ClubOffer>[];
    for (final leagueId in leagueIds) {
      final candidates = candidatesByLeague[leagueId]!
        ..sort((a, b) => a.opportunityScore.compareTo(b.opportunityScore));
      final pool = candidates.take(min(5, candidates.length)).toList();
      final selected = pool[random.nextInt(pool.length)];
      offers.add(_toOffer(selected, profile));
      if (offers.length == count) break;
    }

    if (offers.length < count) {
      final selectedClubIds = offers.map((offer) => offer.club.id).toSet();
      final remaining =
          candidatesByLeague.values
              .expand((items) => items)
              .where(
                (candidate) => !selectedClubIds.contains(candidate.club.id),
              )
              .toList()
            ..shuffle(random);
      for (final candidate in remaining) {
        offers.add(_toOffer(candidate, profile));
        if (offers.length == count) break;
      }
    }

    return offers;
  }

  static ClubOffer _toOffer(_OfferCandidate candidate, CareerProfile profile) {
    final gap = candidate.competitors.first.overall - profile.overall;
    final role = switch (gap) {
      <= 5 => 'İlk 11 adayı',
      <= 10 => 'Rotasyon',
      _ => 'Gelişim oyuncusu',
    };
    final rawSalary =
        2000 +
        (candidate.club.rating - 65) * 550 +
        (profile.overall - 60) * 750 +
        (candidate.club.id % 5) * 250;
    final weeklySalaryEuro =
        (rawSalary.clamp(3000, 25000).toInt() / 250).round() * 250;
    return ClubOffer(
      club: candidate.club,
      league: candidate.league,
      competitors: candidate.competitors,
      role: role,
      contractYears: 1,
      weeklySalaryEuro: weeklySalaryEuro,
    );
  }

  static bool _matchesPosition(CareerPlayer player, String position) {
    final compatible = _compatiblePositions[position] ?? {position};
    return player.positions.any(compatible.contains);
  }

  static const _compatiblePositions = <String, Set<String>>{
    'GK': {'GK'},
    'LB': {'LB', 'LWB'},
    'CB': {'CB'},
    'RB': {'RB', 'RWB'},
    'CDM': {'CDM', 'CM'},
    'CM': {'CM', 'CDM', 'CAM'},
    'CAM': {'CAM', 'CM'},
    'LM': {'LM', 'LW'},
    'RM': {'RM', 'RW'},
    'LW': {'LW', 'LM'},
    'RW': {'RW', 'RM'},
    'ST': {'ST', 'CF'},
  };

  static const _countryLeagueId = <String, int>{
    'İngiltere': 13,
    'Fransa': 16,
    'Almanya': 19,
    'İtalya': 31,
    'İspanya': 53,
    'Türkiye': 68,
  };
}

class _OfferCandidate {
  const _OfferCandidate({
    required this.club,
    required this.league,
    required this.competitors,
    required this.opportunityScore,
  });

  final CareerClub club;
  final CareerLeague league;
  final List<CareerPlayer> competitors;
  final double opportunityScore;
}
