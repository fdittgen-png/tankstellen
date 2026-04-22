// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ignored_stations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the user's list of ignored (hidden) station IDs.
///
/// Ignored stations are filtered out of search results, map markers,
/// and route results. This lets users hide irrelevant or closed stations.
///
/// ## Local-first pattern:
/// - Saves to Hive immediately, then syncs to Supabase.
/// - On conflict: local list wins (union merge on sync).

@ProviderFor(IgnoredStations)
final ignoredStationsProvider = IgnoredStationsProvider._();

/// Manages the user's list of ignored (hidden) station IDs.
///
/// Ignored stations are filtered out of search results, map markers,
/// and route results. This lets users hide irrelevant or closed stations.
///
/// ## Local-first pattern:
/// - Saves to Hive immediately, then syncs to Supabase.
/// - On conflict: local list wins (union merge on sync).
final class IgnoredStationsProvider
    extends $NotifierProvider<IgnoredStations, List<String>> {
  /// Manages the user's list of ignored (hidden) station IDs.
  ///
  /// Ignored stations are filtered out of search results, map markers,
  /// and route results. This lets users hide irrelevant or closed stations.
  ///
  /// ## Local-first pattern:
  /// - Saves to Hive immediately, then syncs to Supabase.
  /// - On conflict: local list wins (union merge on sync).
  IgnoredStationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ignoredStationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ignoredStationsHash();

  @$internal
  @override
  IgnoredStations create() => IgnoredStations();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$ignoredStationsHash() => r'7f656b4ccdb9b582c0306f0441bf2a97acb67676';

/// Manages the user's list of ignored (hidden) station IDs.
///
/// Ignored stations are filtered out of search results, map markers,
/// and route results. This lets users hide irrelevant or closed stations.
///
/// ## Local-first pattern:
/// - Saves to Hive immediately, then syncs to Supabase.
/// - On conflict: local list wins (union merge on sync).

abstract class _$IgnoredStations extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether a specific station is ignored. Rebuilds when ignored list changes.

@ProviderFor(isIgnored)
final isIgnoredProvider = IsIgnoredFamily._();

/// Whether a specific station is ignored. Rebuilds when ignored list changes.

final class IsIgnoredProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a specific station is ignored. Rebuilds when ignored list changes.
  IsIgnoredProvider._({
    required IsIgnoredFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isIgnoredProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isIgnoredHash();

  @override
  String toString() {
    return r'isIgnoredProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isIgnored(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsIgnoredProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isIgnoredHash() => r'6a1ee97134aebc315d0b546ad18d7d3c5b212fcd';

/// Whether a specific station is ignored. Rebuilds when ignored list changes.

final class IsIgnoredFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsIgnoredFamily._()
    : super(
        retry: null,
        name: r'isIgnoredProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a specific station is ignored. Rebuilds when ignored list changes.

  IsIgnoredProvider call(String stationId) =>
      IsIgnoredProvider._(argument: stationId, from: this);

  @override
  String toString() => r'isIgnoredProvider';
}
