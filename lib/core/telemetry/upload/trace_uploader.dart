// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
    try {
      final raw = _storage.getSetting(_configKey);
      if (raw == null) return TraceUploadConfig.disabled;
      return TraceUploadConfig.fromJson(Map<String, dynamic>.from(raw as Map));
    } on Object catch (e, st) {
      // #2311 — `raw as Map` (schema drift) throws TypeError, and
      // fromJson's per-field casts can too.
      // #2366 — the `_storage.getSetting` read is now INSIDE the try too:
      // a closed/corrupt Hive box would otherwise escape this method's
      // documented "never throws" contract. Catch broadly (the #1301
      // TraceStorage precedent) so any failure disables upload instead of
      // silently killing the path with nothing logged.
      debugPrint('TraceUploader: config read/parse failed: $e\n$st');
      return TraceUploadConfig.disabled;
    }
  }

  Future<void> saveConfig(TraceUploadConfig config) async {
    await _storage.putSetting(_configKey, config.toJson());
  }

  /// Upload trace if enabled. Fire-and-forget — never throws.
  ///
  /// #2311 — getConfig() is now read INSIDE the try and the catch is
  /// broadened from `on DioException` to `on Object`, so the documented
  /// "never throws" contract holds even when a non-Dio pre-request error
  /// fires (e.g. a TypeError surfacing from a drifted config read or a
  /// PII-scrub failure) — the upload is dropped, never propagated.
  Future<void> uploadIfEnabled(ErrorTrace trace) async {
    try {
      final config = getConfig();
      if (!config.enabled ||
          config.serverUrl == null ||
          config.serverUrl!.isEmpty) {
        return;
      }

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
    } on Object catch (e, st) {
      // Broad by design (#2311): any error — Dio network failure, a
      // TypeError from config drift, a scrub failure — is swallowed so
      // the fire-and-forget caller never sees an exception.
      debugPrint('TraceUploader: upload failed: $e\n$st');
    }
  }
}
