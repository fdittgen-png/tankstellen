// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/pinned_save_bar.dart';

/// Pinned bottom Save bar (#751 phase 2) on the Add fill-up screen.
/// Thin delegate over the shared [PinnedSaveBar] — the chrome
/// (elevation, M3 surface tier, nav-bar inset handling) lives in core
/// since the vehicle twin proved identical.
///
/// Pulled out of `add_fill_up_screen.dart` (#563 extraction) so the
/// screen file drops well below 300 LOC.
class FillUpPinnedSaveBar extends StatelessWidget {
  final VoidCallback onSave;

  const FillUpPinnedSaveBar({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) =>
      PinnedSaveBar(onSave: onSave, icon: Icons.save_outlined);
}
