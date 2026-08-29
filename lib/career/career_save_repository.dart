import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/football_repository.dart';
import 'career_profile.dart';
import 'offer_generator.dart';

class SavedCareer {
  const SavedCareer({required this.profile, required this.offer});

  final CareerProfile profile;
  final ClubOffer offer;
}

class CareerSaveRepository {
  static const _storageKey = 'wonderkid.saved_career.v1';

  static Future<void> save({
    required CareerProfile profile,
    required ClubOffer offer,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'version': 1,
        'profile': profile.toJson(),
        'offer': {
          'leagueId': offer.league.id,
          'clubId': offer.club.id,
          'competitorIds': offer.competitors
              .map((player) => player.id)
              .toList(growable: false),
          'role': offer.role,
          'contractYears': offer.contractYears,
          'weeklySalaryEuro': offer.weeklySalaryEuro,
        },
      }),
    );
  }

  static Future<SavedCareer?> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final source = preferences.getString(_storageKey);
      if (source == null) return null;

      final json = jsonDecode(source) as Map<String, dynamic>;
      if (json['version'] != 1) return null;

      final profile = CareerProfile.fromJson(
        json['profile'] as Map<String, dynamic>,
      );
      final offerJson = json['offer'] as Map<String, dynamic>;
      final dataset = await FootballRepository.load();
      final league = dataset.leagues.firstWhere(
        (item) => item.id == offerJson['leagueId'] as int,
      );
      final club = league.clubs.firstWhere(
        (item) => item.id == offerJson['clubId'] as int,
      );
      final competitorIds = (offerJson['competitorIds'] as List<dynamic>)
          .cast<int>()
          .toSet();
      final competitors =
          dataset.players
              .where((player) => competitorIds.contains(player.id))
              .toList(growable: false)
            ..sort((a, b) => b.overall.compareTo(a.overall));

      return SavedCareer(
        profile: profile,
        offer: ClubOffer(
          club: club,
          league: league,
          competitors: competitors,
          role: offerJson['role'] as String,
          contractYears: offerJson['contractYears'] as int,
          weeklySalaryEuro: offerJson['weeklySalaryEuro'] as int,
        ),
      );
    } on Object {
      return null;
    }
  }
}
