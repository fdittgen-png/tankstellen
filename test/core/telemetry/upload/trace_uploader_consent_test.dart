// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3866 (Epic #3865) — the trace uploader honours the Error reporting
// consent, not only its own endpoint config.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/telemetry/upload/trace_upload_config.dart';
import 'package:tankstellen/core/telemetry/upload/trace_uploader.dart';

class _Mem implements SettingsStorage {
  final Map<String, dynamic> m = {};
  @override
  dynamic getSetting(String key) => m[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => m[key] = value;
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
  const config =
      TraceUploadConfig(enabled: true, serverUrl: 'https://traces.example');

  test('endpoint configured but NO consent → nothing is sent', () async {
    final storage = _Mem();
    final uploader = TraceUploader(storage);
    await uploader.saveConfig(config);
    expect(uploader.uploadPermitted(), isFalse);
  });

  test('consent + endpoint → permitted', () async {
    final storage = _Mem()..m['consent_error_reporting'] = true;
    final uploader = TraceUploader(storage);
    await uploader.saveConfig(config);
    expect(uploader.uploadPermitted(), isTrue);
  });

  test('consent withdrawn later → no longer permitted', () async {
    final storage = _Mem()..m['consent_error_reporting'] = true;
    final uploader = TraceUploader(storage);
    await uploader.saveConfig(config);
    storage.m['consent_error_reporting'] = false;
    expect(uploader.uploadPermitted(), isFalse);
  });
}
