// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #2261 concern 4 — link tuning (connection priority + best-effort MTU)
/// forwarded through the transport / service to the BLE channel.
void main() {
  silenceErrorLoggerSpool();

  group('link tuning forwards to a tuner-capable channel (#2261)', () {
    test('tuneForRecording / tuneForBackground reach the channel', () async {
      final channel = _TunableChannel();
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      await transport.tuneForRecording();
      await transport.tuneForBackground();

      expect(channel.recordingCalls, 1);
      expect(channel.backgroundCalls, 1);
    });

    test('Obd2Service forwards link tuning to a BLE transport', () async {
      final channel = _TunableChannel();
      final transport = BluetoothObd2Transport(channel);
      final service = Obd2Service(transport);
      await service.connect();

      await service.tuneLinkForRecording();
      await service.tuneLinkForBackground();

      expect(channel.recordingCalls, 1);
      expect(channel.backgroundCalls, 1);
    });

    test('tuning is a safe no-op for a non-tuner channel', () async {
      final channel = _PlainChannel();
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // Must not throw even though the channel is not an Obd2LinkTuner.
      await transport.tuneForRecording();
      await transport.tuneForBackground();
    });

    test('a tuner whose calls throw never propagates — best-effort', () async {
      final channel = _ThrowingTunableChannel();
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // The channel's own try/catch absorbs the platform rejection.
      await transport.tuneForRecording();
      await transport.tuneForBackground();
    });
  });
}

class _PlainChannel implements ElmByteChannel {
  // ignore: close_sinks
  final StreamController<List<int>> _c =
      StreamController<List<int>>.broadcast();
  bool _open = false;
  @override
  Future<void> open() async => _open = true;
  @override
  Future<void> close() async => _open = false;
  @override
  bool get isOpen => _open;
  @override
  Stream<List<int>> get incoming => _c.stream;
  @override
  Future<void> write(List<int> bytes) async {}
}

class _TunableChannel extends _PlainChannel implements Obd2LinkTuner {
  int recordingCalls = 0;
  int backgroundCalls = 0;
  @override
  Future<void> tuneForRecording() async => recordingCalls++;
  @override
  Future<void> tuneForBackground() async => backgroundCalls++;
}

/// Mirrors the real channel's contract: its tuning methods catch
/// platform rejections internally, so they never throw to the caller.
class _ThrowingTunableChannel extends _PlainChannel implements Obd2LinkTuner {
  @override
  Future<void> tuneForRecording() async {
    try {
      throw StateError('androidOnly');
    } catch (_) {/* swallowed, as the real channel does */}
  }

  @override
  Future<void> tuneForBackground() async {
    try {
      throw StateError('androidOnly');
    } catch (_) {/* swallowed */}
  }
}
