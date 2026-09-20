// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4213 — the recognition-priority table. The rules under test are the
// five #4213 lists in order ("Recognition priority") plus the two hard
// prohibitions: a conflict is never resolved by guessing, and a
// registration/search hit never attributes anything by itself.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/api.dart';

/// A mid-month Wednesday — never a weekend, month boundary or DST edge.
final _now = DateTime.utc(2026, 3, 11, 14, 30);
final _clock = FixedClock(_now);

VehicleSignal _signal(
  VehicleAttributionSource source,
  String vehicleId, {
  double confidence = 0.9,
  List<String> evidence = const <String>[],
  String? localVehicleId,
}) =>
    VehicleSignal(
      source: source,
      fleetVehicleId: vehicleId,
      confidence: confidence,
      evidence: evidence,
      localVehicleId: localVehicleId,
    );

VehicleAttributionResolution _resolve(List<VehicleSignal> signals) =>
    VehicleAttributionResolver.resolve(signals, clock: _clock);

void main() {
  group('the priority table is the declaration order', () {
    test('explicit outranks adapter, VIN, QR and search', () {
      expect(
        VehicleAttributionSource.values.map((s) => s.name).toList(),
        ['explicit', 'adapterIdentity', 'vin', 'qr', 'search'],
        reason: 'the resolver sorts on `source.index`; reordering this '
            'enum silently reorders #4213\'s recognition priority',
      );
    });

    test('only the adapter, the VIN and the QR tag are machine evidence',
        () {
      expect(
        [
          for (final s in VehicleAttributionSource.values)
            if (s.isAutomaticEvidence) s.name,
        ],
        ['adapterIdentity', 'vin', 'qr'],
      );
    });

    test('a source round-trips through its wire name, and an unknown one '
        'decodes as null rather than as *some* source', () {
      for (final s in VehicleAttributionSource.values) {
        expect(VehicleAttributionSource.fromWireName(s.wireName), s);
      }
      expect(VehicleAttributionSource.fromWireName('telepathy'), isNull);
      expect(VehicleAttributionSource.fromWireName(null), isNull);
    });
  });

  group('1. explicit beats everything', () {
    test('an explicit pick wins over a confident adapter AND a confident '
        'VIN naming a different car', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-B',
            confidence: 1, evidence: ['adapter:AA:BB']),
        _signal(VehicleAttributionSource.vin, 'veh-B',
            confidence: 1, evidence: ['vin:WVW-B']),
        _signal(VehicleAttributionSource.explicit, 'veh-A',
            confidence: 0.2, evidence: ['tap']),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.confirmed);
      expect(r.attribution!.fleetVehicleId, 'veh-A');
      expect(r.attribution!.source, VehicleAttributionSource.explicit);
      expect(r.attribution!.confidence, 1,
          reason: 'a driver who picks a car IS the ground truth — the '
              'signal\'s own confidence never lowers an explicit pick');
    });

    test('an explicit pick is reportable even when every machine signal '
        'disagrees', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.explicit, 'veh-A'),
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-B'),
      ]);

      expect(r.attribution!.isReportable, isTrue);
    });

    test('two explicit picks naming different cars still refuse — a '
        'caller bug must not become a silent choice', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.explicit, 'veh-A'),
        _signal(VehicleAttributionSource.explicit, 'veh-B'),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.needsConfirmation);
      expect(r.attribution, isNull);
      expect(r.candidates, ['veh-A', 'veh-B']);
    });
  });

  group('2-3. conflicting machine evidence never picks a car', () {
    test('adapter says A, VIN says B → needs confirmation, and NEITHER is '
        'attributed', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-A',
            confidence: 0.95, evidence: ['adapter:AA:BB:CC']),
        _signal(VehicleAttributionSource.vin, 'veh-B',
            confidence: 0.99, evidence: ['vin:WVWZZZ']),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.needsConfirmation);
      expect(r.needsConfirmation, isTrue);
      expect(r.attribution, isNull,
          reason: 'the higher-confidence VIN must NOT win a conflict — '
              '#4213: conflicting adapter/VIN evidence never silently '
              'changes the active vehicle');
      expect(r.candidates, ['veh-A', 'veh-B'],
          reason: 'both proposals are offered, in priority order');
      expect(r.evidence, ['adapter:AA:BB:CC', 'vin:WVWZZZ'],
          reason: 'the confirmation state shows what disagreed');
    });

    test('a QR tag disagreeing with the adapter is a conflict too', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-A'),
        _signal(VehicleAttributionSource.qr, 'veh-C'),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.needsConfirmation);
      expect(r.candidates, ['veh-A', 'veh-C']);
    });

    test('adapter and VIN AGREEING confirm on the adapter — the '
        'higher-priority source — and keep both pieces of evidence', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.vin, 'veh-A',
            confidence: 0.8, evidence: ['vin:WVWZZZ']),
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-A',
            confidence: 0.7,
            evidence: ['adapter:AA:BB:CC'],
            localVehicleId: 'local-1'),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.confirmed);
      expect(r.attribution!.source, VehicleAttributionSource.adapterIdentity);
      expect(r.attribution!.localVehicleId, 'local-1');
      expect(r.attribution!.confidence, 0.8,
          reason: 'corroboration keeps the BEST confidence of the '
              'agreeing signals, not the winner\'s own');
      expect(r.attribution!.evidence, ['adapter:AA:BB:CC', 'vin:WVWZZZ']);
      expect(r.attribution!.at, _now);
    });
  });

  group('4. low confidence is not a fact', () {
    test('a weak adapter signal alone asks for confirmation', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-A',
            confidence: 0.59),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.needsConfirmation);
      expect(r.candidates, ['veh-A']);
    });

    test('two weak signals agreeing are still two weak signals', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-A',
            confidence: 0.4),
        _signal(VehicleAttributionSource.vin, 'veh-A', confidence: 0.5),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.needsConfirmation,
          reason: 'corroboration must not manufacture confidence — '
              '#4213: low-confidence attribution never enters fleet '
              'reporting as fact');
    });

    test('exactly at the threshold it confirms', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-A',
            confidence: VehicleAttributionResolver.minimumAutomaticConfidence),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.confirmed);
      expect(r.attribution!.isReportable, isTrue);
    });
  });

  group('5. a search hit is a search aid, never an attribution', () {
    test('a search signal alone never confirms, however confident', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.search, 'veh-A', confidence: 1),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.needsConfirmation);
      expect(r.attribution, isNull,
          reason: '#4213: registration/visual information is a search '
              'aid, never automatic attribution');
    });

    test('a search signal does not turn an agreeing adapter into a '
        'conflict, and does not win over it', () {
      final r = _resolve([
        _signal(VehicleAttributionSource.adapterIdentity, 'veh-A'),
        _signal(VehicleAttributionSource.search, 'veh-Z'),
      ]);

      expect(r.verdict, VehicleAttributionVerdict.confirmed);
      expect(r.attribution!.fleetVehicleId, 'veh-A');
      expect(r.attribution!.source, VehicleAttributionSource.adapterIdentity);
    });

    test('no signals at all is "none" — not a conflict, not an error', () {
      final r = _resolve(const []);

      expect(r.verdict, VehicleAttributionVerdict.none);
      expect(r.attribution, isNull);
      expect(r.needsConfirmation, isFalse);
    });
  });

  group('an attribution survives persistence unchanged', () {
    test('round-trips through JSON', () {
      final original = VehicleAttribution(
        fleetVehicleId: 'veh-A',
        localVehicleId: 'local-1',
        source: VehicleAttributionSource.adapterIdentity,
        confidence: 0.82,
        evidence: const ['adapter:AA:BB:CC', 'vin:WVWZZZ'],
        at: _now,
      );

      final decoded = VehicleAttribution.fromJson(original.toJson());

      expect(decoded, original);
    });

    test('a blob missing the identity, the source or the stamp decodes as '
        'NO attribution — never a half one', () {
      expect(
        VehicleAttribution.fromJson(const {
          'source': 'explicit',
          'at': '2026-03-11T14:30:00.000Z',
        }),
        isNull,
      );
      expect(
        VehicleAttribution.fromJson(const {
          'fleet_vehicle_id': 'veh-A',
          'source': 'telepathy',
          'at': '2026-03-11T14:30:00.000Z',
        }),
        isNull,
        reason: 'a source a newer build invented must not read as *some* '
            'source',
      );
      expect(
        VehicleAttribution.fromJson(const {
          'fleet_vehicle_id': 'veh-A',
          'source': 'explicit',
          'at': 'not-a-time',
        }),
        isNull,
      );
    });

    test('the converter maps null both ways, so a personal fill-up stays '
        'attribution-free', () {
      const converter = VehicleAttributionJsonConverter();

      expect(converter.fromJson(null), isNull);
      expect(converter.toJson(null), isNull);
      expect(
        converter.fromJson(converter.toJson(VehicleAttribution(
          fleetVehicleId: 'veh-A',
          source: VehicleAttributionSource.explicit,
          confidence: 1,
          at: _now,
        ))),
        isNotNull,
      );
    });
  });
}
