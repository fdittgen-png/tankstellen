import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../domain/cold_start_baselines.dart';

/// The compact Picture-in-Picture tile shown while a trip recording is
/// minimised into a floating window (#1884).
///
/// Deliberately chrome-free and glanceable: it fills the small PiP
/// surface with the live consumption figure on an eco-coach-coloured
/// background, so a single glance tells the driver how they are doing
/// without reading the number. There is no app bar, no buttons —
/// tapping the OS PiP window restores the full recording screen.
class PipTile extends StatelessWidget {
  /// Pre-formatted live consumption, e.g. `'5.4'` — or `'—'` when no
  /// live average is available yet. The unit is rendered separately.
  final String avgText;

  /// Eco-coach band that tints the tile background.
  final ConsumptionBand band;

  /// When true the tile shows a neutral "paused" treatment regardless
  /// of [band] — a stale consumption reading must not look live.
  final bool paused;

  const PipTile({
    super.key,
    required this.avgText,
    required this.band,
    this.paused = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);
    return Material(
      color: palette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              avgText,
              style: TextStyle(
                color: palette.foreground,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              // Unit symbol — language-neutral, same inline mask the
              // recording screen uses for the live-average metric.
              'L/100 km', // i18n-ignore: unit symbol, language-neutral
              style: TextStyle(
                color: palette.foreground.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Background + foreground for the current band. Mirrors the eco-
  /// coach palette of [TripRecordingBanner] so the tile reads as the
  /// same signal the user already knows from the in-app banner.
  _TilePalette _palette(BuildContext context) {
    if (paused) {
      return _TilePalette(
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
        foreground: Theme.of(context).colorScheme.onSurface,
      );
    }
    switch (band) {
      case ConsumptionBand.eco:
        return _TilePalette(
          background: DarkModeColors.success(context),
          foreground: Colors.white,
        );
      case ConsumptionBand.normal:
        return _TilePalette(
          background: Theme.of(context).colorScheme.primary,
          foreground: Theme.of(context).colorScheme.onPrimary,
        );
      case ConsumptionBand.heavy:
        return _TilePalette(
          background: DarkModeColors.warning(context),
          foreground: Colors.black,
        );
      case ConsumptionBand.veryHeavy:
        return _TilePalette(
          background: DarkModeColors.error(context),
          foreground: Colors.white,
        );
      case ConsumptionBand.transient:
        return _TilePalette(
          background: Colors.teal.shade400,
          foreground: Colors.white,
        );
    }
  }
}

class _TilePalette {
  final Color background;
  final Color foreground;
  const _TilePalette({required this.background, required this.foreground});
}
