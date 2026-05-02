import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';

void main() {
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
}

// --- helpers ---------------------------------------------------------

Obd2ConnectionService _build({
  required Obd2PermissionState permState,
  required BluetoothFacade bt,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _FakePermissions(permState),
      bluetooth: bt,
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
  _FakeFacade({required this.batches, this.channel, this.error});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
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
}

/// Minimal channel that answers every write with the canonical ELM327
/// OK prompt so the transport's init sequence completes. Silent mode
/// never emits — useful for the unresponsive-adapter test.
class _FakeChannel implements ElmByteChannel {
  final bool silent;
  final Map<String, String>? respondTo;
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;

  _FakeChannel({this.silent = false, this.respondTo});

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async {
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
    _open = false;
    await _ctrl.close();
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
