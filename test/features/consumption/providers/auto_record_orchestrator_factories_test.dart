// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/android_background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/ios_background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/ios_restoration_event.dart';
import 'package:tankstellen/features/obd2/data/ios_state_restoration_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/consumption/providers/auto_record_orchestrator_factories.dart';

/// #3167 — tests for the auto-record factory seams: per-platform
/// listener selection (the iOS branch is new) and the
/// `stateRestoration` connect-trace origin wrapper.
class _FakeRestorationService implements IosStateRestorationService {
  _FakeRestorationService({this.tagged = false});

  /// Whether this launch should report the one-shot restoration tag.
  bool tagged;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerPersistedAdapter(String peripheralUuid) async {}

  @override
  Stream<IosRestorationEvent> get events => const Stream.empty();

  @override
  IosRestorationWillRestore? get launchRestoration =>
      tagged ? const IosRestorationWillRestore(<String>[]) : null;

  @override
  bool consumeLaunchRestorationTag() {
    if (!tagged) return false;
    tagged = false;
    return true;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('autoRecordListenerFactory platform selection', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    BackgroundAdapterListener buildFor(TargetPlatform platform) {
      debugDefaultTargetPlatformOverride = platform;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container.read(autoRecordListenerFactoryProvider)();
    }

    test('Android gets the foreground-service bridge', () {
      expect(
        buildFor(TargetPlatform.android),
        isA<AndroidBackgroundAdapterListener>(),
      );
    });

    test('iOS gets the Core Bluetooth state-restoration listener (#3167)',
        () {
      expect(
        buildFor(TargetPlatform.iOS),
        isA<IosBackgroundAdapterListener>(),
      );
    });

    test('other platforms keep the loud unimplemented stub', () {
      expect(
        buildFor(TargetPlatform.linux),
        isA<UnimplementedBackgroundAdapterListener>(),
      );
    });
  });

  group('wrapStateRestorationOrigin (#3167)', () {
    setUp(Obd2ConnectTraceLog.clear);
    tearDown(Obd2ConnectTraceLog.clear);

    /// Inner opener standing in for `connectByMac`: opens + ends a trace
    /// the way the connection service does, so the test observes which
    /// origin the trace was stamped with.
    Future<Obd2Service?> tracingInner(String mac) async {
      final trace = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: mac,
      );
      Obd2ConnectTraceLog.endTrace(trace);
      return null;
    }

    test(
        'restoration launch: the FIRST session open is stamped '
        'stateRestoration, the second falls back to the default origin',
        () async {
      final opener = wrapStateRestorationOrigin(
        inner: tracingInner,
        restoration: _FakeRestorationService(tagged: true),
      );

      await opener('AA');
      await opener('BB');

      final traces = Obd2ConnectTraceLog.snapshot();
      expect(traces, hasLength(2));
      // snapshot() is newest-first.
      expect(traces[1].origin, Obd2ConnectOrigin.stateRestoration,
          reason: 'the connect triggered by the Core Bluetooth relaunch '
              'must be distinguishable in a field export');
      expect(traces[0].origin, Obd2ConnectOrigin.firstConnect,
          reason: 'the tag is one-shot — later connects keep the '
              'service default');
    });

    test('normal launch: the wrapper is a transparent pass-through',
        () async {
      final opener = wrapStateRestorationOrigin(
        inner: tracingInner,
        restoration: _FakeRestorationService(),
      );

      await opener('AA');

      final traces = Obd2ConnectTraceLog.snapshot();
      expect(traces, hasLength(1));
      expect(traces.single.origin, Obd2ConnectOrigin.firstConnect);
    });
  });
}
