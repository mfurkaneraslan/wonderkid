import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/career/fixture_generator.dart';
import 'package:wonderkid/data/football_repository.dart';

void main() {
  const wonderkid = CareerClub(
    id: 1,
    name: 'Wonderkid FC',
    rating: 72,
    playerCount: 25,
  );
  const opponents = [
    CareerClub(id: 2, name: 'A FC', rating: 70, playerCount: 25),
    CareerClub(id: 3, name: 'B FC', rating: 71, playerCount: 25),
    CareerClub(id: 4, name: 'C FC', rating: 73, playerCount: 25),
  ];
  const league = CareerLeague(
    id: 68,
    name: 'Süper Lig',
    country: 'Türkiye',
    clubs: [wonderkid, ...opponents],
  );

  test('creates a deterministic double round-robin player fixture', () {
    final fixture = CareerFixtureGenerator.generate(
      league: league,
      club: wonderkid,
      seed: 12345,
    );

    expect(fixture.seasonYear, 2026);
    expect(fixture.startDate, DateTime(2026, 8, 8));
    expect(fixture.firstHalf, hasLength(opponents.length));
    expect(fixture.secondHalf, hasLength(opponents.length));
    expect(fixture.matches, hasLength(opponents.length * 2));
    expect(
      fixture.matches.map((match) => match.week),
      orderedEquals([1, 2, 3, 4, 5, 6]),
    );

    for (final opponent in opponents) {
      final matches = fixture.matches
          .where((match) => match.opponent.id == opponent.id)
          .toList();
      expect(matches, hasLength(2));
      expect(matches.where((match) => match.isHome), hasLength(1));
      expect(matches.where((match) => !match.isHome), hasLength(1));
    }
  });

  test('uses the same schedule for the same career seed', () {
    final first = CareerFixtureGenerator.generate(
      league: league,
      club: wonderkid,
      seed: 77,
    );
    final second = CareerFixtureGenerator.generate(
      league: league,
      club: wonderkid,
      seed: 77,
    );

    expect(
      first.matches.map((match) => (match.opponent.id, match.isHome)),
      orderedEquals(
        second.matches.map((match) => (match.opponent.id, match.isHome)),
      ),
    );
  });
}
