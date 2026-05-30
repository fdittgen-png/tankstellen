// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/supported_pids_resolver.dart';

/// #2457 — discover-all ∩ target-set. The live subscription set is the
/// target PID table intersected with the car's discovered-supported set,
/// with the #811 don't-reject-blind fallback when discovery never ran.
void main() {
  // The #2457 target table (the PIDs subscribed post-#2456).
  const target = <int>{
    0x0C, 0x0D, 0x10, 0x0B, 0x11, 0x5E, // dynamics
    0x44, 0x04, // mixture
    0x06, 0x07, 0x0F, 0x33, // slow-correction
    0x05, 0x2F, // thermal/context
  };

  SupportedPidsResolver buildResolver() => SupportedPidsResolver(
        // discoverSupportedPids walks 0100..01C0; we hand it canned
        // bitmaps via this send closure per test as needed. Default: a
        // resolver with no discovery run (blind session).
        send: (cmd) async => 'NO DATA',
        isConnected: () => true,
      );

  group('SupportedPidsResolver.isResolved', () {
    test('false before any discovery (blind session)', () {
      expect(buildResolver().isResolved, isFalse);
    });
  });

  group('SupportedPidsResolver.resolvedTargetSet — discover-all ∩ target', () {
    test(
        'a probe-less clone (no discovery) resolves to the FULL target set '
        'so the unconditional core still rotates', () {
      final resolver = buildResolver();
      // No discovery has run → don't-reject-blind: the whole target set is
      // returned unchanged.
      expect(resolver.resolvedTargetSet(target), unorderedEquals(target));
    });

    test(
        'a basic car supporting only {0C,0D,04,11} subscribes exactly those '
        '— not the full target', () async {
      // Drive discovery with a bitmap that advertises only the four basic
      // PIDs. 0100 covers PIDs 01..20; set bits for 04, 0C, 0D, 11.
      // Standard supported-PIDs bitmap: 4 bytes, MSB = PID 01. We craft a
      // response by hand for those four bits (and clear the next-range
      // flag so the scan stops after 0100).
      final supported = <int>{0x04, 0x0C, 0x0D, 0x11};
      final resolver = SupportedPidsResolver(
        send: (cmd) async {
          if (cmd.startsWith('0100')) {
            return _bitmapResponse(0x00, supported);
          }
          return 'NO DATA';
        },
        isConnected: () => true,
      );
      final discovered = await resolver.discoverSupportedPids();
      expect(discovered, unorderedEquals(supported),
          reason: 'sanity: discovery parsed the four supported PIDs');

      final resolved = resolver.resolvedTargetSet(target);
      expect(resolved, unorderedEquals(<int>{0x0C, 0x0D, 0x04, 0x11}),
          reason: 'target ∩ discovered keeps only the four the car has');
      // The optional air-mass / mixture PIDs are dropped.
      for (final absent in <int>{0x10, 0x0B, 0x5E, 0x44, 0x33}) {
        expect(resolved, isNot(contains(absent)));
      }
    });

    test('the resolved set is unmodifiable', () {
      final resolved = buildResolver().resolvedTargetSet(target);
      expect(() => resolved.add(0xFF), throwsUnsupportedError);
    });
  });
}

/// Build a Mode-01 supported-PIDs bitmap response for [groupBase] (e.g.
/// 0x00 for the 0100 query) advertising [supported] and clearing the
/// next-range flag. The 4 data bytes have the MSB of byte 0 = PID
/// (groupBase + 1), matching the SAE J1979 layout the parser decodes.
String _bitmapResponse(int groupBase, Set<int> supported) {
  var bits = 0;
  for (final pid in supported) {
    final offset = pid - groupBase; // 1..32
    if (offset < 1 || offset > 32) continue;
    bits |= 1 << (32 - offset);
  }
  final hex = bits.toRadixString(16).padLeft(8, '0').toUpperCase();
  const mode = 0x41; // response to Mode 01
  final pid = groupBase.toRadixString(16).padLeft(2, '0').toUpperCase();
  final bytes = <String>[
    for (var i = 0; i < 8; i += 2) hex.substring(i, i + 2),
  ];
  return '${mode.toRadixString(16).toUpperCase()} $pid ${bytes.join(' ')}>';
}
