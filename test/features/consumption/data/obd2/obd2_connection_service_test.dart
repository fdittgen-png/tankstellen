// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'negotiated_protocol_cache.dart';
import 'package:tankstellen/features/consumption/data/obd2/supported_pids_cache.dart';
import '../../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();
  final registry = Obd2AdapterRegistry.defaults();

  group('Obd2ConnectionService.scan (#741)', () {
    test('throws Obd2PermissionDenied when the user refuses', () async {
      final svc = _build(
        permState: Obd2PermissionState.denied,
        bt: _FakeFacade(batches: const [[]]),
      );
      await expectLater(svc.scan().toList(), throwsA(isA<Obd2PermissionDenied>()));
    });

    test(
      'propagates Obd2BluetoothOff from the BLE facade verbatim — the '
      'service must not catch it as a scan timeout (#1369)',
      () async {
        // The facade emits a typed Obd2BluetoothOff once it has
        // identified that FlutterBluePlus rejected startScan with
        // "Bluetooth must be turned on". The connection service is a
        // pass-through; the picker / VIN reader catches the typed
        // error and renders the "Turn on Bluetooth" message.
        final svc = _build(
          permState: Obd2PermissionState.granted,
          bt: _FakeFacade(
            batches: const [],
            error: const Obd2BluetoothOff(),
          ),
        );
        await expectLater(
          svc.scan().toList(),
          throwsA(isA<Obd2BluetoothOff>()),
        );
      },
    );

    test('throws Obd2ScanTimeout when no known adapter is seen', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        // A phone in range that isn't an OBD2 adapter — registry.resolve
        // returns null, so ranked batches are empty.
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'phone',
              deviceName: 'Pixel 9',
              advertisedServiceUuids: const [
                '0000180f-0000-1000-8000-00805f9b34fb', // battery service
              ],
              rssi: -55,
            ),
          ],
        ]),
      );
      await expectLater(svc.scan().toList(), throwsA(isA<Obd2ScanTimeout>()));
    });

    test('emits ranked vLinker candidate + completes without throwing',
        () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FS',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      expect(emitted, hasLength(1));
      // #761 — "vLinker FS" resolves to the Classic profile, not BLE.
      expect(emitted.single.single.profile.id, 'vlinker-fs-classic');
    });

    test('accumulates across batches and preserves RSSI ranking', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'a',
              deviceName: 'vLinker FS',
              advertisedServiceUuids: const [],
              rssi: -80,
            ),
          ],
          [
            Obd2AdapterCandidate(
              deviceId: 'a',
              deviceName: 'vLinker FS',
              advertisedServiceUuids: const [],
              rssi: -80,
            ),
            Obd2AdapterCandidate(
              deviceId: 'b',
              deviceName: 'OBDLink MX+',
              advertisedServiceUuids: const [],
              rssi: -50,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      expect(emitted.last.first.profile.id, 'obdlink-mx',
          reason: 'strongest RSSI must rank first');
    });
  });

  group('Obd2ConnectionService.connect (#741)', () {
    test('returns a ready Obd2Service on successful init', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: _elmOkResponses()),
        ),
      );
      final candidate = _resolvedVlinker(registry);
      final ready = await svc.connect(candidate);
      expect(ready.isConnected, isTrue);
      await ready.disconnect();
    });

    test('throws Obd2AdapterUnresponsive when the init sequence fails',
        () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          // Channel never emits — BluetoothObd2Transport's 5 s timeout
          // flips the service connect() to return false, which the
          // connection service translates to the typed error.
          channel: _FakeChannel(silent: true),
        ),
      );
      final candidate = _resolvedVlinker(registry);
      await expectLater(
        svc.connect(candidate),
        throwsA(isA<Obd2AdapterUnresponsive>()),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('Obd2ConnectionService dual-transport (#761)', () {
    test('connect dispatches to ClassicBluetoothFacade when the '
        'resolved profile is Classic', () async {
      // Covers the user's actual vLinker FS flow: scan sees a Classic
      // adapter via the classic facade; connect must route through
      // the same facade to build the RFCOMM-backed channel.
      final classicFake = _FakeClassicFacade(
        batches: const [[]],
        channel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: _FakeFacade(batches: const [[]]),
        classicBluetooth: classicFake,
      );
      final candidate = ResolvedObd2Candidate(
        candidate: Obd2AdapterCandidate(
          deviceId: 'cc:dd',
          deviceName: 'vLinker FS 14884',
          advertisedServiceUuids: const [],
          rssi: 0,
        ),
        profile: registry.profiles
            .firstWhere((p) => p.id == 'vlinker-fs-classic'),
      );
      final ready = await svc.connect(candidate);
      expect(ready.isConnected, isTrue);
      expect(classicFake.channelForCalls, ['cc:dd']);
      await ready.disconnect();
    });

    test('connect throws Obd2AdapterUnresponsive on Classic profile '
        'when no Classic facade was wired', () async {
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: _FakeFacade(batches: const [[]]),
        // classicBluetooth: null — misconfiguration safeguard.
      );
      final candidate = ResolvedObd2Candidate(
        candidate: Obd2AdapterCandidate(
          deviceId: 'cc:dd',
          deviceName: 'vLinker FS',
          advertisedServiceUuids: const [],
          rssi: 0,
        ),
        profile: registry.profiles
            .firstWhere((p) => p.id == 'vlinker-fs-classic'),
      );
      await expectLater(
        svc.connect(candidate),
        throwsA(isA<Obd2AdapterUnresponsive>()),
      );
    });

    test('scan merges Classic-only candidates alongside BLE', () async {
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.granted),
        bluetooth: _FakeFacade(batches: const [[]]),
        classicBluetooth: _FakeClassicFacade(batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'cc:dd',
              deviceName: 'vLinker FS 14884',
              advertisedServiceUuids: const [],
              rssi: 0,
            ),
          ],
        ]),
      );
      final emitted = await svc.scan().toList();
      expect(emitted, isNotEmpty);
      expect(emitted.last.single.profile.id, 'vlinker-fs-classic');
    });
  });

  group('Obd2ConnectionService.connectBest', () {
    test('returns null when no scan has happened yet', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(batches: const [[]]),
      );
      expect(await svc.connectBest(), isNull);
    });
  });

  group('Obd2ConnectionService.connectByMacDirect (#2242)', () {
    test('connects WITHOUT scanning on the happy path + runs init',
        () async {
      final directChannel = _FakeChannel(respondTo: _elmOkResponses());
      final fake = _FakeFacade(
        // Non-empty scan batches: if the direct path ever fell back to
        // scan, this would be observable via scanInvoked.
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: directChannel,
      );
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: fake,
      );

      final ready = await svc.connectByMacDirect('aa:bb');

      expect(ready, isNotNull);
      expect(ready!.isConnected, isTrue);
      expect(fake.scanInvoked, isFalse,
          reason: 'direct connect must NOT scan on the happy path');
      expect(fake.directMac, 'aa:bb');
      expect(directChannel.openCalls, 1);
      await ready.disconnect();
    });

    test('passes a 4 s connect timeout to the facade by default',
        () async {
      final fake = _FakeFacade(
        batches: const [[]],
        directChannel: _FakeChannel(respondTo: _elmOkResponses()),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');
      expect(fake.directTimeout, const Duration(seconds: 4));
      await ready!.disconnect();
    });

    test('tears down a prior direct channel before reopening', () async {
      final first = _FakeChannel(respondTo: _elmOkResponses());
      final second = _FakeChannel(respondTo: _elmOkResponses());
      var call = 0;
      final fake = _SequencedDirectFacade(
        sequence: [first, second],
        onDirect: () => call++,
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready1 = await svc.connectByMacDirect('aa:bb');
      expect(first.closeCalls, 0, reason: 'first channel still open');

      final ready2 = await svc.connectByMacDirect('aa:bb');
      expect(first.closeCalls, greaterThanOrEqualTo(1),
          reason: 'prior channel must be torn down before the 2nd open');
      expect(second.openCalls, 1);

      await ready1?.disconnect();
      await ready2?.disconnect();
    });

    test('falls back to the scan path when the direct open times out',
        () async {
      // Direct channel.open() throws (simulates connect timeout / GATT
      // 133); the scan batch carries the same MAC so the fallback
      // connectByMac succeeds.
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        channel: _FakeChannel(respondTo: _elmOkResponses()),
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');

      expect(ready, isNotNull,
          reason: 'scan fallback must still produce a session');
      expect(fake.scanInvoked, isTrue,
          reason: 'failed direct connect must fall back to scan');
      await ready!.disconnect();
    });

    test('returns null when both direct AND scan fallback fail', () async {
      final fake = _FakeFacade(
        // Empty scan ⇒ connectByMac returns null on Obd2ScanTimeout.
        batches: const [[]],
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacDirect('aa:bb');
      expect(ready, isNull);
      expect(fake.scanInvoked, isTrue);
    });

    test(
        'with fallbackToScan:false a failed direct attempt returns null '
        'WITHOUT scanning (#2245)', () async {
      // The in-trip reconnect path owns its own RSSI-gated scan fallback,
      // so it opts out of the service's internal scan to avoid double
      // scanning. A failed direct connect must surface as a plain null.
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: _FakeChannel(
          openError: StateError('connect timed out'),
        ),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready =
          await svc.connectByMacDirect('aa:bb', fallbackToScan: false);
      expect(ready, isNull);
      expect(fake.scanInvoked, isFalse,
          reason: 'fallbackToScan:false must skip the internal scan');
    });
  });

  group('Obd2ConnectionService.connectByMacPassive (#2261 concern 2)', () {
    test(
        'opens an autoConnect channel, NO scan, NO bounded timeout, '
        'runs init', () async {
      final passiveChannel = _FakeChannel(respondTo: _elmOkResponses());
      final fake = _FakeFacade(
        // A non-empty batch would be observable via scanInvoked if the
        // passive path ever scanned — it must not.
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: passiveChannel,
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacPassive('aa:bb');

      expect(ready, isNotNull);
      expect(ready!.isConnected, isTrue);
      expect(fake.directAutoConnect, isTrue,
          reason: 'passive reconnect must request an autoConnect channel');
      expect(fake.scanInvoked, isFalse,
          reason: 'the passive wait must never scan — a passive GATT wait '
              'IS the fallback');
      await ready.disconnect();
    });

    test('returns null on failure WITHOUT a scan fallback', () async {
      final fake = _FakeFacade(
        batches: [
          [
            Obd2AdapterCandidate(
              deviceId: 'aa:bb',
              deviceName: 'vLinker FD',
              advertisedServiceUuids: const [],
              rssi: -55,
            ),
          ],
        ],
        directChannel: _FakeChannel(openError: StateError('passive wait off')),
      );
      final svc = _build(permState: Obd2PermissionState.granted, bt: fake);

      final ready = await svc.connectByMacPassive('aa:bb');
      expect(ready, isNull);
      expect(fake.scanInvoked, isFalse,
          reason: 'a failed passive wait does not scan — the scanner will '
              're-arm another passive wait itself');
    });
  });

  group('Obd2ConnectionService supported-PID cache wiring — #2253', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('conn_svc_pidcache_');
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

    // The resolved candidate's MAC is 'aa:bb' + a Peugeot 107 active
    // vehicle ⇒ this is the production key the service should key on.
    final prodKey = SupportedPidsCache.productionKey(
      adapterMac: 'aa:bb',
      make: 'Peugeot',
      model: '107',
      year: 2008,
    )!;

    test(
        'cold connect scans + persists the bitmap under the adapterMac+'
        'make:model:year production key', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: {
            ..._elmOkResponses(),
            // PIDs 1, 0x0B, 0x0C, 0x0F; continuation bit (PID 32) clear.
            '0100': '41 00 80 32 00 00>',
          }),
        ),
        supportedPidsCache: SupportedPidsCache(box),
        activeVehicleKeyFields: () =>
            (make: 'Peugeot', model: '107', year: 2008, vin: null),
      );

      final ready = await svc.connect(_resolvedVlinker(registry));
      expect(ready.supportsPid(0x0B), isTrue);
      expect(ready.supportsPid(0x5E), isFalse);
      // Persisted under the production key for the next session.
      expect(SupportedPidsCache(box).get(prodKey),
          containsAll([0x01, 0x0B, 0x0C, 0x0F]));
      await ready.disconnect();
    });

    test(
        'warm connect with a pre-seeded production key skips the support '
        'scan AND the 0902 VIN read', () async {
      await SupportedPidsCache(box).put(prodKey, {0x0B, 0x0C, 0x0F});

      // Channel answers ONLY the AT init — neither 0100 nor 0902 wired,
      // so any attempt would surface as the channel's default 'OK>'
      // (a non-bitmap, non-VIN response). We assert the resolver loads
      // the cached set without needing either.
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: _elmOkResponses()),
        ),
        supportedPidsCache: SupportedPidsCache(box),
        activeVehicleKeyFields: () =>
            (make: 'Peugeot', model: '107', year: 2008, vin: null),
      );

      final ready = await svc.connect(_resolvedVlinker(registry));
      // Cached bitmap populated the in-memory set without a scan/VIN read.
      expect(ready.supportsPid(0x0B), isTrue);
      expect(ready.supportsPid(0x5E), isFalse);
      await ready.disconnect();
    });

    test(
        'no cache wired → behaves exactly as before (transport-only), never '
        'rejects a PID', () async {
      final svc = _build(
        permState: Obd2PermissionState.granted,
        bt: _FakeFacade(
          batches: const [[]],
          channel: _FakeChannel(respondTo: _elmOkResponses()),
        ),
        // supportedPidsCache / activeVehicleKeyFields intentionally null.
      );

      final ready = await svc.connect(_resolvedVlinker(registry));
      expect(ready.supportsPid(0x5E), isTrue);
      expect(box.length, 0);
      await ready.disconnect();
    });
  });
}

