import 'package:flutter/material.dart';

import 'career/career_profile.dart';
import 'career/career_save_repository.dart';
import 'career/career_shop_state.dart';
import 'career/fixture_generator.dart';
import 'career/league_progress.dart';
import 'career/offer_generator.dart';
import 'data/football_repository.dart';
import 'match/match_simulation.dart';
import 'match/match_simulation_screen.dart';
import 'training/training_game_screen.dart';
import 'widgets/fc_player_card.dart';

class CareerDashboardScreen extends StatefulWidget {
  const CareerDashboardScreen({
    super.key,
    required this.profile,
    required this.offer,
    this.currentWeek = 1,
    this.lastTrainingWeek,
    this.lastTrainingAttribute,
    this.shopState,
    this.matchResults = const <CareerLeagueMatchResult>[],
  });

  final CareerProfile profile;
  final ClubOffer offer;
  final int currentWeek;
  final int? lastTrainingWeek;
  final String? lastTrainingAttribute;
  final CareerShopState? shopState;
  final List<CareerLeagueMatchResult> matchResults;

  @override
  State<CareerDashboardScreen> createState() => _CareerDashboardScreenState();
}

class _CareerDashboardScreenState extends State<CareerDashboardScreen> {
  static const _accent = Color(0xFFC8FF4D);
  int _selectedIndex = 0;
  late CareerProfile _profile;
  late int? _lastTrainingWeek;
  late String? _lastTrainingAttribute;
  late final CareerSeasonFixture _fixture;
  late CareerShopState _shopState;
  late int _currentWeek;
  late List<CareerLeagueMatchResult> _matchResults;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _currentWeek = widget.currentWeek;
    _lastTrainingWeek = widget.lastTrainingWeek;
    _lastTrainingAttribute = widget.lastTrainingAttribute;
    _shopState =
        widget.shopState ??
        CareerShopState.initial(widget.offer.weeklySalaryEuro);
    _matchResults = [...widget.matchResults];
    _fixture = CareerFixtureGenerator.generate(
      league: widget.offer.league,
      club: widget.offer.club,
      seed: _profile.seed,
    );
  }

  Future<void> _showFixture() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A2116),
      barrierColor: Colors.black.withValues(alpha: 0.72),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FixtureSheet(
        fixture: _fixture,
        league: widget.offer.league,
        selectedClub: widget.offer.club,
        results: _matchResults,
      ),
    );
  }

  Future<void> _showStandings() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A2116),
      barrierColor: Colors.black.withValues(alpha: 0.72),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StandingsSheet(
        league: widget.offer.league,
        selectedClub: widget.offer.club,
        results: _matchResults,
      ),
    );
  }

  Future<void> _playNextMatch() async {
    if (_lastTrainingWeek != _currentWeek) {
      final skipTraining = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('skipTrainingDialog'),
          backgroundColor: const Color(0xFF102A1D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x33C8FF4D)),
          ),
          icon: const Icon(
            Icons.fitness_center_rounded,
            color: Color(0xFFC8FF4D),
            size: 32,
          ),
          title: const Text(
            'ANTRENMAN YAPMADIN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Bu haftaki antrenmanı atlamak mı istiyorsun?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              key: const Key('goToTrainingButton'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ANTRENMANA GİT'),
            ),
            FilledButton(
              key: const Key('skipTrainingButton'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC8FF4D),
                foregroundColor: const Color(0xFF092115),
              ),
              child: const Text('ATLA VE MAÇA ÇIK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (skipTraining != true) {
        if (skipTraining == false) setState(() => _selectedIndex = 1);
        return;
      }
    }

    final matchIndex = (_currentWeek - 1).clamp(0, _fixture.matches.length - 1);
    final match = _fixture.matches[matchIndex];
    final dataset = await FootballRepository.load();
    if (!mounted) return;
    final simulation = CareerMatchEngine.generate(
      profile: _profile,
      offer: widget.offer,
      fixture: match,
      userClubPlayers: dataset.playersForClub(widget.offer.club.id),
      opponentPlayers: dataset.playersForClub(match.opponent.id),
    );
    final result = await Navigator.of(context).push<CareerMatchSimulation>(
      MaterialPageRoute<CareerMatchSimulation>(
        builder: (_) => MatchSimulationScreen(
          profile: _profile,
          leagueName: widget.offer.league.name,
          simulation: simulation,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final weekResults = CareerLeagueSimulator.simulateWeek(
      league: widget.offer.league,
      playerMatch: result,
      seed: _profile.seed,
    );
    setState(() {
      _matchResults = [..._matchResults, ...weekResults];
      _shopState = _shopState.credit(widget.offer.weeklySalaryEuro);
      _currentWeek = (_currentWeek + 1).clamp(1, _fixture.matches.length);
    });
    await CareerSaveRepository.save(
      profile: _profile,
      offer: widget.offer,
      currentWeek: _currentWeek,
      lastTrainingWeek: _lastTrainingWeek,
      lastTrainingAttribute: _lastTrainingAttribute,
      shopState: _shopState,
      matchResults: _matchResults,
    );
  }

  Future<void> _openTraining(TrainingAttribute attribute) async {
    if (_lastTrainingWeek == _currentWeek) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF183A29),
            content: Text('Bu haftaki antrenmanını tamamladın.'),
          ),
        );
      return;
    }
    if (_lastTrainingWeek == _currentWeek - 1 &&
        _lastTrainingAttribute == attribute.name) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF183A29),
            content: Text('Geçen haftaki antrenmanı üst üste seçemezsin.'),
          ),
        );
      return;
    }
    final currentValue = _profile.attributeValue(attribute.name);
    final statIncrease = CareerProfile.trainingIncrement(currentValue);
    final result = await Navigator.of(context).push<TrainingResult>(
      MaterialPageRoute<TrainingResult>(
        builder: (_) => TrainingGameScreen(
          attribute: attribute,
          currentStat: currentValue,
          statIncrease: statIncrease,
          playerAvatarAsset: _profile.avatarAssetPath,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final updatedProfile = result.isSuccessful
        ? _profile.increaseAttribute(attribute.name)
        : _profile;
    setState(() {
      _profile = updatedProfile;
      _lastTrainingWeek = _currentWeek;
      _lastTrainingAttribute = attribute.name;
    });
    await CareerSaveRepository.save(
      profile: updatedProfile,
      offer: widget.offer,
      currentWeek: _currentWeek,
      lastTrainingWeek: _currentWeek,
      lastTrainingAttribute: attribute.name,
      shopState: _shopState,
      matchResults: _matchResults,
    );
    if (!mounted) return;
    final message = result.isSuccessful
        ? '${attribute.turkishLabel} özelliğin ${formatCareerAttribute(statIncrease)} puan arttı.'
        : 'Antrenman tamamlandı ancak özellik puanı kazanamadın.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF183A29),
          content: Text(message),
        ),
      );
  }

  Future<void> _buyShopItem(_ShopItem item) async {
    final currentLevel = _shopState.levelFor(item.categoryId);
    if (item.bonus <= currentLevel) return;
    final price = item.priceFor(
      widget.offer.weeklySalaryEuro,
      currentLevel: currentLevel,
    );
    if (_shopState.balanceEuro < price) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF183A29),
            content: Text('Bu ürün için bakiyen yeterli değil.'),
          ),
        );
      return;
    }

    final bonusIncrease = item.bonus - currentLevel;
    final updatedProfile = _profile.increaseAttributeBy(
      item.attribute,
      bonusIncrease.toDouble(),
    );
    final updatedShopState = _shopState.purchase(
      categoryId: item.categoryId,
      level: item.bonus,
      priceEuro: price,
    );
    setState(() {
      _profile = updatedProfile;
      _shopState = updatedShopState;
    });
    await CareerSaveRepository.save(
      profile: updatedProfile,
      offer: widget.offer,
      currentWeek: _currentWeek,
      lastTrainingWeek: _lastTrainingWeek,
      lastTrainingAttribute: _lastTrainingAttribute,
      shopState: updatedShopState,
      matchResults: _matchResults,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF183A29),
          content: Text(
            '${item.name} alındı • ${_attributeShortLabel(item.attribute)} +$bonusIncrease',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OverviewTab(
        profile: _profile,
        offer: widget.offer,
        fixture: _fixture,
        currentWeek: _currentWeek,
        onOpenFixture: _showFixture,
        onPlayMatch: _playNextMatch,
      ),
      _TrainingTab(
        profile: _profile,
        currentWeek: _currentWeek,
        lastTrainingWeek: _lastTrainingWeek,
        lastTrainingAttribute: _lastTrainingAttribute,
        onStartTraining: _openTraining,
      ),
      _TeamTab(
        profile: _profile,
        offer: widget.offer,
        onOpenFixture: _showFixture,
        onOpenStandings: _showStandings,
      ),
      _ShopTab(
        shopState: _shopState,
        weeklySalaryEuro: widget.offer.weeklySalaryEuro,
        onBuy: _buyShopItem,
      ),
    ];

    return Scaffold(
      key: const Key('careerDashboard'),
      backgroundColor: const Color(0xFF071A12),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: NavigationBar(
              height: 68,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              backgroundColor: const Color(0xFF0C2419),
              indicatorColor: _accent,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  key: Key('dashboardTab'),
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(
                    Icons.dashboard_rounded,
                    color: Color(0xFF092115),
                  ),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  key: Key('trainingTab'),
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF092115),
                  ),
                  label: 'Antrenman',
                ),
                NavigationDestination(
                  key: Key('teamTab'),
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF092115),
                  ),
                  label: 'Takım',
                ),
                NavigationDestination(
                  key: Key('shopTab'),
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(
                    Icons.shopping_bag_rounded,
                    color: Color(0xFF092115),
                  ),
                  label: 'Alışveriş',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.profile,
    required this.offer,
    required this.fixture,
    required this.currentWeek,
    required this.onOpenFixture,
    required this.onPlayMatch,
  });

  final CareerProfile profile;
  final ClubOffer offer;
  final CareerSeasonFixture fixture;
  final int currentWeek;
  final VoidCallback onOpenFixture;
  final VoidCallback onPlayMatch;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _SeasonDateStrip(fixture: fixture, currentWeek: currentWeek),
          const SizedBox(height: 10),
          _ClubHeader(offer: offer),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: FcPlayerCard(profile: profile),
            ),
          ),
          const SizedBox(height: 14),
          _NextMatchCard(
            fixture: fixture,
            currentWeek: currentWeek,
            club: offer.club,
            league: offer.league,
            onOpenFixture: onOpenFixture,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              key: const Key('playNextMatchButton'),
              onPressed: onPlayMatch,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC8FF4D),
                foregroundColor: const Color(0xFF092115),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.sports_soccer_rounded),
              label: const Text(
                'SIRADAKİ MAÇI OYNA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingTab extends StatelessWidget {
  const _TrainingTab({
    required this.profile,
    required this.currentWeek,
    required this.lastTrainingWeek,
    required this.lastTrainingAttribute,
    required this.onStartTraining,
  });

  final CareerProfile profile;
  final int currentWeek;
  final int? lastTrainingWeek;
  final String? lastTrainingAttribute;
  final ValueChanged<TrainingAttribute> onStartTraining;

  @override
  Widget build(BuildContext context) {
    final trainedThisWeek = lastTrainingWeek == currentWeek;
    final previousWeekAttribute = lastTrainingWeek == currentWeek - 1
        ? lastTrainingAttribute
        : null;

    return _PageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _StatusBanner(
            icon: Icons.bolt_rounded,
            title: 'ANTRENMAN HAKKI',
            value: trainedThisWeek ? '0 / 1' : '1 / 1',
            subtitle: trainedThisWeek
                ? 'Bu haftaki antrenmanını tamamladın'
                : 'Bu hafta bir antrenman yapabilirsin',
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'ANTRENMANINI SEÇ'),
          const SizedBox(height: 9),
          _TrainingCard(
            key: const Key('paceTrainingCard'),
            icon: Icons.speed_rounded,
            title: 'Hız',
            onTap: trainedThisWeek || previousWeekAttribute == 'pace'
                ? null
                : () => onStartTraining(TrainingAttribute.pace),
          ),
          const SizedBox(height: 8),
          _TrainingCard(
            key: const Key('shootingTrainingCard'),
            icon: Icons.sports_soccer_rounded,
            title: 'Şut',
            onTap: trainedThisWeek || previousWeekAttribute == 'shooting'
                ? null
                : () => onStartTraining(TrainingAttribute.shooting),
          ),
          const SizedBox(height: 8),
          _TrainingCard(
            key: const Key('passingTrainingCard'),
            icon: Icons.route_rounded,
            title: 'Pas',
            onTap: trainedThisWeek || previousWeekAttribute == 'passing'
                ? null
                : () => onStartTraining(TrainingAttribute.passing),
          ),
          const SizedBox(height: 8),
          _TrainingCard(
            key: const Key('dribblingTrainingCard'),
            icon: Icons.multiple_stop_rounded,
            title: 'Dribbling',
            onTap: trainedThisWeek || previousWeekAttribute == 'dribbling'
                ? null
                : () => onStartTraining(TrainingAttribute.dribbling),
          ),
          const SizedBox(height: 8),
          _TrainingCard(
            key: const Key('defendingTrainingCard'),
            icon: Icons.shield_outlined,
            title: 'Defans',
            onTap: trainedThisWeek || previousWeekAttribute == 'defending'
                ? null
                : () => onStartTraining(TrainingAttribute.defending),
          ),
          const SizedBox(height: 8),
          _TrainingCard(
            key: const Key('physicalTrainingCard'),
            icon: Icons.fitness_center_rounded,
            title: 'Fizik',
            onTap: trainedThisWeek || previousWeekAttribute == 'physical'
                ? null
                : () => onStartTraining(TrainingAttribute.physical),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'MEVCUT ÖZELLİKLER'),
          const SizedBox(height: 9),
          _AttributeGrid(profile: profile),
        ],
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({
    required this.profile,
    required this.offer,
    required this.onOpenFixture,
    required this.onOpenStandings,
  });

  final CareerProfile profile;
  final ClubOffer offer;
  final VoidCallback onOpenFixture;
  final VoidCallback onOpenStandings;

  @override
  Widget build(BuildContext context) {
    final competition =
        <({String name, String position, int overall, bool isUser})>[
          (
            name: profile.name,
            position: profile.position,
            overall: profile.overall,
            isUser: true,
          ),
          ...offer.competitors.map(
            (player) => (
              name: player.shortName,
              position: player.positions.first,
              overall: player.overall,
              isUser: false,
            ),
          ),
        ]..sort((a, b) {
          final overallOrder = b.overall.compareTo(a.overall);
          if (overallOrder != 0) return overallOrder;
          return a.name.compareTo(b.name);
        });

    return _PageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _ClubHeader(offer: offer),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TeamActionButton(
                  key: const Key('teamFixtureButton'),
                  icon: Icons.calendar_month_rounded,
                  label: 'FİKSTÜR',
                  onTap: onOpenFixture,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TeamActionButton(
                  key: const Key('standingsButton'),
                  icon: Icons.leaderboard_rounded,
                  label: 'PUAN DURUMU',
                  onTap: onOpenStandings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'FORMA REKABETİ'),
          const SizedBox(height: 9),
          for (var index = 0; index < competition.length; index++) ...[
            if (index > 0) const SizedBox(height: 7),
            _SquadPlayerRow(
              name: competition[index].name,
              position: competition[index].position,
              overall: competition[index].overall,
              isUser: competition[index].isUser,
            ),
          ],
          const SizedBox(height: 18),
          _InfoPanel(
            icon: Icons.info_outline_rounded,
            text: 'İlk 11 şansın OVR ve formuna göre hesaplanacak. Düzenli antrenman forma rekabetinde avantaj sağlar.',
          ),
        ],
      ),
    );
  }
}

