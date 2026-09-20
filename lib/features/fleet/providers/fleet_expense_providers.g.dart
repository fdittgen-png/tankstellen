// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fleet_expense_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device expense store (#4215). keepAlive — it is a thin
/// wrapper over an encrypted Hive box, and a box that is not open
/// reads as empty, so it is safe to build in a widget test too.

@ProviderFor(fleetExpenseStore)
final fleetExpenseStoreProvider = FleetExpenseStoreProvider._();

/// The on-device expense store (#4215). keepAlive — it is a thin
/// wrapper over an encrypted Hive box, and a box that is not open
/// reads as empty, so it is safe to build in a widget test too.

final class FleetExpenseStoreProvider
    extends
        $FunctionalProvider<
          FleetExpenseStore,
          FleetExpenseStore,
          FleetExpenseStore
        >
    with $Provider<FleetExpenseStore> {
  /// The on-device expense store (#4215). keepAlive — it is a thin
  /// wrapper over an encrypted Hive box, and a box that is not open
  /// reads as empty, so it is safe to build in a widget test too.
  FleetExpenseStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetExpenseStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetExpenseStoreHash();

  @$internal
  @override
  $ProviderElement<FleetExpenseStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FleetExpenseStore create(Ref ref) {
    return fleetExpenseStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetExpenseStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetExpenseStore>(value),
    );
  }
}

String _$fleetExpenseStoreHash() => r'13062cd94be2f5865a73c3bd93c09f3b30c39458';

/// The state machine, wired to the app clock (#3660) so a test that
/// pins time sees the history entries it expects.

@ProviderFor(expenseStateMachine)
final expenseStateMachineProvider = ExpenseStateMachineProvider._();

/// The state machine, wired to the app clock (#3660) so a test that
/// pins time sees the history entries it expects.

final class ExpenseStateMachineProvider
    extends
        $FunctionalProvider<
          ExpenseStateMachine,
          ExpenseStateMachine,
          ExpenseStateMachine
        >
    with $Provider<ExpenseStateMachine> {
  /// The state machine, wired to the app clock (#3660) so a test that
  /// pins time sees the history entries it expects.
  ExpenseStateMachineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseStateMachineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseStateMachineHash();

  @$internal
  @override
  $ProviderElement<ExpenseStateMachine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExpenseStateMachine create(Ref ref) {
    return expenseStateMachine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseStateMachine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseStateMachine>(value),
    );
  }
}

String _$expenseStateMachineHash() =>
    r'119a3bcc84e1902407503aad97ebf84092bafb88';

/// Submit / approve / reject, over the same state machine.

@ProviderFor(fleetExpenseWorkflow)
final fleetExpenseWorkflowProvider = FleetExpenseWorkflowProvider._();

/// Submit / approve / reject, over the same state machine.

final class FleetExpenseWorkflowProvider
    extends
        $FunctionalProvider<
          FleetExpenseWorkflow,
          FleetExpenseWorkflow,
          FleetExpenseWorkflow
        >
    with $Provider<FleetExpenseWorkflow> {
  /// Submit / approve / reject, over the same state machine.
  FleetExpenseWorkflowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetExpenseWorkflowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetExpenseWorkflowHash();

  @$internal
  @override
  $ProviderElement<FleetExpenseWorkflow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FleetExpenseWorkflow create(Ref ref) {
    return fleetExpenseWorkflow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetExpenseWorkflow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetExpenseWorkflow>(value),
    );
  }
}

String _$fleetExpenseWorkflowHash() =>
    r'e61be7433bff64747db5c094c60b9c9072303260';

/// The reconciler, with its default tolerances.

@ProviderFor(expenseReconciler)
final expenseReconcilerProvider = ExpenseReconcilerProvider._();

/// The reconciler, with its default tolerances.

final class ExpenseReconcilerProvider
    extends
        $FunctionalProvider<
          ExpenseReconciler,
          ExpenseReconciler,
          ExpenseReconciler
        >
    with $Provider<ExpenseReconciler> {
  /// The reconciler, with its default tolerances.
  ExpenseReconcilerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseReconcilerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseReconcilerHash();

  @$internal
  @override
  $ProviderElement<ExpenseReconciler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExpenseReconciler create(Ref ref) {
    return expenseReconciler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseReconciler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseReconciler>(value),
    );
  }
}

String _$expenseReconcilerHash() => r'fc9e75bd186c8523c69e701ba20b331543d5700a';

/// Every expense this device holds, newest first.
///
/// The list is the screen's single source of truth: the review screen
/// looks its record up by id on every build rather than holding the
/// object it was pushed with, so a correction made in one place is
/// never rendered stale in another.

@ProviderFor(FleetExpenses)
final fleetExpensesProvider = FleetExpensesProvider._();

/// Every expense this device holds, newest first.
///
/// The list is the screen's single source of truth: the review screen
/// looks its record up by id on every build rather than holding the
/// object it was pushed with, so a correction made in one place is
/// never rendered stale in another.
final class FleetExpensesProvider
    extends $NotifierProvider<FleetExpenses, List<Expense>> {
  /// Every expense this device holds, newest first.
  ///
  /// The list is the screen's single source of truth: the review screen
  /// looks its record up by id on every build rather than holding the
  /// object it was pushed with, so a correction made in one place is
  /// never rendered stale in another.
  FleetExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetExpensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetExpensesHash();

  @$internal
  @override
  FleetExpenses create() => FleetExpenses();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Expense> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Expense>>(value),
    );
  }
}

String _$fleetExpensesHash() => r'4216158f30ab1d555634a6ce65fa2071ce09e1f2';

/// Every expense this device holds, newest first.
///
/// The list is the screen's single source of truth: the review screen
/// looks its record up by id on every build rather than holding the
/// object it was pushed with, so a correction made in one place is
/// never rendered stale in another.

abstract class _$FleetExpenses extends $Notifier<List<Expense>> {
  List<Expense> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Expense>, List<Expense>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Expense>, List<Expense>>,
              List<Expense>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// One expense by id, or null when this device does not hold it — the
/// state a deep link with a stale id must land on.

@ProviderFor(fleetExpenseById)
final fleetExpenseByIdProvider = FleetExpenseByIdFamily._();

/// One expense by id, or null when this device does not hold it — the
/// state a deep link with a stale id must land on.

final class FleetExpenseByIdProvider
    extends $FunctionalProvider<Expense?, Expense?, Expense?>
    with $Provider<Expense?> {
  /// One expense by id, or null when this device does not hold it — the
  /// state a deep link with a stale id must land on.
  FleetExpenseByIdProvider._({
    required FleetExpenseByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fleetExpenseByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fleetExpenseByIdHash();

  @override
  String toString() {
    return r'fleetExpenseByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Expense?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Expense? create(Ref ref) {
    final argument = this.argument as String;
    return fleetExpenseById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Expense? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Expense?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FleetExpenseByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fleetExpenseByIdHash() => r'9abe6d1060b284a3b9b165860daf753648189939';

/// One expense by id, or null when this device does not hold it — the
/// state a deep link with a stale id must land on.

final class FleetExpenseByIdFamily extends $Family
    with $FunctionalFamilyOverride<Expense?, String> {
  FleetExpenseByIdFamily._()
    : super(
        retry: null,
        name: r'fleetExpenseByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One expense by id, or null when this device does not hold it — the
  /// state a deep link with a stale id must land on.

  FleetExpenseByIdProvider call(String id) =>
      FleetExpenseByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'fleetExpenseByIdProvider';
}
