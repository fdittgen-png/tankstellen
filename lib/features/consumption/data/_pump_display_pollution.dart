/// Pre-processing helpers that strip OCR pollution from French pump
/// photos before [PumpDisplayParser] applies labelled extraction and
/// positional inference.
///
/// Split out of `pump_display_parser.dart` so the parser file stays
/// focused on orchestration. Re-exported by the parser so existing
/// callers / tests that `import 'pump_display_parser.dart'` keep
/// resolving [stripPumpDisplayPollution] without changes.
library;

/// Lines matching the French metrology header block that appears on
/// every French pump (Tokheim, Dresser Wayne). The block spans from
/// "Note du service de la Métrologie…" to the first blank line, and
/// its free-text content routinely pollutes positional inference.
final RegExp _kFrenchMetrologyHeader = RegExp(
  r'note\s+du\s+s[eè]rvice\s+de\s+la\s+m[eé]trologie',
  caseSensitive: false,
);

/// Card-reader / UI-overlay labels that appear on the plate beside
/// the main display. These are not part of the transaction readout
/// and must be stripped before positional inference — otherwise
/// numbers printed on the card-reader plate (e.g. regulatory notices)
/// leak into the bucket of candidate decimals.
final RegExp _kOverlayKeywordLine = RegExp(
  r'^(?:carte|cb|re[çc]u|visa|mastercard|paiement|esp[eè]ces?|nouveau|'
  r'contr[ôo]le\s+qualit[eé]|mmq|livraison\s+minimale|pr[eé]paiement)\b',
  caseSensitive: false,
);

/// A lone single-digit "1".."9" on its own line — the station number
/// sticker on the pump housing. The parser still consumes it as a
/// pump-number candidate via `kLonePumpDigitPattern`; we only want
/// to keep it out of the positional-inference decimal pool.
final RegExp _kLoneDigitLine = RegExp(r'^[1-9]$');

/// Removes French pump-photo pollution from OCR text before pattern
/// matching and positional inference:
///
/// 1. The *"Note du service de la Métrologie…"* header block —
///    stripped from its first line up to (and including) the next
///    blank line.
/// 2. Card-reader plate labels (*Carte*, *CB*, *Reçu*, *Visa*,
///    *Mastercard*, *Paiement*, *Espèces*, *Nouveau*, *Contrôle
///    Qualité*, *MMQ*, *Livraison minimale*, *Prépaiement*).
/// 3. Single-digit station stickers ("1".."9" alone on a line).
///
/// Exposed as a top-level function so the unit tests can exercise it
/// in isolation without spinning up the full parser.
String stripPumpDisplayPollution(String rawText) {
  final lines = rawText.split(RegExp(r'\r?\n'));
  final kept = <String>[];
  var inMetrologyBlock = false;
  for (final line in lines) {
    final trimmed = line.trim();
    if (inMetrologyBlock) {
      // End the block on the first blank line.
      if (trimmed.isEmpty) {
        inMetrologyBlock = false;
        kept.add(line);
      }
      continue;
    }
    if (_kFrenchMetrologyHeader.hasMatch(trimmed)) {
      inMetrologyBlock = true;
      continue;
    }
    if (_kOverlayKeywordLine.hasMatch(trimmed)) continue;
    if (_kLoneDigitLine.hasMatch(trimmed)) {
      // Keep the line so the pump-number extractor still sees it
      // (it reads from the RAW text, not the stripped text). But
      // replace with an empty line so positional inference skips it.
      kept.add('');
      continue;
    }
    kept.add(line);
  }
  return kept.join('\n');
}
