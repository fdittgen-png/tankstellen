import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error_tracing/upload/trace_upload_config.dart';

void main() {
  group('TraceUploadConfig', () {
    test('default constructor: enabled false, urls null', () {
      const config = TraceUploadConfig();

      expect(config.enabled, isFalse);
      expect(config.serverUrl, isNull);
      expect(config.authToken, isNull);
    });

    test('disabled singleton matches default constructor', () {
      const fresh = TraceUploadConfig();

      expect(TraceUploadConfig.disabled.enabled, isFalse);
      expect(TraceUploadConfig.disabled.serverUrl, isNull);
      expect(TraceUploadConfig.disabled.authToken, isNull);
      expect(TraceUploadConfig.disabled, equals(fresh));
      // identity is preserved across reads (it's a const).
      expect(
        identical(TraceUploadConfig.disabled, TraceUploadConfig.disabled),
        isTrue,
      );
    });

    test('constructor with values: every field reads back as set', () {
      const config = TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://traces.example.com',
        authToken: 'tok',
      );

      expect(config.enabled, isTrue);
      expect(config.serverUrl, 'https://traces.example.com');
      expect(config.authToken, 'tok');
    });

    test('fromJson round-trip preserves all fields', () {
      const original = TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://traces.example.com',
        authToken: 'secret-token',
      );

      final json = original.toJson();
      final restored = TraceUploadConfig.fromJson(json);

      expect(restored, equals(original));
      expect(restored.enabled, original.enabled);
      expect(restored.serverUrl, original.serverUrl);
      expect(restored.authToken, original.authToken);
    });

    test('fromJson with missing optional fields leaves them null', () {
      final config = TraceUploadConfig.fromJson({'enabled': true});

      expect(config.enabled, isTrue);
      expect(config.serverUrl, isNull);
      expect(config.authToken, isNull);
    });

    test('fromJson with empty map falls back to default enabled=false', () {
      final config = TraceUploadConfig.fromJson(<String, dynamic>{});

      expect(config.enabled, isFalse);
      expect(config.serverUrl, isNull);
      expect(config.authToken, isNull);
    });

    test('copyWith mutates only the supplied fields', () {
      const base = TraceUploadConfig.disabled;

      final updated = base.copyWith(
        enabled: true,
        serverUrl: 'https://traces.example.com',
      );

      expect(updated.enabled, isTrue);
      expect(updated.serverUrl, 'https://traces.example.com');
      expect(updated.authToken, isNull);

      // Original disabled singleton must remain untouched.
      expect(TraceUploadConfig.disabled.enabled, isFalse);
      expect(TraceUploadConfig.disabled.serverUrl, isNull);
      expect(TraceUploadConfig.disabled.authToken, isNull);
    });

    test('equality: same field values produce equal instances and hashCodes',
        () {
      const a = TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://traces.example.com',
        authToken: 'tok',
      );
      const b = TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://traces.example.com',
        authToken: 'tok',
      );
      const different = TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://traces.example.com',
        authToken: 'other',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(different)));
    });
  });
}
