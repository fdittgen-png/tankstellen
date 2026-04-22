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

String _$alertNotifierHash() => r'02f0012d204217a9e97145c5085a1ea1c68511bb';

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
