// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Locale-neutral clock/duration format helpers (#3614) — the
// byte-identical `padLeft(2, '0')` / `m:ss` copies the consumption
// widgets and exporters each hand-rolled. These are language-neutral
// format masks (digits and separators only), not translatable text.

/// Two-digit zero-pad: `7` → `'07'`, `12` → `'12'`.
String twoDigits(int n) => n.toString().padLeft(2, '0');

/// Elapsed time as `m:ss` with unbounded minutes: `0:05`, `9:07`,
/// `75:30`. The trip-recording surfaces render their stopwatch with
/// this shape.
String formatMinutesSeconds(Duration d) =>
    '${d.inMinutes}:${twoDigits(d.inSeconds % 60)}';
