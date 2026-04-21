import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Row of three side-by-side input shortcut buttons on the Add
/// Fill-up screen — *Scan receipt* (ML Kit text recognition),
/// *Scan pump* (LCD-digit OCR, #598) and *OBD-II* (Bluetooth
/// odometer reading). Each button shows a spinner while the
/// corresponding background task is running.
///
/// The Scan-pump button is only rendered when [onScanPump] is
/// non-null, so the 2-button layout survives on surfaces that
/// don't wire up the pump flow yet.
class FillUpInputButtons extends StatelessWidget {
  final bool scanning;
  final bool scanningPump;
  final bool obdReading;
  final VoidCallback onScanReceipt;
  final VoidCallback? onScanPump;
  final VoidCallback onReadObd;

  const FillUpInputButtons({
    super.key,
    required this.scanning,
    this.scanningPump = false,
    required this.obdReading,
    required this.onScanReceipt,
    this.onScanPump,
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
            label: Text(
              l?.scanReceipt ?? 'Scan receipt',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
        if (onScanPump != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('scan_pump_button'),
              onPressed: scanningPump ? null : onScanPump,
              icon: scanningPump
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.local_gas_station),
              label: Text(
                l?.scanPump ?? 'Scan pump',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
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
            label: Text(
              l?.obdConnect ?? 'OBD-II',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }
}
