import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Form to add a new [FillUp] entry.
class AddFillUpScreen extends ConsumerStatefulWidget {
  /// Optional pre-fill from a selected station.
  final String? stationId;
  final String? stationName;

  const AddFillUpScreen({super.key, this.stationId, this.stationName});

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
  FuelType _fuelType = FuelType.e10;
  bool _scanning = false;
  bool _obdReading = false;
  ReceiptScanService? _scanService;

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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanning ? null : _scanReceipt,
                    icon: _scanning
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
                    onPressed: _obdReading ? null : _readObd,
                    icon: _obdReading
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
            TextFormField(
              controller: _litersCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l?.liters ?? 'Liters',
                prefixIcon: const Icon(Icons.water_drop_outlined),
              ),
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l?.totalCost ?? 'Total cost',
                prefixIcon: const Icon(Icons.euro),
              ),
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _odoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l?.odometerKm ?? 'Odometer (km)',
                prefixIcon: const Icon(Icons.speed),
              ),
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
