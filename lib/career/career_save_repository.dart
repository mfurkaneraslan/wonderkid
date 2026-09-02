import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/football_repository.dart';
import 'career_profile.dart';
import 'career_shop_state.dart';
import 'league_progress.dart';
import 'offer_generator.dart';

class SavedCareer {
  const SavedCareer({
    required this.profile,
    required this.offer,
    this.currentWeek = 1,
    this.lastTrainingWeek,
    this.lastTrainingAttribute,
    this.shopState = const CareerShopState(),
    this.matchResults = const <CareerLeagueMatchResult>[],
  });

  final CareerProfile profile;
  final ClubOffer offer;
  final int currentWeek;
  final int? lastTrainingWeek;
  final String? lastTrainingAttribute;
  final CareerShopState shopState;
  final List<CareerLeagueMatchResult> matchResults;
}

class CareerSaveRepository {
  static const _storageKey = 'wonderkid.saved_career.v1';

  static Future<void> save({
    required CareerProfile profile,
    required ClubOffer offer,
    int currentWeek = 1,
    int? lastTrainingWeek,
    String? lastTrainingAttribute,
    CareerShopState? shopState,
    List<CareerLeagueMatchResult> matchResults = const [],
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'version': 1,
        'economyVersion': 2,
        'profile': profile.toJson(),
        'progress': {
          'currentWeek': currentWeek,
          'lastTrainingWeek': lastTrainingWeek,
          'lastTrainingAttribute': lastTrainingAttribute,
        },
        'shop': (shopState ?? CareerShopState.initial(offer.weeklySalaryEuro))
            .toJson(),
        'matchResults': matchResults.map((result) => result.toJson()).toList(),
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
      final progressJson = json['progress'] as Map<String, dynamic>?;
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

      final offer = ClubOffer(
        club: club,
        league: league,
        competitors: competitors,
        role: offerJson['role'] as String,
        contractYears: offerJson['contractYears'] as int,
        weeklySalaryEuro: offerJson['weeklySalaryEuro'] as int,
      );
      final shopJson = json['shop'] as Map<String, dynamic>?;
      var shopState = shopJson == null
          ? CareerShopState.initial(offer.weeklySalaryEuro)
          : CareerShopState.fromJson(shopJson);
      final economyVersion = json['economyVersion'] as int? ?? 1;
      if (economyVersion < 2 &&
          shopState.categoryLevels.isEmpty &&
          shopState.balanceEuro == offer.weeklySalaryEuro * 30) {
        shopState = const CareerShopState();
      }
      final matchResults = (json['matchResults'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                CareerLeagueMatchResult.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);

      return SavedCareer(
        profile: profile,
        currentWeek: progressJson?['currentWeek'] as int? ?? 1,
        lastTrainingWeek: progressJson?['lastTrainingWeek'] as int?,
        lastTrainingAttribute:
            progressJson?['lastTrainingAttribute'] as String?,
        shopState: shopState,
        matchResults: matchResults,
        offer: offer,
      );
    } on Object {
      return null;
    }
  }
}
