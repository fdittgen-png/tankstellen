import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/error_tracing/storage/isolate_error_spool.dart';
import 'package:tankstellen/core/error_tracing/storage/isolate_error_spool_entry.dart';
import 'package:tankstellen/core/error_tracing/trace_recorder.dart';
import 'package:tankstellen/core/logging/error_logger.dart';

/// Captured arguments for the foreground writer seam.
class _ForegroundCall {
  _ForegroundCall({
    required this.recorder,
    required this.error,
    required this.stackTrace,
    required this.layer,
    required this.context,
    required this.classification,
  });

  final TraceRecorder recorder;
  final Object error;
  final StackTrace stackTrace;
  final String layer;
  final Map<String, Object?>? context;
  final ErrorClassification? classification;
}

/// Captured arguments for the background writer seam.
class _BackgroundCall {
  _BackgroundCall({
    required this.layer,
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.classification,
  });

  final String layer;
  final Object error;
  final StackTrace? stackTrace;
  final Map<String, Object?>? context;
  final ErrorClassification? classification;
}

/// Stand-in TraceRecorder. We never invoke `.record()` because the
/// foreground writer seam is replaced with a captor in every test that
/// enters the foreground path — but [_RoutingErrorLogger] still needs
/// *some* recorder reference to satisfy the null check before
/// dispatching.
class _StubTraceRecorder implements TraceRecorder {
  @override
  noSuchMethod(Invocation invocation) {
    throw StateError(
      '_StubTraceRecorder.${invocation.memberName} called — the foreground '
      'writer seam should have intercepted this call',
    );
  }
}

/// Minimal in-memory `Box<String>` substitute — only the surface that
/// `IsolateErrorSpool.enqueue` exercises is implemented (`put`,
/// `length`, `keys`, `delete`, `clear`, `get`). Keeps the integration
/// test free of `Hive.initFlutter` / `path_provider` setup.
class _FakeBox implements Box<String> {
  final Map<String, String> store = <String, String>{};

  @override
  Future<void> put(dynamic key, String value) async {
    store[key as String] = value;
  }

  @override
  String? get(dynamic key, {String? defaultValue}) =>
      store[key as String] ?? defaultValue;

  @override
  int get length => store.length;

  @override
  Iterable<dynamic> get keys => store.keys;

  @override
  Future<void> delete(dynamic key) async {
    store.remove(key as String);
  }

  @override
  Future<int> clear() async {
    final n = store.length;
    store.clear();
    return n;
  }

  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      '_FakeBox.${invocation.memberName} is not implemented',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<_ForegroundCall> fgCalls;
  late List<_BackgroundCall> bgCalls;
  late _StubTraceRecorder stubRecorder;

  setUp(() {
    fgCalls = [];
    bgCalls = [];
    stubRecorder = _StubTraceRecorder();

    // Replace both writer seams with captors that record arguments
    // verbatim so each test can assert exact forwarding without
    // touching Hive or Riverpod.
    debugSetForegroundWriterForTesting((
      recorder,
      error,
      stackTrace,
      layer,
      context,
      classification,
    ) async {
      fgCalls.add(_ForegroundCall(
        recorder: recorder,
        error: error,
        stackTrace: stackTrace,
        layer: layer,
        context: context,
        classification: classification,
      ));
    });
    debugSetBackgroundWriterForTesting((
      layer,
      error,
      stackTrace,
      context,
      classification,
    ) async {
      bgCalls.add(_BackgroundCall(
        layer: layer,
        error: error,
        stackTrace: stackTrace,
        context: context,
        classification: classification,
      ));
    });
  });

  tearDown(() {
    debugResetForegroundForTesting();
    debugResetErrorLoggerForTesting();
    debugResetWritersForTesting();
    IsolateErrorSpool.resetBoxFactoryForTest();
  });

  group('errorLogger.log — mode detection', () {
    test('default (no markForeground) routes to background spool', () async {
      // No debugSetForegroundForTesting → flag stays false → background.
      await errorLogger.log(
        'BackgroundService',
        Exception('boom'),
        StackTrace.current,
      );

      expect(fgCalls, isEmpty);
      expect(bgCalls, hasLength(1));
      expect(bgCalls.single.layer, 'BackgroundService');
    });

    test('after debugSetForegroundForTesting → routes to TraceRecorder',
        () async {
      debugSetForegroundForTesting(
        isForeground: true,
        recorder: stubRecorder,
      );

      await errorLogger.log(
        'StationService',
        Exception('foreground boom'),
        StackTrace.current,
      );

      expect(fgCalls, hasLength(1));
      expect(bgCalls, isEmpty);
      expect(fgCalls.single.layer, 'StationService');
      expect(fgCalls.single.recorder, same(stubRecorder));
    });

    test(
      'foreground flag set but recorder null → falls through to background',
      () async {
        debugSetForegroundForTesting(isForeground: true, recorder: null);

        await errorLogger.log(
          'StationService',
          Exception('boom'),
          StackTrace.current,
        );

        expect(fgCalls, isEmpty);
        expect(bgCalls, hasLength(1),
            reason: 'null recorder must not silently drop the error');
      },
    );
  });

