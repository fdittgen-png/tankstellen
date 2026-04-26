import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/receipt_scan_service.dart';
import '../../domain/add_fill_up_fuel_resolver.dart';
import '../../domain/add_fill_up_validators.dart';
import '../../domain/entities/fill_up.dart';
import '../../domain/fill_up_auto_cost_calculator.dart';
import '../../providers/consumption_providers.dart';
import '../widgets/add_fill_up_form_fields.dart';
import '../widgets/fill_up_no_vehicle_cta.dart';
import '../widgets/fill_up_pinned_save_bar.dart';
import '../widgets/fill_up_scan_handlers.dart';

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

  /// Test seam (#953) — widget tests can swap in a fake
  /// [ReceiptScanService] that returns a pre-canned failing
  /// pump-display outcome without launching the camera. Production
  /// callers leave this null and the screen instantiates a real
  /// service on first use.
  @visibleForTesting
  final ReceiptScanService? scanService;

  const AddFillUpScreen({
    super.key,
    this.stationId,
    this.stationName,
    this.preFilledFuelType,
    this.preFilledPricePerLiter,
    this.scanService,
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
  ReceiptScanService? _scanService;
  String? _vehicleId;
  bool _vehicleInitialized = false;
  ReceiptScanOutcome? _lastScan;
  FillUpAutoCostCalculator? _autoCostCalc;

  @override
  void initState() {
    super.initState();
    final price = widget.preFilledPricePerLiter;
    if (price != null) {
      _autoCostCalc = FillUpAutoCostCalculator(pricePerLiter: price);
      _litersCtrl.addListener(_recomputeCost);
    }
    // #953 — accept an injected scan service so widget tests can drive
    // the failure flow without touching the platform camera channel.
    _scanService = widget.scanService;
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
    } catch (e, st) {
      debugPrint('AddFillUp: active profile unavailable: $e\n$st');
    }
    String? activeId;
    try {
      activeId = ref.read(activeVehicleProfileProvider)?.id;
    } catch (e, st) {
      debugPrint('AddFillUp: active vehicle unavailable: $e\n$st');
    }
    _vehicleId = AddFillUpFuelResolver.pickInitialVehicleId(
      vehicles: vehicles,
      profileDefaultId: defaultId,
      activeVehicleId: activeId,
    );
    final selected = vehicles.firstWhere(
      (v) => v.id == _vehicleId,
      orElse: () => vehicles.first,
    );
    _fuelType = AddFillUpFuelResolver.resolveDefaultFuel(
      vehicle: selected,
      profilePreferred: profilePreferred,
      preFill: widget.preFilledFuelType,
    );
    _vehicleInitialized = true;
  }

  /// Listener bridging the liters controller to the auto-cost
  /// calculator (extracted to `fill_up_auto_cost_calculator.dart`).
  void _recomputeCost() {
    final next = _autoCostCalc?.recompute(
      litersText: _litersCtrl.text,
      costText: _costCtrl.text,
    );
    if (next != null) _costCtrl.text = next;
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _costCtrl.dispose();
    _odoCtrl.dispose();
    _notesCtrl.dispose();
    // Only dispose the service when WE created it (#953). When the
    // test passes one in via `widget.scanService` the fake's lifecycle
    // is owned by the test, not the screen.
    if (widget.scanService == null) {
      _scanService?.dispose();
    }
    super.dispose();
  }

  /// Bridge to the scan helpers in `fill_up_scan_handlers.dart`.
  /// Bundles the controllers + per-field setters the helpers need so
  /// the long async sequences live outside the screen file.
  FillUpScanHostState _buildScanHostState() => FillUpScanHostState(
        litersCtrl: _litersCtrl,
        costCtrl: _costCtrl,
        vehicleId: _vehicleId,
        readService: () => _scanService,
        writeService: (s) => _scanService = s,
        setScanning: (v) => setState(() => _scanning = v),
        setScanningPump: (v) => setState(() => _scanningPump = v),
        setDate: (d) => setState(() => _date = d),
        setFuelType: (f) => setState(() => _fuelType = f),
        setLastScan: (o) => setState(() => _lastScan = o),
        isMounted: () => mounted,
      );

  Future<void> _scanReceipt() => runReceiptScan(context, _buildScanHostState());

  Future<void> _scanPumpDisplay() =>
      runPumpDisplayScan(context, _buildScanHostState());

  Future<void> _reportBadScan() async {
    final scan = _lastScan;
    if (scan == null) return;
    return reportBadReceiptScan(context, _buildScanHostState(), scan);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fillUp = FillUp(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      liters: AddFillUpValidators.parseDouble(_litersCtrl.text),
      totalCost: AddFillUpValidators.parseDouble(_costCtrl.text),
      odometerKm: AddFillUpValidators.parseDouble(_odoCtrl.text),
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
    } catch (e, st) {
      debugPrint('AddFillUp build: vehicle list unavailable: $e\n$st');
      vehicles = const [];
    }
    _initVehicleIfNeeded(vehicles);

    // #706 — consumption requires a vehicle. When none are configured,
    // show an empty-state CTA instead of the full form.
    if (vehicles.isEmpty) {
      return const FillUpNoVehicleCta();
    }

    return PageScaffold(
      title: l?.addFillUp ?? 'Add fill-up',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      bodyPadding: EdgeInsets.zero,
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
            AddFillUpFormFields(
              scanningReceipt: _scanning,
              scanningPump: _scanningPump,
              onScanReceipt: _scanReceipt,
              onScanPumpDisplay: _scanPumpDisplay,
              stationName: widget.stationName,
              dateLabel: dateStr,
              onPickDate: _pickDate,
              vehicleId: _vehicleId,
              vehicles: vehicles,
              onVehicleChanged: (id, selected) {
                setState(() {
                  _vehicleId = id;
                  final derived =
                      AddFillUpFuelResolver.fuelForVehicle(selected);
                  if (derived != null) _fuelType = derived;
                });
              },
              fuelType: _fuelType,
              onFuelChanged: (next) => setState(() => _fuelType = next),
              onOpenVehicle: () =>
                  context.push('/vehicles/edit', extra: _vehicleId!),
              litersCtrl: _litersCtrl,
              costCtrl: _costCtrl,
              odoCtrl: _odoCtrl,
              notesCtrl: _notesCtrl,
              onReportBadScan: _lastScan != null ? _reportBadScan : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: FillUpPinnedSaveBar(onSave: _save),
    );
  }
}
