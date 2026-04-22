import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vin_data.dart';

/// Outcome of the [VinConfirmDialog] (#812 phase 2).
enum VinConfirmOutcome {
  /// User accepted the decoded data — caller should auto-fill fields.
  confirm,

  /// User dismissed or chose to modify manually — caller should leave
  /// fields as-is.
  modify,
}

/// Dialog that summarises a decoded VIN and asks the user to accept or
/// reject the auto-fill (#812 phase 2).
///
/// The [VinDataSource.invalid] case is handled by the caller via a
/// snackbar — we assume [data.source] is one of [VinDataSource.vpic]
/// or [VinDataSource.wmiOffline] when this dialog is shown.
class VinConfirmDialog extends StatelessWidget {
  final VinData data;

  const VinConfirmDialog({super.key, required this.data});

  /// Convenience launcher. Returns [VinConfirmOutcome.modify] if the
  /// user dismisses the dialog via the back button or barrier tap.
  static Future<VinConfirmOutcome> show(
    BuildContext context,
    VinData data,
  ) async {
    final outcome = await showDialog<VinConfirmOutcome>(
      context: context,
      builder: (_) => VinConfirmDialog(data: data),
    );
    return outcome ?? VinConfirmOutcome.modify;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isPartial = data.source == VinDataSource.wmiOffline;

    // Build a best-effort summary. Missing pieces are replaced with
    // an em-dash so the line doesn't collapse into "  —  -cyl, " and
    // confuse the user.
    final year = data.modelYear?.toString() ?? '—';
    final make = data.make ?? '—';
    final model = data.model ?? '—';
    final displacement = data.displacementL != null
        ? data.displacementL!.toStringAsFixed(1)
        : '—';
    final cylinders = data.cylinderCount?.toString() ?? '—';
    final fuel = data.fuelTypePrimary ?? '—';

    final body = l?.vinConfirmBody(year, make, model, displacement,
            cylinders, fuel) ??
        '$year $make $model — ${displacement}L, $cylinders-cyl, $fuel';

    return AlertDialog(
      title: Text(l?.vinConfirmTitle ?? 'Is this your car?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body),
          if (isPartial) ...[
            const SizedBox(height: 12),
            Text(
              l?.vinPartialInfoNote ??
                  'Partial info (offline). You can edit below.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(VinConfirmOutcome.modify),
          child: Text(l?.vinModifyAction ?? 'Modify manually'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(VinConfirmOutcome.confirm),
          child: Text(l?.vinConfirmAction ?? 'Yes, auto-fill'),
        ),
      ],
    );
  }
}
