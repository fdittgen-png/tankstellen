import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/report/domain/entities/report_type.dart';
import 'package:tankstellen/features/report/presentation/screens/report_backend_availability.dart';

import '../../../../helpers/mock_providers.dart';

/// Unit tests for `ReportBackendAvailability` (#561 coverage).
///
/// Covers:
///  - the constructor + the three pure getters (`hasAnyBackend`,
///    `allVisibleRouteToGitHub`, `selectedIsGitHubRouted`).
///  - the `static watch(WidgetRef)` factory across DE / non-DE country
///    and apiKey-set / unset configurations.
///
/// Note on `canSubmitTankSync`: `TankSyncClient.isConnected` is a static
/// getter that reads the global Supabase client state. Without an
/// initialised Supabase instance (the test environment) it returns
/// `false`, so every test below documents `canSubmitTankSync == false`.
/// That's the same shape the screen sees in unit-test contexts and is
/// the surface we want to lock in here.

/// Captures a `WidgetRef` so the tests can call
/// `ReportBackendAvailability.watch(ref)` against an overridden
/// `ProviderContainer`. Same harness pattern as
/// `test/features/vehicle/presentation/widgets/vehicle_save_actions_test.dart`.
class _RefHost extends ConsumerWidget {
  const _RefHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _capturedRef = ref;
    return const SizedBox.shrink();
  }
}

WidgetRef? _capturedRef;

Future<WidgetRef> _pumpAndCaptureRef(
  WidgetTester tester, {
  required List<Object> overrides,
}) async {
  _capturedRef = null;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: const MaterialApp(home: _RefHost()),
    ),
  );
  final ref = _capturedRef;
  if (ref == null) {
    throw StateError('WidgetRef was not captured during pumpWidget.');
  }
  return ref;
}

