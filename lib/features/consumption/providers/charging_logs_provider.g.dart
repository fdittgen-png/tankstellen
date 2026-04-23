// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared [ChargingLogStore] instance. Kept alive for the app's
/// lifetime so the notifier below can re-read it without
/// instantiating a new store per operation — mirrors the shape of
/// [radiusAlertStoreProvider] (#578) and
/// [serviceReminderRepositoryProvider] (#584).

@ProviderFor(chargingLogStore)
final chargingLogStoreProvider = ChargingLogStoreProvider._();

/// Shared [ChargingLogStore] instance. Kept alive for the app's
/// lifetime so the notifier below can re-read it without
/// instantiating a new store per operation — mirrors the shape of
/// [radiusAlertStoreProvider] (#578) and
/// [serviceReminderRepositoryProvider] (#584).

final class ChargingLogStoreProvider
    extends
        $FunctionalProvider<
          ChargingLogStore,
          ChargingLogStore,
          ChargingLogStore
        >
    with $Provider<ChargingLogStore> {
  /// Shared [ChargingLogStore] instance. Kept alive for the app's
  /// lifetime so the notifier below can re-read it without
  /// instantiating a new store per operation — mirrors the shape of
  /// [radiusAlertStoreProvider] (#578) and
  /// [serviceReminderRepositoryProvider] (#584).
  ChargingLogStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chargingLogStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chargingLogStoreHash();

  @$internal
  @override
  $ProviderElement<ChargingLogStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChargingLogStore create(Ref ref) {
    return chargingLogStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChargingLogStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChargingLogStore>(value),
    );
  }
}

String _$chargingLogStoreHash() => r'9921ba627549e835218a3975c56a6c6996f8d327';

/// Charging-log list state (#582 phase 1).
///
/// Loads every persisted log on first read and exposes `add` /
/// `update` / `remove` mutators for the phase-2 UI layer. The
/// notifier shape follows the [RadiusAlerts] (#578) / [ServiceReminderList]
/// (#584) pattern: each mutator writes through the store, then
/// refreshes state from a fresh `store.list()` call so the list
/// stays canonical (including sort order).
///
/// [update] preserves the incoming [ChargingLog.id] and overwrites
/// every other field — the caller is expected to `copyWith` their
/// edits onto the existing entry before calling.

@ProviderFor(ChargingLogs)
final chargingLogsProvider = ChargingLogsProvider._();

/// Charging-log list state (#582 phase 1).
///
/// Loads every persisted log on first read and exposes `add` /
/// `update` / `remove` mutators for the phase-2 UI layer. The
/// notifier shape follows the [RadiusAlerts] (#578) / [ServiceReminderList]
/// (#584) pattern: each mutator writes through the store, then
/// refreshes state from a fresh `store.list()` call so the list
/// stays canonical (including sort order).
///
/// [update] preserves the incoming [ChargingLog.id] and overwrites
/// every other field — the caller is expected to `copyWith` their
/// edits onto the existing entry before calling.
final class ChargingLogsProvider
    extends $AsyncNotifierProvider<ChargingLogs, List<ChargingLog>> {
  /// Charging-log list state (#582 phase 1).
  ///
  /// Loads every persisted log on first read and exposes `add` /
  /// `update` / `remove` mutators for the phase-2 UI layer. The
  /// notifier shape follows the [RadiusAlerts] (#578) / [ServiceReminderList]
  /// (#584) pattern: each mutator writes through the store, then
  /// refreshes state from a fresh `store.list()` call so the list
  /// stays canonical (including sort order).
  ///
  /// [update] preserves the incoming [ChargingLog.id] and overwrites
  /// every other field — the caller is expected to `copyWith` their
  /// edits onto the existing entry before calling.
  ChargingLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chargingLogsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chargingLogsHash();

  @$internal
  @override
  ChargingLogs create() => ChargingLogs();
}

String _$chargingLogsHash() => r'4341211da6a46381ff0a370982ed159d64bc5acf';

/// Charging-log list state (#582 phase 1).
///
/// Loads every persisted log on first read and exposes `add` /
/// `update` / `remove` mutators for the phase-2 UI layer. The
/// notifier shape follows the [RadiusAlerts] (#578) / [ServiceReminderList]
/// (#584) pattern: each mutator writes through the store, then
/// refreshes state from a fresh `store.list()` call so the list
/// stays canonical (including sort order).
///
/// [update] preserves the incoming [ChargingLog.id] and overwrites
/// every other field — the caller is expected to `copyWith` their
/// edits onto the existing entry before calling.

abstract class _$ChargingLogs extends $AsyncNotifier<List<ChargingLog>> {
  FutureOr<List<ChargingLog>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ChargingLog>>, List<ChargingLog>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChargingLog>>, List<ChargingLog>>,
              AsyncValue<List<ChargingLog>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Derived view: every charging log attached to [vehicleId].
///
/// Mirrors the [serviceRemindersForVehicle] (#584) pattern — a
/// family-style selector is cheaper than making every screen filter
/// the full list by hand, and it isolates vehicle A's charts from
/// edits on vehicle B.

@ProviderFor(chargingLogsForVehicle)
final chargingLogsForVehicleProvider = ChargingLogsForVehicleFamily._();

/// Derived view: every charging log attached to [vehicleId].
///
/// Mirrors the [serviceRemindersForVehicle] (#584) pattern — a
/// family-style selector is cheaper than making every screen filter
/// the full list by hand, and it isolates vehicle A's charts from
/// edits on vehicle B.

final class ChargingLogsForVehicleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChargingLog>>,
          List<ChargingLog>,
          FutureOr<List<ChargingLog>>
        >
    with
        $FutureModifier<List<ChargingLog>>,
        $FutureProvider<List<ChargingLog>> {
  /// Derived view: every charging log attached to [vehicleId].
  ///
  /// Mirrors the [serviceRemindersForVehicle] (#584) pattern — a
  /// family-style selector is cheaper than making every screen filter
  /// the full list by hand, and it isolates vehicle A's charts from
  /// edits on vehicle B.
  ChargingLogsForVehicleProvider._({
    required ChargingLogsForVehicleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chargingLogsForVehicleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chargingLogsForVehicleHash();

  @override
  String toString() {
    return r'chargingLogsForVehicleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ChargingLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChargingLog>> create(Ref ref) {
    final argument = this.argument as String;
    return chargingLogsForVehicle(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChargingLogsForVehicleProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chargingLogsForVehicleHash() =>
    r'7d72c555879a02b13171185b796c076f8f173503';

/// Derived view: every charging log attached to [vehicleId].
///
/// Mirrors the [serviceRemindersForVehicle] (#584) pattern — a
/// family-style selector is cheaper than making every screen filter
/// the full list by hand, and it isolates vehicle A's charts from
/// edits on vehicle B.

final class ChargingLogsForVehicleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ChargingLog>>, String> {
  ChargingLogsForVehicleFamily._()
    : super(
        retry: null,
        name: r'chargingLogsForVehicleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Derived view: every charging log attached to [vehicleId].
  ///
  /// Mirrors the [serviceRemindersForVehicle] (#584) pattern — a
  /// family-style selector is cheaper than making every screen filter
  /// the full list by hand, and it isolates vehicle A's charts from
  /// edits on vehicle B.

  ChargingLogsForVehicleProvider call(String vehicleId) =>
      ChargingLogsForVehicleProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'chargingLogsForVehicleProvider';
}
