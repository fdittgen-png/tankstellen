import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorite_station_dismissible.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// One reusable station — kept tiny so test bodies focus on the swipe
/// gestures, not on station fields.
const _station = Station(
  id: 'fav-station-42',
  name: 'Shell Tankstelle',
  brand: 'Shell',
  street: 'Hauptstr.',
  houseNumber: '12',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.405,
  dist: 1.2,
  e5: 1.859,
  e10: 1.799,
  diesel: 1.659,
  isOpen: true,
);

/// Test fake for [UrlLauncherPlatform] — mirrors the pattern used in
/// `driving_station_sheet_test.dart` so the Dismissible swipe-right
/// path can pretend `geo:` URIs launched successfully without going
/// near a real platform channel.
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> launchedUrls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }
}

/// Test double for [Favorites]. Records `remove` / `add` so widget
/// tests can assert the swipe-left and undo paths invoked the right
/// notifier method with the right id, without driving real Hive
/// storage. Because `Favorites` is `keepAlive: true`, this override
/// stays alive for the whole test container.
class _RecordingFavorites extends Favorites {
  _RecordingFavorites([this._initial = const []]);

  final List<String> _initial;
  final List<String> removeCalls = <String>[];
  final List<({String id, Station? station})> addCalls = [];

  @override
  List<String> build() => _initial;

  @override
  Future<void> remove(String stationId) async {
    removeCalls.add(stationId);
  }

  @override
  Future<void> add(
    String stationId, {
    Station? stationData,
    Map<String, dynamic>? rawJson,
  }) async {
    addCalls.add((id: stationId, station: stationData));
  }
}

class _FixedProfile extends ActiveProfile {
  _FixedProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

/// Builds an override list around a custom [Favorites] notifier.
///
/// `standardTestOverrides` injects its own `favoritesProvider` override
/// via `favoritesOverride(...)` — Riverpod rejects two overrides for
/// the same provider, so tests that want a recording fake build the
/// overrides manually here. We replicate the same shared infra
/// (storage mock with no API key, fixed country DE, empty EV
/// favorites, sync disabled) so the dismissible has everything it
/// needs to render.
({List<Object> overrides, MockStorageRepository mockStorage})
    _overridesWithRecordingFavorites(_RecordingFavorites favorites) {
  // ignore: deprecated_member_use
  final storage = mockStorageRepositoryOverride();
  return (
    overrides: [
      storage.override,
      activeCountryOverride(Countries.germany),
      favoritesProvider.overrideWith(() => favorites),
      evFavoritesProvider.overrideWith(() => _EmptyEvFavorites()),
      syncStateProvider.overrideWith(() => _DisabledSyncState()),
    ],
    mockStorage: storage.mock,
  );
}

class _EmptyEvFavorites extends EvFavorites {
  @override
  List<String> build() => const [];
}

class _DisabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}

