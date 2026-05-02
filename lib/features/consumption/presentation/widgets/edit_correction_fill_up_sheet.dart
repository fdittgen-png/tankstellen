import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/add_fill_up_validators.dart';
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import 'fill_up_numeric_field.dart';

/// Modal bottom sheet for editing a synthetic correction [FillUp]
/// (#1361 phase 2b). Opens when the user taps a correction card in the
/// fill-up list — the orange auto-fix-high entries created by the
/// trip-vs-pump reconciler.
///
/// The sheet is intentionally separate from `AddFillUpScreen`:
///   * it carries its own "this entry was auto-generated" framing,
///   * it preserves [FillUp.isCorrection] across edits so the entry
///     stays orange after the user adjusts values,
///   * and it offers a delete button that mirrors the swipe-to-dismiss
///     affordance available on every other fill-up card.
///
/// Editing a correction does NOT convert it into a regular fill-up.
/// The reconciler decided this entry was synthetic; the user is only
/// overriding the auto-computed numbers, not promoting the entry.
class EditCorrectionFillUpSheet extends ConsumerStatefulWidget {
  /// The correction fill-up to edit. Must have `isCorrection == true`
  /// — the parent (Fuel tab list builder) only opens the sheet for
  /// correction entries.
  final FillUp fillUp;

  const EditCorrectionFillUpSheet({super.key, required this.fillUp});

  @override
  ConsumerState<EditCorrectionFillUpSheet> createState() =>
      _EditCorrectionFillUpSheetState();
}

class _EditCorrectionFillUpSheetState
    extends ConsumerState<EditCorrectionFillUpSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _litersCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _odoCtrl;
  late final TextEditingController _stationCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final f = widget.fillUp;
    _litersCtrl = TextEditingController(text: _formatNumber(f.liters));
    _costCtrl = TextEditingController(text: _formatNumber(f.totalCost));
    _odoCtrl = TextEditingController(text: _formatNumber(f.odometerKm));
    _stationCtrl = TextEditingController(text: f.stationName ?? '');
    _notesCtrl = TextEditingController(text: f.notes ?? '');
    _date = f.date;
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _costCtrl.dispose();
    _odoCtrl.dispose();
    _stationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Format a double for the text field. Strips a trailing `.0` so
  /// integer-valued totals don't render with a decimal point — keeps
  /// the field tidy for the typical "0 cost" correction case.
  String _formatNumber(double v) {
    if (v == v.truncateToDouble()) {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final station = _stationCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final updated = widget.fillUp.copyWith(
      date: _date,
      liters: AddFillUpValidators.parseDouble(_litersCtrl.text),
      totalCost: AddFillUpValidators.parseDouble(_costCtrl.text),
      odometerKm: AddFillUpValidators.parseDouble(_odoCtrl.text),
      stationName: station.isEmpty ? null : station,
      notes: notes.isEmpty ? null : notes,
      // #1361 — preserve the correction flag. The user is editing the
      // synthetic entry's values; they are NOT promoting it to a real
      // fill-up.
      isCorrection: true,
    );
    await ref.read(fillUpListProvider.notifier).update(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(fillUpListProvider.notifier).remove(widget.fillUp.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final correctionColor = Colors.orange.shade700;
    final dateStr =
        '${_date.year}-${_pad(_date.month)}-${_pad(_date.day)}';

    return Padding(
      // The sheet is summoned with `isScrollControlled: true` so it can
      // grow past the half-screen default; this padding lifts the form
      // above the on-screen keyboard.
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
                  Icon(
                    Icons.auto_fix_high,
                    color: correctionColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l?.fillUpCorrectionEditTitle ?? 'Edit auto-correction',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l?.fillUpCorrectionEditExplainer ??
                    'This entry was auto-generated to close the gap '
                        'between recorded trips and pumped fuel. Adjust '
                        'the values if you know the actual figures.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(l?.fillUpDate ?? 'Date'),
                subtitle: Text(dateStr),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              FillUpNumericField(
                controller: _litersCtrl,
                label: l?.liters ?? 'Liters',
                icon: Icons.local_drink,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
              const SizedBox(height: 8),
              FillUpNumericField(
                controller: _costCtrl,
                label: l?.totalCost ?? 'Total cost',
                icon: Icons.attach_money,
                // Cost may legitimately be 0 for a correction (no
                // receipt, synthesised entry); accept >= 0 here.
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l?.fieldRequired ?? 'Required';
                  }
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) {
                    return l?.fieldInvalidNumber ?? 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              FillUpNumericField(
                controller: _odoCtrl,
                label: l?.odometerKm ?? 'Odometer (km)',
                icon: Icons.speed,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stationCtrl,
                decoration: InputDecoration(
                  labelText:
                      l?.fillUpCorrectionStation ?? 'Station name (optional)',
                  prefixIcon: const Icon(Icons.local_gas_station),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: l?.notesOptional ?? 'Notes (optional)',
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        l?.fillUpCorrectionDelete ?? 'Delete correction',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l?.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(l?.save ?? 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
