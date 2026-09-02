// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails when any [Text] under [within] (or in the whole tree) is
/// ellipsised / clipped: a paragraph that exceeded its `maxLines`, or
/// whose laid-out size is smaller than its text (#3909, Epic #3907 —
/// "never truncates" is a testable property, not a promise).
void expectNoTextTruncates(WidgetTester tester, {Finder? within}) {
  final finder = within == null
      ? find.byType(Text)
      : find.descendant(of: within, matching: find.byType(Text));
  final offenders = <String>[];
  for (final element in finder.evaluate()) {
    final paragraphs = <RenderParagraph>[];
    void visit(RenderObject ro) {
      if (ro is RenderParagraph) paragraphs.add(ro);
      ro.visitChildren(visit);
    }

    final ro = element.renderObject;
    if (ro == null) continue;
    visit(ro);
    final text = (element.widget as Text).data ?? '';
    for (final p in paragraphs) {
      if (!p.hasSize) continue;
      final exceeded = p.didExceedMaxLines;
      final textSize = p.textSize;
      final clipped = p.size.height + 0.5 < textSize.height ||
          p.size.width + 0.5 < textSize.width;
      if (exceeded || clipped) {
        offenders.add('"$text" (maxLines exceeded: $exceeded, '
            'clipped: $clipped, box ${p.size}, text $textSize)');
      }
    }
  }
  expect(offenders, isEmpty,
      reason: 'text truncates instead of wrapping:\n${offenders.join('\n')}');
}
