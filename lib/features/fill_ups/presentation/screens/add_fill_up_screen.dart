// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/country/country_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/discard_changes_dialog.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../../receipts_ocr/api.dart';
import '../../domain/add_fill_up_fuel_resolver.dart';
import '../../domain/add_fill_up_validators.dart';
import '../../domain/add_fill_up_warnings.dart';
import '../../domain/entities/fill_up.dart';
import '../../domain/fill_up_auto_cost_calculator.dart';
import '../../domain/fill_up_variance.dart';
import '../../providers/consumption_providers.dart';
import '../../../obd2/api.dart';
import '../../../vehicle/api.dart'
    show VehicleOdometerSnapshot, VehicleOdometerSource,
        vehicleOdometerSnapshotStoreProvider;
import '../../../../core/time/app_clock.dart';
import '../widgets/add_fill_up_form_fields.dart';
import '../widgets/fill_up_no_vehicle_cta.dart';
import '../widgets/fill_up_paste_receipt_handler.dart';
import '../widgets/fill_up_pinned_save_bar.dart';
import '../widgets/fill_up_reconciliation_launcher.dart';
import '../widgets/fill_up_scan_handlers.dart';
import '../widgets/fill_up_share_scan_handlers.dart';
import '../widgets/fill_up_variance_prompt.dart';
import '../widgets/fill_up_warning_dialog.dart';
import '../widgets/known_station_lookup.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/utils/unit_formatter.dart';

part 'add_fill_up_screen_form_state.dart';
part 'add_fill_up_screen_save.dart';
part 'add_fill_up_screen_scan.dart';

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
  /// [ReceiptScanService] that returns a pre-canned outcome without
  /// launching the camera. Production callers leave this null and the
  /// screen instantiates a real service on first use.
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

  const AddFillUpScreen({
    super.key,
    this.stationId,
    this.stationName,
    this.preFilledFuelType,
    this.preFilledPricePerLiter,
    this.scanService,
    this.initialFuelLevelBeforeL,
    this.initialFuelLevelAfterL,
  });

  @override
  ConsumerState<AddFillUpScreen> createState() => _AddFillUpScreenState();
}

class _AddFillUpScreenState extends ConsumerState<AddFillUpScreen>
    with _AddFillUpFormState, _AddFillUpScanFlow, _AddFillUpSaveFlow {
  @override
  final _formKey = GlobalKey<FormState>();
  @override
  final _litersCtrl = TextEditingController();
  @override
  final _costCtrl = TextEditingController();
  @override
  final _odoCtrl = TextEditingController();
  @override
  final _notesCtrl = TextEditingController();

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
    // #3877 — a user edit of a prefilled odometer drops the "from your
    // car" note (and makes the field count as dirty again).
    _odoCtrl.addListener(() {
      final p = _odometerPrefill;
      if (p != null && _odoCtrl.text != p.text) {
        setState(() => _odometerPrefill = null);
      }
    });
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
    // #3877 — prefill the odometer from the car once the vehicle is known.
    if (!_odometerPrefillScheduled && _vehicleId != null) {
      _odometerPrefillScheduled = true;
      final id = _vehicleId;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_prefillOdometerFromCar(id)));
    }

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
      title: l.addFillUp,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l.tooltipBack,
        onPressed: () => Navigator.maybePop(context),
      ),
      // #3899 — ONE save affordance: the pinned bottom bar. The #3073
      // app-bar check-mark is gone; the keyboard's drag-to-dismiss below
      // still uncovers the bar on iOS.
      bodyPadding: EdgeInsets.zero,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          // #3073 — drag-to-dismiss the keyboard (iOS lacks a system dismiss).
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              onScanReceipt: _scanReceipt,
              onPasteReceipt: _pasteReceiptText,
              stationName: widget.stationName,
              stationAddress: _stationAddress(),
              onChangeStation: _changeStation,
              dateLabel: dateStr,
              onPickDate: _pickDate,
              vehicleId: _vehicleId,
              vehicles: vehicles,
              onVehicleChanged: (id, selected) {
                // #3877 — a different car has a different odometer.
                if (_odometerPrefill != null) {
                  _odoCtrl.clear();
                  _odometerPrefill = null;
                }
                unawaited(_prefillOdometerFromCar(id));
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
                  EditVehicleRoute(vehicleId: _vehicleId!).push<void>(context),
              isFullTank: _isFullTank,
              onIsFullTankChanged: (v) => setState(() => _isFullTank = v),
              litersCtrl: _litersCtrl,
              costCtrl: _costCtrl,
              odoCtrl: _odoCtrl,
              odometerNote: _odometerPrefillNote(l, context), // #3877
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
