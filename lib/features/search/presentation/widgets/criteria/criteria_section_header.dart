// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text.dart';

/// The criteria sheet's section heading (#3548, promoted to its own file
/// by #3927 so the brand group can label itself the same way as the fuel
/// and amenity groups).
///
/// #3949 (Epic #3947) — the heading is the grammar's **title** role
/// ([AppText.title]): the name of the section, one per group, read
/// before its chips. The old letter-spaced eyebrow was a fifth ad-hoc
/// size; a sheet section names its role now, never its size.
class CriteriaSectionHeader extends StatelessWidget {
  const CriteriaSectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.title(context));
  }
}
