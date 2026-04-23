import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/trip_recording_provider.dart';

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
class Obd2PauseBanner extends ConsumerWidget {
  const Obd2PauseBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching only the phase (via select) means unrelated state
    // changes — live readings, band transitions — don't rebuild the
    // banner. The wider TripRecordingBanner already rebuilds on those.
    final phase = ref.watch(
      tripRecordingProvider.select((s) => s.phase),
    );
    if (phase != TripRecordingPhase.pausedDueToDrop) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MaterialBanner(
      key: const Key('obd2PauseBanner'),
      backgroundColor: theme.colorScheme.errorContainer,
      contentTextStyle: TextStyle(
        color: theme.colorScheme.onErrorContainer,
      ),
      leading: Icon(
        Icons.bluetooth_disabled,
        color: theme.colorScheme.onErrorContainer,
      ),
      content: Text(
        l?.obd2PauseBannerTitle ??
            'OBD2 connection lost — recording paused',
      ),
      actions: [
        TextButton(
          key: const Key('obd2PauseBannerResume'),
          onPressed: () =>
              ref.read(tripRecordingProvider.notifier).resume(),
          child: Text(l?.obd2PauseBannerResume ?? 'Resume recording'),
        ),
        TextButton(
          key: const Key('obd2PauseBannerEnd'),
          onPressed: () =>
              ref.read(tripRecordingProvider.notifier).stop(),
          child: Text(l?.obd2PauseBannerEnd ?? 'End recording'),
        ),
      ],
    );
  }
}
