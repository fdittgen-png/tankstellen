import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Two side-by-side import buttons restored on the Add-Fill-up form
/// (#951). The previous single "Import from…" chip + bottom-sheet was
/// rolled back because the OBD-II tile inside the sheet returned null
/// for the odometer on the user's real hardware (Peugeot 107 + generic
/// ELM327 BLE). Until odometer reading via PID 0xA6 is proven reliable
/// across the supported adapter registry, the OBD-II import path is
/// hidden from the fill-up screen — see `docs/guides/obd2-adapters.md`.
///
/// The full OBD-II trajet flow remains available from the Consumption
/// screen (#888); only this fill-up entry-point is reduced.
///
/// Pulled out of `add_fill_up_screen.dart` (#563 extraction) so the
/// screen file drops well below 300 LOC.
class FillUpImportButtonsPair extends StatelessWidget {
  final bool scanningReceipt;
  final bool scanningPump;
  final VoidCallback onScanReceipt;
  final VoidCallback onScanPumpDisplay;

  const FillUpImportButtonsPair({
    super.key,
    required this.scanningReceipt,
    required this.scanningPump,
    required this.onScanReceipt,
    required this.onScanPumpDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('import_receipt_button'),
            onPressed: scanningReceipt ? null : onScanReceipt,
            icon: scanningReceipt
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner_outlined),
            label: Text(
              l?.fillUpImportReceiptLabel ?? 'Receipt',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('import_pump_button'),
            onPressed: scanningPump ? null : onScanPumpDisplay,
            icon: scanningPump
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.local_gas_station_outlined),
            label: Text(
              l?.fillUpImportPumpLabel ?? 'Pump display',
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
