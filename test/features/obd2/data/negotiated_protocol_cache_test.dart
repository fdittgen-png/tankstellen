// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/elm327_protocol.dart';
import 'package:tankstellen/features/obd2/data/negotiated_protocol_cache.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import '../../../helpers/silence_error_logger.dart';

/// #2261 concern 3 — ATDPN protocol cache + ATSP{n} on warm connect.
void main() {
  silenceErrorLoggerSpool();

  group('Elm327Protocol protocol-number parsing + command (#2261)', () {
    test('ATDPN strips the leading A auto-flag', () {
      expect(Elm327Protocol.parseProtocolNumber('A6>'), '6');
      expect(Elm327Protocol.parseProtocolNumber('6>'), '6');
      expect(Elm327Protocol.parseProtocolNumber('A8\r\r>'), '8');
    });

    test('a CAN protocol digit (A–C) is preserved when not the auto-flag', () {
      // `AA` = auto-flag A + protocol A (ISO 15765 11-bit 500k). Strip
      // only the FIRST A, keep the protocol digit A.
      expect(Elm327Protocol.parseProtocolNumber('AA>'), 'A');
      expect(Elm327Protocol.parseProtocolNumber('C>'), 'C');
    });

    test('NO DATA / error / protocol-0 → null (nothing pinnable)', () {
      expect(Elm327Protocol.parseProtocolNumber('NO DATA>'), isNull);
      expect(Elm327Protocol.parseProtocolNumber('?>'), isNull);
      expect(Elm327Protocol.parseProtocolNumber('UNABLE TO CONNECT>'), isNull);
      expect(Elm327Protocol.parseProtocolNumber('A0>'), isNull);
      expect(Elm327Protocol.parseProtocolNumber(''), isNull);
    });

    test('setProtocolCommand builds ATSP{n}', () {
      expect(Elm327Protocol.setProtocolCommand('6'), 'ATSP6\r');
      expect(Elm327Protocol.setProtocolCommand('A'), 'ATSPA\r');
    });
  });

  group('NegotiatedProtocolCache.keyFor (#2261)', () {
    test('roots on adapter MAC, refines with VIN when present', () {
      expect(
        NegotiatedProtocolCache.keyFor(adapterMac: 'AA:BB', vin: 'WVWZZZ123'),
        'aa:bb:wvwzzz123',
      );
      expect(NegotiatedProtocolCache.keyFor(adapterMac: 'AA:BB'), 'aa:bb');
      expect(NegotiatedProtocolCache.keyFor(adapterMac: null), isNull);
    });
  });

  group('Obd2Service warm/cold protocol cache (#2261)', () {
    late Directory tmpDir;
    late Box<String> box;
    late NegotiatedProtocolCache cache;
    const key = 'aa:bb:vin1';

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('proto_cache_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>('proto_test');
      cache = NegotiatedProtocolCache(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('proto_test');
      tmpDir.deleteSync(recursive: true);
    });

    test(
        'COLD connect (empty cache) runs ATSP0 then reads ATDPN and caches '
        'the negotiated protocol', () async {
      final t = _RecordingTransport(responses: {
        'ATDPN': 'A6>', // auto-found protocol 6
      });
      final service = Obd2Service(
        t,
        protocolCache: cache,
        protocolCacheKey: key,
      );

      final ok = await service.connect();
      expect(ok, isTrue);
      expect(t.log, contains('ATSP0'),
          reason: 'a cold connect must run the ATSP0 auto-search');
      expect(t.log, isNot(contains('ATSP6')),
          reason: 'no warm pin on a cold connect');
      expect(t.log, contains('ATDPN'),
          reason: 'the negotiated protocol must be read after init');
      expect(cache.get(key), '6',
          reason: 'the auto-flag-stripped protocol is persisted');
    });

    test(
        'WARM connect (cache hit) pins ATSP{n} instead of ATSP0 and skips '
        'the auto-search', () async {
      await cache.put(key, '6');
      final t = _RecordingTransport(responses: {
        'ATDPN': '6>', // pinned protocol confirms
      });
      final service = Obd2Service(
        t,
        protocolCache: cache,
        protocolCacheKey: key,
      );

      final ok = await service.connect();
      expect(ok, isTrue);
      expect(t.log, contains('ATSP6'),
          reason: 'a warm connect replays the cached protocol');
      expect(t.log, isNot(contains('ATSP0')),
          reason: 'the multi-second auto-search must be skipped');
      expect(cache.get(key), '6');
    });

    test(
        'WARM connect whose pinned protocol can\'t talk → falls back to '
        'ATSP0 and re-caches the freshly negotiated protocol', () async {
      await cache.put(key, '6'); // stale — wrong car on this adapter
      final t = _RecordingTransport(responses: {
        // First ATDPN (after the warm ATSP6) says it can't describe a
        // protocol; after the fallback ATSP0 it reports protocol 3.
        'ATDPN': '__SEQUENCE__',
      }, atdpnSequence: ['NO DATA>', 'A3>']);
      final service = Obd2Service(
        t,
        protocolCache: cache,
        protocolCacheKey: key,
      );

      final ok = await service.connect();
      expect(ok, isTrue);
      expect(t.log, contains('ATSP6'), reason: 'warm pin attempted first');
      // After the warm ATDPN miss, the fallback ATSP0 must run.
      expect(t.log.where((c) => c == 'ATSP0').length, 1,
          reason: 'a warm protocol that can\'t talk falls back to ATSP0');
      expect(cache.get(key), '3',
          reason: 'the re-negotiated protocol replaces the stale entry');
    });

    test('no cache wired → no ATDPN, no warm pin (pre-#2261 behaviour)',
        () async {
      final t = _RecordingTransport(responses: const {});
      final service = Obd2Service(t); // no protocolCache

      final ok = await service.connect();
      expect(ok, isTrue);
      expect(t.log, contains('ATSP0'));
      expect(t.log, isNot(contains('ATDPN')),
          reason: 'without a cache the protocol is never probed/persisted');
    });
  });
}

/// Records every command and serves canned responses. Supports a
/// per-command sequence for ATDPN so the warm-fallback path can return
/// two different replies on its two reads.
class _RecordingTransport implements Obd2Transport {
  _RecordingTransport({
    required this.responses,
    this.atdpnSequence,
  });

  final Map<String, String> responses;
  final List<String>? atdpnSequence;
  int _atdpnIdx = 0;

  final List<String> log = <String>[];
  bool _connected = false;

  @override
  bool get isConnected => _connected;
  @override
  Future<void> connect() async => _connected = true;
  @override
  Future<void> disconnect() async => _connected = false;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    log.add(cmd);
    if (cmd == 'ATDPN' && atdpnSequence != null) {
      final seq = atdpnSequence!;
      final reply = _atdpnIdx < seq.length ? seq[_atdpnIdx] : seq.last;
      _atdpnIdx++;
      return reply;
    }
    return responses[cmd] ?? 'OK>';
  }
}
