import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/can_frame_decoders/psa_fuel_level_can_decoder.dart';

void main() {
  group('decodeFuelLevelLitres — pure parser (#1401 phase 5)', () {
    test('canonical frame: bytes 4-5 = 0x00,0x5A → 45.0 L', () {
      // raw = 0x005A = 90; litres = 90 / 2 = 45.0.
      final litres = decodeFuelLevelLitres(
        0x0E6,
        const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A],
      );
      expect(litres, 45.0);
    });

    test('endianness probe: bytes 4-5 = 0x00,0x80 → 64.0 L (NOT 0.25)', () {
      // 0x0080 big-endian = 128 → 64.0 L.
      // If we'd accidentally used little-endian we'd read 0x8000 = 32768
      // → 16384.0 L (or worse, single-byte 0x80 = 128 → 64.0 by accident).
      // The trailing 0xFF byte is decoy padding — only bytes 4-5 matter.
      final litres = decodeFuelLevelLitres(
        0x0E6,
        const [0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFF],
      );
      expect(litres, 64.0);
    });

    test('empty tank: bytes 4-5 = 0x00,0x00 → 0.0 L', () {
      final litres = decodeFuelLevelLitres(
        0x0E6,
        const [0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
      );
      expect(litres, 0.0);
    });

    test('boundary high: bytes 4-5 = 0xFF,0xFF → 32767.5 L (parser does '
        'not clamp; caller must sanity-check vs tank capacity)', () {
      // Real PSA tanks cap ~70-80 L, so this value would be a wire
      // error in production — but the decoder intentionally returns
      // the math so a real bug in the endianness assumption surfaces
      // instead of being silently masked.
      final litres = decodeFuelLevelLitres(
        0x0E6,
        const [0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF],
      );
      expect(litres, 32767.5);
    });

    test('full 8-byte payload: only bytes 4-5 are read, the rest is '
        'ignored', () {
      // Realistic 8-byte CAN payload — every byte populated, bytes 4-5
      // = 0x00,0x64 = 100 → 50.0 L. The other bytes are deliberately
      // non-zero to prove they don't influence the result.
      final litres = decodeFuelLevelLitres(
        0x0E6,
        const [0x12, 0x34, 0x56, 0x78, 0x00, 0x64, 0xAB, 0xCD],
      );
      expect(litres, 50.0);
    });

    test('wrong frame id (e.g. 0x123) returns null even with a '
        'valid-looking payload', () {
      final litres = decodeFuelLevelLitres(
        0x123,
        const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A],
      );
      expect(litres, isNull);
    });

    test('frame id one off (0x0E5 / 0x0E7) returns null', () {
      // Adjacent frames on the bus carry different signals — must not
      // accidentally match.
      expect(
        decodeFuelLevelLitres(
          0x0E5,
          const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A],
        ),
        isNull,
      );
      expect(
        decodeFuelLevelLitres(
          0x0E7,
          const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A],
        ),
        isNull,
      );
    });

    test('short payload (4 bytes — byte 5 missing) returns null', () {
      final litres = decodeFuelLevelLitres(
        0x0E6,
        const [0x00, 0x00, 0x00, 0x00],
      );
      expect(litres, isNull);
    });

    test('boundary short payload: exactly 5 bytes still null (need '
        'index 5)', () {
      // Off-by-one guard — we read payload[5], so length must be >= 6,
      // not >= 5.
      final litres = decodeFuelLevelLitres(
        0x0E6,
        const [0x00, 0x00, 0x00, 0x00, 0x5A],
      );
      expect(litres, isNull);
    });

    test('empty payload returns null (does not throw)', () {
      // Defensive: a real adapter that emits a frame line with no
      // payload bytes (corrupt frame, listen-mode buffer flush) must
      // not crash the stream.
      final litres = decodeFuelLevelLitres(0x0E6, const []);
      expect(litres, isNull);
    });

    test('exposes 0x0E6 as the frame id constant', () {
      // Pin the constant so a future "rename for a different platform"
      // surfaces here — phase 5 is hard-coded to PSA EMP2.
      expect(PsaFuelLevelCanDecoder.frameId, 0x0E6);
    });

    test('oemKey is "PSA" (mirrors OemPidTable convention)', () {
      expect(const PsaFuelLevelCanDecoder().oemKey, 'PSA');
    });
  });

  group('PsaFuelLevelCanDecoder.filterFuelLevelStream (#1401 phase 5)', () {
    test('emits one litres value per PSA frame in a pure-PSA stream',
        () async {
      const decoder = PsaFuelLevelCanDecoder();
      final input = Stream<({int id, List<int> payload})>.fromIterable([
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A]),
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x64]),
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
      ]);

      final out = await decoder.filterFuelLevelStream(input).toList();
      expect(out, [45.0, 50.0, 0.0]);
    });

    test('mixed stream: only emits values for 0x0E6, drops other '
        'frame ids', () async {
      const decoder = PsaFuelLevelCanDecoder();
      final input = Stream<({int id, List<int> payload})>.fromIterable([
        // Speed broadcast — different frame, must be skipped.
        (id: 0x0B6, payload: const [0x00, 0x00, 0x12, 0x34, 0x56, 0x78]),
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A]),
        // Random bus traffic.
        (id: 0x123, payload: const [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x64]),
      ]);

      final out = await decoder.filterFuelLevelStream(input).toList();
      expect(out, [45.0, 50.0]);
    });

    test('skips PSA frames with too-short payload (no exception)',
        () async {
      // A real STN listen-mode buffer can occasionally emit a partial
      // frame on overflow. Skipping silently keeps the consumer's
      // monotonic-sample assumptions intact.
      const decoder = PsaFuelLevelCanDecoder();
      final input = Stream<({int id, List<int> payload})>.fromIterable([
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A]),
        (id: 0x0E6, payload: const [0x00, 0x00]),
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x64]),
      ]);

      final out = await decoder.filterFuelLevelStream(input).toList();
      expect(out, [45.0, 50.0]);
    });

    test('empty input stream → empty output stream', () async {
      const decoder = PsaFuelLevelCanDecoder();
      const input = Stream<({int id, List<int> payload})>.empty();

      final out = await decoder.filterFuelLevelStream(input).toList();
      expect(out, isEmpty);
    });

    test('errors on the input stream propagate (decoder does not '
        'swallow)', () async {
      // The transport layer needs to surface adapter disconnects /
      // listen-mode failures so the gating provider can downgrade to
      // active polling. Swallowing here would hide that signal.
      const decoder = PsaFuelLevelCanDecoder();
      final controller =
          StreamController<({int id, List<int> payload})>();
      final received = <double>[];
      Object? caughtError;
      final completer = Completer<void>();

      decoder.filterFuelLevelStream(controller.stream).listen(
            received.add,
            onError: (Object e, StackTrace _) {
              caughtError = e;
              completer.complete();
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete();
            },
          );

      controller.add(
        (id: 0x0E6, payload: const [0x00, 0x00, 0x00, 0x00, 0x00, 0x5A]),
      );
      controller.addError(StateError('listen-mode dropped'));
      // Don't close — the error should still surface.
      await completer.future;
      await controller.close();

      expect(received, [45.0]);
      expect(caughtError, isA<StateError>());
    });
  });
}
