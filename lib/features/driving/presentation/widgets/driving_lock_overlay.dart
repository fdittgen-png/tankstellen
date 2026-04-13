import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen translucent overlay shown after the inactivity timeout.
/// Tapping anywhere dismisses the overlay via [onUnlock].
class DrivingLockOverlay extends StatelessWidget {
  final VoidCallback onUnlock;

  const DrivingLockOverlay({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: onUnlock,
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  l10n?.drivingTapToUnlock ?? 'Tap to unlock',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
