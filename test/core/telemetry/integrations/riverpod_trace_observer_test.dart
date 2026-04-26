import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/integrations/riverpod_trace_observer.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/core/logging/error_logger.dart';

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
    setUp(() => errorLogger.resetForTest());
    tearDown(() => errorLogger.resetForTest());

    test(
      'providerDidFail forwards (error, stackTrace) to errorLogger',
      () async {
        final fakeRecorder = _FakeTraceRecorder();
        // After #1104 the observer routes through `errorLogger.log`,
        // which is bound here directly via the test seam so we skip
        // standing up a full Riverpod TraceRecorder.
        errorLogger.testRecorderOverride = fakeRecorder;

        late ProviderContainer container;
        final observer =
            _DeferredObserver((c) => RiverpodTraceObserver(c));
        container = ProviderContainer(observers: [observer]);
        observer.attach(container);
        addTearDown(container.dispose);

        // Trigger a build error → Riverpod will invoke providerDidFail on
        // every observer with the original error + stackTrace.
        // (Riverpod 3.x re-throws as ProviderException; the observer still
        // receives the original StateError.)
        expect(() => container.read(_exploding), throwsA(isA<Object>()));

        // The observer fires-and-forgets the future; pump microtasks so
        // the async `record` call lands before assertions run.
        await Future<void>.delayed(Duration.zero);

        expect(fakeRecorder.recordCount, 1);
        // Wrapped error preserves the original StateError in its
        // toString() so log triage can still see the message.
        expect(fakeRecorder.capturedError, isNotNull);
        expect(fakeRecorder.capturedError.toString(), contains('boom'));
        expect(fakeRecorder.capturedError.toString(), contains('providers'));
        expect(fakeRecorder.capturedStack, isNotNull);
      },
    );

    test('multiple failing reads each forward to the logger', () async {
      final fakeRecorder = _FakeTraceRecorder();
      errorLogger.testRecorderOverride = fakeRecorder;

      late ProviderContainer container;
      final observer = _DeferredObserver((c) => RiverpodTraceObserver(c));
      container = ProviderContainer(observers: [observer]);
      observer.attach(container);
      addTearDown(container.dispose);

      expect(() => container.read(_exploding), throwsA(isA<Object>()));
      // Invalidate so the build runs again on the next read.
      container.invalidate(_exploding);
      expect(() => container.read(_exploding), throwsA(isA<Object>()));

      await Future<void>.delayed(Duration.zero);
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
