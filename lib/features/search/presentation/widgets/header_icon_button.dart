// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// #3366 — a small primary-tinted icon button used in the search-results
/// header row (list/map view, radar-scope toggle, fuel calculator). Extracted
/// so the three siblings share one definition (and the [AppRadius] token)
/// instead of repeating the Semantics + InkWell + Padding + Icon scaffold.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
