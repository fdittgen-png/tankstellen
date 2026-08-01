// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/guarded.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Records what reached the trace layer so each helper's logging
/// contract can be asserted, and can be told to *throw* so the
/// "never throws" promise is fault-injected rather than assumed.
class _CapturingRecorder implements TraceRecorder {
  _CapturingRecorder({this.throwOnRecord = false});

  final bool throwOnRecord;
  final captured = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    if (throwOnRecord) {
      throw StateError('recorder is down');
    }
    captured.add(error);
  }

  @override
  noSuchMethod(Invocation invocation) => null;
}

void main() {
  late _CapturingRecorder recorder;

  setUp(() {
    recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(() => errorLogger.resetForTest());

  group('logFailure', () {
    test('routes the error to the trace layer with its `where` tag', () async {
      logFailure(
        StateError('boom'),
        StackTrace.current,
        where: 'UnitTest: deliberate',
      );
      await Future<void>.delayed(Duration.zero);

      expect(recorder.captured, hasLength(1));
      expect(recorder.captured.single.toString(), contains('UnitTest: deliberate'));
    });

    test('merges `extra` context without letting it overwrite `where`', () async {
      logFailure(
        StateError('boom'),
        StackTrace.current,
        where: 'canonical',
        extra: const {'where': 'impostor', 'vehicleId': 'v1'},
      );
      await Future<void>.delayed(Duration.zero);

      final text = recorder.captured.single.toString();
      expect(text, contains('canonical'));
      expect(text, contains('v1'));
      expect(text, isNot(contains('impostor')));
    });

    test('never throws when the recorder itself throws', () async {
      errorLogger.testRecorderOverride =
          _CapturingRecorder(throwOnRecord: true);

      expect(
        () => logFailure(
          StateError('boom'),
          StackTrace.current,
          where: 'UnitTest: recorder down',
        ),
        returnsNormally,
      );
      // Let the unawaited future settle so a rethrow would surface.
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('guard', () {
    test('returns the action value when it succeeds', () {
      expect(
        guard(() => 42, where: 'UnitTest: ok', fallback: 0),
        42,
      );
    });

    test('returns the fallback and logs when the action throws', () async {
      final value = guard<int>(
        () => throw StateError('lookup failed'),
        where: 'UnitTest: guard',
        fallback: -1,
      );
      await Future<void>.delayed(Duration.zero);

      expect(value, -1);
      expect(recorder.captured, hasLength(1));
    });

    test('never throws even when the recorder is down', () {
      errorLogger.testRecorderOverride =
          _CapturingRecorder(throwOnRecord: true);

      expect(
        () => guard<int>(
          () => throw StateError('x'),
          where: 'UnitTest: both down',
          fallback: 7,
        ),
        returnsNormally,
      );
    });
  });

  group('guardAsync', () {
    test('returns the awaited value when it succeeds', () async {
      expect(
        await guardAsync(() async => 'ok', where: 'UnitTest', fallback: 'no'),
        'ok',
      );
    });

    test('returns the fallback when the future rejects', () async {
      final value = await guardAsync<String>(
        () => Future<String>.error(StateError('nope')),
        where: 'UnitTest: guardAsync',
        fallback: 'fallback',
      );

      expect(value, 'fallback');
      expect(recorder.captured, hasLength(1));
    });

    test('never throws when the recorder is also down', () async {
      errorLogger.testRecorderOverride =
          _CapturingRecorder(throwOnRecord: true);

      await expectLater(
        guardAsync<int>(
          () => Future<int>.error(StateError('x')),
          where: 'UnitTest',
          fallback: 0,
        ),
        completion(0),
      );
    });
  });

  group('runGuarded', () {
    Widget host(void Function(BuildContext) onReady) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              onReady(context);
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        );

    testWidgets('returns true and shows nothing on success', (tester) async {
      var ran = false;
      late BuildContext ctx;
      await tester.pumpWidget(host((c) => ctx = c));

      final ok = await runGuarded(
        ctx,
        where: 'UnitTest: success',
        errorText: 'should not appear',
        action: () async => ran = true,
      );
      await tester.pump();

      expect(ok, isTrue);
      expect(ran, isTrue);
      expect(find.text('should not appear'), findsNothing);
      expect(recorder.captured, isEmpty);
    });

    testWidgets('returns false, logs, and shows the snackbar on failure',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(host((c) => ctx = c));

      final ok = await runGuarded(
        ctx,
        where: 'UnitTest: failure',
        errorText: 'Sharing failed',
        action: () => Future<void>.error(StateError('nope')),
      );
      await tester.pump();

      expect(ok, isFalse);
      expect(recorder.captured, hasLength(1));
      expect(find.text('Sharing failed'), findsOneWidget);
    });

    testWidgets('does not touch an unmounted context', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(host((c) => ctx = c));
      // Replace the tree so `ctx` is no longer mounted.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      // The unmounted context must not be dereferenced for the snackbar.
      await expectLater(
        runGuarded(
          ctx,
          where: 'UnitTest: unmounted',
          errorText: 'never shown',
          action: () => Future<void>.error(StateError('nope')),
        ),
        completion(isFalse),
      );
      await tester.pump();
      expect(find.text('never shown'), findsNothing);
    });

    testWidgets('a null context is accepted and logs without a snackbar',
        (tester) async {
      final ok = await runGuarded(
        null,
        where: 'UnitTest: no context',
        errorText: 'unreachable',
        action: () => Future<void>.error(StateError('nope')),
      );

      expect(ok, isFalse);
      expect(recorder.captured, hasLength(1));
    });

    testWidgets(
      'never throws when the context has NO ScaffoldMessenger ancestor',
      (tester) async {
        // The regression this pins: surfacing the toast through a helper
        // that resolves the messenger with `ScaffoldMessenger.of` THREW
        // here — out of runGuarded's own catch block. A bare WidgetsApp
        // pump (no MaterialApp, no Scaffold) is exactly that context.
        late BuildContext ctx;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            builder: (context, _) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        );

        await expectLater(
          runGuarded(
            ctx,
            where: 'UnitTest: no messenger ancestor',
            errorText: 'silently untoastable',
            action: () => Future<void>.error(StateError('nope')),
          ),
          completion(isFalse),
        );
        // Traced, not toasted — and above all, not thrown.
        expect(recorder.captured, hasLength(1));
      },
    );

    testWidgets('never throws when the recorder is also down', (tester) async {
      errorLogger.testRecorderOverride =
          _CapturingRecorder(throwOnRecord: true);
      late BuildContext ctx;
      await tester.pumpWidget(host((c) => ctx = c));

      await expectLater(
        runGuarded(
          ctx,
          where: 'UnitTest: everything down',
          action: () => Future<void>.error(StateError('x')),
        ),
        completion(isFalse),
      );
    });
  });
}
