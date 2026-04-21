import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/fuel_type_dropdown.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/obd2_connection_errors.dart';
import '../../providers/trip_recording_provider.dart';
import '../widgets/obd2_adapter_picker.dart';
import 'trip_recording_screen.dart';
import '../../data/receipt_scan_service.dart';
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import '../widgets/bad_scan_report_sheet.dart';
import '../widgets/fill_up_date_row.dart';
import '../widgets/fill_up_input_buttons.dart';
import '../widgets/fill_up_notes_field.dart';
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
  bool _scanningPump = false;
  bool _obdReading = false;
  ReceiptScanService? _scanService;
  String? _vehicleId;
  bool _vehicleInitialized = false;
  ReceiptScanOutcome? _lastScan;

  @override
  void initState() {
    super.initState();
    final price = widget.preFilledPricePerLiter;
    if (price != null) {
      _litersCtrl.addListener(_recomputeCost);
    }
  }

  /// Resolve the initial vehicle selection: prefer the profile's
  /// [UserProfile.defaultVehicleId], fall back to the active vehicle,
  /// otherwise to the first vehicle in the list (vehicle is mandatory —
  /// #713). Each provider read is wrapped independently so one stray
  /// failure (e.g. active profile missing in tests) doesn't skip the
  /// later fallback branches.
  void _initVehicleIfNeeded(List<VehicleProfile> vehicles) {
    if (_vehicleInitialized) return;
    if (vehicles.isEmpty) {
      _vehicleInitialized = true;
      return;
    }
    String? defaultId;
    FuelType? profilePreferred;
    try {
      final profile = ref.read(activeProfileProvider);
      defaultId = profile?.defaultVehicleId;
      profilePreferred = profile?.preferredFuelType;
    } catch (e) {
      debugPrint('AddFillUp: active profile unavailable: $e');
    }
    String? activeId;
    try {
      activeId = ref.read(activeVehicleProfileProvider)?.id;
    } catch (e) {
      debugPrint('AddFillUp: active vehicle unavailable: $e');
    }
    if (defaultId != null && vehicles.any((v) => v.id == defaultId)) {
      _vehicleId = defaultId;
    } else if (activeId != null && vehicles.any((v) => v.id == activeId)) {
      _vehicleId = activeId;
    } else {
      _vehicleId = vehicles.first.id;
    }
    final selected = vehicles.firstWhere(
      (v) => v.id == _vehicleId,
      orElse: () => vehicles.first,
    );
    _fuelType = _resolveDefaultFuel(
      vehicle: selected,
      profilePreferred: profilePreferred,
      preFill: widget.preFilledFuelType,
    );
    _vehicleInitialized = true;
  }

  /// Default-fuel policy (#713):
  /// 1. preFilledFuelType (from receipt scan / station context) if it
  ///    is compatible with the vehicle
  /// 2. profile's preferredFuelType if compatible — honours "suggest
  ///    by default the one in the profile" for flex-fuel vehicles
  /// 3. vehicle's own preferred fuel as the fallback
  /// 4. FuelType.e10 as the global last-resort default
  FuelType _resolveDefaultFuel({
    required VehicleProfile vehicle,
    FuelType? profilePreferred,
    FuelType? preFill,
  }) {
    final vehicleFuel = _fuelForVehicle(vehicle) ?? FuelType.e10;
    final compatible = compatibleFuelsFor(vehicleFuel);
    if (preFill != null && compatible.contains(preFill)) return preFill;
    if (profilePreferred != null && compatible.contains(profilePreferred)) {
      return profilePreferred;
    }
    return vehicleFuel;
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
      final outcome = await _scanService!.scanReceipt();
      if (outcome == null || !mounted) return;
      final result = outcome.parse;

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
        // Only pre-select the fuel when there is no vehicle bound — the
        // vehicle's configured fuel always wins (#698 single source of
        // truth for fuel).
        if (result.fuelType != null && _vehicleId == null) {
          _fuelType = result.fuelType!;
        }
        _lastScan = outcome;
      });

      if (mounted) {
        SnackBarHelper.show(
          context,
          'Receipt scanned — verify values. Tap "Report scan error" '
              'below if anything is off.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Scan failed: $e');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Tap handler for the OBD-II button. Opens the adapter picker
  /// (#743); on successful connect, pushes the trip-recording
  /// screen (#726) which polls live PIDs, lets the user stop when
  /// done, and returns a [TripSaveResult] that pre-fills the
  /// odometer + litres fields. A null return (user cancelled or
  /// discarded the trip) is a no-op.
  Future<void> _readObd() async {
    setState(() => _obdReading = true);
    final l = AppLocalizations.of(context);
    try {
      final service = await showObd2AdapterPicker(context);
      if (service == null || !mounted) return;
      // #726 — hand the service off to the app-wide recording
      // provider. It survives navigation, so the user can leave
      // this screen (and the entire Consumption tab) and come back
      // later via the banner. The provider disconnects the service
      // for us inside stop().
      await ref.read(tripRecordingProvider.notifier).start(service);
      if (!mounted) return;
      final result = await Navigator.of(context).push<TripSaveResult?>(
        MaterialPageRoute(
          builder: (_) => const TripRecordingScreen(),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        if (result.odometerKm != null) {
          _odoCtrl.text = result.odometerKm!.round().toString();
        }
        if (result.litersConsumed != null) {
          _litersCtrl.text = result.litersConsumed!.toStringAsFixed(2);
        }
      });
      if (result.odometerKm != null) {
        SnackBarHelper.showSuccess(
          context,
          l?.obdOdometerRead(result.odometerKm!.round()) ??
              'Odometer read: ${result.odometerKm!.round()} km',
        );
      } else {
        SnackBarHelper.show(
          context,
          l?.obdOdometerUnavailable ?? 'Could not read odometer',
        );
      }
    } on Obd2ConnectionError catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _obdReading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateStr =
        '${_date.year}-${_pad(_date.month)}-${_pad(_date.day)}';
    // Tolerate providers in error state during widget tests without
    // a real Hive storage — the selector simply hides itself (#694).
    List<VehicleProfile> vehicles;
    try {
      vehicles = ref.watch(vehicleProfileListProvider);
    } catch (e) {
      debugPrint('AddFillUp build: vehicle list unavailable: $e');
      vehicles = const [];
    }
    _initVehicleIfNeeded(vehicles);

    // #706 — consumption requires a vehicle. When none are configured,
    // show an empty-state CTA instead of the full form.
    if (vehicles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l?.addFillUp ?? 'Add fill-up'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l?.tooltipBack ?? 'Back',
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
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
                      'Fill-ups are attributed to a vehicle. Add your car '
                          'to start logging consumption.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/vehicles/edit'),
                  icon: const Icon(Icons.add),
                  label: Text(l?.vehicleAdd ?? 'Add vehicle'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              scanningPump: _scanningPump,
              obdReading: _obdReading,
              onScanReceipt: _scanReceipt,
              onScanPump: _scanPumpDisplay,
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
            FillUpDateRow(dateLabel: dateStr, onTap: _pickDate),
            const SizedBox(height: 8),
            // Vehicle picker (#713). Mandatory — the form is only reachable
            // when at least one vehicle exists (empty-state above). Fuel is
            // ALWAYS derived from the selected vehicle, never picked
            // directly here.
            DropdownButtonFormField<String>(
              initialValue: _vehicleId,
              decoration: InputDecoration(
                labelText: l?.fillUpVehicleLabel ?? 'Vehicle',
                prefixIcon: const Icon(Icons.directions_car_outlined),
              ),
              items: vehicles
                  .map(
                    (v) => DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(v.name),
                    ),
                  )
                  .toList(),
              validator: (v) =>
                  v == null ? (l?.fillUpVehicleRequired ?? 'Required') : null,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _vehicleId = v;
                  final selected = vehicles.firstWhere((x) => x.id == v);
                  final derived = _fuelForVehicle(selected);
                  if (derived != null) _fuelType = derived;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_vehicleId != null) ...[
              _VehicleFuelPicker(
                vehicles: vehicles,
                vehicleId: _vehicleId!,
                fuelType: _fuelType,
                onChanged: (next) => setState(() => _fuelType = next),
                onOpenVehicle: () =>
                    context.push('/vehicles/edit', extra: _vehicleId!),
              ),
              const SizedBox(height: 12),
            ],
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
            FillUpNotesField(controller: _notesCtrl),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(l?.save ?? 'Save'),
            ),
            if (_lastScan != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _reportBadScan,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(l?.reportScanError ?? 'Report scan error'),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// #598 — scan the fuel-pump LCD (Betrag / Abgabe / Preis/Liter) and
  /// pre-fill the form. Unlike the receipt path there is no brand
  /// dispatch — every pump emits the same 3-number format — so we
  /// only need the numeric values and one cross-validity check.
  Future<void> _scanPumpDisplay() async {
    setState(() => _scanningPump = true);
    try {
      _scanService ??= ReceiptScanService();
      final result = await _scanService!.scanPumpDisplay();
      if (result == null || !mounted) return;
      if (!result.hasUsableData) {
        SnackBarHelper.show(context, 'Pump display not readable — try again');
        return;
      }
      setState(() {
        if (result.liters != null) {
          _litersCtrl.text = result.liters!.toStringAsFixed(2);
        }
        if (result.totalCost != null) {
          _costCtrl.text = result.totalCost!.toStringAsFixed(2);
        }
      });
      if (mounted) {
        SnackBarHelper.show(
          context,
          'Pump display scanned — verify the values.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Pump scan failed: $e');
      }
    } finally {
      if (mounted) setState(() => _scanningPump = false);
    }
  }

  Future<void> _reportBadScan() async {
    final scan = _lastScan;
    if (scan == null) return;
    final liters = double.tryParse(_litersCtrl.text.replaceAll(',', '.'));
    final cost = double.tryParse(_costCtrl.text.replaceAll(',', '.'));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BadScanReportSheet(
        scan: scan,
        enteredLiters: liters,
        enteredTotalCost: cost,
        appVersion: AppConstants.appVersion,
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
      vehicleId: _vehicleId,
    );

    await ref.read(fillUpListProvider.notifier).add(fillUp);
    if (!mounted) return;
    context.pop();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// Resolve the vehicle's fuel type (#698). EV → electric; combustion →
  /// the stored preferredFuelType parsed back to the typed enum.
  /// Returns null when the vehicle has no fuel configured.
  FuelType? _fuelForVehicle(VehicleProfile v) {
    if (v.type == VehicleType.ev) return FuelType.electric;
    final raw = v.preferredFuelType;
    if (raw == null || raw.trim().isEmpty) return null;
    return FuelType.fromString(raw);
  }
}

/// Fuel picker constrained to the vehicle's compatible fuels (#713).
///
/// A petrol car gets [e10, e5, e98, e85]; a diesel car gets
/// [diesel, dieselPremium]; EV / LPG / CNG / H₂ vehicles pick from
/// their single applicable fuel only. The initial value is the one
/// resolved by [_AddFillUpScreenState._resolveDefaultFuel] — profile
/// preference when compatible, else the vehicle's own fuel — so the
/// form always loads with the most likely choice but still lets the
/// user override it for this specific fill-up (e.g. a flex-fuel
/// E85 car tanking regular SP95 this week).
class _VehicleFuelPicker extends StatelessWidget {
  final List<VehicleProfile> vehicles;
  final String vehicleId;
  final FuelType fuelType;
  final ValueChanged<FuelType> onChanged;
  final VoidCallback onOpenVehicle;

  const _VehicleFuelPicker({
    required this.vehicles,
    required this.vehicleId,
    required this.fuelType,
    required this.onChanged,
    required this.onOpenVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
    final vehicleFuel = _fuelForVehicleStatic(vehicle) ?? FuelType.e10;
    final compatible = compatibleFuelsFor(vehicleFuel);
    final value =
        compatible.contains(fuelType) ? fuelType : compatible.first;

    return Row(
      children: [
        Expanded(
          child: FuelTypeDropdown(
            value: value,
            options: compatible,
            prefixIcon: const Icon(Icons.local_gas_station),
            labelText: '${l?.fuelType ?? 'Fuel type'} • ${vehicle.name}',
            onChanged: onChanged,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: l?.vehicleEditTitle ?? 'Edit vehicle',
          onPressed: onOpenVehicle,
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Mirror of [_AddFillUpScreenState._fuelForVehicle] — kept static
  /// here so the picker can resolve the vehicle's family without
  /// pulling in a dependency on the parent state.
  static FuelType? _fuelForVehicleStatic(VehicleProfile v) {
    if (v.type == VehicleType.ev) return FuelType.electric;
    final raw = v.preferredFuelType;
    if (raw == null || raw.trim().isEmpty) return null;
    return FuelType.fromString(raw);
  }
}
