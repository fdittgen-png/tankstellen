// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_create_sheet.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_form_support.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';
import 'package:tankstellen/features/alerts/providers/zone_alert_price_sample_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// #3905 — zone-alert sheet intuitiveness: locale decimals, price-based
/// default threshold, chosen-location chip, disabled-Save reason.
void main() {
  const chip = Key('radius_alert_center_chip');
  const blocker = Key('radius_alert_save_blocker');

  Station station({
    required String id,
    double? diesel,
    double? e10,
  }) =>
      Station(
        id: id,
        name: id,
        brand: 'Total',
        street: 'Rue',
        postCode: '34550',
        place: 'Bessan',
        lat: 43.36,
        lng: 3.42,
        diesel: diesel,
        e10: e10,
      );

  // Three local stations: diesel median 2.100 → 1.995 seed; E10 median
  // 1.800 → 1.710 seed.
  final sample = [
    station(id: 'a', diesel: 2.000, e10: 1.750),
    station(id: 'b', diesel: 2.100, e10: 1.800),
    station(id: 'c', diesel: 2.300, e10: 1.900),
  ];

  setUp(() => PriceFormatter.setCountry('FR'));
  tearDown(() => PriceFormatter.setCountry('DE'));

  Future<({_CapturingRadiusAlerts fake, MockStorageRepository storage})>
      pumpSheet(
    WidgetTester tester, {
    List<Station> prices = const [],
    bool withPosition = true,
  }) async {
    final test = standardTestOverrides(country: Countries.france);
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    when(() => test.mockStorage.getSetting(any<String>())).thenReturn(null);
    when(() =>
            test.mockStorage
                .getSetting(StorageKeys.permissionRationaleShownNotifications))
        .thenReturn(true);
    final fake = _CapturingRadiusAlerts();
    await pumpApp(
      tester,
      RadiusAlertCreateSheet(idGenerator: () => 'ux-id'),
      overrides: [
        ...test.overrides,
        radiusAlertsProvider.overrideWith(() => fake),
        zoneAlertPriceSampleProvider.overrideWithValue(prices),
        if (withPosition)
          userPositionOverride(lat: 43.36, lng: 3.42, source: 'GPS')
        else
          userPositionNullOverride(),
      ],
    );
    return (fake: fake, storage: test.mockStorage);
  }

  Finder thresholdField() => find.widgetWithText(TextField, 'Threshold (€/L)');
  Finder labelField() =>
      find.widgetWithText(TextField, 'Label (e.g. Home diesel)');
  String thresholdText(WidgetTester tester) =>
      tester.widget<TextField>(thresholdField()).controller!.text;

  Future<void> tapSave(WidgetTester tester) async {
    final saveBtn = find.widgetWithText(FilledButton, 'Save');
    await tester.scrollUntilVisible(
      saveBtn,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();
  }

  group('threshold — locale decimals', () {
    testWidgets('the seed renders with the FR comma, never a dot',
        (tester) async {
      await pumpSheet(tester);
      expect(thresholdText(tester), '1,500');
    });

    testWidgets('a comma-typed value saves as the parsed threshold',
        (tester) async {
      final ctx = await pumpSheet(tester);
      await tester.enterText(labelField(), 'Maison diesel');
      await tester.enterText(thresholdField(), '1,499');
      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();

      await tapSave(tester);

      expect(ctx.fake.addedAlerts.single.threshold, closeTo(1.499, 1e-9));
    });
  });

  group('threshold — price-based default', () {
    test('suggestedThreshold = median − 5 %, floored to 3 decimals', () {
      expect(suggestedThreshold(sample, FuelType.diesel), 1.995);
      expect(suggestedThreshold(sample, FuelType.e10), 1.71);
      expect(suggestedThreshold(sample, FuelType.lpg), isNull);
      expect(suggestedThreshold(const [], FuelType.diesel), isNull);
      expect(kRadiusAlertThresholdDiscount, 0.05);
      expect(kRadiusAlertFallbackThreshold, 1.5);
    });

    testWidgets('seeds from the local diesel price minus 5 %', (tester) async {
      await pumpSheet(tester, prices: sample);
      expect(thresholdText(tester), '1,995');
    });

    testWidgets('falls back to the constant default when no price is known',
        (tester) async {
      await pumpSheet(tester, prices: const []);
      expect(thresholdText(tester), '1,500');
    });

    testWidgets('re-seeds when the fuel changes — unless the user edited it',
        (tester) async {
      await pumpSheet(tester, prices: sample);
      expect(thresholdText(tester), '1,995');

      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(FuelType.e10.displayName).last);
      await tester.pumpAndSettle();
      expect(thresholdText(tester), '1,710');

      // User types their own value: switching fuel must leave it alone.
      await tester.enterText(thresholdField(), '1,600');
      await tester.pump();
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(FuelType.diesel.displayName).last);
      await tester.pumpAndSettle();
      expect(thresholdText(tester), '1,600');
    });
  });

  group('chosen-location chip', () {
    testWidgets('no chip until a location is chosen', (tester) async {
      await pumpSheet(tester);
      expect(find.byKey(chip), findsNothing);
    });

    testWidgets('"Use my location" shows the "My position" chip; clear (x) '
        'drops the centre and disables Save again', (tester) async {
      await pumpSheet(tester);
      await tester.enterText(labelField(), 'Maison');
      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();

      expect(find.byKey(chip), findsOneWidget);
      expect(find.text('My position'), findsOneWidget);
      expect(find.byKey(blocker), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byTooltip('Clear location'));
      await tester.pumpAndSettle();

      expect(find.byKey(chip), findsNothing);
      expect(find.text('Choose a location'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a typed postal code shows the "Postal code …" chip',
        (tester) async {
      await pumpSheet(tester, withPosition: false);
      final postal = find.widgetWithText(TextField, 'Postal code');
      await tester.scrollUntilVisible(
        postal,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(postal, '34550');
      await tester.pump();

      expect(find.text('Postal code 34550'), findsOneWidget);
      // #2211 — a postal code alone is not a centre; the reason stays.
      await tester.enterText(labelField(), 'Bessan');
      await tester.pump();
      expect(find.text('Choose a location'), findsOneWidget);
    });
  });

  group('disabled Save says why', () {
    testWidgets('first unmet reason: label → threshold → location → none',
        (tester) async {
      await pumpSheet(tester);

      expect(find.text('Enter a label'), findsOneWidget);

      await tester.enterText(labelField(), 'Maison');
      await tester.pump();
      expect(find.text('Enter a label'), findsNothing);
      expect(find.text('Choose a location'), findsOneWidget);

      await tester.enterText(thresholdField(), '');
      await tester.pump();
      expect(find.text('Enter a threshold above 0'), findsOneWidget);

      await tester.enterText(thresholdField(), '2,1');
      await tester.pump();
      expect(find.text('Choose a location'), findsOneWidget);

      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();
      expect(find.byKey(blocker), findsNothing);
    });

    testWidgets('French copy', (tester) async {
      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      await pumpApp(
        tester,
        const RadiusAlertCreateSheet(),
        overrides: [
          ...test.overrides,
          radiusAlertsProvider.overrideWith(_CapturingRadiusAlerts.new),
          zoneAlertPriceSampleProvider.overrideWithValue(const []),
          userPositionOverride(lat: 43.36, lng: 3.42, source: 'GPS'),
        ],
        locale: const Locale('fr'),
      );

      expect(find.text('Saisissez un libellé'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Libellé (ex. Diesel maison)'),
        'Maison',
      );
      await tester.pump();
      expect(find.text('Choisissez un emplacement'), findsOneWidget);

      await tester.tap(find.text('Utiliser ma position'));
      await tester.pumpAndSettle();
      expect(find.text('Ma position'), findsOneWidget);
    });
  });

  // #1699 — the new chip + reason line under the en_XA expansion at
  // 320 dp (pumped on their own: the sheet's pre-existing dropdown /
  // slider rows have their own expansion debt outside #3905).
  testWidgets('chip and reason line do not overflow under en_XA at 320 dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      Material(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadiusAlertCenterChip(
                kind: RadiusAlertCenterKind.postal,
                postalCode: '34550',
                onClear: () {},
              ),
              const RadiusAlertSaveBlockerHint(
                blocker: RadiusAlertSaveBlocker.location,
              ),
            ],
          ),
        ),
      ),
      locale: const Locale('en', 'XA'),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(chip), findsOneWidget);
    expect(find.byKey(blocker), findsOneWidget);
  });
}

class _CapturingRadiusAlerts extends RadiusAlerts {
  final List<RadiusAlert> addedAlerts = [];

  @override
  Future<List<RadiusAlert>> build() async => const [];

  @override
  Future<void> add(RadiusAlert alert) async {
    addedAlerts.add(alert);
    state = AsyncValue.data([alert]);
  }
}
