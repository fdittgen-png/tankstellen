import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_log.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/charging_log_readout.dart';
import '../../domain/charging_log_validators.dart';
import '../../providers/charging_logs_provider.dart';
import '../widgets/charging_log_form_fields.dart';

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
///
/// **#563 refactor** — form layout, validators, and the derived
/// readout were extracted to siblings under `presentation/widgets/`
/// and `domain/`. The screen now owns lifecycle (controllers, state
/// flags, vehicle init, submit) and delegates rendering.
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

  /// Resolve the prior-logs list for the readout. Returns null while
  /// the provider is still loading so the panel hides until data
  /// arrives.
  List<ChargingLog>? _allLogsOrNull() {
    final logsAsync = ref.watch(chargingLogsProvider);
    return logsAsync.hasValue ? logsAsync.value : null;
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
        kWh: ChargingLogValidators.parseDouble(_kwhCtrl.text),
        costEur: ChargingLogValidators.parseDouble(_costCtrl.text),
        chargeTimeMin: ChargingLogValidators.parseInt(_timeMinCtrl.text),
        odometerKm: ChargingLogValidators.parseInt(_odoCtrl.text),
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
    final derived = computeChargingLogReadout(
      vehicleId: _vehicleId,
      kWhText: _kwhCtrl.text,
      costText: _costCtrl.text,
      odometerText: _odoCtrl.text,
      date: _date,
      allLogs: _allLogsOrNull(),
    );

    return PageScaffold(
      title: l?.addChargingLogTitle ?? 'Log charging session',
      bodyPadding: EdgeInsets.zero,
      body: Form(
        key: _formKey,
        child: ChargingLogFormFields(
          dateLabel: dateStr,
          onPickDate: _pickDate,
          vehicleId: _vehicleId,
          vehicles: vehicles,
          onVehicleChanged: (id, _) {
            setState(() => _vehicleId = id);
          },
          kwhCtrl: _kwhCtrl,
          costCtrl: _costCtrl,
          timeMinCtrl: _timeMinCtrl,
          odoCtrl: _odoCtrl,
          stationCtrl: _stationCtrl,
          derived: derived,
          saving: _saving,
          onSave: _save,
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
