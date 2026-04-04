import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error_tracing/models/error_trace.dart';
import 'package:tankstellen/core/error_tracing/storage/trace_storage.dart';
import 'package:tankstellen/core/error_tracing/upload/trace_uploader.dart';
import 'package:tankstellen/core/error_tracing/trace_recorder.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

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

/// Minimal fake HiveStorage for the uploader constructor.
class _FakeHiveStorage extends HiveStorage {
  @override
  dynamic getSetting(String key) => null;

  @override
  Future<void> putSetting(String key, dynamic value) async {}

  @override
  String? getActiveProfileId() => null;

  @override
  Map<String, dynamic>? getProfile(String id) => null;
}

/// Fake TraceUploader that does nothing.
class _FakeTraceUploader extends TraceUploader {
  bool uploadCalled = false;
  ErrorTrace? lastTrace;

  _FakeTraceUploader() : super(_FakeHiveStorage());

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

    // Provide overrides so HiveStorage-dependent providers don't fail.
    container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(_FakeHiveStorage()),
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
  });
}
