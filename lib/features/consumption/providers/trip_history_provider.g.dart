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

@ProviderFor(TripHistoryList)
final tripHistoryListProvider = TripHistoryListProvider._();

/// List of finalised trips, newest-first. Empty when the box is
/// closed or carries no entries. Refreshed by callers after they
/// save a new trip via [TripHistoryListNotifier.refresh].
final class TripHistoryListProvider
    extends $NotifierProvider<TripHistoryList, List<TripHistoryEntry>> {
  /// List of finalised trips, newest-first. Empty when the box is
  /// closed or carries no entries. Refreshed by callers after they
  /// save a new trip via [TripHistoryListNotifier.refresh].
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

String _$tripHistoryListHash() => r'57f61d4a6a0a63b355cd76de4974ce9b59dfd48f';

/// List of finalised trips, newest-first. Empty when the box is
/// closed or carries no entries. Refreshed by callers after they
/// save a new trip via [TripHistoryListNotifier.refresh].

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
