// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/trip_verdict.dart';
import '../../providers/trip_history_provider.dart';

/// The 3-tap post-trip verdict prompt (#3501, epic #3498).
///
/// Replaces the export-comment hand-loop ("YOUR VERDICT HERE → smooth /
/// moderate / aggressive") with an in-app affordance: one question, three
/// chips, a "Not now" dismissal. The answer is persisted on the trip entry
/// (`TripHistoryEntry.verdict`) — the #3503 calibration store joins it with
/// the trip's energy KPIs so the analysis thresholds can be tuned against
/// how trips actually FELT.
///
/// Self-hiding: renders nothing once the entry carries ANY verdict
/// (including `skipped`, so a dismissal never nags twice for the same
/// trip). After a tap it swaps to a brief thanks line for the current
/// build only — the persisted verdict hides it on the next visit.
class TripVerdictPromptCard extends ConsumerStatefulWidget {
  final String entryId;

  /// The persisted verdict, or null while unanswered (the only state that
  /// shows the prompt).
  final String? verdict;

  const TripVerdictPromptCard({
    super.key,
    required this.entryId,
    required this.verdict,
  });

  @override
  ConsumerState<TripVerdictPromptCard> createState() =>
      _TripVerdictPromptCardState();
}

class _TripVerdictPromptCardState extends ConsumerState<TripVerdictPromptCard> {
  /// Set the moment the user answers, so the card thanks them in place
  /// without waiting for the provider refresh round-trip.
  TripVerdict? _answered;

  Future<void> _submit(TripVerdict verdict) async {
    setState(() => _answered = verdict);
    await ref
        .read(tripHistoryListProvider.notifier)
        .setVerdict(widget.entryId, verdict);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verdict != null && _answered == null) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final answered = _answered;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: answered != null && answered != TripVerdict.skipped
            ? Row(
                key: const Key('tripVerdictThanks'),
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.tripVerdictThanks,
                        style: theme.textTheme.bodyMedium),
                  ),
                ],
              )
            : answered == TripVerdict.skipped
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(l.tripVerdictPromptTitle,
                                style: theme.textTheme.titleSmall),
                          ),
                          IconButton(
                            key: const Key('tripVerdictDismiss'),
                            tooltip: l.tripVerdictDismiss,
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _submit(TripVerdict.skipped),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            key: const Key('tripVerdictSmooth'),
                            avatar: const Icon(Icons.spa_outlined, size: 18),
                            label: Text(l.tripVerdictSmooth),
                            onPressed: () => _submit(TripVerdict.smooth),
                          ),
                          ActionChip(
                            key: const Key('tripVerdictModerate'),
                            avatar: const Icon(Icons.commute_outlined,
                                size: 18),
                            label: Text(l.tripVerdictModerate),
                            onPressed: () => _submit(TripVerdict.moderate),
                          ),
                          ActionChip(
                            key: const Key('tripVerdictAggressive'),
                            avatar:
                                const Icon(Icons.bolt_outlined, size: 18),
                            label: Text(l.tripVerdictAggressive),
                            onPressed: () => _submit(TripVerdict.aggressive),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
