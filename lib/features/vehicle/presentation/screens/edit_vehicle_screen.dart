import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/brand_logo_mapper.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../domain/entities/vin_data.dart';
import '../../providers/vehicle_providers.dart';
import '../../providers/vin_decoder_provider.dart';
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

  // #812 phase 2 — engine params populated by the VIN decoder;
  // carried through _save for phase-3 OBD2 math.
  int? _engineDisplacementCc;
  int? _engineCylinders;
  int? _curbWeightKg;

  // True while the vPIC request is in flight → VIN field spinner.
  bool _decodingVin = false;

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
    final existing = list.where((v) => v.id == widget.vehicleId).firstOrNull;
    if (existing == null) return;
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
    });
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
    final profile = _ctrl.buildProfile(
      existingId: _existingId,
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
    } catch (e) {
      debugPrint('EditVehicleScreen: VIN decode failed: $e');
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
            if (_existingId != null)
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
          ],
        ),
      ),
      // Pinned bottom Save (#751 §3) — always in the tree regardless
      // of scroll, which tests and TalkBack rely on.
      bottomNavigationBar: VehicleSaveBar(onSave: _save),
    );
  }
}
