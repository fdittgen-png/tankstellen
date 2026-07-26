// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3610 — save()/delete() document a log-never-rethrow contract (their
// call sites fire-and-forget), so the #2349 gate demands the fault
// injection: a throwing box must not propagate.
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/vehicle/data/repositories/service_reminder_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';

import '../../../../helpers/silence_error_logger.dart';

class _ThrowingBox extends Fake implements Box<String> {
  @override
  Future<void> put(dynamic key, String value) async =>
      throw HiveError('disk full');

  @override
  bool containsKey(dynamic key) => true;

  @override
  Future<void> delete(dynamic key) async => throw HiveError('disk full');
}

void main() {
  silenceErrorLoggerSpool();

  const reminder = ServiceReminder(
    id: 'r1',
    vehicleId: 'v1',
    label: 'Oil change',
    intervalKm: 15000,
  );

  test('save() returns normally when the box write throws (#2349 fault '
      'injection — logged, never rethrown)', () async {
    final repo = ServiceReminderRepository(_ThrowingBox());
    await expectLater(repo.save(reminder), completes);
  });

  test('delete() returns normally when the box delete throws', () async {
    final repo = ServiceReminderRepository(_ThrowingBox());
    await expectLater(repo.delete('r1'), completes);
  });
}
