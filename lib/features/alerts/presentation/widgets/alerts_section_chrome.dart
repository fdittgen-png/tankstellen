// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The Alerts screen's section chrome — headers, per-section empty
/// lines, and the card that groups a section's rows.
///
/// Extracted from `alerts_body.dart` at #4154, which added the
/// Opportunities section and pushed that file past the 400-line norm.
/// A real seam rather than a length dodge: these three are pure layout
/// with no provider reads and no knowledge of which section they frame,
/// while the file they left decides WHAT each section contains.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/section_card.dart';

/// One section's alerts, grouped inside a single rounded card with hairline
/// dividers between rows (#2819). `clipBehavior` keeps each row's
/// swipe-to-delete background inside the card's rounded corners.
class GroupedAlertsCard extends StatelessWidget {
  final List<Widget> children;

  const GroupedAlertsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    // SectionCard (#923) clips to its rounded corners and carries the
    // canonical elevation/outline; padding zero keeps the rows full-bleed
    // so the hairline dividers span edge-to-edge.
    return SectionCard(
      margin: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Compact inline empty row for a section with no alerts yet — far less
/// wasteful than a full-screen [EmptyState] inside a two-section layout.
class SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String text;

  const SectionEmpty({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
        Spacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Spacing.lg),
          Expanded(child: Text(text, style: AppText.label(context))),
        ],
      ),
    );
  }
}

/// A section header: title + count + an add button (#2819). Shared by
/// the Station and Zone sections so both read symmetrically. #3951 — the
/// " (n)" suffix is dropped at zero: a "(0)" is chrome for an absence.
class SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  /// #4154 — the Opportunities section has nothing to ADD: it is a
  /// read-out of what the engine found, not a list the user maintains.
  /// Both are null there and the header renders without the button.
  final String? addTooltip;
  final VoidCallback? onAdd;

  const SectionHeader({
    super.key,
    required this.title,
    this.count = 0,
    this.addTooltip,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.md,
        Spacing.md,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count > 0 ? '$title ($count)' : title,
              style: AppText.title(context),
            ),
          ),
          if (onAdd case final add?)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: addTooltip,
              onPressed: add,
            ),
        ],
      ),
    );
  }
}
