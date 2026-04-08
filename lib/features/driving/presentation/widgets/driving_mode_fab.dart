import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/app_localizations.dart';
import '../screens/driving_mode_screen.dart';
import 'safety_disclaimer_dialog.dart';

/// Key used to track whether the safety disclaimer has been shown.
const _kDisclaimerAcceptedKey = 'driving_mode_disclaimer_accepted';

/// Floating action button that enters driving mode.
///
/// On first use, shows a safety disclaimer dialog. After the user accepts,
/// navigates to the full-screen [DrivingModeScreen].
class DrivingModeFab extends StatelessWidget {
  const DrivingModeFab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FloatingActionButton(
      heroTag: 'driving_mode_fab',
      onPressed: () => _onPressed(context),
      tooltip: l10n?.drivingMode ?? 'Driving Mode',
      child: const Icon(Icons.drive_eta),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAccepted = prefs.getBool(_kDisclaimerAcceptedKey) ?? false;

    if (!context.mounted) return;

    if (!alreadyAccepted) {
      final accepted = await SafetyDisclaimerDialog.show(context);
      if (!accepted) return;
      await prefs.setBool(_kDisclaimerAcceptedKey, true);
      if (!context.mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DrivingModeScreen(),
      ),
    );
  }
}
