// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the [TripHistoryRepository] (#726).
///
/// Returns null when the underlying Hive box isn't open — widget
/// tests that don't bother initialising Hive get a silent no-op
/// instead of a thrown error from the UI.

@ProviderFor(tripHistoryRepository)
final tripHistoryRepositoryProvider = TripHistoryRepositoryProvider._();

/// App-wide access to the [TripHistoryRepository] (#726).
///
/// Returns null when the underlying Hive box isn't open — widget
/// tests that don't bother initialising Hive get a silent no-op
/// instead of a thrown error from the UI.

final class TripHistoryRepositoryProvider
    extends
        $FunctionalProvider<
          TripHistoryRepository?,
          TripHistoryRepository?,
          TripHistoryRepository?
        >
    with $Provider<TripHistoryRepository?> {
  /// App-wide access to the [TripHistoryRepository] (#726).
  ///
  /// Returns null when the underlying Hive box isn't open — widget
  /// tests that don't bother initialising Hive get a silent no-op
  /// instead of a thrown error from the UI.
  TripHistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripHistoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripHistoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripHistoryRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripHistoryRepository? create(Ref ref) {
    return tripHistoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripHistoryRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripHistoryRepository?>(value),
    );
  }
}

String _$tripHistoryRepositoryHash() =>
    r'87df5375c9c11858b773597b545b021b73b3d5dd';

/// List of finalised trips, newest-first. Empty when the box is
/// closed or carries no entries. Refreshed by callers after they
/// save a new trip via [TripHistoryListNotifier.refresh].
///
/// #3741 — SUMMARIES-ONLY: entries come from
/// [TripHistoryRepository.loadSummaries], so the heavy per-tick
/// payloads are never materialised on the UI isolate (the flagship
/// list decoded every trip's full 1 Hz sample array on first watch and
/// after every save/delete/verdict/sync — the consumption-tab jank).
/// `entry.samples` is always empty here and `entry.sampleCount` carries
/// the stored count; consumers that render or recompute samples fetch
/// the single trips they need through [tripHistoryDetailProvider].

@ProviderFor(TripHistoryList)
final tripHistoryListProvider = TripHistoryListProvider._();

/// List of finalised trips, newest-first. Empty when the box is
/// closed or carries no entries. Refreshed by callers after they
/// save a new trip via [TripHistoryListNotifier.refresh].
///
/// #3741 — SUMMARIES-ONLY: entries come from
/// [TripHistoryRepository.loadSummaries], so the heavy per-tick
/// payloads are never materialised on the UI isolate (the flagship
/// list decoded every trip's full 1 Hz sample array on first watch and
/// after every save/delete/verdict/sync — the consumption-tab jank).
/// `entry.samples` is always empty here and `entry.sampleCount` carries
/// the stored count; consumers that render or recompute samples fetch
/// the single trips they need through [tripHistoryDetailProvider].
final class TripHistoryListProvider
    extends $NotifierProvider<TripHistoryList, List<TripHistoryEntry>> {
  /// List of finalised trips, newest-first. Empty when the box is
  /// closed or carries no entries. Refreshed by callers after they
  /// save a new trip via [TripHistoryListNotifier.refresh].
  ///
  /// #3741 — SUMMARIES-ONLY: entries come from
  /// [TripHistoryRepository.loadSummaries], so the heavy per-tick
  /// payloads are never materialised on the UI isolate (the flagship
  /// list decoded every trip's full 1 Hz sample array on first watch and
  /// after every save/delete/verdict/sync — the consumption-tab jank).
  /// `entry.samples` is always empty here and `entry.sampleCount` carries
  /// the stored count; consumers that render or recompute samples fetch
  /// the single trips they need through [tripHistoryDetailProvider].
  TripHistoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripHistoryListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripHistoryListHash();

  @$internal
  @override
  TripHistoryList create() => TripHistoryList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TripHistoryEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TripHistoryEntry>>(value),
    );
  }
}

String _$tripHistoryListHash() => r'195cac71f74c0039b204c61ef200c01d98bd6c74';

/// List of finalised trips, newest-first. Empty when the box is
/// closed or carries no entries. Refreshed by callers after they
/// save a new trip via [TripHistoryListNotifier.refresh].
///
/// #3741 — SUMMARIES-ONLY: entries come from
/// [TripHistoryRepository.loadSummaries], so the heavy per-tick
/// payloads are never materialised on the UI isolate (the flagship
/// list decoded every trip's full 1 Hz sample array on first watch and
/// after every save/delete/verdict/sync — the consumption-tab jank).
/// `entry.samples` is always empty here and `entry.sampleCount` carries
/// the stored count; consumers that render or recompute samples fetch
/// the single trips they need through [tripHistoryDetailProvider].

