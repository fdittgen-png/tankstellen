// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/vehicle_profile.dart' show ConnectorType;

part 'mixed_results_filter_provider.g.dart';

/// Filters for the unified fuel + EV search-results list (#1784).
///
/// These are screen-scoped (not `keepAlive`) so the selection resets
/// when the user leaves the results screen — same lifetime as the
/// brand filter. They are deliberately independent of the legacy
/// `unifiedFilterStateProvider` (which drives the superseded
/// `UnifiedSearchResultsView`, removed by #1789) so this pipeline does
/// not depend on a to-be-deleted file.

/// Which station kinds the mixed results list shows.
enum ResultKind {
  /// Fuel stations only.
  fuel,

  /// EV charging stations only.
  ev,

  /// Both kinds — the unified list's default.
  both,
}

/// The active [ResultKind] filter. Defaults to [ResultKind.both] — the
/// whole point of the unified list is the mixed feed.
@riverpod
class ResultKindFilter extends _$ResultKindFilter {
  @override
  ResultKind build() => ResultKind.both;

  // ignore: use_setters_to_change_properties
  void set(ResultKind kind) => state = kind;
}

/// Selected EV connector-type filter. An empty set is a no-op (all
/// connector types pass). Applied only to EV rows by
/// `filteredSortedSearchResults`; fuel rows are never routed through it.
@riverpod
class EvConnectorFilter extends _$EvConnectorFilter {
  @override
  Set<ConnectorType> build() => const {};

  /// Adds [type] when absent, removes it when present.
  void toggle(ConnectorType type) {
    final next = Set<ConnectorType>.from(state);
    if (!next.add(type)) next.remove(type);
    state = next;
  }

  /// Clears the connector filter (all types pass again).
  void clear() => state = const {};
}

/// Minimum charging power (kW) filter. `0` means no minimum. Applied
/// only to EV rows.
@riverpod
class EvMinPowerFilter extends _$EvMinPowerFilter {
  @override
  double build() => 0;

  /// Sets the minimum power, clamped to a sane 0–350 kW envelope.
  void set(double kw) => state = kw.clamp(0, 350);
}
