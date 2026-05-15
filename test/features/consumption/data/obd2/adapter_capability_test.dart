import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_capability.dart';

void main() {
  group('detectCapabilityFromFirmwareString (#1401 phase 1)', () {
    group('STN-chip family → passiveCanCapable', () {
      test('STN1110 v4.0.4 (OBDLink MX+ stock firmware)', () {
        expect(
          detectCapabilityFromFirmwareString('STN1110 v4.0.4'),
          Obd2AdapterCapability.passiveCanCapable,
        );
      });

      test('STN2120 v5.7.1 (newer STN family member)', () {
        expect(
          detectCapabilityFromFirmwareString('STN2120 v5.7.1'),
          Obd2AdapterCapability.passiveCanCapable,
        );
      });

      test('lowercase stn1110 still matches (case-insensitive)', () {
        expect(
          detectCapabilityFromFirmwareString('stn1110'),
          Obd2AdapterCapability.passiveCanCapable,
        );
      });

      test('whitespace padding is trimmed before matching', () {
        expect(
          detectCapabilityFromFirmwareString('  STN1110  '),
          Obd2AdapterCapability.passiveCanCapable,
        );
      });
    });

    group('genuine ELM327 v2.2+ → oemPidsCapable', () {
      test('ELM327 v2.2', () {
        expect(
          detectCapabilityFromFirmwareString('ELM327 v2.2'),
          Obd2AdapterCapability.oemPidsCapable,
        );
      });

      test('ELM327 v2.3', () {
        expect(
          detectCapabilityFromFirmwareString('ELM327 v2.3'),
          Obd2AdapterCapability.oemPidsCapable,
        );
      });

      test('ELM327 v3.0 (future-proofs against a real v3 release)', () {
        expect(
          detectCapabilityFromFirmwareString('ELM327 v3.0'),
          Obd2AdapterCapability.oemPidsCapable,
        );
      });
    });

    group('clones / older firmware → standardOnly', () {
      test('ELM327 v2.1 — the clone-trap case', () {
        // Many counterfeit ELM327 clones report v2.1 but only support
        // the v1.x command set. Phase 1 trusts the version string and
        // floors the threshold at v2.2; a runtime feature-probe that
        // downgrades lying clones is filed in the epic caveats.
        expect(
          detectCapabilityFromFirmwareString('ELM327 v2.1'),
          Obd2AdapterCapability.standardOnly,
        );
      });

      test('ELM327 v2.0', () {
        expect(
          detectCapabilityFromFirmwareString('ELM327 v2.0'),
          Obd2AdapterCapability.standardOnly,
        );
      });

      test('ELM327 v1.5', () {
        expect(
          detectCapabilityFromFirmwareString('ELM327 v1.5'),
          Obd2AdapterCapability.standardOnly,
        );
      });
    });

    group('safe-default cases → standardOnly', () {
      test('empty string', () {
        expect(
          detectCapabilityFromFirmwareString(''),
          Obd2AdapterCapability.standardOnly,
        );
      });

      test('null', () {
        expect(
          detectCapabilityFromFirmwareString(null),
          Obd2AdapterCapability.standardOnly,
        );
      });

      test('garbage / unrecognised banner', () {
        expect(
          detectCapabilityFromFirmwareString('random garbage'),
          Obd2AdapterCapability.standardOnly,
        );
      });

      test('plausibly-named but unknown firmware', () {
        expect(
          detectCapabilityFromFirmwareString('MyCustomFirmware'),
          Obd2AdapterCapability.standardOnly,
        );
      });
    });
  });

  // #1614 — runtime multi-frame ISO 15765 probe that downgrades clones
  // whose firmware string lies about their tier.
  group('classifyMultiFrameProbeResponse (#1614)', () {
    test('a genuine multi-frame VIN reply (49 02 ...) → passed', () {
      expect(
        classifyMultiFrameProbeResponse(
            '014\n0: 49 02 01 57 50 30\n1: 5A 5A 5A 39 38 5A>'),
        CapabilityProbeResult.multiFramePassed,
      );
    });

    test('positive service id without spaces (4902) → passed', () {
      expect(
        classifyMultiFrameProbeResponse('4902015750>'),
        CapabilityProbeResult.multiFramePassed,
      );
    });

    test('CAN ERROR → failed', () {
      expect(
        classifyMultiFrameProbeResponse('CAN ERROR>'),
        CapabilityProbeResult.multiFrameFailed,
      );
    });

    test('BUFFER FULL → failed', () {
      expect(
        classifyMultiFrameProbeResponse('BUFFER FULL>'),
        CapabilityProbeResult.multiFrameFailed,
      );
    });

    test('Mode 09 negative response (7F 09 12) → failed', () {
      expect(
        classifyMultiFrameProbeResponse('7F 09 12>'),
        CapabilityProbeResult.multiFrameFailed,
      );
    });

    test('unrecognised-command marker (?) → failed', () {
      expect(
        classifyMultiFrameProbeResponse('?>'),
        CapabilityProbeResult.multiFrameFailed,
      );
    });

    test('empty response → failed', () {
      expect(
        classifyMultiFrameProbeResponse('   '),
        CapabilityProbeResult.multiFrameFailed,
      );
    });

    test('NO DATA is inconclusive (pre-2005 car) → passed, not a downgrade',
        () {
      expect(
        classifyMultiFrameProbeResponse('NO DATA>'),
        CapabilityProbeResult.multiFramePassed,
      );
    });
  });

  group('probeMultiFrameCapability (#1614)', () {
    test('probe-pass — adapter routes the multi-frame VIN reply', () async {
      final result = await probeMultiFrameCapability(
        (cmd) async {
          expect(cmd, multiFrameProbeCommand);
          return '014\n0: 49 02 01 57 50 30>';
        },
      );
      expect(result, CapabilityProbeResult.multiFramePassed);
    });

    test('probe-fail — adapter returns an error token', () async {
      final result = await probeMultiFrameCapability(
        (cmd) async => 'CAN ERROR>',
      );
      expect(result, CapabilityProbeResult.multiFrameFailed);
    });

    test('probe-fail — the send itself throws', () async {
      final result = await probeMultiFrameCapability(
        (cmd) async => throw StateError('transport dropped'),
      );
      expect(result, CapabilityProbeResult.multiFrameFailed);
    });

    test('probe-timeout — the adapter never answers', () async {
      final result = await probeMultiFrameCapability(
        (cmd) => Completer<String>().future, // never completes
        timeout: const Duration(milliseconds: 50),
      );
      expect(result, CapabilityProbeResult.timedOut);
    });
  });

  group('reconcileCapabilityWithProbe (#1614)', () {
    test('a passed probe keeps the claimed tier', () {
      for (final claimed in Obd2AdapterCapability.values) {
        expect(
          reconcileCapabilityWithProbe(
              claimed, CapabilityProbeResult.multiFramePassed),
          claimed,
        );
      }
    });

    test('a failed probe collapses any tier to standardOnly', () {
      expect(
        reconcileCapabilityWithProbe(Obd2AdapterCapability.oemPidsCapable,
            CapabilityProbeResult.multiFrameFailed),
        Obd2AdapterCapability.standardOnly,
      );
      expect(
        reconcileCapabilityWithProbe(Obd2AdapterCapability.passiveCanCapable,
            CapabilityProbeResult.multiFrameFailed),
        Obd2AdapterCapability.standardOnly,
      );
    });

    test('a timed-out probe collapses any tier to standardOnly', () {
      expect(
        reconcileCapabilityWithProbe(Obd2AdapterCapability.oemPidsCapable,
            CapabilityProbeResult.timedOut),
        Obd2AdapterCapability.standardOnly,
      );
      expect(
        reconcileCapabilityWithProbe(Obd2AdapterCapability.passiveCanCapable,
            CapabilityProbeResult.timedOut),
        Obd2AdapterCapability.standardOnly,
      );
    });
  });
}
