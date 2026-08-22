// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'add_fill_up_screen.dart';

/// #3762 — the save / validation / discard-guard flow of
/// [_AddFillUpScreenState], split out of `add_fill_up_screen.dart` as a
/// `part` mixin to satisfy the #1680 file-length ratchet. Move-only:
/// behaviour preserved verbatim.
mixin _AddFillUpSaveFlow on _AddFillUpFormState {
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
          userL: UnitFormatter.formatDecimal(userLiters, fractionDigits: 2),
          adapterL: UnitFormatter.formatDecimal(adapterDelta, fractionDigits: 2),
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
    final savedMessage = AppLocalizations.of(context).fillUpSavedSnackbar;

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
      enteredOdoKm: UnitFormatter.formatDecimal(enteredOdo, fractionDigits: 0),
      previousOdoKm: previousOdo == null
          ? null
          : UnitFormatter.formatDecimal(previousOdo, fractionDigits: 0),
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
}
