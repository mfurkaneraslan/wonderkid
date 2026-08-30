import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../career/career_profile.dart';

enum TrainingAttribute {
  pace,
  shooting,
  passing,
  dribbling,
  defending,
  physical,
}

extension TrainingAttributeLabel on TrainingAttribute {
  String get turkishLabel => switch (this) {
    TrainingAttribute.pace => 'Hız',
    TrainingAttribute.shooting => 'Şut',
    TrainingAttribute.passing => 'Pas',
    TrainingAttribute.dribbling => 'Dribbling',
    TrainingAttribute.defending => 'Defans',
    TrainingAttribute.physical => 'Fizik',
  };
}

class TrainingResult {
  const TrainingResult({
    required this.attribute,
    required this.score,
    required this.grade,
    required this.isSuccessful,
    required this.statIncrease,
  });

  final TrainingAttribute attribute;
  final int score;
  final String grade;
  final bool isSuccessful;
  final double statIncrease;
}

class TrainingGameScreen extends StatefulWidget {
  const TrainingGameScreen({
    super.key,
    required this.attribute,
    this.statIncrease = 1,
    this.playerAvatarAsset,
  });

  final TrainingAttribute attribute;
  final double statIncrease;
  final String? playerAvatarAsset;

  @override
  State<TrainingGameScreen> createState() => _TrainingGameScreenState();
}

