// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/supported_pids_resolver.dart';

/// #2457 → #3532 — the live subscription set is the OPTIMISTIC UNION:
/// the full target table is subscribed regardless of the discovered
/// `0100` bitmap (clone adapters under-report it; #2475's hard intersect
/// permanently starved PIDs the ECU actually answers — Epic #3527).
/// Only runtime probation (3× consecutive REAL `NO DATA` through
/// [SupportedPidsResolver.noteMode01Reply]) parks a PID, and any parsed
/// reply lifts it again.
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

  group('SupportedPidsResolver.resolvedTargetSet — optimistic union (#3532)',
      () {
    test(
        'a probe-less clone (no discovery) resolves to the FULL target set '
        'so the unconditional core still rotates', () {
      final resolver = buildResolver();
      expect(resolver.resolvedTargetSet(target), unorderedEquals(target));
    });

    test(
        'UNDER-REPORTING bitmap fixture: PIDs the fake ECU answers stay '
        'live even though the bitmap omits them (the #2475 regression)',
        () async {
      // The clone's bitmap advertises only the four basic PIDs…
      final claimed = <int>{0x04, 0x0C, 0x0D, 0x11};
      final resolver = SupportedPidsResolver(
        send: (cmd) async {
          if (cmd.startsWith('0100')) {
            return _bitmapResponse(0x00, claimed);
          }
          return 'NO DATA';
        },
        isConnected: () => true,
      );
      final discovered = await resolver.discoverSupportedPids();
      expect(discovered, unorderedEquals(claimed),
          reason: 'sanity: discovery parsed the four claimed PIDs');

      // …but the ECU actually ANSWERS 0x0B (manifold pressure). Under the
      // old hard intersect this PID was dead for the whole trip; under
      // #3532 it is subscribed and its answers keep it live.
      resolver.noteMode01Reply('010B', '41 0B 64>', parsed: true);
      expect(resolver.isPidSupported(0x0B), isTrue,
          reason: 'an answering PID must never be rejected by the bitmap');
      expect(resolver.resolvedTargetSet(target), unorderedEquals(target),
          reason: 'nothing in probation → the full target set subscribes');
    });

    test('the resolved set is unmodifiable', () {
      final resolved = buildResolver().resolvedTargetSet(target);
      expect(() => resolved.add(0xFF), throwsUnsupportedError);
    });
  });

  group('SupportedPidsResolver — runtime probation (#3532)', () {
    test('3 consecutive real NO DATA replies park the PID; the resolved '
        'target set and isPidSupported both drop it', () {
      final resolver = buildResolver();
      for (var i = 0; i < SupportedPidsResolver.probationThreshold; i++) {
        resolver.noteMode01Reply('015E', 'NO DATA>', parsed: false);
      }
      expect(resolver.isPidInProbation(0x5E), isTrue);
      expect(resolver.isPidSupported(0x5E), isFalse);
      expect(resolver.resolvedTargetSet(target), isNot(contains(0x5E)));
      // The rest of the target set is untouched.
      expect(resolver.resolvedTargetSet(target),
          unorderedEquals(target.difference({0x5E})));
    });

    test('a parsed reply mid-streak resets the counter — flaky ECUs never '
        'reach probation', () {
      final resolver = buildResolver();
      resolver.noteMode01Reply('015E', 'NO DATA>', parsed: false);
      resolver.noteMode01Reply('015E', 'NO DATA>', parsed: false);
      resolver.noteMode01Reply('015E', '41 5E 00 A0>', parsed: true);
      resolver.noteMode01Reply('015E', 'NO DATA>', parsed: false);
      resolver.noteMode01Reply('015E', 'NO DATA>', parsed: false);
      expect(resolver.isPidInProbation(0x5E), isFalse);
      expect(resolver.isPidSupported(0x5E), isTrue);
    });

    test('an answer LIFTS an existing probation (regain path)', () {
      final resolver = buildResolver();
      for (var i = 0; i < SupportedPidsResolver.probationThreshold; i++) {
        resolver.noteMode01Reply('010B', 'NO DATA>', parsed: false);
      }
      expect(resolver.isPidInProbation(0x0B), isTrue);
      resolver.noteMode01Reply('010B', '41 0B 64>', parsed: true);
      expect(resolver.isPidInProbation(0x0B), isFalse);
      expect(resolver.isPidSupported(0x0B), isTrue);
    });

    test('timeouts / garbage / bus errors are link weather — they never '
        'count toward probation', () {
      final resolver = buildResolver();
      for (final weather in [
        '', // timeout-shaped empty read
        'ATZ ELM327 v1.5>', // garbage / echo
        'CAN ERROR>', // bus trouble
        'STOPPED>', // interrupted
      ]) {
        for (var i = 0; i < 5; i++) {
          resolver.noteMode01Reply('010C', weather, parsed: false);
        }
      }
      expect(resolver.isPidInProbation(0x0C), isFalse,
          reason: 'only classified NO DATA is evidence of an absent PID');
    });

    test('non-mode-01 / multi-byte commands are ignored', () {
      final resolver = buildResolver();
      for (var i = 0; i < 5; i++) {
        resolver.noteMode01Reply('0902', 'NO DATA>', parsed: false); // mode 09
        resolver.noteMode01Reply('ATRV', 'NO DATA>', parsed: false); // AT
        resolver.noteMode01Reply('010C1', 'NO DATA>', parsed: false); // odd
      }
      expect(resolver.debugProbationPids, isEmpty);
    });

    test('resetForNewConnection clears probation — the next session '
        'retries every parked PID', () {
      final resolver = buildResolver();
      for (var i = 0; i < SupportedPidsResolver.probationThreshold; i++) {
        resolver.noteMode01Reply('015E', 'NO DATA>', parsed: false);
      }
      expect(resolver.isPidInProbation(0x5E), isTrue);
      resolver.resetForNewConnection();
      expect(resolver.isPidInProbation(0x5E), isFalse);
      expect(resolver.isPidSupported(0x5E), isTrue);
    });

    test('isPidInBitmap stays STRICT for the #3416 precision gate — '
        'probation never widens it', () async {
      final claimed = <int>{0x0C, 0x0D};
      final resolver = SupportedPidsResolver(
        send: (cmd) async {
          if (cmd.startsWith('0100')) {
            return _bitmapResponse(0x00, claimed);
          }
          return 'NO DATA';
        },
        isConnected: () => true,
      );
      await resolver.discoverSupportedPids();
      expect(resolver.isPidInBitmap(0x0C), isTrue);
      expect(resolver.isPidInBitmap(0x66), isFalse,
          reason: 'rare precision PIDs must never be blind-subscribed');
      // An optimistic answer elsewhere doesn't change the bitmap claim.
      resolver.noteMode01Reply('0166', '41 66 ...>', parsed: true);
      expect(resolver.isPidInBitmap(0x66), isFalse);
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
