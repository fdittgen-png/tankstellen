// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/notifications/notification_launch_listener.dart';
import 'package:tankstellen/core/notifications/notification_payload.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_first_frame_boxes.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/widgets/shimmer_placeholder.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/consent/presentation/screens/gdpr_consent_screen.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/setup/presentation/screens/onboarding_wizard_screen.dart';
import 'package:tankstellen/features/station_detail/presentation/screens/station_detail_screen.dart';
import 'package:tankstellen/features/widget/providers/pending_widget_uri_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4318 — the first-frame box contract, EXECUTED route by route.
///
/// Real Hive files, real `HiveStorage`, the real router and real screens.
/// Before each route is pumped, ONLY the boxes in
/// `HiveFirstFrameBoxes.contract` are open — exactly what a cold start has
/// when the first frame is built. The only overrides are the ones no
/// storage decision depends on (locale, GPS, and — for deep links — the
/// station the detail screen shows).
///
/// Two kinds of evidence, because the stores degrade silently: a closed
/// favorites or cache box does not throw, it reads as EMPTY. So a kept box
/// is proven by seeding data, showing it on the first frame, and showing
/// it MISSING when that one box is closed — the empty-state flash deferring
/// it would introduce. A deferred box is proven by the route rendering
/// correctly without it being open beforehand.
///
/// Route matrix: fresh install → consent; incomplete setup → wizard;
/// search landing; favorites landing (narrow + wide); home-widget station
/// deep link; notification deep link. Map landing is left to the existing
/// landing tests: its first frame reads the same boxes as the search
/// landing (profile, settings, feature flags) plus network tiles.
/// Active-trip recovery does not change the first route: it runs
/// post-frame after `HiveBoxes.initDeferred()`, whose boxes are all
/// deferred ones.
class _English extends ActiveLanguage {
  @override
  AppLanguage build() => AppLanguages.all.first;
}

class _NoPosition extends UserPosition {
  @override
  UserPositionData? build() => null;
}

const _station = Station(
  id: 'st-4318',
  name: 'Kontrakt Tankstelle',
  brand: 'KONTRAKT',
  street: 'Ringstr.',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.40,
  e10: 1.799,
  isOpen: true,
);

