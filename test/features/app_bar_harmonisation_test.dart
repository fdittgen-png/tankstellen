import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/ev/presentation/widgets/ev_map_overlay.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// #1313 — every bottom-tab root (Recherche, Carte, Favoris, Conso) must
/// share the same compact PageScaffold AppBar shape. These tests pin
/// the props on each PageScaffold so a future regression that drops one
/// of them on a single screen is caught here rather than on a device.
class _FixedFillUpList extends FillUpList {
  @override
  List<FillUp> build() => const [];
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

void _assertCompactPageScaffold(
  WidgetTester tester,
  Type screenType,
) {
  final scaffold = tester.widget<PageScaffold>(
    find.descendant(
      of: find.byType(screenType),
      matching: find.byType(PageScaffold),
    ),
  );
  expect(
    scaffold.toolbarHeight,
    PageScaffold.compactToolbarHeight,
    reason: '$screenType must use the canonical compact toolbar height',
  );
  expect(
    scaffold.titleSpacing,
    PageScaffold.compactTitleSpacing,
    reason: '$screenType must use the canonical compact titleSpacing',
  );
  expect(
    scaffold.titleTextStyle,
    isNotNull,
    reason: '$screenType must override titleTextStyle (#1313)',
  );
  expect(
    scaffold.titleTextStyle!.fontSize,
    16,
    reason: '$screenType title fontSize must be 16',
  );
  expect(
    scaffold.titleTextStyle!.color,
    isNotNull,
    reason: '#1164 — titleTextStyle.color must be non-null',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom-tab AppBar harmonisation (#1313)', () {
    testWidgets(
      'MapScreen uses the canonical compact PageScaffold props',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

        _assertCompactPageScaffold(tester, MapScreen);
      },
    );

    testWidgets(
      'SearchScreen uses the canonical compact PageScaffold props',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          const SearchScreen(),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

        _assertCompactPageScaffold(tester, SearchScreen);
      },
    );

    testWidgets(
      'FavoritesScreen uses the canonical compact PageScaffold props',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          const FavoritesScreen(),
          overrides: test.overrides,
        );

        _assertCompactPageScaffold(tester, FavoritesScreen);
      },
    );

    testWidgets(
      'ConsumptionScreen uses the canonical compact PageScaffold props',
      (tester) async {
        await pumpApp(
          tester,
          const ConsumptionScreen(),
          overrides: [
            fillUpListProvider.overrideWith(() => _FixedFillUpList()),
            activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
          ],
        );

        _assertCompactPageScaffold(tester, ConsumptionScreen);
      },
    );
  });

  group('MapScreen AppBar actions (#1313)', () {
    testWidgets(
      'AppBar contains the EvToggleButton AND a refresh IconButton',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

        // EV toggle widget must be present in the tree.
        expect(
          find.byType(EvToggleButton),
          findsOneWidget,
          reason: '#1313 — EV toggle moved into MapScreen AppBar actions.',
        );
        // Refresh action must be present in the AppBar actions row.
        final refreshButton = find.descendant(
          of: find.byType(AppBar),
          matching: find.widgetWithIcon(IconButton, Icons.refresh),
        );
        expect(
          refreshButton,
          findsOneWidget,
          reason: '#1313 — Map AppBar must expose Icons.refresh.',
        );
      },
    );

    testWidgets(
      'EvToggleButton is NOT placed inside a Positioned overlay anymore',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

        // The legacy mount point was a `Positioned(left: 16, top: 16)`
        // wrapping the EvToggleButton. Asserting that no `Positioned`
        // ancestor wraps the toggle locks the new mount point in.
        final positionedAncestor = find.ancestor(
          of: find.byType(EvToggleButton),
          matching: find.byType(Positioned),
        );
        expect(
          positionedAncestor,
          findsNothing,
          reason: '#1313 — EV toggle must live in the AppBar, not in a '
              'floating Positioned overlay over the map tiles.',
        );
      },
    );
  });

  group('SearchScreen AppBar actions (#1313)', () {
    testWidgets(
      'AppBar contains a refresh IconButton',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          const SearchScreen(),
          overrides: [
            ...test.overrides,
            userPositionNullOverride(),
          ],
        );

        final refreshButton = find.descendant(
          of: find.byType(AppBar),
          matching: find.widgetWithIcon(IconButton, Icons.refresh),
        );
        expect(
          refreshButton,
          findsOneWidget,
          reason: '#1313 — Search AppBar must expose Icons.refresh.',
        );
      },
    );
  });
}