// --- helpers ---------------------------------------------------------

Obd2ConnectionService _build({
  required Obd2PermissionState permState,
  required BluetoothFacade bt,
  SupportedPidsCache? supportedPidsCache,
  NegotiatedProtocolCache? negotiatedProtocolCache,
  Obd2VehicleKeyFields Function()? activeVehicleKeyFields,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _FakePermissions(permState),
      bluetooth: bt,
      supportedPidsCache: supportedPidsCache,
      negotiatedProtocolCache: negotiatedProtocolCache,
      activeVehicleKeyFields: activeVehicleKeyFields,
    );

ResolvedObd2Candidate _resolvedVlinker(Obd2AdapterRegistry r) {
  // Use the FD (BLE) variant — FS is Classic (#761), and the BLE
  // dispatch is what the unit tests below are validating.
  final candidate = Obd2AdapterCandidate(
    deviceId: 'aa:bb',
    deviceName: 'vLinker FD',
    advertisedServiceUuids: const [],
    rssi: -55,
  );
  return ResolvedObd2Candidate(
    candidate: candidate,
    profile: r.profiles.firstWhere((p) => p.id == 'vlinker-ble'),
  );
}

class _FakePermissions implements Obd2Permissions {
  final Obd2PermissionState state;
  _FakePermissions(this.state);
  @override
  Future<Obd2PermissionState> current() async => state;
  @override
  Future<Obd2PermissionState> request() async => state;
}

class _FakeClassicFacade implements ClassicBluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? channel;
  final List<String> channelForCalls = [];
  _FakeClassicFacade({required this.batches, this.channel});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId) {
    channelForCalls.add(deviceId);
    return channel ?? _FakeChannel(silent: true);
  }
}

