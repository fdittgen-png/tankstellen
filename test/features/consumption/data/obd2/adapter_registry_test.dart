import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapters/smart_obd_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapters/v_linker_fs_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_adapter.dart';

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

  group('Obd2AdapterRegistry.resolve — expanded catalog (#949)', () {
    // Each assertion below mirrors the "resolve by advertised name"
    // path used by the BLE scan flow. The picker feeds the registry
    // via Obd2AdapterCandidate; these tests ensure each new #949
    // entry is reachable without relying on a service-UUID hit.

    test('SmartOBD BLE advert is labelled as SmartOBD (not generic)', () {
      final hit = _candidate(
        name: 'SmartOBD-BT',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'smartobd-ble');
      expect(profile.transport, BluetoothTransport.ble);
    });

    test('SmartOBD Classic bonded-device name lands on a SmartOBD profile',
        () {
      // Classic devices have no advertised services — the name is
      // all we get. BLE and Classic SmartOBD entries share the
      // matcher; the BLE entry is listed first, so the assertion
      // below accepts either SmartOBD id — the guard is against the
      // generic fallback winning.
      final hit = _candidate(name: 'SmartOBD', services: []);
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, startsWith('smartobd'));
    });

    test('ieGeek Scanner matched by name (#949)', () {
      final hit = _candidate(
        name: 'ieGeek 123',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      expect(registry.resolve(hit)?.id, 'iegeek');
    });

    test('vLinker BM+ matches the new BM+ profile, not a generic', () {
      final hit = _candidate(
        name: 'vLinker BM+ BLE',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'vlinker-bm-plus');
    });

    test(
      'vLinker BM-Android (Classic SPP) matches vlinker-bm-android-classic '
      '(#1349)',
      () {
        // User-reported 2026-05-02: bonded device "vLinker BM-Android"
        // was hidden from the picker entirely because no profile
        // matched the name. Classic transport — Bluetooth bonded list
        // carries no advertised services.
        final hit = _candidate(name: 'vLinker BM-Android', services: []);
        final profile = registry.resolve(hit);
        expect(profile, isNotNull,
            reason: 'BM-Android variant must surface in the picker, '
                'not be silently dropped because the registry has no '
                'matcher (#1349)');
        expect(profile!.id, 'vlinker-bm-android-classic');
        expect(profile.transport, BluetoothTransport.classic);
      },
    );

    test(
      'vLinker BM+ does not collide with the new BM-Android entry (#1349)',
      () {
        // Regression guard: the BM+ matcher requires the literal "+"
        // and the BM-Android matcher requires the literal "-android".
        // Neither glyph appears in the other so the entries are
        // disjoint regardless of profile-list ordering.
        final hit = _candidate(
          name: 'vLinker BM+',
          services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
        );
        expect(registry.resolve(hit)?.id, 'vlinker-bm-plus');
      },
    );

    test('vLinker BM (no plus) does NOT collide with the BM+ entry', () {
      // Regression guard: a plain "vLinker BM" advert must not be
      // hijacked by the BM+ matcher — the "+" is the distinguishing
      // glyph. With the current catalog there is no named BM-only
      // profile, so the advert falls through to the generic FFF0
      // BLE fallback (via the advertised Nordic-UART service).
      final hit = _candidate(
        name: 'vLinker BM',
        services: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, isNot('vlinker-bm-plus'));
      expect(profile.id, 'generic-fff0');
    });

    test('Konnwei / KW902 → konnwei-kw902 (#949)', () {
      expect(
        registry.resolve(_candidate(name: 'KONNWEI KW902', services: []))?.id,
        'konnwei-kw902',
      );
      expect(
        registry.resolve(_candidate(name: 'KW902-OBD', services: []))?.id,
        'konnwei-kw902',
      );
    });

    test('Vgate iCar Pro matched by "Vgate" and by "iCar Pro" (#949)', () {
      expect(
        registry
            .resolve(_candidate(name: 'Vgate iCar Pro BLE', services: []))
            ?.id,
        'vgate-icar-pro',
      );
      expect(
        registry.resolve(_candidate(name: 'iCar Pro 2', services: []))?.id,
        'vgate-icar-pro',
      );
    });

    test('Panlong WiFi matched by name (#949)', () {
      expect(
        registry
            .resolve(_candidate(name: 'Panlong WiFi OBD', services: []))
            ?.id,
        'panlong-wifi',
      );
    });

    test('BAFX matched by name (#949)', () {
      expect(
        registry
            .resolve(_candidate(name: 'BAFX Products 34t5', services: []))
            ?.id,
        'bafx',
      );
    });

    test('"random device" name with no OBD signature is rejected', () {
      // Regression guard on the generic fallback: a noisy advert
      // with no OBD signature and no relevant service UUID must not
      // be matched by any of the new #949 entries. The generic-
      // classic profile only fires when the name contains "obd" /
      // "elm327" etc., so "random device" lands on null and the UI
      // hides it.
      final hit = _candidate(name: 'random device', services: []);
      expect(registry.resolve(hit), isNull);
    });

    test('generic Classic ELM327 clone still reaches generic-classic after '
        '#949 additions', () {
      // Guard on the "last entry is the catch-all" contract. A
      // name that carries an OBD signature but matches none of the
      // named profiles must land on the generic-classic fallback.
      final hit = _candidate(name: 'OBD-II Random Clone', services: []);
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'generic-classic');
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
    test('vLinker BLE defaults to GenericElm327Adapter (100 ms / 100 ms)', () {
      final v = registry.profiles.firstWhere((p) => p.id == 'vlinker-ble');
      expect(v.adapter, isA<GenericElm327Adapter>());
      expect(v.adapter.postResetDelay, const Duration(milliseconds: 100));
      expect(v.adapter.interCommandDelay, const Duration(milliseconds: 100));
    });

    test('generic BLE fallback also uses GenericElm327Adapter (#1330 phase 2)',
        () {
      final g = registry.profiles.firstWhere((p) => p.id == 'generic-fff0');
      expect(g.adapter, isA<GenericElm327Adapter>());
    });

    test('generic-classic fallback uses GenericElm327Adapter (#761, #1330)',
        () {
      final g = registry.profiles.firstWhere((p) => p.id == 'generic-classic');
      expect(g.adapter, isA<GenericElm327Adapter>());
      expect(g.transport, BluetoothTransport.classic);
    });
  });

  group('Obd2AdapterProfile.adapter wiring (#1330 phase 2)', () {
    test('vLinker FS Classic profile is wired to VLinkerFsAdapter', () {
      final v =
          registry.profiles.firstWhere((p) => p.id == 'vlinker-fs-classic');
      expect(v.adapter, isA<VLinkerFsAdapter>());
      expect(v.adapter.id, 'vlinker-fs');
      expect(v.adapter.postResetDelay, const Duration(milliseconds: 200));
      expect(v.adapter.interCommandDelay, const Duration(milliseconds: 50));
    });

    test('SmartOBD BLE profile is wired to SmartObdAdapter', () {
      final s = registry.profiles.firstWhere((p) => p.id == 'smartobd-ble');
      expect(s.adapter, isA<SmartObdAdapter>());
      expect(s.adapter.id, 'smart-obd');
      expect(s.adapter.postResetDelay, const Duration(milliseconds: 400));
      expect(s.adapter.interCommandDelay, const Duration(milliseconds: 200));
    });

    test('SmartOBD Classic profile is wired to SmartObdAdapter', () {
      final s = registry.profiles.firstWhere((p) => p.id == 'smartobd-classic');
      expect(s.adapter, isA<SmartObdAdapter>());
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
