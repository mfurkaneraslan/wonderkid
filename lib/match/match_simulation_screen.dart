import 'dart:async';

import 'package:flutter/material.dart';

import '../career/career_profile.dart';
import 'match_simulation.dart';

class MatchSimulationScreen extends StatefulWidget {
  const MatchSimulationScreen({
    super.key,
    required this.profile,
    required this.leagueName,
    required this.simulation,
  });

  final CareerProfile profile;
  final String leagueName;
  final CareerMatchSimulation simulation;

  @override
  State<MatchSimulationScreen> createState() => _MatchSimulationScreenState();
}

class _MatchSimulationScreenState extends State<MatchSimulationScreen> {
  Timer? _timer;
  Timer? _goalTimer;
  int _minute = 0;
  bool _started = false;
  bool _finished = false;
  CareerMatchEvent? _goalBanner;

  List<CareerMatchEvent> get _visibleEvents => widget.simulation.events
      .where((event) => event.minute <= _minute)
      .toList(growable: false);

  int get _homeGoals =>
      _visibleEvents.where((event) => event.isHomeGoal).length;
  int get _awayGoals =>
      _visibleEvents.where((event) => !event.isHomeGoal).length;

  void _startMatch() {
    if (_started) return;
    setState(() => _started = true);
    _scheduleTick();
  }

  void _scheduleTick([Duration delay = const Duration(milliseconds: 38)]) {
    _timer = Timer(delay, () {
      if (!mounted || _finished) return;
      final nextMinute = (_minute + 1).clamp(0, 90);
      final goal = widget.simulation.events
          .where((event) => event.minute == nextMinute)
          .firstOrNull;
      setState(() {
        _minute = nextMinute;
        if (goal != null) _goalBanner = goal;
      });
      if (goal != null) {
        _goalTimer?.cancel();
        _goalTimer = Timer(const Duration(milliseconds: 850), () {
          if (mounted) setState(() => _goalBanner = null);
        });
      }
      if (_minute >= 90) {
        _finishMatch();
      } else {
        _scheduleTick(
          goal == null
              ? const Duration(milliseconds: 38)
              : const Duration(milliseconds: 900),
        );
      }
    });
  }

