// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'add_fill_up_screen.dart';

/// #3762 — the mutable form state + vehicle/fuel seeding helpers of
/// [_AddFillUpScreenState], split out of `add_fill_up_screen.dart` as a
/// `part` mixin to satisfy the #1680 file-length ratchet. Move-only:
/// behaviour preserved verbatim. The mixin owns the mutable scalar form
/// state; the form key + text controllers stay on the State (their
/// lifecycle is `initState`/`dispose`) and are surfaced here as abstract
/// getters that the State's fields satisfy implicitly.
mixin _AddFillUpFormState on ConsumerState<AddFillUpScreen> {
  // ── Infrastructure owned by the State (abstract — the State's fields
  // of the same name satisfy these implicitly). ─────────────────────────
  GlobalKey<FormState> get _formKey;
  TextEditingController get _litersCtrl;
  TextEditingController get _costCtrl;
  TextEditingController get _odoCtrl;
  TextEditingController get _notesCtrl;

  // ── Mutable form state (owned here; `build` + the scan/save flows
  // read and write these). ──────────────────────────────────────────────
  DateTime _date = DateTime.now();
  late FuelType _fuelType = widget.preFilledFuelType ?? FuelType.e10;
  // #1195 — defaults to ON because the typical European pattern is a
  // full "plein". The toggle exposes the partial-top-up case so the
  // tank-level estimator can branch correctly on subsequent reads.
  bool _isFullTank = true;
  bool _scanning = false;
  ReceiptScanService? _scanService;
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

  /// #3877 — the odometer value prefilled from the car (null when nothing
  /// was prefilled or the user edited the field since).
  _OdometerPrefill? _odometerPrefill;
  bool _odometerPrefillScheduled = false;

  /// #3877 — fill the odometer from the car so a receipt scan is enough:
  /// a bounded live read over the kept-alive link when the ignition is
  /// on and the form's vehicle is the adapter's vehicle, else the
  /// per-vehicle snapshot the last recording left (a reading, or reading +
  /// distance driven since). Never overwrites a user-typed value.
  ///
  /// #3899 — the latest KNOWN odometer is the max of the car's reading
  /// and the vehicle's last fill-up: with no (fresh) car reading the last
  /// plein's km is prefilled, and a car reading below it is superseded by
  /// it (the old rule "never below the previous fill-up" now falls back
  /// instead of leaving the field empty).
  Future<void> _prefillOdometerFromCar(String? vehicleId) async {
    if (vehicleId == null || _odoCtrl.text.isNotEmpty) return;
    final now = _clockNow();
    _OdometerPrefill? candidate;
    final live = await _readLiveOdometerKm(vehicleId);
    if (live != null) {
      candidate = _OdometerPrefill(
          km: live, at: now, source: VehicleOdometerSource.obd2, live: true);
    } else {
      final snap = _readOdometerSnapshot(vehicleId);
      if (snap != null && now.difference(snap.at) <= const Duration(days: 14)) {
        candidate = _OdometerPrefill(
            km: snap.km, at: snap.at, source: snap.source, live: false);
      }
    }
    if (!mounted) return;
    final previous = previousFillUpOdometerKm(
        vehicleId: vehicleId, date: _date, allFillUps: _safeFillUps());
    if (previous != null && (candidate == null || candidate.km < previous)) {
      candidate =
          _OdometerPrefill(km: previous, at: now, source: null, live: false);
    }
    if (candidate == null) return;
    if (_odoCtrl.text.isNotEmpty || _vehicleId != vehicleId) return;
    setState(() {
      _odometerPrefill = candidate;
      _odoCtrl.text = candidate!.text;
    });
  }

  /// One bounded PID read on the supervisor's live service — only when the
  /// link is `ready` and the form's vehicle is the active (adapter) one.
  Future<double?> _readLiveOdometerKm(String vehicleId) async {
    try {
      final activeId = ref.read(activeVehicleProfileProvider)?.id;
      if (activeId != vehicleId) return null;
      final sup = ref.read(obd2ReconnectProvider.notifier).supervisor;
      final svc = sup.service;
      if (svc == null || sup.state.value != Obd2LinkState.ready) return null;
      return await svc
          .readOdometerKm()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'AddFillUp: live odometer read failed'}));
      return null;
    }
  }

  VehicleOdometerSnapshot? _readOdometerSnapshot(String vehicleId) {
    try {
      return ref.read(vehicleOdometerSnapshotStoreProvider).read(vehicleId);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'AddFillUp: odometer snapshot read failed'}));
      return null;
    }
  }

  DateTime _clockNow() {
    try {
      return ref.read(appClockProvider).now();
    } catch (_) {
      return _date;
    }
  }

  /// The note rendered under the odometer field, null without a prefill.
  String? _odometerPrefillNote(AppLocalizations l, BuildContext context) {
    final p = _odometerPrefill;
    if (p == null) return null;
    // #3899 — the last plein carries no timestamp worth showing.
    if (p.source == null) return l.fillUpOdometerFromLastFillUp;
    final locale = Localizations.localeOf(context).toString();
    final when = DateFormat.yMMMd(locale).add_Hm().format(p.at);
    if (p.source == VehicleOdometerSource.obd2Estimate) {
      return l.fillUpOdometerEstimatedAt(when);
    }
    final fresh = p.live || _clockNow().difference(p.at) < const Duration(minutes: 1);
    return fresh ? l.fillUpOdometerFromCarJustNow : l.fillUpOdometerFromCarAt(when);
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
}

/// #3877 — what was prefilled into the odometer field and where from.
/// #3899 — a null [source] means the vehicle's last fill-up, not the car.
class _OdometerPrefill {
  const _OdometerPrefill({
    required this.km,
    required this.at,
    required this.source,
    required this.live,
  });
  final double km;
  final DateTime at;
  final VehicleOdometerSource? source;
  final bool live;

  /// Odometers are whole kilometres on every dashboard.
  String get text => km.round().toString();
}
