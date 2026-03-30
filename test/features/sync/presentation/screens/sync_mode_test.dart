import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';

void main() {
  group('SyncMode enum', () {
    test('has four values', () {
      expect(SyncMode.values.length, 4);
    });

    test('values are community, joinExisting, private, none', () {
      expect(SyncMode.values, [
        SyncMode.community,
        SyncMode.joinExisting,
        SyncMode.private,
        SyncMode.none,
      ]);
    });
  });

  group('SyncConfig defaults', () {
    test('default SyncConfig has mode=none and enabled=false', () {
      const config = SyncConfig();
      expect(config.mode, SyncMode.none);
      expect(config.enabled, false);
      expect(config.supabaseUrl, isNull);
      expect(config.supabaseAnonKey, isNull);
      expect(config.userId, isNull);
      expect(config.userEmail, isNull);
    });
  });

  group('SyncConfig.isConfigured', () {
    test('returns true when enabled, url, and key are present', () {
      const config = SyncConfig(
        enabled: true,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'some-key',
      );
      expect(config.isConfigured, true);
    });

    test('returns false when url is null', () {
      const config = SyncConfig(
        enabled: true,
        supabaseAnonKey: 'some-key',
      );
      expect(config.isConfigured, false);
    });

    test('returns false when anonKey is null', () {
      const config = SyncConfig(
        enabled: true,
        supabaseUrl: 'https://example.supabase.co',
      );
      expect(config.isConfigured, false);
    });

    test('returns false when not enabled', () {
      const config = SyncConfig(
        enabled: false,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'some-key',
      );
      expect(config.isConfigured, false);
    });
  });

  group('SyncConfig.modeName', () {
    test('returns correct name for community mode', () {
      const config = SyncConfig(mode: SyncMode.community);
      expect(config.modeName, 'Tankstellen Community');
    });

    test('returns correct name for joinExisting mode', () {
      const config = SyncConfig(mode: SyncMode.joinExisting);
      expect(config.modeName, 'Shared Group');
    });

    test('returns correct name for private mode', () {
      const config = SyncConfig(mode: SyncMode.private);
      expect(config.modeName, 'Private Database');
    });

    test('returns "Local Only" for none mode', () {
      const config = SyncConfig(mode: SyncMode.none);
      expect(config.modeName, 'Local Only');
    });
  });

  group('SyncConfig.hasEmail', () {
    test('returns true when email is non-null and non-empty', () {
      const config = SyncConfig(userEmail: 'user@example.com');
      expect(config.hasEmail, true);
    });

    test('returns false when email is null', () {
      const config = SyncConfig();
      expect(config.hasEmail, false);
    });

    test('returns false when email is empty string', () {
      const config = SyncConfig(userEmail: '');
      expect(config.hasEmail, false);
    });
  });
}
