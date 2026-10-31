// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4552 — byte extraction from a raw Mode 01 reply as the diagnostic
/// trace stores it (lines joined with ` | `). Pure, isolate-safe.
library;

/// Data bytes of the Mode 01 reply to [pid] in [reply] (first answering
/// ECU), or null. `41 0C 1A F8` → `[0x1A, 0xF8]`.
List<int>? mode01Bytes(String reply, int pid) {
  final tokens = reply
      .toUpperCase()
      .split(RegExp(r'[\s|]+'))
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
  final want = pid.toRadixString(16).toUpperCase().padLeft(2, '0');
  for (var i = 0; i + 1 < tokens.length; i++) {
    if (tokens[i] != '41' || tokens[i + 1] != want) continue;
    final out = <int>[];
    for (var j = i + 2; j < tokens.length; j++) {
      final v = int.tryParse(tokens[j], radix: 16);
      if (v == null || tokens[j].length != 2 || tokens[j] == '41') break;
      out.add(v);
    }
    return out.isEmpty ? null : out;
  }
  return null;
}
