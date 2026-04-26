import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error_tracing/collectors/app_state_collector.dart';
import 'package:tankstellen/core/error_tracing/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/error_tracing/integrations/dio_trace_interceptor.dart';
import 'package:tankstellen/core/error_tracing/models/error_trace.dart';
import 'package:tankstellen/core/error_tracing/trace_recorder.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

/// Fake recorder that captures (error, stackTrace) without touching storage,
/// uploader, or the connectivity_plus method channel.
class _FakeTraceRecorder implements TraceRecorder {
  Object? capturedError;
  StackTrace? capturedStack;
  int recordCount = 0;

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    capturedError = error;
    capturedStack = stackTrace;
    recordCount++;
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

/// Captures the most recent `next(options)` invocation.
class _CapturingRequestHandler extends RequestInterceptorHandler {
  RequestOptions? lastOptions;
  int nextCount = 0;

  @override
  void next(RequestOptions options) {
    lastOptions = options;
    nextCount++;
  }
}

class _CapturingErrorHandler extends ErrorInterceptorHandler {
  DioException? lastError;
  int nextCount = 0;

  @override
  void next(DioException err) {
    lastError = err;
    nextCount++;
  }
}

void main() {
  // Sanity: there is no public reset on AppStateCollector / BreadcrumbCollector
  // for static fields from other tests, so each test overwrites the values it
  // cares about and asserts on what it just set.
  setUp(() {
    BreadcrumbCollector.clear();
    // Overwrite the static endpoint slot so a previous test's value can't leak
    // into the assertion below.
    AppStateCollector.updateLastApi('');
  });

  group('DioTraceInterceptor', () {
    test(
      'onRequest updates AppStateCollector + emits api:request breadcrumb + forwards',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        late Ref capturedRef;
        final refCapture = Provider<int>((ref) {
          capturedRef = ref;
          return 0;
        });
        container.read(refCapture);

        final interceptor = DioTraceInterceptor(capturedRef);
        final handler = _CapturingRequestHandler();
        final options = RequestOptions(
          method: 'GET',
          path: '/foo',
        );

        interceptor.onRequest(options, handler);

        // forwarded exactly once with the same options
        expect(handler.nextCount, 1);
        expect(handler.lastOptions, same(options));

        // last endpoint is recorded as "METHOD path"
        // We need a Ref with storageRepositoryProvider overridden to read
        // the snapshot, but only the lastApiEndpoint field is what we assert.
        // Set up a fresh container that *can* read storage; but since the
        // collector's slot is static, reading from any container suffices.
        final readerContainer = ProviderContainer(overrides: [
          storageRepositoryProvider.overrideWithValue(_NullStorage()),
        ]);
        addTearDown(readerContainer.dispose);
        late Ref readerRef;
        final readerCapture = Provider<int>((ref) {
          readerRef = ref;
          return 0;
        });
        readerContainer.read(readerCapture);

        final snapshot = AppStateCollector.collect(readerRef);
        expect(snapshot.lastApiEndpoint, 'GET /foo');

        // breadcrumb recorded
        final breadcrumbs = BreadcrumbCollector.snapshot();
        expect(breadcrumbs, isNotEmpty);
        final last = breadcrumbs.last;
        expect(last.action, 'api:request');
        expect(last.detail, 'GET /foo');
      },
    );

    test('onError forwards (error, stackTrace) to TraceRecorder + handler', () {
      final fakeRecorder = _FakeTraceRecorder();
      final container = ProviderContainer(overrides: [
        traceRecorderProvider.overrideWithValue(fakeRecorder),
      ]);
      addTearDown(container.dispose);

      late Ref capturedRef;
      final refCapture = Provider<int>((ref) {
        capturedRef = ref;
        return 0;
      });
      container.read(refCapture);

      final interceptor = DioTraceInterceptor(capturedRef);
      final handler = _CapturingErrorHandler();
      final stack = StackTrace.current;
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/boom'),
        type: DioExceptionType.connectionError,
        error: 'connection refused',
        stackTrace: stack,
      );

      interceptor.onError(dioErr, handler);

      expect(fakeRecorder.recordCount, 1);
      expect(fakeRecorder.capturedError, same(dioErr));
      expect(fakeRecorder.capturedStack, same(stack));

      expect(handler.nextCount, 1);
      expect(handler.lastError, same(dioErr));
    });

    test('onRequest: empty path still produces "METHOD " endpoint', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      late Ref capturedRef;
      final refCapture = Provider<int>((ref) {
        capturedRef = ref;
        return 0;
      });
      container.read(refCapture);

      final interceptor = DioTraceInterceptor(capturedRef);
      final handler = _CapturingRequestHandler();
      final options = RequestOptions(method: 'POST', path: '/');

      interceptor.onRequest(options, handler);

      expect(handler.nextCount, 1);
      final breadcrumbs = BreadcrumbCollector.snapshot();
      expect(breadcrumbs.last.action, 'api:request');
      expect(breadcrumbs.last.detail, startsWith('POST '));
    });
  });
}

/// Minimal NoSQL stub for storageRepositoryProvider — only the two methods
/// `AppStateCollector.collect` reads need to return null/empty values.
class _NullStorage implements StorageRepository {
  @override
  String? getActiveProfileId() => null;

  @override
  Map<String, dynamic>? getProfile(String id) => null;

  @override
  noSuchMethod(Invocation invocation) => null;
}
