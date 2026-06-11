// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/adapters/smart_obd_adapter.dart';
import 'package:tankstellen/features/obd2/data/adapters/v_linker_fs_adapter.dart';
import 'package:tankstellen/features/obd2/data/elm327_adapter.dart';

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

    test(
        'Classic-discovered clone named "OBDII" → generic-classic fallback '
        '(#761, #3097)', () {
      // Amazon's generic Classic-SPP dongles report themselves with
      // no FFF0 service (Classic has no advertised services) and a
      // name like "OBDII" / "ELM327 v1.5". A Classic-discovered hit
      // (the Android bonded-device path) must land on the
      // generic-classic profile, not null — and NOT be hijacked by
      // the new generic-ble entry that shares the same matchers (#3097).
      final hit = _candidate(
        name: 'OBDII',
        services: [],
        discoveryTransport: BluetoothTransport.classic,
      );
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'generic-classic');
      expect(profile.transport, BluetoothTransport.classic);
    });

    test(
        'BLE-discovered clone named "OBDII" → generic-ble (NOT classic) '
        '(#3097)', () {
      // The iPhone bug: a generic ELM327 BLE adapter advertises a name
      // ("OBDII", "ELM327 v1.5") and NO service UUID, so CoreBluetooth
      // surfaces it over BLE with no advertised services. Before #3097
      // the only generic name matchers lived on the Classic profile, so
      // it resolved to generic-classic → a Classic connect iOS cannot
      // make (no MFi). With the discovery transport stamped `ble`, it
      // must resolve to a BLE profile so the BLE + dynamic-GATT path runs.
      final hit = _candidate(
        name: 'OBDII',
        services: [],
        discoveryTransport: BluetoothTransport.ble,
      );
      final profile = registry.resolve(hit);
      expect(profile, isNotNull);
      expect(profile!.id, 'generic-ble');
      expect(profile.transport, BluetoothTransport.ble,
          reason: 'a BLE-discovered generic ELM327 must resolve to a BLE '
              'profile so it connects on iPhone (#3097)');
    });

    test('a name-only ELM327 v1.5 over BLE resolves to generic-ble (#3097)',
        () {
      final hit = _candidate(
        name: 'ELM327 v1.5',
        services: [],
        discoveryTransport: BluetoothTransport.ble,
      );
      expect(registry.resolve(hit)?.id, 'generic-ble');
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
      // named profiles must land on the generic-classic fallback when
      // discovered over Classic (the Android bonded path) (#3097).
      final hit = _candidate(
        name: 'OBD-II Random Clone',
        services: [],
        discoveryTransport: BluetoothTransport.classic,
      );
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

  group('Obd2AdapterRegistry.resolve — broadened generic matchers (#3103)', () {
    test('bare "obd"/"elm" stems now resolve clone names to a generic profile',
        () {
      // Names that contain the bare stems but match NO specific brand profile.
      for (final n in ['OBD Mini', 'Super OBD', 'ELM 327', 'MyOBD']) {
        final hit = registry.resolve(_candidate(name: n, services: []));
        expect(hit?.isGeneric, isTrue, reason: '$n should resolve to generic');
      }
    });

    test('a SPECIFIC profile still beats the broadened generic (KW902-OBD, '
        'OBDLink MX+)', () {
      expect(
        registry.resolve(_candidate(name: 'KW902-OBD', services: []))?.id,
        'konnwei-kw902',
      );
      expect(
        registry.resolve(_candidate(name: 'OBDLink MX+', services: []))?.id,
        'obdlink-mx',
      );
    });
  });

  group('Obd2AdapterRegistry.rank', () {
    test(
        '#3103 — recognized first (RSSI desc), then NAMED-unrecognized appended '
        '(classify, not drop)', () {
      final cands = [
        _candidate(name: 'Apple Watch', services: [], rssi: -40),
        _candidate(name: 'vLinker FS 14884', services: [], rssi: -70),
        _candidate(name: 'OBDLink MX+', services: [], rssi: -55),
      ];
      final ranked = registry.rank(cands);
      // Recognized adapters rank first by RSSI; the named-but-unknown
      // 'Apple Watch' (a stronger signal) is CLASSIFIED, not dropped, and
      // appended last so it never outranks a real adapter.
      expect(ranked.map((r) => r.profile.id).toList(),
          ['obdlink-mx', 'vlinker-fs-classic', 'unrecognized']);
      expect(ranked.map((r) => r.recognized).toList(), [true, true, false]);
      expect(ranked.last.candidate.deviceName, 'Apple Watch');
    });

    test('#3103 — a NAMELESS device is still dropped (BLE-beacon noise)', () {
      final ranked = registry.rank([
        _candidate(name: '', services: [], rssi: -50),
        _candidate(name: 'OBDLink MX+', services: [], rssi: -55),
      ]);
      expect(ranked.map((r) => r.profile.id).toList(), ['obdlink-mx']);
    });

    test('#3103 — unrecognized placeholder carries the discovery transport', () {
      final ble = registry.rank([
        _candidate(name: 'MyCarThing', services: []),
      ]).single;
      expect(ble.recognized, isFalse);
      expect(ble.profile.transport, BluetoothTransport.ble);

      final classic = registry.rank([
        _candidate(
          name: 'MyCarThing',
          services: const [],
          discoveryTransport: BluetoothTransport.classic,
        ),
      ]).single;
      expect(classic.recognized, isFalse);
      expect(classic.profile.transport, BluetoothTransport.classic);
    });

    test('empty list → empty result', () {
      expect(registry.rank(const []), isEmpty);
    });
  });

  group('Obd2AdapterProfile', () {
    test('vLinker BLE defaults to GenericElm327Adapter (#2969: 1 s / 100 ms)',
        () {
      final v = registry.profiles.firstWhere((p) => p.id == 'vlinker-ble');
      expect(v.adapter, isA<GenericElm327Adapter>());
      // #2969 — generic postResetDelay bumped 100 ms → 1 s for cold clones.
      expect(v.adapter.postResetDelay, const Duration(seconds: 1));
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
      // #2969 — vLinker FS postResetDelay bumped 200 ms → 1 s (field evidence
      // the clones need ≥1 s to re-enumerate after ATZ).
      expect(v.adapter.postResetDelay, const Duration(seconds: 1));
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

  group('Obd2AdapterProfile.compatibility (#1371 phase 1)', () {
    test('default compatibility for an unspecified entry is theoretical', () {
      // The Carista entry in _defaultProfiles intentionally omits the
      // compatibility argument — it must surface as theoretical so
      // adding new entries stays conservative without ceremony.
      final c = registry.profiles.firstWhere((p) => p.id == 'carista');
      expect(c.compatibility, Obd2AdapterCompatibility.theoretical);
    });

    test('vLinker FS Classic is marked as tested', () {
      final v =
          registry.profiles.firstWhere((p) => p.id == 'vlinker-fs-classic');
      expect(v.compatibility, Obd2AdapterCompatibility.tested);
    });

    test('vLinker BM-Android Classic is marked as tested', () {
      final v = registry.profiles
          .firstWhere((p) => p.id == 'vlinker-bm-android-classic');
      expect(v.compatibility, Obd2AdapterCompatibility.tested);
    });

    test('both SmartOBD entries are marked as userVerified', () {
      // Maintainer confirmed the hardware works but the bonded list
      // showed the same name for both transports — neither variant
      // can be promoted past userVerified yet.
      final ble = registry.profiles.firstWhere((p) => p.id == 'smartobd-ble');
      final classic =
          registry.profiles.firstWhere((p) => p.id == 'smartobd-classic');
      expect(ble.compatibility, Obd2AdapterCompatibility.userVerified);
      expect(classic.compatibility, Obd2AdapterCompatibility.userVerified);
    });

    test('every default profile carries a non-null compatibility value', () {
      // Guard so a future entry can't accidentally land with a null
      // value via a refactor — the field is non-nullable today, but
      // documenting the contract here means the wiki matrix can rely
      // on `profile.compatibility.name` without a defensive fallback.
      for (final p in registry.profiles) {
        expect(
          Obd2AdapterCompatibility.values.contains(p.compatibility),
          isTrue,
          reason: 'profile ${p.id} has invalid compatibility value '
              '${p.compatibility}',
        );
      }
    });

    test('exactly two profiles are tested today (#1371 maintainer baseline)',
        () {
      // Regression guard on the phase-1 maintainer baseline. Bumping
      // this count requires a deliberate edit to acknowledge a new
      // verified adapter — and a wiki/docs update in phase 2/3.
      final tested = registry.profiles
          .where((p) => p.compatibility == Obd2AdapterCompatibility.tested)
          .map((p) => p.id)
          .toList();
      expect(tested,
          unorderedEquals(['vlinker-fs-classic', 'vlinker-bm-android-classic']));
    });
  });

  group('catalog integrity (#1651)', () {
    test('the registry ships at least 20 named adapter profiles', () {
      // Epic #1641 grew the registry to the 20+ best-selling adapters.
      // "Named" excludes the two generic-fallback profiles.
      final named = registry.profiles
          .where((p) => p.nameMatchers.isNotEmpty)
          .toList();
      expect(named.length, greaterThanOrEqualTo(20),
          reason: 'registry must list >= 20 named adapters (#1641)');
    });

    test('profile ids are unique', () {
      final ids = registry.profiles.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'every Obd2AdapterProfile.id must be unique');
    });

    test('no name matcher is ambiguous across profiles', () {
      // A matcher owned by two profiles of the SAME transport makes
      // `resolve` order-dependent and ambiguous. Sharing is allowed
      // only for a BLE+Classic pair of the same adapter (e.g. SmartOBD
      // ships both transports under one advertised name).
      final owners = <String, List<Obd2AdapterProfile>>{};
      for (final p in registry.profiles) {
        for (final m in p.nameMatchers) {
          owners.putIfAbsent(m, () => []).add(p);
        }
      }
      final ambiguous = owners.entries.where((e) {
        final transports = e.value.map((p) => p.transport).toSet();
        // OK when each sharing profile has a distinct transport.
        return transports.length != e.value.length;
      }).toList();
      expect(ambiguous, isEmpty,
          reason: 'same-transport profiles share a matcher: '
              '${ambiguous.map((e) => "${e.key} -> "
                  "${e.value.map((p) => p.id)}").join(", ")}');
    });

    test('every generic (matcher-less) profile has a unique service UUID',
        () {
      // Matcher-less profiles resolve purely on the advertised service
      // UUID; two of them sharing a UUID would be a non-deterministic
      // fallback. Named profiles legitimately share the FFF0 family.
      final genericUuids = registry.profiles
          .where((p) => p.nameMatchers.isEmpty && p.serviceUuid.isNotEmpty)
          .map((p) => p.serviceUuid.toLowerCase())
          .toList();
      expect(genericUuids.toSet().length, genericUuids.length,
          reason: 'matcher-less fallback profiles must not share a '
              'service UUID');
    });

    test('every profile carries a valid compatibility enum value', () {
      for (final p in registry.profiles) {
        expect(Obd2AdapterCompatibility.values, contains(p.compatibility),
            reason: '${p.id} has an invalid compatibility value');
      }
    });

    test('every BLE profile defines all three GATT UUIDs', () {
      for (final p in registry.profiles
          .where((p) => p.transport == BluetoothTransport.ble)
          // #3097 — the name-only generic-ble fallback INTENTIONALLY pins no
          // service UUID: it connects via dynamic GATT discovery (#3014), which
          // finds the ELM service post-connect among FFE0/FFF0/18F0/Nordic-UART
          // by characteristic property. Every OTHER BLE profile keeps its exact
          // UUIDs as the known-good hint.
          .where((p) => p.id != 'generic-ble')) {
        expect(p.serviceUuid, isNotEmpty, reason: '${p.id} serviceUuid');
        expect(p.writeCharUuid, isNotEmpty, reason: '${p.id} writeCharUuid');
        expect(p.notifyCharUuid, isNotEmpty,
            reason: '${p.id} notifyCharUuid');
      }
    });

    test('generic-ble fallback pins NO service UUID — dynamic GATT (#3097)',
        () {
      final g = registry.profiles.firstWhere((p) => p.id == 'generic-ble');
      expect(g.transport, BluetoothTransport.ble);
      expect(g.serviceUuid, isEmpty,
          reason: 'generic-ble relies on dynamic GATT discovery so it can '
              'connect to a name-only adapter that advertises no service');
      expect(g.adapter, isA<GenericElm327Adapter>());
      // Shares the generic-classic name signature so the same generic names
      // are recognised on both transports; resolve() splits them by the
      // candidate discovery transport.
      final c = registry.profiles.firstWhere((p) => p.id == 'generic-classic');
      expect(g.nameMatchers, c.nameMatchers);
    });

    test('the #1641 best-seller additions resolve by name', () {
      expect(
          registry.resolve(_candidate(name: 'BlueDriver', services: []))?.id,
          'bluedriver');
      expect(
          registry.resolve(_candidate(name: 'OBDLink LX', services: []))?.id,
          'obdlink-lx');
      expect(
          registry.resolve(_candidate(name: 'OBDLink CX', services: []))?.id,
          'obdlink-cx');
      expect(
          registry.resolve(_candidate(name: 'TopScan', services: []))?.id,
          'topdon-topscan');
      // The tightened MX matcher still catches the MX+.
      expect(
          registry.resolve(_candidate(name: 'OBDLink MX+', services: []))?.id,
          'obdlink-mx');
    });

    test(
        '#3180 — the OBDLink CX profile pins the vendor-documented FFF0 '
        'service / FFF2 write / FFF1 notify layout (NOT the MX+/LX 18F0)',
        () {
      final cx = registry.profiles.firstWhere((p) => p.id == 'obdlink-cx');
      expect(cx.serviceUuid, '0000fff0-0000-1000-8000-00805f9b34fb',
          reason: 'the real CX exposes service FFF0 — the previous 18F0 was '
              'the MX+/LX layout and made the exact-UUID hint miss');
      expect(cx.writeCharUuid, '0000fff2-0000-1000-8000-00805f9b34fb');
      expect(cx.notifyCharUuid, '0000fff1-0000-1000-8000-00805f9b34fb');
      // The MX+/LX siblings keep their custom 18F0 family untouched.
      final mx = registry.profiles.firstWhere((p) => p.id == 'obdlink-mx');
      final lx = registry.profiles.firstWhere((p) => p.id == 'obdlink-lx');
      expect(mx.serviceUuid, '000018f0-0000-1000-8000-00805f9b34fb');
      expect(lx.serviceUuid, '000018f0-0000-1000-8000-00805f9b34fb');
    });
  });

  _transportForNameTests(registry);
}

void _transportForNameTests(Obd2AdapterRegistry registry) {
  group('Obd2AdapterRegistry.transportForName (#2969)', () {
    test('infers Classic for a stored vLinker FS name', () {
      expect(registry.transportForName('vLinker FS 1234'),
          BluetoothTransport.classic);
    });
    test('infers BLE for a stored vLinker FD name', () {
      expect(registry.transportForName('vLinker FD'), BluetoothTransport.ble);
    });
    test('returns null for an unfamiliar adapter name', () {
      expect(registry.transportForName('SomeRandomDongle'), isNull);
    });
    test('returns null for null / empty', () {
      expect(registry.transportForName(null), isNull);
      expect(registry.transportForName(''), isNull);
    });
  });

  group('Obd2AdapterRegistry dual-transport disambiguation (#3014)', () {
    test('SmartOBD name-matches BOTH transports (the ambiguity)', () {
      final matched = registry.transportsForName('SmartOBD');
      expect(matched, contains(BluetoothTransport.ble));
      expect(matched, contains(BluetoothTransport.classic));
    });

    test('a dual-match prefers bonded-Classic when the MAC is bonded', () {
      expect(
        registry.disambiguateTransport(name: 'SmartOBD', macIsBonded: true),
        BluetoothTransport.classic,
      );
    });

    test('a dual-match defaults to BLE when the MAC is NOT bonded', () {
      expect(
        registry.disambiguateTransport(name: 'SmartOBD', macIsBonded: false),
        BluetoothTransport.ble,
      );
    });

    test('a single-transport match returns that transport unchanged', () {
      // vLinker FD is BLE-only; bonded flag is irrelevant.
      expect(
        registry.disambiguateTransport(name: 'vLinker FD', macIsBonded: true),
        BluetoothTransport.ble,
      );
      expect(
        registry.disambiguateTransport(
            name: 'vLinker FS 1', macIsBonded: false),
        BluetoothTransport.classic,
      );
    });

    test('no name match returns null regardless of bonding', () {
      expect(
        registry.disambiguateTransport(
            name: 'SomeRandomDongle', macIsBonded: true),
        isNull,
      );
    });
  });
}

Obd2AdapterCandidate _candidate({
  required String name,
  required Iterable<String> services,
  int rssi = -60,
  BluetoothTransport discoveryTransport = BluetoothTransport.ble,
}) =>
    Obd2AdapterCandidate(
      deviceId: 'aa:bb:cc:dd:ee:ff',
      deviceName: name,
      advertisedServiceUuids: services,
      rssi: rssi,
      discoveryTransport: discoveryTransport,
    );
