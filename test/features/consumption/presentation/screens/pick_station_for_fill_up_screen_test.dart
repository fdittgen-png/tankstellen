import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/presentation/screens/'
    'pick_station_for_fill_up_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Station picker that owns the station-first fill-up flow (#715).
///
/// Tests drive:
/// - empty state when the user has no favorites
/// - a single favorite tile renders + is tappable
/// - tapping pushes /consumption/add with stationId + name + price
/// - the Skip button pushes /consumption/add with no context
void main() {
  group('PickStationForFillUpScreen (#715)', () {
    testWidgets('shows empty state message when no favorites', (tester) async {
      await _pumpPicker(tester, favorites: const []);
      expect(
        find.textContaining('No favorite stations'),
        findsOneWidget,
      );
    });

    testWidgets('renders a tile per favorite station', (tester) async {
      await _pumpPicker(tester, favorites: [_superUJson(), _carrefourJson()]);
      expect(find.text('SUPER U'), findsOneWidget);
      expect(find.text('Carrefour'), findsOneWidget);
    });

    testWidgets(
        'tapping a station navigates to /consumption/add with station data',
        (tester) async {
      await _pumpPicker(tester, favorites: [_superUJson()]);
      await tester.tap(find.byKey(const Key('pick_station_tile_super-u-1')));
      await tester.pumpAndSettle();
      expect(_lastRoute, '/consumption/add');
      expect(_lastExtra, isA<Map>());
      final extra = _lastExtra as Map;
      expect(extra['stationId'], 'super-u-1');
      expect(extra['stationName'], 'SUPER U');
    });

    testWidgets('Skip button navigates to /consumption/add with no context',
        (tester) async {
      await _pumpPicker(tester, favorites: const []);
      await tester.tap(find.byKey(const Key('pick_station_skip')));
      await tester.pumpAndSettle();
      expect(_lastRoute, '/consumption/add');
      expect(_lastExtra, isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

String? _lastRoute;
Object? _lastExtra;

Future<void> _pumpPicker(
  WidgetTester tester, {
  required List<Map<String, dynamic>> favorites,
}) async {
  _lastRoute = null;
  _lastExtra = null;

  final storage = _FakeStorage(favorites: favorites);
  final router = GoRouter(
    initialLocation: '/consumption/pick-station',
    routes: [
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const PickStationForFillUpScreen(),
      ),
      GoRoute(
        path: '/consumption/add',
        builder: (context, state) {
          _lastRoute = '/consumption/add';
          _lastExtra = state.extra;
          return const Scaffold(body: Text('add-fill-up-stub'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(storage),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _superUJson() => {
      'id': 'super-u-1',
      'name': 'Super U Pomerols',
      'brand': 'SUPER U',
      'street': 'Chemin du Portrou',
      'postCode': '34810',
      'place': 'POMEROLS',
      'lat': 43.37,
      'lng': 3.49,
      'e10': 1.999,
      'isOpen': true,
    };

Map<String, dynamic> _carrefourJson() => {
      'id': 'carrefour-1',
      'name': 'Carrefour Marseillan',
      'brand': 'Carrefour',
      'street': 'Rue des Oliviers',
      'postCode': '34340',
      'place': 'MARSEILLAN',
      'lat': 43.35,
      'lng': 3.52,
      'e5': 2.028,
      'isOpen': true,
    };

class _FakeStorage implements StorageRepository {
  final List<Map<String, dynamic>> favorites;
  _FakeStorage({required this.favorites});

  @override
  List<String> getFavoriteIds() =>
      favorites.map((f) => f['id'] as String).toList();

  @override
  Map<String, dynamic>? getFavoriteStationData(String id) {
    for (final f in favorites) {
      if (f['id'] == id) return f;
    }
    return null;
  }

  // ---- everything else returns a benign default ----
  // The picker also watches activeProfileProvider, which cascades into
  // getActiveProfileId + getProfile; return null so the test doesn't
  // require a profile fixture.
  @override
  String? getActiveProfileId() => null;
  @override
  Map<String, dynamic>? getProfile(String id) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null for any other read/bool method — the picker never
    // calls mutating methods so this is safe.
    return null;
  }
}
