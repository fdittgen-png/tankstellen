import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../data/obd2/obd2_service.dart';
import '../../data/obd2/obd2_transport.dart';
import '../../data/receipt_scan_service.dart';
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import '../widgets/fill_up_input_buttons.dart';
import '../widgets/fill_up_numeric_field.dart';

/// Form to add a new [FillUp] entry.
class AddFillUpScreen extends ConsumerStatefulWidget {
  /// Optional pre-fill from a selected station.
  final String? stationId;
  final String? stationName;

  /// Pre-selected fuel type from the station context (e.g. profile fuel type
  /// when opened from a station detail screen). Defaults to [FuelType.e10]
  /// when null.
  final FuelType? preFilledFuelType;

  /// Pre-filled price per liter. When set, the total cost auto-updates as
  /// the user enters liters — turning the common "known-station" fill-up
  /// into a two-tap flow (liters + odometer).
  final double? preFilledPricePerLiter;

  const AddFillUpScreen({
    super.key,
    this.stationId,
    this.stationName,
    this.preFilledFuelType,
    this.preFilledPricePerLiter,
  });

  @override
  ConsumerState<AddFillUpScreen> createState() => _AddFillUpScreenState();
}

class _AddFillUpScreenState extends ConsumerState<AddFillUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _odoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  late FuelType _fuelType = widget.preFilledFuelType ?? FuelType.e10;
  bool _scanning = false;
  bool _obdReading = false;
  ReceiptScanService? _scanService;

  @override
  void initState() {
    super.initState();
    final price = widget.preFilledPricePerLiter;
    if (price != null) {
      _litersCtrl.addListener(_recomputeCost);
    }
  }

  /// Auto-fills the total cost based on the pre-filled price per liter
  /// and the current liters input. Only runs when the user has not manually
  /// typed a cost (empty field) — so we don't clobber a scanned receipt.
  void _recomputeCost() {
    final price = widget.preFilledPricePerLiter;
    if (price == null) return;
    final liters = double.tryParse(_litersCtrl.text.replaceAll(',', '.'));
    if (liters == null || liters <= 0) return;
    final current = double.tryParse(_costCtrl.text.replaceAll(',', '.'));
    // Only overwrite if the user hasn't typed a custom cost. We detect
    // "user-typed" by checking whether the current value matches a prior
    // auto-fill: if the field is empty OR exactly matches the previous
    // auto-computed value, we overwrite.
    final autoCost = (liters * price).toStringAsFixed(2);
    if (_costCtrl.text.isEmpty || current == _lastAutoCost) {
      _costCtrl.text = autoCost;
      _lastAutoCost = double.tryParse(autoCost);
    }
  }

  double? _lastAutoCost;

  @override
  void dispose() {
    _litersCtrl.dispose();
    _costCtrl.dispose();
    _odoCtrl.dispose();
    _notesCtrl.dispose();
    _scanService?.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    setState(() => _scanning = true);
    try {
      _scanService ??= ReceiptScanService();
      final result = await _scanService!.scanReceipt();
      if (result == null || !mounted) return;

      if (!result.hasData) {
        SnackBarHelper.show(context, 'No receipt data found — try again');
        return;
      }

      setState(() {
        if (result.liters != null) {
          _litersCtrl.text = result.liters!.toStringAsFixed(2);
        }
        if (result.totalCost != null) {
          _costCtrl.text = result.totalCost!.toStringAsFixed(2);
        }
        if (result.date != null) {
          _date = result.date!;
        }
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context,
            'Receipt scanned — verify and adjust values');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Scan failed: $e');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _readObd() async {
    setState(() => _obdReading = true);
    try {
      // TODO: Replace FakeObd2Transport with BluetoothObd2Transport
      // when flutter_blue_plus is integrated and tested on real hardware.
      final transport = FakeObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        '01A6': 'NO DATA>',
        '0131': '41 31 4E 20>',
      });
      final service = Obd2Service(transport);
      final connected = await service.connect();
      if (!connected || !mounted) return;

      final km = await service.readOdometerKm();
      await service.disconnect();

      if (km != null && mounted) {
        setState(() {
          _odoCtrl.text = km.round().toString();
        });
        SnackBarHelper.showSuccess(context,
            'Odometer read: ${km.round()} km');
      } else if (mounted) {
        SnackBarHelper.show(context, 'Could not read odometer');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'OBD-II error: $e');
      }
    } finally {
      if (mounted) setState(() => _obdReading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateStr =
        '${_date.year}-${_pad(_date.month)}-${_pad(_date.day)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.addFillUp ?? 'Add fill-up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scan receipt + OBD buttons
            FillUpInputButtons(
              scanning: _scanning,
              obdReading: _obdReading,
              onScanReceipt: _scanReceipt,
              onReadObd: _readObd,
            ),
            const SizedBox(height: 12),
            if (widget.stationName != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(widget.stationName!),
                  subtitle: Text(l?.stationPreFilled ?? 'Station pre-filled'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l?.fillUpDate ?? 'Date'),
              subtitle: Text(dateStr),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<FuelType>(
              initialValue: _fuelType,
              decoration: InputDecoration(
                labelText: l?.fuelType ?? 'Fuel type',
                prefixIcon: const Icon(Icons.local_gas_station),
              ),
              items: FuelType.values
                  .where((f) => f != FuelType.all)
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.apiValue.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _fuelType = v);
              },
            ),
            const SizedBox(height: 12),
            FillUpNumericField(
              controller: _litersCtrl,
              label: l?.liters ?? 'Liters',
              icon: Icons.water_drop_outlined,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            FillUpNumericField(
              controller: _costCtrl,
              label: l?.totalCost ?? 'Total cost',
              icon: Icons.euro,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            FillUpNumericField(
              controller: _odoCtrl,
              label: l?.odometerKm ?? 'Odometer (km)',
              icon: Icons.speed,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: l?.notesOptional ?? 'Notes (optional)',
                prefixIcon: const Icon(Icons.edit_note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(l?.save ?? 'Save'),
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  String? _positiveNumberValidator(String? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l?.fieldRequired ?? 'Required';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return l?.fieldInvalidNumber ?? 'Invalid number';
    }
    return null;
  }

  double _parse(TextEditingController ctrl) =>
      double.parse(ctrl.text.replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fillUp = FillUp(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      liters: _parse(_litersCtrl),
      totalCost: _parse(_costCtrl),
      odometerKm: _parse(_odoCtrl),
      fuelType: _fuelType,
      stationId: widget.stationId,
      stationName: widget.stationName,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await ref.read(fillUpListProvider.notifier).add(fillUp);
    if (!mounted) return;
    context.pop();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
