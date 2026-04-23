import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/form_section_card.dart';
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
import '../widgets/fill_up_import_from_chip.dart';
import '../widgets/fill_up_notes_field.dart';
import '../widgets/fill_up_numeric_field.dart';
import '../widgets/fill_up_price_per_liter_readout.dart';
import '../widgets/fill_up_vehicle_dropdown.dart';

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
    final l = AppLocalizations.of(context);
    try {
      _scanService ??= ReceiptScanService();
      final outcome = await _scanService!.scanReceipt();
      if (outcome == null || !mounted) return;
      final result = outcome.parse;

      if (!result.hasData) {
        SnackBarHelper.show(
          context,
          l?.scanReceiptNoData ?? 'No receipt data found — try again',
        );
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
          l?.scanReceiptSuccess ??
              'Receipt scanned — verify values. Tap "Report scan error" '
                  'below if anything is off.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          l?.scanReceiptFailed(e.toString()) ?? 'Scan failed: $e',
        );
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
    final theme = Theme.of(context);
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l?.consumptionNoVehicleTitle ?? 'Add a vehicle first',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l?.consumptionNoVehicleBody ??
                      'Fill-ups are attributed to a vehicle. Add your car '
                          'to start logging consumption.',
                  style: theme.textTheme.bodyMedium,
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

    final importBusy = _scanning || _scanningPump || _obdReading;

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
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            // Extra breathing room before the pinned Save button —
            // keeps the last field clear of the bottom action.
            MediaQuery.of(context).viewPadding.bottom + 96,
          ),
          children: [
            // Quiet "Import from…" chip replacing the three buttons
            // (#751 phase 2). A busy flag on the chip prevents tapping
            // while any import path is already in flight.
            FillUpImportFromChip(
              busy: importBusy,
              onScanReceipt: _scanReceipt,
              onScanPump: _scanPumpDisplay,
              onReadObd: _readObd,
            ),
            const SizedBox(height: 16),
            // Station pre-fill callout — rendered above the cards so
            // it's unmissable when the user opened the form from a
            // station detail screen (#751 phase 2 keeps the original
            // #581 affordance; it simply graduated from a ListTile
            // card to the restyled header band).
            if (widget.stationName != null) ...[
              _StationPreFillBanner(
                stationName: widget.stationName!,
                label: l?.stationPreFilled ?? 'Station pre-filled',
              ),
              const SizedBox(height: 16),
            ],
            // Card 1: "What you filled" — date, fuel, liters, cost.
            FormSectionCard(
              title: l?.fillUpSectionWhatTitle ?? 'What you filled',
              subtitle: l?.fillUpSectionWhatSubtitle ?? 'Fuel, amount, price',
              icon: Icons.local_gas_station_outlined,
              children: [
                FormFieldTile(
                  icon: Icons.calendar_today_outlined,
                  content: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l?.fillUpDate ?? 'Date',
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(dateStr),
                    ),
                  ),
                ),
                FormFieldTile(
                  icon: Icons.directions_car_outlined,
                  content: FillUpVehicleDropdown(
                    vehicleId: _vehicleId,
                    vehicles: vehicles,
                    onChanged: (id, selected) {
                      setState(() {
                        _vehicleId = id;
                        final derived = _fuelForVehicle(selected);
                        if (derived != null) _fuelType = derived;
                      });
                    },
                  ),
                ),
                if (_vehicleId != null)
                  FormFieldTile(
                    icon: Icons.water_drop_outlined,
                    content: _VehicleFuelPicker(
                      vehicles: vehicles,
                      vehicleId: _vehicleId!,
                      fuelType: _fuelType,
                      onChanged: (next) => setState(() => _fuelType = next),
                      onOpenVehicle: () =>
                          context.push('/vehicles/edit', extra: _vehicleId!),
                    ),
                  ),
                FormFieldTile(
                  icon: Icons.opacity_outlined,
                  content: FillUpNumericField(
                    controller: _litersCtrl,
                    label: l?.liters ?? 'Liters',
                    icon: Icons.water_drop_outlined,
                    validator: _positiveNumberValidator,
                  ),
                ),
                FormFieldTile(
                  icon: Icons.euro,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FillUpNumericField(
                        controller: _costCtrl,
                        label: l?.totalCost ?? 'Total cost',
                        icon: Icons.euro,
                        validator: _positiveNumberValidator,
                      ),
                      // Live-derived price/L — #751 §2 bullet 4.
                      FillUpPricePerLiterReadout(
                        litersController: _litersCtrl,
                        costController: _costCtrl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Card 2: "Where you were" — station, odometer, notes.
            FormSectionCard(
              title: l?.fillUpSectionWhereTitle ?? 'Where you were',
              subtitle:
                  l?.fillUpSectionWhereSubtitle ?? 'Station, odometer, notes',
              icon: Icons.place_outlined,
              children: [
                FormFieldTile(
                  icon: Icons.speed_outlined,
                  content: FillUpNumericField(
                    controller: _odoCtrl,
                    label: l?.odometerKm ?? 'Odometer (km)',
                    icon: Icons.speed,
                    validator: _positiveNumberValidator,
                  ),
                ),
                FormFieldTile(
                  icon: Icons.edit_note_outlined,
                  content: FillUpNotesField(controller: _notesCtrl),
                ),
                if (_lastScan != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: _reportBadScan,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(
                        l?.reportScanError ?? 'Report scan error',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PinnedSaveBar(onSave: _save),
    );
  }

  /// #598 — scan the fuel-pump LCD (Betrag / Abgabe / Preis/Liter) and
  /// pre-fill the form. Unlike the receipt path there is no brand
  /// dispatch — every pump emits the same 3-number format — so we
  /// only need the numeric values and one cross-validity check.
  Future<void> _scanPumpDisplay() async {
    setState(() => _scanningPump = true);
    final l = AppLocalizations.of(context);
    try {
      _scanService ??= ReceiptScanService();
      final result = await _scanService!.scanPumpDisplay();
      if (result == null || !mounted) return;
      if (!result.hasUsableData) {
        SnackBarHelper.show(
          context,
          l?.scanPumpUnreadable ?? 'Pump display not readable — try again',
        );
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
          l?.scanPumpSuccess ?? 'Pump display scanned — verify the values.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          l?.scanPumpFailed(e.toString()) ?? 'Pump scan failed: $e',
        );
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

/// Small banner above the form cards announcing the pre-filled
/// station (#581 affordance restyled for #751 phase 2). Replaces the
/// old ListTile card so the callout is visible above the fold without
/// stealing visual weight from the "What you filled" card.
class _StationPreFillBanner extends StatelessWidget {
  final String stationName;
  final String label;

  const _StationPreFillBanner({
    required this.stationName,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.place_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              container: true,
              label: '$label: $stationName',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      stationName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned bottom Save bar (#751 phase 2). Sits below the scroll view
/// so the CTA is always one tap away regardless of how many cards
/// the user has scrolled past. Respects the system nav-bar inset so
/// it never clips under gesture pills (see
/// `feedback_scaffold_inset_doubling.md`).
class _PinnedSaveBar extends StatelessWidget {
  final VoidCallback onSave;
  const _PinnedSaveBar({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.save_outlined),
            label: Text(l?.save ?? 'Save'),
          ),
        ),
      ),
    );
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
