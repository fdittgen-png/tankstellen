import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Single "Import from…" chip on the restyled Add-Fill-up form
/// (#751 phase 2).
///
/// Replaces the three top-of-form OutlinedButtons (Scan receipt /
/// Scan pump / OBD-II) with a quieter chip-sized affordance that
/// opens a bottom sheet with the same three options. Keeps the form
/// free of three disabled-looking buttons when nothing has been
/// picked yet and lets each import path carry its own descriptive
/// subtitle.
class FillUpImportFromChip extends StatelessWidget {
  /// True while a scan / OBD-II request is in flight. The chip
  /// swaps its icon for a spinner and disables the tap so the user
  /// cannot open the sheet twice. Tapping an item inside the sheet
  /// is the caller's responsibility to guard — this widget only
  /// reflects the busy state on the entry point.
  final bool busy;

  final VoidCallback onScanReceipt;
  final VoidCallback onScanPump;
  final VoidCallback onReadObd;

  const FillUpImportFromChip({
    super.key,
    required this.onScanReceipt,
    required this.onScanPump,
    required this.onReadObd,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = l?.fillUpImportFromLabel ?? 'Import from…';

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionChip(
        // Tap target is enforced by ActionChip's default 48dp row
        // height — no extra padding tweak needed. We still advertise
        // the intent via a Semantics label so TalkBack reads the
        // purpose instead of just "chip".
        avatar: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined, size: 18),
        label: Text(label),
        tooltip: label,
        onPressed: busy ? null : () => _openSheet(context),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Needed so the sheet can grow to fit the three option tiles +
      // title on phones with a short viewport (the widget-test default
      // 600x800 is particularly tight).
      isScrollControlled: true,
      builder: (sheetContext) => _ImportSheet(
        onScanReceipt: () {
          Navigator.of(sheetContext).pop();
          onScanReceipt();
        },
        onScanPump: () {
          Navigator.of(sheetContext).pop();
          onScanPump();
        },
        onReadObd: () {
          Navigator.of(sheetContext).pop();
          onReadObd();
        },
      ),
    );
  }
}

/// Bottom-sheet body with the three import options.
class _ImportSheet extends StatelessWidget {
  final VoidCallback onScanReceipt;
  final VoidCallback onScanPump;
  final VoidCallback onReadObd;

  const _ImportSheet({
    required this.onScanReceipt,
    required this.onScanPump,
    required this.onReadObd,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          8,
          4,
          8,
          MediaQuery.of(context).viewPadding.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                l?.fillUpImportSheetTitle ?? 'Import fill-up data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _ImportTile(
              key: const Key('import_receipt_tile'),
              icon: Icons.document_scanner_outlined,
              title: l?.fillUpImportReceiptLabel ?? 'Receipt',
              subtitle: l?.fillUpImportReceiptDescription ??
                  'Scan a paper receipt with the camera',
              onTap: onScanReceipt,
            ),
            _ImportTile(
              key: const Key('import_pump_tile'),
              icon: Icons.local_gas_station_outlined,
              title: l?.fillUpImportPumpLabel ?? 'Pump display',
              subtitle: l?.fillUpImportPumpDescription ??
                  'Read Betrag / Preis from the pump LCD',
              onTap: onScanPump,
            ),
            _ImportTile(
              key: const Key('import_obd_tile'),
              icon: Icons.bluetooth,
              title: l?.fillUpImportObdLabel ?? 'OBD-II adapter',
              subtitle: l?.fillUpImportObdDescription ??
                  'Read odometer from the OBD-II port over Bluetooth',
              onTap: onReadObd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      // 56dp minimum ensures the tap target passes the 48dp floor.
      minVerticalPadding: 12,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 24, color: theme.colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
