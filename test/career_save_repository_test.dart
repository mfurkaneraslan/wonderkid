import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonderkid/career/career_profile.dart';
import 'package:wonderkid/career/career_save_repository.dart';
import 'package:wonderkid/career/career_shop_state.dart';
import 'package:wonderkid/career/league_progress.dart';
import 'package:wonderkid/career/offer_generator.dart';
import 'package:wonderkid/data/football_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('accepted career survives a save and load cycle', () async {
    final dataset = await FootballRepository.load();
    final profile = CareerProfile.create(
      name: 'Furkan Eraslan',
      nationality: 'Türkiye',
      shirtNumber: 7,
      position: 'ST',
    );
    final offer = CareerOfferEngine.generate(
      dataset: dataset,
      profile: profile,
    ).first;

    final trainedProfile = profile.increaseAttribute('shooting');
    final shopState = CareerShopState.initial(offer.weeklySalaryEuro).purchase(
      categoryId: 'vehicles',
      level: 3,
      priceEuro: offer.weeklySalaryEuro * 3,
    );
    await CareerSaveRepository.save(
      profile: trainedProfile,
      offer: offer,
      currentWeek: 4,
      lastTrainingWeek: 3,
      lastTrainingAttribute: 'shooting',
      shopState: shopState,
      matchResults: const [
        CareerLeagueMatchResult(
          week: 1,
          homeClubId: 1,
          awayClubId: 2,
          homeGoals: 2,
          awayGoals: 1,
        ),
      ],
    );
    final savedCareer = await CareerSaveRepository.load();

    expect(savedCareer, isNotNull);
    expect(savedCareer!.profile.name, profile.name);
    expect(savedCareer.profile.avatarId, profile.avatarId);
    expect(savedCareer.profile.overall, trainedProfile.overall);
    expect(savedCareer.profile.overallProgress, trainedProfile.overallProgress);
    expect(savedCareer.profile.shooting, profile.shooting + 1);
    expect(savedCareer.currentWeek, 4);
    expect(savedCareer.lastTrainingWeek, 3);
    expect(savedCareer.lastTrainingAttribute, 'shooting');
    expect(savedCareer.shopState.balanceEuro, shopState.balanceEuro);
    expect(savedCareer.shopState.levelFor('vehicles'), 3);
    expect(savedCareer.matchResults, hasLength(1));
    expect(savedCareer.matchResults.single.homeGoals, 2);
    expect(savedCareer.offer.club.id, offer.club.id);
    expect(savedCareer.offer.league.id, offer.league.id);
    expect(savedCareer.offer.weeklySalaryEuro, offer.weeklySalaryEuro);
    expect(
      savedCareer.offer.competitors.map((player) => player.id),
      offer.competitors.map((player) => player.id),
    );
  });

  test('training gains slow down after 80 and 90', () {
    expect(CareerProfile.trainingIncrement(79), 1);
    expect(CareerProfile.trainingIncrement(80), 0.5);
    expect(CareerProfile.trainingIncrement(89.99), 0.5);
    expect(CareerProfile.trainingIncrement(90), 0.33);
    expect(CareerProfile.trainingIncrement(98), 0.33);
    expect(formatCareerAttribute(80), '80');
    expect(formatCareerAttribute(80.5), '80,5');
    expect(formatCareerAttribute(90.33), '90,33');
  });

  test('training raises overall according to position weights', () {
    final winger = CareerProfile.create(
      name: 'OVR Test',
      nationality: 'Türkiye',
      shirtNumber: 11,
      position: 'LW',
    );

    final trained = winger.increaseAttributeBy('pace', 4);

    expect(trained.pace, winger.pace + 4);
    expect(trained.overall, winger.overall + 1);
  });

  test('every stat affects overall but position relevance controls impact', () {
    final centreBack = CareerProfile.create(
      name: 'Defender Test',
      nationality: 'Türkiye',
      shirtNumber: 4,
      position: 'CB',
    );

    final shootingBoost = centreBack.increaseAttributeBy('shooting', 20);
    final defendingBoost = centreBack.increaseAttributeBy('defending', 20);

    expect(shootingBoost.overallProgress, greaterThan(0));
    expect(defendingBoost.overall, greaterThan(shootingBoost.overall));
  });

  test('shop bonuses add an exact amount and respect the stat cap', () {
    final profile = CareerProfile.create(
      name: 'Shop Test',
      nationality: 'Türkiye',
      shirtNumber: 10,
      position: 'ST',
    );

    final boosted = profile.increaseAttributeBy('pace', 5);
    expect(boosted.pace, profile.pace + 5);

    final capped = boosted.increaseAttributeBy('pace', 50);
    expect(capped.pace, 99);
  });

  test('a new career starts at zero and salary can be credited', () {
    final initial = CareerShopState.initial(12750);
    expect(initial.balanceEuro, 0);
    expect(initial.credit(12750).balanceEuro, 12750);
  });
}
