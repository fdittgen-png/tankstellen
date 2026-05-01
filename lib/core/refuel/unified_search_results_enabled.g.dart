// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_search_results_enabled.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// Phase 3a (this PR) introduces only the flag and the
/// [unifiedSearchResultsProvider] foundation; the search screen still
/// reads `searchStateProvider` directly. Phase 3b ships the mixed
/// fuel/EV card widgets, and phase 3c rewires the search screen to
/// consume [unifiedSearchResultsProvider] when this flag is on.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` because the unified UI is not yet
/// shipping — flipping the flag without phase 3b/c installed produces
/// an empty result list, which is the safer fallback than a partial
/// rendering.
///
/// Mirrors the [EvShowOnMap] pattern from `lib/features/ev/providers/
/// ev_providers.dart`: keep-alive, Hive-backed, with [toggle] and [set]
/// mutators.

@ProviderFor(UnifiedSearchResultsEnabled)
final unifiedSearchResultsEnabledProvider =
    UnifiedSearchResultsEnabledProvider._();

/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// Phase 3a (this PR) introduces only the flag and the
/// [unifiedSearchResultsProvider] foundation; the search screen still
/// reads `searchStateProvider` directly. Phase 3b ships the mixed
/// fuel/EV card widgets, and phase 3c rewires the search screen to
/// consume [unifiedSearchResultsProvider] when this flag is on.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` because the unified UI is not yet
/// shipping — flipping the flag without phase 3b/c installed produces
/// an empty result list, which is the safer fallback than a partial
/// rendering.
///
/// Mirrors the [EvShowOnMap] pattern from `lib/features/ev/providers/
/// ev_providers.dart`: keep-alive, Hive-backed, with [toggle] and [set]
/// mutators.
final class UnifiedSearchResultsEnabledProvider
    extends $NotifierProvider<UnifiedSearchResultsEnabled, bool> {
  /// Feature flag for the #1116 phase-3 unified fuel + EV search results.
  ///
  /// Phase 3a (this PR) introduces only the flag and the
  /// [unifiedSearchResultsProvider] foundation; the search screen still
  /// reads `searchStateProvider` directly. Phase 3b ships the mixed
  /// fuel/EV card widgets, and phase 3c rewires the search screen to
  /// consume [unifiedSearchResultsProvider] when this flag is on.
  ///
  /// Persisted to the settings box so the user's preference survives
  /// restarts. Defaults to `false` because the unified UI is not yet
  /// shipping — flipping the flag without phase 3b/c installed produces
  /// an empty result list, which is the safer fallback than a partial
  /// rendering.
  ///
  /// Mirrors the [EvShowOnMap] pattern from `lib/features/ev/providers/
  /// ev_providers.dart`: keep-alive, Hive-backed, with [toggle] and [set]
  /// mutators.
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
    r'f3861b3c635983e95666508988811f0937a77b15';

/// Feature flag for the #1116 phase-3 unified fuel + EV search results.
///
/// Phase 3a (this PR) introduces only the flag and the
/// [unifiedSearchResultsProvider] foundation; the search screen still
/// reads `searchStateProvider` directly. Phase 3b ships the mixed
/// fuel/EV card widgets, and phase 3c rewires the search screen to
/// consume [unifiedSearchResultsProvider] when this flag is on.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` because the unified UI is not yet
/// shipping — flipping the flag without phase 3b/c installed produces
/// an empty result list, which is the safer fallback than a partial
/// rendering.
///
/// Mirrors the [EvShowOnMap] pattern from `lib/features/ev/providers/
/// ev_providers.dart`: keep-alive, Hive-backed, with [toggle] and [set]
/// mutators.

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