class _ShopTab extends StatefulWidget {
  const _ShopTab({
    required this.shopState,
    required this.weeklySalaryEuro,
    required this.onBuy,
  });

  final CareerShopState shopState;
  final int weeklySalaryEuro;
  final Future<void> Function(_ShopItem item) onBuy;

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    final category = _shopCategories[_selectedCategory];
    final currentLevel = widget.shopState.levelFor(category.id);
    return _PageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _StatusBanner(
            icon: Icons.account_balance_wallet_outlined,
            title: 'BAKİYE',
            value: _formatEuro(widget.shopState.balanceEuro),
            subtitle:
                'Başlangıç bütçesi • Haftalık maaş ${_formatEuro(widget.weeklySalaryEuro)}',
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'KATEGORİLER'),
          const SizedBox(height: 9),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: _shopCategories.length,
            itemBuilder: (context, index) {
              final item = _shopCategories[index];
              final selected = index == _selectedCategory;
              return _ShopCategoryChip(
                key: Key('shopCategory_${item.id}'),
                category: item,
                selected: selected,
                level: widget.shopState.levelFor(item.id),
                onTap: () => setState(() => _selectedCategory = index),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.attributeLabel} bonusu • Mevcut +$currentLevel / +5',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8FF4D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$currentLevel ${_attributeShortLabel(category.attribute)}',
                  style: const TextStyle(
                    color: Color(0xFFC8FF4D),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in category.items) ...[
            _ShopItemCard(
              item: item,
              currentLevel: currentLevel,
              balanceEuro: widget.shopState.balanceEuro,
              weeklySalaryEuro: widget.weeklySalaryEuro,
              onBuy: widget.onBuy,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child,
      ),
    );
  }
}

