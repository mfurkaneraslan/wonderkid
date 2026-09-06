import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sampleRate = 22050;

void main() {
  final output = Directory('assets/audio')..createSync(recursive: true);
  _writeWav('${output.path}/goal_cheer.wav', _goalCheer(4.2));
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
