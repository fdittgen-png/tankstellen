// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../recovery_message.dart';

/// Renders a [RecoveryMessage] — the one layout every user-facing
/// failure gets (#4141).
///
/// The order is the order the four parts are asked in, and the
/// diagnostic is behind an [ExpansionTile] so a raw exception can never
/// be the first thing a user reads. `whatStillWorks` is given a tinted
/// surface of its own because it is the line that decides whether
/// someone uninstalls, and in every screenshot of the old copy it was
/// the line that was missing.
class RecoveryMessageView extends StatelessWidget {
  const RecoveryMessageView({
    super.key,
    required this.message,
    this.icon,
  });

  final RecoveryMessage message;

  /// Optional leading glyph. The impact already picks a sensible default.
  final IconData? icon;

  IconData get _icon =>
      icon ??
      switch (message.impact) {
        RecoveryImpact.unaffected => Icons.search_off,
        RecoveryImpact.degraded => Icons.cloud_off,
        RecoveryImpact.stopped => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon,
            size: 64,
            color: message.impact == RecoveryImpact.unaffected
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.error),
        const SizedBox(height: 16),
        // 1. What happened.
        Text(message.whatHappened,
            style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        // 2. Why it matters.
        Text(message.whyItMatters, style: muted, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        // 3. Can I continue — the part that was always missing.
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.lg,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(message.whatStillWorks,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 16),
        // 4. What do I do.
        for (final (i, action) in message.actions.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          if (i == 0)
            if (action.icon case final glyph?)
              FilledButton.icon(
                onPressed: action.onInvoke,
                icon: Icon(glyph),
                label: Text(action.label),
              )
            else
              FilledButton(
                  onPressed: action.onInvoke, child: Text(action.label))
          else if (action.icon case final glyph?)
            TextButton.icon(
              onPressed: action.onInvoke,
              icon: Icon(glyph, size: 18),
              label: Text(action.label),
            )
          else
            TextButton(onPressed: action.onInvoke, child: Text(action.label)),
        ],
        if (message.diagnostic.isNotEmpty) ...[
          const SizedBox(height: 12),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(l10n.detailsLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              children: [
                for (final detail in message.diagnostic)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    child: Text(detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        )),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
