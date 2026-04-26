import 'package:dio/dio.dart';

import '../../../core/background/background_retry.dart';
import '../../../core/constants/field_names.dart';
import '../../../core/utils/json_extensions.dart';

/// Fetches Tankerkoenig prices for an arbitrary number of station IDs by
/// chunking the request into batches that respect the API's per-call ID
/// limit, and returns a flat `id → priceMap` lookup for the caller to do
/// whatever it wants with (price-history recording, alert evaluation,
/// cache update — see [BackgroundService]).
///
/// Pulled out of `background_service.dart` for issue #426 so the batching
/// + parsing + retry logic lives in exactly one place. The class is pure
/// Dart with no Riverpod dependency, so it works the same way in the
/// main isolate (with a Ref-provided Dio) and in the WorkManager
/// background isolate (with a freshly-constructed Dio).
class TankerkoenigBatchPriceFetcher {
  TankerkoenigBatchPriceFetcher({
    required Dio dio,
    this.batchSize = 10,
    this.url = 'https://creativecommons.tankerkoenig.de/json/prices.php',
    this.retryConfig = const BackgroundRetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 2),
    ),
  }) : _dio = dio;

  final Dio _dio;

  /// Maximum number of station IDs sent in a single request. Tankerkoenig's
  /// docs cap this at 10.
  final int batchSize;

  /// API endpoint. Constructor-overridable so tests can point at a fake.
  final String url;

  /// Backoff policy passed to [fetchWithRetry] for transient errors.
  final BackgroundRetryConfig retryConfig;

  /// Country prefix used in #753's globally-unique station id scheme
  /// (`de-<uuid>`). Tankerkönig itself only knows the bare UUID, so the
  /// fetcher strips the prefix before sending and re-applies it on the
  /// returned keys so the caller's id space stays consistent — including
  /// the WorkManager background isolate that records price history
  /// against the favorites' canonical (prefixed) ids.
  static const _countryPrefix = 'de-';

  /// Fetches prices for [ids] in batches of [batchSize] and merges the
  /// results into a single map keyed by station ID. Returns an empty map
  /// when [ids] is empty.
  ///
  /// Pass [apiKey] to send the key as a query parameter directly — used by
  /// the background isolate where there's no Dio interceptor. In the main
  /// isolate the key is injected by the Dio interceptor in
  /// `service_providers.dart` so callers can omit it.
  ///
  /// Failed batches are silently dropped so a partial result is still
  /// useful (e.g. one batch of 10 fails but the other 20 stations still
  /// get fresh prices). Per-batch errors are retried via
  /// [BackgroundRetryConfig] before being given up on.
  ///
  /// #753 — accepts ids in either the new prefixed (`de-<uuid>`) or
  /// legacy bare-UUID form. The returned map is keyed in the SAME shape
  /// the caller passed in, so favorites/alerts that store prefixed ids
  /// see prefixed keys back.
  Future<Map<String, Map<String, dynamic>>> fetchBatch({
    required List<String> ids,
    String? apiKey,
  }) async {
    if (ids.isEmpty) {
      return const <String, Map<String, dynamic>>{};
    }

    // Build a bare-id list for the upstream call and remember the
    // original shape each one came in as so we can re-key the response.
    final bareToOriginal = <String, String>{};
    final bareIds = <String>[];
    for (final id in ids) {
      final bare = id.startsWith(_countryPrefix)
          ? id.substring(_countryPrefix.length)
          : id;
      bareIds.add(bare);
      bareToOriginal[bare] = id;
    }

    final result = <String, Map<String, dynamic>>{};

    for (var i = 0; i < bareIds.length; i += batchSize) {
      final batch = bareIds.sublist(
        i,
        i + batchSize > bareIds.length ? bareIds.length : i + batchSize,
      );
      final joined = batch.join(',');

      final data = await fetchWithRetry(
        dio: _dio,
        url: url,
        queryParameters: {
          'ids': joined,
          if (apiKey != null && apiKey.isNotEmpty) 'apikey': apiKey,
        },
        config: retryConfig,
      );
      _mergeBatch(data, into: result, bareToOriginal: bareToOriginal);
    }
    return result;
  }

  void _mergeBatch(
    Map<String, dynamic>? data, {
    required Map<String, Map<String, dynamic>> into,
    required Map<String, String> bareToOriginal,
  }) {
    if (data == null) return;
    if (data[TankerkoenigFields.ok] != true) return;
    if (data[TankerkoenigFields.prices] == null) return;
    final raw = data.getMap(TankerkoenigFields.prices);
    if (raw == null) return;
    for (final entry in raw.entries) {
      final value = entry.value;
      // Re-key the upstream's bare UUID back to whatever shape the
      // caller asked for (prefixed or bare). Falls back to bare when
      // the response carries an unexpected key.
      final outKey = bareToOriginal[entry.key] ?? entry.key;
      if (value is Map<String, dynamic>) {
        into[outKey] = value;
      } else if (value is Map) {
        into[outKey] = Map<String, dynamic>.from(value);
      }
    }
  }
}
