// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/core/telemetry/upload/trace_uploader.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

/// Fake TraceStorage that records calls in memory.
class _FakeTraceStorage extends TraceStorage {
  final stored = <ErrorTrace>[];

  @override
  Future<void> store(ErrorTrace trace) async {
    stored.add(trace);
  }

  @override
  List<ErrorTrace> getAll() => stored;

  @override
  ErrorTrace? getById(String id) =>
      stored.where((t) => t.id == id).firstOrNull;
}

/// Minimal fake StorageRepository for provider overrides.
class _FakeStorageRepository extends Mock implements StorageRepository {}

/// Minimal fake SettingsStorage for the uploader constructor.
class _FakeSettingsStorage implements SettingsStorage {
  @override
  dynamic getSetting(String key) => null;

  @override
  Future<void> putSetting(String key, dynamic value) async {}

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}

/// #2745 — a stand-in for the supabase `AuthRetryableFetchException`. The
/// de-noise gate classifies it by RUNTIME-TYPE NAME + offline substring (so
/// the core telemetry layer carries no supabase import), hence the class
/// name literally matches the real one and its `toString()` carries the
/// wrapped socket message. (A separate fidelity test in
/// `test/core/network/dio_offline_test.dart` drives the REAL supabase class.)
class _FakeAuthRetryableFetchException implements Exception {
  final String _message;
  const _FakeAuthRetryableFetchException(this._message);

  @override
  Type get runtimeType => AuthRetryableFetchException;

  @override
  String toString() =>
      'AuthRetryableFetchException(message: $_message, statusCode: null)';
}

/// Marker type whose NAME the de-noise gate matches on (`runtimeType
/// .toString()`). Declaring it here keeps the telemetry test supabase-free.
class AuthRetryableFetchException {}

/// Fake TraceUploader that does nothing.
class _FakeTraceUploader extends TraceUploader {
  bool uploadCalled = false;
  ErrorTrace? lastTrace;

  _FakeTraceUploader() : super(_FakeSettingsStorage());

  @override
  Future<void> uploadIfEnabled(ErrorTrace trace) async {
    uploadCalled = true;
    lastTrace = trace;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTraceStorage storage;
  late _FakeTraceUploader uploader;
  late TraceRecorder recorder;
  late ProviderContainer container;

  setUp(() {
    // Mock the connectivity_plus method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return ['wifi'];
        }
        return null;
      },
    );

    storage = _FakeTraceStorage();
    uploader = _FakeTraceUploader();

    // Provide overrides so storage-dependent providers don't fail.
    container = ProviderContainer(overrides: [
      storageRepositoryProvider.overrideWithValue(_FakeStorageRepository()),
    ]);

    // Capture a Ref from the container via a temporary provider.
    late Ref capturedRef;
    final refCapture = Provider<int>((ref) {
      capturedRef = ref;
      return 0;
    });
    container.read(refCapture);

