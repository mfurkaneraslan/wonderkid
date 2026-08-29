import 'package:flutter/material.dart';

import 'career/career_profile.dart';
import 'career/fixture_generator.dart';
import 'career/offer_generator.dart';
import 'data/football_repository.dart';

class CareerDashboardScreen extends StatefulWidget {
  const CareerDashboardScreen({
    super.key,
    required this.profile,
    required this.offer,
  });

  final CareerProfile profile;
  final ClubOffer offer;

  @override
  State<CareerDashboardScreen> createState() => _CareerDashboardScreenState();
}

class _CareerDashboardScreenState extends State<CareerDashboardScreen> {
  static const _accent = Color(0xFFC8FF4D);
  int _selectedIndex = 0;
  late final CareerSeasonFixture _fixture;

  @override
  void initState() {
    super.initState();
    _fixture = CareerFixtureGenerator.generate(
      league: widget.offer.league,
      club: widget.offer.club,
      seed: widget.profile.seed,
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
      builder: (_) =>
          _FixtureSheet(fixture: _fixture, league: widget.offer.league),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OverviewTab(
        profile: widget.profile,
        offer: widget.offer,
        fixture: _fixture,
        onOpenTraining: () => setState(() => _selectedIndex = 1),
        onOpenFixture: _showFixture,
      ),
      _TrainingTab(profile: widget.profile),
      _TeamTab(profile: widget.profile, offer: widget.offer),
      const _ShopTab(),
    ];

    return Scaffold(
      key: const Key('careerDashboard'),
      backgroundColor: const Color(0xFF071A12),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
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

  static const _titles = ['KARİYER MERKEZİ', 'ANTRENMAN', 'TAKIM', 'ALIŞVERİŞ'];
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.profile,
    required this.offer,
    required this.fixture,
    required this.onOpenTraining,
    required this.onOpenFixture,
  });

  final CareerProfile profile;
  final ClubOffer offer;
  final CareerSeasonFixture fixture;
  final VoidCallback onOpenTraining;
  final VoidCallback onOpenFixture;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _SeasonDateStrip(fixture: fixture),
          const SizedBox(height: 10),
          _ClubHeader(offer: offer),
          const SizedBox(height: 12),
          _PlayerHero(profile: profile, offer: offer),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(value: '${profile.overall}', label: 'OVR'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(value: '${profile.age}', label: 'YAŞ'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  value: _formatEuro(offer.weeklySalaryEuro),
                  label: 'HAFTALIK',
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NextMatchCard(
            fixture: fixture,
            club: offer.club,
            league: offer.league,
            onOpenFixture: onOpenFixture,
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFC8FF4D),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              key: const Key('openTrainingButton'),
              onTap: onOpenTraining,
              borderRadius: BorderRadius.circular(18),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      color: Color(0xFF092115),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İLK ANTRENMANINA ÇIK',
                            style: TextStyle(
                              color: Color(0xFF092115),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gelişim puanı kazan ve özelliklerini yükselt.',
                            style: TextStyle(
                              color: Color(0xB3092115),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF092115)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'OYUNCU ÖZELLİKLERİ'),
          const SizedBox(height: 9),
          _AttributeGrid(profile: profile),
        ],
      ),
    );
  }
}

class _TrainingTab extends StatelessWidget {
  const _TrainingTab({required this.profile});

