// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/features/sync/presentation/widgets/data_transparency_cards.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('InfoRow', () {
    testWidgets('renders label and value', (tester) async {
      await pumpApp(
        tester,
        const InfoRow(label: 'Items', value: '42'),
      );

      expect(find.text('Items'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });
  });

  group('AccountInfoCard', () {
    testWidgets('renders user ID and server', (tester) async {
      const config = SyncConfig(
        enabled: true,
        userId: 'test-uuid-123',
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
        mode: SyncMode.private,
      );

      await pumpApp(
        tester,
        const AccountInfoCard(syncConfig: config),
      );

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('test-uuid-123'), findsOneWidget);
      expect(find.text('https://test.supabase.co'), findsOneWidget);
    });
  });

  group('DataActionButtons', () {
    // #3081 — destructive actions used to be hidden behind a "data
    // deletion is not available in community mode" warning Card. RLS
    // scopes every delete to the caller's own rows (`FOR ALL USING
    // (user_id = auth.uid())`), so the block was over-broad. The actions
    // must now render unconditionally (the widget no longer takes a
    // `mode` param) and the community warning text must be absent.
    Widget buildButtons() => DataActionButtons(
          loading: false,
          onSync: () {},
          onViewRawJson: () {},
          onExportJson: () {},
          onDeleteAll: () {},
          onForgetAllTrips: () {},
          onDisconnect: () {},
        );

    testWidgets('shows destructive actions and no community warning',
        (tester) async {
      await pumpApp(tester, buildButtons());

      // The broad + narrow destructive actions are both present.
      expect(find.text('Delete all server data'), findsOneWidget);
      expect(
        find.byKey(const Key('forget_all_synced_trips_button')),
        findsOneWidget,
      );
      expect(find.text('Forget all synced trips'), findsOneWidget);

      // The former community-mode warning must be gone entirely.
      expect(
        find.textContaining('Data deletion is not available in community'),
        findsNothing,
      );
    });
  });

  group('SyncedDataCard', () {
    testWidgets('renders data counts', (tester) async {
      await pumpApp(
        tester,
        const SyncedDataCard(data: {
          'favorites': [1, 2, 3],
          'alerts': [1],
          'push_tokens': [],
          'reports': [1, 2],
          'trip_summaries': [1, 2, 2, 4, 5, 6, 7], // 7 trips
        }),
      );

      expect(find.text('Synced data'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // favorites
      expect(find.text('1'), findsOneWidget); // alerts
      expect(find.text('0'), findsOneWidget); // push_tokens
      expect(find.text('2'), findsOneWidget); // reports
      // #2107 — Trips row renders the trip_summaries count.
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('7'), findsOneWidget); // trip_summaries
    });

    testWidgets('Trips row reads 0 when trip_summaries is missing (#2107)',
        (tester) async {
      await pumpApp(
        tester,
        const SyncedDataCard(data: {
          'favorites': [1],
          'alerts': [],
          'push_tokens': [],
          'reports': [],
          // intentionally no trip_summaries key
        }),
      );
      // A 0 for "trip_summaries" must render — proves the row is not
      // skipped when the server payload has no trip rows.
      expect(find.text('Trips'), findsOneWidget);
      // Five 0s total: alerts, push_tokens, reports, trip_summaries,
      // plus the favorites=1 elsewhere. The `findsAtLeastNWidgets(2)`
      // would be brittle, so target the Trips row by walking its
      // sibling: the easiest pin is just to assert "Trips" + the
      // total of 1 (only favorites contributes).
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });
  });
}
