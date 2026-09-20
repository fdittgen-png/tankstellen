// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'driving_pattern_comparison_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Process-wide memo of per-trip totals (#4366). Bounded and
/// fingerprinted — see [DrivingPatternCache] for what invalidates one.

@ProviderFor(drivingPatternCache)
final drivingPatternCacheProvider = DrivingPatternCacheProvider._();

/// Process-wide memo of per-trip totals (#4366). Bounded and
/// fingerprinted — see [DrivingPatternCache] for what invalidates one.

final class DrivingPatternCacheProvider
    extends
        $FunctionalProvider<
          DrivingPatternCache,
          DrivingPatternCache,
          DrivingPatternCache
        >
    with $Provider<DrivingPatternCache> {
  /// Process-wide memo of per-trip totals (#4366). Bounded and
  /// fingerprinted — see [DrivingPatternCache] for what invalidates one.
  DrivingPatternCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'drivingPatternCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$drivingPatternCacheHash();

  @$internal
  @override
  $ProviderElement<DrivingPatternCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DrivingPatternCache create(Ref ref) {
    return drivingPatternCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DrivingPatternCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DrivingPatternCache>(value),
    );
  }
}

String _$drivingPatternCacheHash() =>
    r'538895154134f378ff2630ac0bba6345ece8df20';

/// The comparison for [request].
///
/// Re-runs whenever the trip list changes — a save, an edit, a deletion
/// or a vehicle reassignment all refresh `tripHistoryListProvider` — and
/// the per-trip cache independently misses any trip whose fingerprint or
/// model version moved.

@ProviderFor(drivingPatternComparison)
final drivingPatternComparisonProvider = DrivingPatternComparisonFamily._();

/// The comparison for [request].
///
/// Re-runs whenever the trip list changes — a save, an edit, a deletion
/// or a vehicle reassignment all refresh `tripHistoryListProvider` — and
/// the per-trip cache independently misses any trip whose fingerprint or
/// model version moved.

final class DrivingPatternComparisonProvider
    extends
        $FunctionalProvider<
          AsyncValue<DrivingPatternComparison>,
          DrivingPatternComparison,
          FutureOr<DrivingPatternComparison>
        >
    with
        $FutureModifier<DrivingPatternComparison>,
        $FutureProvider<DrivingPatternComparison> {
  /// The comparison for [request].
  ///
  /// Re-runs whenever the trip list changes — a save, an edit, a deletion
  /// or a vehicle reassignment all refresh `tripHistoryListProvider` — and
  /// the per-trip cache independently misses any trip whose fingerprint or
  /// model version moved.
  DrivingPatternComparisonProvider._({
    required DrivingPatternComparisonFamily super.from,
    required DrivingPatternComparisonRequest super.argument,
  }) : super(
         retry: null,
         name: r'drivingPatternComparisonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$drivingPatternComparisonHash();

  @override
  String toString() {
    return r'drivingPatternComparisonProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DrivingPatternComparison> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DrivingPatternComparison> create(Ref ref) {
    final argument = this.argument as DrivingPatternComparisonRequest;
    return drivingPatternComparison(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DrivingPatternComparisonProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$drivingPatternComparisonHash() =>
    r'1c34c613984f3269611ab4c3cd7e86c8fbc147b9';

/// The comparison for [request].
///
/// Re-runs whenever the trip list changes — a save, an edit, a deletion
/// or a vehicle reassignment all refresh `tripHistoryListProvider` — and
/// the per-trip cache independently misses any trip whose fingerprint or
/// model version moved.

final class DrivingPatternComparisonFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DrivingPatternComparison>,
          DrivingPatternComparisonRequest
        > {
  DrivingPatternComparisonFamily._()
    : super(
        retry: null,
        name: r'drivingPatternComparisonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The comparison for [request].
  ///
  /// Re-runs whenever the trip list changes — a save, an edit, a deletion
  /// or a vehicle reassignment all refresh `tripHistoryListProvider` — and
  /// the per-trip cache independently misses any trip whose fingerprint or
  /// model version moved.

  DrivingPatternComparisonProvider call(
    DrivingPatternComparisonRequest request,
  ) => DrivingPatternComparisonProvider._(argument: request, from: this);

  @override
  String toString() => r'drivingPatternComparisonProvider';
}
