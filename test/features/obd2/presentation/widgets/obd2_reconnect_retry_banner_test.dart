// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_reconnect_retry_banner.dart';
import 'package:tankstellen/features/obd2/providers/obd2_connection_state_provider.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Fake reconnect notifier: returns a fixed state without touching the
/// connection graph, and counts retry() taps. Lets the widget test drive
/// the REAL banner against each state.
class _FakeObd2Reconnect extends Obd2Reconnect {
  _FakeObd2Reconnect(this._initial);
  final Obd2ReconnectState _initial;
  int retryCalls = 0;

  @override
  Obd2ReconnectState build() => _initial;

  @override
  void retry() {
    retryCalls++;
  }
}

class _Host extends StatelessWidget {
  const _Host();
  @override
  Widget build(BuildContext context) =>
      const Column(children: [Obd2ReconnectRetryBanner()]);
}

void main() {
  group('Obd2ReconnectRetryBanner (#3019 / Epic #3013 phase 3)', () {
    testWidgets('zero-height when connected', (tester) async {
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.connected)),
        ],
      );
      expect(find.byKey(const Key('obd2ReconnectingBanner')), findsNothing);
      expect(find.byKey(const Key('obd2ReconnectFailedBanner')), findsNothing);
    });

    testWidgets('shows the reconnecting banner while reconnecting',
        (tester) async {
      // settle:false — the reconnecting banner carries an indefinite
      // CircularProgressIndicator that pumpAndSettle would wait on forever.
      await pumpApp(
        tester,
        const _Host(),
        settle: false,
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.reconnecting)),
        ],
      );
      expect(find.byKey(const Key('obd2ReconnectingBanner')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the terminal tap-to-retry banner when failed',
        (tester) async {
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.terminalFailed)),
        ],
      );
      expect(find.byKey(const Key('obd2ReconnectFailedBanner')), findsOneWidget);
      expect(
          find.byKey(const Key('obd2ReconnectRetryButton')), findsOneWidget);
    });

    testWidgets(
        '#3035 — shows the engine-off banner (turn the ignition on) when '
        'terminalEngineOff, with its own retry button', (tester) async {
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.terminalEngineOff)),
        ],
      );
      expect(find.byKey(const Key('obd2ReconnectEngineOffBanner')),
          findsOneWidget);
      expect(find.byKey(const Key('obd2ReconnectEngineOffRetryButton')),
          findsOneWidget);
      // NOT the generic hardware-failure banner.
      expect(find.byKey(const Key('obd2ReconnectFailedBanner')), findsNothing);
    });

    testWidgets('#3035 — tapping the engine-off retry calls notifier.retry()',
        (tester) async {
      final fake = _FakeObd2Reconnect(Obd2ReconnectState.terminalEngineOff);
      await pumpApp(
        tester,
        const _Host(),
        overrides: [obd2ReconnectProvider.overrideWith(() => fake)],
      );
      await tester
          .tap(find.byKey(const Key('obd2ReconnectEngineOffRetryButton')));
      await tester.pumpAndSettle();
      expect(fake.retryCalls, 1);
    });

    testWidgets('tapping retry calls notifier.retry()', (tester) async {
      final fake = _FakeObd2Reconnect(Obd2ReconnectState.terminalFailed);
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          obd2ReconnectProvider.overrideWith(() => fake),
        ],
      );
      expect(fake.retryCalls, 0);
      await tester.tap(find.byKey(const Key('obd2ReconnectRetryButton')));
      await tester.pumpAndSettle();
      expect(fake.retryCalls, 1);
    });

    testWidgets('names the adapter while reconnecting when known',
        (tester) async {
      await pumpApp(
        tester,
        const _Host(),
        settle: false, // indefinite spinner in the reconnecting banner
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.reconnecting)),
          obd2ConnectionStatusProvider.overrideWith(_StubStatus.new),
        ],
      );
      // The named variant interpolates the adapter name.
      expect(find.textContaining('vLinker FS'), findsOneWidget);
    });
  });
}

/// Stub app-wide status carrying a friendly adapter name for the named
/// reconnecting-banner copy.
class _StubStatus extends Obd2ConnectionStatus {
  @override
  Obd2ConnectionSnapshot build() => const Obd2ConnectionSnapshot(
        state: Obd2ConnectionState.connected,
        adapterName: 'vLinker FS',
      );
}
