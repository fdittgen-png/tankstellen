// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/ev/data/services/ev_price_enricher.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/features/search/data/services/ev_charging_service.dart';
import 'package:tankstellen/features/search/presentation/screens/ev_station_detail_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_header_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_info_cards.dart';
import 'package:tankstellen/features/search/providers/ev_charging_service_provider.dart';
import 'package:tankstellen/features/search/providers/ev_search_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart'
    show ConnectorType;

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

class _MockDio extends Mock implements Dio {}

/// A fake [EvPriceEnricher] mirroring the FR-IRVE "confirmed free" outcome:
/// sets `isPayAtLocation:false`, `isMembershipRequired:false`, and the
/// `isFranceIrveEnriched` attribution flag — exactly what
/// [FrIrvePriceService] writes for a `gratuit` row. Used to prove the
/// detail-screen enrich seam fires on a null-field station (#2632).
class _FreeIrveEnricher implements EvPriceEnricher {
  const _FreeIrveEnricher();

  @override
  Future<List<ChargingStation>> enrich(List<ChargingStation> stations) async {
    return [
      for (final s in stations)
        s.copyWith(
          isPayAtLocation: false,
          isMembershipRequired: false,
          isFranceIrveEnriched: true,
        ),
    ];
  }
}

/// A fault-injecting enricher whose [enrich] rejects with an error, used
/// to prove the detail-screen open-path enrich is defensively caught and
/// degrades to the passed station rather than crashing the screen (#2632).
class _ThrowingEnricher implements EvPriceEnricher {
  const _ThrowingEnricher();

  @override
  Future<List<ChargingStation>> enrich(List<ChargingStation> stations) =>
      Future<List<ChargingStation>>.error(Exception('IRVE boom'));
}

/// Test fixture for a basic EV charging station.
const _testEvStation = ChargingStation(
  id: 'ocm-12345',
  name: 'Supercharger Berlin',
  operator: 'Tesla',
  latitude: 52.52,
  longitude: 13.405,
  dist: 2.3,
  address: 'Alexanderplatz 1',
  postCode: '10178',
  place: 'Berlin',
  connectors: [
    EvConnector(
      id: 'ocm-12345-c1',
      type: ConnectorType.ccs,
      rawType: 'CCS',
      maxPowerKw: 250,
      quantity: 8,
      currentType: 'DC',
      status: ConnectorStatus.available,
      statusLabel: 'Available',
    ),
    EvConnector(
      id: 'ocm-12345-c2',
      type: ConnectorType.type2,
      rawType: 'Type 2',
      maxPowerKw: 22,
      quantity: 4,
      currentType: 'AC',
    ),
  ],
  totalPoints: 12,
  isOperational: true,
  usageCost: '0.39 EUR/kWh',
);

