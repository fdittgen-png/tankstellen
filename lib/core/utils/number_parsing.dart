// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The two ways a number arrives as text, each parsed in exactly one place
/// (#3983).
///
/// Four copies of `_parseDouble` had grown apart: three API parsers accepted
/// `num` or a trimmed `String` (some feeds send `"12.5"`, some `12.5`), and
/// the vehicle form accepted a decimal comma — so `1,5` parsed on one screen
/// and not on another. Two rules, named for their input, not one that
/// guesses.
library;

/// A value from a decoded payload: `null`, a `num`, or a `String` holding a
/// dot-decimal number (leading/trailing whitespace tolerated; empty → null).
/// Anything else → null. Never throws.
double? parseLooseDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
  return null;
}

/// Text a user typed: whitespace trimmed, a decimal comma accepted as a
/// decimal point (`1,5` and `1.5` are the same number). Empty → null.
/// Never throws.
double? parseUserDouble(String text) {
  final trimmed = text.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}
