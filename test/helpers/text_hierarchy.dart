// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The visual grammar's focal-number rule as a testable property (#3950,
/// Epic #3947): the ONE number a card is about must be the largest text on
/// the card, everything else subordinate.
///
/// Sizes are read from each [Text]'s laid-out [RenderParagraph] — its
/// `text.style` is the EFFECTIVE style after the explicit style has been
/// merged over the inherited [DefaultTextStyle], so a `Text` with no style
/// of its own is measured at what it actually rendered, not at null.

/// Effective font size of every [Text] under [within], keyed by the
/// element so duplicates of the same string stay distinct.
Map<Element, double> textFontSizesUnder(WidgetTester tester, Finder within) {
  final sizes = <Element, double>{};
  final texts = find.descendant(of: within, matching: find.byType(Text));
  for (final element in texts.evaluate()) {
    final size = _effectiveFontSize(element);
    if (size != null) sizes[element] = size;
  }
  return sizes;
}

double? _effectiveFontSize(Element textElement) {
  RenderParagraph? paragraph;
  void visit(RenderObject ro) {
    if (paragraph != null) return;
    if (ro is RenderParagraph) {
      paragraph = ro;
      return;
    }
    ro.visitChildren(visit);
  }

  final ro = textElement.renderObject;
  if (ro == null) return null;
  visit(ro);
  return paragraph?.text.style?.fontSize;
}

/// Asserts that the [Text] matched by [focal] renders at a font size
/// STRICTLY larger than every other [Text] under [within] — except the
/// texts matched by [peers], which may tie with it (the other tiles of a
/// stat grid, the other headline values of a table) but never exceed it.
void expectFocalNumberLargest(
  WidgetTester tester, {
  required Finder within,
  required Finder focal,
  Finder? peers,
}) {
  final sizes = textFontSizesUnder(tester, within);
  expect(sizes, isNotEmpty, reason: 'no Text rendered under $within');

  final focalElements = focal.evaluate().toSet();
  expect(focalElements, isNotEmpty, reason: 'focal text $focal not found');
  final focalSize = sizes.entries
      .where((e) => focalElements.contains(e.key))
      .map((e) => e.value)
      .reduce((a, b) => a < b ? a : b);
  final peerElements = peers?.evaluate().toSet() ?? const <Element>{};

  final offenders = <String>[];
  for (final entry in sizes.entries) {
    if (focalElements.contains(entry.key)) continue;
    final text = (entry.key.widget as Text).data ?? '<rich>';
    if (peerElements.contains(entry.key)) {
      if (entry.value > focalSize) {
        offenders.add('"$text" (${entry.value}) exceeds the focal number');
      }
      continue;
    }
    if (entry.value >= focalSize) {
      offenders.add('"$text" (${entry.value}) is not smaller than the '
          'focal number');
    }
  }
  expect(offenders, isEmpty,
      reason: 'the focal number ($focalSize) must be the largest text on '
          'the card:\n${offenders.join('\n')}');
}
