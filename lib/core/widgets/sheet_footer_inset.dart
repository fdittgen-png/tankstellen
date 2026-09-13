// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Padding for the action row at the bottom of a modal sheet, including
/// the system navigation inset.
///
/// #4119 — a sheet runs to the PHYSICAL bottom of the screen, so its
/// footer sits behind the Android navigation bar: five field screenshots
/// showed the system back/home targets drawn over a Delete button. A
/// sheet is not a `Scaffold` body, so nothing upstream adds the inset,
/// which is also why this cannot double it (the
/// `feedback_scaffold_inset_doubling` trap).
///
/// A widget rather than three lines inlined per sheet because this is the
/// third time the class of bug has been fixed (see the
/// `shell_chrome_body_behind_bar` note): bodies run behind the chrome,
/// and every surface that opts out of a Scaffold has to add the gap back
/// by hand. One definition means the next sheet gets it right by using
/// it.
class SheetFooterInset extends StatelessWidget {
  const SheetFooterInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: child,
        ),
      );
}
