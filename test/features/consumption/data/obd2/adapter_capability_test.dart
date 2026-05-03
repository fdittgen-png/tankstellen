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
}
