import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_retry.dart';
import 'package:tankstellen/features/station_services/germany/tankerkoenig_batch_price_fetcher.dart';

/// Records each request the adapter receives and replies with the next
/// queued response. Lets the test drive batch-handling without going to
/// the real Tankerkoenig API.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<ResponseBody> responses;

  _RecordingAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (responses.isEmpty) {
      throw StateError('no more queued responses');
    }
    return responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(String body) {
  return ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

Dio _dioWith(List<ResponseBody> responses) {
  final dio = Dio();
  dio.httpClientAdapter = _RecordingAdapter(responses);
  return dio;
}

void main() {
  group('TankerkoenigBatchPriceFetcher.fetchBatch', () {
    test('returns empty map when ids list is empty', () async {
      final fetcher = TankerkoenigBatchPriceFetcher(dio: _dioWith([]));
      final result =
          await fetcher.fetchBatch(ids: const [], apiKey: 'key');
      expect(result, isEmpty);
    });

    test('omits apikey query parameter when apiKey is null', () async {
      // Main isolate uses a Dio interceptor to inject the key, so the
      // fetcher should not send `apikey` itself.
      final dio = _dioWith([_jsonResponse('{"ok":true,"prices":{}}')]);
      final adapter = dio.httpClientAdapter as _RecordingAdapter;
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio);

      await fetcher.fetchBatch(ids: const ['a']);

      expect(adapter.requests.single.queryParameters.containsKey('apikey'),
          isFalse);
      expect(adapter.requests.single.queryParameters['ids'], 'a');
    });

    test('omits apikey query parameter when apiKey is empty string', () async {
      final dio = _dioWith([_jsonResponse('{"ok":true,"prices":{}}')]);
      final adapter = dio.httpClientAdapter as _RecordingAdapter;
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio);

      await fetcher.fetchBatch(ids: const ['a'], apiKey: '');

      expect(adapter.requests.single.queryParameters.containsKey('apikey'),
          isFalse);
    });

    test('main-isolate path: 25 ids still chunk into 3 batches', () async {
      // Regression for #426 — main isolate getPrices used to truncate
      // `ids.take(10)`; now it must batch the full list.
      final dio = _dioWith([
        _jsonResponse('{"ok":true,"prices":{}}'),
        _jsonResponse('{"ok":true,"prices":{}}'),
        _jsonResponse('{"ok":true,"prices":{}}'),
      ]);
      final adapter = dio.httpClientAdapter as _RecordingAdapter;
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio);

      final ids = List.generate(25, (i) => 'station-$i');
      // No apiKey: simulating the main-isolate path
      await fetcher.fetchBatch(ids: ids);

      expect(adapter.requests, hasLength(3),
          reason: '25 ids must produce 3 requests, not be truncated to 10');
    });

    test('parses a single batch into the id → price map', () async {
      final dio = _dioWith([
        _jsonResponse('{"ok":true,"prices":{'
            '"abc":{"e5":1.799,"e10":1.749,"diesel":1.659,"status":"open"},'
            '"def":{"e5":1.819,"e10":1.769,"diesel":1.679,"status":"open"}'
            '}}'),
      ]);
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio);

      final result = await fetcher.fetchBatch(
        ids: const ['abc', 'def'],
        apiKey: 'key',
      );

      expect(result.keys, unorderedEquals(['abc', 'def']));
      expect(result['abc']!['e5'], 1.799);
      expect(result['def']!['diesel'], 1.679);
    });

    test('chunks 25 ids into 3 requests at the default batchSize of 10',
        () async {
      // 3 success responses, one per batch.
      final dio = _dioWith([
        _jsonResponse('{"ok":true,"prices":{}}'),
        _jsonResponse('{"ok":true,"prices":{}}'),
        _jsonResponse('{"ok":true,"prices":{}}'),
      ]);
      final adapter = dio.httpClientAdapter as _RecordingAdapter;
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio);

      final ids = List.generate(25, (i) => 'station-$i');
      await fetcher.fetchBatch(ids: ids, apiKey: 'key');

      expect(adapter.requests, hasLength(3));
      // 10, 10, 5
      expect(
        adapter.requests[0].queryParameters['ids'].toString().split(',').length,
        10,
      );
      expect(
        adapter.requests[1].queryParameters['ids'].toString().split(',').length,
        10,
      );
      expect(
        adapter.requests[2].queryParameters['ids'].toString().split(',').length,
        5,
      );
    });

    test('honours a custom batchSize', () async {
      final dio = _dioWith([
        _jsonResponse('{"ok":true,"prices":{}}'),
        _jsonResponse('{"ok":true,"prices":{}}'),
        _jsonResponse('{"ok":true,"prices":{}}'),
        _jsonResponse('{"ok":true,"prices":{}}'),
      ]);
      final adapter = dio.httpClientAdapter as _RecordingAdapter;
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio, batchSize: 2);

      final ids = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
      await fetcher.fetchBatch(ids: ids, apiKey: 'key');

      // 7 ids with batchSize 2 → 4 requests (2,2,2,1)
      expect(adapter.requests, hasLength(4));
    });

    test('drops a batch whose response has ok:false', () async {
      final dio = _dioWith([
        _jsonResponse('{"ok":false,"message":"rate limited"}'),
        _jsonResponse('{"ok":true,"prices":{"x":{"e5":1.5,"status":"open"}}}'),
      ]);
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio, batchSize: 1);

      final result =
          await fetcher.fetchBatch(ids: const ['bad', 'x'], apiKey: 'key');

      expect(result.keys, ['x']);
      expect(result['x']!['e5'], 1.5);
    });

    test('passes the api key as a query parameter', () async {
      final dio = _dioWith([_jsonResponse('{"ok":true,"prices":{}}')]);
      final adapter = dio.httpClientAdapter as _RecordingAdapter;
      final fetcher = TankerkoenigBatchPriceFetcher(dio: dio);

      await fetcher.fetchBatch(ids: const ['a'], apiKey: 'super-secret');

      expect(adapter.requests.single.queryParameters['apikey'], 'super-secret');
    });

    test('a partial-failure result still merges good batches', () async {
      // First batch succeeds, second fails after the configured retry budget.
      final dio = _dioWith([
        _jsonResponse('{"ok":true,"prices":{"a":{"e5":1.5,"status":"open"}}}'),
        _jsonResponse('{"ok":false,"message":"oops"}'),
        _jsonResponse('{"ok":false,"message":"oops"}'),
        _jsonResponse('{"ok":false,"message":"oops"}'),
      ]);
      final fetcher = TankerkoenigBatchPriceFetcher(
        dio: dio,
        batchSize: 1,
        retryConfig: const BackgroundRetryConfig(
          maxAttempts: 1,
          baseDelay: Duration.zero,
        ),
      );

      final result = await fetcher.fetchBatch(
        ids: const ['a', 'b'],
        apiKey: 'key',
      );

      expect(result.keys, ['a']);
    });
  });
}
