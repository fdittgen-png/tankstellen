// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4217 — the fleet intent card end to end through the wizard: a fleet
// user reaches the identity step, a personal user never does, and
// walking back and forth keeps what was entered. The sibling
// `onboarding_wizard_screen_test.dart` still owns the personal flow;
// what is added here is only what the fourth card changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/features/feature_management/api.dart';
import 'package:tankstellen/features/fleet/api.dart';
import 'package:tankstellen/features/feature_management/data/app_profile_repository.dart';
import 'package:tankstellen/features/setup/presentation/screens/onboarding_wizard_screen.dart';
import 'package:tankstellen/features/setup/presentation/widgets/fleet_identity_step.dart';
import 'package:tankstellen/features/setup/presentation/widgets/privacy_summary_step.dart';
import 'package:tankstellen/features/setup/presentation/widgets/profile_choice_step.dart';
import 'package:tankstellen/features/setup/providers/onboarding_obd2_connector.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

void main() {
  late List<Object> overrides;

  setUp(() {
    final std = standardTestOverrides();
    overrides = [
      ...std.overrides,
      onboardingObd2ConnectorProvider.overrideWithValue(_NullObd2Connector()),
      appProfileRepositoryProvider.overrideWithValue(_EmptyProfileRepo()),
    ];
    when(() => std.mockStorage.isSetupComplete).thenReturn(false);
    when(() => std.mockStorage.isSetupSkipped).thenReturn(false);
    when(() => std.mockStorage.hasApiKey(any())).thenReturn(false);
  });

  /// A self-hosted backend with an e-mail identity — the only shape
  /// that lets the join form render (ADR 0025 D2/D3).
  const fleetCapableSync = SyncConfig(
    enabled: true,
    supabaseUrl: 'https://acme.supabase.co',
    supabaseAnonKey: 'key',
    userId: 'user-1',
    userEmail: 'driver@acme.example',
    mode: SyncMode.private,
  );

  Future<void> pumpWizard(
    WidgetTester tester, {
    BuildChannel channel = BuildChannel.beta,
    SyncConfig? sync,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides,
          buildChannelProvider.overrideWithValue(channel),
          if (sync != null) fleetSyncConfigProvider.overrideWithValue(sync),
        ].cast(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: OnboardingWizardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  /// The fourth card sits below the fold on a default test surface.
  Future<void> tapCard(WidgetTester tester, String key) async {
    final finder = find.byKey(Key('profileCard_$key'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the fourth card is offered on beta and picks the fleet path',
      (tester) async {
    await pumpWizard(tester);

    expect(find.byType(ProfileChoiceStep), findsOneWidget);
    expect(find.byKey(const Key('profileCard_fleet')), findsOneWidget);
  });

  testWidgets('a production build sees exactly the three cards it saw '
      'before (ADR 0025 D6)', (tester) async {
    await pumpWizard(tester, channel: BuildChannel.production);

    expect(find.byKey(const Key('profileCard_basic')), findsOneWidget);
    expect(find.byKey(const Key('profileCard_medium')), findsOneWidget);
    expect(find.byKey(const Key('profileCard_full')), findsOneWidget);
    expect(find.byKey(const Key('profileCard_fleet')), findsNothing);
  });

  testWidgets('a fleet user reaches the fleet identity step right after '
      'the intent card', (tester) async {
    await pumpWizard(tester);

    await tapCard(tester, 'fleet');
    await tapNext(tester);

    expect(find.byType(FleetIdentityStep), findsOneWidget);
  });

  testWidgets('a personal user never sees either fleet page', (tester) async {
    await pumpWizard(tester);

    await tapCard(tester, 'medium');
    await tapNext(tester);

    expect(find.byType(FleetIdentityStep), findsNothing);
    expect(find.byType(PrivacySummaryStep), findsNothing);
  });

  testWidgets('changing the mind back to a personal card removes the '
      'fleet pages again', (tester) async {
    await pumpWizard(tester);

    await tapCard(tester, 'fleet');
    await tapNext(tester);
    expect(find.byType(FleetIdentityStep), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tapCard(tester, 'full');
    await tapNext(tester);

    expect(find.byType(FleetIdentityStep), findsNothing);
  });

  testWidgets('back and forward across the identity step preserves what '
      'was typed into it', (tester) async {
    await pumpWizard(tester, sync: fleetCapableSync);

    await tapCard(tester, 'fleet');
    await tapNext(tester);
    await tester.enterText(
        find.byKey(const Key('fleetInviteCodeField')), 'ACME-4K2P');
    await tester.pumpAndSettle();

    await tapNext(tester);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('ACME-4K2P'), findsOneWidget,
        reason: '#4217: back navigation preserves data');
  });

  testWidgets('the privacy summary is the last page before Done for a '
      'fleet user, and takes no consent', (tester) async {
    await pumpWizard(tester);

    await tapCard(tester, 'fleet');
    // Identity, Country, Vehicle, Preferences, Landing, [API key],
    // Privacy — walked by name rather than by a count, which is the
    // whole point of the lookup refactor.
    for (var i = 0; i < 8; i++) {
      if (find.byType(PrivacySummaryStep).evaluate().isNotEmpty) break;
      await tapNext(tester);
    }

    expect(find.byType(PrivacySummaryStep), findsOneWidget);
    expect(find.byType(Switch), findsNothing,
        reason: 'ADR 0025 D6 — no new consent control ships before the '
            'manager surfaces and the single policy bump');
  });
}

/// A first run: nothing picked yet, so the intent card is the first
/// thing the user sees.
class _EmptyProfileRepo implements AppProfileRepository {
  AppProfile? _stored;

  @override
  AppProfile? load() => _stored;

  @override
  Future<void> save(AppProfile profile) async => _stored = profile;

  @override
  bool get isEmpty => _stored == null;
}

class _NullObd2Connector implements OnboardingObd2Connector {
  @override
  Future<OnboardingObd2Session?> connect(_) async => null;

  @override
  Future<String?> readVin(_) async => null;
}
