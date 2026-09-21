// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/tanksync_session_gate.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #4162 — the one owner of TankSync's session lifecycle view.
void main() {
  silenceErrorLoggerSpool();

  late FakeHiveStorage storage;
  late TankSyncSessionGate gate;
  late List<SessionObservation> seen;

  setUp(() async {
    BreadcrumbCollector.clear();
    storage = FakeHiveStorage();
    gate = TankSyncSessionGate();
    seen = [];
    gate.debugTap = seen.add;
  });
  tearDown(() {
    BreadcrumbCollector.onAdd = null;
    gate.resetForTest();
  });

  Future<void> configure({bool consent = true}) async {
    await storage.putSetting('sync_enabled', true);
    await storage.putSetting('supabase_url', 'https://a.supabase.co');
    await storage.setSupabaseAnonKey('key');
    await storage.putSetting(StorageKeys.consentCloudSync, consent);
  }

  test('records nothing before it is bound', () {
    gate.observe('early');
    expect(seen, isEmpty);
    expect(gate.phase, isNull);
  });

  test('a documented transition is observed, not recorded as a violation',
      () async {
    gate.bind(storage);
    expect(gate.phase, TankSyncSessionPhase.off);
    await configure();
    gate.observe('settings');
    gate.initRunning(true, 'init.start');
    expect(seen.map((o) => o.phase), [
      TankSyncSessionPhase.off,
      TankSyncSessionPhase.configured,
      TankSyncSessionPhase.initializing,
    ]);
    expect(gate.debugViolations, isEmpty,
        reason: 'off → configured → initializing are documented');
    expect(BreadcrumbCollector.snapshot(), isEmpty);
  });

  test('observe mode: an illegal edge is recorded with its cause and '
      'breadcrumbed, and the phase still advances', () async {
    await configure();
    gate.initRunning(true, 'launch');
    gate.bind(storage); // initializing
    gate.initRunning(false, 'init.done'); // → configured (documented)
    await storage.putSetting('sync_enabled', false);
    gate.observe('disconnect'); // → off (documented)
    await storage.putSetting('sync_enabled', true);
    gate.initRunning(true, 'retry'); // off → initializing: not documented
    expect(gate.debugViolations.single.edge,
        (TankSyncSessionPhase.off, TankSyncSessionPhase.initializing));
    expect(gate.debugViolations.single.cause, 'retry');
    expect(gate.phase, TankSyncSessionPhase.initializing);
    final crumb = BreadcrumbCollector.snapshot().last;
    expect(crumb.action, 'sync session: illegal off→initializing');
    expect(crumb.detail, 'retry');
  });

  test('a snapshot that breaks an invariant is recorded as the invariant, '
      'and no edge is measured from it', () async {
    await configure(consent: false);
    gate.bind(storage); // consentWithdrawn
    gate.observeConfig(const SyncConfig(enabled: true)); // S2 shape
    expect(gate.debugViolations.single.invariant,
        SessionInvariant.noCloudWithoutConsent);
    expect(gate.debugViolations.single.edge, isNull);
    expect(seen.last.broken, {SessionInvariant.noCloudWithoutConsent});
    expect(gate.phase, TankSyncSessionPhase.consentWithdrawn,
        reason: 'the last LAWFUL phase is kept');
    expect(BreadcrumbCollector.snapshot().last.action,
        'sync session: broke noCloudWithoutConsent');
  });

  test('the violation ring is bounded, newest kept', () async {
    await configure(consent: false);
    gate.bind(storage);
    for (var i = 0; i < TankSyncSessionGate.maxViolations + 5; i++) {
      gate.observeConfig(const SyncConfig(enabled: true));
    }
    expect(gate.debugViolations, hasLength(TankSyncSessionGate.maxViolations));
  });

  group('watchAuth — read-only', () {
    test('records an SDK sign-out with its reason, ignores a user-initiated '
        'one, and survives stream errors', () async {
      await configure();
      gate.bind(storage);
      final events = StreamController<AuthState>();
      gate.watchAuth(events.stream);
      events
        ..add(const AuthState(AuthChangeEvent.signedOut, null,
            signOutReason: SignOutReason.userInitiated))
        ..addError(Exception('offline refresh'))
        ..add(const AuthState(AuthChangeEvent.signedOut, null,
            signOutReason: SignOutReason.sessionExpired));
      await pumpEventQueue();
      expect(seen.map((o) => o.cause), [
        'bind',
        'auth:signedOut(sessionExpired)',
      ]);
      await events.close();
    });

    test('a second watch replaces the first subscription', () async {
      await configure();
      gate.bind(storage);
      final first = StreamController<AuthState>.broadcast();
      final second = StreamController<AuthState>.broadcast();
      gate.watchAuth(first.stream);
      gate.watchAuth(second.stream);
      await pumpEventQueue();
      expect(first.hasListener, isFalse);
      expect(second.hasListener, isTrue);
      await first.close();
      await second.close();
    });
  });

  group('never throws', () {
    test('not when the breadcrumb sink throws', () async {
      BreadcrumbCollector.onAdd = () => throw StateError('persistence down');
      await configure(consent: false);
      gate.bind(storage);
      expect(() => gate.observeConfig(const SyncConfig(enabled: true)),
          returnsNormally);
      expect(gate.debugViolations, hasLength(1),
          reason: 'the ring holds the violation even when the crumb fails');
    });

    test('not when reading the facts throws', () {
      gate.bind(_ThrowingStorage());
      expect(() => gate.observe('broken storage'), returnsNormally);
      expect(seen, isEmpty);
    });

    test('not when the auth stream cannot be listened to', () async {
      final events = StreamController<AuthState>();
      events.stream.listen((_) {});
      expect(() => gate.watchAuth(events.stream), returnsNormally);
      await events.close();
    });
  });
}

class _ThrowingStorage extends FakeHiveStorage {
  @override
  dynamic getSetting(String key) => throw StateError('box closed');
}
