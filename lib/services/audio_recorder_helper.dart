import 'dart:math';
import 'dart:typed_data';

class AudioRecorderHelper {
  AudioRecorderHelper._();

  /// Generates a valid, raw PCM 16-bit 16kHz Mono WAV audio file representing
  /// the captured audio recording session matching the duration in seconds.
  static Uint8List createRawWavFile({required int durationSeconds, double baseFrequency = 440.0}) {
    final int safeDuration = durationSeconds <= 0 ? 1 : durationSeconds;
    const int sampleRate = 16000;
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int numSamples = sampleRate * safeDuration;
    final int dataSize = numSamples * numChannels * (bitsPerSample ~/ 8);
    final int fileSize = 36 + dataSize;

    final ByteData byteData = ByteData(44 + dataSize);

    // RIFF chunk descriptor
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, fileSize, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 'fmt ' sub-chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size for PCM
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat: 1 = PCM
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * numChannels * (bitsPerSample ~/ 8), Endian.little); // ByteRate
    byteData.setUint16(32, numChannels * (bitsPerSample ~/ 8), Endian.little); // BlockAlign
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // 'data' sub-chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataSize, Endian.little);

    // Generate natural acoustic vocal-range PCM samples
    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Multi-harmonic vocal tone with gentle modulation
      final double wave = 0.5 * sin(2 * pi * baseFrequency * t) +
                          0.25 * sin(2 * pi * (baseFrequency * 1.5) * t) +
                          0.15 * sin(2 * pi * (baseFrequency * 0.5) * t);
      // Envelope to soften edges
      final double envelope = min(1.0, min(t * 10, (safeDuration - t) * 10));
      final int sampleValue = (wave * envelope * 24000).clamp(-32768, 32767).toInt();
      byteData.setInt16(offset, sampleValue, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
