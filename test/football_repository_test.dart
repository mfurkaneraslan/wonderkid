import 'package:flutter_test/flutter_test.dart';
import 'package:wonderkid/data/football_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the six target leagues and their squads', () async {
    final dataset = await FootballRepository.load();

    expect(dataset.meta.leagueCount, 6);
    expect(dataset.meta.clubCount, 114);
    expect(dataset.meta.playerCount, 3148);
    expect(dataset.leagues, hasLength(6));
    expect(dataset.clubs, hasLength(114));
    expect(dataset.players, hasLength(3148));
    expect(
      dataset.leagues.map((league) => league.name),
      containsAll([
        'Premier League',
        'Ligue 1',
        'Bundesliga',
        'Serie A',
        'La Liga',
        'Süper Lig',
      ]),
    );
  });

  test('supports club squad and position lookups', () async {
    final dataset = await FootballRepository.load();
    final realMadrid = dataset.clubs.singleWhere(
      (club) => club.name == 'Real Madrid',
    );

    expect(dataset.playersForClub(realMadrid.id), isNotEmpty);
    expect(
      dataset
          .playersForPosition('ST')
          .every((player) => player.positions.contains('ST')),
      isTrue,
    );
  });
}