class _TrainingGameScreenState extends State<TrainingGameScreen>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFFC8FF4D);
  static const _duration = 20;
  final Random _random = Random();
  late final AnimationController _meterController;
  Timer? _timer;
  Timer? _paceTickTimer;
  Timer? _dribbleTimer;
  DateTime? _lastDribbleTick;
  int _secondsLeft = _duration;
  int _lives = 3;
  int _score = 0;
  int _target = 0;
  bool _finished = false;
  bool? _lastSuccess;
  final List<_PaceTarget> _paceTargets = [];
  double _dribblePlayerX = 0.5;
  double _dribbleTrackWidth = 0;
  double _dribbleTrackHeight = 0;
  double _dribbleElapsed = 0;
  double _dribbleSpawnElapsed = 0;
  double _dribbleInvulnerability = 0;
  int _dribbleWave = 0;
  final List<_DribbleCone> _dribbleCones = [];

  @override
  void initState() {
    super.initState();
    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _nextChallenge(initial: true);
    _startTimer();
    _startPaceChallenge();
    _startDribblePhysics();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        _finish();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startDribblePhysics() {
    if (widget.attribute != TrainingAttribute.dribbling) return;
    _dribbleTimer?.cancel();
    _dribblePlayerX = 0.5;
    _dribbleElapsed = 0;
    _dribbleSpawnElapsed = 0;
    _dribbleInvulnerability = 0;
    _dribbleWave = 0;
    _dribbleCones.clear();
    _spawnDribbleWave(initial: true);
    _lastDribbleTick = DateTime.now();
    _dribbleTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updateDribblePhysics(),
    );
  }

  void _startPaceChallenge() {
    if (widget.attribute != TrainingAttribute.pace || _finished) return;
    _paceTickTimer?.cancel();
    _paceTargets.clear();
    _spawnPaceTarget();
    _paceTickTimer = Timer.periodic(
      const Duration(milliseconds: 20),
      (_) => _updatePaceTargets(),
    );
  }

  Duration get _paceResponseWindow {
    final elapsedRatio = ((_duration - _secondsLeft) / _duration).clamp(
      0.0,
      1.0,
    );
    return Duration(milliseconds: (700 - (elapsedRatio * 400)).round());
  }

  void _spawnPaceTarget() {
    final occupied = _paceTargets.map((target) => target.index).toSet();
    final available = [
      for (var index = 0; index < 9; index++)
        if (!occupied.contains(index)) index,
    ];
    if (available.isEmpty) return;
    _paceTargets.add(
      _PaceTarget(
        index: available[_random.nextInt(available.length)],
        duration: _paceResponseWindow.inMilliseconds / 1000,
      ),
    );
  }

  void _updatePaceTargets() {
    if (!mounted || _finished) return;
    var targetsToSpawn = 0;
    setState(() {
      final expiredTargets = <_PaceTarget>[];
      for (final target in _paceTargets) {
        target.elapsed += 0.02;
        if (!target.spawnedNext && target.elapsed >= target.duration / 2) {
          target.spawnedNext = true;
          targetsToSpawn++;
        }
        if (target.elapsed >= target.duration) {
          expiredTargets.add(target);
          _lastSuccess = false;
          _lives--;
        }
      }
      _paceTargets.removeWhere(expiredTargets.contains);
      for (var index = 0; index < targetsToSpawn; index++) {
        _spawnPaceTarget();
      }
      if (_paceTargets.isEmpty && _lives > 0) _spawnPaceTarget();
    });
    if (_lives <= 0) _finish();
  }

  void _answerPace(int selectedTarget) {
    if (_finished) return;
    setState(() {
      final targetIndex = _paceTargets.indexWhere(
        (target) => target.index == selectedTarget,
      );
      final success = targetIndex >= 0;
      _lastSuccess = success;
      if (success) {
        _paceTargets.removeAt(targetIndex);
        _score++;
      } else {
        _lives--;
      }
      if (_paceTargets.isEmpty && _lives > 0) _spawnPaceTarget();
    });
    if (_lives <= 0) _finish();
  }

  void _spawnDribbleWave({bool initial = false}) {
    final count = initial
        ? 1
        : switch (_dribbleElapsed) {
            < 6 => 1,
            < 10 => _dribbleWave.isEven ? 2 : 1,
            _ => 2 + (_dribbleWave % 3),
          };
    final positions = switch (count) {
      1 => [0.08 + (_random.nextDouble() * 0.84)],
      2 => [
        0.14 + (_random.nextDouble() * 0.12),
        0.74 + (_random.nextDouble() * 0.12),
      ],
      _ => [
        if (count == 3) ...[
          0.08 + (_random.nextDouble() * 0.05),
          0.47 + (_random.nextDouble() * 0.06),
          0.87 + (_random.nextDouble() * 0.05),
        ] else ...[
          0.07 + (_random.nextDouble() * 0.03),
          0.34 + (_random.nextDouble() * 0.03),
          0.63 + (_random.nextDouble() * 0.03),
          0.90 + (_random.nextDouble() * 0.03),
        ],
      ],
    };
    for (final x in positions) {
      _dribbleCones.add(
        _DribbleCone(
          x: x,
          y: -0.12,
          speed: 0.75 + (_random.nextDouble() * 0.15),
        ),
      );
    }
    _dribbleWave++;
  }

  void _updateDribblePhysics() {
    if (!mounted || _finished) return;
    final now = DateTime.now();
    final previous = _lastDribbleTick ?? now;
    _lastDribbleTick = now;
    final deltaSeconds = (now.difference(previous).inMicroseconds / 1000000)
        .clamp(0.0, 0.05);
    _dribbleElapsed += deltaSeconds;
    _dribbleSpawnElapsed += deltaSeconds;
    _dribbleInvulnerability = max(0, _dribbleInvulnerability - deltaSeconds);
    final speedMultiplier = 1 + ((_dribbleElapsed / _duration) * 1.1);
    final spawnInterval = 0.85 - ((_dribbleElapsed / _duration) * 0.4);
    var collision = false;
    final removedCones = <_DribbleCone>[];

    setState(() {
      for (final cone in _dribbleCones) {
        cone.y += cone.speed * speedMultiplier * deltaSeconds;
        final hitsPlayer =
            !collision &&
            _dribbleInvulnerability <= 0 &&
            _coneTouchesPlayer(cone);
        if (hitsPlayer) {
          collision = true;
          _lives--;
          _lastSuccess = false;
          _dribbleInvulnerability = 0.45;
          removedCones.add(cone);
        } else if (cone.y > 1.08) {
          _score++;
          _lastSuccess = true;
          removedCones.add(cone);
        }
      }
      _dribbleCones.removeWhere(removedCones.contains);
      if (_dribbleSpawnElapsed >= spawnInterval) {
        _dribbleSpawnElapsed = 0;
        _spawnDribbleWave();
      }
    });

    if (collision && _lives <= 0) _finish();
  }

  bool _coneTouchesPlayer(_DribbleCone cone) {
    if (_dribbleTrackWidth <= 0 || _dribbleTrackHeight <= 0) return false;
    const playerSize = 58.0;
    const coneSize = 42.0;
    final playerCenter = Offset(
      (_dribblePlayerX * (_dribbleTrackWidth - playerSize)) + (playerSize / 2),
      _dribbleTrackHeight - 30 - (playerSize / 2),
    );
    final coneCenter = Offset(
      (cone.x * (_dribbleTrackWidth - coneSize)) + (coneSize / 2),
      (cone.y * (_dribbleTrackHeight - coneSize)) + (coneSize / 2),
    );
    const contactDistance = 38.0;
    return (coneCenter - playerCenter).distanceSquared <=
        contactDistance * contactDistance;
  }

  void _nextChallenge({bool initial = false}) {
    switch (widget.attribute) {
      case TrainingAttribute.pace:
        break;
      case TrainingAttribute.shooting:
        _target = _differentRandom(9, initial ? -1 : _target);
        break;
      case TrainingAttribute.passing:
        _target = _differentRandom(4, initial ? -1 : _target);
        break;
      case TrainingAttribute.dribbling:
        _target = _differentRandom(3, initial ? -1 : _target);
        break;
      case TrainingAttribute.defending:
        _target = _differentRandom(2, initial ? -1 : _target);
        break;
      case TrainingAttribute.physical:
        break;
    }
  }

  int _differentRandom(int max, int previous) {
    var next = _random.nextInt(max);
    if (max > 1 && next == previous) next = (next + 1) % max;
    return next;
  }

  void _answer(bool success) {
    if (_finished) return;
    setState(() {
      _lastSuccess = success;
      if (success) {
        _score++;
      } else {
        _lives--;
      }
      _nextChallenge();
    });
    if (_lives <= 0) _finish();
  }

  void _finish() {
    if (_finished) return;
    _timer?.cancel();
    _paceTickTimer?.cancel();
    _dribbleTimer?.cancel();
    _meterController.stop();
    setState(() => _finished = true);
  }

  void _restart() {
    setState(() {
      _secondsLeft = _duration;
      _lives = 3;
      _score = 0;
      _finished = false;
      _lastSuccess = null;
      _nextChallenge(initial: true);
    });
    _meterController.repeat(reverse: true);
    _startTimer();
    _startPaceChallenge();
    _startDribblePhysics();
  }

  TrainingResult get _result {
    final grade = switch (_score) {
      >= 18 => 'S',
      >= 14 => 'A',
      >= 10 => 'B',
      >= 5 => 'C',
      _ => 'D',
    };
    return TrainingResult(
      attribute: widget.attribute,
      score: _score,
      grade: grade,
      isSuccessful: _secondsLeft == 0 && _lives > 0,
      statIncrease: widget.statIncrease,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _paceTickTimer?.cancel();
    _dribbleTimer?.cancel();
    _meterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _trainingInfo(widget.attribute);
    return Scaffold(
      key: const Key('trainingGameScreen'),
      backgroundColor: const Color(0xFF071A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          info.title.toUpperCase(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              child: _finished
                  ? _ResultView(result: _result, onRetry: _restart)
                  : _playView(info),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playView(_TrainingInfo info) {
    return Column(
      children: [
        Row(
          children: [
            _CounterPill(
              key: const Key('trainingTimer'),
              icon: Icons.timer_outlined,
              text: '$_secondsLeft sn',
            ),
            const Spacer(),
            Row(
              key: const Key('trainingLives'),
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    index < _lives
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: index < _lives
                        ? const Color(0xFFFF5E72)
                        : Colors.white24,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _CounterPill(icon: Icons.stars_rounded, text: '$_score'),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            children: [
              Icon(info.icon, color: _accent, size: 26),
              const SizedBox(height: 7),
              Text(
                info.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_lastSuccess != null) ...[
                const SizedBox(height: 5),
                Text(
                  _lastSuccess! ? 'HARİKA!' : 'HAKKINI KAYBETTİN',
                  style: TextStyle(
                    color: _lastSuccess! ? _accent : const Color(0xFFFF5E72),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _gameBody()),
      ],
    );
  }

  Widget _gameBody() => switch (widget.attribute) {
    TrainingAttribute.pace => _paceGame(),
    TrainingAttribute.shooting => _shootingGame(),
    TrainingAttribute.passing => _passingGame(),
    TrainingAttribute.dribbling => _dribblingGame(),
    TrainingAttribute.defending => _defendingGame(),
    TrainingAttribute.physical => _physicalGame(),
  };

  Widget _paceGame() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D492D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, index) {
              final targetPosition = _paceTargets.indexWhere(
                (target) => target.index == index,
              );
              final active = targetPosition >= 0;
              final target = active ? _paceTargets[targetPosition] : null;
              final brightness = target == null
                  ? 0.0
                  : (1 - (target.elapsed / target.duration)).clamp(0.0, 1.0);
              final activeOpacity = 0.25 + (brightness * 0.75);
              return InkWell(
                key: Key('paceTarget$index'),
                onTap: () => _answerPace(index),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  key: active ? Key('paceActiveTarget$index') : null,
                  decoration: BoxDecoration(
                    color: active
                        ? _accent.withValues(alpha: activeOpacity)
                        : const Color(0xFF123524),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? _accent.withValues(
                              alpha: 0.35 + (brightness * 0.65),
                            )
                          : Colors.white12,
                      width: 2,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: _accent.withValues(
                                alpha: brightness * 0.4,
                              ),
                              blurRadius: 18 * brightness,
                              spreadRadius: 2 * brightness,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    active ? Icons.bolt_rounded : Icons.circle_outlined,
                    size: active ? 42 : 18,
                    color: active
                        ? const Color(0xFF092115)
                              .withValues(alpha: 0.35 + (brightness * 0.65))
                        : Colors.white12,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _shootingGame() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.35,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0E442B),
            border: Border.all(color: Colors.white54, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (_, index) => InkWell(
              key: Key('shootingTarget$index'),
              onTap: () => _answer(index == _target),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: index == _target ? _accent : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Icon(
                  index == _target
                      ? Icons.adjust_rounded
                      : Icons.grid_3x3_rounded,
                  color: index == _target
                      ? const Color(0xFF092115)
                      : Colors.white12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passingGame() {
    const alignments = [
      Alignment(-0.75, -0.7),
      Alignment(0.75, -0.55),
      Alignment(-0.65, 0.65),
      Alignment(0.68, 0.72),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D492D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.sports_soccer_rounded,
              color: Colors.white24,
              size: 42,
            ),
          ),
          for (var index = 0; index < alignments.length; index++)
            Align(
              alignment: alignments[index],
              child: InkWell(
                key: Key('passingTarget$index'),
                onTap: () => _answer(index == _target),
                borderRadius: BorderRadius.circular(40),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: index == _target ? 72 : 62,
                  height: index == _target ? 72 : 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _target ? _accent : const Color(0xFF123524),
                    border: Border.all(
                      color: index == _target ? _accent : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: index == _target
                        ? const Color(0xFF092115)
                        : Colors.white60,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dribblingGame() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const playerSize = 58.0;
        const coneSize = 42.0;
        _dribbleTrackWidth = constraints.maxWidth;
        _dribbleTrackHeight = constraints.maxHeight;
        final playableWidth = max(1.0, constraints.maxWidth - playerSize);
        final coneWidth = max(1.0, constraints.maxWidth - coneSize);
        final playableHeight = max(1.0, constraints.maxHeight - coneSize);
        return GestureDetector(
          key: const Key('dribblingDragArea'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dribblePlayerX =
                  (_dribblePlayerX + (details.delta.dx / constraints.maxWidth))
                      .clamp(0.0, 1.0);
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D492D),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: const _DribbleTrackPainter()),
                  ),
                  for (var index = 0; index < _dribbleCones.length; index++)
                    Positioned(
                      key: Key('dribblingCone$index'),
                      left: _dribbleCones[index].x * coneWidth,
                      top: _dribbleCones[index].y * playableHeight,
                      child: const _ConeMarker(size: coneSize),
                    ),
                  Positioned(
                    key: const Key('dribblingPlayer'),
                    left: _dribblePlayerX * playableWidth,
                    bottom: 30,
                    child: _DribblePlayer(
                      size: playerSize,
                      avatarAsset: widget.playerAvatarAsset,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 5,
                    child: Text(
                      'PARMAĞINI SAĞA • SOLA SÜRÜKLE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _defendingGame() {
    final left = _target == 0;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_run_rounded, size: 48),
                  Icon(
                    left ? Icons.west_rounded : Icons.east_rounded,
                    color: _accent,
                    size: 54,
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _CompactAction(
                key: const Key('defendingLeftButton'),
                icon: Icons.chevron_left_rounded,
                label: 'SOLU KAPAT',
                onTap: () => _answer(left),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactAction(
                key: const Key('defendingRightButton'),
                icon: Icons.chevron_right_rounded,
                label: 'SAĞI KAPAT',
                onTap: () => _answer(!left),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _physicalGame() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _meterController,
          builder: (_, child) => Column(
            children: [
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFFF5E72),
                            Color(0xFFC8FF4D),
                            Color(0xFFFF5E72),
                          ],
                          stops: [0, 0.5, 1],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(0, (_meterController.value * 2) - 1),
                      child: Container(
                        width: 92,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _CompactAction(
          key: const Key('physicalStopButton'),
          icon: Icons.pan_tool_alt_rounded,
          label: 'DENGEDE TUT',
          onTap: () {
            final value = _meterController.value;
            _answer(value >= 0.36 && value <= 0.64);
          },
        ),
      ],
    );
  }
}

class _PaceTarget {
  _PaceTarget({required this.index, required this.duration});

  final int index;
  final double duration;
  double elapsed = 0;
  bool spawnedNext = false;
}

class _DribbleCone {
  _DribbleCone({required this.x, required this.y, required this.speed});

  double x;
  double y;
  double speed;
}

class _ConeMarker extends StatelessWidget {
  const _ConeMarker({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.change_history_rounded,
            color: const Color(0xFFFF9A45),
            size: size,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 7)],
          ),
          Positioned(
            bottom: 5,
            child: Container(
              width: size * 0.7,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC46B),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DribblePlayer extends StatelessWidget {
  const _DribblePlayer({required this.size, this.avatarAsset});

  final double size;
  final String? avatarAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFC8FF4D),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8FF4D).withValues(alpha: 0.3),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipOval(
        child: avatarAsset == null
            ? const ColoredBox(
                color: Color(0xFF123524),
                child: Icon(Icons.person_rounded, color: Colors.white),
              )
            : Image.asset(avatarAsset!, fit: BoxFit.cover),
      ),
    );
  }
}

class _DribbleTrackPainter extends CustomPainter {
  const _DribbleTrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 2;
    for (var x = size.width / 4; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stripe);
    }
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.5;
    for (var y = 18.0; y < size.height; y += 42) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, min(y + 20, size.height)),
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onRetry});

  final TrainingResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('trainingResult'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 118,
          height: 118,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFC8FF4D),
            shape: BoxShape.circle,
          ),
          child: Text(
            result.grade,
            style: const TextStyle(
              color: Color(0xFF092115),
              fontSize: 62,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'ANTRENMAN TAMAMLANDI',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          result.isSuccessful
              ? '${result.score} doğru hamle  •  ${result.attribute.turkishLabel} +${formatCareerAttribute(result.statIncrease)}'
              : '${result.score} doğru hamle  •  Gelişim kazanamadın',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          result.isSuccessful
              ? 'Başarılı antrenman!'
              : 'Süre dolmadan 3 hakkın da bitti.',
          style: TextStyle(
            color: result.isSuccessful
                ? const Color(0xFFC8FF4D)
                : const Color(0xFFFFC46B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 38),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            key: const Key('finishTrainingButton'),
            onPressed: () => Navigator.of(context).pop(result),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC8FF4D),
              foregroundColor: const Color(0xFF092115),
            ),
            child: const Text(
              'ANTRENMANA DÖN',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          key: const Key('retryTrainingButton'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('TEKRAR OYNA'),
        ),
      ],
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFFC8FF4D)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
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
    return SizedBox(
      height: 60,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFC8FF4D),
          foregroundColor: const Color(0xFF092115),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
    );
  }
}

class _TrainingInfo {
  const _TrainingInfo({
    required this.title,
    required this.instruction,
    required this.icon,
  });

  final String title;
  final String instruction;
  final IconData icon;
}

_TrainingInfo _trainingInfo(TrainingAttribute attribute) => switch (attribute) {
  TrainingAttribute.pace => const _TrainingInfo(
    title: 'Hız',
    instruction: 'Parlayan hedef sönmeden dokun.',
    icon: Icons.speed_rounded,
  ),
  TrainingAttribute.shooting => const _TrainingInfo(
    title: 'Şut',
    instruction: 'Kalede parlayan hedefi vur.',
    icon: Icons.sports_soccer_rounded,
  ),
  TrainingAttribute.passing => const _TrainingInfo(
    title: 'Pas',
    instruction: 'Parlayan takım arkadaşına pas ver.',
    icon: Icons.route_rounded,
  ),
  TrainingAttribute.dribbling => const _TrainingInfo(
    title: 'Dribbling',
    instruction: 'Oyuncunu sürükle, akan konilerden kaç.',
    icon: Icons.multiple_stop_rounded,
  ),
  TrainingAttribute.defending => const _TrainingInfo(
    title: 'Defans',
    instruction: 'Rakibin gittiği tarafı kapat.',
    icon: Icons.shield_outlined,
  ),
  TrainingAttribute.physical => const _TrainingInfo(
    title: 'Fizik',
    instruction: 'Gösterge yeşil merkeze gelince durdur.',
    icon: Icons.fitness_center_rounded,
  ),
};
