import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/trip_recording_provider.dart';

/// Persistent indicator of an active OBD2 trip (#726). Shown on
/// every screen via `MaterialApp.router.builder` — when the user
/// taps the banner, they're routed back to the trip screen where
/// they can pause or stop.
///
/// The banner is zero-height when no trip is active (the parent's
/// layout stays unaffected), so this widget can safely wrap every
/// screen without regressing any pixel on idle states.
class TripRecordingBanner extends ConsumerWidget {
  final Widget child;

  const TripRecordingBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripRecordingProvider);
    if (!state.isActive) return child;

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.primary,
          elevation: 2,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              key: const Key('tripRecordingBanner'),
              onTap: () => GoRouter.of(context).push('/trip-recording'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: _Content(state: state),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  final TripRecordingState state;

  const _Content({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final live = state.live;
    final distance = live?.distanceKmSoFar;
    final elapsed = live?.elapsed;
    final paused = state.phase == TripRecordingPhase.paused;

    return Row(
      children: [
        Icon(
          paused ? Icons.pause_circle_filled : Icons.fiber_manual_record,
          size: 18,
          color: paused
              ? onPrimary.withValues(alpha: 0.8)
              : Colors.redAccent.shade200,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            paused
                ? (l?.tripBannerPaused ?? 'Trip paused — tap to resume')
                : (l?.tripBannerRecording ?? 'Recording trip'),
            style: TextStyle(color: onPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        if (distance != null)
          Text(
            '${distance.toStringAsFixed(1)} km',
            style: TextStyle(
              color: onPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        const SizedBox(width: 8),
        if (elapsed != null)
          Text(
            _fmtElapsed(elapsed),
            style: TextStyle(
              color: onPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }

  static String _fmtElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}
