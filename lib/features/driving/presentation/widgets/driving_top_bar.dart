import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';

/// Top bar of the driving-mode screen — title + active fuel type chip,
/// over a translucent gradient that fades into the map below.
class DrivingTopBar extends StatelessWidget {
  final FuelType selectedFuel;

  const DrivingTopBar({super.key, required this.selectedFuel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: topPadding + 8,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface.withValues(alpha: 0.9),
              theme.colorScheme.surface.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.drive_eta, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n?.drivingMode ?? 'Driving Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedFuel.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
