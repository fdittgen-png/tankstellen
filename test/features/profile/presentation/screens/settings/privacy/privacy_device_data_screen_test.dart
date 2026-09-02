// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_blocked_users_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_device_data_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy/cache_details_tile.dart';
import 'package:tankstellen/features/profile/presentation/widgets/storage_bar.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../../fakes/fake_hive_storage.dart';
import '../../../../../../helpers/pump_app.dart';

/// #3910 (Epic #3907) — "Data on this device": the one inventory list.
void main() {
  late FakeHiveStorage storage;

  setUp(() {
    storage = FakeHiveStorage();
    unawaited(storage.setFavoriteIds(['f1', 'f2']));
    unawaited(storage.saveProfile('p1', {'name': 'p1'}));
    for (var i = 0; i < 3; i++) {
      unawaited(storage.cacheData('k$i', {'v': i}));
    }
    unawaited(storage.putSetting(
        StorageKeys.blockedContentAuthorIds, ['user-alice']));
    storage.statsOverride = (box) => switch (box) {
          'settings' => 256,
          'profiles' => 512,
          'favorites' => 128,
          'cache' => 3072,
          _ => 0,
        };
  });

  Future<AppLocalizations> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      const PrivacyDeviceDataScreen(),
      overrides: [hiveStorageProvider.overrideWithValue(storage)],
    );
    return AppLocalizations.of(
        tester.element(find.byType(PrivacyDeviceDataScreen)));
  }

  double top(WidgetTester tester, String kind) =>
      tester.getTopLeft(find.byKey(Key('deviceDataRow_$kind'))).dy;

  testWidgets('storage bar on top, one row per category with count + size, '
      'total line', (tester) async {
    final l = await pump(tester);
    expect(find.byType(StorageBar), findsOneWidget);
    expect(find.byKey(const Key('storage_bar_legend')), findsOneWidget);

    expect(find.text(l.favorites), findsAtLeast(1));
    expect(find.byKey(const Key('deviceDataCount_favorites')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const Key('deviceDataCount_favorites')))
            .data,
        '2');
    expect(find.text(l.privacyCacheResponses(3)), findsAtLeast(1));
    expect(find.byKey(const Key('deviceDataRow_blockedUsers')), findsOneWidget);
    expect(find.byKey(const Key('deviceDataRow_settings')), findsOneWidget);
    expect(find.text(l.total), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('deviceDataTotal'))).data,
        formatBytes(storage.storageStats.total));
    // No show/hide-empty-rows toggle anymore.
    expect(find.byKey(const Key('privacyShowAllRowsToggle')), findsNothing);
  });

  testWidgets('empty categories are greyed and sorted after the non-empty '
      'ones', (tester) async {
    await pump(tester);
    // Non-empty: favorites, profiles, blocked users, cache, settings.
    // Empty: ratings, alerts, price history, ignored, itineraries.
    for (final full in ['favorites', 'profiles', 'cache', 'settings']) {
      for (final empty in ['ratings', 'alerts', 'priceHistory', 'itineraries']) {
        expect(top(tester, full), lessThan(top(tester, empty)),
            reason: '$full must sit above the empty $empty row');
      }
    }
    final emptyTile = tester
        .widget<ListTile>(find.byKey(const Key('deviceDataRow_ratings')));
    expect(emptyTile.enabled, isFalse, reason: 'greyed');
    final fullTile = tester
        .widget<ListTile>(find.byKey(const Key('deviceDataRow_favorites')));
    expect(fullTile.enabled, isTrue);
  });

  testWidgets('the blocked-users row opens the block list with its Unblock '
      'action (#3871)', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('deviceDataRow_blockedUsers')));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyBlockedUsersScreen), findsOneWidget);
    expect(find.text('user-alice'), findsOneWidget);
    await tester.tap(find.byKey(const Key('blocked_author_unblock_user-alice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blocked_authors_empty')), findsOneWidget);
    expect(storage.getSetting(StorageKeys.blockedContentAuthorIds), <String>[]);
  });

  testWidgets('cache details are collapsed; expanding shows the TTL table '
      'and the clear-cache button', (tester) async {
    final l = await pump(tester);
    expect(find.byType(CacheDetailsTile), findsOneWidget);
    expect(find.text(l.privacyCacheDetails), findsOneWidget);
    expect(find.text(l.stationSearch), findsNothing, reason: 'collapsed');
    expect(find.byKey(const Key('privacyClearCacheButton')), findsNothing);

    await tester.tap(find.byKey(const Key('privacyCacheDetailsTile')));
    await tester.pumpAndSettle();
    expect(find.text(l.stationSearch), findsOneWidget);
    expect(find.text(l.privacyClearCacheEntries(3)), findsOneWidget);

    await tester.tap(find.byKey(const Key('privacyClearCacheButton')));
    await tester.pumpAndSettle();
    expect(find.text(l.clearCacheTitle), findsOneWidget);
    await tester.tap(find.text(l.clearCacheButton).last);
    await tester.pumpAndSettle();
    expect(storage.cacheEntryCount, 0);
    expect(find.text(l.cacheEmpty), findsOneWidget);
  });
}
