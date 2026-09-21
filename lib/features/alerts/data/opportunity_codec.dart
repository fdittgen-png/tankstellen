// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// JSON for [Opportunity], so a scan's findings outlive the scan (#4183).
///
/// The engine (#4149–#4153) is pure and in-memory. To reach the feed
/// (#4154) — and to answer "why didn't I get an alert" after the fact —
/// what a scan found has to be written down, including everything the
/// budget refused. Suppressed means "not a push", never "discarded", and
/// that promise is only real if the refused ones are still somewhere.
///
/// ## Two rules this codec keeps
///
/// **A value's provenance survives the round trip.** [Opportunity.priceAge]
/// is a `DataValue<Duration>` precisely because nine of seventeen
/// providers stamp nothing, and a codec that flattened it to a nullable
/// `int` would re-introduce the bug #4156 removed — at the one layer
/// where nobody would look for it. Every variant of the sealed type is
/// encoded with its reason or basis intact.
///
/// **A row we cannot read is skipped, never guessed.** Decoding returns
/// null on anything malformed or on an enum name this build does not
/// know (an older build reading a newer store). A feed that silently
/// drops one row is a small bug; a feed that invents `kind: bestStopNow`
/// for a row it could not parse is a wrong claim about money.
library;

import '../../../core/domain/data_value.dart';
import '../../../core/services/provider_capability.dart';
import '../domain/opportunity.dart';

/// Encodes and decodes [Opportunity] as plain JSON maps.
abstract final class OpportunityCodec {
  /// The codec version, stamped on every row.
  ///
  /// Read back but not yet branched on: with one version there is
  /// nothing to migrate, and a `switch` over a single case is a guess
  /// about the shape of a change that has not happened. It exists so
  /// that when a field does change, the rows already on devices say
  /// which shape they are.
  static const int version = 1;

  static Map<String, Object?> encode(Opportunity o) => {
        'v': version,
        'kind': o.kind.name,
        if (o.stationId != null) 'stationId': o.stationId,
        if (o.stationName != null) 'stationName': o.stationName,
        'fuelType': o.fuelType,
        'currentPrice': o.currentPrice,
        'reference': o.reference.name,
        if (o.referencePrice != null) 'referencePrice': o.referencePrice,
        if (o.grossSaving != null) 'grossSaving': o.grossSaving,
        if (o.detourCost != null) 'detourCost': o.detourCost,
        if (o.netSaving != null) 'netSaving': o.netSaving,
        'distanceKm': o.distanceKm,
        if (o.detourTime != null) 'detourTimeMs': o.detourTime!.inMilliseconds,
        'priceAge': encodePriceAge(o.priceAge),
        'confidence': o.confidence.name,
        'detectedAt': o.detectedAt.toIso8601String(),
        'expiresAt': o.expiresAt.toIso8601String(),
      };

  /// [Opportunity] from [json], or null when it cannot be read.
  static Opportunity? decode(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();

    final kind = _enumByName(OpportunityKind.values, map['kind']);
    final reference = _enumByName(OpportunityReference.values, map['reference']);
    final confidence = _enumByName(DataConfidence.values, map['confidence']);
    final fuelType = map['fuelType'];
    final currentPrice = _asDouble(map['currentPrice']);
    final distanceKm = _asDouble(map['distanceKm']);
    final detectedAt = _asDate(map['detectedAt']);
    final expiresAt = _asDate(map['expiresAt']);
    final priceAge = decodePriceAge(map['priceAge']);

    if (kind == null ||
        reference == null ||
        confidence == null ||
        fuelType is! String ||
        currentPrice == null ||
        distanceKm == null ||
        detectedAt == null ||
        expiresAt == null ||
        priceAge == null) {
      return null;
    }

    final detourMs = map['detourTimeMs'];
    return Opportunity(
      kind: kind,
      stationId: map['stationId'] as String?,
      stationName: map['stationName'] as String?,
      fuelType: fuelType,
      currentPrice: currentPrice,
      reference: reference,
      referencePrice: _asDouble(map['referencePrice']),
      grossSaving: _asDouble(map['grossSaving']),
      detourCost: _asDouble(map['detourCost']),
      netSaving: _asDouble(map['netSaving']),
      distanceKm: distanceKm,
      detourTime:
          detourMs is int ? Duration(milliseconds: detourMs) : null,
      priceAge: priceAge,
      confidence: confidence,
      detectedAt: detectedAt,
      expiresAt: expiresAt,
    );
  }

  /// The sealed [DataValue] variants, each with what makes it that
  /// variant. Total over the type, so adding a variant breaks here
  /// rather than silently encoding it as something else.
  static Map<String, Object?> encodePriceAge(DataValue<Duration> age) =>
      switch (age) {
        Measured<Duration>(:final value, :final at) => {
            'k': 'measured',
            'ms': value.inMilliseconds,
            if (at != null) 'at': at.toIso8601String(),
          },
        Estimated<Duration>(:final value, :final basis) => {
            'k': 'estimated',
            'ms': value.inMilliseconds,
            'basis': basis.name,
          },
        Stale<Duration>(:final value, :final age) => {
            'k': 'stale',
            'ms': value.inMilliseconds,
            'ageMs': age.inMilliseconds,
          },
        Unknown<Duration>(:final reason) => {
            'k': 'unknown',
            'reason': reason.name,
          },
      };

  static DataValue<Duration>? decodePriceAge(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    final ms = map['ms'];
    switch (map['k']) {
      case 'measured':
        if (ms is! int) return null;
        final at = _asDate(map['at']);
        return DataValue.measured(Duration(milliseconds: ms), at: at);
      case 'estimated':
        final basis = _enumByName(DataBasis.values, map['basis']);
        if (ms is! int || basis == null) return null;
        return DataValue.estimated(Duration(milliseconds: ms), basis: basis);
      case 'stale':
        final ageMs = map['ageMs'];
        if (ms is! int || ageMs is! int) return null;
        return DataValue.stale(Duration(milliseconds: ms),
            age: Duration(milliseconds: ageMs));
      case 'unknown':
        final reason = _enumByName(DataUnknownReason.values, map['reason']);
        if (reason == null) return null;
        return DataValue.unknown(reason: reason);
      default:
        return null;
    }
  }

  /// The enum value called [name], or null when this build has none.
  ///
  /// Null rather than a fallback: a row from a newer build naming a kind
  /// we do not have is a row we cannot render, and rendering it as the
  /// first enum value would put a confident wrong label on it.
  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static double? _asDouble(Object? v) => v is num ? v.toDouble() : null;

  static DateTime? _asDate(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}
