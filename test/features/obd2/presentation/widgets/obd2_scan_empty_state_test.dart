// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_scan_readiness.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_scan_empty_state.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Future<void> pumpEmptyState(
  WidgetTester tester,
  Obd2ScanReadiness state, {
  VoidCallback? onRetry,
}) async {
  // A unique key per state forces a fresh ProviderScope element. Without
  // it, re-pumping inside a loop reuses the mounted scope and the widget
  // reads the PREVIOUS state's resolved value while the new override is
  // still loading — which silently made the loop assertions vacuous.
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(state),
      overrides: [
        obd2ScanReadinessProvider.overrideWith((ref) async => state),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Obd2ScanEmptyState(onRetry: onRetry ?? () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Resolve the expected message straight from the delegates so the test
/// asserts the WIRING, not a copy of the English string — a literal
/// would have to be edited every time the copy is reworded.
Future<String> messageFor(
  WidgetTester tester,
  String Function(AppLocalizations) pick,
) async {
  final l = await AppLocalizations.delegate.load(const Locale('en'));
  return pick(l);
}

void main() {
  group('Obd2ScanEmptyState — each cause gets its own instruction', () {
    testWidgets('ready → "check the adapter", no settings button',
        (tester) async {
      await pumpEmptyState(tester, Obd2ScanReadiness.ready);

      expect(
        find.text(await messageFor(tester, (l) => l.obd2ScanEmptyReady)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('obdPickerEmptyOpenSettings')), findsNothing);
      expect(find.byKey(const Key('obdPickerEmptyRetry')), findsOneWidget);
    });

    testWidgets('bluetoothOff → turn-it-on message + settings button',
        (tester) async {
      await pumpEmptyState(tester, Obd2ScanReadiness.bluetoothOff);

      expect(
        find.text(
          await messageFor(tester, (l) => l.obd2ScanBlockedBluetoothOff),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('obdPickerEmptyOpenSettings')),
        findsOneWidget,
      );
    });

    testWidgets(
      'THE SILENT ONE: locationServicesOff names the real blocker and '
      'reassures about privacy',
      (tester) async {
        await pumpEmptyState(tester, Obd2ScanReadiness.locationServicesOff);

        final msg = await messageFor(
          tester,
          (l) => l.obd2ScanBlockedLocationServices,
        );
        expect(find.text(msg), findsOneWidget);
        // The reassurance matters: the requirement is an OS constraint,
        // not a data-collection choice, and users read it as the latter.
        expect(msg.toLowerCase(), contains('no location is recorded'));
        expect(
          find.byKey(const Key('obdPickerEmptyOpenSettings')),
          findsOneWidget,
        );
      },
    );

    testWidgets('unsupported → no settings button (nothing would help)',
        (tester) async {
      await pumpEmptyState(tester, Obd2ScanReadiness.unsupported);

      expect(
        find.text(
          await messageFor(tester, (l) => l.obd2ScanBlockedUnsupported),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('obdPickerEmptyOpenSettings')), findsNothing);
    });

    testWidgets(
      'permissionDenied offers retry only — re-prompting IS the retry path',
      (tester) async {
        await pumpEmptyState(tester, Obd2ScanReadiness.permissionDenied);

        expect(
          find.text(
            await messageFor(tester, (l) => l.obd2ScanBlockedPermission),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('obdPickerEmptyOpenSettings')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'permissionPermanentlyDenied offers settings — retry alone can never '
      'reach a granted state',
      (tester) async {
        await pumpEmptyState(
          tester,
          Obd2ScanReadiness.permissionPermanentlyDenied,
        );

        expect(
          find.text(
            await messageFor(
              tester,
              (l) => l.obd2ScanBlockedPermissionSettings,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('obdPickerEmptyOpenSettings')),
          findsOneWidget,
        );
      },
    );

    testWidgets('every readiness state renders a distinct reason', (tester) async {
      final seen = <String>{};
      for (final state in Obd2ScanReadiness.values) {
        await pumpEmptyState(tester, state);
        final text = tester
            .widget<Text>(find.byKey(const Key('obdPickerEmptyReason')))
            .data!;
        expect(text, isNotEmpty, reason: '$state has no message');
        expect(seen.add(text), isTrue,
            reason: '$state reuses another state\'s message: "$text"');
      }
      expect(seen, hasLength(Obd2ScanReadiness.values.length));
    });
  });

  group('affordances', () {
    testWidgets('the retry button actually calls back', (tester) async {
      var retried = 0;
      await pumpEmptyState(
        tester,
        Obd2ScanReadiness.bluetoothOff,
        onRetry: () => retried++,
      );

      await tester.tap(find.byKey(const Key('obdPickerEmptyRetry')));
      await tester.pump();

      expect(retried, 1);
    });

    testWidgets('retry stays available even when a blocker is present',
        (tester) async {
      // The user may clear the blocker from the notification shade while
      // this sheet is open, so retry must never be hidden or disabled.
      for (final state in Obd2ScanReadiness.values) {
        await pumpEmptyState(tester, state);
        final button = tester.widget<FilledButton>(
          find.byKey(const Key('obdPickerEmptyRetry')),
        );
        expect(button.onPressed, isNotNull, reason: '$state disabled retry');
      }
    });

    testWidgets('meets tap-target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpEmptyState(tester, Obd2ScanReadiness.locationServicesOff);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });
  });
}
