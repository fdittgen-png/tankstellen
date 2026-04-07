import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../fixtures/stations.dart';
import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// Fixed ActiveLanguage notifier for testing.
class _FixedActiveLanguage extends ActiveLanguage {
  final AppLanguage _language;
  _FixedActiveLanguage(this._language);

  @override
  AppLanguage build() => _language;
}

/// Fixed SearchState returning empty data.
class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }
}

/// Fixed FavoriteStations returning empty data.
class _EmptyFavoriteStations extends FavoriteStations {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> loadAndRefresh() async {}
}

/// Pumps a full-screen widget in a MaterialApp with RTL forced.
///
/// Unlike the standard pumpApp helper, this wraps in MaterialApp directly
/// (no extra Scaffold) so screens that provide their own Scaffold get
/// correct AppBar / nav semantics. Text direction is forced to RTL.
Future<void> _pumpRtlScreen(
  WidgetTester tester,
  Widget child, {
  required List<Object> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  // Use a fixed pump duration to avoid infinite animation loops.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('RTL layout verification', () {
    // -----------------------------------------------------------------------
    // Core: Directionality propagation
    // -----------------------------------------------------------------------
    group('Directionality propagation', () {
      testWidgets('pumpRtlApp sets TextDirection.rtl in the widget tree',
          (tester) async {
        late TextDirection capturedDirection;

        await pumpRtlApp(
          tester,
          Builder(
            builder: (context) {
              capturedDirection = Directionality.of(context);
              return const SizedBox();
            },
          ),
        );

        expect(capturedDirection, TextDirection.rtl);
      });

      testWidgets('default pumpApp uses TextDirection.ltr', (tester) async {
        late TextDirection capturedDirection;

        await pumpApp(
          tester,
          Builder(
            builder: (context) {
              capturedDirection = Directionality.of(context);
              return const SizedBox();
            },
          ),
        );

        expect(capturedDirection, TextDirection.ltr);
      });
    });

    // -----------------------------------------------------------------------
    // StationCard in RTL
    // -----------------------------------------------------------------------
    group('StationCard RTL', () {
      testWidgets('renders without errors in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        // Card renders successfully
        expect(find.byType(StationCard), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('brand text is present in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        expect(find.text('STAR'), findsOneWidget);
      });

      testWidgets('favorite icon renders in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
            isFavorite: true,
            onFavoriteTap: () {},
          ),
        );

        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('Row children are laid out in reverse order for RTL',
          (tester) async {
        await pumpRtlApp(
          tester,
          StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
            isFavorite: false,
            onFavoriteTap: () {},
          ),
        );

        // In RTL, the favorite button (last in code) should appear on the
        // left side, and the status indicator (first in code) on the right.
        final starFinder = find.byIcon(Icons.star_border);
        final brandFinder = find.text('STAR');

        expect(starFinder, findsOneWidget);
        expect(brandFinder, findsOneWidget);

        final starX = tester.getCenter(starFinder).dx;
        final brandX = tester.getCenter(brandFinder).dx;

        // In RTL, the star (end of Row) is to the left of the brand text
        expect(starX, lessThan(brandX),
            reason: 'In RTL, trailing elements should appear on the left');
      });

      testWidgets('cheapest badge renders in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
            isCheapest: true,
          ),
        );

        expect(find.text('Cheapest'), findsOneWidget);
      });

      testWidgets('semantic label is present in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          StationCard(
            station: testStation,
            selectedFuelType: FuelType.e10,
          ),
        );

        expect(
          find.bySemanticsLabel(RegExp(r'STAR.*Hauptstr.*Open')),
          findsOneWidget,
        );
      });
    });

    // -----------------------------------------------------------------------
    // SortSelector in RTL
    // -----------------------------------------------------------------------
    group('SortSelector RTL', () {
      testWidgets('renders all chips in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          SortSelector(
            selected: SortMode.distance,
            onChanged: (_) {},
          ),
        );

        expect(find.text('Distance'), findsOneWidget);
        expect(find.text('Price'), findsOneWidget);
        expect(find.text('A-Z'), findsOneWidget);
      });

      testWidgets('chips are in reversed visual order for RTL', (tester) async {
        await pumpRtlApp(
          tester,
          SortSelector(
            selected: SortMode.distance,
            onChanged: (_) {},
          ),
        );

        final distanceX = tester.getCenter(find.text('Distance')).dx;
        final azX = tester.getCenter(find.text('A-Z')).dx;

        // In RTL, Distance (first in code) should be to the right of A-Z
        expect(distanceX, greaterThan(azX),
            reason: 'In RTL, first Row child should appear on the right');
      });

      testWidgets('selected chip state is correct in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          SortSelector(
            selected: SortMode.price,
            onChanged: (_) {},
          ),
        );

        // Verify the semantic label includes "selected" for price chip
        expect(
          find.bySemanticsLabel(RegExp(r'Sort by Price.*selected')),
          findsOneWidget,
        );
      });
    });

    // -----------------------------------------------------------------------
    // EmptyState in RTL
    // -----------------------------------------------------------------------
    group('EmptyState RTL', () {
      testWidgets('renders centered content in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          const EmptyState(
            icon: Icons.star_outline,
            title: 'No favorites yet',
            subtitle: 'Add stations to your favorites',
          ),
        );

        expect(find.text('No favorites yet'), findsOneWidget);
        expect(find.text('Add stations to your favorites'), findsOneWidget);
        expect(find.byIcon(Icons.star_outline), findsOneWidget);
      });

      testWidgets('action button renders in RTL', (tester) async {
        var tapped = false;
        await pumpRtlApp(
          tester,
          EmptyState(
            icon: Icons.search,
            title: 'Search for stations',
            actionLabel: 'Search now',
            onAction: () => tapped = true,
          ),
        );

        final button = find.text('Search now');
        expect(button, findsOneWidget);

        await tester.tap(button);
        expect(tapped, isTrue);
      });

      testWidgets('icon and title are vertically centered in RTL',
          (tester) async {
        await pumpRtlApp(
          tester,
          const EmptyState(
            icon: Icons.star_outline,
            title: 'Test title',
          ),
        );

        // Icon and title should be horizontally centered (same center X)
        final iconCenter = tester.getCenter(find.byIcon(Icons.star_outline));
        final textCenter = tester.getCenter(find.text('Test title'));

        // Allow small tolerance for text alignment differences
        expect((iconCenter.dx - textCenter.dx).abs(), lessThan(2.0),
            reason: 'Icon and title should be horizontally centered in RTL');
      });
    });

    // -----------------------------------------------------------------------
    // Full screen: SearchScreen in RTL
    // -----------------------------------------------------------------------
    group('SearchScreen RTL', () {
      List<Object> _overrides() {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);
        return [
          ...test.overrides,
          activeLanguageProvider
              .overrideWith(() => _FixedActiveLanguage(AppLanguages.all.first)),
          userPositionNullOverride(),
          searchStateProvider.overrideWith(() => _EmptySearchState()),
        ];
      }

      testWidgets('SearchScreen renders without errors in RTL', (tester) async {
        await _pumpRtlScreen(
          tester,
          const SearchScreen(),
          overrides: _overrides(),
        );

        expect(find.byType(SearchScreen), findsOneWidget);
      });

      testWidgets('SearchScreen AppBar is present in RTL', (tester) async {
        await _pumpRtlScreen(
          tester,
          const SearchScreen(),
          overrides: _overrides(),
        );

        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Full screen: FavoritesScreen in RTL
    // -----------------------------------------------------------------------
    group('FavoritesScreen RTL', () {
      List<Object> _overrides() {
        final test = standardTestOverrides(favoriteIds: []);
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);
        return [
          ...test.overrides,
          favoriteStationsProvider
              .overrideWith(() => _EmptyFavoriteStations()),
        ];
      }

      testWidgets('FavoritesScreen renders without errors in RTL',
          (tester) async {
        await _pumpRtlScreen(
          tester,
          const FavoritesScreen(),
          overrides: _overrides(),
        );

        expect(find.byType(FavoritesScreen), findsOneWidget);
      });

      testWidgets('FavoritesScreen empty state is present in RTL',
          (tester) async {
        await _pumpRtlScreen(
          tester,
          const FavoritesScreen(),
          overrides: _overrides(),
        );

        expect(find.byIcon(Icons.star_outline), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // RTL-specific layout concerns
    // -----------------------------------------------------------------------
    group('RTL-specific alignment checks', () {
      testWidgets('CrossAxisAlignment.start aligns to the right in RTL',
          (tester) async {
        await pumpRtlApp(
          tester,
          const SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aligned text'),
              ],
            ),
          ),
        );

        final textRect = tester.getRect(find.text('Aligned text'));
        final parentRect = tester.getRect(find.byType(SizedBox).first);

        // In RTL, start alignment means right-aligned
        expect(textRect.right, closeTo(parentRect.right, 1.0),
            reason:
                'CrossAxisAlignment.start should align right edge in RTL');
      });

      testWidgets('Row reverses children order in RTL', (tester) async {
        await pumpRtlApp(
          tester,
          const Row(
            children: [
              Text('First'),
              SizedBox(width: 20),
              Text('Second'),
              SizedBox(width: 20),
              Text('Third'),
            ],
          ),
        );

        final firstX = tester.getCenter(find.text('First')).dx;
        final secondX = tester.getCenter(find.text('Second')).dx;
        final thirdX = tester.getCenter(find.text('Third')).dx;

        // In RTL: First should be rightmost, Third should be leftmost
        expect(firstX, greaterThan(secondX));
        expect(secondX, greaterThan(thirdX));
      });

      testWidgets(
          'EdgeInsetsDirectional respects RTL (start = right, end = left)',
          (tester) async {
        await pumpRtlApp(
          tester,
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 50),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('Padded text'),
            ),
          ),
        );

        final textRect = tester.getRect(find.text('Padded text'));
        // In RTL, start padding is on the right, so text left edge should
        // be near 0 and right edge should be away from the screen right edge.
        // The 50px start padding in RTL means 50px from the right.
        final screenWidth = tester.view.physicalSize.width /
            tester.view.devicePixelRatio;

        expect(textRect.right, lessThanOrEqualTo(screenWidth - 50 + 1),
            reason: 'Start padding in RTL should push content from the right');
      });
    });
  });
}