  void _finishMatch() {
    _timer?.cancel();
    setState(() {
      _minute = 90;
      _finished = true;
      _goalBanner = null;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _goalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simulation = widget.simulation;
    if (_finished) {
      return _MatchPerformanceSummary(
        profile: widget.profile,
        leagueName: widget.leagueName,
        simulation: simulation,
        onContinue: () => Navigator.of(context).pop(simulation),
      );
    }
    return Scaffold(
      key: const Key('matchSimulationScreen'),
      backgroundColor: const Color(0xFF071A12),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('backFromMatchButton'),
                      onPressed: _started && !_finished
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'MAÇ GÜNÜ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.leagueName} • ${simulation.fixture.week}. HAFTA',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 14),
                _SquadStatusCard(
                  profile: widget.profile,
                  simulation: simulation,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF174D31), Color(0xFF0D2B1D)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ScoreClub(
                              id: simulation.homeClub.id,
                              name: simulation.homeClub.name,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                Text(
                                  _started ? "$_minute'" : '—',
                                  key: const Key('matchMinute'),
                                  style: const TextStyle(
                                    color: Color(0xFFC8FF4D),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_homeGoals  -  $_awayGoals',
                                  key: const Key('liveScore'),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _ScoreClub(
                              id: simulation.awayClub.id,
                              name: simulation.awayClub.name,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: _minute / 90,
                          backgroundColor: Colors.white10,
                          color: const Color(0xFFC8FF4D),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _goalBanner == null
                            ? Text(
                                !_started
                                    ? 'Maçı başlatmaya hazırsın.'
                                    : _finished
                                    ? 'MAÇ BİTTİ'
                                    : 'Maç oynanıyor...',
                                key: ValueKey('status_$_started$_finished'),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : Container(
                                key: ValueKey(_goalBanner!.minute),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC8FF4D),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66C8FF4D),
                                      blurRadius: 28,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _goalBanner!.isHomeGoal ==
                                          simulation.fixture.isHome
                                      ? 'GOOOL!'
                                      : 'GOL!',
                                  style: const TextStyle(
                                    color: Color(0xFF092115),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _EventPanel(events: _visibleEvents.reversed.toList()),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    key: const Key('matchPrimaryButton'),
                    onPressed: _started ? null : _startMatch,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC8FF4D),
                      foregroundColor: const Color(0xFF092115),
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'MAÇI BAŞLAT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SquadStatusCard extends StatelessWidget {
  const _SquadStatusCard({required this.profile, required this.simulation});

  final CareerProfile profile;
  final CareerMatchSimulation simulation;

  @override
  Widget build(BuildContext context) {
    final detail = switch (simulation.squadStatus) {
      PlayerSquadStatus.starting =>
        '${profile.position} • İlk düdükle sahadasın',
      PlayerSquadStatus.substitute =>
        '${profile.position} • ${simulation.entryMinute}. dakikada oyuna gireceksin',
      PlayerSquadStatus.out => '${profile.position} • Bu maçta forma şansı yok',
    };
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFC8FF4D).withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded, color: Color(0xFFC8FF4D)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  simulation.squadStatus.label,
                  key: const Key('squadStatus'),
                  style: const TextStyle(
                    color: Color(0xFFC8FF4D),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreClub extends StatelessWidget {
  const _ScoreClub({required this.id, required this.name});

  final int id;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Image.asset(
            'assets/clubs/$id.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.shield_rounded, size: 42),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _EventPanel extends StatelessWidget {
  const _EventPanel({required this.events});

  final List<CareerMatchEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white10),
      ),
      child: events.isEmpty
          ? const Center(
              child: Text(
                'Henüz gol olmadı.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            )
          : Column(
              children: [
                for (final event in events.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: Text(
                            "${event.minute}'",
                            style: const TextStyle(
                              color: Color(0xFFC8FF4D),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(Icons.sports_soccer_rounded, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.assist == null
                                ? event.scorer
                                : '${event.scorer}  •  Asist: ${event.assist}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
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

class _MatchPerformanceSummary extends StatelessWidget {
  const _MatchPerformanceSummary({
    required this.profile,
    required this.leagueName,
    required this.simulation,
    required this.onContinue,
  });

  final CareerProfile profile;
  final String leagueName;
  final CareerMatchSimulation simulation;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final rating = simulation.playerRating;
    return Scaffold(
      key: const Key('matchPerformanceSummary'),
      backgroundColor: const Color(0xFF071A12),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  const Text(
                    'MAÇ SONU',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$leagueName • ${simulation.fixture.week}. HAFTA',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF174D31), Color(0xFF0D2B1D)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ScoreClub(
                            id: simulation.homeClub.id,
                            name: simulation.homeClub.name,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${simulation.homeGoals}  -  ${simulation.awayGoals}',
                            key: const Key('finalScore'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ScoreClub(
                            id: simulation.awayClub.id,
                            name: simulation.awayClub.name,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    key: const Key('playerMatchResult'),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102A1D),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          profile.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rating == null ? '—' : rating.toStringAsFixed(1),
                          key: const Key('playerMatchRating'),
                          style: const TextStyle(
                            color: Color(0xFFC8FF4D),
                            fontSize: 46,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '10 ÜZERİNDEN MAÇ PUANI',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 18),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          childAspectRatio: 1.55,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            _ResultValue(
                              label: 'GOL',
                              value: '${simulation.playerGoals}',
                            ),
                            _ResultValue(
                              label: 'ASİST',
                              value: '${simulation.playerAssists}',
                            ),
                            _ResultValue(
                              label: 'ŞUT',
                              value: '${simulation.playerShots}',
                            ),
                            _ResultValue(
                              label: 'İSABETLİ ŞUT',
                              value: '${simulation.playerShotsOnTarget}',
                            ),
                            _ResultValue(
                              label: 'TOP KAYBI',
                              value: '${simulation.playerTurnovers}',
                            ),
                            _ResultValue(
                              label: 'OYNANAN DK',
                              value: '${simulation.minutesPlayed}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton.icon(
                      key: const Key('continueAfterMatchButton'),
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC8FF4D),
                        foregroundColor: const Color(0xFF092115),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      label: const Text(
                        'DEVAM ET',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFC8FF4D),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
