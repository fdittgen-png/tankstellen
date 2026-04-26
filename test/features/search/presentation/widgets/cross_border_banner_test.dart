import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/features/search/domain/entities/cross_border_suggestion.dart';
import 'package:tankstellen/features/search/presentation/widgets/cross_border_banner.dart';
import 'package:tankstellen/features/search/providers/cross_border_suggestion_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('CrossBorderBanner', () {
    testWidgets('shows nothing when suggestion is null', (tester) async {
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderSuggestionProvider
              .overrideWith((ref) async => null),
        ],
      );

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows nothing while suggestion is loading', (tester) async {
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderSuggestionProvider.overrideWith((ref) {
            // Never-completing future keeps the AsyncValue in `loading`.
            return Completer<CrossBorderSuggestion?>().future;
          }),
        ],
      );

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders headline + flag when suggestion exists',
        (tester) async {
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderSuggestionProvider.overrideWith(
            (ref) async => const CrossBorderSuggestion(
              neighborCountryCode: 'FR',
              neighborName: 'France',
              neighborFlag: '\u{1F1EB}\u{1F1F7}',
              distanceKm: 4.0,
              priceDeltaPerLiter: 0.12,
              sampleCount: 6,
            ),
          ),
        ],
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('\u{1F1EB}\u{1F1F7}'), findsOneWidget);
      expect(
        find.textContaining('France'),
        findsOneWidget,
      );
      expect(find.textContaining('0.12'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('dismiss button hides banner for that neighbor',
        (tester) async {
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderSuggestionProvider.overrideWith(
            (ref) async => const CrossBorderSuggestion(
              neighborCountryCode: 'FR',
              neighborName: 'France',
              neighborFlag: '\u{1F1EB}\u{1F1F7}',
              distanceKm: 4.0,
              priceDeltaPerLiter: 0.12,
              sampleCount: 6,
            ),
          ),
        ],
      );

      expect(find.byType(Card), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('hidden when suggestion neighbor is already dismissed',
        (tester) async {
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderSuggestionProvider.overrideWith(
            (ref) async => const CrossBorderSuggestion(
              neighborCountryCode: 'FR',
              neighborName: 'France',
              neighborFlag: '\u{1F1EB}\u{1F1F7}',
              distanceKm: 4.0,
              priceDeltaPerLiter: 0.12,
              sampleCount: 6,
            ),
          ),
          crossBorderBannerDismissedProvider
              .overrideWith(() => _PreDismissed({'FR'})),
        ],
      );

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('tap invokes country switch via ActiveCountry.select()',
        (tester) async {
      final spy = _SpyActiveCountry(Countries.germany);
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          activeCountryProvider.overrideWith(() => spy),
          // The banner's tap handler reads the user position to feed
          // searchByCoordinates; without one it returns early.
          userPositionProvider.overrideWith(
            () => _FixedUserPosition(49.23, 7.0),
          ),
          crossBorderSuggestionProvider.overrideWith(
            (ref) async => const CrossBorderSuggestion(
              neighborCountryCode: 'FR',
              neighborName: 'France',
              neighborFlag: '\u{1F1EB}\u{1F1F7}',
              distanceKm: 4.0,
              priceDeltaPerLiter: 0.12,
              sampleCount: 6,
            ),
          ),
        ],
      );

      // Tap the body of the card (not the dismiss icon).
      await tester.tap(find.text('\u{1F1EB}\u{1F1F7}'));
      // Don't pumpAndSettle — searchByCoordinates dispatches further
      // async work we don't care about here.
      await tester.pump();

      expect(spy.selectedCodes, contains('FR'));
    });
  });
}

class _PreDismissed extends CrossBorderBannerDismissed {
  final Set<String> _initial;
  _PreDismissed(this._initial);

  @override
  Set<String> build() => Set<String>.from(_initial);
}

class _FixedUserPosition extends UserPosition {
  final double _lat;
  final double _lng;
  _FixedUserPosition(this._lat, this._lng);

  @override
  UserPositionData? build() => UserPositionData(
        lat: _lat,
        lng: _lng,
        updatedAt: DateTime.now(),
        source: 'test',
      );
}

class _SpyActiveCountry extends ActiveCountry {
  final CountryConfig _initial;
  final List<String> selectedCodes = [];

  _SpyActiveCountry(this._initial);

  @override
  CountryConfig build() => _initial;

  @override
  Future<void> select(CountryConfig country) async {
    selectedCodes.add(country.code);
    state = country;
  }
}
