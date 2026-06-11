// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trip_history_repository.dart';
import '../../domain/add_fill_up_validators.dart';
import '../../providers/trip_history_provider.dart';
import 'fill_up_numeric_field.dart';

/// Modal bottom sheet for editing a synthetic reconciliation trajet
/// (#2444). Opens when the user taps a virtual trip row in the Trajets
/// list — the warning-coloured entries the guided reconciliation
/// workflow's Path B injected for unrecorded driving.
///
/// Lets the user adjust the missing distance + fuel, or delete the
/// virtual trip entirely. Preserves `isVirtual: true` across edits so
/// the entry stays distinct and keeps counting on the TRAJETS side of
/// the reconciliation invariant.
class EditVirtualTrajetSheet extends ConsumerStatefulWidget {
  /// The virtual trip to edit. Must have `summary.isVirtual == true` —
  /// the Trajets list only opens this sheet for virtual rows.
  final TripHistoryEntry entry;

  const EditVirtualTrajetSheet({super.key, required this.entry});

  @override
  ConsumerState<EditVirtualTrajetSheet> createState() =>
      _EditVirtualTrajetSheetState();
}

class _EditVirtualTrajetSheetState
    extends ConsumerState<EditVirtualTrajetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _fuelCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.entry.summary;
    _distanceCtrl = TextEditingController(text: _fmt(s.distanceKm));
    _fuelCtrl = TextEditingController(text: _fmt(s.fuelLitersConsumed ?? 0));
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _fuelCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final distance = AddFillUpValidators.parseDouble(_distanceCtrl.text);
    final fuel = AddFillUpValidators.parseDouble(_fuelCtrl.text);
    final updated = widget.entry.copyWith(
      summary: widget.entry.summary.copyWith(
        distanceKm: distance,
        fuelLitersConsumed: fuel,
        avgLPer100Km: distance > 0 ? fuel / distance * 100 : null,
        // Preserve the synthetic flag — editing values does NOT promote
        // the entry to a real trip.
        isVirtual: true,
      ),
    );
    await ref.read(tripHistoryListProvider.notifier).save(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(tripHistoryListProvider.notifier).delete(widget.entry.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final color = DarkModeColors.warning(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_fix_high, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.reconcileVirtualTrajetEditTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.reconcileVirtualTrajetEditExplainer,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FillUpNumericField(
                controller: _distanceCtrl,
                label: l.reconcileWorkflowVirtualDistanceLabel,
                icon: Icons.straighten,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
              const SizedBox(height: 8),
              FillUpNumericField(
                controller: _fuelCtrl,
                label: l.liters,
                icon: Icons.local_drink,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(l.reconcileVirtualTrajetDelete),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(onPressed: _save, child: Text(l.save)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
