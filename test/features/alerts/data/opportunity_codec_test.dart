// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/data/opportunity_codec.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';

/// #4183 — the codec that lets a scan's findings outlive the scan.
///
/// The assertions that matter are the two the library doc names:
/// provenance survives the trip, and an unreadable row is skipped rather
/// than guessed at.
void main() {
  final detected = DateTime.utc(2026, 9, 15, 8);
  final expires = detected.add(const Duration(hours: 6));

  Opportunity opportunity({
    DataValue<Duration> priceAge =
        const DataValue<Duration>.measured(Duration(minutes: 12)),
    double? gross,
    double? detour,
    double? net,
    String? stationId = 'de-abc',
    Duration? detourTime,
  }) =>
      Opportunity(
        kind: OpportunityKind.bestStopNow,
        stationId: stationId,
        stationName: 'ARAL Berlin',
        fuelType: 'e10',
        currentPrice: 1.649,
        reference: OpportunityReference.localMedian,
        referencePrice: 1.729,
        grossSaving: gross,
        detourCost: detour,
        netSaving: net,
        distanceKm: 3.2,
        detourTime: detourTime,
        priceAge: priceAge,
        confidence: DataConfidence.high,
        detectedAt: detected,
        expiresAt: expires,
      );

  /// The round trip a real store performs: through actual JSON text, not
  /// just through the maps. A `Duration` that only survives an in-memory
  /// map is not persisted.
  Opportunity? roundTrip(Opportunity o) => OpportunityCodec.decode(
      jsonDecode(jsonEncode(OpportunityCodec.encode(o))));

  group('round trip', () {
    test('every field survives', () {
      final original = opportunity(
        gross: 4.20,
        detour: 0.40,
        net: 3.80,
        detourTime: const Duration(minutes: 4),
      );
      final back = roundTrip(original)!;

      expect(back, original,
          reason: 'Opportunity == covers the load-bearing fields');
      expect(back.stationName, original.stationName);
      expect(back.grossSaving, 4.20);
      expect(back.detourCost, 0.40);
      expect(back.detourTime, const Duration(minutes: 4));
      expect(back.confidence, DataConfidence.high);
      expect(back.savingIsReproducible, isTrue,
          reason: 'trust rule 4 must still hold after a round trip — a '
              'codec that rounded the money would make a stored claim '
              'stop reconciling');
    });

    test('an unpriced opportunity stays unpriced, not zeroed', () {
      final back = roundTrip(opportunity())!;
      expect(back.netSaving, isNull);
      expect(back.isPriceable, isFalse,
          reason: 'a missing saving encoded as 0.0 would make it rankable '
              'on money it does not have');
    });

    test('an opportunity about an area keeps its null station', () {
      final back = roundTrip(opportunity(stationId: null))!;
      expect(back.stationId, isNull);
    });
  });

  group('priceAge provenance', () {
    test('measured survives with its value', () {
      final back = roundTrip(opportunity(
          priceAge: const DataValue.measured(Duration(hours: 3))))!;
      expect(back.priceAge, const Measured(Duration(hours: 3)));
    });

    test('measured keeps its observation time', () {
      final at = DateTime.utc(2026, 9, 15, 7, 30);
      final back = roundTrip(opportunity(
          priceAge: DataValue.measured(const Duration(hours: 1), at: at)))!;
      expect((back.priceAge as Measured<Duration>).at, at);
    });

    test('unknown survives WITH ITS REASON', () {
      // The one that matters: nine of seventeen providers stamp nothing,
      // and flattening this to a nullable int would re-introduce the bug
      // #4156 removed, at a layer nobody would look at.
      final back = roundTrip(opportunity(
          priceAge: const DataValue.unknown(
              reason: DataUnknownReason.notPublishedByProvider)))!;
      expect(
          back.priceAge,
          const DataValue<Duration>.unknown(
              reason: DataUnknownReason.notPublishedByProvider));
    });

    test('the two reasons for an unknown stay distinct', () {
      final byProvider = roundTrip(opportunity(
          priceAge: const DataValue.unknown(
              reason: DataUnknownReason.notPublishedByProvider)))!;
      final byRow = roundTrip(opportunity(
          priceAge: const DataValue.unknown(
              reason: DataUnknownReason.notPublishedForThisItem)))!;
      expect(byProvider.priceAge, isNot(byRow.priceAge),
          reason: '"the provider publishes nothing" and "the provider '
              'left this row blank" are different facts and the feed '
              'renders them differently');
    });

    test('estimated and stale are encodable too — the type is sealed', () {
      // Neither is produced by ProviderCapability.priceAge today. The
      // codec is total over the sealed type anyway, so adding a producer
      // later does not silently write a row nothing can read back.
      expect(
          OpportunityCodec.decodePriceAge(OpportunityCodec.encodePriceAge(
              const DataValue.estimated(Duration(hours: 2),
                  basis: DataBasis.fleetAverage))),
          const Estimated(Duration(hours: 2), basis: DataBasis.fleetAverage));
      expect(
          OpportunityCodec.decodePriceAge(OpportunityCodec.encodePriceAge(
              const DataValue.stale(Duration(hours: 2),
                  age: Duration(days: 3)))),
          const Stale(Duration(hours: 2), age: Duration(days: 3)));
    });
  });

  group('a row we cannot read is skipped, never guessed', () {
    test('not a map', () {
      expect(OpportunityCodec.decode('nonsense'), isNull);
      expect(OpportunityCodec.decode(null), isNull);
    });

    test('an unknown kind — a row from a newer build', () {
      final map = OpportunityCodec.encode(opportunity())
        ..['kind'] = 'someKindThisBuildDoesNotHave';
      expect(OpportunityCodec.decode(map), isNull,
          reason: 'falling back to the first enum value would put a '
              'confident wrong label on a row about money');
    });

    test('an unknown unknown-reason', () {
      final map = OpportunityCodec.encode(opportunity());
      (map['priceAge']! as Map)['reason'] = 'somethingNew';
      (map['priceAge']! as Map)['k'] = 'unknown';
      expect(OpportunityCodec.decode(map), isNull);
    });

    test('a missing required field', () {
      final map = OpportunityCodec.encode(opportunity())..remove('currentPrice');
      expect(OpportunityCodec.decode(map), isNull);
    });

    test('a price that is not a number', () {
      final map = OpportunityCodec.encode(opportunity())
        ..['currentPrice'] = '1.649';
      expect(OpportunityCodec.decode(map), isNull,
          reason: 'a string price parsed leniently is how a decimal comma '
              'becomes a wrong number');
    });

    test('an unparseable timestamp', () {
      final map = OpportunityCodec.encode(opportunity())
        ..['expiresAt'] = 'yesterday';
      expect(OpportunityCodec.decode(map), isNull);
    });
  });

  test('every row is stamped with the codec version', () {
    expect(OpportunityCodec.encode(opportunity())['v'], OpportunityCodec.version);
  });
}
