// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorite_station_dismissible.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3905 — the Favorites card flags a price whose upstream stamp is older
/// than `kStalePriceThreshold` (7 days), read through the AppClock seam.
void main() {
  const badge = Key('station_card_stale_price_badge');
  // Mid-month Wednesday (per the AppClock guidance) — no boundary lands.
  final now = DateTime(2026, 9, 16, 14, 30);

  Station station(String updatedAt) => Station(
        id: 'fav-stale-1',
        name: 'Total Montpellier',
        brand: 'TotalEnergies',
        street: 'Avenue de la Mer',
        postCode: '34000',
        place: 'Montpellier',
        lat: 43.6,
        lng: 3.88,
        dist: 1.2,
        diesel: 2.219,
        isOpen: true,
        updatedAt: updatedAt,
      );

  Future<void> pumpCard(WidgetTester tester, Station s) async {
    final test = standardTestOverrides(favoriteIds: [s.id]);
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    when(() => test.mockStorage.getSetting(any())).thenReturn(null);

    await pumpApp(
      tester,
      Material(child: FavoriteStationDismissible(station: s)),
      overrides: [
        ...test.overrides,
        activeProfileProvider.overrideWith(() => _NoProfile()),
        appClockProvider.overrideWithValue(FixedClock(now)),
      ],
    );
  }

  group('FavoriteStationDismissible stale-price badge', () {
    testWidgets('6-day-old price: no badge', (tester) async {
      final stamp = now.subtract(const Duration(days: 6)).toIso8601String();
      await pumpCard(tester, station(stamp));

      expect(find.byKey(badge), findsNothing);
      expect(find.text('Old price'), findsNothing);
    });

    testWidgets('8-day-old price: "Old price" badge shown', (tester) async {
      final stamp = now.subtract(const Duration(days: 8)).toIso8601String();
      await pumpCard(tester, station(stamp));

      expect(find.byKey(badge), findsOneWidget);
      expect(find.text('Old price'), findsOneWidget);
    });

    testWidgets('the year-less French "dd/MM HH:mm" stamp is read too',
        (tester) async {
      // "Mis à jour 16/07 11:00" seen in September — the reported case.
      await pumpCard(tester, station('16/07 11:00'));

      expect(find.byKey(badge), findsOneWidget);
    });
  });
}

class _NoProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}