    recorder = TraceRecorder(storage, uploader, capturedRef);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      null,
    );
    container.dispose();
  });

  group('TraceRecorder', () {
    test('recording an error creates an ErrorTrace in storage', () async {
      final error = Exception('something went wrong');
      final stack = StackTrace.current;

      await recorder.record(error, stack);

      expect(storage.stored, hasLength(1));
      final trace = storage.stored.first;
      expect(trace.errorMessage, contains('something went wrong'));
      expect(trace.errorType, contains('Exception'));
      expect(trace.category, ErrorCategory.unknown);
      expect(trace.id, isNotEmpty);
      expect(trace.stackTrace, isNotEmpty);
    });

    test('recording with stack trace preserves stack info', () async {
      final error = Exception('test');
      final stack = StackTrace.current;

      await recorder.record(error, stack);

      final trace = storage.stored.first;
      expect(trace.stackTrace, contains('trace_recorder_test.dart'));
    });

    test('traces are stored via TraceStorage and uploaded', () async {
      await recorder.record(Exception('x'), StackTrace.current);

      expect(storage.stored, hasLength(1));
      expect(uploader.uploadCalled, isTrue);
      expect(uploader.lastTrace, isNotNull);
      expect(uploader.lastTrace!.id, storage.stored.first.id);
    });

    test('ServiceChainExhaustedException builds chain snapshot', () async {
      const error = ServiceChainExhaustedException(errors: [
        'Service A failed',
        'Service B failed',
      ]);

      await recorder.record(error, StackTrace.current);

      final trace = storage.stored.first;
      expect(trace.category, ErrorCategory.serviceChain);
      expect(trace.serviceChainState, isNotNull);
      expect(trace.serviceChainState!.attempts, hasLength(2));
    });

    test('timezone offset is formatted correctly', () async {
      await recorder.record(Exception('tz'), StackTrace.current);

      final trace = storage.stored.first;
      // Should match +HH:MM or -HH:MM pattern
      expect(trace.timezoneOffset, matches(RegExp(r'^[+-]\d{2}:\d{2}$')));
    });

    test('multiple recordings create independent traces', () async {
      await recorder.record(Exception('first'), StackTrace.current);
      await recorder.record(Exception('second'), StackTrace.current);

      expect(storage.stored, hasLength(2));
      expect(storage.stored[0].id, isNot(storage.stored[1].id));
      expect(storage.stored[0].errorMessage, contains('first'));
      expect(storage.stored[1].errorMessage, contains('second'));
    });

    test('ApiException is classified as api error', () async {
      const error = ApiException(message: 'rate limited', statusCode: 429);
      await recorder.record(error, StackTrace.current);

      final trace = storage.stored.first;
      expect(trace.category, ErrorCategory.api);
      expect(trace.errorMessage, contains('rate limited'));
    });

    test('CacheException is classified as cache error', () async {
      const error = CacheException(message: 'corrupted');
      await recorder.record(error, StackTrace.current);

      expect(storage.stored.first.category, ErrorCategory.cache);
    });

    test('recorded trace includes network state', () async {
      await recorder.record(Exception('net'), StackTrace.current);

      final trace = storage.stored.first;
      expect(trace.networkState, isNotNull);
      expect(trace.networkState.isOnline, isA<bool>());
    });

    // #1394 — when the error arrives wrapped in [ContextualError]
    // (i.e. via `errorLogger.log`), the recorder must unwrap it so the
    // category reflects the real layer and the errorType reflects the
    // root exception class — not the wrapper.
    test('ContextualError is unwrapped: category from layer + type from inner',
        () async {
      final wrapped = ContextualError(
        layer: ErrorLayer.services,
        error: Exception('boom'),
        context: null,
      );
      await recorder.record(wrapped, StackTrace.current);

      final trace = storage.stored.first;
      expect(trace.category, ErrorCategory.api,
          reason: 'services layer must infer api, not unknown');
      expect(trace.errorType, contains('Exception'),
          reason: 'errorType must reflect the unwrapped exception, '
              'not the ContextualError wrapper');
      expect(trace.errorMessage, contains('[services]'),
          reason: 'wrapper toString preserves the layer prefix for grep');
    });

    test('ContextualError preserves classifier match for known types',
        () async {
      // ApiException carries enough type info on its own — the
      // classifier should still win even when the wrapper is present.
      final wrapped = ContextualError(
        layer: ErrorLayer.ui,
        error: const ApiException(message: 'rate limited', statusCode: 429),
        context: null,
      );
      await recorder.record(wrapped, StackTrace.current);

      expect(storage.stored.first.category, ErrorCategory.api,
          reason: 'ApiException stays api — layer fallback only fires '
              'when classifier returns unknown');
    });

    // #2671 — benign offline/cancelled transients are EXPECTED, not errors.
    // They must NOT be persisted as error traces (no store, no upload) so
    // the error log stays signal-rich. The filter lives in `record()` so
    // EVERY caller path (dio interceptor, errorLogger.log, service chain)
    // is covered.
    group('benign-transient suppression (#2671)', () {
      test('a "Failed host lookup" SocketException is NOT persisted',
          () async {
        const error =
            SocketException('Failed host lookup: supabase.co');
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'offline DNS failure must not be stored');
        expect(uploader.uploadCalled, isFalse,
            reason: 'offline DNS failure must not be uploaded');
      });

      test(
          'a "Failed host lookup" SocketException wrapped in ContextualError '
          'is NOT persisted (matches on the unwrapped error)', () async {
        final wrapped = ContextualError(
          layer: ErrorLayer.services,
          error: const SocketException('Failed host lookup: supabase.co'),
          context: null,
        );
        await recorder.record(wrapped, StackTrace.current);

        expect(storage.stored, isEmpty);
        expect(uploader.uploadCalled, isFalse);
      });

      test('a cancelled DioException is NOT persisted', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/stations'),
          type: DioExceptionType.cancel,
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'user-cancelled request must not be stored');
        expect(uploader.uploadCalled, isFalse,
            reason: 'user-cancelled request must not be uploaded');
      });

      test(
          'a NON-cancel DioException (genuine failure) IS still persisted',
          () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/stations'),
          type: DioExceptionType.badResponse,
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, hasLength(1),
            reason: 'a real API failure must still be recorded');
        expect(uploader.uploadCalled, isTrue);
      });

      test('a genuine ApiException still persists (filter is narrow)',
          () async {
        const error = ApiException(message: 'boom', statusCode: 500);
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, hasLength(1),
            reason: 'a genuine API error must still be recorded');
        expect(uploader.uploadCalled, isTrue);
      });

      test(
          'a non-host-lookup SocketException (e.g. connection refused) IS '
          'still persisted', () async {
        const error = SocketException('Connection refused');
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, hasLength(1),
            reason: 'only host-lookup (offline DNS) is benign; a refused '
                'connection is a real failure worth a trace');
      });
    });

    // #2703 — the field shapes from the southern-France route corridor that
    // slipped through the #2671 filter: a DioException[connectionError] that
    // WRAPS the host-lookup SocketException, a DioException[connectionTimeout]
    // (the 4 UK-feed timeouts), a DioException[unknown] wrapping a
    // SocketException, and a bare HttpException connection-abort. These are
    // expected transients and must NOT persist; a badResponse (4xx/5xx) and a
    // connection-refused SocketException (while ONLINE) still must.
    group('connection-layer transient suppression (#2703)', () {
      test(
          'a DioException[connectionError] wrapping a host-lookup '
          'SocketException is NOT persisted', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/stations'),
          type: DioExceptionType.connectionError,
          error: const SocketException('Failed host lookup: api2.krlmedia.com'),
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'a connectionError wrapping a host lookup is offline');
        expect(uploader.uploadCalled, isFalse);
      });

      test('a DioException[connectionTimeout] is NOT persisted', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/stations'),
          type: DioExceptionType.connectionTimeout,
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'a connection timeout is an expected transient (#2703)');
        expect(uploader.uploadCalled, isFalse);
      });

      test('a DioException[receiveTimeout] is NOT persisted', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/stations'),
          type: DioExceptionType.receiveTimeout,
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty);
      });

      test(
          'a DioException[unknown] wrapping a SocketException is NOT persisted',
          () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/stations'),
          type: DioExceptionType.unknown,
          error: const SocketException('Connection failed'),
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'an unknown Dio error wrapping a SocketException is '
                'an offline transient on some platforms (#2703)');
      });

      test('a bare HttpException (connection abort) is NOT persisted',
          () async {
        const error = HttpException('Software caused connection abort');
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'a raw socket-layer connection abort is a transient');
      });

      test(
          'a DioException[badResponse] (a real 4xx/5xx) IS still persisted '
          '— the filter never suppresses a server answer', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/stations'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/stations'),
            statusCode: 503,
          ),
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, hasLength(1),
            reason: 'a 5xx is a real server error and must persist (#2703)');
        expect(uploader.uploadCalled, isTrue);
      });
    });

    // #2745 — error-log #14: offline host-lookup shapes that arrive WITHOUT a
    // Dio wrapper slipped through the #2703 gate and ERROR-logged. The central
    // de-noise gate now suppresses them via the broadened `isOfflineError`
    // superset: a supabase `AuthRetryableFetchException(host lookup)` (traces
    // #2–4), an on-device geocoder `PlatformException(IO_ERROR/UNAVAILABLE)`
    // (trace #7), and a `DioException[unknown]` wrapping an `HttpException`
    // connection-abort (FR trace #1). The guard: a GENUINE failure persists.
    group('offline-without-Dio-wrapper suppression (#2745)', () {
      test(
          'a supabase AuthRetryableFetchException wrapping a host lookup is '
          'NOT persisted (traces #2–4)', () async {
        const error = SocketException(
          'Failed host lookup: abc.supabase.co '
          '(OS Error: No address associated with hostname, errno = 7)',
        );
        // The supabase client surfaces this as an AuthRetryableFetchException
        // carrying the socket message; match the field shape via toString.
        final wrapped = _FakeAuthRetryableFetchException(error.toString());
        await recorder.record(wrapped, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'an offline supabase retryable fetch is a transient');
        expect(uploader.uploadCalled, isFalse);
      });

      test(
          'an on-device geocoder PlatformException(IO_ERROR, UNAVAILABLE) is '
          'NOT persisted (trace #7)', () async {
        final error = PlatformException(
          code: 'IO_ERROR',
          message: 'grpc failed: UNAVAILABLE: Unable to resolve host',
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'the offline native geocoder IO error is a transient');
      });

      test(
          'a DioException[unknown] wrapping an HttpException connection-abort '
          'is NOT persisted (FR trace #1)', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/records'),
          type: DioExceptionType.unknown,
          error: const HttpException('Software caused connection abort'),
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'an unknown Dio error wrapping a connection-abort is '
                'offline (the FR feed dropped the socket)');
      });

      test(
          'a GENUINE AuthRetryableFetchException (real 5xx, no offline '
          'substring) IS still persisted', () async {
        const error =
            _FakeAuthRetryableFetchException('Internal Server Error (500)');
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, hasLength(1),
            reason: 'a non-offline retryable fetch is a real failure');
        expect(uploader.uploadCalled, isTrue);
      });

      test(
          'a GENUINE PlatformException (not an offline IO error) IS still '
          'persisted', () async {
        final error = PlatformException(
          code: 'PARSE_ERROR',
          message: 'malformed placemark payload',
        );
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, hasLength(1),
            reason: 'a real platform fault must still ERROR-log');
      });
    });

    // #2703 — the offline SECONDARY signal: with the connectivity probe
    // reporting `none`, a network-category transient with NO offline-specific
    // shape (a generic TimeoutException) is still suppressed. The default
    // setUp mock reports `wifi` (online); this group re-mocks `none`.
    group('offline secondary signal (#2703)', () {
      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'check') {
              return <String>['none'];
            }
            return null;
          },
        );
      });

      test('a generic TimeoutException while offline is NOT persisted',
          () async {
        final error = TimeoutException('request timed out');
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'a network call made while offline is a doomed transient');
        expect(uploader.uploadCalled, isFalse);
      });

      test(
          'a connection-refused SocketException while offline is suppressed '
          '(it would persist while online)', () async {
        const error = SocketException('Connection refused');
        await recorder.record(error, StackTrace.current);

        expect(storage.stored, isEmpty,
            reason: 'offline → any socket failure is an expected transient');
      });
    });
  });
}
