import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Bottom bar with 3 oversized buttons for driving mode.
///
/// Buttons: re-center on location, nearest station, exit driving mode.
/// All touch targets are 72dp for safe in-car use.
class DrivingBottomBar extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback onNearestStation;
  final VoidCallback onExit;

  const DrivingBottomBar({
    super.key,
    required this.onRecenter,
    required this.onNearestStation,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DrivingButton(
            icon: Icons.my_location,
            label: l10n?.currentLocation ?? 'Location',
            onTap: onRecenter,
          ),
          _DrivingButton(
            icon: Icons.local_gas_station,
            label: l10n?.drivingNearestStation ?? 'Nearest',
            onTap: onNearestStation,
            isPrimary: true,
          ),
          _DrivingButton(
            icon: Icons.close,
            label: l10n?.drivingExit ?? 'Exit',
            onTap: onExit,
          ),
        ],
      ),
    );
  }
}

class _DrivingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _DrivingButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    final bgColor = isPrimary
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 96,
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
