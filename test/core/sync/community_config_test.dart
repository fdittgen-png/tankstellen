import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/community_config.dart';

void main() {
  group('CommunityConfig.supabaseUrl', () {
    test('is a non-empty string', () {
      expect(CommunityConfig.supabaseUrl, isNotEmpty);
    });

    test('starts with https://', () {
      expect(CommunityConfig.supabaseUrl, startsWith('https://'));
    });

    test('contains .supabase.co', () {
      expect(CommunityConfig.supabaseUrl, contains('.supabase.co'));
    });
  });

  group('CommunityConfig.supabaseAnonKey', () {
    test('is a non-empty string', () {
      expect(CommunityConfig.supabaseAnonKey, isNotEmpty);
    });

    test('has 3 JWT parts separated by dots', () {
      final parts = CommunityConfig.supabaseAnonKey.split('.');
      expect(parts.length, 3,
          reason: 'A JWT must have exactly 3 parts (header.payload.signature)');
    });

    test('length is >= 200 characters', () {
      expect(CommunityConfig.supabaseAnonKey.length, greaterThanOrEqualTo(200),
          reason: 'Supabase anon keys are long JWTs, typically 200+ chars');
    });
  });
}