class _SeasonDateStrip extends StatelessWidget {
  const _SeasonDateStrip({required this.fixture, required this.currentWeek});

  final CareerSeasonFixture fixture;
  final int currentWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC8FF4D).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFC8FF4D).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFFC8FF4D),
            size: 19,
          ),
          const SizedBox(width: 9),
          Text(
            _monthYear(fixture.matches[currentWeek - 1].date),
            key: const Key('careerDate'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            '${fixture.seasonYear} • $currentWeek. HAFTA',
            key: const Key('careerWeek'),
            style: const TextStyle(
              color: Color(0xFFC8FF4D),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  const _NextMatchCard({
    required this.fixture,
    required this.currentWeek,
    required this.club,
    required this.league,
    required this.onOpenFixture,
  });

  final CareerSeasonFixture fixture;
  final int currentWeek;
  final CareerClub club;
  final CareerLeague league;
  final VoidCallback onOpenFixture;

  @override
  Widget build(BuildContext context) {
    final match = fixture.matches[currentWeek - 1];
    final homeClub = match.isHome ? club : match.opponent;
    final awayClub = match.isHome ? match.opponent : club;
    return Container(
      key: const Key('nextMatchCard'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF183E2A), Color(0xFF0D271B)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'SIRADAKİ MAÇ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                '${match.week}. HAFTA • ${_shortDate(match.date)}',
                style: const TextStyle(
                  color: Color(0xFFC8FF4D),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              league.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MatchClub(club: homeClub, label: 'EV SAHİBİ'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      _dayMonth(match.date),
                      style: const TextStyle(
                        color: Color(0xFFC8FF4D),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.32),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _MatchClub(club: awayClub, label: 'DEPLASMAN'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              key: const Key('openFixtureButton'),
              onPressed: onOpenFixture,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.list_alt_rounded, size: 17),
              label: const Text(
                'TÜM FİKSTÜR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchClub extends StatelessWidget {
  const _MatchClub({required this.club, required this.label});

  final CareerClub club;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ClubLogo(club: club, size: 50),
        const SizedBox(height: 7),
        Text(
          club.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.32),
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _FixtureSheet extends StatelessWidget {
  const _FixtureSheet({
    required this.fixture,
    required this.league,
    required this.selectedClub,
    required this.results,
  });

  final CareerSeasonFixture fixture;
  final CareerLeague league;
  final CareerClub selectedClub;
  final List<CareerLeagueMatchResult> results;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.84,
        child: Column(
          children: [
            const SizedBox(height: 9),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2026/27 FİKSTÜRÜ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${league.name} • ${fixture.matches.length} maç',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.42),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            Expanded(
              child: _FixtureList(
                matches: fixture.matches,
                selectedClub: selectedClub,
                results: results,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixtureList extends StatelessWidget {
  const _FixtureList({
    required this.matches,
    required this.selectedClub,
    required this.results,
  });

  final List<CareerFixtureMatch> matches;
  final CareerClub selectedClub;
  final List<CareerLeagueMatchResult> results;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final match = matches[index];
        final result = results
            .where(
              (item) =>
                  item.week == match.week &&
                  ((item.homeClubId == selectedClub.id &&
                          item.awayClubId == match.opponent.id) ||
                      (item.awayClubId == selectedClub.id &&
                          item.homeClubId == match.opponent.id)),
            )
            .firstOrNull;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Column(
                  children: [
                    Text(
                      '${match.week}',
                      style: const TextStyle(
                        color: Color(0xFFC8FF4D),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'HAFTA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ClubLogo(club: match.opponent, size: 36),
              const SizedBox(width: 9),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        match.opponent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: match.isHome ? 'Ev' : 'Deplasman',
                      child: Icon(
                        match.isHome
                            ? Icons.home_rounded
                            : Icons.flight_rounded,
                        key: Key(
                          match.isHome
                              ? 'homeMatch_${match.week}'
                              : 'awayMatch_${match.week}',
                        ),
                        size: 14,
                        color: const Color(0xFFC8FF4D),
                      ),
                    ),
                  ],
                ),
              ),
              if (result == null)
                Text(
                  _shortDate(match.date),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                _FixtureResultBadge(
                  key: Key('fixtureResult_${match.week}'),
                  result: result,
                  selectedClubId: selectedClub.id,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FixtureResultBadge extends StatelessWidget {
  const _FixtureResultBadge({
    super.key,
    required this.result,
    required this.selectedClubId,
  });

  final CareerLeagueMatchResult result;
  final int selectedClubId;

  @override
  Widget build(BuildContext context) {
    final userIsHome = result.homeClubId == selectedClubId;
    final userGoals = userIsHome ? result.homeGoals : result.awayGoals;
    final opponentGoals = userIsHome ? result.awayGoals : result.homeGoals;
    final color = userGoals > opponentGoals
        ? const Color(0xFFC8FF4D)
        : userGoals < opponentGoals
        ? const Color(0xFFFF6577)
        : const Color(0xFFFFD65A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        '$userGoals - $opponentGoals',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StandingsSheet extends StatelessWidget {
  const _StandingsSheet({
    required this.league,
    required this.selectedClub,
    required this.results,
  });

  final CareerLeague league;
  final CareerClub selectedClub;
  final List<CareerLeagueMatchResult> results;

  @override
  Widget build(BuildContext context) {
    final standings = CareerLeagueSimulator.standings(
      league: league,
      results: results,
    );

    return SafeArea(
      top: false,
      child: SizedBox(
        key: const Key('standingsSheet'),
        height: MediaQuery.sizeOf(context).height * 0.84,
        child: Column(
          children: [
            const SizedBox(height: 9),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PUAN DURUMU',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${league.name} • 2026/27',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.42),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 34),
                  Expanded(
                    child: Text(
                      'TAKIM',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const _StandingsHeader(label: 'O'),
                  const _StandingsHeader(label: 'AV'),
                  const _StandingsHeader(label: 'P'),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: standings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final standing = standings[index];
                  final club = standing.club;
                  final selected = club.id == selectedClub.id;
                  return Container(
                    key: Key('standing_${club.id}'),
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFC8FF4D).withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFC8FF4D)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 25,
                          child: Text(
                            '${index + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFFC8FF4D)
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _ClubLogo(club: club, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            club.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StandingsValue(value: '${standing.played}'),
                        _StandingsValue(value: '${standing.goalDifference}'),
                        _StandingsValue(
                          value: '${standing.points}',
                          strong: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingsHeader extends StatelessWidget {
  const _StandingsHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.38),
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StandingsValue extends StatelessWidget {
  const _StandingsValue({required this.value, this.strong = false});

  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: strong ? const Color(0xFFC8FF4D) : Colors.white70,
          fontSize: 11,
          fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _ClubHeader extends StatelessWidget {
  const _ClubHeader({required this.offer});

  final ClubOffer offer;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          _ClubLogo(club: offer.club, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${offer.league.country} • ${offer.league.name}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFC8FF4D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${offer.club.rating}',
              style: const TextStyle(
                color: Color(0xFF092115),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamActionButton extends StatelessWidget {
  const _TeamActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFC8FF4D), size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: const Color(0xFFC8FF4D),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFC8FF4D).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFC8FF4D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFC8FF4D),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: Material(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8FF4D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: const Color(0xFFC8FF4D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(
                  enabled ? Icons.play_arrow_rounded : Icons.lock_rounded,
                  color: const Color(0xFFC8FF4D),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SquadPlayerRow extends StatelessWidget {
  const _SquadPlayerRow({
    required this.name,
    required this.position,
    required this.overall,
    this.isUser = false,
  });

  final String name;
  final String position;
  final int overall;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFFC8FF4D).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUser
              ? const Color(0xFFC8FF4D)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              position,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isUser ? '$name  (Sen)' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$overall',
            style: const TextStyle(
              color: Color(0xFFC8FF4D),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeGrid extends StatelessWidget {
  const _AttributeGrid({required this.profile});

  final CareerProfile profile;

  @override
  Widget build(BuildContext context) {
    final attributes = [
      ('PAC', profile.pace),
      ('SHO', profile.shooting),
      ('PAS', profile.passing),
      ('DRI', profile.dribbling),
      ('DEF', profile.defending),
      ('PHY', profile.physical),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attributes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final attribute = attributes[index];
        return _MetricTile(
          value: formatCareerAttribute(attribute.$2),
          label: attribute.$1,
        );
      },
    );
  }
}

class _ShopCategoryChip extends StatelessWidget {
  const _ShopCategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.level,
    required this.onTap,
  });

  final _ShopCategory category;
  final bool selected;
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFC8FF4D)
          : Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                category.icon,
                color: selected
                    ? const Color(0xFF092115)
                    : const Color(0xFFC8FF4D),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF092115)
                            : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+$level / +5',
                      style: TextStyle(
                        color: selected
                            ? const Color(0xAA092115)
                            : Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.currentLevel,
    required this.balanceEuro,
    required this.weeklySalaryEuro,
    required this.onBuy,
  });

  final _ShopItem item;
  final int currentLevel;
  final int balanceEuro;
  final int weeklySalaryEuro;
  final Future<void> Function(_ShopItem item) onBuy;

  @override
  Widget build(BuildContext context) {
    final owned = currentLevel >= item.bonus;
    final price = item.priceFor(weeklySalaryEuro, currentLevel: currentLevel);
    final affordable = balanceEuro >= price;
    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFC8FF4D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: const Color(0xFFC8FF4D), size: 25),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '+${item.bonus} ${_attributeShortLabel(item.attribute)}',
                      style: const TextStyle(
                        color: Color(0xFFC8FF4D),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      owned ? 'ALINDI' : _formatEuro(price),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: FilledButton(
              key: Key('buyShopItem_${item.id}'),
              onPressed: owned || !affordable ? null : () async => onBuy(item),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC8FF4D),
                foregroundColor: const Color(0xFF092115),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                owned
                    ? 'SAHİP'
                    : affordable
                    ? 'SATIN AL'
                    : 'YETERSİZ',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCategory {
  const _ShopCategory({
    required this.id,
    required this.title,
    required this.attribute,
    required this.attributeLabel,
    required this.icon,
    required this.items,
  });

  final String id;
  final String title;
  final String attribute;
  final String attributeLabel;
  final IconData icon;
  final List<_ShopItem> items;
}

class _ShopItem {
  const _ShopItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.attribute,
    required this.bonus,
    required this.icon,
  });

  final String id;
  final String categoryId;
  final String name;
  final String attribute;
  final int bonus;
  final IconData icon;

  int priceFor(int weeklySalaryEuro, {required int currentLevel}) {
    final upgradeLevels = bonus - currentLevel;
    if (upgradeLevels <= 0) return 0;
    return ((weeklySalaryEuro * upgradeLevels) / 250).round() * 250;
  }
}

String _attributeShortLabel(String attribute) => switch (attribute) {
  'pace' => 'PAC',
  'shooting' => 'SHO',
  'passing' => 'PAS',
  'dribbling' => 'DRI',
  'defending' => 'DEF',
  'physical' => 'PHY',
  _ => attribute.toUpperCase(),
};

const _shopCategories = <_ShopCategory>[
  _ShopCategory(
    id: 'vehicles',
    title: 'Araçlar',
    attribute: 'pace',
    attributeLabel: 'Hız',
    icon: Icons.directions_car_outlined,
    items: [
      _ShopItem(
        id: 'vehicle_1',
        categoryId: 'vehicles',
        name: 'Şehir Otomobili',
        attribute: 'pace',
        bonus: 1,
        icon: Icons.directions_car_outlined,
      ),
      _ShopItem(
        id: 'vehicle_2',
        categoryId: 'vehicles',
        name: 'Sportif Hatchback',
        attribute: 'pace',
        bonus: 2,
        icon: Icons.electric_car_outlined,
      ),
      _ShopItem(
        id: 'vehicle_3',
        categoryId: 'vehicles',
        name: 'GT Coupé',
        attribute: 'pace',
        bonus: 3,
        icon: Icons.time_to_leave_outlined,
      ),
      _ShopItem(
        id: 'vehicle_4',
        categoryId: 'vehicles',
        name: 'Süper Otomobil',
        attribute: 'pace',
        bonus: 4,
        icon: Icons.sports_motorsports_outlined,
      ),
      _ShopItem(
        id: 'vehicle_5',
        categoryId: 'vehicles',
        name: 'Özel Hypercar',
        attribute: 'pace',
        bonus: 5,
        icon: Icons.bolt_rounded,
      ),
    ],
  ),
  _ShopCategory(
    id: 'homes',
    title: 'Evler',
    attribute: 'physical',
    attributeLabel: 'Fizik',
    icon: Icons.home_outlined,
    items: [
      _ShopItem(
        id: 'home_1',
        categoryId: 'homes',
        name: 'Stüdyo Daire',
        attribute: 'physical',
        bonus: 1,
        icon: Icons.apartment_outlined,
      ),
      _ShopItem(
        id: 'home_2',
        categoryId: 'homes',
        name: 'Şehir Dairesi',
        attribute: 'physical',
        bonus: 2,
        icon: Icons.location_city_outlined,
      ),
      _ShopItem(
        id: 'home_3',
        categoryId: 'homes',
        name: 'Bahçeli Villa',
        attribute: 'physical',
        bonus: 3,
        icon: Icons.home_work_outlined,
      ),
      _ShopItem(
        id: 'home_4',
        categoryId: 'homes',
        name: 'Lüks Rezidans',
        attribute: 'physical',
        bonus: 4,
        icon: Icons.domain_outlined,
      ),
      _ShopItem(
        id: 'home_5',
        categoryId: 'homes',
        name: 'Özel Malikâne',
        attribute: 'physical',
        bonus: 5,
        icon: Icons.villa_outlined,
      ),
    ],
  ),
  _ShopCategory(
    id: 'boots',
    title: 'Krampon',
    attribute: 'shooting',
    attributeLabel: 'Şut',
    icon: Icons.ice_skating_outlined,
    items: [
      _ShopItem(
        id: 'boot_1',
        categoryId: 'boots',
        name: 'Akademi Kramponu',
        attribute: 'shooting',
        bonus: 1,
        icon: Icons.ice_skating_outlined,
      ),
      _ShopItem(
        id: 'boot_2',
        categoryId: 'boots',
        name: 'Kontrol Serisi',
        attribute: 'shooting',
        bonus: 2,
        icon: Icons.sports_soccer_outlined,
      ),
      _ShopItem(
        id: 'boot_3',
        categoryId: 'boots',
        name: 'Güç Serisi',
        attribute: 'shooting',
        bonus: 3,
        icon: Icons.flash_on_outlined,
      ),
      _ShopItem(
        id: 'boot_4',
        categoryId: 'boots',
        name: 'Profesyonel Elite',
        attribute: 'shooting',
        bonus: 4,
        icon: Icons.workspace_premium_outlined,
      ),
      _ShopItem(
        id: 'boot_5',
        categoryId: 'boots',
        name: 'İmza Kramponu',
        attribute: 'shooting',
        bonus: 5,
        icon: Icons.auto_awesome_outlined,
      ),
    ],
  ),
  _ShopCategory(
    id: 'technology',
    title: 'Teknoloji',
    attribute: 'passing',
    attributeLabel: 'Pas',
    icon: Icons.devices_outlined,
    items: [
      _ShopItem(
        id: 'tech_1',
        categoryId: 'technology',
        name: 'Akıllı Saat',
        attribute: 'passing',
        bonus: 1,
        icon: Icons.watch_outlined,
      ),
      _ShopItem(
        id: 'tech_2',
        categoryId: 'technology',
        name: 'Analiz Tableti',
        attribute: 'passing',
        bonus: 2,
        icon: Icons.tablet_mac_outlined,
      ),
      _ShopItem(
        id: 'tech_3',
        categoryId: 'technology',
        name: 'VR Oyun Görüşü',
        attribute: 'passing',
        bonus: 3,
        icon: Icons.view_in_ar_outlined,
      ),
      _ShopItem(
        id: 'tech_4',
        categoryId: 'technology',
        name: 'Taktik İstasyonu',
        attribute: 'passing',
        bonus: 4,
        icon: Icons.computer_outlined,
      ),
      _ShopItem(
        id: 'tech_5',
        categoryId: 'technology',
        name: 'AI Performans Labı',
        attribute: 'passing',
        bonus: 5,
        icon: Icons.memory_outlined,
      ),
    ],
  ),
  _ShopCategory(
    id: 'skills',
    title: 'Beceri',
    attribute: 'dribbling',
    attributeLabel: 'Dribbling',
    icon: Icons.sports_soccer_outlined,
    items: [
      _ShopItem(
        id: 'skill_1',
        categoryId: 'skills',
        name: 'Antrenman Topu',
        attribute: 'dribbling',
        bonus: 1,
        icon: Icons.sports_soccer_outlined,
      ),
      _ShopItem(
        id: 'skill_2',
        categoryId: 'skills',
        name: 'Slalom Seti',
        attribute: 'dribbling',
        bonus: 2,
        icon: Icons.traffic_outlined,
      ),
      _ShopItem(
        id: 'skill_3',
        categoryId: 'skills',
        name: 'Denge Tahtası',
        attribute: 'dribbling',
        bonus: 3,
        icon: Icons.balance_outlined,
      ),
      _ShopItem(
        id: 'skill_4',
        categoryId: 'skills',
        name: 'Reaksiyon Işıkları',
        attribute: 'dribbling',
        bonus: 4,
        icon: Icons.lightbulb_outline_rounded,
      ),
      _ShopItem(
        id: 'skill_5',
        categoryId: 'skills',
        name: 'Özel Beceri Sahası',
        attribute: 'dribbling',
        bonus: 5,
        icon: Icons.stadium_outlined,
      ),
    ],
  ),
  _ShopCategory(
    id: 'defense',
    title: 'Savunma',
    attribute: 'defending',
    attributeLabel: 'Defans',
    icon: Icons.shield_outlined,
    items: [
      _ShopItem(
        id: 'defense_1',
        categoryId: 'defense',
        name: 'Direnç Bandı',
        attribute: 'defending',
        bonus: 1,
        icon: Icons.linear_scale_rounded,
      ),
      _ShopItem(
        id: 'defense_2',
        categoryId: 'defense',
        name: 'Müdahale Mankeni',
        attribute: 'defending',
        bonus: 2,
        icon: Icons.sports_martial_arts_outlined,
      ),
      _ShopItem(
        id: 'defense_3',
        categoryId: 'defense',
        name: 'Reaksiyon Duvarı',
        attribute: 'defending',
        bonus: 3,
        icon: Icons.grid_4x4_rounded,
      ),
      _ShopItem(
        id: 'defense_4',
        categoryId: 'defense',
        name: 'İkili Mücadele Seti',
        attribute: 'defending',
        bonus: 4,
        icon: Icons.groups_outlined,
      ),
      _ShopItem(
        id: 'defense_5',
        categoryId: 'defense',
        name: 'Özel Savunma Sahası',
        attribute: 'defending',
        bonus: 5,
        icon: Icons.security_rounded,
      ),
    ],
  ),
];

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(13)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
      ),
      child: child,
    );
  }
}

class _ClubLogo extends StatelessWidget {
  const _ClubLogo({required this.club, required this.size});

  final CareerClub club;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = club.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Image.asset(
        'assets/clubs/${club.id}.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            initials,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.56),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

String _formatEuro(int amount) {
  var remaining = amount.toString();
  final groups = <String>[];
  while (remaining.length > 3) {
    groups.insert(0, remaining.substring(remaining.length - 3));
    remaining = remaining.substring(0, remaining.length - 3);
  }
  groups.insert(0, remaining);
  return '€${groups.join('.')}';
}

const _turkishMonths = [
  'OCAK',
  'ŞUBAT',
  'MART',
  'NİSAN',
  'MAYIS',
  'HAZİRAN',
  'TEMMUZ',
  'AĞUSTOS',
  'EYLÜL',
  'EKİM',
  'KASIM',
  'ARALIK',
];

String _monthYear(DateTime date) =>
    '${_turkishMonths[date.month - 1]} ${date.year}';

String _dayMonth(DateTime date) =>
    '${date.day} ${_turkishMonths[date.month - 1]}';

String _shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
