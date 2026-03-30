// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station_rating_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages station ratings (1-5 stars) with three privacy levels:
///
/// - **local**: Saved only on this device (no sync)
/// - **private**: Synced with user's Supabase database (only visible to user)
/// - **shared**: Synced and visible to all users of the database
///
/// The rating mode is configured in the user profile (`ratingMode` field).
/// When mode changes, existing ratings are not retroactively synced/unsynced.

@ProviderFor(StationRatings)
final stationRatingsProvider = StationRatingsProvider._();

/// Manages station ratings (1-5 stars) with three privacy levels:
///
/// - **local**: Saved only on this device (no sync)
/// - **private**: Synced with user's Supabase database (only visible to user)
/// - **shared**: Synced and visible to all users of the database
///
/// The rating mode is configured in the user profile (`ratingMode` field).
/// When mode changes, existing ratings are not retroactively synced/unsynced.
final class StationRatingsProvider
    extends $NotifierProvider<StationRatings, Map<String, int>> {
  /// Manages station ratings (1-5 stars) with three privacy levels:
  ///
  /// - **local**: Saved only on this device (no sync)
  /// - **private**: Synced with user's Supabase database (only visible to user)
  /// - **shared**: Synced and visible to all users of the database
  ///
  /// The rating mode is configured in the user profile (`ratingMode` field).
  /// When mode changes, existing ratings are not retroactively synced/unsynced.
  StationRatingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stationRatingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stationRatingsHash();

  @$internal
  @override
  StationRatings create() => StationRatings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$stationRatingsHash() => r'a145ca612a9fc812f74b622810c38ed63c1a3c04';

/// Manages station ratings (1-5 stars) with three privacy levels:
///
/// - **local**: Saved only on this device (no sync)
/// - **private**: Synced with user's Supabase database (only visible to user)
/// - **shared**: Synced and visible to all users of the database
///
/// The rating mode is configured in the user profile (`ratingMode` field).
/// When mode changes, existing ratings are not retroactively synced/unsynced.

abstract class _$StationRatings extends $Notifier<Map<String, int>> {
  Map<String, int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, int>, Map<String, int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, int>, Map<String, int>>,
              Map<String, int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Get the rating for a specific station (null if not rated).

@ProviderFor(stationRating)
final stationRatingProvider = StationRatingFamily._();

/// Get the rating for a specific station (null if not rated).

final class StationRatingProvider extends $FunctionalProvider<int?, int?, int?>
    with $Provider<int?> {
  /// Get the rating for a specific station (null if not rated).
  StationRatingProvider._({
    required StationRatingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stationRatingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stationRatingHash();

  @override
  String toString() {
    return r'stationRatingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int? create(Ref ref) {
    final argument = this.argument as String;
    return stationRating(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StationRatingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stationRatingHash() => r'49fc720f62fbc68d79ba5887ef0fa31c788fe54f';

/// Get the rating for a specific station (null if not rated).

final class StationRatingFamily extends $Family
    with $FunctionalFamilyOverride<int?, String> {
  StationRatingFamily._()
    : super(
        retry: null,
        name: r'stationRatingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get the rating for a specific station (null if not rated).

  StationRatingProvider call(String stationId) =>
      StationRatingProvider._(argument: stationId, from: this);

  @override
  String toString() => r'stationRatingProvider';
}
