import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/charging_cost_calculator.dart';
import '../../../ev/domain/entities/charging_log.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../providers/charging_logs_provider.dart';
import '../widgets/fill_up_date_row.dart';
import '../widgets/fill_up_numeric_field.dart';
import '../widgets/fill_up_vehicle_dropdown.dart';

/// Form to add a new [ChargingLog] entry (#582 phase 2).
///
/// Mirrors the shape of [AddFillUpScreen] — numeric fields, vehicle
/// picker, date row, save action — but persists to
/// [chargingLogsProvider] instead of [fillUpListProvider]. Shares
/// [FillUpNumericField] / [FillUpDateRow] / [FillUpVehicleDropdown]
/// so the visual language stays identical between the fuel and
/// charging flows.
///
/// The EUR/100 km readout below the cost field is best-effort: it
/// computes against the most-recent prior charging log for the
/// selected vehicle (distance = currentOdometer - prevOdometer).
/// When there is no prior log, the readout hides and a small helper
/// line explains why. Phase-3 will upgrade this to the vehicle's
/// consumption baseline when odometer-only anchoring isn't enough.
class AddChargingLogScreen extends ConsumerStatefulWidget {
  /// Optional pre-fill from a selected EV station. Phase 3 wires
  /// this up from the EV-station-detail screen (#691) — this phase
  /// only exposes the plumbing so the form can be reached from the
  /// consumption tab FAB with no station context.
  final String? chargingStationId;
  final String? stationName;

  const AddChargingLogScreen({
    super.key,
    this.chargingStationId,
    this.stationName,
  });

  @override
  ConsumerState<AddChargingLogScreen> createState() =>
      _AddChargingLogScreenState();
}

