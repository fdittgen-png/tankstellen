// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

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
    r'd3d80dd4010d0e9e337b2664342440ac7ebe137f';

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

String _$tripHistoryDetailHash() => r'ef875ce19c7fd15795829547b7168641a3eef2e7';

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

/// The list's own (summary-only) entry for [id], rebuilt only when THIS
/// trip's identity changes — the sample count moves on hydration, the
/// verdict on the post-trip prompt — not on every list refresh (#3882).

@ProviderFor(_listedTrip)
final _listedTripProvider = _ListedTripFamily._();

/// The list's own (summary-only) entry for [id], rebuilt only when THIS
/// trip's identity changes — the sample count moves on hydration, the
/// verdict on the post-trip prompt — not on every list refresh (#3882).

final class _ListedTripProvider
    extends
        $FunctionalProvider<
          TripHistoryEntry?,
          TripHistoryEntry?,
          TripHistoryEntry?
        >
    with $Provider<TripHistoryEntry?> {
  /// The list's own (summary-only) entry for [id], rebuilt only when THIS
  /// trip's identity changes — the sample count moves on hydration, the
  /// verdict on the post-trip prompt — not on every list refresh (#3882).
  _ListedTripProvider._({
    required _ListedTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'_listedTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_listedTripHash();

  @override
  String toString() {
    return r'_listedTripProvider'
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
    return _listedTrip(ref, argument);
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
    return other is _ListedTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_listedTripHash() => r'6feba079ec08d13c7f0c59ff6141189d9d5b02ca';

/// The list's own (summary-only) entry for [id], rebuilt only when THIS
/// trip's identity changes — the sample count moves on hydration, the
/// verdict on the post-trip prompt — not on every list refresh (#3882).

final class _ListedTripFamily extends $Family
    with $FunctionalFamilyOverride<TripHistoryEntry?, String> {
  _ListedTripFamily._()
    : super(
        retry: null,
        name: r'_listedTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The list's own (summary-only) entry for [id], rebuilt only when THIS
  /// trip's identity changes — the sample count moves on hydration, the
  /// verdict on the post-trip prompt — not on every list refresh (#3882).

  _ListedTripProvider call(String id) =>
      _ListedTripProvider._(argument: id, from: this);

  @override
  String toString() => r'_listedTripProvider';
}

/// The identity of the listed trip's CONTENT — a record, so dependents
/// rebuild on a value change only (Riverpod filters on `==`), not on
/// every list refresh that hands out a fresh instance (#3882).

@ProviderFor(_listedTripKey)
final _listedTripKeyProvider = _ListedTripKeyFamily._();

/// The identity of the listed trip's CONTENT — a record, so dependents
/// rebuild on a value change only (Riverpod filters on `==`), not on
/// every list refresh that hands out a fresh instance (#3882).

final class _ListedTripKeyProvider
    extends
        $FunctionalProvider<
          (int?, String?, int?),
          (int?, String?, int?),
          (int?, String?, int?)
        >
    with $Provider<(int?, String?, int?)> {
  /// The identity of the listed trip's CONTENT — a record, so dependents
  /// rebuild on a value change only (Riverpod filters on `==`), not on
  /// every list refresh that hands out a fresh instance (#3882).
  _ListedTripKeyProvider._({
    required _ListedTripKeyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'_listedTripKeyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_listedTripKeyHash();

  @override
  String toString() {
    return r'_listedTripKeyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<(int?, String?, int?)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  (int?, String?, int?) create(Ref ref) {
    final argument = this.argument as String;
    return _listedTripKey(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue((int?, String?, int?) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<(int?, String?, int?)>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _ListedTripKeyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_listedTripKeyHash() => r'9339608f0c9148be5f5531e15c9c07fd2db16c5a';

/// The identity of the listed trip's CONTENT — a record, so dependents
/// rebuild on a value change only (Riverpod filters on `==`), not on
/// every list refresh that hands out a fresh instance (#3882).

final class _ListedTripKeyFamily extends $Family
    with $FunctionalFamilyOverride<(int?, String?, int?), String> {
  _ListedTripKeyFamily._()
    : super(
        retry: null,
        name: r'_listedTripKeyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The identity of the listed trip's CONTENT — a record, so dependents
  /// rebuild on a value change only (Riverpod filters on `==`), not on
  /// every list refresh that hands out a fresh instance (#3882).

  _ListedTripKeyProvider call(String id) =>
      _ListedTripKeyProvider._(argument: id, from: this);

  @override
  String toString() => r'_listedTripKeyProvider';
}

/// #3882 — the trip-detail screen's loader: the FULL entry decoded on a
/// background isolate ([TripHistoryRepository.loadByIdAsync]), exposed as
/// an [AsyncValue] so the screen paints a skeleton instead of blocking
/// the UI isolate on a 40-minute trip's 34-column decode.
///
/// Re-decodes only when the trip's own `(sampleCount, verdict)` moves
/// (hydration, verdict) — a list refresh for an unrelated save/delete no
/// longer re-reads the row. With no repository (closed box in widget
/// tests) the list's fixture entry is served synchronously, so
/// fixture-driven screens render on the first pump exactly as before.

@ProviderFor(TripDetailLoader)
final tripDetailLoaderProvider = TripDetailLoaderFamily._();

/// #3882 — the trip-detail screen's loader: the FULL entry decoded on a
/// background isolate ([TripHistoryRepository.loadByIdAsync]), exposed as
/// an [AsyncValue] so the screen paints a skeleton instead of blocking
/// the UI isolate on a 40-minute trip's 34-column decode.
///
/// Re-decodes only when the trip's own `(sampleCount, verdict)` moves
/// (hydration, verdict) — a list refresh for an unrelated save/delete no
/// longer re-reads the row. With no repository (closed box in widget
/// tests) the list's fixture entry is served synchronously, so
/// fixture-driven screens render on the first pump exactly as before.
final class TripDetailLoaderProvider
    extends $NotifierProvider<TripDetailLoader, AsyncValue<TripHistoryEntry?>> {
  /// #3882 — the trip-detail screen's loader: the FULL entry decoded on a
  /// background isolate ([TripHistoryRepository.loadByIdAsync]), exposed as
  /// an [AsyncValue] so the screen paints a skeleton instead of blocking
  /// the UI isolate on a 40-minute trip's 34-column decode.
  ///
  /// Re-decodes only when the trip's own `(sampleCount, verdict)` moves
  /// (hydration, verdict) — a list refresh for an unrelated save/delete no
  /// longer re-reads the row. With no repository (closed box in widget
  /// tests) the list's fixture entry is served synchronously, so
  /// fixture-driven screens render on the first pump exactly as before.
  TripDetailLoaderProvider._({
    required TripDetailLoaderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripDetailLoaderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripDetailLoaderHash();

  @override
  String toString() {
    return r'tripDetailLoaderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TripDetailLoader create() => TripDetailLoader();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<TripHistoryEntry?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<TripHistoryEntry?>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripDetailLoaderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripDetailLoaderHash() => r'3807d0e64fa861c5753fb301e612f08e6c1c28d4';

/// #3882 — the trip-detail screen's loader: the FULL entry decoded on a
/// background isolate ([TripHistoryRepository.loadByIdAsync]), exposed as
/// an [AsyncValue] so the screen paints a skeleton instead of blocking
/// the UI isolate on a 40-minute trip's 34-column decode.
///
/// Re-decodes only when the trip's own `(sampleCount, verdict)` moves
/// (hydration, verdict) — a list refresh for an unrelated save/delete no
/// longer re-reads the row. With no repository (closed box in widget
/// tests) the list's fixture entry is served synchronously, so
/// fixture-driven screens render on the first pump exactly as before.

final class TripDetailLoaderFamily extends $Family
    with
        $ClassFamilyOverride<
          TripDetailLoader,
          AsyncValue<TripHistoryEntry?>,
          AsyncValue<TripHistoryEntry?>,
          AsyncValue<TripHistoryEntry?>,
          String
        > {
  TripDetailLoaderFamily._()
    : super(
        retry: null,
        name: r'tripDetailLoaderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// #3882 — the trip-detail screen's loader: the FULL entry decoded on a
  /// background isolate ([TripHistoryRepository.loadByIdAsync]), exposed as
  /// an [AsyncValue] so the screen paints a skeleton instead of blocking
  /// the UI isolate on a 40-minute trip's 34-column decode.
  ///
  /// Re-decodes only when the trip's own `(sampleCount, verdict)` moves
  /// (hydration, verdict) — a list refresh for an unrelated save/delete no
  /// longer re-reads the row. With no repository (closed box in widget
  /// tests) the list's fixture entry is served synchronously, so
  /// fixture-driven screens render on the first pump exactly as before.

  TripDetailLoaderProvider call(String id) =>
      TripDetailLoaderProvider._(argument: id, from: this);

  @override
  String toString() => r'tripDetailLoaderProvider';
}

/// #3882 — the trip-detail screen's loader: the FULL entry decoded on a
/// background isolate ([TripHistoryRepository.loadByIdAsync]), exposed as
/// an [AsyncValue] so the screen paints a skeleton instead of blocking
/// the UI isolate on a 40-minute trip's 34-column decode.
///
/// Re-decodes only when the trip's own `(sampleCount, verdict)` moves
/// (hydration, verdict) — a list refresh for an unrelated save/delete no
/// longer re-reads the row. With no repository (closed box in widget
/// tests) the list's fixture entry is served synchronously, so
/// fixture-driven screens render on the first pump exactly as before.

abstract class _$TripDetailLoader
    extends $Notifier<AsyncValue<TripHistoryEntry?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<TripHistoryEntry?> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<TripHistoryEntry?>,
              AsyncValue<TripHistoryEntry?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TripHistoryEntry?>,
                AsyncValue<TripHistoryEntry?>
              >,
              AsyncValue<TripHistoryEntry?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// #3882 — only the speed + fuel-rate columns of one trip, as light
/// samples, for the speed-consumption histogram (the carbon charts tab):
/// a 2-column read instead of the 34-column full decode. Refreshes with
/// the list like [tripHistoryDetailProvider].

@ProviderFor(tripSpeedFuelSamples)
final tripSpeedFuelSamplesProvider = TripSpeedFuelSamplesFamily._();

/// #3882 — only the speed + fuel-rate columns of one trip, as light
/// samples, for the speed-consumption histogram (the carbon charts tab):
/// a 2-column read instead of the 34-column full decode. Refreshes with
/// the list like [tripHistoryDetailProvider].

final class TripSpeedFuelSamplesProvider
    extends
        $FunctionalProvider<
          List<TripSample>,
          List<TripSample>,
          List<TripSample>
        >
    with $Provider<List<TripSample>> {
  /// #3882 — only the speed + fuel-rate columns of one trip, as light
  /// samples, for the speed-consumption histogram (the carbon charts tab):
  /// a 2-column read instead of the 34-column full decode. Refreshes with
  /// the list like [tripHistoryDetailProvider].
  TripSpeedFuelSamplesProvider._({
    required TripSpeedFuelSamplesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripSpeedFuelSamplesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripSpeedFuelSamplesHash();

  @override
  String toString() {
    return r'tripSpeedFuelSamplesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<TripSample>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<TripSample> create(Ref ref) {
    final argument = this.argument as String;
    return tripSpeedFuelSamples(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TripSample> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TripSample>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripSpeedFuelSamplesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripSpeedFuelSamplesHash() =>
    r'983ca9e1414b80d1feea17e396066d4e273fbe8e';

/// #3882 — only the speed + fuel-rate columns of one trip, as light
/// samples, for the speed-consumption histogram (the carbon charts tab):
/// a 2-column read instead of the 34-column full decode. Refreshes with
/// the list like [tripHistoryDetailProvider].

final class TripSpeedFuelSamplesFamily extends $Family
    with $FunctionalFamilyOverride<List<TripSample>, String> {
  TripSpeedFuelSamplesFamily._()
    : super(
        retry: null,
        name: r'tripSpeedFuelSamplesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// #3882 — only the speed + fuel-rate columns of one trip, as light
  /// samples, for the speed-consumption histogram (the carbon charts tab):
  /// a 2-column read instead of the 34-column full decode. Refreshes with
  /// the list like [tripHistoryDetailProvider].

  TripSpeedFuelSamplesProvider call(String id) =>
      TripSpeedFuelSamplesProvider._(argument: id, from: this);

  @override
  String toString() => r'tripSpeedFuelSamplesProvider';
}
