// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/data_value.dart';
import '../../../core/domain/fleet/claim_class.dart';
import '../../../core/domain/fleet/fleet_provenance.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/sync/sync_transport.dart' show JsonRow;
import '../domain/fleet_kpis.dart';
import 'fleet_review_transport.dart';

/// The manager dashboard's one door to the server (#4216).
///
/// Thin on purpose: the arithmetic is `fleet_period_metrics`' (where
/// the suppression threshold cannot be bypassed) and `FleetKpis`'s
/// (where provenance survives the roll-up). What lives here is the
/// boundary — decoding the wire row into [ClaimedValue]s that state
/// their claim class, and telling "there is nothing to report" apart
/// from "I could not ask", because a dashboard that renders an empty
/// fleet after a failed call has lied about the fleet.
class FleetMetricsReader {
  const FleetMetricsReader({this.transport});

  /// The wire. `null` resolves
  /// [SupabaseFleetReviewTransport.currentOrNull] at call time, so
  /// production passes nothing and a test injects a fake.
  final FleetReviewTransport? transport;

  /// The period's figures, or **null** when the question could not be
  /// asked at all (no session, or the server refused).
  ///
  /// An empty [FleetKpis] means "this organisation reported nothing in
  /// this period"; null means "ask again". The screen renders two
  /// different things, and conflating them is how an offline manager
  /// concludes their fleet stopped buying fuel.
  Future<FleetKpis?> read({
    required String orgId,
    required DateTime from,
    required DateTime to,
  }) async {
    final wire = transport ?? SupabaseFleetReviewTransport.currentOrNull();
    if (wire == null) return null;
    final List<JsonRow> rows;
    try {
      rows = await wire.selectPeriodMetrics(
          orgId: orgId, from: from, to: to);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: const {
        'where': 'FleetMetricsReader.read refused',
      });
      return null;
    }
    return FleetKpis.over(decodePeriodMetrics(rows));
  }

  /// Record that a manager took the aggregate off the device.
  ///
  /// Returns false when the trail was NOT written — no session, a
  /// refusal, a server that said no. ADR 0025 D5.4 makes the audit row
  /// part of the export, not a side effect of it, so a caller that
  /// gets false must not hand over the file.
  Future<bool> logExport({
    required String orgId,
    required String kind,
  }) async {
    final wire = transport ?? SupabaseFleetReviewTransport.currentOrNull();
    if (wire == null) return false;
    try {
      return await wire.logExport(orgId: orgId, kind: kind);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: const {
        'where': 'FleetMetricsReader.logExport refused',
      });
      return false;
    }
  }
}

/// Decode `fleet_period_metrics` rows into the domain (#4216).
///
/// Three things the decode is careful about:
///
///  * a row the server marked `suppressed` becomes
///    [FleetVehicleMetrics.suppressedRow] and nothing else is read off
///    it — not even a sample count it should not be carrying;
///  * every figure arrives as a [ClaimedValue] under the class ADR
///    0025 gives it, so a screen cannot render litres and CO2e the
///    same way by accident;
///  * a CO2e number with no factor version is dropped to "not
///    calculated". The server ties the two together; this is the belt,
///    because #4219's rule is that a number never appears without the
///    source behind it.
///
/// A row this build cannot read is skipped rather than half-decoded.
List<FleetVehicleMetrics> decodePeriodMetrics(List<JsonRow> rows) {
  final out = <FleetVehicleMetrics>[];
  for (final row in rows) {
    final id = row['fleet_vehicle_id'];
    if (id is! String || id.isEmpty) continue;
    if (row['suppressed'] == true) {
      out.add(FleetVehicleMetrics.suppressedRow(id));
      continue;
    }
    final samples = _int(row['sample_count']) ?? 0;
    final currency = row['currency'];
    final co2 = _double(row['co2e_kg']);
    final version = row['co2_factor_version'];
    final hasFactor = co2 != null && version is String && version.isNotEmpty;
    out.add(FleetVehicleMetrics(
      fleetVehicleId: id,
      suppressed: false,
      spend: _fact(_double(row['spend']), samples),
      currency: currency is String && currency.isNotEmpty ? currency : null,
      litres: _fact(_double(row['litres']), samples),
      km: _fact(_double(row['km']), samples),
      co2eKg: hasFactor
          ? ClaimedValue<double>.unchecked(
              Estimated<double>(co2, basis: DataBasis.fleetAverage),
              claim: ClaimClass.environmentalEstimate,
              sampleCount: samples,
              provenance: const [
                FleetMetricSource.measuredFillUp,
                FleetMetricSource.derived,
              ],
            )
          : ClaimedValue<double>.notCalculated(
              reason: DataUnknownReason.notPublishedForThisItem,
              claim: ClaimClass.environmentalEstimate,
            ),
      co2FactorVersion: hasFactor ? version : null,
      measuredShare: _derived(_double(row['measured_share']), samples),
      sampleCount: samples,
    ));
  }
  return out;
}

/// Class 1 over a pump-confirmed number, or a stated absence.
ClaimedValue<double> _fact(double? value, int samples) => value == null
    ? ClaimedValue<double>.notCalculated(
        reason: DataUnknownReason.notMeasuredYet,
        claim: ClaimClass.measuredFact)
    : ClaimedValue<double>.measuredFact(value,
        source: FleetMetricSource.measuredFillUp, sampleCount: samples);

/// Class 2 over measured inputs the server already combined.
ClaimedValue<double> _derived(double? value, int samples) => value == null
    ? ClaimedValue<double>.notCalculated(
        reason: DataUnknownReason.notMeasuredYet,
        claim: ClaimClass.calculatedOperational)
    : ClaimedValue<double>.unchecked(
        Measured<double>(value),
        claim: ClaimClass.calculatedOperational,
        sampleCount: samples,
        provenance: const [
          FleetMetricSource.measuredFillUp,
          FleetMetricSource.derived,
        ],
      );

/// PostgREST hands `numeric` back as a JSON number on one build and a
/// string on another; neither is a reason to lose a figure.
double? _double(Object? raw) => switch (raw) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };

int? _int(Object? raw) => switch (raw) {
      final int n => n,
      final num n => n.toInt(),
      final String s => int.tryParse(s),
      _ => null,
    };
