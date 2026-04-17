import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';

void main() {
  group('SyncConfig defaults', () {
    test('default constructor: disabled, no url/key/user, mode none', () {
      const cfg = SyncConfig();
      expect(cfg.enabled, isFalse);
      expect(cfg.supabaseUrl, isNull);
      expect(cfg.supabaseAnonKey, isNull);
      expect(cfg.userId, isNull);
      expect(cfg.userEmail, isNull);
      expect(cfg.mode, SyncMode.none);
    });
  });

  group('SyncConfig.isConfigured', () {
    test('false when disabled', () {
      const cfg = SyncConfig(
        supabaseUrl: 'https://x.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(cfg.isConfigured, isFalse);
    });

    test('false when enabled but URL is missing', () {
      const cfg = SyncConfig(enabled: true, supabaseAnonKey: 'anon-key');
      expect(cfg.isConfigured, isFalse);
    });

    test('false when enabled but key is missing', () {
      const cfg = SyncConfig(
        enabled: true,
        supabaseUrl: 'https://x.supabase.co',
      );
      expect(cfg.isConfigured, isFalse);
    });

    test('true when enabled + URL + key all present', () {
      const cfg = SyncConfig(
        enabled: true,
        supabaseUrl: 'https://x.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(cfg.isConfigured, isTrue);
    });
  });

  group('SyncConfig.modeName', () {
    test('community', () {
      expect(
        const SyncConfig(mode: SyncMode.community).modeName,
        'Tankstellen Community',
      );
    });

    test('joinExisting', () {
      expect(
        const SyncConfig(mode: SyncMode.joinExisting).modeName,
        'Shared Group',
      );
    });

    test('private', () {
      expect(
        const SyncConfig(mode: SyncMode.private).modeName,
        'Private Database',
      );
    });

    test('none', () {
      expect(
        const SyncConfig(mode: SyncMode.none).modeName,
        'Local Only',
      );
    });

    test('every SyncMode value has a non-empty, distinct modeName', () {
      // Fail-fast if someone adds a new enum case and forgets to
      // extend the modeName switch.
      final names = SyncMode.values
          .map((m) => SyncConfig(mode: m).modeName)
          .toSet();
      expect(names.length, SyncMode.values.length);
      for (final n in names) {
        expect(n, isNotEmpty);
      }
    });
  });

  group('SyncConfig.hasEmail', () {
    test('false when email is null', () {
      const cfg = SyncConfig();
      expect(cfg.hasEmail, isFalse);
    });

    test('false when email is empty string', () {
      const cfg = SyncConfig(userEmail: '');
      expect(cfg.hasEmail, isFalse);
    });

    test('true when email is set', () {
      const cfg = SyncConfig(userEmail: 'user@example.com');
      expect(cfg.hasEmail, isTrue);
    });
  });
}
