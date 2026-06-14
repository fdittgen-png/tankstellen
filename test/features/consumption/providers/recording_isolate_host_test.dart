// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/recording_isolate_protocol.dart';
import 'package:tankstellen/features/consumption/providers/recording_isolate_host.dart';

/// #3321 — proves the [RecordingIsolateHost] transport works end-to-end with a
/// REAL spawned isolate: handshake → command down → fixes streamed back. The
/// echo entry point stands in for the (device-validated) geolocator-in-isolate
/// production entry point; the machinery under test is identical.
@pragma('vm:entry-point')
void _echoEntryPoint(SendPort toMain) {
  final fromMain = ReceivePort();
  // Handshake: hand the host our command port first.
  toMain.send(fromMain.sendPort);
  fromMain.listen((Object? message) {
    final cmd = decodeRecordingCommand(message);
    if (cmd == RecordingIsolateCommand.start) {
      // Emit two synthetic fixes, then idle.
      toMain.send(const RecordingFixMessage(
        epochMs: 1000,
        speedKmh: 30,
        latitude: 48.1,
        longitude: 11.5,
      ).toMap());
      toMain.send(const RecordingFixMessage(epochMs: 2000, speedKmh: 45).toMap());
    } else if (cmd == RecordingIsolateCommand.stop) {
      fromMain.close();
    }
  });
}

void main() {
  test('spawn → handshake → start streams decoded fixes back from the isolate',
      () async {
    final host = RecordingIsolateHost();
    addTearDown(host.dispose);

    final received = <RecordingFixMessage>[];
    final twoFixes = host.fixes.take(2).forEach(received.add);

    await host.spawn(_echoEntryPoint);
    await host.ready; // handshake landed
    host.send(RecordingIsolateCommand.start);

    await twoFixes.timeout(const Duration(seconds: 10));

    expect(received, hasLength(2));
    expect(received[0].speedKmh, 30);
    expect(received[0].latitude, 48.1);
    expect(received[1].speedKmh, 45);
    expect(received[1].latitude, isNull);
  });

  test('dispose before any command is safe (no hang, no throw)', () async {
    final host = RecordingIsolateHost();
    await host.spawn(_echoEntryPoint);
    await host.ready;
    await host.dispose(); // must complete
    // A late send after dispose is a no-op, not a crash.
    host.send(RecordingIsolateCommand.start);
  });
}
