// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/time/app_clock.dart';
import '../data/fleet_expense_workflow.dart';
import '../data/fleet_expense_store.dart';
import '../domain/expense.dart';
import '../domain/expense_reconciler.dart';
import '../domain/expense_state_machine.dart';

part 'fleet_expense_providers.g.dart';

/// The on-device expense store (#4215). keepAlive — it is a thin
/// wrapper over an encrypted Hive box, and a box that is not open
/// reads as empty, so it is safe to build in a widget test too.
@Riverpod(keepAlive: true)
FleetExpenseStore fleetExpenseStore(Ref ref) => FleetExpenseStore.hive();

/// The state machine, wired to the app clock (#3660) so a test that
/// pins time sees the history entries it expects.
@Riverpod(keepAlive: true)
ExpenseStateMachine expenseStateMachine(Ref ref) =>
    ExpenseStateMachine(clock: ref.watch(appClockProvider));

/// Submit / approve / reject, over the same state machine.
@Riverpod(keepAlive: true)
FleetExpenseWorkflow fleetExpenseWorkflow(Ref ref) => FleetExpenseWorkflow(
      stateMachine: ref.watch(expenseStateMachineProvider),
    );

/// The reconciler, with its default tolerances.
@Riverpod(keepAlive: true)
ExpenseReconciler expenseReconciler(Ref ref) => const ExpenseReconciler();

/// Every expense this device holds, newest first.
///
/// The list is the screen's single source of truth: the review screen
/// looks its record up by id on every build rather than holding the
/// object it was pushed with, so a correction made in one place is
/// never rendered stale in another.
@Riverpod(keepAlive: true)
class FleetExpenses extends _$FleetExpenses {
  @override
  List<Expense> build() => ref.watch(fleetExpenseStoreProvider).loadAll();

  /// Persist [expense] (insert or overwrite by id) and refresh.
  Future<void> upsert(Expense expense) async {
    final store = ref.read(fleetExpenseStoreProvider);
    await store.write(expense);
    state = store.loadAll();
  }

  /// Drop one expense from the device.
  Future<void> forget(String id) async {
    final store = ref.read(fleetExpenseStoreProvider);
    await store.forget(id);
    state = store.loadAll();
  }
}

/// One expense by id, or null when this device does not hold it — the
/// state a deep link with a stale id must land on.
@riverpod
Expense? fleetExpenseById(Ref ref, String id) {
  for (final expense in ref.watch(fleetExpensesProvider)) {
    if (expense.id == id) return expense;
  }
  return null;
}