/// A search result holding [_station], so the detail provider serves it
/// from its cache fast path instead of the network.
class _SearchHoldsStation extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      AsyncValue.data(ServiceResult(
        data: const [FuelStationResult(_station)],
        source: ServiceSource.cache,
        fetchedAt: DateTime.utc(2026, 9, 16),
      ));
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('first_frame_routes_');
    Hive.init(dir.path);
    HiveOpenTiming.reset();
    HiveDeferredUserBoxes.resetForTest();
    await HiveFirstFrameBoxes.openAll(null);
  });

  tearDown(() async {
    HiveDeferredUserBoxes.resetForTest();
    // A widget test can leave a Hive write pending on the fake clock; a
    // hung close must not hang the suite.
    try {
      await Hive.close().timeout(const Duration(seconds: 2));
    } on TimeoutException catch (e) {
      debugPrint('first_frame_route_matrix: close timed out ($e)');
    }
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException catch (e) {
        debugPrint('first_frame_route_matrix: temp cleanup skipped ($e)');
      }
    }
  });

  final storage = HiveStorage();

  Future<void> consentGiven() async {
    await storage.putSetting(StorageKeys.gdprConsentGiven, true);
    await storage.putSetting(
        StorageKeys.consentPolicyVersion, AppConstants.privacyPolicyVersion);
  }

  Future<void> readyWithLanding(String landing) async {
    await consentGiven();
    await storage.putSetting(StorageKeys.setupSkipped, true);
    await storage.putSetting(StorageKeys.swipeTutorialShown, true);
    await storage.saveProfile('p1', {
      'id': 'p1',
      'name': 'Test',
      'preferredFuelType': 'e10',
      'defaultSearchRadius': 10.0,
      'landingScreen': landing,
    });
    await storage.setActiveProfileId('p1');
  }

  Future<void> closeBox(String name) => Hive.box<dynamic>(name).close();

  /// Pumps the real router over [container] and lets the first route
  /// settle. Returns nothing; assertions read the tree.
  Future<ProviderContainer> launch(
    WidgetTester tester, {
    List<Override> overrides = const [],
    bool wide = false,
    void Function(ProviderContainer container)? beforeFirstFrame,
  }) async {
    // What a cold start has open when the first frame is built — the
    // contract, and nothing the #4318 deferral took out of it.
    for (final name in HiveDeferredUserBoxes.names) {
      expect(Hive.isBoxOpen(name), isFalse, reason: '$name opened too early');
    }
    expect(Hive.isBoxOpen(HiveBoxes.isolateErrorSpool), isFalse);

    tester.view.physicalSize =
        // Below the 600 dp split, so "narrow" really is the phone layout.
        wide ? const Size(1400, 900) : const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      activeLanguageProvider.overrideWith(_English.new),
      userPositionProvider.overrideWith(_NoPosition.new),
      ...overrides,
    ]);
    beforeFirstFrame?.call(container);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    return container;
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    tester.takeException();
    container.dispose();
  }

  group('onboarding routes', () {
    testWidgets('fresh install → consent', (tester) async {
      final c = await launch(tester);
      expect(find.byType(GdprConsentScreen), findsOneWidget);
      await unmount(tester, c);
    });

    testWidgets('consent given, setup incomplete → setup wizard',
        (tester) async {
      await tester.runAsync(consentGiven);
      final c = await launch(tester);
      expect(find.byType(OnboardingWizardScreen), findsOneWidget);
      await unmount(tester, c);
    });
  });

  group('landing routes', () {
    testWidgets('search landing builds with the contract boxes only',
        (tester) async {
      await tester.runAsync(() => readyWithLanding('nearest'));
      final c = await launch(tester);
      expect(find.byType(SearchScreen), findsOneWidget);
      await unmount(tester, c);
    });

    Future<void> seedFavorite() async {
      await storage.setFavoriteIds([_station.id]);
      await storage.saveFavoriteStationData(_station.id, _station.toJson());
    }

    testWidgets('favorites landing lists the stored favorite on its first '
        'frame', (tester) async {
      await tester.runAsync(() async {
        await readyWithLanding('favorites');
        await seedFavorite();
      });
      final c = await launch(tester);
      expect(find.byType(FavoritesScreen), findsOneWidget);
      // The favorite card leads with the brand.
      expect(find.text(_station.brand), findsWidgets);
      await unmount(tester, c);
    });

    testWidgets('KEEP favorites — without it the same launch shows an empty '
        'favorites list (the flash deferring it would cause)', (tester) async {
      await tester.runAsync(() async {
        await readyWithLanding('favorites');
        await seedFavorite();
        await closeBox(HiveBoxes.favorites);
      });
      final c = await launch(tester);
      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text(_station.brand), findsNothing);
      await unmount(tester, c);
    });

    Future<void> seedAlert() => storage.saveAlerts([
          PriceAlert(
            id: 'a1',
            stationId: _station.id,
            stationName: 'Alarm Tankstelle',
            fuelType: FuelType.e10,
            targetPrice: 1.5,
            createdAt: DateTime.utc(2026, 9, 1),
          ).toJson(),
        ]);

    testWidgets('favorites landing on a wide screen shows the stored alert '
        'beside the list on its first frame', (tester) async {
      await tester.runAsync(() async {
        await readyWithLanding('favorites');
        await seedAlert();
      });
      final c = await launch(tester, wide: true);
      expect(find.text('Alarm Tankstelle'), findsOneWidget);
      await unmount(tester, c);
    });

    testWidgets('KEEP alerts — without it the wide favorites landing loses '
        'the alert pane content', (tester) async {
      await tester.runAsync(() async {
        await readyWithLanding('favorites');
        await seedAlert();
        await closeBox(HiveBoxes.alerts);
      });
      final c = await launch(tester, wide: true);
      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('Alarm Tankstelle'), findsNothing);
      await unmount(tester, c);
    });
  });

  group('KEEP cache — the landing auto-search reads it cache-first', () {
    test('a stored entry is a hit with the box open and a SILENT miss with '
        'it closed', () async {
      final cache = CacheManager(storage);
      await cache.put('4318:probe', {'price': 1.799},
          ttl: const Duration(hours: 1), source: ServiceSource.tankerkoenigApi);
      expect(cache.get('4318:probe'), isNotNull);

      await closeBox(HiveBoxes.cache);
      expect(cache.get('4318:probe'), isNull,
          reason: 'no error, no retry — a search that starts on the first '
              'post-frame callback, before a deferred open finished, would '
              'wait on the network for prices the device already holds');
    });
  });

  group('deep links reach the station detail without priceHistory being '
      'opened before launch', () {
    final overrides = <Override>[
      searchStateProvider.overrideWith(_SearchHoldsStation.new),
    ];

    /// Arms the deferred boxes with an opener the test releases. The gate
    /// logic (single flight, the detail waiting) runs in the widget test's
    /// fake zone; the real `Hive.openBox` must run outside it, or its file
    /// I/O never completes (a hang, not a failure).
    late int opens;
    late Completer<Box<dynamic>> opened;

    void armHeldOpener() {
      opens = 0;
      opened = Completer<Box<dynamic>>();
      HiveDeferredUserBoxes.arm(null);
      HiveDeferredUserBoxes.opener = (name, cipher) {
        opens++;
        return opened.future;
      };
    }

    Future<void> releaseRealOpen(WidgetTester tester) => tester.runAsync(
        () async => opened.complete(await Hive.openBox<dynamic>(
            HiveBoxes.priceHistory)));

    Future<void> expectHeldOnShimmer(WidgetTester tester) async {
      // A push is applied by the router on the following frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(StationDetailScreen), findsOneWidget);
      expect(find.byType(ShimmerStationDetail), findsOneWidget,
          reason: 'the detail must not render its price-history rows '
              'before the box is open — no row appearing late');
      expect(find.text(_station.brand), findsNothing);
      expect(opens, 1);
    }

    Future<void> expectDetailRendered(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(StationDetailScreen), findsOneWidget);
      expect(find.byType(ShimmerStationDetail), findsNothing);
      expect(Hive.isBoxOpen(HiveBoxes.priceHistory), isTrue);
      expect(opens, 1, reason: 'one open, however many readers asked');
    }

    testWidgets('home-widget station deep link', (tester) async {
      await tester.runAsync(() => readyWithLanding('nearest'));
      armHeldOpener();
      final c = await launch(tester,
          overrides: overrides,
          beforeFirstFrame: (c) => c
              .read(pendingWidgetUriProvider.notifier)
              .set(Uri.parse('tankstellenwidget://station?id=${_station.id}')));
      await expectHeldOnShimmer(tester);

      await releaseRealOpen(tester);
      await expectDetailRendered(tester);
      await unmount(tester, c);
    });

    testWidgets('notification deep link', (tester) async {
      await tester.runAsync(() => readyWithLanding('nearest'));
      armHeldOpener();
      final c = await launch(tester, overrides: overrides);
      c.read(notificationLaunchHandlerProvider).handle(NotificationPayload(
            kind: NotificationPayload.kindRadius,
            stationId: _station.id,
            country: 'de',
          ).encode());
      await expectHeldOnShimmer(tester);

      await releaseRealOpen(tester);
      await expectDetailRendered(tester);
      await unmount(tester, c);
    });
  });
}
