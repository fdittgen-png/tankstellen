// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_search_results_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Combines fuel + EV search results into a single
/// [List<RefuelOption>] for the #1116 phase-3 unified search list.
///
/// Phase 3a (this file) lays the foundation. The search screen still
/// reads `searchStateProvider` directly today; phase 3b ships the
/// mixed-card widgets and phase 3c rewires the screen to consume this
/// provider behind the [unifiedSearchResultsEnabledProvider] flag.
///
/// Contract:
///
/// * When the flag is off, returns an empty list. Callers fall back to
///   the legacy fuel-only path. This keeps the no-op semantics until
///   phase 3b/c land.
/// * When the flag is on, walks both upstream sources independently:
///   - the fuel side via [searchStateProvider], mapping
///     [FuelStationResult]s through [StationAsRefuelOption] using the
///     currently selected fuel from [selectedFuelTypeProvider];
///   - the EV side via [eVSearchStateProvider], mapping every
///     [ChargingStation] through [ChargingStationAsRefuelOption].
///   The two lists are concatenated (fuel first, EV after) so the
///   downstream UI can apply its own sort/filter chips deterministically.
/// * Stations whose price for the active fuel is `null` are skipped on
///   the fuel side. The phase-2 [StationAsRefuelOption] returns a null
///   price for those stations, but the unified list is consumed by
///   price-driven UI (lowest-first sort, savings badges); a price-less
///   row would render as a placeholder for no useful reason. Callers
///   that need *every* station regardless of price should keep using
///   `searchStateProvider`.
/// * The provider NEVER throws. Loading and error states on either
///   upstream collapse to an empty contribution from that side; the
///   other side still surfaces. UI consumers treat an empty result
///   list as "no results yet" and rely on the upstream
///   [AsyncValue.isLoading] / `.hasError` flags for spinners + retry
///   affordances (phase 3b).
///
/// Note: this is a synchronous, non-keep-alive provider — Riverpod
/// re-derives it whenever any of the upstreams update, which is the
/// behaviour we want so the unified card list refreshes as the fuel +
/// EV searches land.

@ProviderFor(unifiedSearchResults)
final unifiedSearchResultsProvider = UnifiedSearchResultsProvider._();

/// Combines fuel + EV search results into a single
/// [List<RefuelOption>] for the #1116 phase-3 unified search list.
///
/// Phase 3a (this file) lays the foundation. The search screen still
/// reads `searchStateProvider` directly today; phase 3b ships the
/// mixed-card widgets and phase 3c rewires the screen to consume this
/// provider behind the [unifiedSearchResultsEnabledProvider] flag.
///
/// Contract:
///
/// * When the flag is off, returns an empty list. Callers fall back to
///   the legacy fuel-only path. This keeps the no-op semantics until
///   phase 3b/c land.
/// * When the flag is on, walks both upstream sources independently:
///   - the fuel side via [searchStateProvider], mapping
///     [FuelStationResult]s through [StationAsRefuelOption] using the
///     currently selected fuel from [selectedFuelTypeProvider];
///   - the EV side via [eVSearchStateProvider], mapping every
///     [ChargingStation] through [ChargingStationAsRefuelOption].
///   The two lists are concatenated (fuel first, EV after) so the
///   downstream UI can apply its own sort/filter chips deterministically.
/// * Stations whose price for the active fuel is `null` are skipped on
///   the fuel side. The phase-2 [StationAsRefuelOption] returns a null
///   price for those stations, but the unified list is consumed by
///   price-driven UI (lowest-first sort, savings badges); a price-less
///   row would render as a placeholder for no useful reason. Callers
///   that need *every* station regardless of price should keep using
///   `searchStateProvider`.
/// * The provider NEVER throws. Loading and error states on either
///   upstream collapse to an empty contribution from that side; the
///   other side still surfaces. UI consumers treat an empty result
///   list as "no results yet" and rely on the upstream
///   [AsyncValue.isLoading] / `.hasError` flags for spinners + retry
///   affordances (phase 3b).
///
/// Note: this is a synchronous, non-keep-alive provider — Riverpod
/// re-derives it whenever any of the upstreams update, which is the
/// behaviour we want so the unified card list refreshes as the fuel +
/// EV searches land.

final class UnifiedSearchResultsProvider
    extends
        $FunctionalProvider<
          List<RefuelOption>,
          List<RefuelOption>,
          List<RefuelOption>
        >
    with $Provider<List<RefuelOption>> {
  /// Combines fuel + EV search results into a single
  /// [List<RefuelOption>] for the #1116 phase-3 unified search list.
  ///
  /// Phase 3a (this file) lays the foundation. The search screen still
  /// reads `searchStateProvider` directly today; phase 3b ships the
  /// mixed-card widgets and phase 3c rewires the screen to consume this
  /// provider behind the [unifiedSearchResultsEnabledProvider] flag.
  ///
  /// Contract:
  ///
  /// * When the flag is off, returns an empty list. Callers fall back to
  ///   the legacy fuel-only path. This keeps the no-op semantics until
  ///   phase 3b/c land.
  /// * When the flag is on, walks both upstream sources independently:
  ///   - the fuel side via [searchStateProvider], mapping
  ///     [FuelStationResult]s through [StationAsRefuelOption] using the
  ///     currently selected fuel from [selectedFuelTypeProvider];
  ///   - the EV side via [eVSearchStateProvider], mapping every
  ///     [ChargingStation] through [ChargingStationAsRefuelOption].
  ///   The two lists are concatenated (fuel first, EV after) so the
  ///   downstream UI can apply its own sort/filter chips deterministically.
  /// * Stations whose price for the active fuel is `null` are skipped on
  ///   the fuel side. The phase-2 [StationAsRefuelOption] returns a null
  ///   price for those stations, but the unified list is consumed by
  ///   price-driven UI (lowest-first sort, savings badges); a price-less
  ///   row would render as a placeholder for no useful reason. Callers
  ///   that need *every* station regardless of price should keep using
  ///   `searchStateProvider`.
  /// * The provider NEVER throws. Loading and error states on either
  ///   upstream collapse to an empty contribution from that side; the
  ///   other side still surfaces. UI consumers treat an empty result
  ///   list as "no results yet" and rely on the upstream
  ///   [AsyncValue.isLoading] / `.hasError` flags for spinners + retry
  ///   affordances (phase 3b).
  ///
  /// Note: this is a synchronous, non-keep-alive provider — Riverpod
  /// re-derives it whenever any of the upstreams update, which is the
  /// behaviour we want so the unified card list refreshes as the fuel +
  /// EV searches land.
  UnifiedSearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unifiedSearchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unifiedSearchResultsHash();

  @$internal
  @override
  $ProviderElement<List<RefuelOption>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<RefuelOption> create(Ref ref) {
    return unifiedSearchResults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RefuelOption> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RefuelOption>>(value),
    );
  }
}

String _$unifiedSearchResultsHash() =>
    r'54035757d018d4552a630dbe75311e74affca4c5';
