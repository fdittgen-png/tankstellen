// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/sync/fleet/fleet_directory.dart';
import '../../../core/time/app_clock.dart';
import '../data/fleet_metrics_reader.dart';
import '../data/fleet_review_transport.dart';
import '../domain/expense.dart';
import '../domain/fleet_attention.dart';
import '../domain/fleet_kpis.dart';
import 'fleet_expense_providers.dart';

part 'fleet_manager_providers.g.dart';

/// One reporting window, UTC at both ends.
typedef FleetPeriod = ({DateTime from, DateTime to});

/// The default aggregation threshold when an organisation has not
/// configured one (ADR 0025 D9). A placeholder documented as
/// deployment configuration — never a legal conclusion.
const int kDefaultAggregationMinSamples = 5;

/// The manager dashboard's server seam.
@Riverpod(keepAlive: true)
FleetMetricsReader fleetMetricsReader(Ref ref) => const FleetMetricsReader();

/// The signed-in user a manager action is stamped with, or the empty
/// string when nobody is signed in.
///
/// Only the DEVICE's copy of the history uses it. The server stamps
/// `fleet_audit_events.actor` from `auth.uid()` inside the definer
/// body, so a client that lied here would produce a local history that
/// disagrees with the trail — and the trail is the one that counts.
@Riverpod(keepAlive: true)
String fleetActingUserId(Ref ref) =>
    SupabaseFleetReviewTransport.currentOrNull()?.userId ?? '';

/// The organisation the manager surfaces report on, as this device
/// last pulled it.
///
/// **This is the slice's one wiring point.** F3 (#4212 tail) owns
/// `FleetScope` — the provider that resolves membership, role and
/// directory freshness — and it is not on this branch. Rather than
/// guess at its shape, F9 reads the directory through this override
/// point: it returns null here, every manager screen renders its "no
/// fleet on this device" state, and the integrator replaces the body
/// with the scope's directory in one line. Tests override it directly.
///
/// The directory is also where the threshold and the vehicle names
/// come from, so wiring this one provider lights the whole surface.
@Riverpod(keepAlive: true)
FleetDirectory? fleetManagerDirectory(Ref ref) => null;

/// The organisation's own aggregation threshold, or the placeholder
/// default (D9). Floored at 1: suppression is not switchable off.
@riverpod
int fleetAggregationMinSamples(Ref ref) {
  final raw = ref.watch(fleetManagerDirectoryProvider)?.policy[
      'aggregationMinSamples'];
  final value = switch (raw) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? kDefaultAggregationMinSamples,
    _ => kDefaultAggregationMinSamples,
  };
  return value < 1 ? 1 : value;
}

/// The reporting window, defaulting to the last 90 days.
///
/// Ninety days because the fleet figures are built from fill-ups and
/// a shorter window on a vehicle refuelled fortnightly would sit under
/// the suppression threshold by construction — the dashboard would
/// show nothing and blame privacy for what is really the period.
@Riverpod(keepAlive: true)
class FleetReportPeriod extends _$FleetReportPeriod {
  @override
  FleetPeriod build() {
    final now = ref.watch(appClockProvider).now().toUtc();
    return (from: now.subtract(const Duration(days: 90)), to: now);
  }

  /// Report on [from]..[to] instead. A reversed pair is swapped rather
  /// than sent to a server that would refuse it.
  void select({required DateTime from, required DateTime to}) {
    final a = from.toUtc();
    final b = to.toUtc();
    state = a.isAfter(b) ? (from: b, to: a) : (from: a, to: b);
  }
}

/// The period's aggregate, or null when the question could not be
/// asked (no fleet on this device, no session, a server that refused).
///
/// Null is not "an empty fleet". The screens render two different
/// states, because a manager who is told their vehicles bought no fuel
/// when really the phone is offline has been told something false.
@riverpod
Future<FleetKpis?> fleetPeriodKpis(Ref ref) async {
  final directory = ref.watch(fleetManagerDirectoryProvider);
  if (directory == null) return null;
  final period = ref.watch(fleetReportPeriodProvider);
  return ref.watch(fleetMetricsReaderProvider).read(
        orgId: directory.orgId,
        from: period.from,
        to: period.to,
      );
}

/// The "Needs attention" list for the current period — empty when
/// there is nothing to report, never a placeholder.
@riverpod
List<FleetAttentionItem> fleetAttentionItems(Ref ref) {
  final kpis = ref.watch(fleetPeriodKpisProvider).asData?.value;
  return kpis == null ? const [] : fleetAttention(kpis);
}

/// The organisation's expense review queue (#4215 shipped the server
/// half and the workflow; #4216 gives it a screen).
///
/// Drafts never appear: the policy stops them server-side and
/// `decodeReviewQueue` drops one that somehow arrived anyway.
@riverpod
Future<List<Expense>> fleetReviewQueue(Ref ref) async {
  final directory = ref.watch(fleetManagerDirectoryProvider);
  if (directory == null) return const [];
  return ref.watch(fleetExpenseWorkflowProvider).reviewQueue(directory.orgId);
}

/// One vehicle's figures for the current period, or null when the
/// period holds no row for it at all.
@riverpod
FleetVehicleMetrics? fleetVehicleMetricsById(Ref ref, String fleetVehicleId) {
  final kpis = ref.watch(fleetPeriodKpisProvider).asData?.value;
  if (kpis == null) return null;
  for (final row in kpis.vehicles) {
    if (row.fleetVehicleId == fleetVehicleId) return row;
  }
  return null;
}

/// The org's own name for a vehicle, or null when this device's
/// directory does not know it. Never a plate unless the organisation
/// chose to publish a masked one.
@riverpod
FleetVehicleRow? fleetVehicleRowById(Ref ref, String fleetVehicleId) {
  final directory = ref.watch(fleetManagerDirectoryProvider);
  if (directory == null) return null;
  for (final v in directory.vehicles) {
    if (v.id == fleetVehicleId) return v;
  }
  return null;
}
