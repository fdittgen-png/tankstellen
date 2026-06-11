// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/broken_map_belief.dart';
import 'package:tankstellen/features/obd2/data/broken_map_detector.dart';
import 'package:tankstellen/features/obd2/data/oem_pid_table.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/broken_map_widgets.dart'
    show BrokenMapBand, brokenMapBandFor;
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// Locked-in regression fixtures for the broken-MAP detection edge
/// cases addressed by epic #1610 — diesel, high-altitude and
/// tuned-engine inputs (#1624).
///
/// Each fixture drives one full [BrokenMapDetector.probe] round and
/// pins the resulting [BrokenMapBand]. The band — not a raw float — is
/// the user-visible contract (silent / verifying chip / warning
/// snackbar / hard-disable banner), so locking the band is what keeps
/// a future membership-function or Bayes recalibration from silently
/// changing whether a user gets warned.
///
/// The high-altitude and tuned-engine fixtures specifically guard the
/// #1623 barometric + induction-class threshold scaling: without it,
/// the high-altitude petrol case would mis-classify into the verifying
/// band and the turbo case would score a borderline reading more
/// confidently than the wider band intends.
void main() {
  final fixedNow = DateTime(2026, 5, 4, 10, 30);

  setUp(() {
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _NoOpRecorder();
  });
  tearDown(errorLogger.resetForTest);

  group('broken-MAP edge-case fixtures (#1624)', () {
    for (final f in _fixtures) {
      test(f.name, () async {
        final belief = await const BrokenMapDetector().probe(
          f.port(),
          isDiesel: f.isDiesel,
          prior: const BrokenMapBelief(),
          now: fixedNow,
          vehicle: f.vehicle,
        );
        expect(belief.observationCount, 1,
            reason: 'the probe must fold exactly one observation');
        expect(
          brokenMapBandFor(belief.pointEstimate),
          f.expectedBand,
          reason: 'pointEstimate was ${belief.pointEstimate}',
        );
      });
    }
  });

  // The detection bands ladder up only across repeated observations —
  // a single fold from the weak default prior cannot reach the warning
  // band. This fixture pins that a *sustained* broken-diesel signal
  // crosses into the warning band (0.7) where the user is first told,
  // and that one more probe escalates to the hard-disable band (0.9).
  group('broken-MAP sustained-signal fixture (#1624)', () {
    test('two broken-diesel probes cross into the warning band, a third '
        'into hard-disable', () async {
      const detector = BrokenMapDetector();
      var belief = const BrokenMapBelief();
      for (var i = 0; i < 2; i++) {
        belief = await detector.probe(
          _brokenDieselPort(),
          isDiesel: true,
          prior: belief,
          now: fixedNow,
        );
      }
      expect(belief.observationCount, 2);
      expect(belief.pointEstimate, greaterThan(0.7));
      expect(brokenMapBandFor(belief.pointEstimate), BrokenMapBand.warning);

      final escalated = await detector.probe(
        _brokenDieselPort(),
        isDiesel: true,
        prior: belief,
        now: fixedNow,
      );
      expect(escalated.pointEstimate, greaterThan(0.9));
      expect(
        brokenMapBandFor(escalated.pointEstimate),
        BrokenMapBand.hardDisable,
      );
    });
  });

  // Direct contrast: the #1623 induction-band widening means a
  // borderline diesel rev swing scores *less confidently clean* on a
  // turbo than on a NA diesel — the turbo posterior sits higher.
  group('tuned-engine vs NA contrast (#1624)', () {
    test('a borderline rev swing lifts the posterior higher on a turbo',
        () async {
      const detector = BrokenMapDetector();
      // 28 kPa swing — near-healthy for a NA diesel.
      Map<String, List<String>> portMap() => {
            '0111\r': [_resp(0x11, 3)],
            '010B\r': [_resp(0x0B, 100), _resp(0x0B, 128)],
            '0133\r': [_resp(0x33, 101)],
          };
      final na = await detector.probe(
        _FakeRawPort(portMap()),
        isDiesel: true,
        prior: const BrokenMapBelief(),
        now: fixedNow,
        vehicle: _vehicle(InductionType.naturallyAspirated),
      );
      final turbo = await detector.probe(
        _FakeRawPort(portMap()),
        isDiesel: true,
        prior: const BrokenMapBelief(),
        now: fixedNow,
        vehicle: _vehicle(InductionType.turbocharged),
      );
      expect(turbo.pointEstimate, greaterThan(na.pointEstimate));
    });
  });
}

/// One named regression fixture.
class _Fixture {
  const _Fixture({
    required this.name,
    required this.isDiesel,
    required this.responses,
    required this.expectedBand,
    this.vehicle,
  });

  final String name;
  final bool isDiesel;
  final Map<String, List<String>> responses;
  final BrokenMapBand expectedBand;
  final ReferenceVehicle? vehicle;

  _FakeRawPort port() => _FakeRawPort(responses);
}

