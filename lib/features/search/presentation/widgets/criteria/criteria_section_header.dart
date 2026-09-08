// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/help/help_dot.dart';
import '../../../../../core/theme/app_text.dart';

/// The criteria sheet's section heading (#3548, promoted to its own file
/// by #3927 so the brand group can label itself the same way as the fuel
/// and amenity groups).
///
/// #3949 (Epic #3947) — the heading is the grammar's **title** role
/// ([AppText.title]): the name of the section, one per group, read
/// before its chips. The old letter-spaced eyebrow was a fifth ad-hoc
/// size; a sheet section names its role now, never its size.
/// #4007 — a section that carries an [anchor] grows a `?` at the end of
/// its heading, which opens the guide at exactly that control. Without
/// one the header is unchanged, so a section is documented when its
/// paragraph is written and not before.
class CriteriaSectionHeader extends StatelessWidget {
  const CriteriaSectionHeader(this.text, {this.anchor, super.key});

  final String text;
  final String? anchor;

  @override
  Widget build(BuildContext context) {
    final title = Text(text, style: AppText.title(context));
    if (anchor case final anchor?) {
      return Row(
        children: [Flexible(child: title), HelpDot(anchor)],
      );
    }
    return title;
  }
}
