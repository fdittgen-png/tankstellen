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

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 and the project leitmotiv in CLAUDE.md.

@ProviderFor(ecoScoreForFillUp)
final ecoScoreForFillUpProvider = EcoScoreForFillUpFamily._();

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 and the project leitmotiv in CLAUDE.md.

final class EcoScoreForFillUpProvider
    extends $FunctionalProvider<EcoScore?, EcoScore?, EcoScore?>
    with $Provider<EcoScore?> {
  /// Per-fill-up eco-score — compares this tank's L/100 km to the
  /// rolling average over the last 3 same-fuel-type fill-ups.
  ///
  /// Returns `null` for fill-ups where the score is not meaningful
  /// (first-ever fill-up, odometer rollback, no same-fuel history).
  /// Callers render nothing when the return is null.
  ///
  /// Keyed by fill-up id so the Riverpod graph invalidates just the
  /// affected card when a single fill-up is edited, not the whole list.
  /// See #676 and the project leitmotiv in CLAUDE.md.
  EcoScoreForFillUpProvider._({
    required EcoScoreForFillUpFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ecoScoreForFillUpProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ecoScoreForFillUpHash();

  @override
  String toString() {
    return r'ecoScoreForFillUpProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EcoScore?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EcoScore? create(Ref ref) {
    final argument = this.argument as String;
    return ecoScoreForFillUp(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EcoScore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EcoScore?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EcoScoreForFillUpProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ecoScoreForFillUpHash() => r'd73756e1f350917069211ef38a04a8d020682ca3';

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 and the project leitmotiv in CLAUDE.md.

final class EcoScoreForFillUpFamily extends $Family
    with $FunctionalFamilyOverride<EcoScore?, String> {
  EcoScoreForFillUpFamily._()
    : super(
        retry: null,
        name: r'ecoScoreForFillUpProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-fill-up eco-score — compares this tank's L/100 km to the
  /// rolling average over the last 3 same-fuel-type fill-ups.
  ///
  /// Returns `null` for fill-ups where the score is not meaningful
  /// (first-ever fill-up, odometer rollback, no same-fuel history).
  /// Callers render nothing when the return is null.
  ///
  /// Keyed by fill-up id so the Riverpod graph invalidates just the
  /// affected card when a single fill-up is edited, not the whole list.
  /// See #676 and the project leitmotiv in CLAUDE.md.

  EcoScoreForFillUpProvider call(String fillUpId) =>
      EcoScoreForFillUpProvider._(argument: fillUpId, from: this);

  @override
  String toString() => r'ecoScoreForFillUpProvider';
}
