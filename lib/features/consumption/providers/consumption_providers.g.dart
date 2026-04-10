// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consumption_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for reading/writing [FillUp] entries.

@ProviderFor(fillUpRepository)
final fillUpRepositoryProvider = FillUpRepositoryProvider._();

/// Repository for reading/writing [FillUp] entries.

final class FillUpRepositoryProvider
    extends
        $FunctionalProvider<
          FillUpRepository,
          FillUpRepository,
          FillUpRepository
        >
    with $Provider<FillUpRepository> {
  /// Repository for reading/writing [FillUp] entries.
  FillUpRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fillUpRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fillUpRepositoryHash();

  @$internal
  @override
  $ProviderElement<FillUpRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FillUpRepository create(Ref ref) {
    return fillUpRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FillUpRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FillUpRepository>(value),
    );
  }
}

String _$fillUpRepositoryHash() => r'cc5e51ddaa9f996875c6e5bace204386b25f55dd';

/// Mutable list of all fill-ups, newest first.

@ProviderFor(FillUpList)
final fillUpListProvider = FillUpListProvider._();

/// Mutable list of all fill-ups, newest first.
final class FillUpListProvider
    extends $NotifierProvider<FillUpList, List<FillUp>> {
  /// Mutable list of all fill-ups, newest first.
  FillUpListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fillUpListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fillUpListHash();

  @$internal
  @override
  FillUpList create() => FillUpList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FillUp> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FillUp>>(value),
    );
  }
}

String _$fillUpListHash() => r'e2bb73e61f4e76be8d2bed3547d6e77ac20b092b';

/// Mutable list of all fill-ups, newest first.

abstract class _$FillUpList extends $Notifier<List<FillUp>> {
  List<FillUp> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<FillUp>, List<FillUp>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<FillUp>, List<FillUp>>,
              List<FillUp>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Aggregated stats derived from the current fill-up list.

@ProviderFor(consumptionStats)
final consumptionStatsProvider = ConsumptionStatsProvider._();

/// Aggregated stats derived from the current fill-up list.

final class ConsumptionStatsProvider
    extends
        $FunctionalProvider<
          ConsumptionStats,
          ConsumptionStats,
          ConsumptionStats
        >
    with $Provider<ConsumptionStats> {
  /// Aggregated stats derived from the current fill-up list.
  ConsumptionStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consumptionStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consumptionStatsHash();

  @$internal
  @override
  $ProviderElement<ConsumptionStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConsumptionStats create(Ref ref) {
    return consumptionStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsumptionStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsumptionStats>(value),
    );
  }
}

String _$consumptionStatsHash() => r'6613eff02126b04dc046d555deafd254b7211e9b';
