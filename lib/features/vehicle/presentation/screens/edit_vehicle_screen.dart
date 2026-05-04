import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/brand_logo_mapper.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_vin_reader.dart';
import '../../domain/entities/reference_vehicle.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../domain/entities/vin_data.dart';
import '../../providers/obd2_vin_reader_provider.dart';
import '../../providers/vehicle_providers.dart';
import '../../providers/vin_adapter_pair_auto_populator_provider.dart';
import '../../providers/vin_decoder_provider.dart';
import '../widgets/auto_record_section.dart';
import '../widgets/calibration_section.dart';
import '../widgets/obd2_capability_section.dart';
import '../widgets/reference_vehicle_picker.dart';
import '../widgets/ve_reset_confirm_dialog.dart';
import '../widgets/vehicle_drivetrain_section.dart';
import '../widgets/vehicle_extras_section.dart';
import '../widgets/vehicle_form_controllers.dart';
import '../widgets/vehicle_header.dart';
import '../widgets/vehicle_identity_section.dart';
import '../widgets/vehicle_save_actions.dart';
import '../widgets/vehicle_save_bar.dart';
import '../widgets/vin_confirm_dialog.dart';
import '../widgets/vin_info_sheet.dart';

/// Sentinel for the four "leave alone" arguments on
/// [_EditVehicleScreenState._saveCalibrationOverride] — `null` is a
/// valid override value (clears the manual override) so a separate
/// marker is needed to distinguish "don't touch" from "set to null".
const Object _kSentinel = Object();

