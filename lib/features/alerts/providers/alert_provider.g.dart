// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(alertRepository)
final alertRepositoryProvider = AlertRepositoryProvider._();

final class AlertRepositoryProvider
    extends
        $FunctionalProvider<AlertRepository, AlertRepository, AlertRepository>
    with $Provider<AlertRepository> {
  AlertRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertRepositoryHash();

  @$internal
  @override
  $ProviderElement<AlertRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertRepository create(Ref ref) {
    return alertRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertRepository>(value),
    );
  }
}

String _$alertRepositoryHash() => r'fc65d74649a3f18c253681736b245db8f6e43249';

/// Injectable merge function. Production code uses the real
/// [AlertsSync.merge]; tests override this provider with a fake.

@ProviderFor(alertsMergeFn)
final alertsMergeFnProvider = AlertsMergeFnProvider._();

/// Injectable merge function. Production code uses the real
/// [AlertsSync.merge]; tests override this provider with a fake.

final class AlertsMergeFnProvider
    extends $FunctionalProvider<AlertsMergeFn, AlertsMergeFn, AlertsMergeFn>
    with $Provider<AlertsMergeFn> {
  /// Injectable merge function. Production code uses the real
  /// [AlertsSync.merge]; tests override this provider with a fake.
  AlertsMergeFnProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertsMergeFnProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertsMergeFnHash();

  @$internal
  @override
  $ProviderElement<AlertsMergeFn> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertsMergeFn create(Ref ref) {
    return alertsMergeFn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertsMergeFn value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertsMergeFn>(value),
    );
  }
}

String _$alertsMergeFnHash() => r'6ec72990e3b88e6041de3ae2ae7711c643aaf6ec';

/// Injectable delete-propagation function. Production code uses the real
/// [AlertsSync.delete]; tests override this provider with a fake.

@ProviderFor(alertsDeleteFn)
final alertsDeleteFnProvider = AlertsDeleteFnProvider._();

/// Injectable delete-propagation function. Production code uses the real
/// [AlertsSync.delete]; tests override this provider with a fake.

final class AlertsDeleteFnProvider
    extends $FunctionalProvider<AlertsDeleteFn, AlertsDeleteFn, AlertsDeleteFn>
    with $Provider<AlertsDeleteFn> {
  /// Injectable delete-propagation function. Production code uses the real
  /// [AlertsSync.delete]; tests override this provider with a fake.
  AlertsDeleteFnProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertsDeleteFnProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertsDeleteFnHash();

  @$internal
  @override
  $ProviderElement<AlertsDeleteFn> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertsDeleteFn create(Ref ref) {
    return alertsDeleteFn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertsDeleteFn value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertsDeleteFn>(value),
    );
  }
}

String _$alertsDeleteFnHash() => r'ce5095f5a836ad87c3a46924b647902e6c998bcd';

@ProviderFor(AlertNotifier)
final alertProvider = AlertNotifierProvider._();

final class AlertNotifierProvider
    extends $NotifierProvider<AlertNotifier, List<PriceAlert>> {
  AlertNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertNotifierHash();

  @$internal
  @override
  AlertNotifier create() => AlertNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PriceAlert> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PriceAlert>>(value),
    );
  }
}

String _$alertNotifierHash() => r'f2060492020b95fe213f0a6ecbacce8330bb0f03';

abstract class _$AlertNotifier extends $Notifier<List<PriceAlert>> {
  List<PriceAlert> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<PriceAlert>, List<PriceAlert>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PriceAlert>, List<PriceAlert>>,
              List<PriceAlert>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// AsyncValue wrapper around [alertProvider] (#858).
///
/// The legacy [alertProvider] is a synchronous NotifierProvider, so if the
/// underlying storage throws on read the error propagates to
/// [ErrorWidget] with no retry affordance. This derived provider re-exposes
/// the same list as an [AsyncValue] so screens can render a proper
/// `ServiceChainErrorWidget` via `.when(..., error: ...)`.
///
/// Existing consumers of [alertProvider] keep working untouched; only
/// screens that want a user-visible error branch need to switch.

@ProviderFor(alertsAsync)
final alertsAsyncProvider = AlertsAsyncProvider._();

/// AsyncValue wrapper around [alertProvider] (#858).
///
/// The legacy [alertProvider] is a synchronous NotifierProvider, so if the
/// underlying storage throws on read the error propagates to
/// [ErrorWidget] with no retry affordance. This derived provider re-exposes
/// the same list as an [AsyncValue] so screens can render a proper
/// `ServiceChainErrorWidget` via `.when(..., error: ...)`.
///
/// Existing consumers of [alertProvider] keep working untouched; only
/// screens that want a user-visible error branch need to switch.

final class AlertsAsyncProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PriceAlert>>,
          AsyncValue<List<PriceAlert>>,
          AsyncValue<List<PriceAlert>>
        >
    with $Provider<AsyncValue<List<PriceAlert>>> {
  /// AsyncValue wrapper around [alertProvider] (#858).
  ///
  /// The legacy [alertProvider] is a synchronous NotifierProvider, so if the
  /// underlying storage throws on read the error propagates to
  /// [ErrorWidget] with no retry affordance. This derived provider re-exposes
  /// the same list as an [AsyncValue] so screens can render a proper
  /// `ServiceChainErrorWidget` via `.when(..., error: ...)`.
  ///
  /// Existing consumers of [alertProvider] keep working untouched; only
  /// screens that want a user-visible error branch need to switch.
  AlertsAsyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertsAsyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertsAsyncHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<PriceAlert>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<PriceAlert>> create(Ref ref) {
    return alertsAsync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<PriceAlert>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<PriceAlert>>>(value),
    );
  }
}

String _$alertsAsyncHash() => r'23ee8094c9602cfc97a335904ee5a97b617d351e';
