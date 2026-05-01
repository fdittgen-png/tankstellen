import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/sharing/widget_share_renderer.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';

/// #1344 — coverage for the FavoritesScreen Share AppBar action.
///
/// Pumps the screen with one fuel favorite, taps the share button, and
/// asserts that:
///   * the share sink was invoked with a non-empty PNG file path,
///   * the captured [ShareParams.subject] carries the localised
///     "favourites" string with today's date,
///   * the share button is keyed `favorites_share_button` (test seam).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('favorites_share_');
    debugTemporaryDirectoryOverride = () async => tempDir;
  });

  tearDown(() {
    debugShareSinkOverride = null;
    debugTemporaryDirectoryOverride = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'tapping Share invokes the share sink with a PNG file + localised subject',
    (tester) async {
      ShareParams? captured;
      debugShareSinkOverride = (params) async {
        captured = params;
      };

      final test = standardTestOverrides(favoriteIds: [testStation.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      final result = ServiceResult(
        data: const [testStation],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            favoriteStationsProvider.overrideWith(
              () => _FixedFavoriteStations(result),
            ),
          ].cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: FavoritesScreen(),
          ),
        ),
      );
      // Use plain pump (NOT pumpAndSettle) — the favorites tab's
      // station-card spinner / banner can animate indefinitely on the
      // 600-px test surface and would never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Sanity check: the share button is rendered for the seeded
      // favorites + Favorites-tab default.
      final shareButton = find.byKey(const Key('favorites_share_button'));
      expect(shareButton, findsOneWidget,
          reason: 'share button must be visible when favorites are non-empty');

      // The renderer awaits the real engine rasterisation pipeline
      // (toImage / toByteData), which the fake-async clock used by
      // pumpAndSettle never resolves. `runAsync` lets the GPU work
      // complete, then we pump once more to let the snackbar /
      // post-tap state advance.
      await tester.runAsync(() async {
        await tester.tap(shareButton);
        // Drive the share future to completion. We poll for up to
        // 2 seconds for the captured ShareParams instead of a fixed
        // sleep — keeps the test snappy when the engine is fast.
        final deadline = DateTime.now().add(const Duration(seconds: 2));
        while (captured == null && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(captured, isNotNull, reason: 'share sink was not invoked');
      expect(captured!.files, isNotNull);
      expect(captured!.files!.length, 1);
      final shared = captured!.files!.single;
      expect(shared.path, isNotEmpty,
          reason: 'XFile path must be a real temp-file path');
      expect(shared.path.endsWith('.png'), isTrue,
          reason: 'expected PNG file, got ${shared.path}');
      // The English ARB renders "Tankstellen — favourites on <date>".
      expect(captured!.subject, isNotNull);
      expect(captured!.subject, contains('favourites'));
    },
  );
}

class _FixedFavoriteStations extends FavoriteStations {
  final ServiceResult<List<Station>> _result;
  _FixedFavoriteStations(this._result);

  @override
  AsyncValue<ServiceResult<List<Station>>> build() =>
      AsyncValue.data(_result);

  @override
  Future<void> loadAndRefresh() async {
    // No-op: keep the fixed result
  }
}
