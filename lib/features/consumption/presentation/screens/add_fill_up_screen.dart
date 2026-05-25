// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/discard_changes_dialog.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
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
import '../../domain/fill_up_variance.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/current_obd2_fuel_level_provider.dart';
import '../widgets/add_fill_up_form_fields.dart';
import '../widgets/fill_up_no_vehicle_cta.dart';
import '../widgets/fill_up_pinned_save_bar.dart';
import '../widgets/fill_up_scan_handlers.dart';
import '../widgets/fill_up_variance_prompt.dart';
import 'pump_display_camera_screen.dart';

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

  /// Test seam (#1401 phase 7b) — adapter-captured tank level read
  /// at the moment the pump started. Production callers will populate
  /// this from the live OBD2 producer chain (tracked in a follow-up
  /// to #1401); until that wiring lands the value is always null and
  /// the variance prompt never fires. Tests inject a value to
  /// exercise the dialog flow end-to-end.
  @visibleForTesting
  final double? initialFuelLevelBeforeL;

  /// Test seam (#1401 phase 7b) — adapter-captured tank level read
  /// at pump end. See [initialFuelLevelBeforeL] for context.
  @visibleForTesting
  final double? initialFuelLevelAfterL;

  /// Test seam (#1868) — widget tests swap in a stub returning a
  /// fixture image path instead of launching the in-app
  /// [PumpDisplayCameraScreen]. Production callers leave this null.
  @visibleForTesting
  final Future<String?> Function(BuildContext)? pumpImageCapture;

  const AddFillUpScreen({
    super.key,
    this.stationId,
    this.stationName,
    this.preFilledFuelType,
    this.preFilledPricePerLiter,
    this.scanService,
    this.initialFuelLevelBeforeL,
    this.initialFuelLevelAfterL,
    this.pumpImageCapture,
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
  // #1195 — defaults to ON because the typical European pattern is a
  // full "plein". The toggle exposes the partial-top-up case so the
  // tank-level estimator can branch correctly on subsequent reads.
  bool _isFullTank = true;
  bool _scanning = false;
  bool _scanningPump = false;
  ReceiptScanService? _scanService;
  String? _vehicleId;
  bool _vehicleInitialized = false;
  ReceiptScanOutcome? _lastScan;
  FillUpAutoCostCalculator? _autoCostCalc;

  /// Adapter-captured tank level (litres) snapshotted at form-open
  /// (#1434). Closes the producer-wiring gap from #1401 — paired with
  /// [_fuelLevelAfterL] (captured at save) so the persisted [FillUp]
  /// carries both reads, lighting up the verified-by-adapter badge
  /// (#1430) and the variance prompt when the user-typed liters
  /// disagrees with the adapter delta by >5 %.
  ///
  /// Null when no trip is recording, the adapter doesn't surface
  /// PID 0x2F, or the active vehicle has no tankCapacityL configured.
  /// Test seam [AddFillUpScreen.initialFuelLevelBeforeL] takes
  /// precedence when set, so widget tests can drive the dialog flow
  /// without standing up a live OBD2 stack.
  double? _fuelLevelBeforeL;

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
    // #1434 — snapshot the OBD2 tank level NOW so the persisted FillUp
    // remembers what the adapter saw at form-open. The widget's test
    // seam takes precedence so widget tests can pin a deterministic
    // value without spinning up the trip-recording graph.
    _fuelLevelBeforeL =
        widget.initialFuelLevelBeforeL ?? _readObd2FuelLevelLitres();
  }

  /// One-shot read of the OBD2 fuel-level provider at the current
  /// instant. `ref.read` (not `watch`) — we capture a single snapshot,
  /// not a reactive subscription. Returns null when the provider is
  /// unavailable in the test container or any other read-time failure
  /// (defensive: a missing OBD2 reading must never block save).
  double? _readObd2FuelLevelLitres() {
    try {
      return ref.read(currentObd2FuelLevelLitresProvider);
    } catch (e, st) {
      debugPrint('AddFillUp: OBD2 fuel-level read failed: $e\n$st');
      return null;
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
        capturePumpImage: widget.pumpImageCapture ?? _capturePumpImage,
      );

  /// Pushes the #1868 in-app camera screen and returns the captured
  /// pump-display photo's path (null on cancel / camera unavailable).
  Future<String?> _capturePumpImage(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PumpDisplayCameraScreen()),
    );
  }

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

    final userLiters = AddFillUpValidators.parseDouble(_litersCtrl.text);
    // #1434 — capture the post-fill tank level NOW (form-submit). The
    // before-fill capture happened in initState and lives on the
    // state field. The test seam takes precedence so widget tests can
    // exercise the variance / no-variance flows without a live OBD2
    // chain. Both nulls on a no-OBD2 phone leave the FillUp in the
    // legacy "user-entered only" shape — variance prompt skips itself
    // (FillUpVariance.hasAdapterCapture returns false).
    final afterL =
        widget.initialFuelLevelAfterL ?? _readObd2FuelLevelLitres();
    var fillUp = FillUp(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      liters: userLiters,
      totalCost: AddFillUpValidators.parseDouble(_costCtrl.text),
      odometerKm: AddFillUpValidators.parseDouble(_odoCtrl.text),
      fuelType: _fuelType,
      stationId: widget.stationId,
      stationName: widget.stationName,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      vehicleId: _vehicleId,
      isFullTank: _isFullTank,
      fuelLevelBeforeL: _fuelLevelBeforeL,
      fuelLevelAfterL: afterL,
    );

    // #1401 phase 7b — when both adapter fuel-level captures are
    // present and the user-entered litres differ from the adapter
    // delta by more than 5 %, ask before persisting. Skip the gate
    // entirely when either capture is missing — no baseline, no
    // dialog. Dismissing the dialog is treated as "Keep my entry"
    // (the user's typed value wins).
    if (FillUpVariance.hasAdapterCapture(fillUp)) {
      final adapterDelta = FillUpVariance.adapterDeltaL(fillUp)!;
      if (FillUpVariance.isVarianceAbove5Percent(userLiters, adapterDelta)) {
        final choice = await showFillUpVarianceDialog(
          context: context,
          userL: userLiters.toStringAsFixed(2),
          adapterL: adapterDelta.toStringAsFixed(2),
        );
        if (!mounted) return;
        if (choice == FillUpVarianceChoice.useAdapter) {
          fillUp = fillUp.copyWith(liters: adapterDelta);
        }
      }
    }

    // Capture the root messenger + theme before the screen pops — the
    // success confirmation appears on the surface we return to (#1692).
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final savedMessage = AppLocalizations.of(context)?.fillUpSavedSnackbar ??
        'Fill-up saved';

    await ref.read(fillUpListProvider.notifier).add(fillUp);
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(
      SnackBarHelper.successSnackBar(scheme, savedMessage),
    );
  }

  /// #1693 — true once the user has entered any fill-up data (typed or
  /// receipt-scanned). The form's controllers all start empty, so any
  /// non-empty field means there is unsaved data the discard guard
  /// should protect.
  bool get _isDirty =>
      _litersCtrl.text.isNotEmpty ||
      _costCtrl.text.isNotEmpty ||
      _odoCtrl.text.isNotEmpty ||
      _notesCtrl.text.isNotEmpty;

  /// #1693 — discard guard for a blocked pop (system back / the
  /// leading button via `Navigator.maybePop`). Confirms with the user
  /// before discarding the unsaved fill-up.
  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final discard = await showDiscardChangesDialog(context);
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // #1693 — locale-aware date instead of a raw YYYY-MM-DD string.
    final dateStr = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(_date);
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

    // #1693 — guard unsaved fill-up data. `canPop` blocks the system
    // back gesture and `Navigator.maybePop` (the leading button)
    // whenever the form is dirty; the save path uses an imperative
    // `context.pop()` which is unaffected.
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: PageScaffold(
      title: l?.addFillUp ?? 'Add fill-up',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => Navigator.maybePop(context),
      ),
      bodyPadding: EdgeInsets.zero,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
              isFullTank: _isFullTank,
              onIsFullTankChanged: (v) => setState(() => _isFullTank = v),
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
      ),
    );
  }
}
