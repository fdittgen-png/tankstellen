// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../obd2/api.dart';
import '../../providers/trip_recording_provider.dart';

/// #3862 (Epic #3855) — "Engine off for N min — stop recording?"
///
/// A manual recording left running in a parked car used to record GPS
/// forever. Once the engine has been off and the car stationary for
/// [TripRecordingController.parkedPromptAfter], the controller raises
/// `parkedPromptDue` and this pill asks the one question that matters.
/// **Stop** ends and saves the trip; **Keep** dismisses for the rest of
/// the session (some drivers wait in the car on purpose). Auto-record
/// trips never show it — they end themselves on the same condition.
///
/// Floats in the recording banner's overlay Stack like the drop pills
/// (#3545): zero-size when idle, only the pill claims hits.
class ParkedPromptPill extends ConsumerWidget {
  const ParkedPromptPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(tripRecordingProvider.select((s) => s.parkedPromptDue));
    if (!due) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = TripRecordingController.parkedPromptAfter.inMinutes;
    return Semantics(
      liveRegion: true,
      child: Material(
        key: const Key('parkedPromptPill'),
        color: theme.colorScheme.tertiaryContainer,
        elevation: 3,
        borderRadius: AppRadius.xl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_parking_outlined,
                    size: 18,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l.obd2ParkedPromptTitle(minutes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('parkedPromptKeep'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.onTertiaryContainer,
                    ),
                    onPressed: () => ref
                        .read(tripRecordingProvider.notifier)
                        .dismissParkedPrompt(),
                    child: Text(l.obd2ParkedPromptKeep),
                  ),
                  FilledButton.tonal(
                    key: const Key('parkedPromptStop'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        ref.read(tripRecordingProvider.notifier).stop(),
                    child: Text(l.obd2ParkedPromptStop),
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
