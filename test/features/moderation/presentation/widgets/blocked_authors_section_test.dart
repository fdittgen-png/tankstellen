// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/moderation/api.dart';

import '../../../../helpers/pump_app.dart';

/// #3871 — the Privacy Dashboard "Blocked users" card: lists every
/// blocked author id, Unblock removes one (state + persisted list),
/// and an empty block list renders an explicit empty state.
void main() {
  Future<_MemorySettings> pumpSection(
    WidgetTester tester, {
    List<String> blocked = const [],
  }) async {
    final settings = _MemorySettings();
    if (blocked.isNotEmpty) {
      settings.values[StorageKeys.blockedContentAuthorIds] = blocked;
    }
    await pumpApp(
      tester,
      const SingleChildScrollView(child: BlockedAuthorsSection()),
      overrides: [settingsStorageProvider.overrideWithValue(settings)],
    );
    return settings;
  }

  testWidgets('lists every blocked author id with an Unblock button',
      (tester) async {
    await pumpSection(tester, blocked: ['user-bob', 'user-alice']);

    expect(find.text('Blocked users'), findsOneWidget);
    expect(find.text('user-alice'), findsOneWidget);
    expect(find.text('user-bob'), findsOneWidget);
    expect(find.text('Unblock'), findsNWidgets(2));
    expect(find.byKey(const Key('blocked_authors_empty')), findsNothing);
  });

  testWidgets('Unblock removes exactly that author and persists the rest',
      (tester) async {
    final settings =
        await pumpSection(tester, blocked: ['user-alice', 'user-bob']);

    await tester.tap(find.byKey(const Key('blocked_author_unblock_user-alice')));
    await tester.pumpAndSettle();

    expect(find.text('user-alice'), findsNothing);
    expect(find.text('user-bob'), findsOneWidget);
    expect(find.text('Unblock'), findsOneWidget);
    expect(
      settings.values[StorageKeys.blockedContentAuthorIds],
      ['user-bob'],
      reason: 'unblock must reach the persisted device-local list',
    );
  });

  testWidgets('unblocking the last author falls back to the empty state',
      (tester) async {
    await pumpSection(tester, blocked: ['user-alice']);

    await tester.tap(find.byKey(const Key('blocked_author_unblock_user-alice')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('blocked_authors_empty')), findsOneWidget);
    expect(find.text('No blocked users'), findsOneWidget);
    expect(find.text('Unblock'), findsNothing);
  });

  testWidgets('empty block list renders the empty state, card still shown',
      (tester) async {
    await pumpSection(tester);

    expect(find.byKey(const Key('blocked_authors_section')), findsOneWidget);
    expect(find.text('No blocked users'), findsOneWidget);
    expect(find.text('Unblock'), findsNothing);
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
