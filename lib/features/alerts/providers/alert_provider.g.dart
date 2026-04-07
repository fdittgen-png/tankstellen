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

String _$alertNotifierHash() => r'8735ffc899b32f314dd61963a1d195bce93bd469';

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