  group('errorLogger.log — foreground forwarding', () {
    setUp(() {
      debugSetForegroundForTesting(
        isForeground: true,
        recorder: stubRecorder,
      );
    });

    test('forwards every arg verbatim (layer, error, stack, context, class)',
        () async {
      final stack = StackTrace.fromString('fake-stack-1');
      final err = Exception('foreground-arg-test');
      final ctx = <String, Object?>{
        'stationId': 'st-42',
        'attempt': 3,
        'isStale': true,
      };

      await errorLogger.log(
        'StationServiceChain',
        err,
        stack,
        context: ctx,
        classification: ErrorClassification.network,
      );

      expect(fgCalls, hasLength(1));
      final call = fgCalls.single;
      expect(call.layer, 'StationServiceChain');
      expect(call.error, same(err));
      expect(call.stackTrace, same(stack));
      expect(call.context, ctx);
      expect(call.classification, ErrorClassification.network);
    });

    test('null stackTrace is replaced with a real StackTrace.current', () async {
      // The foreground pipeline (`TraceRecorder.record`) requires a
      // non-null StackTrace, so the router substitutes
      // `StackTrace.current` rather than passing null. We verify the
      // substitution happens but don't assert on the trace's content
      // (which depends on the Dart runtime's frame layout).
      await errorLogger.log(
        'Layer',
        Exception('e'),
        null,
      );

      expect(fgCalls, hasLength(1));
      expect(fgCalls.single.stackTrace, isNotNull);
      expect(fgCalls.single.stackTrace, isA<StackTrace>());
    });

    test('null context and null classification forward as null', () async {
      await errorLogger.log(
        'Layer',
        Exception('e'),
        StackTrace.fromString('s'),
      );

      expect(fgCalls, hasLength(1));
      expect(fgCalls.single.context, isNull);
      expect(fgCalls.single.classification, isNull);
    });
  });

  group('errorLogger.log — background forwarding', () {
    test('forwards layer/error/stack/context/classification verbatim',
        () async {
      final stack = StackTrace.fromString('bg-stack-1');
      final err = Exception('bg-arg-test');
      final ctx = <String, Object?>{
        'taskName': 'refreshPrices',
        'alertId': 'alert-7',
      };

      await errorLogger.log(
        'background.refreshPrices',
        err,
        stack,
        context: ctx,
        classification: ErrorClassification.api,
      );

      expect(bgCalls, hasLength(1));
      final call = bgCalls.single;
      expect(call.layer, 'background.refreshPrices');
      expect(call.error, same(err));
      expect(call.stackTrace, same(stack));
      expect(call.context, ctx);
      expect(call.classification, ErrorClassification.api);
    });

    test('null stackTrace forwards null (no synthesized trace)', () async {
      // For the background path we DO forward null — the spool's
      // `enqueue` synthesizes `StackTrace.current` itself if needed.
      // The router must not invent a fake trace because that would
      // hide the async-gap context the spool wants to capture.
      await errorLogger.log(
        'Layer',
        Exception('e'),
        null,
      );

      expect(bgCalls, hasLength(1));
      expect(bgCalls.single.stackTrace, isNull);
    });

    test('null context and null classification forward as null', () async {
      await errorLogger.log(
        'Layer',
        Exception('e'),
        StackTrace.fromString('s'),
      );

      expect(bgCalls, hasLength(1));
      expect(bgCalls.single.context, isNull);
      expect(bgCalls.single.classification, isNull);
    });
  });

  group('errorLogger.log — defensive contract', () {
    test('a throwing background writer is swallowed (no rethrow)', () async {
      debugSetBackgroundWriterForTesting((
        layer,
        error,
        stackTrace,
        context,
        classification,
      ) async {
        throw StateError('downstream Hive failure');
      });

      // Must not throw — observability failures cannot derail callers.
      await expectLater(
        errorLogger.log(
          'BackgroundService',
          Exception('boom'),
          StackTrace.current,
        ),
        completes,
      );
    });

    test('a throwing foreground writer is swallowed (no rethrow)', () async {
      debugSetForegroundForTesting(
        isForeground: true,
        recorder: stubRecorder,
      );
      debugSetForegroundWriterForTesting((
        recorder,
        error,
        stackTrace,
        layer,
        context,
        classification,
      ) async {
        throw StateError('downstream TraceRecorder failure');
      });

      await expectLater(
        errorLogger.log(
          'StationService',
          Exception('boom'),
          StackTrace.current,
        ),
        completes,
      );
    });
  });

  group('errorLogger.log — production background path → spool', () {
    // Integration-ish: hand the production `_writeBackground` a fake
    // Hive box and assert the spool sees the right entry shape. The
    // captor tests above prove the router forwards args; this proves
    // the production writer maps them onto `IsolateErrorSpool.enqueue`.
    setUp(() {
      debugResetWritersForTesting();
    });

    test(
      'production writer maps layer→isolateTaskName and merges classification',
      () async {
        // Mock path_provider so Hive's plugin probe doesn't fail when
        // the production writer reaches into IsolateErrorSpool. We
        // fully replace the box factory below so this is belt-and-
        // suspenders, but `Hive.initFlutter` isn't required because
        // boxFactory short-circuits the open path.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => '.',
        );

        final fake = _FakeBox();
        IsolateErrorSpool.boxFactory = () async => fake;

        await errorLogger.log(
          'background.refreshPrices',
          Exception('integration-boom'),
          StackTrace.fromString('integration-stack'),
          context: {'alertId': 'a-7'},
          classification: ErrorClassification.api,
        );

        expect(fake.store, hasLength(1));
        final raw = fake.store.values.single;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final entry = IsolateErrorSpoolEntry.fromJson(json);
        expect(entry.isolateTaskName, 'background.refreshPrices');
        expect(entry.errorMessage, contains('integration-boom'));
        expect(entry.contextMap['alertId'], 'a-7');
        expect(entry.contextMap['_classification'], 'api');
      },
    );
  });
}
