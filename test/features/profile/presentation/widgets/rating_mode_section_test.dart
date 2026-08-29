// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/profile/presentation/widgets/rating_mode_section.dart';

import '../../../../helpers/pump_app.dart';

/// #3871 — switching station ratings to "shared" is a public
/// contribution: the first switch shows the one-time notice, Cancel
/// keeps the previous mode, Continue applies it and never asks again.
void main() {
  Future<({_MemorySettings settings, List<String> changes})> pumpSection(
    WidgetTester tester, {
    String ratingMode = 'local',
    bool noticeAccepted = false,
  }) async {
    final settings = _MemorySettings();
    if (noticeAccepted) {
      settings.values[StorageKeys.ugcPublicNoticeShown] = true;
    }
    final changes = <String>[];
    await pumpApp(
      tester,
      RatingModeSection(ratingMode: ratingMode, onChanged: changes.add),
      overrides: [settingsStorageProvider.overrideWithValue(settings)],
    );
    return (settings: settings, changes: changes);
  }

  testWidgets('switching to private never shows the notice', (tester) async {
    final t = await pumpSection(tester);

    await tester.tap(find.text('Private'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ugc_public_notice_dialog')), findsNothing);
    expect(t.changes, ['private']);
  });

  testWidgets('first switch to shared shows the notice; Cancel keeps the '
      'previous mode', (tester) async {
    final t = await pumpSection(tester);

    await tester.tap(find.text('Shared'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ugc_public_notice_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ugc_public_notice_cancel')));
    await tester.pumpAndSettle();

    expect(t.changes, isEmpty, reason: 'Cancel must not change the mode');
    expect(t.settings.values.containsKey(StorageKeys.ugcPublicNoticeShown),
        isFalse);
  });

  testWidgets('Continue applies shared and persists the accepted flag',
      (tester) async {
    final t = await pumpSection(tester);

    await tester.tap(find.text('Shared'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ugc_public_notice_continue')));
    await tester.pumpAndSettle();

    expect(t.changes, ['shared']);
    expect(t.settings.values[StorageKeys.ugcPublicNoticeShown], isTrue);
  });

  testWidgets('once accepted, switching to shared asks no more',
      (tester) async {
    final t = await pumpSection(tester, noticeAccepted: true);

    await tester.tap(find.text('Shared'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ugc_public_notice_dialog')), findsNothing);
    expect(t.changes, ['shared']);
  });
}

class _MemorySettings implements SettingsStorage {
  final Map<String, dynamic> values = {};

  @override
  dynamic getSetting(String key) => values[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    values[key] = value;
  }

  @override
  bool get isSetupComplete => true;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
