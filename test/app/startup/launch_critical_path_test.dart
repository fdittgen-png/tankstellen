// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/launch_critical_path.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';
import 'package:tankstellen/features/widget/providers/pending_widget_uri_provider.dart';

/// #4319 — the launch prerequisites as a dependency graph. Every test
/// holds tasks open with completers and EXECUTES the production
/// orchestration; none sleeps, none reads source text.
void main() {
  setUp(StartupTimer.instance.reset);
  tearDown(StartupTimer.instance.reset);

  group('LaunchCriticalPath.run', () {
    late List<String> events;
    late Completer<Uri?> probe;
    late Completer<bool> storage;
    late int containersCreated;
    late ProviderContainer? created;

    setUp(() {
      events = [];
      probe = Completer<Uri?>();
      storage = Completer<bool>();
      containersCreated = 0;
      created = null;
    });

    tearDown(() => created?.dispose());

    Future<ProviderContainer?> launch({
      Future<void> Function()? dateFormatting,
    }) =>
        LaunchCriticalPath.run(
          probeWidgetLaunch: () {
            events.add('probe started');
            return probe.future;
          },
          storage: () {
            events.add('storage started');
            return storage.future;
          },
          dateFormatting: dateFormatting ??
              () async {
                events.add('dates');
              },
          createContainer: () {
            containersCreated++;
            events.add('container');
            return created = ProviderContainer();
          },
        );

    test('1 — with the widget probe held open, storage starts (and '
        'finishes) before the probe answers', () async {
      final result = launch();
      expect(events, containsAllInOrder(['probe started', 'storage started']));

      storage.complete(true);
      await pumpEventQueue();
      expect(probe.isCompleted, isFalse);
      expect(containersCreated, 0,
          reason: 'no container before the inbound-launch answer');

      probe.complete(null);
      expect(await result, isNotNull);
    });

    test('2 — with storage held open, the widget probe has already started',
        () async {
      final result = launch();
      expect(events.first, 'probe started',
          reason: 'the probe needs nothing and starts first');
      probe.complete(Uri.parse('tankstellenwidget://station?id=de-1'));
      await pumpEventQueue();
      expect(storage.isCompleted, isFalse);
      expect(containersCreated, 0);

      storage.complete(true);
      expect(await result, isNotNull);
    });

    test('date formatting runs while the storage phase is still pending',
        () async {
      final result = launch();
      expect(events, ['probe started', 'storage started', 'dates']);
      storage.complete(true);
      probe.complete(null);
      await result;
    });

    test('3 — the launch waits for BOTH the storage verdict and the widget '
        'answer, in either order', () async {
      var done = false;
      unawaited(launch().then((_) => done = true));

      probe.complete(null);
      await pumpEventQueue();
      expect(done, isFalse, reason: 'storage verdict still pending');

      storage.complete(true);
      await pumpEventQueue();
      expect(done, isTrue);
      expect(containersCreated, 1);
    });

    test('5 — a storage failure while the probe is still running launches '
        'nothing and leaks no async error', () async {
      final uncaught = <Object>[];
      ProviderContainer? result = ProviderContainer();

      await runZonedGuarded(() async {
        final pending = launch(
          dateFormatting: () async => throw StateError('dates exploded'),
        );
        storage.complete(false);
        result = await pending;
        // The independent probe settles AFTER the verdict.
        probe.complete(Uri.parse('tankstellenwidget://station?id=de-1'));
        await pumpEventQueue();
      }, (e, _) => uncaught.add(e));

      expect(result, isNull);
      expect(containersCreated, 0, reason: 'no real-app launch');
      expect(uncaught, isEmpty);
    });

    test('a date-formatting failure after a good storage verdict still '
        'fails the launch, as the unguarded await did before #4319', () async {
      final result = launch(
        dateFormatting: () async => throw StateError('dates exploded'),
      );
      storage.complete(true);
      probe.complete(null);
      await expectLater(result, throwsA(isA<StateError>()));
      expect(containersCreated, 0);
    });

    test('6 — the widget URI is on the container BEFORE it is returned to '
        'the launch (and so before the first redirect)', () async {
      final uri = Uri.parse('tankstellenwidget://station?id=de-42');
      final result = launch();
      probe.complete(uri);
      storage.complete(true);
      final container = await result;
      expect(container!.read(pendingWidgetUriProvider), uri);
    });

    test('no URI → nothing is stashed', () async {
      final result = launch();
      probe.complete(null);
      storage.complete(true);
      expect((await result)!.read(pendingWidgetUriProvider), isNull);
    });

    test('marks storage_ready and records overlapping spans', () async {
      StartupTimer.instance.start();
      final result = launch();
      storage.complete(true);
      await pumpEventQueue();
      probe.complete(null);
      await result;

      expect(StartupTimer.instance.milestones.map((m) => m.name),
          contains('storage_ready'));
      final names = StartupTimer.instance.spans.map((s) => s.name).toList();
      expect(names, containsAll(
          ['widget_launch_probe', 'storage_phase', 'date_formatting']));
      // The spans list is in completion order: the probe was started first
      // and finished last — it overlapped the whole storage phase.
      expect(names.indexOf('storage_phase'),
          lessThan(names.indexOf('widget_launch_probe')));
      final probeSpan = StartupTimer.instance.spans
          .firstWhere((s) => s.name == 'widget_launch_probe');
      final storageSpan = StartupTimer.instance.spans
          .firstWhere((s) => s.name == 'storage_phase');
      expect(probeSpan.startMs, lessThanOrEqualTo(storageSpan.startMs));
      expect(probeSpan.endMs, greaterThanOrEqualTo(storageSpan.endMs));
    });
  });

  group('LaunchCriticalPath.storagePhase', () {
    test('4 — with TraceStorage.init held open, the default profile is '
        'seeded as soon as the boxes are open', () async {
      final events = <String>[];
      final boxes = Completer<void>();
      final trace = Completer<void>();
      final profileSeeded = Completer<void>();

      final phase = LaunchCriticalPath.storagePhase(
        openBoxes: () {
          events.add('boxes');
          return boxes.future;
        },
        loadApiKeys: () async => events.add('keys'),
        seedDefaultProfile: () async {
          events.add('profile');
          profileSeeded.complete();
        },
        telemetry: {
          'trace_storage': () {
            events.add('trace');
            return trace.future;
          },
          'health_counters': () async => events.add('health'),
        },
      );

      await pumpEventQueue();
      expect(events, ['boxes'],
          reason: 'nothing may observe a partially opened store');

      boxes.complete();
      await profileSeeded.future;
      expect(trace.isCompleted, isFalse,
          reason: 'the profile seed no longer waits for telemetry');
      expect(events, containsAll(['keys', 'profile', 'trace', 'health']));

      var phaseDone = false;
      unawaited(phase.then((_) => phaseDone = true));
      await pumpEventQueue();
      expect(phaseDone, isFalse,
          reason: 'the phase itself still waits for every task');
      trace.complete();
      await phase;
    });

    test('a failing task still lets its siblings finish, and the phase '
        'rethrows the failure for the storage gate', () async {
      final trace = Completer<void>();
      var healthDone = false;
      final uncaught = <Object>[];
      Object? surfaced;

      await runZonedGuarded(() async {
        final phase = LaunchCriticalPath.storagePhase(
          openBoxes: () async {},
          loadApiKeys: () async => throw StateError('keystore'),
          seedDefaultProfile: () async => throw StateError('profile'),
          telemetry: {
            'trace_storage': () => trace.future,
            'health_counters': () async => healthDone = true,
          },
        );
        await pumpEventQueue();
        trace.complete();
        try {
          await phase;
        } on Object catch (e) {
          surfaced = e;
        }
      }, (e, _) => uncaught.add(e));

      expect(healthDone, isTrue);
      expect(surfaced, isA<StateError>());
      expect(uncaught, isEmpty,
          reason: 'the second failure must not escape unhandled');
    });

    test('a failing core-box open stops before any dependent task starts',
        () async {
      final started = <String>[];
      await expectLater(
        LaunchCriticalPath.storagePhase(
          openBoxes: () async => throw StateError('corrupt'),
          loadApiKeys: () async => started.add('keys'),
          seedDefaultProfile: () async => started.add('profile'),
          telemetry: {'trace_storage': () async => started.add('trace')},
        ),
        throwsA(isA<StateError>()),
      );
      expect(started, isEmpty);
    });
  });
}
