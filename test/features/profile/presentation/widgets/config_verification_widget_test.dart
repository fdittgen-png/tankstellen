import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/presentation/widgets/config_verification_widget.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../fakes/fake_storage_repository.dart';
import '../../../../helpers/pump_app.dart';

class _FixedActiveProfile extends ActiveProfile {
  _FixedActiveProfile(this._value);
  final UserProfile? _value;
  @override
  UserProfile? build() => _value;
}

class _DisabledSync extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}

class _ConnectedSync extends SyncState {
  @override
  SyncConfig build() => const SyncConfig(
        enabled: true,
        mode: SyncMode.community,
        userId: 'user-abc',
        userEmail: 'test@example.com',
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
}

List<Object> _buildOverrides({
  UserProfile? profile,
  bool hasApiKey = false,
  bool syncEnabled = false,
}) {
  // #521 — hasApiKey() is true in production whenever ANY key is configured.
  // FakeHiveStorage models that via `hasBundledDefaultKey` (true by default)
  // PLUS the actual key — `hasApiKey` here controls only the custom-key flag.
  final fake = FakeStorageRepository();
  if (hasApiKey) {
    fake.setApiKey('custom-key');
  }
  // The widget reads the bundled-default fingerprint when no custom key is
  // configured; mirror the legacy mock value so any UI that surfaces the
  // first 8 chars stays stable.

  return [
    storageRepositoryProvider.overrideWithValue(fake),
    activeProfileProvider.overrideWith(() => _FixedActiveProfile(profile)),
    syncStateProvider
        .overrideWith(() => syncEnabled ? _ConnectedSync() : _DisabledSync()),
  ];
}

UserProfile _sampleProfile() => const UserProfile(
      id: 'p1',
      name: 'Standard',
      preferredFuelType: FuelType.e10,
      countryCode: 'fr',
      routeSegmentKm: 50,
    );

void main() {
  group('ConfigVerificationWidget (#519)', () {
    // Keep the legacy smoke test for the widget class + the StorageStats
    // data class further down.
    test('widget can be instantiated', () {
      const widget = ConfigVerificationWidget();
      expect(widget, isA<ConfigVerificationWidget>());
    });

    testWidgets('renders every section header in French', (tester) async {
      await pumpApp(
        tester,
        const ConfigVerificationWidget(),
        overrides: _buildOverrides(profile: _sampleProfile()),
        locale: const Locale('fr'),
      );

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Clés API'), findsOneWidget);
      expect(find.text('Synchronisation'), findsOneWidget);

      expect(find.text('Profil actif'), findsOneWidget);
      expect(find.text('Carburant préféré'), findsOneWidget);
      expect(find.text('Pays'), findsOneWidget);
      expect(find.text("Segment d'itinéraire"), findsOneWidget);
      expect(find.text('Clé API Tankerkoenig'), findsOneWidget);
      expect(find.text('Clé API recharge VE'), findsOneWidget);

      expect(find.text('Résumé de confidentialité'), findsOneWidget);
    });

    testWidgets('renders every section header in English', (tester) async {
      await pumpApp(
        tester,
        const ConfigVerificationWidget(),
        overrides: _buildOverrides(profile: _sampleProfile()),
        locale: const Locale('en'),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('API keys'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.text('Active profile'), findsOneWidget);
      expect(find.text('Preferred fuel'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
      expect(find.text('Route segment'), findsOneWidget);
      expect(find.text('Tankerkoenig API key'), findsOneWidget);
      expect(find.text('EV charging API key'), findsOneWidget);
      expect(find.text('Privacy summary'), findsOneWidget);
    });

    testWidgets(
        '#521: Tankerkoenig row shows "Clé communautaire par défaut" '
        'when no custom key is set (FR)', (tester) async {
      await pumpApp(
        tester,
        const ConfigVerificationWidget(),
        overrides: _buildOverrides(profile: _sampleProfile()),
        locale: const Locale('fr'),
      );
      // The community key is bundled — we never render "demo mode".
      expect(find.text('Clé communautaire par défaut'), findsOneWidget);
      expect(find.text('Non définie (mode démo)'), findsNothing);
      expect(find.text('Not set (demo mode)'), findsNothing);
    });

    testWidgets(
        '#521: Tankerkoenig row shows "Configurée" under FR when the '
        'user has set their own key', (tester) async {
      await pumpApp(
        tester,
        const ConfigVerificationWidget(),
        overrides:
            _buildOverrides(profile: _sampleProfile(), hasApiKey: true),
        locale: const Locale('fr'),
      );
      expect(find.text('Configurée'), findsOneWidget);
      expect(find.text('Clé communautaire par défaut'), findsNothing);
    });

    testWidgets('TankSync row shows "Désactivée" under FR when disconnected',
        (tester) async {
      await pumpApp(
        tester,
        const ConfigVerificationWidget(),
        overrides: _buildOverrides(profile: _sampleProfile()),
        locale: const Locale('fr'),
      );
      expect(find.text('Désactivée'), findsOneWidget);
      expect(find.text('Disabled'), findsNothing);
    });

    testWidgets('TankSync row shows "Connectée" under FR when connected',
        (tester) async {
      await pumpApp(
        tester,
        const ConfigVerificationWidget(),
        overrides: _buildOverrides(
          profile: _sampleProfile(),
          syncEnabled: true,
        ),
        locale: const Locale('fr'),
      );
      expect(find.text('Connectée'), findsOneWidget);
    });

    testWidgets('no English label leaks under a FR locale', (tester) async {
      await pumpApp(
        tester,
        const ConfigVerificationWidget(),
        overrides: _buildOverrides(profile: _sampleProfile()),
        locale: const Locale('fr'),
      );

      // These are the exact English strings the widget used to
      // hardcode before #519. If any of them still renders, the
      // translation wiring has regressed.
      for (final englishLabel in [
        'Active profile',
        'Preferred fuel',
        'Country',
        'Route segment',
        'Tankerkoenig API key',
        'Not set (demo mode)',
        'EV charging API key',
        'Default (shared)',
        'Disabled',
        'Privacy summary',
      ]) {
        expect(
          find.text(englishLabel),
          findsNothing,
          reason: '"$englishLabel" must be translated on FR locale',
        );
      }
    });
  });

  group('StorageStats', () {
    test('has correct default values', () {
      const stats = StorageStats();
      expect(stats.favoriteCount, 0);
      expect(stats.alertCount, 0);
      expect(stats.ignoredCount, 0);
      expect(stats.ratingsCount, 0);
      expect(stats.cacheEntryCount, 0);
      expect(stats.priceHistoryCount, 0);
      expect(stats.profileCount, 0);
      expect(stats.hasGpsPosition, false);
      expect(stats.hasApiKey, false);
      expect(stats.hasCustomEvKey, false);
    });

    test('accepts custom values', () {
      const stats = StorageStats(
        favoriteCount: 5,
        alertCount: 2,
        ignoredCount: 3,
        ratingsCount: 1,
        cacheEntryCount: 15,
        priceHistoryCount: 4,
        profileCount: 1,
        hasGpsPosition: true,
        hasApiKey: true,
        hasCustomEvKey: false,
      );
      expect(stats.favoriteCount, 5);
      expect(stats.alertCount, 2);
      expect(stats.ignoredCount, 3);
      expect(stats.ratingsCount, 1);
      expect(stats.cacheEntryCount, 15);
      expect(stats.priceHistoryCount, 4);
      expect(stats.profileCount, 1);
      expect(stats.hasGpsPosition, isTrue);
      expect(stats.hasApiKey, isTrue);
      expect(stats.hasCustomEvKey, isFalse);
    });
  });
}
