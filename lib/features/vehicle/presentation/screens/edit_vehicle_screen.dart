import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/brand_logo_mapper.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_vin_reader.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../domain/entities/vin_data.dart';
import '../../providers/obd2_vin_reader_provider.dart';
import '../../providers/vehicle_providers.dart';
import '../../providers/vin_decoder_provider.dart';
import '../widgets/auto_record_section.dart';
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

/// Form for adding or editing a [VehicleProfile].
///
/// Pass [vehicleId] to edit an existing profile; omit to create a new one.
class EditVehicleScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const EditVehicleScreen({super.key, this.vehicleId});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = VehicleFormControllers();

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

  @override
  void initState() {
    super.initState();
    // Rebuild on every name keystroke so the header title tracks input.
    _ctrl.nameController.addListener(_refresh);
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
    super.dispose();
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
    );
    await ref.read(vehicleProfileListProvider.notifier).save(profile);
    await ref.syncActiveProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pop();
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
  }

  /// #815 — confirm-dialog → write default η_v (0.85), reset samples.
  Future<void> _resetVolumetricEfficiency() async {
    final id = _existingId;
    if (id == null) return;
    final confirmed = await VeResetConfirmDialog.show(context);
    if (confirmed != true || !mounted) return;
    await ref.resetVolumetricEfficiency(id);
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
              ),
              // Card: hands-free auto-record settings (#1004 phase 6).
              // Spread alongside the extras list so the host ListView
              // owns scroll virtualisation for the row.
              const SizedBox(height: 16),
              AutoRecordSection(vehicleId: _existingId!),
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
