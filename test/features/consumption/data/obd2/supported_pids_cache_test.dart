// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/supported_pids_cache.dart';

// Shared AT-init boilerplate for the FakeObd2Transport — mirrors
// obd2_service_test.dart so the #811 tests can stay self-contained.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
};

/// Build a valid VIN Mode 09 PID 02 response (`49 02 01 ...`) from a
/// plain-ASCII 17-character VIN. Lets individual tests declare a VIN
/// as a string instead of hand-packing hex frames.
String _vinResponse(String vin) {
  assert(vin.length == 17, 'VIN must be 17 chars');
  final bytes = StringBuffer('49 02 01');
  for (final codeUnit in vin.codeUnits) {
    bytes.write(' ${codeUnit.toRadixString(16).toUpperCase().padLeft(2, '0')}');
  }
  bytes.write('>');
  return bytes.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Elm327Protocol.parseSupportedPidsBitmap — #811 parser', () {
    test('groupBase 0x00, all zeros → empty set', () {
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 00 00 00 00 00>',
        0x00,
      );
      expect(pids, isEmpty);
    });

    test('groupBase 0x00, single high bit → PID 1', () {
      // 0x80 = 1000_0000 → MSB = PID (groupBase + 1) = PID 1.
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 00 80 00 00 00>',
        0x00,
      );
      expect(pids, {1});
    });

    test('groupBase 0x00, BE 3F A8 13 → canonical "modern car" bitmap', () {
      // Picked from the issue description as a real-world example.
      // 0xBE = 1011_1110 → bits 0,2,3,4,5,6 set → PIDs 1, 3, 4, 5, 6, 7.
      // 0x3F = 0011_1111 → bits 2,3,4,5,6,7 set → PIDs 11,12,13,14,15,16.
      // 0xA8 = 1010_1000 → bits 0,2,4       → PIDs 17,19,21.
      // 0x13 = 0001_0011 → bits 3,6,7       → PIDs 28,31,32.
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 00 BE 3F A8 13>',
        0x00,
      );
      expect(
        pids,
        {1, 3, 4, 5, 6, 7, 11, 12, 13, 14, 15, 16, 17, 19, 21, 28, 31, 32},
      );
    });

    test('groupBase 0x20 shifts the PID numbers by the base', () {
      // Same 0x80 bitmap but for range 0x20..0x3F → should decode to
      // PID (0x20 + 1) = PID 33.
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 20 80 00 00 00>',
        0x20,
      );
      expect(pids, {33});
    });

    test('groupBase 0x40 → PIDs 0x41..0x60 (65..96)', () {
      // 0x01 in the last byte = PID (0x40 + 32) = 0x60 = 96.
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 40 00 00 00 01>',
        0x40,
      );
      expect(pids, {96});
    });

    test('groupBase 0x60 → PIDs 0x61..0x80 (97..128)', () {
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 60 80 00 00 00>',
        0x60,
      );
      expect(pids, {0x61});
    });

    test('groupBase 0x80 → PIDs 0x81..0xA0 (129..160)', () {
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 80 80 00 00 00>',
        0x80,
      );
      expect(pids, {0x81});
    });

    test('groupBase 0xA0 → PIDs 0xA1..0xC0 (161..192)', () {
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 A0 80 00 00 00>',
        0xA0,
      );
      expect(pids, {0xA1});
    });

    test('groupBase 0xC0 → PIDs 0xC1..0xE0 (193..224)', () {
      final pids = Elm327Protocol.parseSupportedPidsBitmap(
        '41 C0 80 00 00 00>',
        0xC0,
      );
      expect(pids, {0xC1});
    });

    test('NO DATA returns null (not an empty set — a distinct signal)', () {
      expect(
        Elm327Protocol.parseSupportedPidsBitmap('NO DATA>', 0x00),
        isNull,
      );
    });

    test('truncated response returns null (minBytes guard)', () {
      // Missing last payload byte — only 3 of 4 bytes present.
      expect(
        Elm327Protocol.parseSupportedPidsBitmap('41 00 FF FF FF>', 0x00),
        isNull,
      );
    });

    test('wrong Mode echo (42 instead of 41) returns null', () {
      expect(
        Elm327Protocol.parseSupportedPidsBitmap('42 00 FF FF FF FF>', 0x00),
        isNull,
      );
    });

    test('wrong PID echo returns null', () {
      // Response claims range 0x20 but caller asked about 0x00.
      expect(
        Elm327Protocol.parseSupportedPidsBitmap('41 20 FF FF FF FF>', 0x00),
        isNull,
      );
    });

    test('multi-response chain — a single bitmap spread across frames '
        'still decodes correctly once cleanResponse anchors on "41"', () {
      // ELM327 frames can arrive with a leading "SEARCHING..." line or
      // multiple echoed \r between payload bytes. cleanResponse strips
      // them; the parser should still land on the right 6 bytes.
      const raw = 'SEARCHING...\r\r41 00\rBE 3F A8 13\r>';
      final pids = Elm327Protocol.parseSupportedPidsBitmap(raw, 0x00);
      expect(
        pids,
        {1, 3, 4, 5, 6, 7, 11, 12, 13, 14, 15, 16, 17, 19, 21, 28, 31, 32},
      );
    });
  });

  group('SupportedPidsCache — #811 persistence', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('supported_pids_cache_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>(
        'test_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('empty cache returns null', () {
      final cache = SupportedPidsCache(box);
      expect(cache.get('unknown-vin'), isNull);
    });

    test('round-trip — put then get yields the same set', () async {
      final cache = SupportedPidsCache(box);
      final pids = {1, 3, 11, 12, 13, 14, 15, 16, 32};
      await cache.put('VF7PPPP0000000001', pids);
      expect(cache.get('VF7PPPP0000000001'), pids);
    });

    test('fallbackKey lower-cases and trims, so capitalisation '
        'mismatches share a cache entry', () {
      final a = SupportedPidsCache.fallbackKey(
        make: 'Peugeot',
        model: '107',
        year: 2008,
      );
      final b = SupportedPidsCache.fallbackKey(
        make: '  PEUGEOT  ',
        model: '107 ',
        year: 2008,
      );
      expect(a, b);
    });

    test('persistence across Hive close/reopen — stored set loads back', () async {
      final boxName = box.name;
      final cache = SupportedPidsCache(box);
      await cache.put('VIN-X', {1, 3, 5, 32});
      await box.close();

      final reopened = await Hive.openBox<String>(boxName);
      final cache2 = SupportedPidsCache(reopened);
      expect(cache2.get('VIN-X'), {1, 3, 5, 32});
      // Reassign the test-scope `box` so tearDown deletes the right one.
      box = reopened;
    });

    test('corrupt JSON entry ignored → returns null', () async {
      // Simulate an entry that's not valid JSON (e.g. a disk corruption
      // or a stale payload from a previous schema).
      await box.put('VIN-CORRUPT', 'not-json');
      final cache = SupportedPidsCache(box);
      expect(cache.get('VIN-CORRUPT'), isNull);
    });

    test('non-list JSON entry ignored → returns null', () async {
      // JSON-valid but wrong shape (object instead of list).
      await box.put('VIN-WRONG-SHAPE', '{"pids": [1, 2]}');
      final cache = SupportedPidsCache(box);
      expect(cache.get('VIN-WRONG-SHAPE'), isNull);
    });

    test('clear wipes every entry', () async {
      final cache = SupportedPidsCache(box);
      await cache.put('VIN-A', {1});
      await cache.put('VIN-B', {2});
      await cache.clear();
      expect(cache.get('VIN-A'), isNull);
      expect(cache.get('VIN-B'), isNull);
    });
  });

  group('Obd2Service connect-time cache integration — #811', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('obd2_cache_int_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>(
        'test_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('cache miss on first connect → scan runs, result is persisted',
        () async {
      final transport = FakeObd2Transport({
        ..._initResponses,
        '0902': _vinResponse('VF7PPPP0000000001'),
        // Only range 0x00 bitmap is answered; continuation bit (PID
        // 32) is NOT set so the walk stops after one round-trip.
        // Byte 0 bit 0 = PID 1, byte 1 bit 2 = PID 0x0B, byte 1 bit
        // 3 = PID 0x0C, byte 1 bit 6 = PID 0x0F.
        '0100': '41 00 80 32 00 00>',
      });
      final cache = SupportedPidsCache(box);
      final service = Obd2Service(transport, pidsCache: cache);

      final ok = await service.connect();
      expect(ok, isTrue);

      // Scan ran → in-memory set populated with the decoded PIDs.
      expect(service.supportsPid(0x01), isTrue);
      expect(service.supportsPid(0x0B), isTrue);
      expect(service.supportsPid(0x0C), isTrue);
      expect(service.supportsPid(0x0F), isTrue);
      expect(service.supportsPid(0x5E), isFalse);

      // And persisted under the VIN key for next session.
      expect(cache.get('VF7PPPP0000000001'),
          containsAll([0x01, 0x0B, 0x0C, 0x0F]));
    });

    test('cache hit on second connect → no scan, no 01 XX round-trips',
        () async {
      // Pre-seed the cache as if a previous session already scanned.
      await SupportedPidsCache(box).put(
        'VF7PPPP0000000001',
        {0x01, 0x0B, 0x0C, 0x0F},
      );

      // Note: '0100' is INTENTIONALLY NOT in the transport's response
      // map. If the service tries to scan, FakeObd2Transport returns
      // 'NO DATA>' — which would blank the in-memory cache and fail
      // the supportsPid(0x0B) assertion below.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '0902': _vinResponse('VF7PPPP0000000001'),
      });
      final cache = SupportedPidsCache(box);
      final service = Obd2Service(transport, pidsCache: cache);

      final ok = await service.connect();
      expect(ok, isTrue);

      expect(service.supportsPid(0x0B), isTrue,
          reason: 'cached set must have populated _supportedPids without '
              'any 01 XX round-trip');
      expect(service.supportsPid(0x5E), isFalse);
    });

    test(
        'VIN change invalidates the cache hit — different VIN forces a '
        'fresh scan', () async {
      // Cache was filled for car A (only PID 0x01).
      await SupportedPidsCache(box).put('VF7PPPP0000000001', {0x01});

      // Now we connect to a DIFFERENT car (VF7PPPP0000000002). The cache
      // has no entry for this second VIN, so the service must run a
      // fresh scan. VIN chosen without 'A' so byte 0x41 doesn't confuse
      // cleanResponse's Mode 01 anchor.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '0902': _vinResponse('VF7PPPP0000000002'),
        '0100': '41 00 00 32 00 00>', // PIDs 0x0B, 0x0C, 0x0F
      });
      final cache = SupportedPidsCache(box);
      final service = Obd2Service(transport, pidsCache: cache);

      final ok = await service.connect();
      expect(ok, isTrue);

      // Fresh-scan PIDs, NOT the cached VIN-A single-PID set.
      expect(service.supportsPid(0x0B), isTrue);
      expect(service.supportsPid(0x0C), isTrue);
      expect(service.supportsPid(0x0F), isTrue);
      expect(service.supportsPid(0x01), isFalse,
          reason: 'VIN-A cache must not leak into VIN-B');
    });

    test(
        'no VIN from the car + no fallback key → cache skipped, scan still '
        'runs blindly', () async {
      final transport = FakeObd2Transport({
        ..._initResponses,
        // 0902 NOT provided → FakeObd2Transport returns 'NO DATA>' →
        // parseVin returns null.
        '0100': '41 00 80 00 00 00>', // PID 1 only, no continuation
      });
      final cache = SupportedPidsCache(box);
      final service = Obd2Service(transport, pidsCache: cache);

      final ok = await service.connect();
      expect(ok, isTrue);
      // No cache key → nothing written.
      expect(box.length, 0);
      // And nothing primed in memory either — supportsPid stays in
      // "unknown ⇒ allow" mode.
      expect(service.supportsPid(0x5E), isTrue);
    });

    test(
        'no VIN + fallback key provided → cache uses the fallback make:'
        'model:year', () async {
      final fallback = SupportedPidsCache.fallbackKey(
        make: 'Peugeot',
        model: '107',
        year: 2008,
      );
      // Pre-seed with the fallback-key scenario.
      await SupportedPidsCache(box).put(fallback, {0x0B, 0x0C, 0x0F});

      final transport = FakeObd2Transport({
        ..._initResponses,
        // 0902 NOT provided → VIN parse returns null → fall back to
        // the injected static key.
      });
      final cache = SupportedPidsCache(box);
      final service = Obd2Service(
        transport,
        pidsCache: cache,
        vehicleFallbackKey: fallback,
      );

      final ok = await service.connect();
      expect(ok, isTrue);
      // Cached PIDs loaded → 0x5E still false → sanity signal.
      expect(service.supportsPid(0x0B), isTrue);
      expect(service.supportsPid(0x5E), isFalse);
    });

    test('readFuelRateLPerHour skips PID 5E and MAF round-trips when '
        'the cached set excludes them (Peugeot 107 flow)', () async {
      // Seed cache with the real Peugeot 107 1KR-FE profile: no 5E,
      // no MAF, but MAP/IAT/RPM all present.
      const vin = 'VF7PPPP0000000001';
      await SupportedPidsCache(box).put(vin, {0x0B, 0x0C, 0x0F});

      // Intentionally do NOT wire '015E' or '0110' — if the service
      // bypasses the cache and tries them, FakeObd2Transport returns
      // 'NO DATA>' and the round-trips count toward wasted Bluetooth
      // time. We assert the fuel rate comes out of the speed-density
      // path anyway.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '0902': _vinResponse(vin),
        '010B': '41 0B 28>', // MAP 40 kPa
        '010F': '41 0F 41>', // IAT 25 °C
        '010C': '41 0C 0C 80>', // RPM 800
      });
      final service = Obd2Service(
        transport,
        pidsCache: SupportedPidsCache(box),
      );
      await service.connect();

      expect(service.supportsPid(0x5E), isFalse);
      expect(service.supportsPid(0x10), isFalse);
      final rate = await service.readFuelRateLPerHour();
      expect(rate, isNotNull);
      expect(rate, greaterThan(0));
    });
  });

  group('SupportedPidsCache.productionKey — #2253', () {
    test('mac + full make/model/year → adapterMac:make:model:year', () {
      final key = SupportedPidsCache.productionKey(
        adapterMac: 'AA:BB:CC:DD',
        make: 'Peugeot',
        model: '107',
        year: 2008,
      );
      expect(key, 'aa:bb:cc:dd:peugeot:107:2008');
    });

    test('mac only (no vehicle fields) → adapterMac-only key', () {
      final key = SupportedPidsCache.productionKey(adapterMac: 'AA:BB');
      expect(key, 'aa:bb');
    });

    test('partial vehicle (missing year) degrades to adapterMac-only', () {
      final key = SupportedPidsCache.productionKey(
        adapterMac: 'AA:BB',
        make: 'Peugeot',
        model: '107',
        // year omitted
      );
      expect(key, 'aa:bb');
    });

    test('blank make/model degrade to adapterMac-only', () {
      final key = SupportedPidsCache.productionKey(
        adapterMac: 'AA:BB',
        make: '  ',
        model: '',
        year: 2008,
      );
      expect(key, 'aa:bb');
    });

    test('no adapterMac → null (resolver falls back to VIN-first path)', () {
      expect(
        SupportedPidsCache.productionKey(adapterMac: null),
        isNull,
      );
      expect(
        SupportedPidsCache.productionKey(adapterMac: ''),
        isNull,
      );
    });

    test('case-insensitive — capitalisation mismatch shares a slot', () {
      final a = SupportedPidsCache.productionKey(
        adapterMac: 'AA:BB',
        make: 'Peugeot',
        model: '107',
        year: 2008,
      );
      final b = SupportedPidsCache.productionKey(
        adapterMac: 'aa:bb',
        make: 'PEUGEOT',
        model: '107',
        year: 2008,
      );
      expect(a, b);
    });
  });

  group('Obd2Service production-key cache wiring (HIT-skip-0902) — #2253', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('obd2_prodkey_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>(
        'test_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    // The production-shaped key the live Obd2ConnectionService hands the
    // service — no VIN involved.
    final prodKey = SupportedPidsCache.productionKey(
      adapterMac: 'AA:BB:CC:DD',
      make: 'Peugeot',
      model: '107',
      year: 2008,
    )!;

    test(
        'cold connect (cache miss) → scan runs, bitmap persisted under the '
        'production key; 0902 fallback only when scan needs a precise key',
        () async {
      final transport = FakeObd2Transport({
        ..._initResponses,
        // No 0902 wired → VIN parse returns null → resolver falls back
        // to the production key for persistence.
        '0100': '41 00 80 32 00 00>', // PIDs 1, 0x0B, 0x0C, 0x0F
      });
      final service = Obd2Service(
        transport,
        pidsCache: SupportedPidsCache(box),
        vehicleFallbackKey: prodKey,
      );

      final ok = await service.connect();
      expect(ok, isTrue);

      // Scan ran on the cold path.
      expect(transport.sentCommands, contains('0100'));
      // In-memory + persisted under the production key.
      expect(service.supportsPid(0x0B), isTrue);
      expect(service.supportsPid(0x5E), isFalse);
      expect(box.get(prodKey), isNotNull,
          reason: 'cold path must persist the bitmap under the prod key');
      expect(
        SupportedPidsCache(box).get(prodKey),
        containsAll([0x01, 0x0B, 0x0C, 0x0F]),
      );
    });

    test(
        'warm connect (cache HIT on production key) → NO support scan AND '
        'NO 0902 VIN read', () async {
      // Pre-seed as if a previous session already scanned this
      // adapter+vehicle.
      await SupportedPidsCache(box).put(prodKey, {0x01, 0x0B, 0x0C, 0x0F});

      // Neither 0100 NOR 0902 is wired — if the service tries either,
      // FakeObd2Transport returns 'NO DATA>'. We assert by command
      // capture that it sends NEITHER.
      final transport = FakeObd2Transport({..._initResponses});
      final service = Obd2Service(
        transport,
        pidsCache: SupportedPidsCache(box),
        vehicleFallbackKey: prodKey,
      );

      final ok = await service.connect();
      expect(ok, isTrue);

      // The whole point of #2253: a warm connect pays neither the
      // multi-frame VIN read nor the 8 × 01 XX support scan.
      expect(transport.sentCommands, isNot(contains('0902')),
          reason: 'HIT on the production key must skip the 0902 VIN read');
      expect(transport.sentCommands, isNot(contains('0100')),
          reason: 'HIT must skip the supported-PID support scan');

      // Cached set populated the in-memory bitmap.
      expect(service.supportsPid(0x0B), isTrue);
      expect(service.supportsPid(0x5E), isFalse);
    });

    test(
        'warm HIT → unsupported PIDs are NOT polled by the recording-loop '
        'consumers (readFuelRateLPerHour speed-density path)', () async {
      // Peugeot 107 1KR-FE: no 5E, no MAF; MAP/IAT/RPM present.
      await SupportedPidsCache(box).put(prodKey, {0x0B, 0x0C, 0x0F});

      // 015E / 0110 intentionally NOT wired: if the service polled an
      // unsupported PID it would hit FakeObd2Transport's NO DATA and
      // show up in sentCommands.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '010B': '41 0B 28>', // MAP 40 kPa
        '010F': '41 0F 41>', // IAT 25 °C
        '010C': '41 0C 0C 80>', // RPM 800
      });
      final service = Obd2Service(
        transport,
        pidsCache: SupportedPidsCache(box),
        vehicleFallbackKey: prodKey,
      );
      await service.connect();

      expect(service.supportsPid(0x5E), isFalse);
      expect(service.supportsPid(0x10), isFalse);

      final rate = await service.readFuelRateLPerHour();
      expect(rate, isNotNull);
      expect(rate, greaterThan(0));

      // The unsupported PID commands were never sent.
      expect(transport.sentCommands, isNot(contains('015E')));
      expect(transport.sentCommands, isNot(contains('0110')));
    });

    test(
        'no-cache (cold) path unchanged — service built transport-only still '
        'scans blindly and never rejects a PID', () async {
      final transport = FakeObd2Transport({..._initResponses});
      // No pidsCache, no vehicleFallbackKey — exactly the pre-#2253
      // construction.
      final service = Obd2Service(transport);

      final ok = await service.connect();
      expect(ok, isTrue);

      // prime() is a no-op without a cache → no fallback probe, no scan,
      // no VIN read.
      expect(transport.sentCommands, isNot(contains('0100')));
      expect(transport.sentCommands, isNot(contains('0902')));
      // "Unknown ⇒ allow": every PID still reports supported.
      expect(service.supportsPid(0x5E), isTrue);
      expect(service.supportsPid(0x0B), isTrue);
    });

    test(
        'VIN-keyed legacy entries still resolve when no fallback key is '
        'supplied (no regression to the #811 VIN path)', () async {
      const vin = 'VF7PPPP0000000001';
      await SupportedPidsCache(box).put(vin, {0x0B, 0x0C, 0x0F});

      // No vehicleFallbackKey → resolver must read 0902 and hit on VIN.
      final transport = FakeObd2Transport({
        ..._initResponses,
        '0902': _vinResponse(vin),
      });
      final service = Obd2Service(
        transport,
        pidsCache: SupportedPidsCache(box),
      );

      final ok = await service.connect();
      expect(ok, isTrue);
      // VIN read happened (it's the only key source here)…
      expect(transport.sentCommands, contains('0902'));
      // …and the cached set loaded → no support scan.
      expect(transport.sentCommands, isNot(contains('0100')));
      expect(service.supportsPid(0x0B), isTrue);
      expect(service.supportsPid(0x5E), isFalse);
    });
  });
}
