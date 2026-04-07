import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';

void main() {
  late StartupTimer timer;

  setUp(() {
    timer = StartupTimer.instance;
    timer.reset();
  });

  tearDown(() {
    timer.reset();
  });

  group('StartupTimer', () {
    test('starts with clean state', () {
      expect(timer.isRunning, isFalse);
      expect(timer.milestones, isEmpty);
      expect(timer.totalMs, isNull);
    });

    test('start begins timing', () {
      timer.start();
      expect(timer.isRunning, isTrue);
    });

    test('mark records milestones in order', () {
      timer.start();
      timer.mark('step_a');
      timer.mark('step_b');
      timer.mark('step_c');

      expect(timer.milestones, hasLength(3));
      expect(timer.milestones[0].name, 'step_a');
      expect(timer.milestones[1].name, 'step_b');
      expect(timer.milestones[2].name, 'step_c');
    });

    test('milestones have non-decreasing elapsed times', () {
      timer.start();
      timer.mark('first');
      timer.mark('second');

      expect(timer.milestones[1].elapsedMs,
          greaterThanOrEqualTo(timer.milestones[0].elapsedMs));
    });

    test('finish stops timer and records totalMs', () {
      timer.start();
      timer.mark('init');
      timer.finish();

      expect(timer.isRunning, isFalse);
      expect(timer.totalMs, isNotNull);
      expect(timer.totalMs, greaterThanOrEqualTo(0));
    });

    test('finish is idempotent when not running', () {
      timer.finish();
      expect(timer.totalMs, isNull);
    });

    test('mark is ignored when timer is not running', () {
      timer.mark('should_not_appear');
      expect(timer.milestones, isEmpty);
    });

    test('start clears previous milestones', () {
      timer.start();
      timer.mark('old');
      timer.finish();

      timer.start();
      expect(timer.milestones, isEmpty);
      expect(timer.totalMs, isNull);
    });

    test('reset clears all state', () {
      timer.start();
      timer.mark('data');
      timer.finish();

      timer.reset();
      expect(timer.isRunning, isFalse);
      expect(timer.milestones, isEmpty);
      expect(timer.totalMs, isNull);
    });

    test('totalMs is >= last milestone elapsed time', () {
      timer.start();
      timer.mark('final_step');
      timer.finish();

      expect(timer.totalMs,
          greaterThanOrEqualTo(timer.milestones.last.elapsedMs));
    });

    test('milestones list is unmodifiable', () {
      timer.start();
      timer.mark('test');

      expect(
        () => timer.milestones.add(
          const StartupMilestone(name: 'hack', elapsedMs: 0),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('StartupMilestone', () {
    test('toString returns readable format', () {
      const milestone = StartupMilestone(name: 'hive_init', elapsedMs: 42);
      expect(milestone.toString(), 'StartupMilestone(hive_init, 42ms)');
    });

    test('stores name and elapsed time', () {
      const milestone = StartupMilestone(name: 'test', elapsedMs: 100);
      expect(milestone.name, 'test');
      expect(milestone.elapsedMs, 100);
    });
  });
}