abstract class _$TripHistoryList extends $Notifier<List<TripHistoryEntry>> {
  List<TripHistoryEntry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<TripHistoryEntry>, List<TripHistoryEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<TripHistoryEntry>, List<TripHistoryEntry>>,
              List<TripHistoryEntry>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Full decode of ONE persisted trip — samples materialised (#3741).
///
/// [tripHistoryListProvider] is summaries-only; consumers that render or
/// recompute per-tick samples (the trip-detail charts, the trajets map
/// polylines, the speed-consumption histogram, the achievements sample
/// metrics) fetch exactly the trips they need through this family
/// instead of paying a full-history decode.
///
/// Watching the list makes every save/delete/verdict/sync refresh
/// re-read the row (the notifier pushes a new list instance on each).
/// Falls back to the list's own entry when the repository is
/// unavailable (closed box in widget tests, where the list provider is
/// overridden with fully-populated fixtures) or when the row vanished
/// between refreshes.

@ProviderFor(tripHistoryDetail)
final tripHistoryDetailProvider = TripHistoryDetailFamily._();

/// Full decode of ONE persisted trip — samples materialised (#3741).
///
/// [tripHistoryListProvider] is summaries-only; consumers that render or
/// recompute per-tick samples (the trip-detail charts, the trajets map
/// polylines, the speed-consumption histogram, the achievements sample
/// metrics) fetch exactly the trips they need through this family
/// instead of paying a full-history decode.
///
/// Watching the list makes every save/delete/verdict/sync refresh
/// re-read the row (the notifier pushes a new list instance on each).
/// Falls back to the list's own entry when the repository is
/// unavailable (closed box in widget tests, where the list provider is
/// overridden with fully-populated fixtures) or when the row vanished
/// between refreshes.

final class TripHistoryDetailProvider
    extends
        $FunctionalProvider<
          TripHistoryEntry?,
          TripHistoryEntry?,
          TripHistoryEntry?
        >
    with $Provider<TripHistoryEntry?> {
  /// Full decode of ONE persisted trip — samples materialised (#3741).
  ///
  /// [tripHistoryListProvider] is summaries-only; consumers that render or
  /// recompute per-tick samples (the trip-detail charts, the trajets map
  /// polylines, the speed-consumption histogram, the achievements sample
  /// metrics) fetch exactly the trips they need through this family
  /// instead of paying a full-history decode.
  ///
  /// Watching the list makes every save/delete/verdict/sync refresh
  /// re-read the row (the notifier pushes a new list instance on each).
  /// Falls back to the list's own entry when the repository is
  /// unavailable (closed box in widget tests, where the list provider is
  /// overridden with fully-populated fixtures) or when the row vanished
  /// between refreshes.
  TripHistoryDetailProvider._({
    required TripHistoryDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripHistoryDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripHistoryDetailHash();

  @override
  String toString() {
    return r'tripHistoryDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TripHistoryEntry?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TripHistoryEntry? create(Ref ref) {
    final argument = this.argument as String;
    return tripHistoryDetail(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripHistoryEntry? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripHistoryEntry?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripHistoryDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripHistoryDetailHash() => r'c37ca46504282dfdd040bf78870e14e6eb2683af';

/// Full decode of ONE persisted trip — samples materialised (#3741).
///
/// [tripHistoryListProvider] is summaries-only; consumers that render or
/// recompute per-tick samples (the trip-detail charts, the trajets map
/// polylines, the speed-consumption histogram, the achievements sample
/// metrics) fetch exactly the trips they need through this family
/// instead of paying a full-history decode.
///
/// Watching the list makes every save/delete/verdict/sync refresh
/// re-read the row (the notifier pushes a new list instance on each).
/// Falls back to the list's own entry when the repository is
/// unavailable (closed box in widget tests, where the list provider is
/// overridden with fully-populated fixtures) or when the row vanished
/// between refreshes.

final class TripHistoryDetailFamily extends $Family
    with $FunctionalFamilyOverride<TripHistoryEntry?, String> {
  TripHistoryDetailFamily._()
    : super(
        retry: null,
        name: r'tripHistoryDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Full decode of ONE persisted trip — samples materialised (#3741).
  ///
  /// [tripHistoryListProvider] is summaries-only; consumers that render or
  /// recompute per-tick samples (the trip-detail charts, the trajets map
  /// polylines, the speed-consumption histogram, the achievements sample
  /// metrics) fetch exactly the trips they need through this family
  /// instead of paying a full-history decode.
  ///
  /// Watching the list makes every save/delete/verdict/sync refresh
  /// re-read the row (the notifier pushes a new list instance on each).
  /// Falls back to the list's own entry when the repository is
  /// unavailable (closed box in widget tests, where the list provider is
  /// overridden with fully-populated fixtures) or when the row vanished
  /// between refreshes.

  TripHistoryDetailProvider call(String id) =>
      TripHistoryDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'tripHistoryDetailProvider';
}
