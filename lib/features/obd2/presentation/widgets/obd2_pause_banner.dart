// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/providers/trip_recording_provider.dart';

/// Banner shown when the OBD2 Bluetooth link drops mid-recording
/// (#797 phase 2).
///
/// Phase 1 (#864) persists the partial trip and flips the recording
/// controller to [TripRecordingPhase.pausedDueToDrop]. This banner
/// surfaces that state to the user, with two escape hatches:
///
///   * **Resume recording** — re-enters the recording phase. Intended
///     for when the adapter reconnected on its own (phase 3 will add
///     the auto-reconnect scanner; until then the user initiates).
///   * **End recording** — stops the controller so the captured trip
///     is finalised and saved via the normal fill-up flow.
///
/// The widget renders zero-height unless the phase is
/// [TripRecordingPhase.pausedDueToDrop], so it's safe to drop into
/// any layout that always-on renders the trip chrome.
///
/// #1330 phase 3 — when the drop reason is
/// [TripDropReason.silentFailure] (adapter connected but every PID
/// parse returned null) the banner swaps copy to
/// `tripRecordingObd2NotResponding` so the user knows to try a
/// different adapter rather than wait for a Bluetooth reconnect that
/// never happens.
class Obd2PauseBanner extends ConsumerWidget {
  const Obd2PauseBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching only the phase (via select) means unrelated state
    // changes — live readings, band transitions — don't rebuild the
    // banner. The wider TripRecordingBanner already rebuilds on those.
    final phase = ref.watch(tripRecordingProvider.select((s) => s.phase));
    if (phase != TripRecordingPhase.pausedDueToDrop) {
      return const SizedBox.shrink();
    }
    final dropReason = ref.watch(
      tripRecordingProvider.select((s) => s.dropReason),
    );

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSilentFailure = dropReason == TripDropReason.silentFailure;
    // #3545 — a compact floating pill instead of a full-width
    // MaterialBanner: the widget now lives in an overlay Stack, so it
    // must never claim more width than its content (hits beside it fall
    // through to the screen underneath). liveRegion announces the pause
    // to screen readers, which the ambient overlay placement no longer
    // guarantees by document order.
    return Semantics(
      liveRegion: true,
      child: Material(
        key: const Key('obd2PauseBanner'),
        color: theme.colorScheme.errorContainer,
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
                    isSilentFailure
                        ? Icons.report_gmailerrorred_outlined
                        : Icons.bluetooth_disabled,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isSilentFailure
                          ? (l.tripRecordingObd2NotResponding)
                          : (l.obd2PauseBannerTitle),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
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
                    key: const Key('obd2PauseBannerResume'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    onPressed: () =>
                        ref.read(tripRecordingProvider.notifier).resume(),
                    child: Text(l.obd2PauseBannerResume),
                  ),
                  TextButton(
                    key: const Key('obd2PauseBannerEnd'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    onPressed: () =>
                        ref.read(tripRecordingProvider.notifier).stop(),
                    child: Text(l.obd2PauseBannerEnd),
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
