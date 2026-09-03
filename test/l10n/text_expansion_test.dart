// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fill_ups/domain/services/monthly_insights_aggregator.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_insights_card.dart';
import 'package:tankstellen/features/obd2/api.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/domain/entities/price_record.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_choices_screen.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices/all_prices_table_header.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices_station_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/criteria/criteria_action_bar.dart';
import 'package:tankstellen/features/search/presentation/widgets/criteria/criteria_option_row.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/results_row.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_mode_toggle.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/search/providers/all_prices_comparison_model.dart';
import 'package:tankstellen/features/search/providers/all_prices_table_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/search/providers/station_rating_provider.dart';
import 'package:tankstellen/features/setup/presentation/widgets/language_selector.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/opening_hours_view.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_history_section.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_amenities_services_section.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_header.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_prices_section.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_status_row.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording/recording_status_strip.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_avg_consumption_card.dart';
import 'package:tankstellen/features/trips/providers/recording_gps_fix_provider.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../fixtures/stations.dart';
import '../helpers/mock_providers.dart';
import '../helpers/never_truncates.dart';
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
/// #3904 — a reliable two-month comparison with the widest figures the
/// month card renders (four-digit km, hours + minutes, a two-decimal
/// consumption with its unit) so every value column is at its widest.
const _monthSummary = MonthlyInsightsSummary(
  currentMonthTripCount: 3,
  previousMonthTripCount: 97,
  currentMonthDriveTime: Duration(hours: 1, minutes: 19),
  previousMonthDriveTime: Duration(hours: 22, minutes: 25),
  currentMonthDistanceKm: 48.0,
  previousMonthDistanceKm: 1039.0,
  currentMonthAvgConsumptionLPer100km: 10.1,
  previousMonthAvgConsumptionLPer100km: 10.6,
  isComparisonReliable: true,
);

/// #3933 — the widest all-prices row the French flex-fuel case produces:
/// four columns plus the "+n" expander, every cell carrying a price, a
/// delta and a cost per 100 km, and a two-part verdict line underneath.
/// If the grid survives this at 320 dp it survives every real result set.
const _allPricesColumns = AllPricesColumns(
  visible: [FuelType.e10, FuelType.e98, FuelType.diesel, FuelType.e85],
  overflow: [FuelType.lpg],
);

const _allPricesStation = Station(
  id: 'fr-expansion',
  name: 'Flex',
  brand: 'TOTAL ENERGIES',
  street: 'Avenue de la Gare',
  postCode: '34120',
  place: 'Pezenas',
  lat: 43.46,
  lng: 3.42,
  dist: 12.4,
  e10: 2.089,
  e98: 2.189,
  diesel: 1.929,
  e85: 0.839,
  lpg: 0.959,
  isOpen: true,
);

List<Object> _allPricesOverrides() => <Object>[
      fakeHiveStorageOverride().override,
      activeCountryOverride(Countries.france),
      allPricesColumnsProvider.overrideWithValue(_allPricesColumns),
      allPricesBestByFuelProvider.overrideWithValue(
        const {FuelType.e85: 0.809, FuelType.e10: 2.029},
      ),
      allPricesFuelCostModelProvider.overrideWithValue(
        const FuelCostModel(
          litersPer100kmByFuel: {FuelType.e85: 6.0, FuelType.e10: 4.6},
          usableFuels: {
            FuelType.e5,
            FuelType.e10,
            FuelType.e98,
            FuelType.e85,
          },
        ),
      ),
    ];

