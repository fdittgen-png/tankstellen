// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3870 (Epic #3865) — the two disclosed, switchable third-party flows:
// the map tile proxy (default on) and internet brand logos (default OFF).
// #3909 (Epic #3907) — rendered as rows with a short subtitle + info icon.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/providers/privacy_controls_provider.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/consent/presentation/widgets/privacy_control_rows.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fakes/fake_hive_storage.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late FakeHiveStorage storage;
  setUp(() {
    storage = FakeHiveStorage();
    AppConstants.tileProxyDisabledByUser = false;
  });
  tearDown(() => AppConstants.tileProxyDisabledByUser = false);

  Future<void> pump(WidgetTester tester) => pumpApp(
        tester,
        const SingleChildScrollView(child: PrivacyControlRows()),
        overrides: [hiveStorageProvider.overrideWithValue(storage)],
      );

  testWidgets('defaults: proxy on, internet logos off', (tester) async {
    await pump(tester);
    final proxy =
        tester.widget<Switch>(find.byKey(const Key('privacyTileProxySwitch')));
    final logos = tester
        .widget<Switch>(find.byKey(const Key('privacyRemoteLogosSwitch')));
    expect(proxy.value, isTrue);
    expect(logos.value, isFalse);
    expect(AppConstants.effectiveTileUrl, AppConstants.tileProxyUrl);
  });

  testWidgets('switching the proxy off persists and routes tiles OSM-direct',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('privacyTileProxySwitch')));
    await tester.pumpAndSettle();
    expect(storage.getSetting(StorageKeys.tileProxyEnabled), isFalse);
    expect(AppConstants.tileProxyDisabledByUser, isTrue);
    expect(AppConstants.effectiveTileUrl, AppConstants.osmTileUrl,
        reason: 'every map surface resolves through effectiveTileUrl');
  });

  testWidgets('switching internet logos on persists', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('privacyRemoteLogosSwitch')));
    await tester.pumpAndSettle();
    expect(storage.getSetting(StorageKeys.remoteBrandLogos), isTrue);
  });

  testWidgets('#3909 — the row shows the short subtitle; the info icon opens '
      'the full disclosure in a dialog', (tester) async {
    await pump(tester);
    final l = AppLocalizations.of(
        tester.element(find.byType(PrivacyControlRows)));
    expect(find.text(l.remoteLogosToggleShort), findsOneWidget);
    expect(find.text(l.remoteLogosToggleSubtitle), findsNothing);

    await tester.tap(find.byKey(const Key('privacyRemoteLogosInfo')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l.remoteLogosToggleSubtitle), findsOneWidget);
    expect(find.text(l.remoteLogosToggleTitle), findsNWidgets(2),
        reason: 'row title + dialog title');
  });

  test('the provider mirrors a stored opt-out into the tile resolver',
      () async {
    // A fresh container reading a stored `false` must flip the flag.
    await storage.putSetting(StorageKeys.tileProxyEnabled, false);
    final container = ProviderContainer(
        overrides: [hiveStorageProvider.overrideWithValue(storage)]);
    addTearDown(container.dispose);
    expect(container.read(tileProxyEnabledProvider), isFalse);
    expect(AppConstants.tileProxyDisabledByUser, isTrue);
  });
}
