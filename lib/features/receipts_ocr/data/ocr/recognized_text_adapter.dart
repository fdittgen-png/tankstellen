// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'recognized_text_block.dart';

/// Maps ML Kit's [RecognizedText] block/line geometry into the PURE
/// [RecognizedTextBlock] list the label-anchored extractor consumes
/// (#2478).
///
/// This is the thin boundary the issue calls for: it replaces the old
/// `final text = recognized.text;` discard that threw away every box,
/// leaving a flat string in which a bare `PRIX` regex could not tell
/// which number sat under which label.
///
/// We emit one [RecognizedTextBlock] per ML Kit *line* (not just per
/// block) because on a pump readout a single block frequently spans the
/// whole strip — `PRIX 18,59` on one visual row would otherwise fuse the
/// label and its value into one un-anchorable token. Falling to lines
/// keeps each label and each number a separately-anchorable box. Blocks
/// with no lines (rare) fall back to the block box itself.
List<RecognizedTextBlock> mapRecognizedText(RecognizedText recognized) {
  final out = <RecognizedTextBlock>[];
  for (final block in recognized.blocks) {
    if (block.lines.isEmpty) {
      out.add(_fromRect(block.text, block.boundingBox));
      continue;
    }
    for (final line in block.lines) {
      out.add(_fromRect(line.text, line.boundingBox));
    }
  }
  return out;
}

RecognizedTextBlock _fromRect(String text, Rect rect) => RecognizedTextBlock(
      text: text,
      box: OcrBox(
        left: rect.left,
        top: rect.top,
        right: rect.right,
        bottom: rect.bottom,
      ),
    );