/// #3938 — the paged help bubble reads a shown flag and an int position
/// from the settings box; a stateful fake keeps both absent so the bubble
/// renders open on tip 1.
List<Object> _helpBubbleOverrides() => <Object>[
      fakeHiveStorageOverride().override,
      fakeStorageRepositoryOverride().override,
    ];

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

  /// #3662 (llmwiki page 26) — text SCALING is the same bug class in
  /// another axis: a user's 1.3x font setting expands every string at
  /// once. Pumps [child] in plain English at a 1.3x text scale on the
  /// same 320 dp viewport and fails on any overflow. Layouts that
  /// survive the en_XA expansion usually survive large fonts — but
  /// "usually" is not a test.
  Future<void> pumpScaled(
    WidgetTester tester,
    Widget child, {
    List<Object>? overrides,
    String? widgetName,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, child, overrides: overrides);

    expect(
      tester.takeException(),
      isNull,
      reason: '${widgetName ?? child.runtimeType} overflows at 320 dp '
          'under a 1.3x text scale — a user-raised font setting breaks '
          'its fixed-size chrome. Give the offending Row/Column a '
          'Flexible/Expanded child, allow wrapping, or shorten the '
          'layout.',
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

    // #3909 (Epic #3907) — the "Your choices" list: every consent /
    // privacy-control subtitle wraps, none ellipsises.
    testWidgets('PrivacyChoicesScreen — no row truncates', (tester) async {
      await pumpPseudo(
        tester,
        const PrivacyChoicesScreen(),
        overrides: [fakeHiveStorageOverride().override],
        widgetName: 'PrivacyChoicesScreen',
      );
      expectNoTextTruncates(tester,
          within: find.byKey(const Key('privacyChoicesList')));
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

    testWidgets('MonthlyInsightsCard — reliable comparison (#3904)',
        (tester) async {
      await pumpPseudo(
        tester,
        const MonthlyInsightsCard(summary: _monthSummary),
        widgetName: 'MonthlyInsightsCard',
      );
    });

    // #3933 — the all-prices comparison table has FIXED columns, so an
    // expanded translation cannot be absorbed by re-flowing: it has to
    // shrink inside its column instead. These two cases are the proof.
    testWidgets('AllPricesTableHeader — sticky columns + legend (#3933)',
        (tester) async {
      await pumpPseudo(
        tester,
        const AllPricesTableHeader(),
        overrides: _allPricesOverrides(),
        widgetName: 'AllPricesTableHeader',
      );
    });

    // #3938 — the paged help bubble is the surface the epic moved the
    // explanations INTO, so it is the one that must survive expansion:
    // five sentences, a dismiss button and a three-part nav group inside
    // one card at 320 dp.
    testWidgets('HelpBanner — the paged search-surface bubble (#3938)',
        (tester) async {
      await pumpPseudo(
        tester,
        const HelpBanner(
          storageKey: StorageKeys.helpBannerSearchResults,
          icon: Icons.lightbulb_outline,
          surface: HelpSurface.searchResults,
        ),
        overrides: _helpBubbleOverrides(),
        widgetName: 'HelpBanner (paged)',
      );
      // Guard against a vacuous pass: a hidden bubble cannot overflow.
      expect(
        find.byKey(
          const ValueKey(
            'help-bubble-pager-${StorageKeys.helpBannerSearchResults}',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AllPricesStationCard — four columns + verdict (#3933)',
        (tester) async {
      await pumpPseudo(
        tester,
        const SingleChildScrollView(
          child: AllPricesStationCard(station: _allPricesStation),
        ),
        overrides: _allPricesOverrides(),
        widgetName: 'AllPricesStationCard',
      );
    });
  });

  group('Text-scale overflow (1.3x font setting, #3662)', () {
    testWidgets('StationCard — open station', (tester) async {
      await pumpScaled(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
        widgetName: 'StationCard',
      );
    });

    testWidgets('StationCard — favorite station', (tester) async {
      await pumpScaled(
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
      // #3660 — the wall-clock ratchet: a pinned mid-month instant, not
      // a raw wall-clock read; the banner takes staleness explicitly.
      final result = ServiceResult<List<String>>(
        data: const ['cached'],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 3, 11, 14, 15),
        isStale: true,
        errors: const [],
      );
      await pumpScaled(
        tester,
        ServiceStatusBanner(result: result),
        widgetName: 'ServiceStatusBanner',
      );
    });

    testWidgets('LanguageSelector — choice-chip wrap', (tester) async {
      // The selector's chip Wrap grows VERTICALLY at a raised text
      // scale by design; on the real setup screen it sits inside a
      // SingleChildScrollView (setup_screen.dart), so the scaled pass
      // pumps it in the same container — a bottom overflow here would
      // be a harness artifact, not a defect. Horizontal overflow (the
      // real bug class) still fails.
      await pumpScaled(
        tester,
        SingleChildScrollView(
          child: LanguageSelector(
            selected: AppLanguages.all.first,
            onSelect: (_) {},
          ),
        ),
        widgetName: 'LanguageSelector',
      );
    });

    testWidgets('PrivacyChoicesScreen — no row truncates', (tester) async {
      await pumpScaled(
        tester,
        const PrivacyChoicesScreen(),
        overrides: [fakeHiveStorageOverride().override],
        widgetName: 'PrivacyChoicesScreen',
      );
      expectNoTextTruncates(tester,
          within: find.byKey(const Key('privacyChoicesList')));
    });

    testWidgets('FuelTypeSelector — Germany fuel set', (tester) async {
      await pumpScaled(
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

    testWidgets('MonthlyInsightsCard — reliable comparison (#3904)',
        (tester) async {
      await pumpScaled(
        tester,
        const MonthlyInsightsCard(summary: _monthSummary),
        widgetName: 'MonthlyInsightsCard',
      );
    });

    testWidgets('AllPricesTableHeader — sticky columns + legend (#3933)',
        (tester) async {
      await pumpScaled(
        tester,
        const AllPricesTableHeader(),
        overrides: _allPricesOverrides(),
        widgetName: 'AllPricesTableHeader',
      );
    });

    testWidgets('HelpBanner — the paged search-surface bubble (#3938)',
        (tester) async {
      await pumpScaled(
        tester,
        const HelpBanner(
          storageKey: StorageKeys.helpBannerSearchResults,
          icon: Icons.lightbulb_outline,
          surface: HelpSurface.searchResults,
        ),
        overrides: _helpBubbleOverrides(),
        widgetName: 'HelpBanner (paged)',
      );
      // Guard against a vacuous pass: a hidden bubble cannot overflow.
      expect(
        find.byKey(
          const ValueKey(
            'help-bubble-pager-${StorageKeys.helpBannerSearchResults}',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AllPricesStationCard — four columns + verdict (#3933)',
        (tester) async {
      await pumpScaled(
        tester,
        const SingleChildScrollView(
          child: AllPricesStationCard(station: _allPricesStation),
        ),
        overrides: _allPricesOverrides(),
        widgetName: 'AllPricesStationCard',
      );
    });
  });

  // #3902 — the station-detail rows this pass reworded / restyled: the
  // parameterised status phrase, the "Not sold here" footnote, the
  // self-service automate line and the brand header (its round directions
  // button is gone, so the heading column now spans the full width).
  group('Station detail rows (#3902)', () {
    // Pinned instant — the status row only formats the age, never reads the
    // wall clock itself.
    final result = ServiceResult<Object>(
      data: const Object(),
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026, 3, 11, 14, 15),
    );
    final statusOverrides = <Object>[
      stationRatingsProvider.overrideWith(
        () => _SeededStationRatings({testStation.id: 4}),
      ),
    ];
    final pricesOverrides = <Object>[
      activeProfileProvider.overrideWith(() => _NullActiveProfile()),
    ];
    final automate = WeeklyOpeningHours.allWeek24h(automate24h: true);
    final wednesday = DateTime(2026, 6, 3, 10, 0);

    Widget statusRow() => StationStatusRow(
          station: testStation,
          serviceResult: result,
          stationId: testStation.id,
        );

    testWidgets('StationStatusRow — pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        statusRow(),
        overrides: statusOverrides,
        widgetName: 'StationStatusRow',
      );
    });

    testWidgets('StationStatusRow — 1.3x', (tester) async {
      await pumpScaled(
        tester,
        statusRow(),
        overrides: statusOverrides,
        widgetName: 'StationStatusRow',
      );
    });

    testWidgets('StationPricesSection with a "Not sold here" footnote — '
        'pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        const SingleChildScrollView(
          child: StationPricesSection(station: kUnpricedE5Station),
        ),
        overrides: pricesOverrides,
        widgetName: 'StationPricesSection',
      );
    });

    testWidgets('StationPricesSection with a "Not sold here" footnote — 1.3x',
        (tester) async {
      await pumpScaled(
        tester,
        const SingleChildScrollView(
          child: StationPricesSection(station: kUnpricedE5Station),
        ),
        overrides: pricesOverrides,
        widgetName: 'StationPricesSection',
      );
    });

    testWidgets('OpeningHoursView with the automate line — pseudo-locale',
        (tester) async {
      await pumpPseudo(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: automate, now: wednesday),
        ),
        widgetName: 'OpeningHoursView (automate)',
      );
    });

    testWidgets('OpeningHoursView with the automate line — 1.3x',
        (tester) async {
      await pumpScaled(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: automate, now: wednesday),
        ),
        widgetName: 'OpeningHoursView (automate)',
      );
    });

    testWidgets('StationBrandHeader — pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        const StationBrandHeader(station: testStation),
        widgetName: 'StationBrandHeader',
      );
    });

    testWidgets('StationBrandHeader — 1.3x', (tester) async {
      await pumpScaled(
        tester,
        const StationBrandHeader(station: testStation),
        widgetName: 'StationBrandHeader',
      );
    });
  });

  // #3916 — the recording screen's status strip (two chip rows whose
  // labels must ellipsize, never overflow) and the consumption card with
  // its longest fuel-source badge ("Estimated · pump-calibrated ±12 %").
  group('Recording screen status strip + fuel-source badge (#3916)', () {
    final now = DateTime(2026, 3, 11, 14, 30);
    // The widest chip labels: a reconnect in flight + an approximate fix
    // with coverage.
    List<Object> stripOverrides() => <Object>[
          tripRecordingProvider.overrideWith(
            () => _FixedTripRecording(const TripRecordingState(
              phase: TripRecordingPhase.degradedGpsOnly,
              dropReason: TripDropReason.transportError,
              reconnectPassiveWaiting: true,
              live: TripLiveReading(
                elapsed: Duration(minutes: 5),
                distanceKmSoFar: 4.0,
              ),
            )),
          ),
          obd2ReconnectProvider.overrideWith(
            () => _PinnedLinkState(Obd2LinkState.idle),
          ),
          obd2ConnectionStatusProvider.overrideWith(
            () => _FixedObd2Status(const Obd2ConnectionSnapshot(
              state: Obd2ConnectionState.connected,
              adapterName: 'vLinker FS',
            )),
          ),
          recordingGpsFixProvider.overrideWith(
            () => _SeededGpsFix(RecordingGpsFix(
              fixAt: now.subtract(const Duration(seconds: 1)),
              firstFixAt: now.subtract(const Duration(seconds: 61)),
              fixCount: 59,
              accuracyM: 40.0,
            )),
          ),
          appClockProvider.overrideWithValue(FixedClock(now)),
        ];
    // The widest badge: an estimated branch with a pump-calibrated gain.
    const estimatedReading = TripLiveReading(
      elapsed: Duration(minutes: 5),
      distanceKmSoFar: 5.0,
      fuelLitersSoFar: 0.3,
      fuelRateLPerHour: 4.0,
      fuelSource: FuelRateSourceTag.speedDensity,
    );
    List<Object> badgeOverrides() => <Object>[
          activeVehicleProfileProvider.overrideWith(
            () => _FixedActiveVehicle(const VehicleProfile(
              id: 'veh-a',
              name: 'Test',
              pumpGain: 1.12,
              pumpGainSamples: 3,
            )),
          ),
        ];

    testWidgets('RecordingStatusStrip — pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        const RecordingStatusStrip(),
        overrides: stripOverrides(),
        widgetName: 'RecordingStatusStrip',
      );
    });

    testWidgets('RecordingStatusStrip — 1.3x', (tester) async {
      await pumpScaled(
        tester,
        const RecordingStatusStrip(),
        overrides: stripOverrides(),
        widgetName: 'RecordingStatusStrip',
      );
    });

    testWidgets('TripAvgConsumptionCard with the calibrated-estimate badge '
        '— pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        const TripAvgConsumptionCard(live: estimatedReading),
        overrides: badgeOverrides(),
        widgetName: 'TripAvgConsumptionCard (fuel-source badge)',
      );
    });

    testWidgets('TripAvgConsumptionCard with the calibrated-estimate badge '
        '— 1.3x', (tester) async {
      await pumpScaled(
        tester,
        const TripAvgConsumptionCard(live: estimatedReading),
        overrides: badgeOverrides(),
        widgetName: 'TripAvgConsumptionCard (fuel-source badge)',
      );
    });
  });

  // #3928 (Epic #3925) — the two station-detail strings this issue adds
  // are the longest prose on the page: the single-observation sentence
  // and the merged section heading. Both must survive an expanded
  // translation at 320 dp and a 1.3x font setting.
  group('Station detail — price history + merged services (#3928)', () {
    const singlePointStation = Station(
      id: 'station-3928',
      name: 'Star Tankstelle',
      brand: 'STAR',
      street: 'Hauptstr.',
      houseNumber: '12',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.5200,
      lng: 13.4050,
      dist: 1.5,
      diesel: 2.329,
      isOpen: true,
    );

    List<Object> historyOverrides() {
      final storage = fakeHiveStorageOverride();
      return <Object>[
        storage.override,
        priceHistoryRepositoryProvider
            .overrideWithValue(PriceHistoryRepository(storage.fake)),
        priceHistoryProvider('station-3928').overrideWithValue([
          PriceRecord(
            stationId: 'station-3928',
            recordedAt: DateTime(2026, 8, 21, 9, 30),
            diesel: 2.329,
          ),
        ]),
        priceStatsProvider('station-3928', FuelType.diesel)
            .overrideWithValue(const PriceStats(
          min: 2.329,
          max: 2.329,
          avg: 2.329,
          current: 2.329,
        )),
      ];
    }

    /// A station whose amenity chips and raw services together overflow
    /// the eight-chip fold — the widest the merged section ever gets.
    final crowdedStation = singlePointStation.copyWith(
      amenities: const {
        StationAmenity.shop,
        StationAmenity.carWash,
        StationAmenity.airPump,
        StationAmenity.atm,
      },
      services: const [
        'Piste poids lourds',
        'Automate CB',
        'Location de vehicules',
        'Vente de gaz domestique',
        'Relais colis',
        'Douches',
      ],
      department: 'Berlin',
      region: 'Berlin',
    );

    testWidgets('PriceHistorySection single-observation line — en_XA',
        (tester) async {
      await pumpPseudo(
        tester,
        const SingleChildScrollView(
          child: PriceHistorySection(
            stationId: 'station-3928',
            station: singlePointStation,
          ),
        ),
        overrides: historyOverrides(),
        widgetName: 'PriceHistorySection (single observation)',
      );
    });

    testWidgets('PriceHistorySection single-observation line — 1.3x',
        (tester) async {
      await pumpScaled(
        tester,
        const SingleChildScrollView(
          child: PriceHistorySection(
            stationId: 'station-3928',
            station: singlePointStation,
          ),
        ),
        overrides: historyOverrides(),
        widgetName: 'PriceHistorySection (single observation)',
      );
    });

    testWidgets('Amenities & services merged section — en_XA', (tester) async {
      await pumpPseudo(
        tester,
        SingleChildScrollView(
          child: StationAmenitiesServicesSection(station: crowdedStation),
        ),
        widgetName: 'StationAmenitiesServicesSection',
      );
    });

    testWidgets('Amenities & services merged section — 1.3x', (tester) async {
      await pumpScaled(
        tester,
        SingleChildScrollView(
          child: StationAmenitiesServicesSection(station: crowdedStation),
        ),
        widgetName: 'StationAmenitiesServicesSection',
      );
    });
  });

  // #3927 (Epic #3925) — the criteria sheet's fixed-size chrome: the mode
  // toggle that used to wrap over two lines, the sticky action bar with
  // its disabled-reason line, and one route-option row.
  group('Search criteria sheet chrome (#3927)', () {
    Widget modeToggle() =>
        SearchModeToggle(mode: SearchMode.nearby, onChanged: (_) {});

    Widget actionBar() => Builder(
      builder: (context) => CriteriaActionBar(
        onSubmit: () {},
        onReset: () {},
        disabledReason: AppLocalizations.of(
          context,
        ).criteriaSubmitDisabledRoute,
      ),
    );

    Widget optionRow() => Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return CriteriaOptionRow(
          label: l10n.routeSegment,
          value: '200 km',
          caption: l10n.showCheapestEveryNKm(200),
          child: CriteriaOptionSlider(
            value: 200,
            min: 50,
            max: 1000,
            divisions: 19,
            label: '200 km',
            onChanged: (_) {},
          ),
        );
      },
    );

    testWidgets('SearchModeToggle — pseudo-locale', (tester) async {
      await pumpPseudo(tester, modeToggle(), widgetName: 'SearchModeToggle');
      // The words survive; only the icons may be dropped (#3927).
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(text.maxLines, 1);
      }
    });

    testWidgets('SearchModeToggle — 1.3x', (tester) async {
      await pumpScaled(tester, modeToggle(), widgetName: 'SearchModeToggle');
    });

    testWidgets('CriteriaActionBar — pseudo-locale', (tester) async {
      await pumpPseudo(tester, actionBar(), widgetName: 'CriteriaActionBar');
    });

    testWidgets('CriteriaActionBar — 1.3x', (tester) async {
      await pumpScaled(tester, actionBar(), widgetName: 'CriteriaActionBar');
    });

    testWidgets('CriteriaOptionRow — pseudo-locale', (tester) async {
      await pumpPseudo(tester, optionRow(), widgetName: 'CriteriaOptionRow');
    });

    testWidgets('CriteriaOptionRow — 1.3x', (tester) async {
      await pumpScaled(tester, optionRow(), widgetName: 'CriteriaOptionRow');
    });
  });

  // #3926 — the two-row results chrome. Both rows pack several segments /
  // controls onto one band, which is exactly the shape that breaks under an
  // expanded translation: row A wraps its pills, row B ellipsises the count
  // and the radar chip and wraps its sort chips.
  group('#3926 results chrome — two rows', () {
    final chromeNow = DateTime(2026, 3, 11, 14, 30);

    List<Object> chromeOverrides() {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
      when(() => test.mockStorage.getRatings())
          .thenReturn(const <String, int>{});
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      return <Object>[
        ...test.overrides,
        userPositionOverride(lat: 48.85, lng: 2.35, source: 'GPS'),
        appClockProvider.overrideWithValue(FixedClock(chromeNow)),
        searchStateProvider.overrideWith(
          () => _ChromeSearchState(chromeNow.subtract(const Duration(hours: 2))),
        ),
      ];
    }

    testWidgets('SearchSummaryBar (row A) — pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        const SearchSummaryBar(),
        overrides: chromeOverrides(),
        widgetName: 'SearchSummaryBar (row A)',
      );
    });

    testWidgets('SearchSummaryBar (row A) — 1.3x', (tester) async {
      await pumpScaled(
        tester,
        const SearchSummaryBar(),
        overrides: chromeOverrides(),
        widgetName: 'SearchSummaryBar (row A)',
      );
    });

    testWidgets('SearchResultsRow (row B) — pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        const SearchResultsRow(items: _chromeItems),
        overrides: chromeOverrides(),
        widgetName: 'SearchResultsRow (row B)',
      );
    });

    testWidgets('SearchResultsRow (row B) — 1.3x', (tester) async {
      await pumpScaled(
        tester,
        const SearchResultsRow(items: _chromeItems),
        overrides: chromeOverrides(),
        widgetName: 'SearchResultsRow (row B)',
      );
    });

    testWidgets('SearchResultsRow (row B) with the radar scope entry '
        '— pseudo-locale', (tester) async {
      await pumpPseudo(
        tester,
        SearchResultsRow(items: _chromeItems, onRadarToggle: () {}),
        overrides: chromeOverrides(),
        widgetName: 'SearchResultsRow (row B, radar scope)',
      );
    });
  });
}