  final CareerProfile profile;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _StatusBanner(
            icon: Icons.bolt_rounded,
            title: 'GELİŞİM PUANI',
            value: '0',
            subtitle: 'Antrenman yaparak puan kazan.',
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'BU HAFTANIN PROGRAMI'),
          const SizedBox(height: 9),
          const _TrainingCard(
            icon: Icons.speed_rounded,
            title: 'Hız ve Çeviklik',
            detail: 'Tempo • Sprint • Top kontrolü',
            reward: '+2 GP',
          ),
          const SizedBox(height: 8),
          const _TrainingCard(
            icon: Icons.sports_soccer_rounded,
            title: 'Bitiricilik',
            detail: 'Şut • Pozisyon alma • Soğukkanlılık',
            reward: '+2 GP',
          ),
          const SizedBox(height: 8),
          const _TrainingCard(
            icon: Icons.route_rounded,
            title: 'Pas Oyunu',
            detail: 'Kısa pas • Uzun pas • Vizyon',
            reward: '+2 GP',
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
  const _TeamTab({required this.profile, required this.offer});

  final CareerProfile profile;
  final ClubOffer offer;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _ClubHeader(offer: offer),
          const SizedBox(height: 12),
          _StatusBanner(
            icon: Icons.shield_outlined,
            title: 'KADRO ROLÜ',
            value: offer.role,
            subtitle: '${profile.position} • #${profile.shirtNumber}',
            valueSmall: true,
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'FORMA REKABETİ'),
          const SizedBox(height: 9),
          _SquadPlayerRow(
            name: profile.name,
            position: profile.position,
            overall: profile.overall,
            isUser: true,
          ),
          for (final competitor in offer.competitors) ...[
            const SizedBox(height: 7),
            _SquadPlayerRow(
              name: competitor.shortName,
              position: competitor.positions.first,
              overall: competitor.overall,
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

class _ShopTab extends StatelessWidget {
  const _ShopTab();

  @override
  Widget build(BuildContext context) {
    return const _PageFrame(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBanner(
              icon: Icons.account_balance_wallet_outlined,
              title: 'BAKİYE',
              value: '€0',
              subtitle: 'Maaş ödemeleriyle bakiyen artacak.',
            ),
            SizedBox(height: 18),
            _SectionTitle(title: 'KATEGORİLER'),
            SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _ShopCategory(
                    icon: Icons.ice_skating_outlined,
                    title: 'Krampon',
                    subtitle: 'Performans',
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: _ShopCategory(
                    icon: Icons.watch_outlined,
                    title: 'Aksesuar',
                    subtitle: 'Stil',
                  ),
                ),
              ],
            ),
            SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _ShopCategory(
                    icon: Icons.directions_car_outlined,
                    title: 'Araçlar',
                    subtitle: 'Yaşam tarzı',
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: _ShopCategory(
                    icon: Icons.home_outlined,
                    title: 'Evler',
                    subtitle: 'Yaşam tarzı',
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            _InfoPanel(
              icon: Icons.lock_outline_rounded,
              text: 'Alışveriş ürünleri kariyer ilerledikçe ve maaş kazandıkça açılacak.',
            ),
          ],
        ),
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
  const _SeasonDateStrip({required this.fixture});

  final CareerSeasonFixture fixture;

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
            _monthYear(fixture.startDate),
            key: const Key('careerDate'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            '${fixture.seasonYear} • 1. HAFTA',
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
    required this.club,
    required this.league,
    required this.onOpenFixture,
  });

  final CareerSeasonFixture fixture;
  final CareerClub club;
  final CareerLeague league;
  final VoidCallback onOpenFixture;

  @override
  Widget build(BuildContext context) {
    final match = fixture.nextMatch;
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
  const _FixtureSheet({required this.fixture, required this.league});

  final CareerSeasonFixture fixture;
  final CareerLeague league;

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
            Expanded(child: _FixtureList(matches: fixture.matches)),
          ],
        ),
      ),
    );
  }
}

class _FixtureList extends StatelessWidget {
  const _FixtureList({required this.matches});

  final List<CareerFixtureMatch> matches;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final match = matches[index];
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
              Text(
                _shortDate(match.date),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
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

class _PlayerHero extends StatelessWidget {
  const _PlayerHero({required this.profile, required this.offer});

  final CareerProfile profile;
  final ClubOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174D31), Color(0xFF0D2B1D)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8FF4D)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              profile.avatarAssetPath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: 228,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.position}  •  #${profile.shirtNumber}  •  ${profile.nationality}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  offer.role.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFC8FF4D),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    this.compact = false,
  });

  final String value;
  final String label;
  final bool compact;

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
                fontSize: compact ? 16 : 20,
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
    this.valueSmall = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool valueSmall;

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
                    fontSize: valueSmall ? 17 : 24,
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
    required this.icon,
    required this.title,
    required this.detail,
    required this.reward,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC8FF4D)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            reward,
            style: const TextStyle(
              color: Color(0xFFC8FF4D),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
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
        return _MetricTile(value: '${attribute.$2}', label: attribute.$1);
      },
    );
  }
}

class _ShopCategory extends StatelessWidget {
  const _ShopCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC8FF4D), size: 28),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

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
