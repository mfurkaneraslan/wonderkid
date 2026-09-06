import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sampleRate = 22050;

void main() {
  final output = Directory('assets/audio')..createSync(recursive: true);
  _writeWav(
    '${output.path}/fulltime_whistle.wav',
    _whistle([0.05, 0.92, 1.82], 3.35, finalLong: true),
  );
  _writeWav('${output.path}/stadium_ambience.wav', _stadiumAmbience(10));
  _writeWav('${output.path}/goal_cheer.wav', _goalCheer(4.2));
}

List<double> _whistle(
  List<double> starts,
  double duration, {
  bool finalLong = false,
}) {
  final samples = List<double>.filled((duration * _sampleRate).round(), 0);
  for (var burst = 0; burst < starts.length; burst++) {
    final start = starts[burst];
    final length = finalLong && burst == starts.length - 1 ? 1.18 : 0.62;
    for (var index = 0; index < samples.length; index++) {
      final time = index / _sampleRate - start;
      if (time < 0 || time > length) continue;
      final attack = min(1.0, time / 0.025);
      final release = min(1.0, (length - time) / 0.09);
      final envelope = attack * release;
      final vibrato = sin(2 * pi * 6.2 * time) * 55;
      final tone =
          sin(2 * pi * (2650 + vibrato) * time) * 0.58 +
          sin(2 * pi * (3180 + vibrato) * time) * 0.24;
      samples[index] += tone * envelope;
    }
  }
  return samples;
}

List<double> _stadiumAmbience(double duration) {
  final random = Random(1907);
  final samples = List<double>.filled((duration * _sampleRate).round(), 0);
  var smoothNoise = 0.0;
  for (var index = 0; index < samples.length; index++) {
    final time = index / _sampleRate;
    smoothNoise = smoothNoise * 0.965 + (random.nextDouble() * 2 - 1) * 0.035;
    final murmur =
        sin(2 * pi * 83 * time) * 0.045 +
        sin(2 * pi * 117 * time + 1.7) * 0.035 +
        sin(2 * pi * 151 * time + 0.4) * 0.024;
    final wave = 0.75 + sin(2 * pi * 0.18 * time) * 0.16;
    samples[index] = (smoothNoise * 0.34 + murmur) * wave;
  }
  _crossfadeLoop(samples, 0.55);
  return samples;
}

List<double> _goalCheer(double duration) {
  final random = Random(2000);
  final samples = List<double>.filled((duration * _sampleRate).round(), 0);
  var lowNoise = 0.0;
  var midNoise = 0.0;
  for (var index = 0; index < samples.length; index++) {
    final time = index / _sampleRate;
    final white = random.nextDouble() * 2 - 1;
    lowNoise = lowNoise * 0.93 + white * 0.07;
    midNoise = midNoise * 0.72 + white * 0.28;
    final attack = min(1.0, time / 0.16);
    final release = time < 2.9 ? 1.0 : max(0.0, (duration - time) / 1.3);
    final swell = attack * release * (0.82 + sin(2 * pi * 2.4 * time) * 0.08);
    final voices =
        sin(2 * pi * 132 * time) * 0.055 +
        sin(2 * pi * 176 * time + 0.8) * 0.045 +
        sin(2 * pi * 221 * time + 2.1) * 0.035;
    var claps = 0.0;
    for (final clapAt in const [0.28, 0.51, 0.77, 1.04, 1.34, 1.69, 2.08]) {
      final delta = time - clapAt;
      if (delta >= 0 && delta < 0.045) {
        claps += white * (1 - delta / 0.045) * 0.36;
      }
    }
    samples[index] =
        ((lowNoise * 0.58 + midNoise * 0.31 + voices) * swell + claps).clamp(
          -0.92,
          0.92,
        );
  }
  return samples;
}

void _crossfadeLoop(List<double> samples, double seconds) {
  final length = (seconds * _sampleRate).round();
  final start = List<double>.from(samples.take(length));
  for (var index = 0; index < length; index++) {
    final mix = index / (length - 1);
    final tailIndex = samples.length - length + index;
    final blended = samples[tailIndex] * (1 - mix) + start[index] * mix;
    samples[tailIndex] = blended;
    samples[index] = blended;
  }
}

void _writeWav(String path, List<double> samples) {
  final bytes = ByteData(44 + samples.length * 2);
  void ascii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _sampleRate, Endian.little);
  bytes.setUint32(28, _sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, samples.length * 2, Endian.little);
  for (var index = 0; index < samples.length; index++) {
    final value = (samples[index].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + index * 2, value, Endian.little);
  }
  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}
