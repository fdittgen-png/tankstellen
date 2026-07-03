// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/classic_connect_cooldown.dart';
import 'package:tankstellen/features/obd2/data/classic_elm_channel.dart';
import 'package:tankstellen/features/obd2/data/classic_method_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_platform_budgets.dart';
import '../../../helpers/silence_error_logger.dart';

/// Fake [Obd2ClassicMethodChannel] that records the budgetMs the channel
/// threads through and can be armed to HANG (a wedged platform thread).
class _BudgetFakePlugin extends Obd2ClassicMethodChannel {
  _BudgetFakePlugin();

  final List<int?> budgets = [];
  bool hang = false;

  final StreamController<List<int>> incomingController =
      StreamController<List<int>>.broadcast();

  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
    int? budgetMs, // #3421
  }) async {
    budgets.add(budgetMs);
    if (hang) {
      // Never completes — models the #3415 t5/t8 wedged native connect.
      return Completer<ClassicConnectResult>().future;
    }
    return (ok: true, strategy: 'secure', error: null);
  }

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  Future<void> dispose() async {
    if (!incomingController.isClosed) await incomingController.close();
  }
}

void main() {
  silenceErrorLoggerSpool();
  late _BudgetFakePlugin fake;
  late int nowMs;
  late List<Duration> cooldownWaits;
  late ClassicConnectCooldown cooldown;

  setUp(() {
    fake = _BudgetFakePlugin();
    nowMs = 500000;
    cooldownWaits = [];
    // Frozen fake clock + recording no-op wait: the tests below advance
    // [nowMs] explicitly, so nothing sleeps real time.
    cooldown = ClassicConnectCooldown(
      now: () => DateTime.fromMillisecondsSinceEpoch(nowMs),
      wait: (d) async => cooldownWaits.add(d),
    );
  });

  tearDown(() async {
    await fake.dispose();
  });

  ClassicElmChannel channel({int? budgetMs, Duration? grace}) =>
      ClassicElmChannel(
        address: 'AA:BB',
        plugin: fake,
        cooldown: cooldown,
        connectBudgetMs:
            budgetMs ?? Obd2PlatformBudgets.classicConnectLadderBudgetMs,
        deadlineGrace: grace ?? Obd2PlatformBudgets.classicConnectDartGrace,
      );

  group('#3421 — whole-ladder budget threading', () {
    test('open() threads the default budget to the plugin', () async {
      final ch = channel();
      await ch.open();
      expect(
        fake.budgets,
        [Obd2PlatformBudgets.classicConnectLadderBudgetMs],
      );
      await ch.close();
    });

    test('a custom connectBudgetMs is threaded verbatim', () async {
      final ch = channel(budgetMs: 5000);
      await ch.open();
      expect(fake.budgets, [5000]);
      await ch.close();
    });
  });

  group('#3421 — post-close cooldown at the re-open seam', () {
    test(
        'close() of a LIVE link then a rapid re-open waits the 1.5 s gap '
        'and counts it INSIDE the budget (native gets budget − waited)',
        () async {
      final ch = channel();
      await ch.open(); // no stamp yet → no wait
      expect(cooldownWaits, isEmpty);
      await ch.close(); // stamps lastCloseAt for AA:BB at nowMs

      // Re-open immediately (the fake clock has not advanced): the full
      // 1500 ms gap must be waited and subtracted from the native budget.
      await ch.open();
      expect(cooldownWaits, [const Duration(milliseconds: 1500)]);
      expect(
        fake.budgets.last,
        Obd2PlatformBudgets.classicConnectLadderBudgetMs - 1500,
      );
      await ch.close();
    });

    test('an unexpected DROP also stamps the cooldown', () async {
      final ch = channel();
      await ch.open();
      // A benign Classic drop signature on the reader stream — the channel's
      // onError flips `_open` and `_signalDrop` stamps the cooldown.
      fake.incomingController.addError(
        StateError('bt socket closed, read return: -1'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(ch.isOpen, isFalse);

      await ch.open(); // reconnect attempt right after the drop
      expect(cooldownWaits, [const Duration(milliseconds: 1500)]);
      await ch.close();
    });

    test('a close() after a FAILED open does NOT stamp (open-retry rungs '
        'stay unpaced)', () async {
      final failing = _FailingOpenPlugin();
      final ch = ClassicElmChannel(
        address: 'AA:BB',
        plugin: failing,
        cooldown: cooldown,
      );
      await expectLater(ch.open(), throwsA(isA<Obd2AdapterUnresponsive>()));
      await ch.close(); // the transport's #2906 inter-attempt teardown
      await expectLater(ch.open(), throwsA(isA<Obd2AdapterUnresponsive>()));
      expect(cooldownWaits, isEmpty,
          reason: 'no link was ever live, so there is nothing to cool down');
    });
  });

  group('#3421 — Dart-side deadline (defense-in-depth)', () {
    test(
        'a wedged platform thread cannot hold open() past budget + grace — '
        'TimeoutException instead of the field 4.7–16.8 min hangs', () async {
      fake.hang = true;
      final ch = channel(
        budgetMs: 60,
        grace: const Duration(milliseconds: 40),
      );
      await expectLater(
        ch.open(),
        throwsA(isA<TimeoutException>()),
      );
      expect(ch.isOpen, isFalse);
    });

    test('a healthy connect is untouched by the deadline', () async {
      final ch = channel(
        budgetMs: 60,
        grace: const Duration(milliseconds: 40),
      );
      await ch.open();
      expect(ch.isOpen, isTrue);
      await ch.close();
    });
  });
}

/// Plugin whose connect cleanly fails (ok:false) — the channel raises the
/// typed Obd2AdapterUnresponsive BEFORE `_open` flips, so a close() that
/// follows must not stamp the cooldown.
class _FailingOpenPlugin extends Obd2ClassicMethodChannel {
  _FailingOpenPlugin();

  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
    int? budgetMs, // #3421
  }) async =>
      (ok: false, strategy: 'exhausted', error: 'rfcomm open failed');

  @override
  Future<void> disconnect() async {}

  @override
  Stream<List<int>> get incoming => const Stream<List<int>>.empty();
}
