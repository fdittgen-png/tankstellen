// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../l10n/app_localizations.dart';

/// The search refinements, collapsed until asked for (#4166).
///
/// The criteria form ran about two and a half screens with every section
/// at the same visual weight — a header for Marques looked exactly as
/// important as the fuel selector. The overwhelming majority of searches
/// are fuel plus where; everything here is a refinement most users never
/// touch, and it was costing every user a scroll on every search.
///
/// ## Why the count is the whole design
///
/// Collapsing filters is a trap unless the collapsed state says what is
/// active. A user whose search returns three stations because two
/// amenity filters are on, with nothing on screen to explain it, will
/// conclude the app is broken — and they would be right to. [activeCount]
/// is what makes this safe: the header reads "More filters (2)" and the
/// narrow result has a visible cause.
class CriteriaRefinements extends StatefulWidget {
  const CriteriaRefinements({
    super.key,
    required this.activeCount,
    required this.children,
  });

  /// How many refinements are currently set. Rendered in the header, and
  /// the reason collapsing does not hide anything.
  final int activeCount;

  final List<Widget> children;

  @override
  State<CriteriaRefinements> createState() => _CriteriaRefinementsState();
}

class _CriteriaRefinementsState extends State<CriteriaRefinements> {
  /// Opens itself when something is already on, so a returning user sees
  /// the filters shaping their results rather than a closed drawer.
  late bool _expanded = widget.activeCount > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.criteriaMoreFilters(widget.activeCount),
                    style: AppText.title(context).copyWith(
                      color: widget.activeCount > 0
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        // `hidden` rather than a conditional child: the state of the
        // controls inside survives collapsing, so a user who folds the
        // section away does not silently lose the amenities they picked.
        Offstage(
          offstage: !_expanded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}
