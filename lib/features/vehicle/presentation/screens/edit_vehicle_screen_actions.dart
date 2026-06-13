// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'edit_vehicle_screen.dart';

/// #3234 — the imperative form actions + the mutable form state extracted out
/// of `_EditVehicleScreenState` as a `part` mixin, so the screen file holds
/// only the widget shell, the load/dispose lifecycle and `build`.
///
/// It is a `part` (not a separate library) so the form fields and methods stay
/// **private** — the State's `build` reads `_type` / `_decodingVin` / … and
/// calls `_save` / `_decodeVin` / … exactly as before, with zero call-site
/// churn. The mixin owns the mutable scalar form state; the five infrastructure
/// members it needs (`_ctrl`, `_formKey`, the OBD2 card key + highlight
/// controller, the scroll controller) stay on the State and are surfaced here
/// as abstract getters that the State's fields satisfy implicitly.
mixin _VehicleEditActions on ConsumerState<EditVehicleScreen> {
  // ── Infrastructure owned by the State (abstract — the State's fields of the
  // same name satisfy these implicitly). ───────────────────────────────────
  VehicleFormControllers get _ctrl;
  GlobalKey<FormState> get _formKey;

  // ── Mutable form state (owned here; `build` + the load path read these). ──

  // #710 — combustion default; user can flip to Hybrid/Electric.
  VehicleType _type = VehicleType.combustion;
  // #2885 — multi-fuel capability flag. Loaded from the profile, surfaced (and
  // toggleable) only when the preferred fuel is E10 / E85.
  bool _multiFuelCapable = false;
  final Set<ConnectorType> _connectors = {};
  String? _existingId;
  String? _adapterMac;
  String? _adapterName;
  // #1328 — flips true after the first successful load so later provider
  // updates (e.g. `_save` writing the freshest profile) don't clobber edits.
  bool _hasInitiallyLoaded = false;

  // #812 phase 2 — engine params populated by the VIN decoder; carried through
  // `_save` for phase-3 OBD2 math.
  int? _engineDisplacementCc;
  int? _engineCylinders;
  int? _curbWeightKg;

  // True while the vPIC request is in flight → VIN field spinner.
  bool _decodingVin = false;

  // True while an OBD2 Mode 09 PID 02 read is in flight (#1162).
  bool _readingVinFromCar = false;

  // #1372 phase 3 — the catalog row the user picked via [ReferenceVehiclePicker]
  // (new-vehicle path only). When set, `_save` threads its catalog-only metadata
  // into the freshly-minted profile via `buildProfile`.
  ReferenceVehicle? _pickedReferenceVehicle;

  /// Open the VIN explanation sheet (#895). Restores focus on dismiss so
  /// TalkBack users don't lose their place.
  Future<void> _showVinInfo() async {
    await VinInfoSheet.show(context);
    if (!mounted) return;
    _ctrl.vinFocusNode.requestFocus();
  }

  /// Shared validator for optional numeric inputs. Empty is fine (→ null);
  /// non-empty must parse.
  String? _validateOptionalNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
    if (parsed != null) return null;
    return AppLocalizations.of(context).fieldInvalidNumber;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    // #1226 — read the freshest persisted profile and pass it as `existing:`
    // so `buildProfile` can `copyWith` over it, preserving every non-form field
    // (calibrationMode, autoRecord, runtime-calibrated η_v, driving stats, VIN
    // metadata, …) verbatim.
    final id = _existingId;
    final existing = id == null
        ? null
        : ref
            .read(vehicleProfileListProvider)
            .where((v) => v.id == id)
            .firstOrNull;
    final profile = _ctrl.buildProfile(
      existing: existing,
      type: _type,
      connectors: _connectors,
      adapterMac: _adapterMac,
      adapterName: _adapterName,
      engineDisplacementCc: _engineDisplacementCc,
      engineCylinders: _engineCylinders,
      curbWeightKg: _curbWeightKg,
      multiFuelCapable: _multiFuelCapable,
      referenceVehicle: _pickedReferenceVehicle,
    );
    await ref.read(vehicleProfileListProvider.notifier).save(profile);
    await ref.syncActiveProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Open the reference catalog picker (#1372 phase 3) and apply the user's
  /// selection. New-vehicle path only — the button is hidden when editing so a
  /// tap doesn't silently overwrite the user's tweaks.
  Future<void> _openCatalogPicker() async {
    final picked = await ReferenceVehiclePicker.show(context);
    if (picked == null || !mounted) return;
    setState(() {
      _ctrl.applyReferenceVehicle(picked);
      _engineDisplacementCc = picked.displacementCc;
      _pickedReferenceVehicle = picked;
    });
  }

  /// Decode the current VIN (#812 phase 2). Success → confirm dialog → optional
  /// auto-fill. Invalid → snackbar; dialog is skipped.
  Future<void> _decodeVin() async {
    final l = AppLocalizations.of(context);
    final vin = _ctrl.vinController.text.trim();
    if (vin.isEmpty) {
      SnackBarHelper.show(context, l.vinInvalidFormat);
      return;
    }

    setState(() => _decodingVin = true);
    VinData? decoded;
    try {
      decoded = await ref.read(decodedVinProvider(vin).future);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'EditVehicleScreen: VIN decode failed'}));
    }
    if (!mounted) return;
    setState(() => _decodingVin = false);

    if (decoded == null || decoded.source == VinDataSource.invalid) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        decoded == null ? (l.vinDecodeError) : (l.vinInvalidFormat),
      );
      return;
    }

    final outcome = await VinConfirmDialog.show(context, decoded);
    if (!mounted) return;
    if (outcome == VinConfirmOutcome.confirm) _applyDecodedVin(decoded);
  }

  /// Copy non-null engine fields from [data] (#812 phase 2). Displacement:
  /// L → cc. Curb weight ≈ GVWR / 2.205 (vPIC has no payload field).
  void _applyDecodedVin(VinData data) {
    setState(() {
      if (data.displacementL != null) {
        _engineDisplacementCc = (data.displacementL! * 1000).round();
      }
      if (data.cylinderCount != null) _engineCylinders = data.cylinderCount;
      if (data.gvwrLbs != null) {
        _curbWeightKg = (data.gvwrLbs! / 2.205).round();
      }
    });
  }

  /// Read the VIN from the paired OBD2 adapter (#1162). On success, sets the VIN
  /// text field (the decoder is triggered manually so the user can verify
  /// first). On failure, surfaces a localized snackbar and leaves the field
  /// editable.
  Future<void> _readVinFromCar() async {
    final l = AppLocalizations.of(context);
    // #1339 — gate on the adapter-selection field; VIN reading via Mode 09 PID
    // 02 only needs an adapter to talk to.
    final mac = _adapterMac;
    if (mac == null || mac.isEmpty) return;

    setState(() => _readingVinFromCar = true);
    final result =
        await ref.read(vinReaderServiceProvider).readVin(pairedAdapterMac: mac);
    if (!mounted) return;
    setState(() => _readingVinFromCar = false);

    if (result.isSuccess) {
      _ctrl.vinController.text = result.vin!;
      return;
    }

    final message = result.failure == ObdVinFailureReason.unsupported
        ? (l.vehicleReadVinFailedUnsupportedSnackbar)
        : (l.vehicleReadVinFailedGenericSnackbar);
    SnackBarHelper.show(context, message);
  }

  /// #2960 — adapter pair / forget handler. Persists the new adapter state
  /// **in place** and rebuilds the adapter section WITHOUT popping the route
  /// (earlier this routed through [_save], whose trailing `Navigator.pop()`
  /// closed the form on every add/remove).
  void _onAdapterChanged(String? name, String? mac) {
    setState(() {
      _adapterName = name;
      _adapterMac = mac;
    });
    // Persist the adapter change without tearing down the form; unsaved edits
    // carry through because [_persistAdapterChange] builds from the live
    // controllers — same as Save.
    unawaited(_persistAdapterChange());
    // #1399 — fire-and-forget VIN-driven auto-population. Only when an adapter
    // was just PAIRED (not unpaired) and we have an existing profile id.
    if (mac != null && mac.isNotEmpty) {
      unawaited(_runAutoPopulationAfterPair(mac));
    }
  }

  /// #2960 — persist the current form state (including the just-changed adapter
  /// MAC / name) WITHOUT popping the route. The adapter-section counterpart to
  /// [_save] minus the validation gate + the trailing pop. New-vehicle path
  /// (no `_existingId`) no-ops. Never throws.
  Future<void> _persistAdapterChange() async {
    final id = _existingId;
    if (id == null) return;
    try {
      final existing = ref
          .read(vehicleProfileListProvider)
          .where((v) => v.id == id)
          .firstOrNull;
      if (existing == null) return;
      final profile = _ctrl.buildProfile(
        existing: existing,
        type: _type,
        connectors: _connectors,
        adapterMac: _adapterMac,
        adapterName: _adapterName,
        engineDisplacementCc: _engineDisplacementCc,
        engineCylinders: _engineCylinders,
        curbWeightKg: _curbWeightKg,
        multiFuelCapable: _multiFuelCapable,
        referenceVehicle: _pickedReferenceVehicle,
      );
      await ref.read(vehicleProfileListProvider.notifier).save(profile);
      if (!mounted) return;
      await ref.syncActiveProfile(profile);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'EditVehicleScreen: adapter-change persist failed',
      }));
    }
  }

  /// #1399 — run the post-pair auto-population flow. Always returns quickly (the
  /// orchestrator owns the connect/disconnect lifecycle + a bounded timeout);
  /// never throws.
  Future<void> _runAutoPopulationAfterPair(String pairedAdapterMac) async {
    final id = _existingId;
    if (id == null) return;
    final populator = ref.read(vinAdapterPairAutoPopulatorProvider);
    final existing = ref
        .read(vehicleProfileListProvider)
        .where((v) => v.id == id)
        .firstOrNull;
    if (existing == null) return;

    final outcome = await populator.run(
      pairedAdapterMac: pairedAdapterMac,
      profile: existing,
    );
    if (!mounted) return;

    final updated = outcome.profile;
    if (updated == null) return;

    // Persist the merged profile + reload local form state so the "(detected)"
    // badges + auto-filled fields show immediately.
    await ref.read(vehicleProfileListProvider.notifier).save(updated);
    if (!mounted) return;
    setState(() {
      _engineDisplacementCc = updated.engineDisplacementCc;
      _engineCylinders = updated.engineCylinders;
      _curbWeightKg = updated.curbWeightKg;
      _ctrl.load(updated);
    });

    final summary = outcome.conflictSummary;
    if (summary == null) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.show(
      context,
      l.vehicleDetectedFromVinSnackbar(summary),
      action: SnackBarAction(
        label: l.vehicleDetectedFromVinApply,
        onPressed: () => _applyDetectedConflicts(updated),
      ),
    );
  }

  /// #1399 — overwrite the user-entered fields with the detected-* values when
  /// they disagree, after the user explicitly tapped "Apply".
  Future<void> _applyDetectedConflicts(VehicleProfile profile) async {
    final overwritten = profile.copyWith(
      make: profile.detectedMake ?? profile.make,
      model: profile.detectedModel ?? profile.model,
      year: profile.detectedYear ?? profile.year,
      engineDisplacementCc:
          profile.detectedEngineDisplacementCc ?? profile.engineDisplacementCc,
      preferredFuelType: profile.detectedFuelType ?? profile.preferredFuelType,
    );
    await ref.read(vehicleProfileListProvider.notifier).save(overwritten);
    if (!mounted) return;
    setState(() {
      _engineDisplacementCc = overwritten.engineDisplacementCc;
      _ctrl.load(overwritten);
    });
  }

  /// #815 — confirm-dialog → write default η_v (0.85), reset samples.
  Future<void> _resetVolumetricEfficiency() async {
    final id = _existingId;
    if (id == null) return;
    final confirmed = await VeResetConfirmDialog.show(context);
    if (confirmed != true || !mounted) return;
    await ref.resetVolumetricEfficiency(id);
  }

  /// #1397 — persist a single calibration-override field. Reads the freshest
  /// profile so the copyWith doesn't clobber fields changed elsewhere since the
  /// form last loaded.
  Future<void> _saveCalibrationOverride({
    Object? manualEngineDisplacementCcOverride = _kSentinel,
    Object? manualVolumetricEfficiencyOverride = _kSentinel,
    Object? manualAfrOverride = _kSentinel,
    Object? manualFuelDensityGPerLOverride = _kSentinel,
  }) async {
    final id = _existingId;
    if (id == null) return;
    final existing = ref
        .read(vehicleProfileListProvider)
        .where((v) => v.id == id)
        .firstOrNull;
    if (existing == null) return;
    final updated = existing.copyWith(
      manualEngineDisplacementCcOverride:
          identical(manualEngineDisplacementCcOverride, _kSentinel)
              ? existing.manualEngineDisplacementCcOverride
              : manualEngineDisplacementCcOverride as double?,
      manualVolumetricEfficiencyOverride:
          identical(manualVolumetricEfficiencyOverride, _kSentinel)
              ? existing.manualVolumetricEfficiencyOverride
              : manualVolumetricEfficiencyOverride as double?,
      manualAfrOverride: identical(manualAfrOverride, _kSentinel)
          ? existing.manualAfrOverride
          : manualAfrOverride as double?,
      manualFuelDensityGPerLOverride:
          identical(manualFuelDensityGPerLOverride, _kSentinel)
              ? existing.manualFuelDensityGPerLOverride
              : manualFuelDensityGPerLOverride as double?,
    );
    await ref.read(vehicleProfileListProvider.notifier).save(updated);
  }
}