/// #3926 — a two-station result set downloaded at a pinned instant, so the
/// row-A freshness segment renders its longest ("Prices from 2 h ago") form.
class _ChromeSearchState extends SearchState {
  _ChromeSearchState(this._fetchedAt);

  final DateTime _fetchedAt;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: _chromeItems,
          source: ServiceSource.prixCarburantsApi,
          fetchedAt: _fetchedAt,
        ),
      );
}

const _chromeItems = <SearchResultItem>[
  FuelStationResult(_chromeStationA),
  FuelStationResult(_chromeStationB),
];

const _chromeStationA = Station(
  id: 'fr-chrome-a',
  name: 'A',
  brand: 'TOTAL',
  street: 'rue A',
  postCode: '75001',
  place: 'Paris',
  lat: 48.85,
  lng: 2.35,
  dist: 1.2,
  e10: 1.75,
  isOpen: true,
);

const _chromeStationB = Station(
  id: 'fr-chrome-b',
  name: 'B',
  brand: 'ESSO',
  street: 'rue B',
  postCode: '75002',
  place: 'Paris',
  lat: 48.86,
  lng: 2.36,
  dist: 2.4,
  e10: 1.95,
  isOpen: true,
);

// #3916 — pinned fakes for the recording status strip + badge cases.
class _FixedTripRecording extends TripRecording {
  _FixedTripRecording(this._state);
  final TripRecordingState _state;
  @override
  TripRecordingState build() => _state;
}

