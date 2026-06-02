// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/services/fill_up_monthly_stats_aggregator.dart';
import 'consumption_providers.dart';

part 'monthly_fuel_stats_provider.g.dart';

/// Per-month fill-up statistics for the consumption-statistics detail
/// page (#2698), oldest first. Each month carries the FULL
/// `ConsumptionStats` for that month's fill-ups via the canonical
/// `ConsumptionStats.fromFillUps` window walker — so the page can show
/// month-over-month comparison + evolution charts with no new storage.
///
/// Lives in its own file (not the [fillUpListProvider] god-class) so the
/// 975-line consumption_providers.dart stays at its file_length snapshot.
@riverpod
List<MonthlyFuelStats> monthlyFuelStats(Ref ref) =>
    FillUpMonthlyStatsAggregator.byMonth(ref.watch(fillUpListProvider));
