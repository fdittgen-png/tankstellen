// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_search_results_enabled.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// As of #1373 phase 3f this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.unifiedSearchResults]. The legacy
/// `StorageKeys.unifiedSearchResultsEnabled` Hive-settings key is read
/// once by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// Defaults to `false` per the manifest because the unified UI is still
/// converging — flipping the flag without all phase 3b/c surfaces
/// installed produces an empty result list, which is the safer
/// fallback than a partial rendering.

@ProviderFor(UnifiedSearchResultsEnabled)
final unifiedSearchResultsEnabledProvider =
    UnifiedSearchResultsEnabledProvider._();

/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// As of #1373 phase 3f this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.unifiedSearchResults]. The legacy
/// `StorageKeys.unifiedSearchResultsEnabled` Hive-settings key is read
/// once by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// Defaults to `false` per the manifest because the unified UI is still
/// converging — flipping the flag without all phase 3b/c surfaces
/// installed produces an empty result list, which is the safer
/// fallback than a partial rendering.
final class UnifiedSearchResultsEnabledProvider
    extends $NotifierProvider<UnifiedSearchResultsEnabled, bool> {
  /// Feature flag for the #1116 phase-3 unified fuel + EV search results.
  ///
  /// As of #1373 phase 3f this is a thin shim over [featureFlagsProvider]
  /// — the canonical state lives in the central feature-flag set keyed by
  /// [Feature.unifiedSearchResults]. The legacy
  /// `StorageKeys.unifiedSearchResultsEnabled` Hive-settings key is read
  /// once by the `legacyToggleMigrationProvider` on first launch after
  /// upgrade and promoted into the central set; subsequent reads/writes
  /// go through here.
  ///
  /// Defaults to `false` per the manifest because the unified UI is still
  /// converging — flipping the flag without all phase 3b/c surfaces
  /// installed produces an empty result list, which is the safer
  /// fallback than a partial rendering.
  UnifiedSearchResultsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unifiedSearchResultsEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unifiedSearchResultsEnabledHash();

  @$internal
  @override
  UnifiedSearchResultsEnabled create() => UnifiedSearchResultsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$unifiedSearchResultsEnabledHash() =>
    r'bd0c4c48b32ee20ae7ecce4037b844d23f513f48';

/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// As of #1373 phase 3f this is a thin shim over [featureFlagsProvider]
/// — the canonical state lives in the central feature-flag set keyed by
/// [Feature.unifiedSearchResults]. The legacy
/// `StorageKeys.unifiedSearchResultsEnabled` Hive-settings key is read
/// once by the `legacyToggleMigrationProvider` on first launch after
/// upgrade and promoted into the central set; subsequent reads/writes
/// go through here.
///
/// Defaults to `false` per the manifest because the unified UI is still
/// converging — flipping the flag without all phase 3b/c surfaces
/// installed produces an empty result list, which is the safer
/// fallback than a partial rendering.

abstract class _$UnifiedSearchResultsEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
