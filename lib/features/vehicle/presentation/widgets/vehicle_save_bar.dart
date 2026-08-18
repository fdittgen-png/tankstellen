// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/pinned_save_bar.dart';

/// Pinned bottom Save bar on the restyled edit-vehicle form
/// (#751 §3). Thin delegate over the shared [PinnedSaveBar] — the
/// chrome (elevation, M3 surface tier, nav-bar inset handling) lives
/// in core since the fill-up twin proved identical.
class VehicleSaveBar extends StatelessWidget {
  final VoidCallback onSave;
  const VehicleSaveBar({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) =>
      PinnedSaveBar(onSave: onSave, icon: Icons.save);
}