class _PinnedLinkState extends Obd2Reconnect {
  _PinnedLinkState(this._pinned);
  final Obd2LinkState _pinned;
  @override
  Obd2LinkState build() => _pinned;
}

class _FixedObd2Status extends Obd2ConnectionStatus {
  _FixedObd2Status(this._initial);
  final Obd2ConnectionSnapshot _initial;
  @override
  Obd2ConnectionSnapshot build() => _initial;
}

class _SeededGpsFix extends RecordingGpsFixTracker {
  _SeededGpsFix(this._fix);
  final RecordingGpsFix? _fix;
  @override
  RecordingGpsFix? build() => _fix;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._v);
  final VehicleProfile? _v;
  @override
  VehicleProfile? build() => _v;
}

/// testStation without its Super E5 price — drives the #3902 footnote.
const kUnpricedE5Station = Station(
  id: '51d4b477-a095-1aa0-e100-80009459e03a',
  name: 'Star Tankstelle',
  brand: 'STAR',
  street: 'Hauptstr.',
  houseNumber: '12',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5200,
  lng: 13.4050,
  dist: 1.5,
  e10: 1.799,
  diesel: 1.659,
  isOpen: true,
);

class _SeededStationRatings extends StationRatings {
  _SeededStationRatings(this._initial);
  final Map<String, int> _initial;
  @override
  Map<String, int> build() => _initial;
}

class _NullActiveProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}
