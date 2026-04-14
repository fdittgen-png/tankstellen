import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Row of the two side-by-side input shortcut buttons on the Add Fill-up
/// screen — *Scan receipt* (ML Kit text recognition) and *OBD-II* (Bluetooth
/// odometer reading). Each button shows a spinner while the corresponding
/// background task is running.
///
/// Stateless: the parent screen owns the loading flags and delivers them
/// + the action callbacks via the constructor. Pulled out of
/// `add_fill_up_screen.dart` so the screen's build method drops the
/// 31-line inline button-row markup.
class FillUpInputButtons extends StatelessWidget {
  final bool scanning;
  final bool obdReading;
  final VoidCallback onScanReceipt;
  final VoidCallback onReadObd;

  const FillUpInputButtons({
    super.key,
    required this.scanning,
    required this.obdReading,
    required this.onScanReceipt,
    required this.onReadObd,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: scanning ? null : onScanReceipt,
            icon: scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner),
            label: Text(l?.scanReceipt ?? 'Scan receipt'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: obdReading ? null : onReadObd,
            icon: obdReading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth),
            label: Text(l?.obdConnect ?? 'OBD-II'),
          ),
        ),
      ],
    );
  }
}
