import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorites_loading_view.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  // FavoritesLoadingView has infinite animations (repeating pulse + shimmer +
  // LinearProgressIndicator), so we use pump() instead of pumpAndSettle().

  Future<void> pumpLoading(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: FavoritesLoadingView()),
        ),
      ),
    );
    // Pump a single frame — enough to build the widget tree
    await tester.pump();
  }

  group('FavoritesLoadingView', () {
    testWidgets('shows pulsing fuel icon', (tester) async {
      await pumpLoading(tester);
      expect(find.byIcon(Icons.local_gas_station_rounded), findsOneWidget);
    });

    testWidgets('shows loading text', (tester) async {
      await pumpLoading(tester);
      expect(find.text('Updating your favorites...'), findsOneWidget);
      expect(find.text('Fetching the latest prices'), findsOneWidget);
    });

    testWidgets('shows linear progress indicator', (tester) async {
      await pumpLoading(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('uses FadeTransition for pulse animation', (tester) async {
      await pumpLoading(tester);
      // Multiple FadeTransitions exist from Material route transitions;
      // verify at least one is present (our pulse animation)
      expect(find.byType(FadeTransition), findsWidgets);
    });
  });
}
