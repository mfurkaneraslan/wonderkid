import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonderkid/career/career_profile.dart';
import 'package:wonderkid/career/career_save_repository.dart';
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

    await CareerSaveRepository.save(profile: profile, offer: offer);
    final savedCareer = await CareerSaveRepository.load();

    expect(savedCareer, isNotNull);
    expect(savedCareer!.profile.name, profile.name);
    expect(savedCareer.profile.avatarId, profile.avatarId);
    expect(savedCareer.profile.overall, profile.overall);
    expect(savedCareer.offer.club.id, offer.club.id);
    expect(savedCareer.offer.league.id, offer.league.id);
    expect(savedCareer.offer.weeklySalaryEuro, offer.weeklySalaryEuro);
    expect(
      savedCareer.offer.competitors.map((player) => player.id),
      offer.competitors.map((player) => player.id),
    );
  });
}
