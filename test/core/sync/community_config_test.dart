import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/community_config.dart';

const _testConfig = {
  'supabase_url': 'https://test-project.supabase.co',
  'supabase_anon_key':
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc3NDYzODQ2NiwiZXhwIjoyMDkwMjE0NDY2fQ'
      '.fake-signature-for-testing-purposes-only-pad-pad-pad',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CommunityConfig.reset();

    // Mock the asset bundle to serve our test config. The top-level
    // ServicesBinding.setMockMessageHandler is deprecated (#711) —
    // use TestDefaultBinaryMessengerBinding's helper which routes to
    // the test messenger so handlers are isolated per test.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/tanksync_config.json') {
        final bytes = utf8.encode(json.encode(_testConfig));
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('CommunityConfig', () {
    test('load() reads from asset bundle', () async {
      await CommunityConfig.load();
      expect(CommunityConfig.supabaseUrl, 'https://test-project.supabase.co');
      expect(CommunityConfig.supabaseAnonKey, contains('eyJ'));
    });

    test('supabaseUrl starts with https://', () async {
      await CommunityConfig.load();
      expect(CommunityConfig.supabaseUrl, startsWith('https://'));
    });

    test('supabaseUrl contains .supabase.co', () async {
      await CommunityConfig.load();
      expect(CommunityConfig.supabaseUrl, contains('.supabase.co'));
    });

    test('supabaseAnonKey has 3 JWT parts', () async {
      await CommunityConfig.load();
      final parts = CommunityConfig.supabaseAnonKey.split('.');
      expect(parts.length, 3);
    });

    test('isConfigured returns true when loaded', () async {
      await CommunityConfig.load();
      expect(CommunityConfig.isConfigured, isTrue);
    });

    test('isConfigured returns false before load', () {
      // Without loading, no dart-define either → empty
      expect(CommunityConfig.isConfigured, isFalse);
    });

    test('load() is idempotent', () async {
      await CommunityConfig.load();
      final url1 = CommunityConfig.supabaseUrl;
      await CommunityConfig.load();
      expect(CommunityConfig.supabaseUrl, url1);
    });
  });
}
