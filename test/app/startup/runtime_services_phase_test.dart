// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/runtime_services_phase.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/alerts/background/background_service.dart';

/// #4317 — notification init, the background scheduler and the home-widget
/// answer left the splash → app critical path. These tests RUN the phase
/// (#4116: a source scan proves text, not behaviour).
class _CapturingRecorder implements TraceRecorder {
  final captured = <ContextualError>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    if (error is ContextualError) captured.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingFetcher implements BackgroundPriceFetcher {
  int opportunisticScans = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleOpportunisticScan() async => opportunisticScans++;
}

RuntimeServices _services({
  Future<void> Function()? notifications,
  Future<void> Function()? reconcile,
  Future<void> Function()? wake,
  Future<void> Function()? homeWidget,
}) =>
    RuntimeServices(
      initNotifications: notifications ?? () async {},
      reconcileBackground: reconcile ?? () async {},
      opportunisticWake: wake ?? () async {},
      homeWidgetSetup: homeWidget ?? () async {},
    );

void main() {
  late _CapturingRecorder recorder;

  setUp(() {
    recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
    RuntimeServicesPhase.resetForTest();
    StartupTimer.instance.reset();
  });

  tearDown(() {
    errorLogger.resetForTest();
    RuntimeServicesPhase.resetForTest();
    StartupTimer.instance.reset();
  });

  group('failure isolation', () {
    test('a failing service is logged with its name and siblings still run',
        () async {
      var backgroundRan = false;
      var wakeRan = false;
      var widgetRan = false;

      await expectLater(
        RuntimeServicesPhase.run(_services(
          notifications: () async => throw StateError('plugin exploded'),
          reconcile: () async => backgroundRan = true,
          wake: () async => wakeRan = true,
          homeWidget: () async => widgetRan = true,
        )),
        completes,
      );

      expect([backgroundRan, wakeRan, widgetRan], everyElement(isTrue));
      expect(recorder.captured, hasLength(1));
      expect(recorder.captured.single.layer, ErrorLayer.background);
      expect(recorder.captured.single.context,
          containsPair('service', 'notifications'));
      expect(recorder.captured.single.inner, isA<StateError>());
    });

    test('a failing reconcile does not cancel the opportunistic wake', () async {
      var wakeRan = false;
      await RuntimeServicesPhase.run(_services(
        reconcile: () => Future<void>.error(Exception('workmanager')),
        wake: () async => wakeRan = true,
      ));
      expect(wakeRan, isTrue);
      expect(recorder.captured.single.context,
          containsPair('service', 'background'));
    });

    test('a notification init that never completes does not hold the others',
        () async {
      final never = Completer<void>();
      final backgroundDone = Completer<void>();
      final widgetDone = Completer<void>();

      unawaited(RuntimeServicesPhase.run(_services(
        notifications: () => never.future,
        wake: () async => backgroundDone.complete(),
        homeWidget: () async => widgetDone.complete(),
      )));

      await expectLater(
          Future.wait([backgroundDone.future, widgetDone.future]), completes);
      expect(never.isCompleted, isFalse);
    });
  });

  group('the background slot', () {
    test('reconcile runs before the opportunistic wake, and the wake runs once',
        () async {
      final order = <String>[];
      await RuntimeServicesPhase.run(_services(
        reconcile: () async => order.add('reconcile'),
        wake: () async => order.add('wake'),
      ));
      expect(order, ['reconcile', 'wake']);
    });

    test('with active alerts, a cold launch schedules exactly one '
        'opportunistic scan through the real BackgroundService gate', () async {
      final fetcher = _CountingFetcher();
      await RuntimeServicesPhase.run(_services(
        wake: () => BackgroundService.onOpportunisticWake(
          fetcher: fetcher,
          alertsGate: () async => true,
        ),
      ));
      expect(fetcher.opportunisticScans, 1);
    });

    test('without active alerts, no scan is scheduled', () async {
      final fetcher = _CountingFetcher();
      await RuntimeServicesPhase.run(_services(
        wake: () => BackgroundService.onOpportunisticWake(
          fetcher: fetcher,
          alertsGate: () async => false,
        ),
      ));
      expect(fetcher.opportunisticScans, 0);
    });
  });

  test('records the runtime_services_deferred span with per-service times',
      () async {
    StartupTimer.instance.start();
    await RuntimeServicesPhase.run(_services());

    final span = StartupTimer.instance.spans
        .singleWhere((s) => s.name == RuntimeServicesPhase.spanName);
    expect(span.endMs, greaterThanOrEqualTo(span.startMs));
    expect(span.attributes.keys, containsAll(<String>[
      'notificationsMs',
      'backgroundMs',
      'opportunistic_wakeMs',
      'home_widgetMs',
    ]));
  });

  group('scheduling', () {
    testWidgets('the app renders while every service is still pending — '
        'nothing starts before a frame', (tester) async {
      final never = Completer<void>();
      var started = 0;
      Future<void> hang() {
        started++;
        return never.future;
      }

      RuntimeServicesPhase.scheduleAfterFirstFrame(_services(
        notifications: hang,
        reconcile: hang,
        homeWidget: hang,
      ));
      expect(started, 0, reason: 'scheduling must not start any service');

      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('real app'),
      ));

      expect(find.text('real app'), findsOneWidget);
      expect(started, 3,
          reason: 'the services start from the post-frame callback');
    });

    testWidgets('a second schedule in the same process is ignored — no '
        'duplicate plugin init', (tester) async {
      var inits = 0;
      final services = _services(notifications: () async => inits++);

      RuntimeServicesPhase.scheduleAfterFirstFrame(services);
      RuntimeServicesPhase.scheduleAfterFirstFrame(services);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const SizedBox(width: 1));

      expect(inits, 1);
    });
  });

  group('SentPlatformCall', () {
    test('a failure is held — never an uncaught async error — and rethrown '
        'later with its original stack', () async {
      final uncaught = <Object>[];
      late SentPlatformCall call;

      await runZonedGuarded(() async {
        call = SentPlatformCall(() async {
          throw StateError('setAppGroupId failed');
        });
        // Let the failure settle with nobody listening yet.
        await Future<void>.delayed(Duration.zero);
      }, (e, _) => uncaught.add(e));

      expect(uncaught, isEmpty);
      await expectLater(call.rethrowFailure(), throwsA(isA<StateError>()));
      StackTrace? rethrown;
      await call.rethrowFailure().catchError(
          (Object _, StackTrace st) => rethrown = st);
      expect(rethrown.toString(), contains('runtime_services_phase_test.dart'),
          reason: 'the stack must be the one the call threw with');
    });

    test('a synchronous throw from the call is captured too', () async {
      final call = SentPlatformCall(() => throw ArgumentError('sync'));
      await expectLater(call.rethrowFailure(), throwsA(isA<ArgumentError>()));
    });

    test('the call is sent immediately, not when its answer is awaited', () {
      var sent = false;
      SentPlatformCall(() async => sent = true);
      expect(sent, isTrue);
    });

    test('a successful call resolves quietly', () async {
      await expectLater(SentPlatformCall(() async {}).rethrowFailure(), completes);
    });
  });
}