void main() {
  group('ReportBackendAvailability constructor + pure getters', () {
    test('stores the constructor arguments verbatim', () {
      const visible = [ReportType.wrongE5, ReportType.wrongName];
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: true,
        canSubmitTankSync: false,
        visibleTypes: visible,
      );
      expect(a.canSubmitTankerkoenig, isTrue);
      expect(a.canSubmitTankSync, isFalse);
      expect(a.visibleTypes, same(visible));
    });

    test('hasAnyBackend → false when neither backend is available', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: false,
        canSubmitTankSync: false,
        visibleTypes: const [],
      );
      expect(a.hasAnyBackend, isFalse);
    });

    test('hasAnyBackend → true when only Tankerkoenig is available', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: true,
        canSubmitTankSync: false,
        visibleTypes: const [],
      );
      expect(a.hasAnyBackend, isTrue);
    });

    test('hasAnyBackend → true when only TankSync is available', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: false,
        canSubmitTankSync: true,
        visibleTypes: const [],
      );
      expect(a.hasAnyBackend, isTrue);
    });

    test('hasAnyBackend → true when both backends are available', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: true,
        canSubmitTankSync: true,
        visibleTypes: const [],
      );
      expect(a.hasAnyBackend, isTrue);
    });

    test('allVisibleRouteToGitHub → true vacuously for an empty list', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: false,
        canSubmitTankSync: false,
        visibleTypes: const [],
      );
      expect(a.allVisibleRouteToGitHub, isTrue);
    });

    test(
        'allVisibleRouteToGitHub → true when every visible type routes to '
        'GitHub (FR/non-DE shape)', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: false,
        canSubmitTankSync: false,
        visibleTypes: const [ReportType.wrongName, ReportType.wrongAddress],
      );
      expect(a.allVisibleRouteToGitHub, isTrue);
    });

    test(
        'allVisibleRouteToGitHub → false when any visible type is not '
        'GitHub-routed (DE shape — full list)', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: true,
        canSubmitTankSync: false,
        visibleTypes: ReportType.values,
      );
      expect(a.allVisibleRouteToGitHub, isFalse);
    });

    test('selectedIsGitHubRouted → false for null selection', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: false,
        canSubmitTankSync: false,
        visibleTypes: const [],
      );
      expect(a.selectedIsGitHubRouted(null), isFalse);
    });

    test('selectedIsGitHubRouted → true for wrongName / wrongAddress', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: false,
        canSubmitTankSync: false,
        visibleTypes: const [],
      );
      expect(a.selectedIsGitHubRouted(ReportType.wrongName), isTrue);
      expect(a.selectedIsGitHubRouted(ReportType.wrongAddress), isTrue);
    });

    test(
        'selectedIsGitHubRouted → false for every backend-routed type '
        '(price + status)', () {
      final a = ReportBackendAvailability(
        canSubmitTankerkoenig: false,
        canSubmitTankSync: false,
        visibleTypes: const [],
      );
      const backendRouted = <ReportType>[
        ReportType.wrongE5,
        ReportType.wrongE10,
        ReportType.wrongDiesel,
        ReportType.wrongE85,
        ReportType.wrongE98,
        ReportType.wrongLpg,
        ReportType.wrongStatusOpen,
        ReportType.wrongStatusClosed,
      ];
      for (final t in backendRouted) {
        expect(
          a.selectedIsGitHubRouted(t),
          isFalse,
          reason: '$t is not GitHub-routed and must report false',
        );
      }
    });
  });

  group('ReportBackendAvailability.watch', () {
    testWidgets('DE + Tankerkoenig key set → canSubmitTankerkoenig = true',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(true);
      when(() => test.mockStorage.getApiKey())
          .thenReturn('11111111-2222-3333-4444-555555555555');

      final ref = await _pumpAndCaptureRef(tester, overrides: test.overrides);
      final a = ReportBackendAvailability.watch(ref);

      expect(a.canSubmitTankerkoenig, isTrue);
      // No initialised Supabase in tests → TankSync side stays false.
      expect(a.canSubmitTankSync, isFalse);
      // DE → all 10 visible.
      expect(a.visibleTypes, equals(ReportType.values));
      // Sanity: hasAnyBackend lights up via Tankerkoenig alone.
      expect(a.hasAnyBackend, isTrue);
    });

    testWidgets('DE + no Tankerkoenig key → canSubmitTankerkoenig = false',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      final ref = await _pumpAndCaptureRef(tester, overrides: test.overrides);
      final a = ReportBackendAvailability.watch(ref);

      expect(a.canSubmitTankerkoenig, isFalse);
      expect(a.canSubmitTankSync, isFalse);
      expect(a.visibleTypes, equals(ReportType.values));
      // Neither backend → no-backend banner condition.
      expect(a.hasAnyBackend, isFalse);
      // …but DE includes price/status types, so the radio row is not
      // entirely GitHub-routed — `allVisibleRouteToGitHub` is false.
      expect(a.allVisibleRouteToGitHub, isFalse);
    });

    testWidgets(
        'DE + empty-string Tankerkoenig key → canSubmitTankerkoenig = false',
        (tester) async {
      // The factory specifically guards on `apiKey.isNotEmpty`; an empty
      // string must be treated the same as null.
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(true);
      when(() => test.mockStorage.getApiKey()).thenReturn('');

      final ref = await _pumpAndCaptureRef(tester, overrides: test.overrides);
      final a = ReportBackendAvailability.watch(ref);

      expect(a.canSubmitTankerkoenig, isFalse,
          reason: 'empty string must not enable the Tankerkoenig backend');
    });

    testWidgets(
        'FR + Tankerkoenig key set → canSubmitTankerkoenig still false '
        '(country-gated)',
        (tester) async {
      final test = standardTestOverrides(country: Countries.france);
      // Even if a key is present, FR is not the Tankerkoenig country.
      when(() => test.mockStorage.hasApiKey()).thenReturn(true);
      when(() => test.mockStorage.getApiKey())
          .thenReturn('11111111-2222-3333-4444-555555555555');

      final ref = await _pumpAndCaptureRef(tester, overrides: test.overrides);
      final a = ReportBackendAvailability.watch(ref);

      expect(a.canSubmitTankerkoenig, isFalse);
      expect(a.canSubmitTankSync, isFalse);
      // FR → only the 2 GitHub-routed types are visible.
      expect(
        a.visibleTypes,
        equals(const [ReportType.wrongName, ReportType.wrongAddress]),
      );
      // All visible types are GitHub-routed → no-backend banner is
      // suppressed by the screen because `allVisibleRouteToGitHub` is
      // true even though `hasAnyBackend` is false.
      expect(a.allVisibleRouteToGitHub, isTrue);
      expect(a.hasAnyBackend, isFalse);
    });

    testWidgets(
        'DE — visibleTypes mirrors ReportType.visibleForCountry("DE")',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      final ref = await _pumpAndCaptureRef(tester, overrides: test.overrides);
      final a = ReportBackendAvailability.watch(ref);

      expect(
        a.visibleTypes,
        equals(ReportType.visibleForCountry('DE')),
      );
    });

    testWidgets(
        'GB — visibleTypes mirrors ReportType.visibleForCountry("GB")',
        (tester) async {
      final test = standardTestOverrides(country: Countries.unitedKingdom);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      final ref = await _pumpAndCaptureRef(tester, overrides: test.overrides);
      final a = ReportBackendAvailability.watch(ref);

      expect(
        a.visibleTypes,
        equals(ReportType.visibleForCountry('GB')),
      );
    });
  });
}