void main() {
  group('FavoriteStationDismissible', () {
    testWidgets('renders the inner StationCard for the supplied station',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: [_station.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const FavoriteStationDismissible(station: _station),
        overrides: test.overrides,
      );

      expect(find.byType(StationCard), findsOneWidget);
      // The StationCard is keyed with the station id so the parent ListView
      // can recycle tiles cleanly across rebuilds.
      final card = tester.widget<StationCard>(find.byType(StationCard));
      expect(card.station.id, _station.id);
      expect(card.isFavorite, isTrue);
      expect(card.selectedFuelType, FuelType.all);
    });

    testWidgets(
        'background widgets expose Navigate (swipe-right) and Remove '
        '(swipe-left) labels + icons during the corresponding drag',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: [_station.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const FavoriteStationDismissible(station: _station),
        overrides: test.overrides,
      );

      // Dismissible only inserts its `background` widgets into the
      // visible tree once a drag is in progress AND the move animation
      // is non-zero. We keep two gestures alive long enough for the
      // background Stack to render, then release them. `skipOffstage:
      // false` is added to the finders to keep them robust against the
      // Stack briefly hiding the layer behind a FractionalTranslation
      // before the next frame.

      // --- Swipe-right (Navigate background) ---
      final right = await tester.startGesture(
        tester.getCenter(find.byType(Dismissible)),
      );
      // Several incremental moves give the Dismissible time to flip
      // `_dragUnderway` and rebuild with the background Stack inserted.
      await right.moveBy(const Offset(40, 0));
      await tester.pump();
      await right.moveBy(const Offset(80, 0));
      await tester.pump();
      await right.moveBy(const Offset(80, 0));
      await tester.pump();

      expect(find.text('Navigate', skipOffstage: false), findsOneWidget);
      expect(find.byIcon(Icons.navigation, skipOffstage: false),
          findsOneWidget);

      // Drag back to the rest position so confirmDismiss won't fire
      // when we release.
      await right.moveBy(const Offset(-200, 0));
      await tester.pump();
      await right.up();
      await tester.pumpAndSettle();

      // --- Swipe-left (Remove background) ---
      final left = await tester.startGesture(
        tester.getCenter(find.byType(Dismissible)),
      );
      await left.moveBy(const Offset(-40, 0));
      await tester.pump();
      await left.moveBy(const Offset(-80, 0));
      await tester.pump();
      await left.moveBy(const Offset(-80, 0));
      await tester.pump();

      expect(find.text('Remove', skipOffstage: false), findsOneWidget);
      expect(find.byIcon(Icons.delete, skipOffstage: false), findsOneWidget);

      await left.moveBy(const Offset(200, 0));
      await tester.pump();
      await left.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'swipe-right launches a geo: URI and the StationCard stays in the '
        'tree because confirmDismiss returns false', (tester) async {
      final fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;

      final test = standardTestOverrides(favoriteIds: [_station.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const FavoriteStationDismissible(station: _station),
        overrides: test.overrides,
      );

      await tester.fling(
        find.byType(Dismissible),
        const Offset(500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Navigate path: a geo: URI was launched with the station coordinates
      // and the brand label encoded as the place name.
      expect(fake.launchedUrls, isNotEmpty);
      final launched = fake.launchedUrls.first;
      expect(launched, startsWith('geo:'));
      expect(launched, contains('52.52'));
      expect(launched, contains('13.405'));
      expect(
        launched,
        contains(Uri.encodeComponent(_station.displayName)),
      );

      // Card stays mounted: confirmDismiss returns false so the Dismissible
      // animates back into place rather than removing the row.
      expect(find.byType(StationCard), findsOneWidget);
    });

    testWidgets(
        'swipe-left calls favorites.remove(id) and shows the localized '
        '"removed from favorites" snackbar', (tester) async {
      final favorites = _RecordingFavorites([_station.id]);
      final test = _overridesWithRecordingFavorites(favorites);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.isFavorite(any())).thenReturn(true);

      await pumpApp(
        tester,
        const FavoriteStationDismissible(station: _station),
        overrides: test.overrides,
      );

      await tester.fling(
        find.byType(Dismissible),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(favorites.removeCalls, [_station.id]);

      // Snackbar text is the en-locale `removedFromFavoritesName` template
      // with the station display name interpolated in.
      expect(
        find.text('${_station.displayName} removed from favorites'),
        findsOneWidget,
      );
      // Undo action is wired with the localized "Undo" label.
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets(
        'snackbar undo button calls favorites.add(id) with the original '
        'station data so the row can be restored verbatim', (tester) async {
      final favorites = _RecordingFavorites([_station.id]);
      final test = _overridesWithRecordingFavorites(favorites);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.isFavorite(any())).thenReturn(true);

      await pumpApp(
        tester,
        const FavoriteStationDismissible(station: _station),
        overrides: test.overrides,
      );

      await tester.fling(
        find.byType(Dismissible),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Press the undo action. Tapping the SnackBarAction triggers the
      // notifier's add() with both id and the original Station entity.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(favorites.addCalls, hasLength(1));
      expect(favorites.addCalls.single.id, _station.id);
      expect(favorites.addCalls.single.station, isNotNull);
      expect(favorites.addCalls.single.station!.id, _station.id);
    });

    testWidgets(
        'tapping the inner StationCard pushes /station/<id> via GoRouter',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: [_station.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      String? landedOn;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: FavoriteStationDismissible(station: _station),
            ),
          ),
          GoRoute(
            path: '/station/:id',
            builder: (_, state) {
              landedOn = '/station/${state.pathParameters['id']}';
              return Scaffold(
                body: Text('detail-${state.pathParameters['id']}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: test.overrides.cast(),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The StationCard wraps its body in a single InkWell whose onTap
      // is the pushed-by-the-dismissible /station/:id route. Tapping the
      // card itself exercises that path.
      await tester.tap(find.byType(StationCard));
      await tester.pumpAndSettle();

      expect(landedOn, '/station/${_station.id}');
      expect(find.text('detail-${_station.id}'), findsOneWidget);
    });

    testWidgets(
        'tapping the favorite-star inside StationCard fires '
        'favorites.remove(id)', (tester) async {
      final favorites = _RecordingFavorites([_station.id]);
      final test = _overridesWithRecordingFavorites(favorites);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.isFavorite(any())).thenReturn(true);

      await pumpApp(
        tester,
        const FavoriteStationDismissible(station: _station),
        overrides: test.overrides,
      );

      // The StationCard wires onFavoriteTap to the only IconButton it
      // renders — the favorite toggle inside the price column. Tapping
      // that exercises the dismissible's `onFavoriteTap` callback,
      // which routes to `favorites.remove(station.id)`.
      final iconButton = find.byType(IconButton);
      expect(iconButton, findsOneWidget,
          reason: 'StationCard should expose exactly one IconButton — '
              'the favorite toggle');

      await tester.tap(iconButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(favorites.removeCalls, [_station.id]);
    });

    testWidgets(
        'activeProfileProvider override flows through to '
        'StationCard.profileFuelType so the profile fuel highlight matches',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: [_station.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      const profile = UserProfile(
        id: 'p1',
        name: 'Test',
        preferredFuelType: FuelType.diesel,
      );

      await pumpApp(
        tester,
        const FavoriteStationDismissible(station: _station),
        overrides: [
          ...test.overrides,
          activeProfileProvider.overrideWith(() => _FixedProfile(profile)),
        ],
      );

      final card = tester.widget<StationCard>(find.byType(StationCard));
      expect(card.profileFuelType, FuelType.diesel);
    });
  });
}
