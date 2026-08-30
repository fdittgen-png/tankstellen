// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consent/presentation/widgets/consent_settings_section.dart';
import 'package:tankstellen/features/consent/presentation/widgets/privacy_controls_section.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/about_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/backup_restore_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/data_sources_location_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/features_use_mode_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy_data_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/sync_account_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/about_section.dart';
import 'package:tankstellen/features/profile/presentation/widgets/api_key_section.dart';
import 'package:tankstellen/features/profile/presentation/widgets/feature_management_section.dart';
import 'package:tankstellen/features/profile/presentation/widgets/location_section_widget.dart';
import 'package:tankstellen/features/profile/presentation/widgets/storage_section.dart';
import 'package:tankstellen/features/profile/presentation/widgets/tank_sync_section.dart';
import 'package:tankstellen/features/profile/presentation/widgets/use_mode_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../helpers/pump_app.dart';
import 'settings_test_harness.dart';

/// One minimal widget test per Settings topic screen (#3884), part 2:
/// Features & use mode · Data sources & location · Sync & account ·
/// Privacy & data · Backup & restore · About.
void main() {
  Future<void> pumpTall(WidgetTester tester, Widget screen,
      {Set<Feature>? flags}) async {
    await tester.binding.setSurfaceSize(const Size(600, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, screen, overrides: settingsTestOverrides(flags: flags));
  }

  AppLocalizations l10n(WidgetTester tester, Type screen) =>
      AppLocalizations.of(tester.element(find.byType(screen)));

  testWidgets('Features & use mode hosts the use-mode chooser above the '
      'feature switches, expanded', (tester) async {
    await pumpTall(tester, const FeaturesUseModeScreen());
    expect(find.byType(UseModeSection), findsOneWidget);
    expect(find.byType(FeatureManagementSection), findsOneWidget);
    expect(find.byKey(const Key('featureToggle_priceAlerts'),
            skipOffstage: false),
        findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(
      tester.getTopLeft(find.byType(UseModeSection)).dy,
      lessThan(tester.getTopLeft(find.byType(FeatureManagementSection)).dy),
    );
  });

  testWidgets('Data sources & location hosts the API key + Location sections',
      (tester) async {
    await pumpTall(tester, const DataSourcesLocationScreen());
    final l = l10n(tester, DataSourcesLocationScreen);
    expect(find.text(l.apiKeySetup), findsOneWidget);
    expect(find.byType(ApiKeySection), findsOneWidget);
    expect(find.text(l.sectionLocation), findsOneWidget);
    expect(find.byType(LocationSectionWidget), findsOneWidget);
    // The two formerly hard-coded strings now come from ARB.
    expect(find.text(l.locationGpsAutoHint), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('Sync & account hosts the TankSync section under the brand '
      'header + localised subtitle', (tester) async {
    await pumpTall(tester, const SyncAccountScreen(),
        flags: const {Feature.tankSync});
    final l = l10n(tester, SyncAccountScreen);
    expect(find.text('TankSync'), findsOneWidget);
    expect(find.text(l.tankSyncSectionSubtitle), findsOneWidget);
    expect(find.byType(TankSyncSection), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('Privacy & data hosts the five consents (trip sync back next '
      'to Cloud Sync), privacy controls, the dashboard tile and Storage '
      'without a Delete-all button', (tester) async {
    await pumpTall(tester, const PrivacyDataScreen());
    final l = l10n(tester, PrivacyDataScreen);
    expect(find.byType(ConsentSettingsSection), findsOneWidget);
    expect(find.byKey(const Key('tripsSyncToggle')), findsOneWidget);
    expect(find.byType(PrivacyControlsSection), findsOneWidget);
    expect(find.byKey(const Key('settingsPrivacyDashboardTile')),
        findsOneWidget);
    expect(find.byType(StorageSection), findsOneWidget);
    expect(find.text(l.deleteAllButton), findsNothing,
        reason: 'the Privacy Dashboard owns deletion (#3884)');
    expect(find.text(l.settingsStorageDeleteHint), findsOneWidget);
    expect(find.byKey(const Key('storagePrivacyDashboardLink')),
        findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('Backup & restore hosts the export and restore actions',
      (tester) async {
    await pumpTall(tester, const BackupRestoreScreen());
    final l = l10n(tester, BackupRestoreScreen);
    expect(find.byKey(const Key('settingsExportBackupTile')), findsOneWidget);
    expect(find.byKey(const Key('settingsRestoreBackupTile')), findsOneWidget);
    expect(find.text(l.exportBackupMenuLabel), findsOneWidget);
    expect(find.text(l.restoreBackupMenuLabel), findsOneWidget);
  });

  testWidgets('About hosts the unchanged About section', (tester) async {
    await pumpTall(tester, const AboutScreen());
    expect(find.byType(AboutSection), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });
}
