// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../../l10n/app_localizations.dart';

/// The ONE inline stage-progress card the trip start / save twins
/// (#2274 / #2548) share: a slowly-rotating + pulsing stage icon, an
/// indeterminate [LinearProgressIndicator], and a stage-driven status
/// label swapped through an [AnimatedSwitcher].
///
/// Indeterminate by design — the flows it fronts are fixed await
/// sequences with no per-item counter, so there is NO determinate %.
///
/// Feature boundary: primitives + callbacks only. Callers keep their
/// own stage enums and map them to [icon] / [label] / [stageKey].
class StagedProgressCard extends StatefulWidget {
  /// Icon for the current stage.
  final IconData icon;

  /// Localized status label for the current stage.
  final String label;

  /// Identity of the current stage — drives the [AnimatedSwitcher]
  /// label crossfade (pass the caller's stage enum value).
  final Object stageKey;

  /// Widget-test handle on the [Card].
  final Key? cardKey;

  /// #2548 — wrap the label in a liveRegion [Semantics] so TalkBack /
  /// VoiceOver announce each stage transition.
  final bool announceStages;

  /// #3335 — when non-null, a "Cancel" affordance is shown so the user
  /// can interrupt a stuck/slow flow. Null hides the button.
  final VoidCallback? onCancel;

  /// Widget-test handle on the Cancel button.
  final Key? cancelKey;

  const StagedProgressCard({
    super.key,
    required this.icon,
    required this.label,
    required this.stageKey,
    this.cardKey,
    this.announceStages = false,
    this.onCancel,
    this.cancelKey,
  });

  @override
  State<StagedProgressCard> createState() => _StagedProgressCardState();
}

class _StagedProgressCardState extends State<StagedProgressCard>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labelText = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        widget.label,
        key: ValueKey(widget.stageKey),
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
    return Card(
      key: widget.cardKey,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.1).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: RotationTransition(
                    turns: _spin,
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // #2548 — a liveRegion so assistive tech announces
                  // each stage transition as the flow progresses.
                  child: widget.announceStages
                      ? Semantics(liveRegion: true, child: labelText)
                      : labelText,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppRadius.md,
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.15),
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            // #3335 — escape hatch for a stuck / slow flow.
            if (widget.onCancel != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: widget.cancelKey,
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                  child: Text(l.cancel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