class _AddChargingLogScreenState extends ConsumerState<AddChargingLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kwhCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _timeMinCtrl = TextEditingController();
  final _odoCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _vehicleId;
  bool _vehicleInitialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.stationName != null) {
      _stationCtrl.text = widget.stationName!;
    }
    // Rebuild the derived EUR/100 km readout as the user types the
    // three fields that feed it.
    _kwhCtrl.addListener(_onDerivedInputsChanged);
    _costCtrl.addListener(_onDerivedInputsChanged);
    _odoCtrl.addListener(_onDerivedInputsChanged);
  }

  @override
  void dispose() {
    _kwhCtrl.dispose();
    _costCtrl.dispose();
    _timeMinCtrl.dispose();
    _odoCtrl.dispose();
    _stationCtrl.dispose();
    super.dispose();
  }

  void _onDerivedInputsChanged() => setState(() {});

  /// Seed the vehicle picker from the active-profile's vehicle or the
  /// first EV-capable vehicle. Falls back to the first vehicle in the
  /// list if no EV exists — the user can still log a session (hybrid
  /// cars can be charged too).
  void _initVehicleIfNeeded(List<VehicleProfile> vehicles) {
    if (_vehicleInitialized) return;
    if (vehicles.isEmpty) {
      _vehicleInitialized = true;
      return;
    }
    String? activeId;
    try {
      activeId = ref.read(activeVehicleProfileProvider)?.id;
    } catch (e, st) {
      debugPrint('AddChargingLog: active vehicle unavailable: $e\n$st');
    }
    final evVehicles =
        vehicles.where((v) => v.isEv).toList(growable: false);
    if (activeId != null &&
        evVehicles.any((v) => v.id == activeId)) {
      _vehicleId = activeId;
    } else if (evVehicles.isNotEmpty) {
      _vehicleId = evVehicles.first.id;
    } else if (activeId != null && vehicles.any((v) => v.id == activeId)) {
      _vehicleId = activeId;
    } else {
      _vehicleId = vehicles.first.id;
    }
    _vehicleInitialized = true;
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

  String? _nonNegativeIntValidator(String? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l?.fieldRequired ?? 'Required';
    }
    final parsed = int.tryParse(value.replaceAll(',', '.').split('.').first);
    if (parsed == null || parsed < 0) {
      return l?.fieldInvalidNumber ?? 'Invalid number';
    }
    return null;
  }

  double _parseDouble(TextEditingController ctrl) =>
      double.parse(ctrl.text.replaceAll(',', '.'));

  int _parseInt(TextEditingController ctrl) => int.parse(
        ctrl.text.replaceAll(',', '.').split('.').first,
      );

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

  /// Compute EUR/100 km for a hypothetical log carrying the form's
  /// current inputs, comparing against the most-recent prior log for
  /// the selected vehicle. Returns null when inputs are incomplete,
  /// unparseable, or there's no prior log to anchor the distance.
  _DerivedReadout? _deriveReadout() {
    if (_vehicleId == null) return null;
    final kWh = double.tryParse(_kwhCtrl.text.replaceAll(',', '.'));
    final cost = double.tryParse(_costCtrl.text.replaceAll(',', '.'));
    final parsedOdo = int.tryParse(
      _odoCtrl.text.replaceAll(',', '.').split('.').first,
    );
    if (kWh == null || kWh <= 0) return null;
    if (cost == null || cost <= 0) return null;
    if (parsedOdo == null || parsedOdo <= 0) return null;
    // Local non-nullable copy — Dart's flow analysis does not promote
    // captured nullable locals inside closures like [firstWhere].
    final int odo = parsedOdo;

    final logsAsync = ref.watch(chargingLogsProvider);
    final all = logsAsync.hasValue ? logsAsync.value : null;
    if (all == null) return null;
    final prior = all
        .where((log) => log.vehicleId == _vehicleId)
        .toList(growable: false);
    if (prior.isEmpty) return const _DerivedReadout.empty();

    // Prior logs are oldest-first; the anchor is the most recent one
    // with odometer < odo (i.e. driven since then).
    final candidate = prior.reversed.firstWhere(
      (log) => log.odometerKm < odo,
      orElse: () => prior.last,
    );
    final int kmDriven = odo - candidate.odometerKm;
    if (kmDriven <= 0) return const _DerivedReadout.empty();

    final preview = ChargingLog(
      id: 'preview',
      vehicleId: _vehicleId!,
      date: _date,
      kWh: kWh,
      costEur: cost,
      chargeTimeMin: 0,
      odometerKm: odo,
    );
    final eurPer100 = ChargingCostCalculator.eurPer100km(
      preview,
      kmDriven: kmDriven,
    );
    final kwhPer100 = ChargingCostCalculator.kWhPer100km(
      preview,
      kmDriven: kmDriven,
    );
    return _DerivedReadout(
      eurPer100km: eurPer100,
      kwhPer100km: kwhPer100,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null) return;
    setState(() => _saving = true);
    try {
      final log = ChargingLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        vehicleId: _vehicleId!,
        date: _date,
        kWh: _parseDouble(_kwhCtrl),
        costEur: _parseDouble(_costCtrl),
        chargeTimeMin: _parseInt(_timeMinCtrl),
        odometerKm: _parseInt(_odoCtrl),
        stationName:
            _stationCtrl.text.trim().isEmpty ? null : _stationCtrl.text.trim(),
        chargingStationId: widget.chargingStationId,
      );
      await ref.read(chargingLogsProvider.notifier).add(log);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('AddChargingLog._save: $e\n$st');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    List<VehicleProfile> vehicles;
    try {
      vehicles = ref.watch(vehicleProfileListProvider);
    } catch (e, st) {
      debugPrint('AddChargingLog build: vehicle list unavailable: $e\n$st');
      vehicles = const [];
    }
    _initVehicleIfNeeded(vehicles);

    if (vehicles.isEmpty) {
      return PageScaffold(
        title: l?.addChargingLogTitle ?? 'Log charging session',
        bodyPadding: const EdgeInsets.all(32),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l?.consumptionNoVehicleTitle ?? 'Add a vehicle first',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l?.consumptionNoVehicleBody ??
                    'Charging sessions are attributed to a vehicle. '
                        'Add your car to start logging.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final dateStr =
        '${_date.year}-${_pad(_date.month)}-${_pad(_date.day)}';
    final derived = _deriveReadout();

    return PageScaffold(
      title: l?.addChargingLogTitle ?? 'Log charging session',
      bodyPadding: EdgeInsets.zero,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FillUpDateRow(dateLabel: dateStr, onTap: _pickDate),
            const SizedBox(height: 8),
            FillUpVehicleDropdown(
              vehicleId: _vehicleId,
              vehicles: vehicles,
              onChanged: (id, _) {
                setState(() => _vehicleId = id);
              },
            ),
            const SizedBox(height: 12),
            FillUpNumericField(
              key: const Key('charging_kwh_field'),
              controller: _kwhCtrl,
              label: l?.chargingKwh ?? 'Energy (kWh)',
              icon: Icons.bolt_outlined,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            FillUpNumericField(
              key: const Key('charging_cost_field'),
              controller: _costCtrl,
              label: l?.chargingCost ?? 'Total cost',
              icon: Icons.euro,
              validator: _positiveNumberValidator,
            ),
            _DerivedReadoutPanel(readout: derived),
            const SizedBox(height: 12),
            FillUpNumericField(
              key: const Key('charging_time_field'),
              controller: _timeMinCtrl,
              label: l?.chargingTimeMin ?? 'Charge time (min)',
              icon: Icons.timer_outlined,
              validator: _nonNegativeIntValidator,
            ),
            const SizedBox(height: 12),
            FillUpNumericField(
              key: const Key('charging_odo_field'),
              controller: _odoCtrl,
              label: l?.odometerKm ?? 'Odometer (km)',
              icon: Icons.speed,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('charging_station_field'),
              controller: _stationCtrl,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                LengthLimitingTextInputFormatter(80),
              ],
              decoration: InputDecoration(
                labelText: l?.chargingStationName ?? 'Station (optional)',
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('charging_save_button'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(l?.save ?? 'Save'),
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
          ],
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Shape returned by [_AddChargingLogScreenState._deriveReadout].
///
/// A null instance means "inputs incomplete" — hide the panel
/// entirely. A [_DerivedReadout.empty] instance means "inputs
/// complete but no prior log to anchor the distance" — render the
/// helper text instead of numbers so the user knows why the
/// readout is blank.
class _DerivedReadout {
  final double? eurPer100km;
  final double? kwhPer100km;

  const _DerivedReadout({
    required this.eurPer100km,
    required this.kwhPer100km,
  });

  const _DerivedReadout.empty()
      : eurPer100km = null,
        kwhPer100km = null;

  bool get hasValues => eurPer100km != null && kwhPer100km != null;
}

class _DerivedReadoutPanel extends StatelessWidget {
  final _DerivedReadout? readout;

  const _DerivedReadoutPanel({required this.readout});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = readout;
    if (r == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
    );
    if (!r.hasValues) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 12),
        child: Text(
          l?.chargingDerivedHelper ?? 'Need a previous log to compare',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          key: const Key('charging_derived_helper'),
        ),
      );
    }
    final eurStr = r.eurPer100km!.toStringAsFixed(2);
    final kwhStr = r.kwhPer100km!.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 12),
      child: Row(
        key: const Key('charging_derived_readout'),
        children: [
          Icon(Icons.insights_outlined,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${l?.chargingEurPer100km(eurStr) ?? '$eurStr EUR / 100 km'}'
              '  •  '
              '${l?.chargingKwhPer100km(kwhStr) ?? '$kwhStr kWh / 100 km'}',
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
