// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/widget_launch_probe.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// #4319 / #4317 — the home-widget cold-launch probe starts before
/// storage. These tests drive the REAL `home_widget` Dart API over a mocked
/// method channel, so what they prove is the plugin's actual call surface.
class _CapturingRecorder implements TraceRecorder {
  final captured = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async =>
      captured.add(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late _CapturingRecorder recorder;

  setUp(() {
    calls = [];
    recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
    BreadcrumbCollector.clear();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    errorLogger.resetForTest();
    BreadcrumbCollector.clear();
  });

  void mockPlugin(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  test('the group id is SENT before the launch probe — the order every later '
      'widget write depends on on iOS', () async {
    mockPlugin((call) async => call.method == 'initiallyLaunchedFromHomeWidget'
        ? 'tankstellenwidget://station?id=de-1'
        : true);

    await WidgetLaunchProbe().start();

    expect(calls.map((c) => c.method),
        ['setAppGroupId', 'initiallyLaunchedFromHomeWidget']);
  });

  test('the probe does not depend on the group id: it answers while '
      'setAppGroupId never does', () async {
    final never = Completer<Object?>();
    mockPlugin((call) => call.method == 'setAppGroupId'
        ? never.future
        : Future.value('tankstellenwidget://station?id=de-7'));

    final probe = WidgetLaunchProbe();
    final uri = await probe.start();

    expect(uri, Uri.parse('tankstellenwidget://station?id=de-7'));
    expect(
      calls.singleWhere((c) => c.method == 'initiallyLaunchedFromHomeWidget')
          .arguments,
      isNull,
      reason: 'the probe carries no group id argument',
    );
  });

  test('a plugin that never answers costs exactly the 200 ms cap', () {
    fakeAsync((clock) {
      final probe = WidgetLaunchProbe(
        setGroupId: () async {},
        readLaunchUri: () => Completer<Uri?>().future,
      );
      Uri? result = Uri.parse('sentinel:');
      var done = false;
      unawaited(probe.start().then((uri) {
        result = uri;
        done = true;
      }));

      clock.elapse(const Duration(milliseconds: 199));
      expect(done, isFalse);
      clock.elapse(const Duration(milliseconds: 1));
      expect(done, isTrue);
      expect(result, isNull);
    });
  });

  test('a failure is held, not logged, until after the bind', () async {
    final probe = WidgetLaunchProbe(
      setGroupId: () async => throw PlatformException(code: 'no-group'),
      readLaunchUri: () async => throw PlatformException(code: 'boom'),
    );

    await expectLater(probe.start(), completion(isNull));
    await pumpEventQueue();
    expect(recorder.captured, isEmpty,
        reason: 'a pre-bind log would create the spool box file before the '
            '#4118 key check looks for box files');

    await probe.reportAfterBind();
    expect(recorder.captured, hasLength(1));
    await expectLater(probe.groupId!.rethrowFailure(),
        throwsA(isA<PlatformException>()));
  });

  test('a timeout is reported as a breadcrumb, not an error trace', () {
    fakeAsync((clock) {
      final probe = WidgetLaunchProbe(
        setGroupId: () async {},
        readLaunchUri: () => Completer<Uri?>().future,
      );
      unawaited(probe.start());
      clock.elapse(WidgetLaunchProbe.defaultCap);
      unawaited(probe.reportAfterBind());
      clock.flushMicrotasks();
    });
    expect(recorder.captured, isEmpty);
    expect(BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('widget-launch-probe-timeout'));
  });
}
