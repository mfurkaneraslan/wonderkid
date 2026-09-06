import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

abstract interface class MatchAudioController {
  Future<void> startMatch();

  Future<void> playGoal();

  Future<void> finishMatch();

  Future<void> dispose();
}

class AssetMatchAudioController implements MatchAudioController {
  final AudioPlayer _ambiencePlayer = AudioPlayer();
  final AudioPlayer _whistlePlayer = AudioPlayer();
  final AudioPlayer _goalPlayer = AudioPlayer();

  @override
  Future<void> startMatch() async {
    await Future.wait([
      _safely(() async {
        await _ambiencePlayer.setReleaseMode(ReleaseMode.loop);
        await _ambiencePlayer.setVolume(0.22);
        await _ambiencePlayer.play(AssetSource('audio/stadium_ambience.wav'));
      }),
      _safely(() async {
        await _whistlePlayer.setVolume(0.82);
        await _whistlePlayer.play(AssetSource('audio/kickoff_whistle.wav'));
      }),
    ]);
  }

  @override
  Future<void> playGoal() => _safely(() async {
    await _goalPlayer.stop();
    await _goalPlayer.setVolume(0.95);
    await _goalPlayer.play(AssetSource('audio/goal_cheer.wav'));
  });

  @override
  Future<void> finishMatch() async {
    await _safely(_ambiencePlayer.stop);
    await _safely(() async {
      await _whistlePlayer.stop();
      await _whistlePlayer.setVolume(0.9);
      await _whistlePlayer.play(AssetSource('audio/fulltime_whistle.wav'));
    });
  }

  @override
  Future<void> dispose() async {
    await Future.wait([
      _safely(_ambiencePlayer.dispose),
      _safely(_whistlePlayer.dispose),
      _safely(_goalPlayer.dispose),
    ]);
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Ses desteği olmayan bir cihazda maç simülasyonu çalışmaya devam eder.
    }
  }
}
