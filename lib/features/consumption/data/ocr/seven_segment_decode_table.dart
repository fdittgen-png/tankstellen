// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Canonical 7-segment patterns and the [SevenSegmentReading] result
/// type, factored out of `seven_segment_recognizer.dart` to keep each
/// file focused (and inside the 400-line cap).
library;

/// Canonical segment patterns (a,b,c,d,e,f,g) → digit. The keys are the
/// seven booleans joined as a bit-string in a–g order:
///
///     aaaa
///    f    b
///     gggg
///    e    c
///     dddd
const Map<String, String> kSegmentTable = <String, String>{
  '1111110': '0',
  '0110000': '1',
  '1101101': '2',
  '1111001': '3',
  '0110011': '4',
  '1011011': '5',
  '1011111': '6',
  '1110000': '7',
  '1111111': '8',
  '1111011': '9',
  // Tolerant variants where one faint segment drops out under glare.
  '1111100': '0', // d faint
  '0111110': '6', // a faint
  '1110011': '4', // a bleeds into a 4
};

/// Result of decoding one 7-segment number.
class SevenSegmentReading {
  /// The decoded characters, including any decimal point (e.g. `8.03`).
  /// May contain `?` for an unmatched glyph.
  final String text;

  /// `0..1` — fraction of digit cells that matched a known pattern.
  final double confidence;

  /// Number of digit cells decoded (excludes gaps / decimal points).
  final int digitCount;

  const SevenSegmentReading({
    required this.text,
    required this.confidence,
    required this.digitCount,
  });

  static const empty =
      SevenSegmentReading(text: '', confidence: 0, digitCount: 0);

  /// The reading parsed as a number, or `null` when it holds an
  /// unmatched glyph or is not a valid decimal.
  double? get value {
    if (text.isEmpty || text.contains('?')) return null;
    return double.tryParse(text);
  }

  bool get isEmpty => digitCount == 0;
}
