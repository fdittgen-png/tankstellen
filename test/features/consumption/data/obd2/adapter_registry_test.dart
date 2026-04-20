import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';

void main() {
  final registry = Obd2AdapterRegistry.defaults();

  group('Obd2AdapterRegistry.resolve (#733 + #761)', () {
    test('vLinker FS matches the Classic profile — not BLE (#761)', () {
      // Ground-truth evidence from the user's device 2026-04-20: the
      // adapter appears as "vLinker FS 14884" in Android Bluetooth
      // settings under Classic. Our registry must resolve it to the
      // classic transport so Obd2ConnectionService dispatches to the
      // ClassicBluetoothFacade.
      final hit = _candidate(name: 'vLinker FS 14884', services: []);
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'vlinker-fs-classic');
      expect(profile.transport, BluetoothTransport.classic);
    });

    test('vLinker FD (BLE variant) matches the BLE profile', () {
      final hit = _candidate(name: 'vLinker FD', services: []);
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'vlinker-ble');
      expect(profile.transport, BluetoothTransport.ble);
    });

    test('OBDLink MX+ matched by name', () {
      final hit = _candidate(name: 'OBDLink MX+', services: []);
      expect(registry.resolve(hit)?.id, 'obdlink-mx');
    });

    test('Carista matched by name even though it shares the FFF0 service',
        () {
      final hit = _candidate(
        name: 'Carista OBD2',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      expect(registry.resolve(hit)?.id, 'carista');
    });

    test('unknown name with FFF0 service → generic-fff0 (BLE fallback)',
        () {
      final hit = _candidate(
        name: 'Some Random Clone',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      expect(registry.resolve(hit)?.id, 'generic-fff0');
    });

    test('Classic clone named "OBDII" → generic-classic fallback (#761)',
        () {
      // Amazon's generic Classic-SPP dongles report themselves with
      // no FFF0 service (Classic has no advertised services) and a
      // name like "OBDII" / "ELM327 v1.5". Must land on the
      // generic-classic profile, not null.
      final hit = _candidate(name: 'OBDII', services: []);
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'generic-classic');
      expect(profile.transport, BluetoothTransport.classic);
    });

    test('unknown name and unrelated service → null (hide from picker)',
        () {
      final hit = _candidate(
        name: 'Apple Watch',
        services: const ['0000180d-0000-1000-8000-00805f9b34fb'],
      );
      expect(registry.resolve(hit), isNull);
    });

    test('empty name + empty services → null', () {
      expect(registry.resolve(_candidate(name: '', services: [])), isNull);
    });

    test('service UUID match is case-insensitive', () {
      final hit = _candidate(
        name: '',
        services: const ['0000FFF0-0000-1000-8000-00805F9B34FB'],
      );
      expect(registry.resolve(hit)?.id, 'generic-fff0');
    });
  });

  group('Obd2AdapterRegistry.allServiceUuids', () {
    test('only BLE profiles contribute service UUIDs (#761)', () {
      // Classic profiles have no advertised service UUID — including
      // them would poison `FlutterBluePlus.startScan(withServices:)`
      // with garbage filters. Confirm they're excluded.
      final uuids = registry.allServiceUuids;
      expect(uuids.contains('0000fff0-0000-1000-8000-00805f9b34fb'), isTrue);
      expect(uuids.contains('000018f0-0000-1000-8000-00805f9b34fb'), isTrue);
      expect(uuids, everyElement(isNotEmpty));
    });
  });

  group('Obd2AdapterRegistry.rank', () {
    test('drops unresolved candidates, sorts resolved by RSSI desc', () {
      final cands = [
        _candidate(name: 'Apple Watch', services: [], rssi: -40),
        _candidate(name: 'vLinker FS 14884', services: [], rssi: -70),
        _candidate(name: 'OBDLink MX+', services: [], rssi: -55),
      ];
      final ranked = registry.rank(cands);
      expect(ranked.map((r) => r.profile.id).toList(),
          ['obdlink-mx', 'vlinker-fs-classic']);
    });

    test('empty list → empty result', () {
      expect(registry.rank(const []), isEmpty);
    });
  });

  group('Obd2AdapterProfile', () {
    test('vLinker BLE defaults to 100 ms init delay', () {
      final v =
          registry.profiles.firstWhere((p) => p.id == 'vlinker-ble');
      expect(v.initDelay, const Duration(milliseconds: 100));
    });

    test('generic BLE fallback uses a longer init delay for slow clones',
        () {
      final g =
          registry.profiles.firstWhere((p) => p.id == 'generic-fff0');
      expect(g.initDelay, const Duration(milliseconds: 300));
    });

    test('generic-classic fallback also uses the 300 ms init delay (#761)',
        () {
      final g =
          registry.profiles.firstWhere((p) => p.id == 'generic-classic');
      expect(g.initDelay, const Duration(milliseconds: 300));
      expect(g.transport, BluetoothTransport.classic);
    });
  });
}

Obd2AdapterCandidate _candidate({
  required String name,
  required Iterable<String> services,
  int rssi = -60,
}) =>
    Obd2AdapterCandidate(
      deviceId: 'aa:bb:cc:dd:ee:ff',
      deviceName: name,
      advertisedServiceUuids: services,
      rssi: rssi,
    );