void main() {
  group('EVStationDetailScreen', () {
    late MockHiveStorage mockStorage;
    late List<Object> overrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.getRating(any())).thenReturn(null);
      when(() => mockStorage.getEvApiKey()).thenReturn(null);

      overrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        favoritesOverride([]),
        isFavoriteOverride('ocm-12345', false),
      ];
    });

    testWidgets('renders Scaffold with operator in app bar', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      // App bar title shows operator when non-empty
      expect(find.text('Tesla'), findsAtLeast(1));
    });

    testWidgets('renders station name and address', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('Supercharger Berlin'), findsOneWidget);
      expect(find.text('Alexanderplatz 1'), findsOneWidget);
    });

    testWidgets('renders connector information', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('CCS'), findsOneWidget);
      expect(find.text('Type 2'), findsOneWidget);
      expect(find.text('250 kW'), findsOneWidget);
    });

    testWidgets('shows operational status', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('Operational'), findsOneWidget);
    });

    testWidgets('shows usage cost when available', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('0.39 EUR/kWh'), findsOneWidget);
    });
  });

  /// Structural responsive-layout coverage for the EV detail screen (#2532,
  /// Epic #2525). NO macOS goldens — the adaptive branch is pinned by
  /// finding (or not finding) the two-pane [VerticalDivider] while the SAME
  /// section cards render in both layouts.
  group('EVStationDetailScreen responsive layout (#2532)', () {
    late MockHiveStorage mockStorage;
    late List<Object> overrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.getRating(any())).thenReturn(null);
      when(() => mockStorage.getEvApiKey()).thenReturn(null);
      overrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        favoritesOverride([]),
        isFavoriteOverride('ocm-12345', false),
      ];
    });

    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );
    }

    testWidgets(
      'wide (900x600) renders two panes (a VerticalDivider) with the header '
      'and connector cards both mounted',
      (tester) async {
        await pumpAt(tester, const Size(900, 600));

        // The two-pane layout is identified by its divider.
        expect(find.byType(VerticalDivider), findsOneWidget);

        // BOTH the LEFT-pane header and the RIGHT-pane connector card render
        // simultaneously (the portrait single column also mounts both, but
        // the divider proves the two-pane split is active here).
        expect(find.byType(EVStationHeaderCard), findsOneWidget);
        expect(find.byType(EVConnectorsCard), findsOneWidget);

        // A normal AppBar — there is no expanding SliverAppBar in this screen.
        expect(find.byType(AppBar), findsOneWidget);
      },
    );

    testWidgets(
      'compact (590x900) keeps a single column — no VerticalDivider',
      (tester) async {
        // 590dp is below the 600dp split breakpoint (still compact) yet wide
        // enough that the pre-existing connector-tile Row does not overflow —
        // this test isolates the layout BRANCH, not that widget's intrinsic
        // sizing.
        await pumpAt(tester, const Size(590, 900));

        // No two-pane split on compact.
        expect(find.byType(VerticalDivider), findsNothing);

        // The section cards still render in the single column.
        expect(find.byType(EVStationHeaderCard), findsOneWidget);
        expect(find.byType(EVConnectorsCard), findsOneWidget);
      },
    );
  });

  // The #2632 fix: the free EV price layer (#2619) now surfaces on the
  // detail screen regardless of HOW the station was opened — not just the
  // search-list tap that was the single enriched seam before. These tests
  // pin the badge behaviour AND the two regressions the fix closes.
  group('EVStationDetailScreen access-cost badge (#2632)', () {
    late MockHiveStorage mockStorage;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.getRating(any())).thenReturn(null);
      when(() => mockStorage.getEvApiKey()).thenReturn(null);
    });

    List<Object> overridesFor(String id) => [
          hiveStorageProvider.overrideWithValue(mockStorage),
          favoritesOverride([]),
          isFavoriteOverride(id, false),
        ];

    /// Pumps the detail screen on a comfortably wide surface so the header
    /// card's status Row (which renders the longer "Status unknown" label
    /// when `isOperational` is null) does not trip the unrelated ~2px
    /// RenderFlex overflow — this group asserts the PRICING card, not the
    /// header's intrinsic sizing.
    Future<void> pumpDetail(
      WidgetTester tester,
      ChargingStation station, {
      required List<Object> overrides,
    }) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpApp(
        tester,
        EVStationDetailScreen(station: station),
        overrides: overrides,
      );
    }

    /// A FR-coordinate station carrying NONE of the #2619 access-cost
    /// fields — the dominant cause (favorite rehydrate / map marker /
    /// deep-link) where the old code showed "Pricing not available".
    const nullFieldsFr = ChargingStation(
      id: 'ocm-99',
      name: 'Borne Lyon',
      operator: 'Réseau Public',
      latitude: 45.764,
      longitude: 4.835,
      dist: 1.0,
      address: 'Place Bellecour',
      postCode: '69002',
      place: 'Lyon',
      connectors: [
        EvConnector(
          id: 'ocm-99-c1',
          type: ConnectorType.type2,
          maxPowerKw: 22,
          status: ConnectorStatus.available,
        ),
      ],
      totalPoints: 2,
      isOperational: true,
      // usageCost + all UsageType fields null → no badge WITHOUT enrich.
    );

    testWidgets(
      'free station (isPayAtLocation:false, isMembershipRequired:false) '
      'shows the FREE badge',
      (tester) async {
        const freeStation = ChargingStation(
          id: 'ocm-1',
          name: 'Free Charger',
          latitude: 52.5,
          longitude: 13.4,
          isPayAtLocation: false,
          isMembershipRequired: false,
        );
        await pumpDetail(
          tester,
          freeStation,
          overrides: overridesFor('ocm-1'),
        );

        expect(find.text('Free'), findsOneWidget);
      },
    );

    testWidgets('paid station (isPayAtLocation:true) shows the PAID badge',
        (tester) async {
      const paidStation = ChargingStation(
        id: 'ocm-2',
        name: 'Paid Charger',
        latitude: 52.5,
        longitude: 13.4,
        isPayAtLocation: true,
      );
      await pumpDetail(
        tester,
        paidStation,
        overrides: overridesFor('ocm-2'),
      );

      expect(find.text('Pay at location'), findsOneWidget);
    });

    testWidgets(
      'all-null access fields + null usageCost falls back to '
      '"Pricing not available" — no false badge',
      (tester) async {
        const unknownStation = ChargingStation(
          id: 'ocm-3',
          name: 'Unknown Charger',
          latitude: 52.5,
          longitude: 13.4,
        );
        await pumpDetail(
          tester,
          unknownStation,
          overrides: overridesFor('ocm-3'),
        );

        expect(find.text('Free'), findsNothing);
        expect(find.text('Pay at location'), findsNothing);
        expect(
          find.text('Pricing not available from provider'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'DOMINANT-CAUSE REGRESSION: a rehydrated FR station with ALL #2619 '
      'fields null surfaces the FREE badge + IRVE attribution once the '
      'open-path enrich fires',
      (tester) async {
        await pumpDetail(
          tester,
          nullFieldsFr,
          overrides: [
            ...overridesFor('ocm-99'),
            // The enricher seam — mirrors a confirmed-free IRVE row.
            evPriceEnricherProvider
                .overrideWithValue(const _FreeIrveEnricher()),
          ],
        );
        await tester.pumpAndSettle();

        // initState enrich fired on a null-field station → FREE badge now
        // shows where the old single-seam path would have shown nothing.
        expect(find.text('Free'), findsOneWidget);
        // …and the France IRVE attribution line is rendered (gated on
        // isFranceIrveEnriched, which only the enrich could have set).
        expect(
          find.textContaining('Base nationale des IRVE'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'REFRESH REGRESSION: tapping refresh re-enriches, so an un-enriched '
      'OCM re-fetch does NOT strip the badge',
      (tester) async {
        // A real EVChargingService whose Dio returns ONE matching-id OCM
        // record with NO UsageType block — i.e. the raw refresh that used
        // to overwrite the enriched station and erase the badge (#2632).
        final dio = _MockDio();
        when(() => dio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: '/poi/'),
              statusCode: 200,
              data: <dynamic>[
                {
                  'ID': 99,
                  'AddressInfo': {
                    'Title': 'Borne Lyon',
                    'Latitude': 45.764,
                    'Longitude': 4.835,
                    'AddressLine1': 'Place Bellecour',
                  },
                  'Connections': const <dynamic>[],
                  'NumberOfPoints': 2,
                  // No UsageType, no UsageCost → un-enriched on its own.
                },
              ],
            ));

        await pumpDetail(
          tester,
          nullFieldsFr,
          overrides: [
            ...overridesFor('ocm-99'),
            evPriceEnricherProvider
                .overrideWithValue(const _FreeIrveEnricher()),
            evChargingServiceProvider.overrideWithValue(
              EVChargingService(apiKey: 'k', dio: dio),
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Sanity: the open-path enrich already produced the badge.
        expect(find.text('Free'), findsOneWidget);

        // Tap refresh → service returns the un-enriched record.
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();

        // The badge SURVIVES — _refreshStation re-applied the enrich.
        expect(find.text('Free'), findsOneWidget);
      },
    );

    testWidgets(
      'open-path enrich that throws is caught — screen degrades to the '
      'passed station and still renders (never-throws fault path)',
      (tester) async {
        // The enrich future rejects; _enrichOnOpen must swallow it. The
        // screen renders the un-enriched station (its own access fields)
        // rather than crashing — `returnsNormally`/no-throw is the contract.
        // Capture the swallowed error via the logger's spool seam so it
        // never falls through to a real Hive box in the test.
        addTearDown(errorLogger.resetForTest);
        errorLogger.spoolEnqueueOverride = ({
          required String isolateTaskName,
          required Object error,
          StackTrace? stack,
          Map<String, dynamic>? contextMap,
          DateTime? timestamp,
        }) async {};

        const paidStation = ChargingStation(
          id: 'ocm-4',
          name: 'Resilient Charger',
          latitude: 52.5,
          longitude: 13.4,
          isPayAtLocation: true,
        );
        await pumpDetail(
          tester,
          paidStation,
          overrides: [
            ...overridesFor('ocm-4'),
            evPriceEnricherProvider
                .overrideWithValue(const _ThrowingEnricher()),
          ],
        );

        // No exception surfaced through pumpAndSettle; the station's own
        // (un-enriched) PAID signal still renders.
        expect(tester.takeException(), isNull);
        expect(find.text('Pay at location'), findsOneWidget);
      },
    );
  });
}
