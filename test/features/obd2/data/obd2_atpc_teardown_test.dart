// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_atpc_teardown.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

import '../../../helpers/silence_error_logger.dart';

/// Fake transport whose ATPC handling is scriptable: it can answer, throw,
/// or hang — and records the full command + disconnect transcript so the
/// tests assert ORDER (ATPC strictly before the transport teardown, #3422).
class _TranscriptTransport implements Obd2Transport {
  _TranscriptTransport({this.throwOnAtpc = false, this.hangOnAtpc = false});

  final bool throwOnAtpc;
  final bool hangOnAtpc;
  final transcript = <String>[];
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async => _connected = true;

  /// Test seam: model a DROP (the channels clear their open flag on the
  /// drop edge, so a dropped link reads `isConnected == false`).
  void drop() => _connected = false;

  @override
  Future<String> sendCommand(String command) async {
    final cmd = command.trim();
    transcript.add(cmd);
    if (cmd == 'ATPC') {
      if (throwOnAtpc) throw StateError('link died mid-ATPC');
      if (hangOnAtpc) return Completer<String>().future; // never answers
    }
    return 'OK>';
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    transcript.add('<disconnect>');
  }
}

void main() {
  silenceErrorLoggerSpool();

  group('ATPC before deliberate disconnect (#3422 prevention)', () {
    test('Obd2Service.disconnect() sends ATPC, then tears the transport '
        'down — transcript-verified', () async {
      final transport = _TranscriptTransport();
      await transport.connect();
      final service = Obd2Service(transport);

      await service.disconnect();

      expect(transport.transcript, ['ATPC', '<disconnect>']);
    });

    test('a drop-triggered teardown (link already dead) sends NO ATPC',
        () async {
      final transport = _TranscriptTransport();
      await transport.connect();
      final service = Obd2Service(transport);
      transport.drop(); // the drop edge cleared isConnected (#2671)

      await service.disconnect();

      expect(transport.transcript, ['<disconnect>'],
          reason: 'never write ATPC into a dead socket');
    });

    test('never throws — a throwing ATPC send is swallowed and the '
        'disconnect proceeds (fault injection)', () async {
      final transport = _TranscriptTransport(throwOnAtpc: true);
      await transport.connect();
      final service = Obd2Service(transport);

      await expectLater(service.disconnect(), completes);
      expect(transport.transcript, ['ATPC', '<disconnect>']);
    });

    test('never hangs — an unresponsive adapter is cut off by the bounded '
        'timeout and the disconnect proceeds', () {
      fakeAsync((async) {
        final transport = _TranscriptTransport(hangOnAtpc: true);
        var done = false;
        unawaited(() async {
          await transport.connect();
          await Obd2Service(transport).disconnect();
          done = true;
        }());
        async.elapse(kAtpcTeardownTimeout + const Duration(seconds: 1));
        expect(done, isTrue);
        expect(transport.transcript, ['ATPC', '<disconnect>']);
      });
    });

    test('the helper alone skips a never-connected transport', () async {
      final transport = _TranscriptTransport();
      await sendProtocolCloseBeforeTeardown(transport);
      expect(transport.transcript, isEmpty);
    });
  });
}
