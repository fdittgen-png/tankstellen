// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_reconnect_retry_banner.dart';
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
  group('Obd2ReconnectRetryBanner (#3019, reworked #3505)', () {
    testWidgets('zero-height when connected', (tester) async {
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.connected)),
        ],
      );
      expect(find.byKey(const Key('obd2ReconnectFailedBanner')), findsNothing);
    });

    testWidgets(
        '#3505 — RECONNECTING paints NO app-wide strip (the pulsing status '
        'dot is the ambient surface now)', (tester) async {
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.reconnecting)),
        ],
      );
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'background housekeeping must not colonise every screen '
              'with an urgent spinner strip (#3505)');
      expect(find.byKey(const Key('obd2ReconnectFailedBanner')), findsNothing);
    });

    testWidgets(
        '#3505 — terminal ENGINE-OFF (parked car, the expected idle state) '
        'paints no app-wide banner either', (tester) async {
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          obd2ReconnectProvider.overrideWith(
              () => _FakeObd2Reconnect(Obd2ReconnectState.terminalEngineOff)),
        ],
      );
      expect(find.byKey(const Key('obd2ReconnectFailedBanner')), findsNothing);
      expect(find.byType(Container), findsNothing);
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

    testWidgets(
        '#3505 — the X dismisses the failed strip for the current episode',
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
      await tester.tap(find.byKey(const Key('obd2ReconnectDismissButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('obd2ReconnectFailedBanner')), findsNothing,
          reason: 'dismissed for this episode — a fresh drop re-arms it');
    });
  });
}
