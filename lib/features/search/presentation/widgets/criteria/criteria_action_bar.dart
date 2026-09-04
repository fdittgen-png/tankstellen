// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../l10n/app_localizations.dart';

/// The criteria sheet's sticky bottom action bar (#3927, Epic #3925).
///
/// Until now the sheet's submit was the shell's unlabeled docked search
/// FAB — visually identical to the tab bar's, greyed out with no reason
/// given in route mode — while "Save as my defaults" sat in the form as a
/// full-width outlined button and read as the primary action. This bar
/// makes the real primary action explicit and always reachable:
///
///   * a `FilledButton` labelled **Search** that takes the row's width;
///   * when it is disabled, the one-line reason directly above it
///     (route mode without both endpoints, or a search already running);
///   * a quiet `Reset` text action restoring the saved defaults.
///
/// #3949 (Epic #3947) — Reset sits **beside** Search on one row (text
/// action left, primary button filling the rest), not centred under it:
/// two stacked buttons read as two primary actions of different weight,
/// while a row reads as one primary action with a quiet escape hatch. The
/// row also saves the height of a whole button, which matters on a sheet
/// that already scrolls.
///
/// Chrome mirrors [PinnedSaveBar]: `surfaceContainerHighest` + elevation so
/// the bar lifts off the scrolling form, and a bottom-only `SafeArea` so it
/// never clips under the gesture pill.
class CriteriaActionBar extends StatelessWidget {
  const CriteriaActionBar({
    super.key,
    required this.onSubmit,
    required this.onReset,
    this.disabledReason,
  });

  /// Runs the search with the criteria currently on screen.
  final VoidCallback onSubmit;

  /// Restores the saved defaults (or the factory ones).
  final VoidCallback onReset;

  /// When non-null the submit button is disabled and this line explains
  /// why. Null means the search can run.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reason = disabledReason;

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.md,
            Spacing.xl,
            Spacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reason != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        key: const ValueKey('criteria-disabled-reason'),
                        style: AppText.label(context),
                        // One line for every shipped translation at
                        // 360 dp; the second line is the escape valve
                        // for the en_XA expansion at 320 dp, so the
                        // reason degrades to wrapping rather than to a
                        // truncated half-sentence.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  // The quiet secondary action. Its label ellipsises inside
                  // a loose Flexible so an expanded translation can never
                  // push the primary button off the row; Search keeps the
                  // rest of the width.
                  Flexible(
                    child: TextButton.icon(
                      key: const ValueKey('criteria-reset-button'),
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: Text(
                        l10n.criteriaReset,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: const ValueKey('criteria-submit-button'),
                      onPressed: reason == null ? onSubmit : null,
                      icon: const Icon(Icons.search),
                      label: Text(
                        l10n.criteriaSubmit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
