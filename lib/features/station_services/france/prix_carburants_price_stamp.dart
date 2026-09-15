// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The Prix-Carburants price stamp, parsed once and offered in two
/// forms (#4189).
///
/// Its own library because the two forms are the whole point, and
/// keeping them together is what stops the mistake this issue fixed: the
/// adapter used to parse the provider's `*_maj` stamp, format it as
/// `dd/MM HH:mm`, and throw the instant away. `DateTime.tryParse` then
/// returned null for the survivor, `ProviderCapability.priceAge` read
/// that as "the provider left this row blank", the freshness gate
/// blocked, and the confident pick was silently withheld across France.
///
/// One value, two outputs, side by side, each labelled for what it is
/// for. `prix_carburants_parsers.dart` was also at the 400-line cap.
library;

import '../../../core/logging/app_log.dart';

/// The most recent `*_maj` stamp on a record, as a real instant (#4189).
///
/// The machine-readable half. `parsePrixCarburantsMostRecentUpdate`
/// renders the same value for display; this one is what the
/// price-freshness gate reasons over. Null when no `*_maj` field is
/// populated or the newest one will not parse — an absent age, never a
/// guessed one.
DateTime? parsePrixCarburantsUpdatedAt(Map<String, dynamic> r) {
  final newest = _newestMaj(r);
  return newest == null ? null : DateTime.tryParse(newest);
}

/// The newest populated `*_maj` value on [r], or null.
String? _newestMaj(Map<String, dynamic> r) {
  final dates = <String>[
    r['gazole_maj']?.toString() ?? '',
    r['sp95_maj']?.toString() ?? '',
    r['e10_maj']?.toString() ?? '',
    r['sp98_maj']?.toString() ?? '',
    r['e85_maj']?.toString() ?? '',
    r['gplc_maj']?.toString() ?? '',
  ].where((d) => d.isNotEmpty).toList();
  if (dates.isEmpty) return null;
  dates.sort((a, b) => b.compareTo(a)); // Most recent first
  return dates.first;
}

/// Format the most recent `*_maj` ISO timestamp on a record as
/// `dd/MM HH:mm`. Returns `null` when no timestamp fields are
/// populated; falls back to a trimmed substring on malformed input.
///
/// **Display only** — see [Station.updatedAt]. Reasoning about freshness
/// goes through [parsePrixCarburantsUpdatedAt] (#4189).
String? parsePrixCarburantsMostRecentUpdate(Map<String, dynamic> r) {
  final dates = <String>[?_newestMaj(r)];
  if (dates.isEmpty) return null;
  // Format: "2026-03-23T00:01:00+00:00" → "23/03 00:01"
  try {
    final dt = DateTime.parse(dates.first);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } on FormatException catch (e, st) {
    // #3977 — the façade, not a hand-rolled block. Moving code to a new
    // file must ratchet DOWN at the new site, never relocate a baseline
    // entry (the per-FILE lints all key on the path).
    log.error(e, st, context: const {
      'where': 'Prix-Carburants date parse failed',
    });
    final raw = dates.first;
    final cut = raw.length >= 16 ? raw.substring(0, 16) : raw;
    return cut.replaceAll('T', ' ');
  }
}
