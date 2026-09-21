// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../widgets/home_blocks.dart';

/// The home surface (#4137) — "what can Sparkilo do for me right now?"
///
/// Home today is the search screen: a good search screen, and the wrong
/// front door, because it asks the user to start a task before telling
/// them anything. This composes what the app already knows.
///
/// ## Not a shell branch, deliberately
///
/// #4137 describes "a landing surface above the existing branches", but
/// `shell_destinations.dart` pins router-branch indices BY NAME because
/// deep links route to them, and #4143 — which owns the tab question —
/// says "do this LAST" precisely because the other children are still
/// stabilising those surfaces. So this ships as a screen plus its
/// blocks; whether it becomes a tab, and what happens to FIND, stays
/// #4143's decision with #4137 in hand.
///
/// ## Every block can be absent
///
/// Blocks render only when they have something true to say, so a
/// first-run home is short rather than four empty cards (#4137's own
/// non-negotiable). That means this screen can legitimately be nearly
/// empty on a fresh install — which is why it is not yet the front door.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      children: const [
        HomeNextStopBlock(),
        SizedBox(height: Spacing.md),
        HomeVehicleBlock(),
        SizedBox(height: Spacing.md),
        HomeSavingsBlock(),
      ],
    );
  }
}
