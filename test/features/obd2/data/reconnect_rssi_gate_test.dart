// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/reconnect_rssi_gate.dart';

/// Unit tests for the pure relative-RSSI / two-consecutive-batch gate
/// that the in-trip reconnect scan fallback uses (#2245). NOT an
/// absolute −85 dBm cutoff — gates relative to the last successful
/// connect this session.
void main() {
  group('shouldConnectFromScan (#2245)', () {
    test('connects when the seen RSSI is within −15 dBm of the baseline',
        () {
      // Baseline −60, seen −70 ⇒ drop of 10, inside the 15 dBm window.
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: -60,
          seenRssi: -70,
          consecutiveBatchesSeen: 1,
        ),
        isTrue,
      );
    });

    test('connects exactly at the −15 dBm boundary', () {
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: -60,
          seenRssi: -75, // exactly baseline − 15
          consecutiveBatchesSeen: 1,
        ),
        isTrue,
      );
    });

    test('skips a single weak sighting below the relative window', () {
      // Baseline −60, seen −80 ⇒ drop of 20, beyond 15 dBm, seen once.
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: -60,
          seenRssi: -80,
          consecutiveBatchesSeen: 1,
        ),
        isFalse,
      );
    });

    test('connects a weak sighting once it appears in two consecutive '
        'batches', () {
      // Same weak −80, but now seen twice — the stable-sighting rule
      // overrides the relative-RSSI miss.
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: -60,
          seenRssi: -80,
          consecutiveBatchesSeen: 2,
        ),
        isTrue,
      );
    });

    test('with no baseline yet, gates purely on two consecutive batches',
        () {
      // First reconnect of the session: no relative baseline exists.
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: null,
          seenRssi: -50, // strong, but baseline is unknown
          consecutiveBatchesSeen: 1,
        ),
        isFalse,
        reason: 'no baseline ⇒ a single sighting is not enough',
      );
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: null,
          seenRssi: -90, // even very weak, if seen twice it connects
          consecutiveBatchesSeen: 2,
        ),
        isTrue,
      );
    });

    test('a stronger-than-baseline sighting always connects', () {
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: -70,
          seenRssi: -50, // closer than baseline
          consecutiveBatchesSeen: 1,
        ),
        isTrue,
      );
    });

    test(
        'a bonded Classic sighting (rssi==0 sentinel, hint=classic) passes '
        'on the FIRST batch (#2565)', () {
      // Bluetooth Classic has no RSSI: the bonded-device enumeration pins
      // it at the 0 sentinel and surfaces it once per scan window. Without
      // the hint it would have to wait for a 2nd consecutive batch (which
      // intervening BLE batches keep resetting) — the storm signature.
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: null,
          seenRssi: 0, // Classic bonded sentinel
          consecutiveBatchesSeen: 1, // seen exactly once
          transportHint: 'classic',
        ),
        isTrue,
        reason: 'a bonded Classic adapter is in range by construction — '
            'connect on the first sighting, never wait for a second batch',
      );
    });

    test(
        'the Classic first-batch shortcut does NOT leak into the BLE gate '
        '(#2565)', () {
      // A BLE adapter never reports a 0 dBm RSSI, but even if seenRssi were
      // 0 with a BLE / null hint the legacy gate must still apply (no
      // baseline + seen once ⇒ skip).
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: null,
          seenRssi: 0,
          consecutiveBatchesSeen: 1,
          transportHint: 'ble',
        ),
        isFalse,
        reason: 'the first-batch shortcut is Classic-only — BLE keeps the '
            'two-consecutive-batches rule',
      );
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: null,
          seenRssi: 0,
          consecutiveBatchesSeen: 1,
          // No transportHint at all — the legacy callers pass none.
        ),
        isFalse,
      );
    });

    group('RECOVERY relaxation (#2907)', () {
      test('a marginal single-batch sighting connects in recovery but NOT '
          'in the default gate', () {
        // Baseline −60, seen −90 ⇒ a 30 dBm drop, seen exactly once. The
        // default gate skips it (beyond 15 dBm AND not seen twice); the
        // recovery gate attempts it (within the widened 35 dBm tolerance).
        expect(
          shouldConnectFromScan(
            lastSuccessfulRssi: -60,
            seenRssi: -90,
            consecutiveBatchesSeen: 1,
          ),
          isFalse,
          reason: 'the default initial-pick gate skips a far, single sighting',
        );
        expect(
          shouldConnectFromScan(
            lastSuccessfulRssi: -60,
            seenRssi: -90,
            consecutiveBatchesSeen: 1,
            recovery: true,
          ),
          isTrue,
          reason: 'recovery widens the tolerance to 35 dBm — the pinned '
              'adapter is worth a marginal reconnect attempt',
        );
      });

      test('with no baseline, ANY single sighting connects in recovery', () {
        // The first reconnect of the session has no relative baseline. The
        // default gate needs two consecutive batches; recovery attempts the
        // pinned MAC on the first sighting (no wrong-device risk).
        expect(
          shouldConnectFromScan(
            lastSuccessfulRssi: null,
            seenRssi: -88,
            consecutiveBatchesSeen: 1,
          ),
          isFalse,
        );
        expect(
          shouldConnectFromScan(
            lastSuccessfulRssi: null,
            seenRssi: -88,
            consecutiveBatchesSeen: 1,
            recovery: true,
          ),
          isTrue,
          reason: 'a pinned-MAC recovery scan attempts any first sighting',
        );
      });

      test('recovery still rejects a sighting weaker than the widened '
          'tolerance when seen only once', () {
        // Baseline −50, seen −95 ⇒ a 45 dBm drop, beyond even the 35 dBm
        // recovery window, and seen exactly once ⇒ still skipped.
        expect(
          shouldConnectFromScan(
            lastSuccessfulRssi: -50,
            seenRssi: -95,
            consecutiveBatchesSeen: 1,
            recovery: true,
          ),
          isFalse,
        );
        // …but a second consecutive sighting of even that weak link connects.
        expect(
          shouldConnectFromScan(
            lastSuccessfulRssi: -50,
            seenRssi: -95,
            consecutiveBatchesSeen: 2,
            recovery: true,
          ),
          isTrue,
        );
      });
    });

    test('honours custom thresholds', () {
      // Tighten the window to 5 dBm: a 10 dBm drop now fails the
      // relative gate and, seen once, is skipped.
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: -60,
          seenRssi: -70,
          consecutiveBatchesSeen: 1,
          relativeDropDbm: 5,
        ),
        isFalse,
      );
      // Require 3 consecutive batches: two sightings of a weak adapter
      // are no longer enough.
      expect(
        shouldConnectFromScan(
          lastSuccessfulRssi: -60,
          seenRssi: -90,
          consecutiveBatchesSeen: 2,
          requiredConsecutiveBatches: 3,
        ),
        isFalse,
      );
    });
  });
}
