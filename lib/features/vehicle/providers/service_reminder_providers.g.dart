// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_reminder_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for CRUD on [ServiceReminder] entries (#584).
///
/// Opens against the already-registered `service_reminders` Hive box
/// (see [HiveBoxes.serviceReminders]).

@ProviderFor(serviceReminderRepository)
final serviceReminderRepositoryProvider = ServiceReminderRepositoryProvider._();

/// Repository for CRUD on [ServiceReminder] entries (#584).
///
/// Opens against the already-registered `service_reminders` Hive box
/// (see [HiveBoxes.serviceReminders]).

final class ServiceReminderRepositoryProvider
    extends
        $FunctionalProvider<
          ServiceReminderRepository,
          ServiceReminderRepository,
          ServiceReminderRepository
        >
    with $Provider<ServiceReminderRepository> {
  /// Repository for CRUD on [ServiceReminder] entries (#584).
  ///
  /// Opens against the already-registered `service_reminders` Hive box
  /// (see [HiveBoxes.serviceReminders]).
  ServiceReminderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceReminderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceReminderRepositoryHash();

  @$internal
  @override
  $ProviderElement<ServiceReminderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServiceReminderRepository create(Ref ref) {
    return serviceReminderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServiceReminderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServiceReminderRepository>(value),
    );
  }
}

String _$serviceReminderRepositoryHash() =>
    r'b62354f1ce62244f630cbb67a12035c0b9f35cbd';

/// Evaluator that combines [ServiceReminderRepository] with the
/// app's [NotificationService]. Exposed as a provider so the fill-up
/// save path can fire it after a new fill-up is persisted.

@ProviderFor(serviceReminderEvaluator)
final serviceReminderEvaluatorProvider = ServiceReminderEvaluatorProvider._();

/// Evaluator that combines [ServiceReminderRepository] with the
/// app's [NotificationService]. Exposed as a provider so the fill-up
/// save path can fire it after a new fill-up is persisted.

final class ServiceReminderEvaluatorProvider
    extends
        $FunctionalProvider<
          ServiceReminderEvaluator,
          ServiceReminderEvaluator,
          ServiceReminderEvaluator
        >
    with $Provider<ServiceReminderEvaluator> {
  /// Evaluator that combines [ServiceReminderRepository] with the
  /// app's [NotificationService]. Exposed as a provider so the fill-up
  /// save path can fire it after a new fill-up is persisted.
  ServiceReminderEvaluatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceReminderEvaluatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceReminderEvaluatorHash();

  @$internal
  @override
  $ProviderElement<ServiceReminderEvaluator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServiceReminderEvaluator create(Ref ref) {
    return serviceReminderEvaluator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServiceReminderEvaluator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServiceReminderEvaluator>(value),
    );
  }
}

String _$serviceReminderEvaluatorHash() =>
    r'b46da525c9cea889a8a7c0c6f9ee484cc0c88835';

/// Mutable list of every stored reminder. Individual screens watch
/// [serviceRemindersForVehicle] — this provider is the source of
/// truth for the mutations.

@ProviderFor(ServiceReminderList)
final serviceReminderListProvider = ServiceReminderListProvider._();

/// Mutable list of every stored reminder. Individual screens watch
/// [serviceRemindersForVehicle] — this provider is the source of
/// truth for the mutations.
final class ServiceReminderListProvider
    extends $NotifierProvider<ServiceReminderList, List<ServiceReminder>> {
  /// Mutable list of every stored reminder. Individual screens watch
  /// [serviceRemindersForVehicle] — this provider is the source of
  /// truth for the mutations.
  ServiceReminderListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceReminderListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceReminderListHash();

  @$internal
  @override
  ServiceReminderList create() => ServiceReminderList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ServiceReminder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ServiceReminder>>(value),
    );
  }
}

String _$serviceReminderListHash() =>
    r'70cfd31b0c39b078716e14f1857bdc18b68d13d4';

/// Mutable list of every stored reminder. Individual screens watch
/// [serviceRemindersForVehicle] — this provider is the source of
/// truth for the mutations.

abstract class _$ServiceReminderList extends $Notifier<List<ServiceReminder>> {
  List<ServiceReminder> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ServiceReminder>, List<ServiceReminder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ServiceReminder>, List<ServiceReminder>>,
              List<ServiceReminder>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Derived list of reminders attached to a specific vehicle.
///
/// Vehicle-edit UI watches this instead of the global list so a
/// reminder change on one vehicle doesn't invalidate the edit screen
/// of another.

@ProviderFor(serviceRemindersForVehicle)
final serviceRemindersForVehicleProvider = ServiceRemindersForVehicleFamily._();

/// Derived list of reminders attached to a specific vehicle.
///
/// Vehicle-edit UI watches this instead of the global list so a
/// reminder change on one vehicle doesn't invalidate the edit screen
/// of another.

final class ServiceRemindersForVehicleProvider
    extends
        $FunctionalProvider<
          List<ServiceReminder>,
          List<ServiceReminder>,
          List<ServiceReminder>
        >
    with $Provider<List<ServiceReminder>> {
  /// Derived list of reminders attached to a specific vehicle.
  ///
  /// Vehicle-edit UI watches this instead of the global list so a
  /// reminder change on one vehicle doesn't invalidate the edit screen
  /// of another.
  ServiceRemindersForVehicleProvider._({
    required ServiceRemindersForVehicleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'serviceRemindersForVehicleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceRemindersForVehicleHash();

  @override
  String toString() {
    return r'serviceRemindersForVehicleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<ServiceReminder>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ServiceReminder> create(Ref ref) {
    final argument = this.argument as String;
    return serviceRemindersForVehicle(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ServiceReminder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ServiceReminder>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceRemindersForVehicleProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceRemindersForVehicleHash() =>
    r'ae77757632a19115643230f6b8d5abfe87cf4ff7';

/// Derived list of reminders attached to a specific vehicle.
///
/// Vehicle-edit UI watches this instead of the global list so a
/// reminder change on one vehicle doesn't invalidate the edit screen
/// of another.

final class ServiceRemindersForVehicleFamily extends $Family
    with $FunctionalFamilyOverride<List<ServiceReminder>, String> {
  ServiceRemindersForVehicleFamily._()
    : super(
        retry: null,
        name: r'serviceRemindersForVehicleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Derived list of reminders attached to a specific vehicle.
  ///
  /// Vehicle-edit UI watches this instead of the global list so a
  /// reminder change on one vehicle doesn't invalidate the edit screen
  /// of another.

  ServiceRemindersForVehicleProvider call(String vehicleId) =>
      ServiceRemindersForVehicleProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'serviceRemindersForVehicleProvider';
}
