import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error_tracing/integrations/riverpod_trace_observer.dart';
import 'package:tankstellen/core/error_tracing/models/error_trace.dart';
import 'package:tankstellen/core/error_tracing/trace_recorder.dart';

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

/// A provider whose build throws — used to drive the natural
/// `providerDidFail` path inside the Riverpod runtime so the test
/// exercises the observer end-to-end (no internal-API construction
/// of `ProviderObserverContext`).
final _exploding = Provider<int>((ref) {
  throw StateError('boom');
});

void main() {
  group('RiverpodTraceObserver', () {
    test(
      'providerDidFail forwards (error, stackTrace) to traceRecorderProvider',
      () {
        final fakeRecorder = _FakeTraceRecorder();

        // Build the container *first*, then attach the observer using the
        // explicit constructor argument — RiverpodTraceObserver(_container)
        // breaks the chicken-and-egg by storing the container reference.
        late ProviderContainer container;
        final observer =
            _DeferredObserver((c) => RiverpodTraceObserver(c));
        container = ProviderContainer(
          observers: [observer],
          overrides: [
            traceRecorderProvider.overrideWithValue(fakeRecorder),
          ],
        );
        observer.attach(container);
        addTearDown(container.dispose);

        // Trigger a build error → Riverpod will invoke providerDidFail on
        // every observer with the original error + stackTrace.
        // (Riverpod 3.x re-throws as ProviderException; the observer still
        // receives the original StateError.)
        expect(() => container.read(_exploding), throwsA(isA<Object>()));

        expect(fakeRecorder.recordCount, 1);
        expect(fakeRecorder.capturedError, isA<StateError>());
        expect(
          (fakeRecorder.capturedError as StateError).message,
          'boom',
        );
        expect(fakeRecorder.capturedStack, isNotNull);
      },
    );

    test('multiple failing reads each forward to the recorder', () {
      final fakeRecorder = _FakeTraceRecorder();
      late ProviderContainer container;
      final observer = _DeferredObserver((c) => RiverpodTraceObserver(c));
      container = ProviderContainer(
        observers: [observer],
        overrides: [
          traceRecorderProvider.overrideWithValue(fakeRecorder),
        ],
      );
      observer.attach(container);
      addTearDown(container.dispose);

      expect(() => container.read(_exploding), throwsA(isA<Object>()));
      // Invalidate so the build runs again on the next read.
      container.invalidate(_exploding);
      expect(() => container.read(_exploding), throwsA(isA<Object>()));

      expect(fakeRecorder.recordCount, 2);
    });
  });
}

/// Wrapper that lets us pass an observer to `ProviderContainer` and then
/// inject the container reference (resolves the chicken-and-egg without
/// touching `@internal` Riverpod APIs).
final class _DeferredObserver extends ProviderObserver {
  _DeferredObserver(this._build);
  final RiverpodTraceObserver Function(ProviderContainer) _build;
  RiverpodTraceObserver? _delegate;

  void attach(ProviderContainer container) {
    _delegate = _build(container);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _delegate?.providerDidFail(context, error, stackTrace);
  }
}
