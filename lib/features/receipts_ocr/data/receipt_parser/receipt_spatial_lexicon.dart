// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Multi-language, OCR-confusion-tolerant label lexicon for the spatial
/// receipt parser (#3458).
///
/// Replaces the regex table of `receipt_label_table.dart`: the field
/// evidence (Pézenas E85 receipt, 2026-07-03) showed the thermal-print
/// "TOT TTC" arriving from ML Kit as "TOT TIC" — a one-glyph confusion no
/// exact regex catches. Classification here is token-based: each block is
/// accent-folded, upper-cased and split into words, and every word is
/// matched EXACTLY against the short-term table and with **edit distance
/// ≤ 1** against the long-term table (≥ 4 chars), so `TOT TIC`,
/// `VOLUNE` and `PRECI0`-style one-glyph confusions still classify.
///
/// All words are DATA (what the paper receipt prints), never user-facing
/// ARB strings.
library;

/// What a printed receipt label denotes.
enum ReceiptLabelKind { volume, unitPrice, total, vat, net }

/// Short label terms (≤ 3 chars) matched EXACTLY — fuzzy matching on
/// 3-char tokens produces false positives, so these never fuzz. `TOT`
/// alone classifies as total, which is what rescues the `TOT TIC`
/// confusion without fuzzing `TTC` itself.
const Map<String, ReceiptLabelKind> _exactShortTerms = {
  'TOT': ReceiptLabelKind.total,
  'TTC': ReceiptLabelKind.total,
  'TVA': ReceiptLabelKind.vat,
  'IVA': ReceiptLabelKind.vat,
  'VAT': ReceiptLabelKind.vat,
  'DPH': ReceiptLabelKind.vat,
  'MVA': ReceiptLabelKind.vat,
  'NET': ReceiptLabelKind.net,
  'HT': ReceiptLabelKind.net,
  'PU': ReceiptLabelKind.unitPrice,
  'QTY': ReceiptLabelKind.volume,
};

/// Long label terms (≥ 4 chars) matched with edit distance ≤ 1.
const Map<String, ReceiptLabelKind> _fuzzyTerms = {
  // --- volume -------------------------------------------------------
  'VOLUME': ReceiptLabelKind.volume,
  'VOLUMEN': ReceiptLabelKind.volume,
  'MENGE': ReceiptLabelKind.volume,
  'LITER': ReceiptLabelKind.volume,
  'LITRE': ReceiptLabelKind.volume,
  'LITRES': ReceiptLabelKind.volume,
  'LITRI': ReceiptLabelKind.volume,
  'LITROS': ReceiptLabelKind.volume,
  'QUANTITE': ReceiptLabelKind.volume,
  'QUANTITA': ReceiptLabelKind.volume,
  'QUANTITY': ReceiptLabelKind.volume,
  'MNOZSTVI': ReceiptLabelKind.volume,
  'OBJEM': ReceiptLabelKind.volume,
  // --- price per litre ----------------------------------------------
  'PRIX': ReceiptLabelKind.unitPrice,
  'PREIS': ReceiptLabelKind.unitPrice,
  'PRIS': ReceiptLabelKind.unitPrice,
  'PRECIO': ReceiptLabelKind.unitPrice,
  'PREZZO': ReceiptLabelKind.unitPrice,
  'PRICE': ReceiptLabelKind.unitPrice,
  'LITERPREIS': ReceiptLabelKind.unitPrice,
  'CENA': ReceiptLabelKind.unitPrice,
  'UNIT': ReceiptLabelKind.unitPrice,
  // --- total --------------------------------------------------------
  'TOTAL': ReceiptLabelKind.total,
  'TOTALE': ReceiptLabelKind.total,
  'TOTAAL': ReceiptLabelKind.total,
  'GESAMT': ReceiptLabelKind.total,
  'SUMME': ReceiptLabelKind.total,
  'SUMMA': ReceiptLabelKind.total,
  'BETRAG': ReceiptLabelKind.total,
  'MONTANT': ReceiptLabelKind.total,
  'IMPORTE': ReceiptLabelKind.total,
  'IMPORTO': ReceiptLabelKind.total,
  'CELKEM': ReceiptLabelKind.total,
  // --- VAT / net exclusions -----------------------------------------
  'MWST': ReceiptLabelKind.vat,
  'MEHRWERTSTEUER': ReceiptLabelKind.vat,
  'MOMS': ReceiptLabelKind.vat,
  'NETTO': ReceiptLabelKind.net,
};

/// Accent folding for the label vocabulary (é→E, à→A, č→C, ž→Z, í→I, …)
/// so `Quantité`, `Quantità`, `Množství` normalise to the folded table
/// keys. Applied AFTER upper-casing.
const Map<String, String> _accentFold = {
  'À': 'A', 'Á': 'A', 'Â': 'A', 'Ä': 'A', 'Å': 'A', 'Ã': 'A',
  'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ě': 'E',
  'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
  'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O',
  'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U', 'Ů': 'U',
  'Č': 'C', 'Ç': 'C', 'Ć': 'C',
  'Ď': 'D', 'Ñ': 'N', 'Ň': 'N',
  'Ř': 'R', 'Š': 'S', 'Ś': 'S',
  'Ť': 'T', 'Ý': 'Y',
  'Ž': 'Z', 'Ź': 'Z', 'Ż': 'Z',
  'Ł': 'L', 'ß': 'SS',
};

