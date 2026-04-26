import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/upload/trace_upload_config.dart';
import 'package:tankstellen/core/telemetry/upload/trace_uploader.dart';
import 'package:tankstellen/core/data/storage_repository.dart';

ErrorTrace _makeTrace() {
  return ErrorTrace(
    id: 'test-trace-1',
    timestamp: DateTime.now(),
    timezoneOffset: '+01:00',
    category: ErrorCategory.unknown,
    errorType: 'Exception',
    errorMessage: 'test',
    stackTrace: '#0 main',
    deviceInfo: const DeviceInfo(
      os: 'test',
      osVersion: '1.0',
      platform: 'test',
      locale: 'en',
      screenWidth: 400,
      screenHeight: 800,
      appVersion: '1.0.0',
    ),
    appState: const AppStateSnapshot(),
    networkState: const NetworkSnapshot(isOnline: true),
  );
}

/// Fake SettingsStorage that works without real Hive initialization.
class _FakeSettingsStorage implements SettingsStorage {
  final _settings = <String, dynamic>{};

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}

void main() {
  group('TraceUploadConfig', () {
    test('disabled config has enabled=false and null URL', () {
      const config = TraceUploadConfig.disabled;
      expect(config.enabled, isFalse);
      expect(config.serverUrl, isNull);
      expect(config.authToken, isNull);
    });

    test('fromJson parses valid config', () {
      final config = TraceUploadConfig.fromJson({
        'enabled': true,
        'serverUrl': 'https://example.com/traces',
        'authToken': 'secret-token',
      });

      expect(config.enabled, isTrue);
      expect(config.serverUrl, 'https://example.com/traces');
      expect(config.authToken, 'secret-token');
    });

    test('fromJson with minimal fields defaults correctly', () {
      final config = TraceUploadConfig.fromJson({});

      expect(config.enabled, isFalse);
      expect(config.serverUrl, isNull);
      expect(config.authToken, isNull);
    });

    test('toJson roundtrip preserves values', () {
      const config = TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://test.com',
        authToken: 'tok',
      );
      final json = config.toJson();
      final restored = TraceUploadConfig.fromJson(json);

      expect(restored.enabled, config.enabled);
      expect(restored.serverUrl, config.serverUrl);
      expect(restored.authToken, config.authToken);
    });
  });

  group('TraceUploader', () {
    late _FakeSettingsStorage fakeStorage;
    late TraceUploader uploader;

    setUp(() {
      fakeStorage = _FakeSettingsStorage();
      uploader = TraceUploader(fakeStorage);
    });

    test('getConfig returns disabled when no config stored', () {
      final config = uploader.getConfig();
      expect(config.enabled, isFalse);
    });

    test('saveConfig and getConfig roundtrip', () async {
      const config = TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://example.com',
        authToken: 'my-token',
      );

      await uploader.saveConfig(config);
      final retrieved = uploader.getConfig();

      expect(retrieved.enabled, isTrue);
      expect(retrieved.serverUrl, 'https://example.com');
      expect(retrieved.authToken, 'my-token');
    });

    test('getConfig throws on non-map stored data (code limitation)', () async {
      // The `as Map` cast in getConfig throws TypeError, which is not caught
      // by the FormatException handler. This documents the current behavior.
      await fakeStorage.putSetting('trace_upload_config', 'not-a-map');
      expect(() => uploader.getConfig(), throwsA(isA<TypeError>()));
    });

    test('getConfig throws on map with wrong types (code limitation)', () async {
      // fromJson does `as bool?` cast on the 'enabled' field. A string value
      // throws TypeError, not FormatException. Documents this limitation.
      await fakeStorage.putSetting('trace_upload_config', <String, dynamic>{
        'enabled': 'not-a-bool',
      });
      expect(() => uploader.getConfig(), throwsA(isA<TypeError>()));
    });

    test('uploadIfEnabled does nothing when disabled', () async {
      // Should not throw
      await uploader.uploadIfEnabled(_makeTrace());
    });

    test('uploadIfEnabled does nothing when URL is empty', () async {
      await uploader.saveConfig(const TraceUploadConfig(
        enabled: true,
        serverUrl: '',
      ));
      // Should not throw
      await uploader.uploadIfEnabled(_makeTrace());
    });

    test('upload failure does not throw', () async {
      await uploader.saveConfig(const TraceUploadConfig(
        enabled: true,
        serverUrl: 'https://nonexistent.invalid/traces',
        authToken: 'token',
      ));

      // This will fail the HTTP request but must not throw
      await expectLater(
        uploader.uploadIfEnabled(_makeTrace()),
        completes,
      );
    });
  });
}
