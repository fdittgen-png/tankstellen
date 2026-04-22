// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_reminders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared [ServiceReminderStore] instance. Kept alive for the app's
/// lifetime so the async notifier below can re-read it without
/// re-instantiating a store per operation.

@ProviderFor(serviceReminderStore)
final serviceReminderStoreProvider = ServiceReminderStoreProvider._();

/// Shared [ServiceReminderStore] instance. Kept alive for the app's
/// lifetime so the async notifier below can re-read it without
/// re-instantiating a store per operation.

final class ServiceReminderStoreProvider
    extends
        $FunctionalProvider<
          ServiceReminderStore,
          ServiceReminderStore,
          ServiceReminderStore
        >
    with $Provider<ServiceReminderStore> {
  /// Shared [ServiceReminderStore] instance. Kept alive for the app's
  /// lifetime so the async notifier below can re-read it without
  /// re-instantiating a store per operation.
  ServiceReminderStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceReminderStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceReminderStoreHash();

  @$internal
  @override
  $ProviderElement<ServiceReminderStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServiceReminderStore create(Ref ref) {
    return serviceReminderStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServiceReminderStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServiceReminderStore>(value),
    );
  }
}

String _$serviceReminderStoreHash() =>
    r'15f257b214e18316d83adc3deb6022ea44ec79f1';

/// Vehicle service-reminder state (#584 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] / [markServiced] for the phase-2 UI
/// layer. Mirrors the shape of `radiusAlertsProvider` so the two
/// feel familiar side-by-side in the Settings screen.

@ProviderFor(ServiceReminders)
final serviceRemindersProvider = ServiceRemindersProvider._();

/// Vehicle service-reminder state (#584 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] / [markServiced] for the phase-2 UI
/// layer. Mirrors the shape of `radiusAlertsProvider` so the two
/// feel familiar side-by-side in the Settings screen.
final class ServiceRemindersProvider
    extends $AsyncNotifierProvider<ServiceReminders, List<ServiceReminder>> {
  /// Vehicle service-reminder state (#584 phase 1).
  ///
  /// Loads the persisted list from the store on first read and exposes
  /// [add] / [remove] / [toggle] / [markServiced] for the phase-2 UI
  /// layer. Mirrors the shape of `radiusAlertsProvider` so the two
  /// feel familiar side-by-side in the Settings screen.
  ServiceRemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceRemindersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceRemindersHash();

  @$internal
  @override
  ServiceReminders create() => ServiceReminders();
}

String _$serviceRemindersHash() => r'4c2c91152aae4a95183e0ad5d5680e629edfea22';

/// Vehicle service-reminder state (#584 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] / [markServiced] for the phase-2 UI
/// layer. Mirrors the shape of `radiusAlertsProvider` so the two
/// feel familiar side-by-side in the Settings screen.

abstract class _$ServiceReminders
    extends $AsyncNotifier<List<ServiceReminder>> {
  FutureOr<List<ServiceReminder>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ServiceReminder>>, List<ServiceReminder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ServiceReminder>>,
                List<ServiceReminder>
              >,
              AsyncValue<List<ServiceReminder>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
