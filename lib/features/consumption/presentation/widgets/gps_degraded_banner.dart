// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
// `trip_recording_provider.dart` re-exports `TripRecordingPhase`.
import '../../providers/trip_recording_provider.dart';

/// Lightweight banner shown when the OBD2 link drops mid-trip but GPS is
/// still alive (#2565 — the GPS-DEGRADE half of the connection-resilience
/// work).
///
/// Unlike [Obd2PauseBanner], recording NEVER pauses in this state: the
/// trip keeps capturing GPS-only samples (live speed from the GPS latch,
/// a physics-derived L/100 km estimate) while the reconnect scanner tries
/// to re-attach the dongle. So this banner carries NO Resume / End
/// actions — recording continues automatically and the metric cards show
/// genuinely live GPS values. It surfaces only to tell the user WHY the
/// OBD2-derived readings briefly switched to GPS, and clears itself the
/// instant the dongle re-attaches.
///
/// Renders zero-height unless the phase is
/// [TripRecordingPhase.degradedGpsOnly], so it is safe to drop into any
/// layout that always-on renders the trip chrome. The pause banner and
/// this banner are mutually exclusive: the pause banner renders only for
/// [TripRecordingPhase.pausedDueToDrop] (BOTH sources gone), this one
/// only for [TripRecordingPhase.degradedGpsOnly] (OBD2 gone, GPS alive).
class GpsDegradedBanner extends ConsumerWidget {
  const GpsDegradedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching only the phase (via select) means unrelated state changes
    // — live readings, band transitions — don't rebuild the banner.
    final phase = ref.watch(
      tripRecordingProvider.select((s) => s.phase),
    );
    if (phase != TripRecordingPhase.degradedGpsOnly) {
      return const SizedBox.shrink();
    }
    // #2767 — once the reconnect scanner exhausts its active-scan attempts it
    // drops to a passive autoConnect wait (it still periodically re-arms an
    // active scan). The trip keeps recording on GPS regardless, so this is a
    // calmer "we're still waiting" state, not a failure — surface a distinct,
    // less-urgent copy so the user isn't left reading "reconnecting" forever.
    final passiveWaiting = ref.watch(
      tripRecordingProvider.select((s) => s.reconnectPassiveWaiting),
    );

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MaterialBanner(
      key: const Key('gpsDegradedBanner'),
      // A neutral/informational surface (not the error surface the pause
      // banner uses) — the trip is fine, it's just running on GPS.
      backgroundColor: theme.colorScheme.secondaryContainer,
      contentTextStyle: TextStyle(
        color: theme.colorScheme.onSecondaryContainer,
      ),
      leading: Icon(
        // A steady "fix held" glyph for the busy reconnect, a quieter
        // "still listening" glyph once we've dropped to the passive wait.
        passiveWaiting ? Icons.bluetooth_searching : Icons.gps_fixed,
        color: theme.colorScheme.onSecondaryContainer,
      ),
      content: Text(
        passiveWaiting
            ? (l?.obd2GpsDegradedPassiveWaitingBanner ??
                'Recording with GPS — waiting for the OBD2 adapter')
            : (l?.obd2GpsDegradedBannerTitle ??
                'Recording with GPS — OBD2 reconnecting'),
      ),
      // No Resume / End: recording continues automatically. A
      // MaterialBanner requires a non-empty actions list, so a single
      // zero-size placeholder keeps the layout valid without offering a
      // tap target the user must not need.
      actions: const [SizedBox.shrink()],
    );
  }
}
