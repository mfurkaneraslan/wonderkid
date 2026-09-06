import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

abstract interface class MatchAudioController {
  Future<void> enterMatchDay();

  Future<void> playKickoff();

  Future<void> playGoal();

  Future<void> playFulltime();

  Future<void> dispose();
}

class AssetMatchAudioController implements MatchAudioController {
  final AudioPlayer _ambiencePlayer = AudioPlayer();
  final AudioPlayer _kickoffPlayer = AudioPlayer();
  final AudioPlayer _goalPlayer = AudioPlayer();
  final AudioPlayer _fulltimePlayer = AudioPlayer();
  Future<void>? _ready;

  @override
  Future<void> enterMatchDay() => _ready ??= _prepareAudio();

  Future<void> _prepareAudio() async {
    await Future.wait([
      _safely(() async {
        await _ambiencePlayer.setReleaseMode(ReleaseMode.loop);
        await _ambiencePlayer.setVolume(0.22);
        await _ambiencePlayer.play(AssetSource('audio/stadium_ambience.mp3'));
      }),
      _safely(() async {
        await _kickoffPlayer.setReleaseMode(ReleaseMode.stop);
        await _kickoffPlayer.setVolume(0.82);
        await _kickoffPlayer.setSourceAsset('audio/kickoff_whistle.wav');
      }),
      _safely(() async {
        await _goalPlayer.setReleaseMode(ReleaseMode.stop);
        await _goalPlayer.setVolume(0.95);
        await _goalPlayer.setSourceAsset('audio/goal_cheer.wav');
      }),
      _safely(() async {
        await _fulltimePlayer.setReleaseMode(ReleaseMode.stop);
        await _fulltimePlayer.setVolume(0.9);
        await _fulltimePlayer.setSourceAsset('audio/fulltime_whistle.wav');
      }),
    ]);
  }

  @override
  Future<void> playKickoff() async {
    await enterMatchDay();
    await _restart(_kickoffPlayer);
  }

  @override
  Future<void> playGoal() async {
    await enterMatchDay();
    await _restart(_goalPlayer);
  }

  @override
  Future<void> playFulltime() async {
    await enterMatchDay();
    await _restart(_fulltimePlayer);
  }

  @override
  Future<void> dispose() async {
    await Future.wait([
      _safely(_ambiencePlayer.dispose),
      _safely(_kickoffPlayer.dispose),
      _safely(_goalPlayer.dispose),
      _safely(_fulltimePlayer.dispose),
    ]);
  }

  Future<void> _restart(AudioPlayer player) => _safely(() async {
    await player.seek(Duration.zero);
    await player.resume();
  });

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Ses desteği olmayan bir cihazda maç simülasyonu çalışmaya devam eder.
    }
  }
}
