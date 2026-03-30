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

String _$alertRepositoryHash() => r'7560d4fc7b5c1b047758e5f5f4dd23eac00f7222';

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

String _$alertNotifierHash() => r'adae03f8a59473c9167c2702a5f9afc6eafd8059';

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
