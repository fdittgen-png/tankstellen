// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/companion_auto_record_coordinator.dart';
import 'package:tankstellen/features/obd2/data/companion_device_association.dart';

/// #3320 — the FGS-gated, one-time Companion-Device-Manager association
/// decision for hands-free auto-record.
class _FakeAssociation implements CompanionDeviceAssociation {
  bool supported = true;
  bool associated = false;
  int associateCalls = 0;
  String? associatedMac;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> isAssociated() async => associated;

  @override
  Future<bool> associate(String mac) async {
    associateCalls++;
    associatedMac = mac;
    associated = true;
    return true;
  }

  @override
  Future<bool> disassociate() async {
    associated = false;
    return true;
  }
}

void main() {
  late _FakeAssociation fake;

  CompanionAutoRecordCoordinator build({required bool fgsEnabled}) =>
      CompanionAutoRecordCoordinator(association: fake, fgsEnabled: fgsEnabled);

  setUp(() => fake = _FakeAssociation());

  test('FGS disabled (default build) → never touches the platform', () async {
    final ok = await build(fgsEnabled: false).ensureAssociated('AA:BB:CC:DD:EE:FF');
    expect(ok, isFalse);
    expect(fake.associateCalls, 0);
  });

  test('unsupported (iOS / pre-34) → false, no associate', () async {
    fake.supported = false;
    final ok = await build(fgsEnabled: true).ensureAssociated('AA:BB:CC:DD:EE:FF');
    expect(ok, isFalse);
    expect(fake.associateCalls, 0);
  });

  test('already associated → true without re-prompting', () async {
    fake.associated = true;
    final ok = await build(fgsEnabled: true).ensureAssociated('AA:BB:CC:DD:EE:FF');
    expect(ok, isTrue);
    expect(fake.associateCalls, 0);
  });

  test('supported + not associated → associates the given MAC', () async {
    final ok = await build(fgsEnabled: true).ensureAssociated('AA:BB:CC:DD:EE:FF');
    expect(ok, isTrue);
    expect(fake.associateCalls, 1);
    expect(fake.associatedMac, 'AA:BB:CC:DD:EE:FF');
  });

  test('#3437 — a declined dialog is not re-prompted for the same MAC this '
      'session (once per association need)', () async {
    final declining = _DecliningAssociation();
    final coordinator = CompanionAutoRecordCoordinator(
        association: declining, fgsEnabled: true);

    expect(await coordinator.ensureAssociated('AA:BB:CC:DD:EE:FF'), isFalse);
    expect(await coordinator.ensureAssociated('AA:BB:CC:DD:EE:FF'), isFalse);
    expect(declining.associateCalls, 1,
        reason: 'the system dialog fires at most once per MAC per session — '
            'a declined user must not be re-nagged on every trip start');

    // A different dongle is a NEW association need → one fresh attempt.
    expect(await coordinator.ensureAssociated('11:22:33:44:55:66'), isFalse);
    expect(declining.associateCalls, 2);
  });

  test('#3437 — an existing association keeps short-circuiting true and '
      'never consumes the per-session attempt', () async {
    fake.associated = true;
    final coordinator = build(fgsEnabled: true);
    expect(await coordinator.ensureAssociated('AA:BB:CC:DD:EE:FF'), isTrue);
    expect(await coordinator.ensureAssociated('AA:BB:CC:DD:EE:FF'), isTrue);
    expect(fake.associateCalls, 0);
  });

  test('a throwing platform call is swallowed — never throws into the start '
      'path, resolves false (#2349)', () async {
    final coordinator = CompanionAutoRecordCoordinator(
      association: _ThrowingAssociation(),
      fgsEnabled: true,
    );
    // Fault injected (isSupported throws): the call must complete normally...
    await expectLater(
        coordinator.ensureAssociated('AA:BB:CC:DD:EE:FF'), completes);
    // ...and resolve false rather than propagating.
    expect(await coordinator.ensureAssociated('AA:BB:CC:DD:EE:FF'), isFalse);
  });
}

/// #3437 — supported + never associated + the user declines every dialog:
/// the worst case for re-nagging.
class _DecliningAssociation implements CompanionDeviceAssociation {
  int associateCalls = 0;
  @override
  Future<bool> isSupported() async => true;
  @override
  Future<bool> isAssociated() async => false;
  @override
  Future<bool> associate(String mac) async {
    associateCalls++;
    return false; // user tapped "don't allow"
  }

  @override
  Future<bool> disassociate() async => false;
}

class _ThrowingAssociation implements CompanionDeviceAssociation {
  @override
  Future<bool> isSupported() async => throw Exception('channel blew up');
  @override
  Future<bool> isAssociated() async => false;
  @override
  Future<bool> associate(String mac) async => false;
  @override
  Future<bool> disassociate() async => false;
}
