// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/country/country_provider.dart';
import '../../../../core/widgets/discard_changes_dialog.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/ocr/pump_ocr_config.dart';
import '../../data/receipt_scan_service.dart';
import '../../domain/add_fill_up_fuel_resolver.dart';
import '../../domain/add_fill_up_validators.dart';
import '../../domain/add_fill_up_warnings.dart';
import '../../domain/entities/fill_up.dart';
import '../../domain/fill_up_auto_cost_calculator.dart';
import '../../domain/fill_up_variance.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/current_obd2_fuel_level_provider.dart';
import '../widgets/add_fill_up_form_fields.dart';
import '../widgets/fill_up_no_vehicle_cta.dart';
import '../widgets/fill_up_paste_receipt_handler.dart';
import '../widgets/fill_up_pinned_save_bar.dart';
import '../widgets/fill_up_reconciliation_launcher.dart';
import '../widgets/fill_up_scan_handlers.dart';
import '../widgets/fill_up_share_scan_handlers.dart';
import '../widgets/fill_up_variance_prompt.dart';
import '../widgets/fill_up_warning_dialog.dart';
import 'pump_display_camera_screen.dart';
import '../../../../core/logging/error_logger.dart';

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

  /// Test seam (#1868 / #2275) — widget tests swap in a stub returning
  /// a fixture [PumpCaptureResult] (path + reticle ROI) instead of
  /// launching the in-app [PumpDisplayCameraScreen]. Production callers
  /// leave this null.
  @visibleForTesting
  final Future<PumpCaptureResult?> Function(BuildContext)? pumpImageCapture;

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
  // #2276 — loaded once on first pump-display scan; drives the guided
  // alignment overlay with the correct orientation + field slots for
  // the active country/brand pump template.
  PumpOcrConfig? _ocrConfig;
  String? _vehicleId;
  bool _vehicleInitialized = false;
  ReceiptScanOutcome? _lastScan;
  FillUpAutoCostCalculator? _autoCostCalc;

  /// Unit price per litre read off the last receipt scan (#2689). Set by
  /// the scan handler when the OCR parser extracts a `pricePerLiter`, and
  /// persisted into the saved [FillUp.scannedPricePerLiter] so the exact
  /// quoted price survives instead of the `totalCost / liters` quotient.
  /// Null until a scan reads a price; manual entries leave it null.
  double? _scannedPricePerLiter;

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
    // #2735/#2838 — when an OS share intent routed the user here, prefill
    // from it after the first frame: image/PDF OCR'd, e-receipt text applied
    // (one helper drains both stashes; lives in the widgets file, #1680).
    scheduleSharedReceiptPrefillIfPending(
      ref,
      context,
      _buildScanHostState,
      () => mounted,
    );
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
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'AddFillUp: OBD2 fuel-level read failed'}));
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
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'AddFillUp: active profile unavailable'}));
    }
    String? activeId;
    try {
      activeId = ref.read(activeVehicleProfileProvider)?.id;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'AddFillUp: active vehicle unavailable'}));
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
    // #2886 — a multi-fuel vehicle re-seeds the picker from the fuel the
    // user actually pumped last tank (when the OCR/station pre-fill
    // doesn't already pin one). Single-fuel vehicles keep the pre-#2886
    // behaviour: `allowAnyCompatible` stays false, so `lastUsedFuel` is
    // never consulted.
    final lastUsed = selected.multiFuelCapable
        ? AddFillUpFuelResolver.lastUsedFuelForVehicle(
            _safeFillUps(),
            vehicleId: selected.id,
          )
        : null;
    _fuelType = AddFillUpFuelResolver.resolveDefaultFuel(
      vehicle: selected,
      profilePreferred: profilePreferred,
      preFill: widget.preFilledFuelType,
      allowAnyCompatible: selected.multiFuelCapable,
      lastUsedFuel: lastUsed,
    );
    _vehicleInitialized = true;
  }

  /// Read the fill-up history defensively (#2886) — a partially-built
  /// test container without Hive must degrade to an empty list rather
  /// than throw while seeding the multi-fuel picker.
  List<FillUp> _safeFillUps() {
    try {
      return ref.read(fillUpListProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'AddFillUp: fill-up history unavailable'}));
      return const [];
    }
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
        setScannedPricePerLiter: (p) =>
            setState(() => _scannedPricePerLiter = p),
        setLastScan: (o) => setState(() => _lastScan = o),
        isMounted: () => mounted,
        capturePumpImage: widget.pumpImageCapture ?? _capturePumpImage,
        // #2275 — the active country drives the per-country validation
        // gate. Brand-template selection (a specific pump make) is a
        // later signal; for now the country-only template is used, so
        // we leave the brand null and let the config fall back. Read
        // defensively: a partially-initialised container (some widget
        // tests) must degrade to "no profile" rather than throw before
        // the scan even runs.
        activeCountry: _activeCountryCode(),
      );

  /// The active country code for OCR validation, or null when it can't
  /// be resolved (so the parser skips range-checking instead of the
  /// screen failing to build the scan host).
  String? _activeCountryCode() {
    try {
      return ref.read(activeCountryProvider).code;
    } catch (_) {
      return null;
    }
  }

  /// Pushes the #1868 in-app camera screen and returns the capture
  /// (photo path + overlay ROI), or null on cancel / camera unavailable.
  ///
  /// #2276 — loads the OCR brand template to seed the guided alignment
  /// overlay with the correct orientation and per-field slot geometry.
  Future<PumpCaptureResult?> _capturePumpImage(BuildContext context) async {
    // Load the OCR config lazily (cached after first load).
    final cfg = _ocrConfig ??= PumpOcrConfig();
    await cfg.load();
    final country = _activeCountryCode();
    final template = country != null
        ? cfg.templateFor(country: country)
        : null;
    if (!context.mounted) return null;
    return Navigator.of(context).push<PumpCaptureResult>(
      MaterialPageRoute(
        builder: (_) => PumpDisplayCameraScreen(
          initialOrientation:
              template?.displayOrientation ?? OcrDisplayOrientation.horizontal,
          fieldSpec: template?.pumpDisplay,
        ),
      ),
    );
  }

  Future<void> _scanReceipt() => runReceiptScan(context, _buildScanHostState());

  Future<void> _scanPumpDisplay() =>
      runPumpDisplayScan(context, _buildScanHostState());

  /// #2687 — the manual, on-device "paste receipt text" entry point.
  /// Opens the paste dialog, parses the pasted text with the pure-Dart
  /// [EReceiptTextParser] (no camera, no cloud) and pre-fills the form
  /// through the SAME body the camera / share paths use. Never auto-saves.
  Future<void> _pasteReceiptText() =>
      runPasteReceiptText(context, _buildScanHostState());

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

    // #2836 — data-quality gate: warn (don't block) when the chosen fuel
    // doesn't match the vehicle's engine family, or the odometer is below
    // the previous fill-up. A dismiss / "Go back" aborts the save.
    if (!await _confirmDataQualityWarnings()) return;
    if (!mounted) return;

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
      // #2689 — persist the receipt-scanned unit price verbatim when one
      // was read; null for manual entries falls back to the computed
      // pricePerLiter getter.
      scannedPricePerLiter: _scannedPricePerLiter,
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

    // Guided reconciliation workflow (Epic #2439 / #2442) — the plein
    // save above may have published a pending gap (recorded trips
    // didn't account for all the pumped fuel). NEVER silent: raise the
    // guided workflow now, before we pop, so the user attributes +
    // resolves the gap. "Decide later" / dismiss leaves the pending
    // gap intact (#2445). Logic lives in the extracted launcher so this
    // save flow stays lean. Mirrors the await-choice-then-route shape
    // of the variance prompt above.
    await runReconciliationWorkflowIfPending(
      context: context,
      ref: ref,
      savedFillUp: fillUp,
    );
    if (!mounted) return;

    context.pop();
    messenger.showSnackBar(
      SnackBarHelper.successSnackBar(scheme, savedMessage),
    );
  }

  /// #2836 — compute the fuel-mismatch / odometer-monotonicity warnings
  /// for the pending entry and, when any fire, confirm with the user.
  /// Returns true when it is OK to proceed (no warnings, or "Save
  /// anyway"); false to abort the save ("Go back and fix" / dismiss).
  Future<bool> _confirmDataQualityWarnings() async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) return true; // no vehicle → no engine to match.
    VehicleProfile? vehicle;
    List<FillUp> allFills = const [];
    try {
      final vehicles = ref.read(vehicleProfileListProvider);
      for (final v in vehicles) {
        if (v.id == vehicleId) vehicle = v;
      }
      allFills = ref.read(fillUpListProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'AddFillUp: warning-gate read failed'}));
      return true; // can't evaluate → don't block the save.
    }
    if (vehicle == null) return true;
    final enteredOdo = AddFillUpValidators.parseDouble(_odoCtrl.text);
    final previousOdo = previousFillUpOdometerKm(
      vehicleId: vehicleId,
      date: _date,
      allFillUps: allFills,
    );
    final warnings = computeFillUpWarnings(
      vehicle: vehicle,
      chosenFuel: _fuelType,
      enteredOdometerKm: enteredOdo,
      previousOdometerKm: previousOdo,
    );
    if (warnings.isEmpty) return true;
    return showFillUpWarningDialog(
      context: context,
      warnings: warnings,
      chosenFuel: _fuelType,
      vehicleFuel: AddFillUpFuelResolver.fuelForVehicle(vehicle),
      enteredOdoKm: enteredOdo.toStringAsFixed(0),
      previousOdoKm: previousOdo?.toStringAsFixed(0),
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
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'AddFillUp build: vehicle list unavailable'}));
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
              onPasteReceipt: _pasteReceiptText,
              stationName: widget.stationName,
              dateLabel: dateStr,
              onPickDate: _pickDate,
              vehicleId: _vehicleId,
              vehicles: vehicles,
              onVehicleChanged: (id, selected) {
                setState(() {
                  _vehicleId = id;
                  if (selected.multiFuelCapable) {
                    // #2886 — seed the picker from the fuel last pumped
                    // for this multi-fuel vehicle, falling back through
                    // the resolver chain when it has no history yet.
                    _fuelType = AddFillUpFuelResolver.resolveDefaultFuel(
                      vehicle: selected,
                      allowAnyCompatible: true,
                      lastUsedFuel:
                          AddFillUpFuelResolver.lastUsedFuelForVehicle(
                        _safeFillUps(),
                        vehicleId: selected.id,
                      ),
                    );
                  } else {
                    final derived =
                        AddFillUpFuelResolver.fuelForVehicle(selected);
                    if (derived != null) _fuelType = derived;
                  }
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
