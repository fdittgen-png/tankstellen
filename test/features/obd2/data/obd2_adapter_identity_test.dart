// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/obd2_adapter_identity.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3168 — iOS CBPeripheral UUID rotation: identity capture, the name-based
/// rematch decision table, and the fresh-UUID re-persist.
void main() {
  silenceErrorLoggerSpool();
  final registry = Obd2AdapterRegistry.defaults();

  const iosUuid = '12345678-9ABC-4DEF-8012-3456789ABCDE';
  const iosUuidRotated = 'FEDCBA98-7654-4321-8FED-CBA987654321';
  const androidMac = 'AA:BB:CC:DD:EE:FF';

  ResolvedObd2Candidate candidate(String id, String name, {int rssi = -55}) {
    final ranked = registry.rank([
      Obd2AdapterCandidate(
        deviceId: id,
        deviceName: name,
        advertisedServiceUuids: const [],
        rssi: rssi,
      ),
    ]);
    expect(ranked, isNotEmpty, reason: 'test candidate "$name" must rank');
    return ranked.single;
  }

  group('looksLikeIosPeripheralUuid (#3168)', () {
    test('matches a canonical iOS CBPeripheral UUID (any case)', () {
      expect(looksLikeIosPeripheralUuid(iosUuid), isTrue);
      expect(looksLikeIosPeripheralUuid(iosUuid.toLowerCase()), isTrue);
      expect(looksLikeIosPeripheralUuid(' $iosUuid '), isTrue,
          reason: 'tolerates surrounding whitespace');
    });

    test('rejects an Android MAC and non-UUID shapes', () {
      expect(looksLikeIosPeripheralUuid(androidMac), isFalse);
      expect(looksLikeIosPeripheralUuid(''), isFalse);
      expect(looksLikeIosPeripheralUuid('not-a-uuid'), isFalse);
      expect(looksLikeIosPeripheralUuid('12345678-9ABC-4DEF-8012'), isFalse,
          reason: 'truncated UUID must not match');
      expect(
          looksLikeIosPeripheralUuid(
              '12345678-9ABC-4DEF-8012-3456789ABCDE-EXTRA'),
          isFalse,
          reason: 'trailing garbage must not match');
    });
  });

  group('Obd2AdapterIdentity.fromCandidate (#3168 — picker capture seam)', () {
    test('UUID-shaped deviceId (iOS) → uuidIos carries the reconnection key',
        () {
      final identity =
          Obd2AdapterIdentity.fromCandidate(candidate(iosUuid, 'OBDLink CX'));
      expect(identity.deviceId, iosUuid);
      expect(identity.name, 'OBDLink CX');
      expect(identity.uuidIos, iosUuid);
    });

    test('MAC-shaped deviceId (Android) → uuidIos stays null', () {
      final identity = Obd2AdapterIdentity.fromCandidate(
          candidate(androidMac, 'OBDLink CX'));
      expect(identity.deviceId, androidMac);
      expect(identity.uuidIos, isNull);
    });

    test('anonymous advertisement → name falls back to the profile label',
        () {
      // A nameless candidate matched by service UUID resolves to the
      // generic FFF0 profile; the persisted name is its display label —
      // the same fallback the picker used before the capture moved here.
      final ranked = registry.rank([
        Obd2AdapterCandidate(
          deviceId: iosUuid,
          deviceName: '',
          advertisedServiceUuids: const [
            '0000fff0-0000-1000-8000-00805f9b34fb',
          ],
          rssi: -55,
        ),
      ]);
      expect(ranked, isNotEmpty);
      final identity = Obd2AdapterIdentity.fromCandidate(ranked.single);
      expect(identity.name, ranked.single.profile.displayName);
      expect(identity.name, isNotEmpty);
    });
  });

  group('Obd2UuidRematchDecision.decide — the #3168 decision table', () {
    test('rotated UUID + exactly one name match → matched', () {
      final fresh = candidate(iosUuidRotated, 'OBDLink CX');
      final decision = Obd2UuidRematchDecision.decide(
        pinnedId: iosUuid,
        pinnedName: 'OBDLink CX',
        ranked: [candidate(androidMac, 'vLinker FD'), fresh],
      );
      expect(decision.result, Obd2UuidRematchResult.matched);
      expect(decision.candidate, same(fresh));
    });

    test('pinned id still present under the SAME id is not a rematch '
        '(deviceId differs case-insensitively)', () {
      final decision = Obd2UuidRematchDecision.decide(
        pinnedId: iosUuid,
        pinnedName: 'OBDLink CX',
        ranked: [candidate(iosUuid.toLowerCase(), 'OBDLink CX')],
      );
      expect(decision.result, Obd2UuidRematchResult.noCandidate,
          reason: 'a case-variant of the pinned id is the SAME peripheral — '
              'the exact-id path owns it, never the rematch');
    });

    test('name collision — two same-named candidates → ambiguous, no pick',
        () {
      final decision = Obd2UuidRematchDecision.decide(
        pinnedId: iosUuid,
        pinnedName: 'OBDLink CX',
        ranked: [
          candidate(iosUuidRotated, 'OBDLink CX'),
          candidate('00000000-1111-4222-8333-444455556666', 'OBDLink CX'),
        ],
      );
      expect(decision.result, Obd2UuidRematchResult.ambiguous);
      expect(decision.candidate, isNull);
      expect(decision.candidateCount, 2);
    });

    test('no same-named candidate → noCandidate', () {
      final decision = Obd2UuidRematchDecision.decide(
        pinnedId: iosUuid,
        pinnedName: 'OBDLink CX',
        ranked: [candidate(iosUuidRotated, 'vLinker FD')],
      );
      expect(decision.result, Obd2UuidRematchResult.noCandidate);
    });

    test('MAC-shaped pinned id (Android) → notEligible even on a name match '
        '— MACs are stable, a same-named other-MAC device is a DIFFERENT '
        'adapter', () {
      final decision = Obd2UuidRematchDecision.decide(
        pinnedId: androidMac,
        pinnedName: 'OBDLink CX',
        ranked: [candidate('11:22:33:44:55:66', 'OBDLink CX')],
      );
      expect(decision.result, Obd2UuidRematchResult.notEligible);
    });

    test('no persisted name → notEligible (nothing to rematch by)', () {
      for (final name in [null, '', '  ']) {
        final decision = Obd2UuidRematchDecision.decide(
          pinnedId: iosUuid,
          pinnedName: name,
          ranked: [candidate(iosUuidRotated, 'OBDLink CX')],
        );
        expect(decision.result, Obd2UuidRematchResult.notEligible,
            reason: 'pinnedName=${name == null ? 'null' : '"$name"'}');
      }
    });
  });

  group('repersistRotatedAdapterIdentity (#3168)', () {
    const fresh = Obd2AdapterIdentity(
      deviceId: iosUuidRotated,
      name: 'OBDLink CX',
      uuidIos: iosUuidRotated,
    );

    test('rotates the identity fields on every pinned profile and keeps the '
        'user-facing name + other preferences intact', () async {
      const pinned = VehicleProfile(
        id: 'v1',
        name: 'My BMW',
        obd2AdapterMac: iosUuid,
        obd2AdapterName: 'OBDLink CX',
        pairedAdapterUuidIos: iosUuid,
        tankCapacityL: 52,
      );
      const other = VehicleProfile(
        id: 'v2',
        name: 'Other car',
        obd2AdapterMac: androidMac,
        obd2AdapterName: 'vLinker FD',
      );
      final saved = <VehicleProfile>[];
      await repersistRotatedAdapterIdentity(
        profiles: const [pinned, other],
        save: (p) async => saved.add(p),
        staleId: iosUuid,
        fresh: fresh,
      );
      expect(saved, hasLength(1), reason: 'only the pinned profile rotates');
      expect(saved.single.id, 'v1');
      expect(saved.single.obd2AdapterMac, iosUuidRotated);
      expect(saved.single.pairedAdapterUuidIos, iosUuidRotated);
      expect(saved.single.obd2AdapterName, 'OBDLink CX',
          reason: 'the user-facing adapter name must stay intact');
      expect(saved.single.tankCapacityL, 52,
          reason: 'unrelated preferences must stay intact');
    });

    test('matches a legacy profile pinned only via pairedAdapterUuidIos '
        '(pre-#3168 persisted state)', () async {
      const legacy = VehicleProfile(
        id: 'v1',
        name: 'My BMW',
        obd2AdapterMac: 'something-else',
        obd2AdapterName: 'OBDLink CX',
        pairedAdapterUuidIos: iosUuid,
      );
      final saved = <VehicleProfile>[];
      await repersistRotatedAdapterIdentity(
        profiles: const [legacy],
        save: (p) async => saved.add(p),
        staleId: iosUuid.toLowerCase(), // case-insensitive match
        fresh: fresh,
      );
      expect(saved, hasLength(1));
      expect(saved.single.obd2AdapterMac, iosUuidRotated);
      expect(saved.single.pairedAdapterUuidIos, iosUuidRotated);
    });

    test('no pinned profile → no writes', () async {
      const unrelated = VehicleProfile(id: 'v1', name: 'Car');
      var saves = 0;
      await repersistRotatedAdapterIdentity(
        profiles: const [unrelated],
        save: (_) async => saves++,
        staleId: iosUuid,
        fresh: fresh,
      );
      expect(saves, 0);
    });

    test('FAULT INJECTION — a throwing save is swallowed (never throws), '
        'the connect that triggered the rotation is never derailed',
        () async {
      const pinned = VehicleProfile(
        id: 'v1',
        name: 'My BMW',
        obd2AdapterMac: iosUuid,
        obd2AdapterName: 'OBDLink CX',
      );
      await expectLater(
        repersistRotatedAdapterIdentity(
          profiles: const [pinned],
          save: (_) async => throw StateError('hive write failed'),
          staleId: iosUuid,
          fresh: fresh,
        ),
        completes,
      );
    });
  });
}
