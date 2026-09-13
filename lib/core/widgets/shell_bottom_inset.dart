// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Lifts bottom-anchored CONTENT clear of the app's bottom chrome and the
/// system navigation area (#4147).
///
/// Branch bodies draw behind the shell's bottom bar (#4084 / #4096) — the
/// map shows through the docked button's notch, and that is the look the
/// whole app has now. `PageScaffold` states the consequence:
///
/// > The bar's height arrives inside the body as
/// > `MediaQuery.padding.bottom`.
///
/// A map may paint there; it is decoration. A **bar with buttons in it**
/// may not, and the difference is what this widget names. On the route
/// map the summary bar's two actions ended up on top of the Android
/// gesture strip, where a tap competes with system navigation.
///
/// Reaching for `MediaQuery.paddingOf(context).bottom` by hand is what
/// everyone forgets: this is the fourth occurrence of the family after
/// #4119, #4120 and #4121, and an earlier one was a P0 in the field.
///
/// **It cannot double-count.** `padding.bottom` already includes the
/// system inset — the Scaffold adds the bar height ON TOP of it — so this
/// consumes that one value and never adds `viewPadding.bottom` as well.
/// That was the old hand-rolled Trajets Stack bug.
class ShellBottomInset extends StatelessWidget {
  const ShellBottomInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: child,
      );
}