/// Upper-cases and accent-folds [raw] for lexicon comparison.
String foldReceiptToken(String raw) {
  final upper = raw.toUpperCase();
  final sb = StringBuffer();
  for (final ch in upper.split('')) {
    sb.write(_accentFold[ch] ?? ch);
  }
  return sb.toString();
}

/// Splits a block's text into candidate label words (letters only —
/// digits/punctuation are separators, so `TVA 20,00 %` yields `TVA` and
/// `P.U.` yields `P` + `U`, which re-joins to `PU` for the short table).
List<String> _labelTokens(String text) {
  final folded = foldReceiptToken(text);
  final words =
      folded.split(RegExp(r'[^A-Z]+')).where((w) => w.isNotEmpty).toList();
  // `P.U.` / `p. u.` arrive as single letters; re-join adjacent
  // single-letter runs so the short table can match `PU`.
  final joined = <String>[];
  final run = StringBuffer();
  for (final w in words) {
    if (w.length == 1) {
      run.write(w);
      continue;
    }
    if (run.isNotEmpty) {
      joined.add(run.toString());
      run.clear();
    }
    joined.add(w);
  }
  if (run.isNotEmpty) joined.add(run.toString());
  return joined;
}

/// `true` when [a] and [b] are within Levenshtein distance 1 (one
/// substitution, insertion or deletion) — the OCR one-glyph confusion
/// budget (`TIC`↔`TTC` class, `T0TAL`, `VOLUNE`).
bool withinOneEdit(String a, String b) {
  if (a == b) return true;
  final la = a.length, lb = b.length;
  if ((la - lb).abs() > 1) return false;
  if (la == lb) {
    var diffs = 0;
    for (var i = 0; i < la; i++) {
      if (a[i] != b[i]) {
        diffs++;
        if (diffs > 1) return false;
      }
    }
    return true;
  }
  // Lengths differ by one: try to align with a single skip in the longer.
  final long = la > lb ? a : b;
  final short = la > lb ? b : a;
  var i = 0, j = 0;
  var skipped = false;
  while (i < long.length && j < short.length) {
    if (long[i] == short[j]) {
      i++;
      j++;
      continue;
    }
    if (skipped) return false;
    skipped = true;
    i++; // skip one char in the longer string
  }
  return true;
}

/// Classifies [text] as a receipt label, or null when no lexicon term
/// matches. Every word is tried exactly against the short table and with
/// edit distance ≤ 1 against the long table. When several kinds match in
/// one block, exclusions win (`TOTAL HT` is the NET line, `MONTANT TVA`
/// the VAT line), then unit-price beats total beats volume — the receipt
/// convention where the bare `Prix` is the per-litre price.
ReceiptLabelKind? classifySpatialLabel(String text) {
  final kinds = <ReceiptLabelKind>{};
  for (final token in _labelTokens(text)) {
    final exact = _exactShortTerms[token];
    if (exact != null) {
      kinds.add(exact);
      continue;
    }
    if (token.length < 4) continue;
    for (final entry in _fuzzyTerms.entries) {
      if ((token.length - entry.key.length).abs() > 1) continue;
      if (withinOneEdit(token, entry.key)) {
        kinds.add(entry.value);
        break;
      }
    }
  }
  if (kinds.isEmpty) return null;
  // Priority: exclusion lines first so a VAT/Net line can never be
  // claimed as a transaction field.
  for (final kind in const [
    ReceiptLabelKind.vat,
    ReceiptLabelKind.net,
    ReceiptLabelKind.unitPrice,
    ReceiptLabelKind.total,
    ReceiptLabelKind.volume,
  ]) {
    if (kinds.contains(kind)) return kind;
  }
  return null;
}

/// `true` when [fullText] carries enough fuel-station markers to route a
/// receipt to the spatial parser (legacy flat-text heuristic kept from
/// #2848 for receipts whose blocks are too fused to classify): a
/// pump/volume/price marker AND a per-litre price signal.
bool looksLikeFuelStationReceipt(String fullText) {
  final lower = fullText.toLowerCase();
  final hasPump =
      RegExp(r'\bpompe\b|\bpump\b|\bs[aä]ule\b|\bpista\b').hasMatch(lower);
  final hasVolume =
      RegExp(r'\bvolume\b|\bquantit|\blitres?\b|\blitri\b').hasMatch(lower);
  final hasPriceLabel =
      RegExp(r'\bprix\b|prix\s*unit|\bp\.?\s*u\.?\b|literpreis|prezzo')
          .hasMatch(lower);
  final hasPerLitreToken =
      RegExp(r'(?:€|eur)\s*/\s*l|/\s*l\b|€\s*\d').hasMatch(lower);

  final stationSignal = hasPump || hasVolume || hasPriceLabel;
  final priceSignal = hasPerLitreToken || (hasPriceLabel && hasVolume);
  return stationSignal && priceSignal;
}
