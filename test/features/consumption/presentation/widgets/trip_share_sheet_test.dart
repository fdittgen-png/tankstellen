// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/sync/trip_shares_sync.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_share_sheet.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Fake wire so the share sheet's create / list / revoke flows can be
/// driven without a live Supabase client (#2240). Records calls and
/// returns scripted results — mirrors the override-seam pattern used by
/// the OBD2 diagnostic share button and the trip-detail lazy fetch.
class _FakeWire extends TripShareWire {
  _FakeWire({
    this.shareResult = TripShareResult.shared,
    this.linkToken = 'tok-abc',
    List<TripShare>? initialShares,
  }) : shares = initialShares ?? <TripShare>[];

  final TripShareResult shareResult;
  final String? linkToken;
  List<TripShare> shares;

  final List<String> sharedEmails = [];
  final List<String> revokedIds = [];
  int createLinkCalls = 0;

  @override
  Future<TripShareResult> shareWithEmail(String tripId, String email) async {
    sharedEmails.add(email);
    return shareResult;
  }

  @override
  Future<String?> createShareLink(String tripId) async {
    createLinkCalls++;
    return linkToken;
  }

  @override
  Future<List<TripShare>> listSharesForTrip(String tripId) async => shares;

  @override
  Future<void> revoke(String shareId) async {
    revokedIds.add(shareId);
    shares = shares.where((s) => s.id != shareId).toList();
  }
}

void main() {
  tearDown(() {
    debugTripShareWireOverride = null;
    debugTripShareLinkSinkOverride = null;
  });

  Future<void> pumpSheet(WidgetTester tester, _FakeWire wire) async {
    debugTripShareWireOverride = wire;
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: TripShareSheet(tripId: 'trip-1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders title, email field and both share actions (en)',
      (tester) async {
    await pumpSheet(tester, _FakeWire());
    expect(find.text('Share this trip'), findsOneWidget);
    expect(find.byKey(const Key('trip_share_email_field')), findsOneWidget);
    expect(find.byKey(const Key('trip_share_send_button')), findsOneWidget);
    expect(find.byKey(const Key('trip_share_create_link_button')),
        findsOneWidget);
    // No shares yet → empty-state caption.
    expect(find.text('Not shared with anyone yet.'), findsOneWidget);
  });

  testWidgets('entering an email + tapping Share calls the wire and shows '
      'the success snackbar', (tester) async {
    final wire = _FakeWire();
    await pumpSheet(tester, wire);

    await tester.enterText(
        find.byKey(const Key('trip_share_email_field')), 'friend@example.com');
    await tester.tap(find.byKey(const Key('trip_share_send_button')));
    await tester.pumpAndSettle();

    expect(wire.sharedEmails, ['friend@example.com']);
    expect(find.text('Trip shared.'), findsOneWidget);
  });

  testWidgets('an unknown recipient surfaces the not-found message',
      (tester) async {
    final wire = _FakeWire(shareResult: TripShareResult.recipientNotFound);
    await pumpSheet(tester, wire);

    await tester.enterText(
        find.byKey(const Key('trip_share_email_field')), 'ghost@example.com');
    await tester.tap(find.byKey(const Key('trip_share_send_button')));
    await tester.pumpAndSettle();

    expect(find.text('No TankSync account uses that email.'), findsOneWidget);
  });

  testWidgets('Create share link mints a token, hands the link to the OS '
      'share sheet, and confirms', (tester) async {
    final wire = _FakeWire(linkToken: 'xyz789');
    ShareParams? captured;
    debugTripShareLinkSinkOverride = (params) async => captured = params;
    await pumpSheet(tester, wire);

    await tester.tap(find.byKey(const Key('trip_share_create_link_button')));
    await tester.pumpAndSettle();

    expect(wire.createLinkCalls, 1);
    expect(captured, isNotNull);
    // The minted token rides in the shared link text.
    expect(captured!.text, contains('xyz789'));
    expect(find.textContaining('Share link copied'), findsOneWidget);
  });

  testWidgets('existing shares render a revoke control that calls the wire',
      (tester) async {
    final wire = _FakeWire(initialShares: [
      const TripShare(
        id: 'share-1',
        tripId: 'trip-1',
        ownerId: 'owner',
        sharedWithId: 'recipient',
      ),
      const TripShare(
        id: 'share-2',
        tripId: 'trip-1',
        ownerId: 'owner',
        shareToken: 'tok-link',
      ),
    ]);
    await pumpSheet(tester, wire);

    // A direct share + an unclaimed link share are both listed.
    expect(find.text('An account'), findsOneWidget);
    expect(find.text('Share link (unclaimed)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trip_share_revoke_share-1')));
    await tester.pumpAndSettle();

    expect(wire.revokedIds, ['share-1']);
    expect(find.text('Share revoked.'), findsOneWidget);
    // The revoked direct share is gone; the link share remains.
    expect(find.text('An account'), findsNothing);
    expect(find.text('Share link (unclaimed)'), findsOneWidget);
  });
}
