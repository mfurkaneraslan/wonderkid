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
  late final AnimationController _shotController;
  Timer? _timer;
  Timer? _paceTickTimer;
  Timer? _dribbleTimer;
  Timer? _passingPreviewTimer;
  Timer? _physicalTimer;
  DateTime? _lastDribbleTick;
  int _secondsLeft = _duration;
  int _lives = 3;
  int _score = 0;
  int _target = 0;
  bool _finished = false;
  bool? _lastSuccess;
  final List<_PaceTarget> _paceTargets = [];
  double _shotAim = 0;
  double _shotPower = 0;
  double _shotFieldHeight = 0;
  bool _shotAnimating = false;
  _ShotOutcome? _shotOutcome;
  String? _shotFeedback;
  double _dribblePlayerX = 0.5;
  double _dribbleTrackWidth = 0;
  double _dribbleTrackHeight = 0;
  double _dribbleElapsed = 0;
  double _dribbleSpawnElapsed = 0;
  double _dribbleInvulnerability = 0;
  int _dribbleWave = 0;
  final List<_DribbleCone> _dribbleCones = [];
  List<int> _passingPattern = [];
  final List<int> _passingInput = [];
  int _passingRevealStep = 0;
  bool _passingShowingPattern = false;
  bool _passingLocked = false;
  Offset? _passingPointer;
  double _physicalPosition = 0;
  double _physicalVelocity = 0;
  double _physicalDrift = 0;
  double _physicalDriftElapsed = 0;
  bool _physicalLeftHeld = false;
  bool _physicalRightHeld = false;

  @override
  void initState() {
    super.initState();
    _shotController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 720),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _completeShot();
        });
    _nextChallenge(initial: true);
    _startTimer();
    _startPaceChallenge();
    _startDribblePhysics();
    _startPassingPattern(initial: true);
    _startPhysicalBalance(initial: true);
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.attribute == TrainingAttribute.passing) return;
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

  void _startPassingPattern({bool initial = false}) {
    if (widget.attribute != TrainingAttribute.passing || _finished) return;
    _passingPreviewTimer?.cancel();
    final pattern = _generatePassingPattern(5 + _random.nextInt(5));

    void resetPattern() {
      _passingPattern = pattern;
      _passingInput.clear();
      _passingPointer = null;
      _passingRevealStep = 1;
      _passingShowingPattern = true;
      _passingLocked = true;
    }

    if (initial) {
      resetPattern();
    } else {
      setState(resetPattern);
    }

    final stepDuration = Duration(
      milliseconds: (2000 / pattern.length).round(),
    );
    _passingPreviewTimer = Timer.periodic(stepDuration, (timer) {
      if (!mounted || _finished) {
        timer.cancel();
        return;
      }
      if (_passingRevealStep >= _passingPattern.length) {
        timer.cancel();
        setState(() {
          _passingShowingPattern = false;
          _passingLocked = false;
          _passingRevealStep = 0;
        });
      } else {
        setState(() => _passingRevealStep++);
      }
    });
  }

  void _recordPassingPoint(Offset position, Size size) {
    if (_finished || _passingLocked || _passingShowingPattern) return;
    final node = _passingNodeAt(position, size);
    setState(() {
      _passingPointer = position;
      if (node != null && !_passingInput.contains(node)) {
        if (_passingInput.isNotEmpty) {
          final midpoint = _passingMidpoint(_passingInput.last, node);
          if (midpoint != null && !_passingInput.contains(midpoint)) {
            _passingInput.add(midpoint);
          }
        }
        _passingInput.add(node);
      }
    });
  }

  List<int> _generatePassingPattern(int targetLength) {
    final pattern = <int>[_random.nextInt(9)];
    while (pattern.length < targetLength) {
      final candidates = List<int>.generate(9, (index) => index)
        ..removeWhere(pattern.contains)
        ..shuffle(_random);
      var added = false;
      for (final candidate in candidates) {
        final midpoint = _passingMidpoint(pattern.last, candidate);
        final needsMidpoint = midpoint != null && !pattern.contains(midpoint);
        final requiredSlots = needsMidpoint ? 2 : 1;
        if (pattern.length + requiredSlots > targetLength) continue;
        if (needsMidpoint) pattern.add(midpoint);
        pattern.add(candidate);
        added = true;
        break;
      }
      if (!added) {
        return _generatePassingPattern(targetLength);
      }
    }
    return pattern;
  }

  void _submitPassingPattern() {
    if (_finished || _passingLocked || _passingInput.isEmpty) return;
    final success =
        _passingInput.length == _passingPattern.length &&
        List.generate(
          _passingPattern.length,
          (index) => _passingInput[index] == _passingPattern[index],
        ).every((matches) => matches);
    setState(() {
      _passingLocked = true;
      _passingPointer = null;
      _lastSuccess = success;
      if (success) {
        _score++;
      } else {
        _lives--;
      }
    });

    if (_score >= 4 || _lives <= 0) {
      _finish();
    } else {
      _startPassingPattern();
    }
  }

  int? _passingNodeAt(Offset position, Size size) {
    final centers = _passingCenters(size);
    final hitRadius = min(size.width, size.height) * 0.11;
    for (var index = 0; index < centers.length; index++) {
      if ((position - centers[index]).distance <= hitRadius) return index;
    }
    return null;
  }

  void _startPhysicalBalance({bool initial = false}) {
    if (widget.attribute != TrainingAttribute.physical || _finished) return;
    _physicalTimer?.cancel();

    void resetBalance() {
      _physicalPosition = 0;
      _physicalVelocity = 0;
      _physicalDrift = _random.nextBool() ? 0.55 : -0.55;
      _physicalDriftElapsed = 0;
      _physicalLeftHeld = false;
      _physicalRightHeld = false;
    }

    if (initial) {
      resetBalance();
    } else {
      setState(resetBalance);
    }
    _physicalTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updatePhysicalBalance(),
    );
  }

  void _updatePhysicalBalance() {
    if (!mounted ||
        _finished ||
        widget.attribute != TrainingAttribute.physical) {
      return;
    }
    const deltaSeconds = 0.016;
    final elapsedRatio = ((_duration - _secondsLeft) / _duration).clamp(
      0.0,
      1.0,
    );
    final difficulty = 1 + (elapsedRatio * 1.9);
    final driftInterval = 0.75 - (elapsedRatio * 0.38);
    var fell = false;

    setState(() {
      _physicalDriftElapsed += deltaSeconds;
      if (_physicalDriftElapsed >= driftInterval) {
        _physicalDriftElapsed = 0;
        var nextDrift = (_random.nextDouble() * 2) - 1;
        if (nextDrift.abs() < 0.32) {
          nextDrift = nextDrift.isNegative ? -0.32 : 0.32;
        }
        _physicalDrift = nextDrift;
        _physicalVelocity += _physicalDrift * 0.055 * difficulty;
      }

      final control =
          (_physicalRightHeld ? 1.0 : 0.0) - (_physicalLeftHeld ? 1.0 : 0.0);
      final outwardPull = _physicalPosition * 0.72 * difficulty;
      final randomPull = _physicalDrift * 0.48 * difficulty;
      _physicalVelocity +=
          (outwardPull + randomPull + (control * 2.75)) * deltaSeconds;
      _physicalVelocity *= 0.987 - (elapsedRatio * 0.003);
      _physicalPosition += _physicalVelocity * deltaSeconds;

      if (_physicalPosition.abs() >= 1) {
        fell = true;
        _lives--;
        _lastSuccess = false;
        _physicalPosition = 0;
        _physicalVelocity = 0;
        _physicalDrift = _random.nextBool() ? 0.55 : -0.55;
        _physicalDriftElapsed = 0;
      }
    });

    if (fell && _lives <= 0) _finish();
  }

  void _setPhysicalControl(int direction, bool pressed) {
    if (_finished || widget.attribute != TrainingAttribute.physical) return;
    setState(() {
      if (direction < 0) {
        _physicalLeftHeld = pressed;
      } else {
        _physicalRightHeld = pressed;
      }
      if (pressed) {
        _physicalVelocity += direction * 0.065;
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

  void _beginShot(DragStartDetails details) {
    if (_finished || _shotAnimating) return;
    setState(() {
      _shotAim = 0;
      _shotPower = 0;
      _shotFeedback = null;
    });
  }

  void _releaseShot(DragEndDetails details) {
    if (_finished || _shotAnimating || _shotFieldHeight <= 0) return;
    // Power comes only from the release velocity. Holding the ball or moving it
    // back and forth therefore cannot be used to tune the shot meter.
    final upwardVelocity = max(0.0, -details.velocity.pixelsPerSecond.dy);
    final power = (upwardVelocity / 2400).clamp(0.0, 1.0);
    final aim = upwardVelocity <= 0
        ? 0.0
        : (details.velocity.pixelsPerSecond.dx / upwardVelocity).clamp(
            -1.4,
            1.4,
          );
    final _ShotOutcome outcome;
    if (power < 0.28) {
      outcome = _ShotOutcome.weak;
    } else if (power > 0.70) {
      outcome = _ShotOutcome.over;
    } else if (aim.abs() > 0.65) {
      outcome = _ShotOutcome.wide;
    } else {
      outcome = _ShotOutcome.goal;
    }
    setState(() {
      _shotAim = aim;
      _shotPower = power;
      _shotOutcome = outcome;
      _shotAnimating = true;
      _shotFeedback = switch (outcome) {
        _ShotOutcome.weak => 'ÇOK ZAYIF',
        _ShotOutcome.goal => 'DENGELİ ŞUT',
        _ShotOutcome.over => 'FAZLA GÜÇLÜ',
        _ShotOutcome.wide => 'DIŞARI',
      };
    });
    _shotController.forward(from: 0);
  }

  void _completeShot() {
    if (!mounted || _finished || !_shotAnimating) return;
    final success = _shotOutcome == _ShotOutcome.goal;
    setState(() {
      _shotAnimating = false;
      _shotAim = 0;
      _shotPower = 0;
      _shotFeedback = success ? 'GOL!' : _shotFeedback;
    });
    _answer(success);
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
    _passingPreviewTimer?.cancel();
    _physicalTimer?.cancel();
    _physicalLeftHeld = false;
    _physicalRightHeld = false;
    _shotController.stop();
    setState(() => _finished = true);
  }

  void _restart() {
    setState(() {
      _secondsLeft = _duration;
      _lives = 3;
      _score = 0;
      _finished = false;
      _lastSuccess = null;
      _shotAnimating = false;
      _shotOutcome = null;
      _shotFeedback = null;
      _shotAim = 0;
      _shotPower = 0;
      _passingPattern = [];
      _passingInput.clear();
      _passingRevealStep = 0;
      _passingShowingPattern = false;
      _passingLocked = false;
      _passingPointer = null;
      _physicalPosition = 0;
      _physicalVelocity = 0;
      _physicalDrift = 0;
      _physicalDriftElapsed = 0;
      _physicalLeftHeld = false;
      _physicalRightHeld = false;
      _nextChallenge(initial: true);
    });
    _shotController.reset();
    _startTimer();
    _startPaceChallenge();
    _startDribblePhysics();
    _startPassingPattern(initial: true);
    _startPhysicalBalance(initial: true);
  }

  TrainingResult get _result {
    final grade = widget.attribute == TrainingAttribute.passing
        ? (_score >= 4 ? 'A' : 'D')
        : switch (_score) {
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
      isSuccessful: widget.attribute == TrainingAttribute.passing
          ? _score >= 4 && _lives > 0
          : _secondsLeft == 0 && _lives > 0,
      statIncrease: widget.statIncrease,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _paceTickTimer?.cancel();
    _dribbleTimer?.cancel();
    _passingPreviewTimer?.cancel();
    _physicalTimer?.cancel();
    _shotController.dispose();
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
            if (widget.attribute == TrainingAttribute.passing)
              _CounterPill(
                key: const Key('passingStatus'),
                icon: _passingShowingPattern
                    ? Icons.visibility_rounded
                    : Icons.gesture_rounded,
                text: _passingShowingPattern ? 'DESENİ İZLE' : 'SIRA SENDE',
              )
            else
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
            _CounterPill(
              icon: Icons.stars_rounded,
              text: widget.attribute == TrainingAttribute.passing
                  ? '$_score/4'
                  : '$_score',
            ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        _shotFieldHeight = constraints.maxHeight;
        return GestureDetector(
          key: const Key('shootingSwipeArea'),
          behavior: HitTestBehavior.opaque,
          onPanStart: _beginShot,
          onPanEnd: _releaseShot,
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
                    child: CustomPaint(painter: const _ShotFieldPainter()),
                  ),
                  Positioned(
                    key: const Key('shootingGoal'),
                    top: 28,
                    left: constraints.maxWidth * 0.17,
                    width: constraints.maxWidth * 0.66,
                    height: constraints.maxHeight * 0.27,
                    child: CustomPaint(painter: const _GoalPainter()),
                  ),
                  if (_shotFeedback != null)
                    Positioned(
                      top: constraints.maxHeight * 0.38,
                      left: 0,
                      right: 0,
                      child: Text(
                        _shotFeedback!,
                        key: const Key('shotFeedback'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _shotOutcome == _ShotOutcome.goal
                              ? _accent
                              : const Color(0xFFFF8A65),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  Positioned(
                    right: 14,
                    bottom: 52,
                    width: 12,
                    height: constraints.maxHeight * 0.32,
                    child: _ShotPowerMeter(power: _shotPower),
                  ),
                  AnimatedBuilder(
                    animation: _shotController,
                    builder: (context, child) {
                      final position = _shotBallPosition(
                        Size(constraints.maxWidth, constraints.maxHeight),
                      );
                      return Positioned(
                        key: const Key('shootingBall'),
                        left: position.dx,
                        top: position.dy,
                        child: child!,
                      );
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black54, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 8),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        color: Colors.black87,
                        size: 38,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Text(
                      'TEK HAMLEDE YUKARI SWIPE’LA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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

  Offset _shotBallPosition(Size size) {
    const ballSize = 46.0;
    final start = Offset((size.width - ballSize) / 2, size.height - 82);
    if (!_shotAnimating || _shotOutcome == null) return start;
    final t = Curves.easeOut.transform(_shotController.value);
    final goalShift = _shotAim * size.width * 0.22 * t;
    final missShift = _shotAim.sign * size.width * 0.50 * t;
    return switch (_shotOutcome!) {
      _ShotOutcome.goal => Offset(
        start.dx + goalShift,
        start.dy - ((start.dy - (size.height * 0.19)) * t) - (sin(pi * t) * 34),
      ),
      _ShotOutcome.weak => Offset(
        start.dx + goalShift,
        start.dy -
            (sin(pi * t) * size.height * 0.28) -
            (t * size.height * 0.08),
      ),
      _ShotOutcome.over => Offset(
        start.dx + goalShift,
        start.dy - ((size.height + 70) * t),
      ),
      _ShotOutcome.wide => Offset(
        start.dx + missShift,
        start.dy - ((start.dy - (size.height * 0.20)) * t),
      ),
    };
  }

  Widget _passingGame() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final centers = _passingCenters(size);
            final activePattern = _passingShowingPattern
                ? _passingPattern.take(_passingRevealStep).toList()
                : List<int>.from(_passingInput);
            final markerSize = min(size.width, size.height) * 0.20;
            return GestureDetector(
              key: const Key('passingPatternBoard'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) =>
                  _recordPassingPoint(details.localPosition, size),
              onPanUpdate: (details) =>
                  _recordPassingPoint(details.localPosition, size),
              onPanEnd: (_) => _submitPassingPattern(),
              onPanCancel: () {
                if (mounted) setState(() => _passingPointer = null);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D492D),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PassingPatternPainter(
                            selectedNodes: activePattern,
                            pointer: _passingShowingPattern
                                ? null
                                : _passingPointer,
                            preview: _passingShowingPattern,
                          ),
                        ),
                      ),
                      for (var index = 0; index < centers.length; index++)
                        Positioned(
                          key: _passingPattern.contains(index)
                              ? Key(
                                  'passingPatternStep${_passingPattern.indexOf(index)}',
                                )
                              : Key('passingNode$index'),
                          left: centers[index].dx - (markerSize / 2),
                          top: centers[index].dy - (markerSize / 2),
                          width: markerSize,
                          height: markerSize,
                          child: const IgnorePointer(child: SizedBox.expand()),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
    final elapsedRatio = ((_duration - _secondsLeft) / _duration).clamp(
      0.0,
      1.0,
    );
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              height: 290,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  final markerX =
                      (width * 0.5) + (_physicalPosition * width * 0.38);
                  final markerY =
                      (height * 0.22) +
                      (_physicalPosition.abs() *
                          _physicalPosition.abs() *
                          height *
                          0.40);
                  return Container(
                    key: const Key('physicalBalanceBoard'),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D492D),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BalanceArcPainter(
                              difficulty: elapsedRatio,
                            ),
                          ),
                        ),
                        Positioned(
                          key: const Key('physicalIndicator'),
                          left: markerX - 17,
                          top: markerY - 38,
                          width: 34,
                          height: 34,
                          child: const CustomPaint(
                            painter: _BalanceMarkerPainter(),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 24,
                          child: Column(
                            children: [
                              Text(
                                'ZORLUK  %${(35 + (elapsedRatio * 65)).round()}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'İBREYİ ÇİZGİNİN ÜZERİNDE TUT',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _BalanceControlButton(
                key: const Key('physicalLeftButton'),
                icon: Icons.chevron_left_rounded,
                label: 'SOLA DENGELE',
                active: _physicalLeftHeld,
                onChanged: (pressed) => _setPhysicalControl(-1, pressed),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BalanceControlButton(
                key: const Key('physicalRightButton'),
                icon: Icons.chevron_right_rounded,
                label: 'SAĞA DENGELE',
                active: _physicalRightHeld,
                onChanged: (pressed) => _setPhysicalControl(1, pressed),
              ),
            ),
          ],
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

List<Offset> _passingCenters(Size size) {
  const positions = [0.19, 0.5, 0.81];
  return [
    for (final y in positions)
      for (final x in positions) Offset(size.width * x, size.height * y),
  ];
}

int? _passingMidpoint(int from, int to) {
  final fromRow = from ~/ 3;
  final fromColumn = from % 3;
  final toRow = to ~/ 3;
  final toColumn = to % 3;
  if ((fromRow + toRow).isOdd || (fromColumn + toColumn).isOdd) return null;
  final middleRow = (fromRow + toRow) ~/ 2;
  final middleColumn = (fromColumn + toColumn) ~/ 2;
  final midpoint = (middleRow * 3) + middleColumn;
  return midpoint == from || midpoint == to ? null : midpoint;
}

class _PassingPatternPainter extends CustomPainter {
  const _PassingPatternPainter({
    required this.selectedNodes,
    required this.pointer,
    required this.preview,
  });

  final List<int> selectedNodes;
  final Offset? pointer;
  final bool preview;

  @override
  void paint(Canvas canvas, Size size) {
    final centers = _passingCenters(size);
    final radius = min(size.width, size.height) * 0.075;
    final activeColor = preview
        ? const Color(0xFF47C8FF)
        : const Color(0xFFC8FF4D);
    final linePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.9)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var index = 1; index < selectedNodes.length; index++) {
      canvas.drawLine(
        centers[selectedNodes[index - 1]],
        centers[selectedNodes[index]],
        linePaint,
      );
    }
    if (pointer != null && selectedNodes.isNotEmpty) {
      canvas.drawLine(
        centers[selectedNodes.last],
        pointer!,
        linePaint..color = activeColor.withValues(alpha: 0.45),
      );
    }

    for (var index = 0; index < centers.length; index++) {
      final selectedOrder = selectedNodes.indexOf(index);
      final isSelected = selectedOrder >= 0;
      canvas.drawCircle(
        centers[index],
        radius,
        Paint()
          ..color = isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.035)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        centers[index],
        radius,
        Paint()
          ..color = isSelected ? activeColor : Colors.white54
          ..strokeWidth = isSelected ? 3 : 2
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        centers[index],
        radius * 0.30,
        Paint()
          ..color = isSelected ? activeColor : Colors.white70
          ..style = PaintingStyle.fill,
      );
      if (isSelected) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${selectedOrder + 1}',
            style: const TextStyle(
              color: Color(0xFF092115),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          centers[index] -
              Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PassingPatternPainter oldDelegate) =>
      oldDelegate.selectedNodes != selectedNodes ||
      oldDelegate.pointer != pointer ||
      oldDelegate.preview != preview;
}

class _BalanceArcPainter extends CustomPainter {
  const _BalanceArcPainter({required this.difficulty});

  final double difficulty;

  Offset _point(Size size, double t) {
    final start = Offset(size.width * 0.12, size.height * 0.62);
    final control = Offset(size.width * 0.50, size.height * 0.02);
    final end = Offset(size.width * 0.88, size.height * 0.62);
    final inverse = 1 - t;
    return Offset(
      (inverse * inverse * start.dx) +
          (2 * inverse * t * control.dx) +
          (t * t * end.dx),
      (inverse * inverse * start.dy) +
          (2 * inverse * t * control.dy) +
          (t * t * end.dy),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.02,
        size.width * 0.88,
        size.height * 0.62,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF47C8FF).withValues(alpha: 0.20)
        ..strokeWidth = 13
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final safePath = Path()
      ..moveTo(_point(size, 0.39).dx, _point(size, 0.39).dy);
    for (var step = 40; step <= 61; step++) {
      final point = _point(size, step / 100);
      safePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      safePath,
      Paint()
        ..color = const Color(0xFFC8FF4D)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (final t in [0.0, 1.0]) {
      final point = _point(size, t);
      canvas.drawCircle(
        point,
        10,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFFC46B),
            const Color(0xFFFF5E72),
            difficulty,
          )!,
      );
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF071A12));
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceArcPainter oldDelegate) =>
      oldDelegate.difficulty != difficulty;
}

class _BalanceMarkerPainter extends CustomPainter {
  const _BalanceMarkerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..lineTo(2, 2)
      ..lineTo(size.width - 2, 2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF47C8FF)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BalanceMarkerPainter oldDelegate) => false;
}

class _BalanceControlButton extends StatelessWidget {
  const _BalanceControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onChanged(true),
        onPointerUp: (_) => onChanged(false),
        onPointerCancel: (_) => onChanged(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 64,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFC8FF4D) : const Color(0xFF123524),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? const Color(0xFFC8FF4D) : Colors.white24,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: active ? const Color(0xFF092115) : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF092115) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ShotOutcome { weak, goal, over, wide }

class _ShotPowerMeter extends StatelessWidget {
  const _ShotPowerMeter({required this.power});

  final double power;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const Column(
            children: [
              Expanded(child: ColoredBox(color: Color(0x55FF7043))),
              Expanded(child: ColoredBox(color: Color(0x668BC34A))),
              Expanded(child: ColoredBox(color: Color(0x55FFC107))),
            ],
          ),
          FractionallySizedBox(
            heightFactor: power,
            child: Container(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}

class _GoalPainter extends CustomPainter {
  const _GoalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final post = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final net = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final goal = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    canvas.drawRect(goal, post);
    for (var column = 1; column < 6; column++) {
      final x = size.width * column / 6;
      canvas.drawLine(Offset(x, 5), Offset(x, size.height - 5), net);
    }
    for (var row = 1; row < 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(5, y), Offset(size.width - 5, y), net);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalPainter oldDelegate) => false;
}

class _ShotFieldPainter extends CustomPainter {
  const _ShotFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.72),
      line,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.72),
        width: size.width * 0.6,
        height: size.height * 0.3,
      ),
      pi,
      pi,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _ShotFieldPainter oldDelegate) => false;
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
              : result.attribute == TrainingAttribute.passing
              ? '3 hakkın da bitti.'
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
    instruction: 'Topu dengeli güçle swipe’la, yere değmeden gol at.',
    icon: Icons.sports_soccer_rounded,
  ),
  TrainingAttribute.passing => const _TrainingInfo(
    title: 'Pas',
    instruction: 'Deseni izle, sonra aynı sırayla çiz. 4 deseni tamamla.',
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
    instruction: 'Sağ-sol tuşlarını basılı tut, 20 saniye dengede kal.',
    icon: Icons.fitness_center_rounded,
  ),
};
