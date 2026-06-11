// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_device_identity.dart';

/// #3125 — never-throws fault path for [SyncDeviceIdentity] (#2349
/// ratchet: a documented never-throws boundary needs a fault-injection
/// sibling test).
///
/// In this suite Hive is never initialised, so the settings box is
/// unavailable — exactly the storage-fault path the docstring promises
/// to absorb: `deviceId` must return normally with a session-stable id
/// instead of throwing.
void main() {
  setUp(SyncDeviceIdentity.resetForTest);
  tearDown(SyncDeviceIdentity.resetForTest);

  test('deviceId returns normally when the settings box is unavailable', () {
    String? id;
    expect(() => id = SyncDeviceIdentity.deviceId, returnsNormally);
    expect(id, isNotEmpty);
  });

  test('deviceId is session-stable across reads without storage', () {
    final first = SyncDeviceIdentity.deviceId;
    expect(SyncDeviceIdentity.deviceId, first,
        reason: 'within one session the forensic stamps must agree even '
            'when the id could not be persisted');
  });

  test('resetForTest pins a deterministic id for other suites', () {
    SyncDeviceIdentity.resetForTest('pinned-id');
    expect(SyncDeviceIdentity.deviceId, 'pinned-id');
  });

  test('appVersion is non-empty', () {
    expect(SyncDeviceIdentity.appVersion, isNotEmpty);
  });
}
