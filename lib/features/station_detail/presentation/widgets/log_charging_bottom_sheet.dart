import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../consumption/providers/charging_logs_provider.dart';
import '../../../ev/domain/entities/charging_log.dart';
import '../../../vehicle/providers/vehicle_providers.dart';

/// Modal bottom sheet that captures the parameters of an EV charging
/// session and writes it to [chargingLogsProvider] (#582 phase 2).
///
/// Invoked from the EV station detail screen with the station name
/// pre-filled. Vehicle is pulled from [activeVehicleProfileProvider];
/// when no vehicle is active the form still persists (vehicleId
/// defaults to an empty string so the entry shows up in "all logs"
/// without breaking the per-vehicle filter — the user can edit and
/// reassign later).
///
/// ### Fields
/// - kWh (required, `>= 0`)
/// - Cost in EUR (required, `>= 0`)
/// - Charge time in minutes (optional — defaults to 0, which the
///   entity documents as "unreported")
/// - Odometer in km (optional — defaults to 0 when blank)
/// - Notes (currently captured in `stationName` suffix-style until a
///   dedicated notes field lands on the model; phase 2 keeps the UI
///   surface ready)
class LogChargingBottomSheet extends ConsumerStatefulWidget {
  /// Suggested station name, pre-filled into the form. Editable.
  final String? stationName;

  /// Optional OCM charging station id — carried onto the saved
  /// [ChargingLog] so phase-3 analytics can aggregate by station
  /// without relying on free-form strings.
  final String? chargingStationId;

  const LogChargingBottomSheet({
    super.key,
    this.stationName,
    this.chargingStationId,
  });

  /// Convenience launcher used by the EV station detail screen.
  /// Exposed so a widget test can invoke the same code path the
  /// real button uses — avoids duplicating the `showModalBottomSheet`
  /// call site.
  static Future<ChargingLog?> show(
    BuildContext context, {
    String? stationName,
    String? chargingStationId,
  }) {
    return showModalBottomSheet<ChargingLog>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => LogChargingBottomSheet(
        stationName: stationName,
        chargingStationId: chargingStationId,
      ),
    );
  }

  @override
  ConsumerState<LogChargingBottomSheet> createState() =>
      _LogChargingBottomSheetState();
}

class _LogChargingBottomSheetState
    extends ConsumerState<LogChargingBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stationNameCtrl;
  final _kwhCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stationNameCtrl = TextEditingController(text: widget.stationName ?? '');
  }

  @override
  void dispose() {
    _stationNameCtrl.dispose();
    _kwhCtrl.dispose();
    _costCtrl.dispose();
    _timeCtrl.dispose();
    _odometerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _validateRequiredNumber(String? v, String missingMsg, String badMsg) {
    if (v == null || v.trim().isEmpty) return missingMsg;
    final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return badMsg;
    return null;
  }

  String? _validateOptionalNumber(String? v, String badMsg) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return badMsg;
    return null;
  }

  double _parseDouble(String raw) =>
      double.parse(raw.trim().replaceAll(',', '.'));

  int _parseIntOrZero(String raw) {
    if (raw.trim().isEmpty) return 0;
    final asDouble = double.tryParse(raw.trim().replaceAll(',', '.'));
    return asDouble?.round() ?? 0;
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final active = ref.read(activeVehicleProfileProvider);
    final now = DateTime.now();
    final id = 'cl-${now.microsecondsSinceEpoch}';
    final log = ChargingLog(
      id: id,
      vehicleId: active?.id ?? '',
      date: now,
      kWh: _parseDouble(_kwhCtrl.text),
      costEur: _parseDouble(_costCtrl.text),
      chargeTimeMin: _parseIntOrZero(_timeCtrl.text),
      odometerKm: _parseIntOrZero(_odometerCtrl.text),
      stationName: _stationNameCtrl.text.trim().isEmpty
          ? null
          : _stationNameCtrl.text.trim(),
      chargingStationId: widget.chargingStationId,
    );

    await ref.read(chargingLogsProvider.notifier).add(log);
    if (!mounted) return;
    Navigator.of(context).pop(log);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      // Lift the sheet above the on-screen keyboard so the Save button
      // stays reachable when typing — standard Flutter pattern for
      // input-heavy bottom sheets.
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l?.chargingLogAddTitle ?? 'Log charging',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l?.chargingLogAddSubtitle ?? 'Record this charging session',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('charging_log_station_name'),
                controller: _stationNameCtrl,
                decoration: InputDecoration(
                  labelText: l?.chargingLogStationLabel ?? 'Station',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('charging_log_kwh'),
                controller: _kwhCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l?.chargingLogKwhLabel ?? 'Energy (kWh)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => _validateRequiredNumber(
                  v,
                  l?.chargingLogValidationKwh ?? 'Enter the kWh delivered',
                  l?.chargingLogValidationNumber ?? 'Enter a valid number',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('charging_log_cost'),
                controller: _costCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l?.chargingLogCostLabel ?? 'Cost (EUR)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => _validateRequiredNumber(
                  v,
                  l?.chargingLogValidationCost ?? 'Enter the amount paid',
                  l?.chargingLogValidationNumber ?? 'Enter a valid number',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('charging_log_time'),
                controller: _timeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      l?.chargingLogTimeLabel ?? 'Charge time (minutes)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => _validateOptionalNumber(
                  v,
                  l?.chargingLogValidationNumber ?? 'Enter a valid number',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('charging_log_odometer'),
                controller: _odometerCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      l?.chargingLogOdometerLabel ?? 'Odometer (km)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => _validateOptionalNumber(
                  v,
                  l?.chargingLogValidationNumber ?? 'Enter a valid number',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('charging_log_notes'),
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText:
                      l?.chargingLogNotesLabel ?? 'Notes (optional)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l?.chargingLogCancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('charging_log_save'),
                      onPressed: _saving ? null : _handleSave,
                      child: Text(l?.chargingLogSave ?? 'Save'),
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
}
