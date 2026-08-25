import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/career/career_profile.dart';
import 'package:wonderkid/career/offer_generator.dart';
import 'package:wonderkid/data/football_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates a 17 year old profile with position-based attributes', () {
    final striker = CareerProfile.create(
      name: 'Test Player',
      nationality: 'Türkiye',
      shirtNumber: 9,
      position: 'ST',
    );

    expect(striker.age, 17);
    expect(striker.overall, inInclusiveRange(60, 65));
    expect(striker.shooting, greaterThan(striker.passing));
    expect(striker.position, 'ST');
  });

  test('generates three deterministic offers from different leagues', () async {
    final dataset = await FootballRepository.load();
    final profile = CareerProfile.create(
      name: 'Test Player',
      nationality: 'Türkiye',
      shirtNumber: 9,
      position: 'ST',
    );

    final offers = CareerOfferEngine.generate(
      dataset: dataset,
      profile: profile,
    );
    final repeated = CareerOfferEngine.generate(
      dataset: dataset,
      profile: profile,
    );

    expect(offers, hasLength(3));
    expect(offers.map((offer) => offer.league.id).toSet(), hasLength(3));
    expect(offers.first.league.name, 'Süper Lig');
    expect(offers.every((offer) => offer.club.rating <= 78), isTrue);
    expect(offers.every((offer) => offer.competitors.isNotEmpty), isTrue);
    expect(
      repeated.map((offer) => offer.club.id),
      offers.map((offer) => offer.club.id),
    );
  });
}