final List<_Fixture> _fixtures = [
  // --- Diesel, sea level -------------------------------------------------
  _Fixture(
    name: 'diesel — healthy 35 kPa rev swing at sea level → silent',
    isDiesel: true,
    responses: {
      '0111\r': [_resp(0x11, 3)],
      '010B\r': [_resp(0x0B, 95), _resp(0x0B, 130)],
      '0133\r': [_resp(0x33, 101)],
    },
    expectedBand: BrokenMapBand.silent,
  ),
  _Fixture(
    name: 'diesel — flat 1 kPa rev swing at sea level → verifying',
    isDiesel: true,
    responses: {
      '0111\r': [_resp(0x11, 3)],
      '010B\r': [_resp(0x0B, 98), _resp(0x0B, 99)],
      '0133\r': [_resp(0x33, 101)],
    },
    expectedBand: BrokenMapBand.verifying,
  ),
  // --- High altitude (low baro) -----------------------------------------
  // baro 80 kPa ≈ 2000 m. A 30 kPa idle vacuum delta at altitude is
  // proportionally normal; #1623 baro scaling keeps it in the silent
  // band. Without the scaling the fixed 15-45 window would score it
  // 0.5 and mis-classify into the verifying band.
  _Fixture(
    name: 'high-altitude petrol — 30 kPa vacuum at baro 80 stays silent',
    isDiesel: false,
    responses: {
      '0111\r': [_resp(0x11, 3)],
      '010B\r': [_resp(0x0B, 50)],
      '0133\r': [_resp(0x33, 80)],
    },
    expectedBand: BrokenMapBand.silent,
  ),
  // A genuinely broken sensor at altitude still reads near-atmospheric
  // and must still be caught — the scaling must not blind the detector.
  _Fixture(
    name: 'high-altitude petrol — broken (near-atmospheric MAP) still caught',
    isDiesel: false,
    responses: {
      '0111\r': [_resp(0x11, 3)],
      '010B\r': [_resp(0x0B, 78)],
      '0133\r': [_resp(0x33, 80)],
    },
    expectedBand: BrokenMapBand.verifying,
  ),
  // --- Tuned / forced-induction engines ---------------------------------
  // A turbo diesel with a borderline 28 kPa swing: the widened band
  // plus the induction Bayes-factor keep it out of a confident verdict
  // — silent on a single observation.
  _Fixture(
    name: 'turbo diesel — borderline 28 kPa swing → silent on one probe',
    isDiesel: true,
    responses: {
      '0111\r': [_resp(0x11, 3)],
      '010B\r': [_resp(0x0B, 100), _resp(0x0B, 128)],
      '0133\r': [_resp(0x33, 101)],
    },
    vehicle: _vehicle(InductionType.turbocharged),
    expectedBand: BrokenMapBand.silent,
  ),
  // A healthy turbo petrol pulling strong idle vacuum is unambiguous —
  // band widening adds tolerance but never invents a broken verdict.
  _Fixture(
    name: 'turbo petrol — strong idle vacuum → silent',
    isDiesel: false,
    responses: {
      '0111\r': [_resp(0x11, 3)],
      '010B\r': [_resp(0x0B, 35)],
      '0133\r': [_resp(0x33, 101)],
    },
    vehicle: _vehicle(InductionType.turbocharged),
    expectedBand: BrokenMapBand.silent,
  ),
];

Map<String, List<String>> _brokenDieselFixture() => {
      '0111\r': [_resp(0x11, 3)],
      '010B\r': [_resp(0x0B, 98), _resp(0x0B, 99)],
      '0133\r': [_resp(0x33, 101)],
    };

_FakeRawPort _brokenDieselPort() => _FakeRawPort(_brokenDieselFixture());

/// Minimal [ReferenceVehicle] carrying just the [inductionType] the
/// detector forwards to the membership-function scaling.
ReferenceVehicle _vehicle(InductionType induction) => ReferenceVehicle(
      make: 'Fixture',
      model: 'Edge',
      generation: 'I',
      yearStart: 2022,
      displacementCc: 1600,
      fuelType: 'diesel',
      transmission: 'manual',
      inductionType: induction,
    );

/// Build a Mode 01 single-byte response (`41 PID XX>` with prompt).
String _resp(int pid, int value) {
  final p = pid.toRadixString(16).padLeft(2, '0').toUpperCase();
  final v = value.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '41 $p $v\r>';
}

/// In-memory [Obd2RawCommandPort] — ordered canned responses per
/// command; unknown / exhausted commands resolve to the empty string,
/// the shape a real adapter delivers on NO DATA.
class _FakeRawPort implements Obd2RawCommandPort {
  _FakeRawPort(this.responses);

  final Map<String, List<String>> responses;
  final Map<String, int> _callCount = <String, int>{};

  @override
  Future<String> sendRaw(String command) async {
    final n = _callCount[command] ?? 0;
    _callCount[command] = n + 1;
    final list = responses[command];
    if (list == null || list.isEmpty) return '';
    return list[n < list.length ? n : list.length - 1];
  }
}

class _NoOpRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
