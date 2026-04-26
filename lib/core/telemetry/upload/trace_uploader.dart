import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/storage_repository.dart';
import '../../services/dio_factory.dart';
import '../../storage/storage_providers.dart';
import '../pii_scrubber.dart';
import '../models/error_trace.dart';
import 'trace_upload_config.dart';

part 'trace_uploader.g.dart';

@Riverpod(keepAlive: true)
TraceUploader traceUploader(Ref ref) {
  return TraceUploader(ref.watch(storageRepositoryProvider));
}

class TraceUploader {
  final SettingsStorage _storage;
  static const String _configKey = 'trace_upload_config';

  TraceUploader(this._storage);

  TraceUploadConfig getConfig() {
    final raw = _storage.getSetting(_configKey);
    if (raw == null) return TraceUploadConfig.disabled;
    try {
      return TraceUploadConfig.fromJson(Map<String, dynamic>.from(raw as Map));
    } on FormatException catch (e, st) {
      debugPrint('TraceUploader: config parse failed: $e\n$st');
      return TraceUploadConfig.disabled;
    }
  }

  Future<void> saveConfig(TraceUploadConfig config) async {
    await _storage.putSetting(_configKey, config.toJson());
  }

  /// Upload trace if enabled. Fire-and-forget — never throws.
  Future<void> uploadIfEnabled(ErrorTrace trace) async {
    final config = getConfig();
    if (!config.enabled ||
        config.serverUrl == null ||
        config.serverUrl!.isEmpty) {
      return;
    }

    try {
      final dio = DioFactory.create(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        // Trace uploads are user/session triggered and must dispatch
        // immediately — opting out of the default rate limiter.
        rateLimit: null,
      );
      // #1109 — same PII redaction policy as Sentry's `beforeSend`.
      // Strips emails, lat/lng pairs, token-like strings, and caps long
      // breadcrumb payloads so the user-configured trace endpoint sees
      // the same scrubbed surface Sentry does.
      final scrubbed = PiiScrubber.scrubErrorTrace(trace);
      await dio.post(
        config.serverUrl!,
        data: scrubbed.toJson(),
        options: Options(headers: {
          'Content-Type': 'application/json',
          if (config.authToken != null && config.authToken!.isNotEmpty)
            'Authorization': 'Bearer ${config.authToken}',
        }),
      );
    } on DioException catch (e, st) {
      debugPrint('TraceUploader: upload failed: $e\n$st');
    }
  }
}
