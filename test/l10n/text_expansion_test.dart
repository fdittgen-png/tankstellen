import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/setup/presentation/widgets/language_selector.dart';

import '../fixtures/stations.dart';
import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// Pseudo-localization pass for text-expansion overflow (#1699).
///
/// `en_XA` is a synthetic pseudo-locale (`tool/gen_pseudo_arb.dart` →
/// `lib/l10n/app_en_XA.arb`) whose every string is accented and padded
/// ~45% longer than English — the band German / Finnish / Slavic
/// translations occupy. It never ships in the language picker; it
/// exists so this test can pump fixed-size chrome under deliberately
/// long strings.
///
/// Each test pumps a chrome widget under `Locale('en', 'XA')` at a
/// narrow 320 dp viewport (the smallest phone width still in the
/// support matrix) and asserts no `RenderFlex` overflow. A layout that
/// survives `en_XA` at 320 dp survives every real translation; a
/// failure here is real chrome that truncates for non-English users.
void main() {
  const pseudoLocale = Locale('en', 'XA');

  /// Pumps [child] under the pseudo-locale at a 320 dp viewport, then
  /// fails if layout raised an overflow (or any other) exception.
  Future<void> pumpPseudo(
    WidgetTester tester,
    Widget child, {
    List<Object>? overrides,
    String? widgetName,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, child, locale: pseudoLocale, overrides: overrides);

    expect(
      tester.takeException(),
      isNull,
      reason: '${widgetName ?? child.runtimeType} overflows at 320 dp '
          'under the en_XA pseudo-locale — its fixed-size chrome is too '
          'tight for expanded (German / Slavic / Finnish) translations. '
          'Give the offending Row/Column a Flexible/Expanded child, allow '
          'wrapping, or shorten the layout.',
    );
  }

  group('Text-expansion overflow (pseudo-locale en_XA)', () {
    testWidgets('StationCard — open station', (tester) async {
      await pumpPseudo(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
        widgetName: 'StationCard',
      );
    });

    testWidgets('StationCard — favorite station', (tester) async {
      await pumpPseudo(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
        ),
        widgetName: 'StationCard (favorite)',
      );
    });

    testWidgets('ServiceStatusBanner — stale / offline banner',
        (tester) async {
      final result = ServiceResult<List<String>>(
        data: const ['cached'],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isStale: true,
        errors: const [],
      );
      await pumpPseudo(
        tester,
        ServiceStatusBanner(result: result),
        widgetName: 'ServiceStatusBanner',
      );
    });

    testWidgets('LanguageSelector — choice-chip wrap', (tester) async {
      await pumpPseudo(
        tester,
        LanguageSelector(
          selected: AppLanguages.all.first,
          onSelect: (_) {},
        ),
        widgetName: 'LanguageSelector',
      );
    });

    testWidgets('FuelTypeSelector — Germany fuel set', (tester) async {
      await pumpPseudo(
        tester,
        const FuelTypeSelector(),
        overrides: [
          fakeHiveStorageOverride().override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
        widgetName: 'FuelTypeSelector',
      );
    });
  });
}