/// Form for adding or editing a [VehicleProfile].
///
/// Pass [vehicleId] to edit an existing profile; omit to create a new one.
class EditVehicleScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const EditVehicleScreen({super.key, this.vehicleId});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = VehicleFormControllers();

  // #1400 — anchors the OBD2 adapter card in the scrollable so the
  // passive "Pair an adapter in the section below" link on the
  // auto-record card can `Scrollable.ensureVisible` to it.
  final GlobalKey _obd2CardKey = GlobalKey();

  // #1400 — scroll controller for the host `ListView`. Owned here
  // (instead of relying on the implicit primary controller) so the
  // auto-record link's tap handler can fall back to an `animateTo(0)`
  // when the OBD2 card has been virtualised out of the tree by
  // ListView's lazy build, then run `Scrollable.ensureVisible` once
  // the card remounts.
  final ScrollController _scrollController = ScrollController();

  // #1400 — drives a brief amber border pulse on the OBD2 card after
  // the user taps the auto-record link. forward → reverse runs
  // 1 s end-to-end (500 ms each way).
  late final AnimationController _obd2HighlightController;

  // #710 — combustion default; user can flip to Hybrid/Electric.
  VehicleType _type = VehicleType.combustion;
  final Set<ConnectorType> _connectors = {};
  String? _existingId;
  String? _adapterMac;
  String? _adapterName;
  // #1328 — `_loadExisting()` runs in a postFrameCallback so it sees a
  // snapshot of `vehicleProfileListProvider` that may still be empty
  // while Hive is resolving (the provider is sync but the underlying
  // settings storage may rebuild). When that happens the VIN field
  // (and every other controller) stays blank. We belt-and-suspender the
  // initial path by also listening to provider transitions in `build()`
  // and re-running the load if the form is editing an existing profile
  // that hasn't been hydrated yet. This flag flips to true after the
  // first successful load so subsequent provider updates (e.g. from
  // `_save()` writing the freshest profile) don't clobber user edits.
  bool _hasInitiallyLoaded = false;

  // #812 phase 2 — engine params populated by the VIN decoder;
  // carried through _save for phase-3 OBD2 math.
  int? _engineDisplacementCc;
  int? _engineCylinders;
  int? _curbWeightKg;

  // True while the vPIC request is in flight → VIN field spinner.
  bool _decodingVin = false;

  // True while an OBD2 Mode 09 PID 02 read is in flight (#1162).
  // Disables the "Read VIN from car" button and shows a spinner so
  // the user has visible feedback during the bounded ~3 s window.
  bool _readingVinFromCar = false;

  // #1372 phase 3 — the catalog row the user picked via
  // [ReferenceVehiclePicker]. Non-null only on the new-vehicle path
  // (the picker button is hidden for existing vehicles to avoid
  // silently overwriting user tweaks). When set, `_save` threads it
  // into `buildProfile` so the freshly-minted profile carries the
  // catalog's `volumetricEfficiency`, `make`, `model`, `year`,
  // `referenceVehicleId`, and `engineDisplacementCc` from the get-go.
  // The user can still edit any controller-backed field before
  // tapping Save; tapping the picker again replaces the prior pick.
  ReferenceVehicle? _pickedReferenceVehicle;

  @override
  void initState() {
    super.initState();
    // Rebuild on every name keystroke so the header title tracks input.
    _ctrl.nameController.addListener(_refresh);
    _obd2HighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.vehicleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _refresh() => mounted ? setState(() {}) : null;

  void _loadExisting() {
    final list = ref.read(vehicleProfileListProvider);
    _applyLoadedList(list);
  }

  /// Copy the matching [VehicleProfile] from [list] into the form's
  /// controllers and scalar state. Returns true when a profile matched
  /// and was applied, false when none was found (the provider hasn't
  /// resolved yet, the id was deleted, etc.).
  ///
  /// Used by both the initial postFrameCallback path and the
  /// `ref.listen` second-chance refill (#1328). The
  /// [_hasInitiallyLoaded] flag is set on success so subsequent
  /// rebuilds don't clobber user edits.
  bool _applyLoadedList(List<VehicleProfile> list) {
    final existing = list.where((v) => v.id == widget.vehicleId).firstOrNull;
    if (existing == null) return false;
    final snap = _ctrl.load(existing);
    setState(() {
      _existingId = snap.id;
      _type = snap.type;
      _connectors
        ..clear()
        ..addAll(snap.connectors);
      _adapterMac = snap.adapterMac;
      _adapterName = snap.adapterName;
      _engineDisplacementCc = snap.engineDisplacementCc;
      _engineCylinders = snap.engineCylinders;
      _curbWeightKg = snap.curbWeightKg;
      _hasInitiallyLoaded = true;
    });
    return true;
  }

  @override
  void dispose() {
    _ctrl.nameController.removeListener(_refresh);
    _ctrl.dispose();
    _obd2HighlightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the host `ListView` so the OBD2 adapter card is visible
  /// near the top of the viewport and pulses an amber border around
  /// it for ~1 s (#1400). Wired to the passive "Pair an adapter in
  /// the section below" link on the auto-record card so users have a
  /// single canonical place to pair an adapter — this method just
  /// surfaces it.
  ///
  /// Two-stage scroll: ListView lazily builds children, so when the
  /// user has scrolled the auto-record link into view the OBD2 card
  /// (which lives ABOVE) may have already been virtualised out of
  /// the tree. In that case `_obd2CardKey.currentContext` is null
  /// and `Scrollable.ensureVisible` cannot fire. We `animateTo(0)`
  /// first to pull the OBD2 card back into the tree, then run
  /// `ensureVisible` so the card lands near the top of the viewport
  /// regardless of small layout shifts above (header / identity /
  /// drivetrain cards).
  ///
  /// Safe no-op if the OBD2 card isn't in the tree even after the
  /// pull-back (e.g. brand-new vehicle that hasn't been saved yet —
  /// the extras section is gated on `_existingId != null`).
  Future<void> _scrollToAndHighlightObd2Card() async {
    // Stage 1 — pull the OBD2 card back into the tree. Cheap no-op
    // when the controller has no clients (e.g. isolated widget
    // pumps that don't mount a Scrollable) or when offset is
    // already near zero.
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
    }
    // Stage 2 — once the card is in the tree, ensure it lands at
    // alignment 0.1 (near the top, with a small breathing-room
    // strip above so the user can see we scrolled). The
    // `currentContext` lookup happens AFTER the previous await so
    // we always pick up the freshly-mounted element.
    final ctx = _obd2CardKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      alignment: 0.1,
    );
    if (!mounted) return;
    // Run the highlight controller once forward → reverse so the
    // border fades in over 500 ms then back out over 500 ms (1 s
    // total). Awaiting forward then reverse keeps the controller
    // sequence deterministic for tests.
    await _obd2HighlightController.forward(from: 0.0);
    if (!mounted) return;
    await _obd2HighlightController.reverse();
  }

  /// Open the VIN explanation sheet (#895). Restores focus on dismiss
  /// so TalkBack users don't lose their place.
  Future<void> _showVinInfo() async {
    await VinInfoSheet.show(context);
    if (!mounted) return;
    _ctrl.vinFocusNode.requestFocus();
  }

  /// Shared validator for optional numeric inputs. Empty is fine
  /// (→ null); non-empty must parse.
  String? _validateOptionalNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
    if (parsed != null) return null;
    return AppLocalizations.of(context)?.fieldInvalidNumber ?? 'Invalid number';
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    // #1226 — read the freshest persisted profile from the provider
    // and pass it as `existing:` so `buildProfile` can `copyWith` over
    // it. This preserves every non-form field (calibrationMode,
    // pairedAdapterMac, autoRecord & friends, runtime-calibrated η_v,
    // driving-stats aggregates, VIN-decode metadata, ...) verbatim and
    // closes the bug class behind #1217 / #1221 (which was a minimum-
    // scope thread-through for `calibrationMode` only).
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
      referenceVehicle: _pickedReferenceVehicle,
    );
    await ref.read(vehicleProfileListProvider.notifier).save(profile);
    await ref.syncActiveProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Open the reference catalog picker (#1372 phase 3) and apply the
  /// user's selection. New-vehicle path only — the button is hidden
  /// when editing an existing profile so a tap doesn't silently
  /// overwrite the user's tweaks.
  ///
  /// On selection:
  ///   * `_ctrl.applyReferenceVehicle(...)` writes the catalog values
  ///     into the text controllers (`name`, `preferredFuelType`).
  ///   * Scalar engine state (`_engineDisplacementCc`) is overwritten
  ///     with the catalog row's value so the OBD-II layer can use it
  ///     immediately on the first trip.
  ///   * The picked entry itself is stashed in
  ///     [_pickedReferenceVehicle] so `_save` can thread the
  ///     catalog-only metadata (slug, volumetricEfficiency, make,
  ///     model, year) into the new profile via `buildProfile`.
  ///
  /// A second tap on the picker overwrites the prior pick — same flow,
  /// no special handling.
  Future<void> _openCatalogPicker() async {
    final picked = await ReferenceVehiclePicker.show(context);
    if (picked == null || !mounted) return;
    setState(() {
      _ctrl.applyReferenceVehicle(picked);
      _engineDisplacementCc = picked.displacementCc;
      _pickedReferenceVehicle = picked;
    });
  }

  /// Decode the current VIN (#812 phase 2). Success → confirm dialog
  /// → optional auto-fill. Invalid → snackbar; dialog is skipped.
  Future<void> _decodeVin() async {
    final l = AppLocalizations.of(context);
    final vin = _ctrl.vinController.text.trim();
    if (vin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l?.vinInvalidFormat ?? 'Invalid VIN format')),
      );
      return;
    }

    setState(() => _decodingVin = true);
    VinData? decoded;
    try {
      decoded = await ref.read(decodedVinProvider(vin).future);
    } catch (e, st) {
      debugPrint('EditVehicleScreen: VIN decode failed: $e\n$st');
    }
    if (!mounted) return;
    setState(() => _decodingVin = false);

    if (decoded == null || decoded.source == VinDataSource.invalid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(decoded == null
              ? (l?.vinDecodeError ?? "Couldn't decode this VIN")
              : (l?.vinInvalidFormat ?? 'Invalid VIN format')),
        ),
      );
      return;
    }

    final outcome = await VinConfirmDialog.show(context, decoded);
    if (!mounted) return;
    if (outcome == VinConfirmOutcome.confirm) _applyDecodedVin(decoded);
  }

  /// Copy non-null engine fields from [data] (#812 phase 2).
  /// Displacement: L → cc. Curb weight ≈ GVWR / 2.205 (vPIC has no
  /// payload field, so GVWR is the best proxy for now).
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

  /// Read the VIN from the paired OBD2 adapter (#1162). On success,
  /// sets the VIN text field; the existing decoder hook (#812 phase 2)
  /// can then be triggered manually by the user — we don't auto-fire
  /// it because the user may want to verify the value first. On any
  /// failure, surfaces a localized snackbar and leaves the field
  /// editable.
  Future<void> _readVinFromCar() async {
    final l = AppLocalizations.of(context);
    // #1339 — gate on the basic adapter-selection field
    // (`obd2AdapterMac`, surfaced here as `_adapterMac`), NOT the
    // auto-record `pairedAdapterMac` flag (#1004). VIN reading via
    // Mode 09 PID 02 only needs an adapter to talk to; auto-record
    // pairing is unrelated.
    final mac = _adapterMac;
    if (mac == null || mac.isEmpty) return;

    setState(() => _readingVinFromCar = true);
    final result = await ref
        .read(vinReaderServiceProvider)
        .readVin(pairedAdapterMac: mac);
    if (!mounted) return;
    setState(() => _readingVinFromCar = false);

    if (result.isSuccess) {
      _ctrl.vinController.text = result.vin!;
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final message = result.failure == ObdVinFailureReason.unsupported
        ? (l?.vehicleReadVinFailedUnsupportedSnackbar ??
            'VIN not available (Mode 09 PID 02 unsupported on pre-2005 vehicles)')
        : (l?.vehicleReadVinFailedGenericSnackbar ??
            'VIN read failed — please enter manually');
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _onAdapterChanged(String? name, String? mac) {
    setState(() {
      _adapterName = name;
      _adapterMac = mac;
    });
    _save();
    // #1399 — fire-and-forget VIN-driven auto-population. Only runs
    // when an adapter was just PAIRED (not unpaired) and we have an
    // existing profile id to write the detected fields onto. The
    // populator is silent on every error path; the only user-facing
    // surface is an optional "Detected: ... Apply?" snackbar when the
    // decoded values disagree with values the user has entered.
    if (mac != null && mac.isNotEmpty) {
      unawaited(_runAutoPopulationAfterPair(mac));
    }
  }

  /// #1399 — run the post-pair auto-population flow. Always returns
  /// quickly (the orchestrator owns the connect/disconnect lifecycle
  /// and a bounded timeout); never throws.
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

    // Persist the merged profile + reload local form state so the
    // "(detected)" badges reflect the fresh detected-* values and any
    // auto-filled user fields (make/model/year/displacement/fuelType)
    // show up immediately in the controllers.
    await ref.read(vehicleProfileListProvider.notifier).save(updated);
    if (!mounted) return;
    setState(() {
      _engineDisplacementCc = updated.engineDisplacementCc;
      _engineCylinders = updated.engineCylinders;
      _curbWeightKg = updated.curbWeightKg;
      // The form controllers re-read the canonical profile via the
      // load() helper so VIN / preferredFuelType etc. land in the
      // text fields as well.
      _ctrl.load(updated);
    });

    final summary = outcome.conflictSummary;
    if (summary == null) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l?.vehicleDetectedFromVinSnackbar(summary) ??
              'Detected from VIN: $summary. Apply?',
        ),
        action: SnackBarAction(
          label: l?.vehicleDetectedFromVinApply ?? 'Apply',
          onPressed: () => _applyDetectedConflicts(updated),
        ),
      ),
    );
  }

  /// #1399 — overwrite the user-entered fields with the detected-*
  /// values when they disagree, after the user explicitly tapped
  /// "Apply" on the conflict snackbar.
  Future<void> _applyDetectedConflicts(VehicleProfile profile) async {
    final overwritten = profile.copyWith(
      make: profile.detectedMake ?? profile.make,
      model: profile.detectedModel ?? profile.model,
      year: profile.detectedYear ?? profile.year,
      engineDisplacementCc:
          profile.detectedEngineDisplacementCc ?? profile.engineDisplacementCc,
      preferredFuelType:
          profile.detectedFuelType ?? profile.preferredFuelType,
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

  /// #1397 — persist a single calibration-override field. Reads the
  /// freshest profile from the provider so the copyWith doesn't clobber
  /// fields the user changed in another section since the form last
  /// loaded.
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

  /// Brand-accent colour from the vehicle name. Falls back to the
  /// theme primary when no brand matches. The brand mapper is shared
  /// with fuel stations — overlap is rare but harmless.
  Color _brandAccent(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = _ctrl.nameController.text;
    if (name.isEmpty) return primary;
    for (final token in name.toLowerCase().split(RegExp(r'\s+'))) {
      if (BrandLogoMapper.hasLogo(token)) return primary;
    }
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEdit = _existingId != null || widget.vehicleId != null;
    final accent = _brandAccent(context);

    // #1328 — second-chance refill for the pre-population race. When the
    // initial postFrameCallback ran before the provider resolved (Hive
    // box still hydrating, etc.), the form controllers stayed blank.
    // Listening here re-runs the load the moment the provider produces
    // a list that contains our target id. Guarded by
    // `_hasInitiallyLoaded` so user edits aren't clobbered by later
    // provider updates (e.g. `_save()` writing the persisted profile
    // back into the list).
    final targetId = widget.vehicleId;
    if (targetId != null) {
      ref.listen<List<VehicleProfile>>(vehicleProfileListProvider,
          (prev, next) {
        if (_hasInitiallyLoaded) return;
        if (next.any((v) => v.id == targetId)) {
          _applyLoadedList(next);
        }
      });
    }

    return PageScaffold(
      title: isEdit
          ? (l?.vehicleEditTitle ?? 'Edit vehicle')
          : (l?.vehicleAddTitle ?? 'Add vehicle'),
      actions: [
        IconButton(
          icon: const Icon(Icons.check),
          tooltip: l?.save ?? 'Save',
          onPressed: _save,
        ),
      ],
      bodyPadding: EdgeInsets.zero,
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16,
              MediaQuery.of(context).viewPadding.bottom + 96),
          children: [
            // Big brand-tinted header — #751 §3.
            VehicleHeader(
              name: _ctrl.nameController.text,
              accent: accent,
              type: _type,
            ),
            const SizedBox(height: 16),
            // #1372 phase 3 — reference-catalog picker entry point.
            // Visible only when creating a new vehicle (gated on
            // `widget.vehicleId == null` AND no successful prior load).
            // Hiding it in edit mode prevents a tap from silently
            // overwriting the user's manually-tweaked fields.
            if (!isEdit) ...[
              OutlinedButton.icon(
                onPressed: _openCatalogPicker,
                icon: const Icon(Icons.directions_car_outlined),
                label: Text(
                  l?.pickerButtonLabel ?? 'Pick from catalog',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l?.pickerHelpText ??
                    'Pre-fill from 50+ supported vehicles',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            // Card 1: Identity (name + VIN).
            VehicleIdentitySection(
              nameController: _ctrl.nameController,
              vinController: _ctrl.vinController,
              vinFocus: _ctrl.vinFocusNode,
              accent: accent,
              decodingVin: _decodingVin,
              onDecodeVin: _decodeVin,
              onShowVinInfo: _showVinInfo,
              // #1328 — always show the "Read VIN from car" button. When
              // no adapter is selected we pass `onReadVinFromCar = null`
              // (which renders the button visibly disabled with a hint)
              // so users discover the feature even before pairing.
              // #1339 — "selected" here is the basic `obd2AdapterMac`
              // state (`_adapterMac`), NOT the auto-record
              // `pairedAdapterMac` flag (#1004); VIN reading only needs
              // an adapter to talk to.
              adapterMac: _adapterMac,
              onReadVinFromCar:
                  (_adapterMac != null && _adapterMac!.isNotEmpty)
                      ? _readVinFromCar
                      : null,
              readingVinFromCar: _readingVinFromCar,
            ),
            const SizedBox(height: 16),
            // Card 2: Drivetrain (type + type-specific fields).
            VehicleDrivetrainSection(
              type: _type,
              onTypeChanged: (t) => setState(() => _type = t),
              accent: accent,
              batteryController: _ctrl.batteryController,
              maxChargingKwController: _ctrl.maxChargingKwController,
              minSocController: _ctrl.minSocController,
              maxSocController: _ctrl.maxSocController,
              connectors: _connectors,
              onToggleConnector: (c) => setState(() {
                if (_connectors.contains(c)) {
                  _connectors.remove(c);
                } else {
                  _connectors.add(c);
                }
              }),
              tankController: _ctrl.tankController,
              fuelTypeController: _ctrl.fuelTypeController,
              numberValidator: _validateOptionalNumber,
            ),
            // Extras for saved vehicles — adapter, baselines, VE
            // reset, service reminders. All need a stable id.
            // Spread a List<Widget> instead of wrapping in a Column
            // so tester.scrollUntilVisible still works on the rows
            // below the fold (see feedback_ci_column_in_listview.md).
            if (_existingId != null) ...[
              ...VehicleExtrasSection.build(
                context: context,
                vehicleId: _existingId!,
                adapterMac: _adapterMac,
                adapterName: _adapterName,
                onAdapterPaired: (name, mac) => _onAdapterChanged(name, mac),
                onAdapterForget: () => _onAdapterChanged(null, null),
                onResetVolumetricEfficiency: _resetVolumetricEfficiency,
                currentOdometerKm: ref.latestOdometerKm(_existingId!),
                obd2CardKey: _obd2CardKey,
                obd2HighlightAnimation: _obd2HighlightController,
              ),
              // Card: hands-free auto-record settings (#1004 phase 6).
              // Spread alongside the extras list so the host ListView
              // owns scroll virtualisation for the row.
              // #1400 — the auto-record card's "Pair an adapter in the
              // section below" link calls back into the screen so we
              // can `Scrollable.ensureVisible` the canonical OBD2 card
              // and pulse its border. The link replaces the duplicate
              // orange-tinted "Pair an adapter" button that lived in
              // the auto-record card before #1400.
              const SizedBox(height: 16),
              AutoRecordSection(
                vehicleId: _existingId!,
                onScrollToObd2Card: _scrollToAndHighlightObd2Card,
              ),
              // #1401 phase 6 — adapter capability tier card. Renders
              // nothing when no adapter is connected (collapsed via
              // [SizedBox.shrink] inside the widget) so it doesn't
              // pad the layout for users who haven't paired anything.
              const SizedBox(height: 16),
              const Obd2CapabilitySection(),
              const SizedBox(height: 16),
              // #1397 — collapsed-by-default expansion tile that lets
              // users override the four physics constants the OBD2
              // estimator uses (displacement, η_v, AFR, fuel density).
              // Each row labels its source so users know whether the
              // value came from VIN decode / catalog / default / their
              // own keyboard. The auto-learner (#815) writes back into
              // `volumetricEfficiency`; the readout panel + reset
              // button surface its state.
              Builder(builder: (context) {
                final profile = ref
                    .watch(vehicleProfileListProvider)
                    .where((v) => v.id == _existingId)
                    .firstOrNull;
                if (profile == null) return const SizedBox.shrink();
                return CalibrationSection(
                  profile: profile,
                  onDisplacementChanged: (v) => _saveCalibrationOverride(
                    manualEngineDisplacementCcOverride: v,
                  ),
                  onVolumetricEfficiencyChanged: (v) =>
                      _saveCalibrationOverride(
                    manualVolumetricEfficiencyOverride: v,
                  ),
                  onAfrChanged: (v) =>
                      _saveCalibrationOverride(manualAfrOverride: v),
                  onFuelDensityChanged: (v) => _saveCalibrationOverride(
                    manualFuelDensityGPerLOverride: v,
                  ),
                  onResetLearner: _resetVolumetricEfficiency,
                );
              }),
            ],
          ],
        ),
      ),
      // Pinned bottom Save (#751 §3) — always in the tree regardless
      // of scroll, which tests and TalkBack rely on.
      bottomNavigationBar: VehicleSaveBar(onSave: _save),
    );
  }
}