class _FakeFacade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  final ElmByteChannel? channel;
  final Object? error;

  /// Channel handed back by [channelForDirect] (#2242). When null the
  /// direct path reuses [channel] / a silent fallback.
  final ElmByteChannel? directChannel;

  /// Set true the first time [scan] is iterated — lets the direct-connect
  /// happy-path test assert NO scan occurred.
  bool scanInvoked = false;

  /// Args captured from the most recent [channelForDirect] call.
  String? directMac;
  Duration? directTimeout;
  bool directAutoConnect = false;
  int directCalls = 0;

  _FakeFacade({
    required this.batches,
    this.channel,
    this.error,
    this.directChannel,
  });

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    scanInvoked = true;
    for (final batch in batches) {
      yield batch;
    }
    final err = error;
    if (err != null) {
      throw err;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) =>
      channel ?? _FakeChannel(silent: true);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    directCalls++;
    directMac = mac;
    directTimeout = connectTimeout;
    directAutoConnect = autoConnect;
    return directChannel ?? channel ?? _FakeChannel(silent: true);
  }
}

/// Hands back a different direct channel per call so the teardown test
/// can assert the FIRST channel is closed before the SECOND opens.
class _SequencedDirectFacade implements BluetoothFacade {
  final List<ElmByteChannel> sequence;
  final void Function() onDirect;
  int _i = 0;
  _SequencedDirectFacade({required this.sequence, required this.onDirect});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) =>
      _FakeChannel(silent: true);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    onDirect();
    return sequence[_i++];
  }
}

/// Minimal channel that answers every write with the canonical ELM327
/// OK prompt so the transport's init sequence completes. Silent mode
/// never emits — useful for the unresponsive-adapter test.
class _FakeChannel implements ElmByteChannel {
  final bool silent;
  final Map<String, String>? respondTo;

  /// When set, [open] throws this — simulates a direct-connect timeout /
  /// GATT_ERROR 133 so the service falls back to the scan path (#2242).
  final Object? openError;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;
  int openCalls = 0;
  int closeCalls = 0;

  _FakeChannel({this.silent = false, this.respondTo, this.openError});

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async {
    openCalls++;
    final err = openError;
    if (err != null) throw err;
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (silent) return;
    final cmd = String.fromCharCodes(bytes).trim();
    final reply = respondTo?[cmd] ?? 'OK>';
    _ctrl.add(reply.codeUnits);
  }

  @override
  Future<void> close() async {
    closeCalls++;
    _open = false;
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}

/// Canned init-sequence responses covering what `Elm327Protocol.initCommands`
/// sends: ATZ, ATE0, ATL0, ATH0, ATSP0.
Map<String, String> _elmOkResponses() => {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    };
