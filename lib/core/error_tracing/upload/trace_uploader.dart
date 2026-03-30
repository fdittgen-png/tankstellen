import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../constants/app_constants.dart';
import '../../storage/hive_storage.dart';
import '../models/error_trace.dart';
import 'trace_upload_config.dart';

part 'trace_uploader.g.dart';

@Riverpod(keepAlive: true)
TraceUploader traceUploader(Ref ref) {
  return TraceUploader(ref.watch(hiveStorageProvider));
}

class TraceUploader {
  final HiveStorage _storage;
  static const String _configKey = 'trace_upload_config';

  TraceUploader(this._storage);

  TraceUploadConfig getConfig() {
    final raw = _storage.getSetting(_configKey);
    if (raw == null) return TraceUploadConfig.disabled;
    try {
      return TraceUploadConfig.fromJson(Map<String, dynamic>.from(raw as Map));
    } on FormatException catch (_) {
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
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'User-Agent': AppConstants.userAgent,
          'Content-Type': 'application/json',
          if (config.authToken != null && config.authToken!.isNotEmpty)
            'Authorization': 'Bearer ${config.authToken}',
        },
      ));
      await dio.post(config.serverUrl!, data: trace.toJson());
    } on DioException catch (_) {
      // Upload failure must never cause secondary errors.
    }
  }
}
