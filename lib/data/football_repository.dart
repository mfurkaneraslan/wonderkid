import 'dart:convert';

import 'package:flutter/services.dart';

class FootballRepository {
  static const _assetPath = 'assets/data/fc26_career.json';
  static Future<FootballDataset>? _cachedDataset;

  static Future<FootballDataset> load() {
    return _cachedDataset ??= _loadFromAssets();
  }

  static Future<FootballDataset> _loadFromAssets() async {
    final source = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(source) as Map<String, dynamic>;
    return FootballDataset.fromJson(json);
  }
}

class FootballDataset {
  const FootballDataset({
    required this.meta,
    required this.leagues,
    required this.players,
  });

  factory FootballDataset.fromJson(Map<String, dynamic> json) {
    return FootballDataset(
      meta: FootballDatasetMeta.fromJson(json['meta'] as Map<String, dynamic>),
      leagues: (json['leagues'] as List<dynamic>)
          .map((item) => CareerLeague.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      players: (json['players'] as List<dynamic>)
          .map((item) => CareerPlayer.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final FootballDatasetMeta meta;
  final List<CareerLeague> leagues;
  final List<CareerPlayer> players;

  List<CareerClub> get clubs =>
      leagues.expand((league) => league.clubs).toList(growable: false);

  List<CareerPlayer> playersForClub(int clubId) {
    return players
        .where((player) => player.clubId == clubId)
        .toList(growable: false);
  }

  List<CareerPlayer> playersForPosition(String position) {
    return players
        .where((player) => player.positions.contains(position))
        .toList(growable: false);
  }
}

class FootballDatasetMeta {
  const FootballDatasetMeta({
    required this.source,
    required this.snapshotDate,
    required this.leagueCount,
    required this.clubCount,
    required this.playerCount,
  });

  factory FootballDatasetMeta.fromJson(Map<String, dynamic> json) {
    return FootballDatasetMeta(
      source: json['source'] as String,
      snapshotDate: json['snapshotDate'] as String,
      leagueCount: json['leagueCount'] as int,
      clubCount: json['clubCount'] as int,
      playerCount: json['playerCount'] as int,
    );
  }

  final String source;
  final String snapshotDate;
  final int leagueCount;
  final int clubCount;
  final int playerCount;
}

class CareerLeague {
  const CareerLeague({
    required this.id,
    required this.name,
    required this.country,
    required this.clubs,
  });

  factory CareerLeague.fromJson(Map<String, dynamic> json) {
    return CareerLeague(
      id: json['id'] as int,
      name: json['name'] as String,
      country: json['country'] as String,
      clubs: (json['clubs'] as List<dynamic>)
          .map((item) => CareerClub.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String country;
  final List<CareerClub> clubs;
}

class CareerClub {
  const CareerClub({
    required this.id,
    required this.name,
    required this.rating,
    required this.playerCount,
  });

  factory CareerClub.fromJson(Map<String, dynamic> json) {
    return CareerClub(
      id: json['id'] as int,
      name: json['name'] as String,
      rating: json['rating'] as int,
      playerCount: json['playerCount'] as int,
    );
  }

  final int id;
  final String name;
  final int rating;
  final int playerCount;
}

class CareerPlayer {
  const CareerPlayer({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.positions,
    required this.overall,
    required this.potential,
    required this.age,
    required this.clubId,
    required this.clubName,
    required this.leagueId,
    required this.nationality,
    required this.preferredFoot,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    required this.gkDiving,
    required this.gkHandling,
    required this.gkKicking,
    required this.gkPositioning,
    required this.gkReflexes,
  });

  factory CareerPlayer.fromJson(Map<String, dynamic> json) {
    int? optionalInt(String key) => json[key] as int?;

    return CareerPlayer(
      id: json['id'] as int,
      shortName: json['shortName'] as String,
      longName: json['longName'] as String,
      positions: (json['positions'] as List<dynamic>).cast<String>(),
      overall: json['overall'] as int,
      potential: json['potential'] as int,
      age: json['age'] as int,
      clubId: json['clubId'] as int,
      clubName: json['clubName'] as String,
      leagueId: json['leagueId'] as int,
      nationality: json['nationality'] as String,
      preferredFoot: json['preferredFoot'] as String,
      pace: optionalInt('pace'),
      shooting: optionalInt('shooting'),
      passing: optionalInt('passing'),
      dribbling: optionalInt('dribbling'),
      defending: optionalInt('defending'),
      physical: optionalInt('physical'),
      gkDiving: optionalInt('gkDiving'),
      gkHandling: optionalInt('gkHandling'),
      gkKicking: optionalInt('gkKicking'),
      gkPositioning: optionalInt('gkPositioning'),
      gkReflexes: optionalInt('gkReflexes'),
    );
  }

  final int id;
  final String shortName;
  final String longName;
  final List<String> positions;
  final int overall;
  final int potential;
  final int age;
  final int clubId;
  final String clubName;
  final int leagueId;
  final String nationality;
  final String preferredFoot;
  final int? pace;
  final int? shooting;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? physical;
  final int? gkDiving;
  final int? gkHandling;
  final int? gkKicking;
  final int? gkPositioning;
  final int? gkReflexes;
}
