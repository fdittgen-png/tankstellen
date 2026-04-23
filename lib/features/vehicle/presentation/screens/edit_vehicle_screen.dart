import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../consumption/presentation/widgets/vehicle_adapter_section.dart';
import '../../../consumption/presentation/widgets/vehicle_baseline_section.dart';
import '../../../consumption/providers/consumption_providers.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../domain/entities/vin_data.dart';
import '../../providers/vehicle_providers.dart';
import '../../providers/vin_decoder_provider.dart';
import '../widgets/service_reminder_section.dart';
import '../widgets/vehicle_combustion_section.dart';
import '../widgets/vehicle_ev_section.dart';
import '../widgets/vin_confirm_dialog.dart';

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
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _batteryCtrl = TextEditingController();
  final _maxKwCtrl = TextEditingController();
  final _tankCtrl = TextEditingController();
  // Pre-fill a sensible default so the "Preferred fuel" dropdown shows
  // E10 rather than the empty "Not set" option (#710). For EV the save
  // flow ignores this value anyway.
  final _fuelTypeCtrl = TextEditingController(text: 'e10');
  final _minSocCtrl = TextEditingController(text: '20');
  final _maxSocCtrl = TextEditingController(text: '80');
  // VIN onboarding (#812 phase 2). The controller feeds the decode
  // provider; the populated engine fields are stored separately and
  // carried through _save.
  final _vinCtrl = TextEditingController();

  // Combustion is the dominant case; start there and let the user
  // flip to Hybrid/Electric if needed (#710).
  VehicleType _type = VehicleType.combustion;
  final Set<ConnectorType> _connectors = {};
  String? _existingId;
  String? _adapterMac;
  String? _adapterName;

  // Engine params populated by the VIN decoder (#812 phase 2).
  // The form has no direct UI for these yet — they live alongside
  // the VIN field and will feed the OBD2 fuel-rate math in phase 3.
  int? _engineDisplacementCc;
  int? _engineCylinders;
  int? _curbWeightKg;

  // Decode button state — flips to true while the vPIC request is in
  // flight so the UI shows a spinner instead of the magnifying glass.
  bool _decodingVin = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleId != null) {
      // Load after first frame so we have access to ref.
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final list = ref.read(vehicleProfileListProvider);
    final existing = list.where((v) => v.id == widget.vehicleId).firstOrNull;
    if (existing == null) return;
    setState(() {
      _existingId = existing.id;
      _nameCtrl.text = existing.name;
      _type = existing.type;
      _batteryCtrl.text = existing.batteryKwh?.toString() ?? '';
      _maxKwCtrl.text = existing.maxChargingKw?.toString() ?? '';
      _tankCtrl.text = existing.tankCapacityL?.toString() ?? '';
      _fuelTypeCtrl.text = existing.preferredFuelType ?? '';
      _minSocCtrl.text = existing.chargingPreferences.minSocPercent.toString();
      _maxSocCtrl.text = existing.chargingPreferences.maxSocPercent.toString();
      _connectors
        ..clear()
        ..addAll(existing.supportedConnectors);
      _adapterMac = existing.obd2AdapterMac;
      _adapterName = existing.obd2AdapterName;
      _vinCtrl.text = existing.vin ?? '';
      _engineDisplacementCc = existing.engineDisplacementCc;
      _engineCylinders = existing.engineCylinders;
      _curbWeightKg = existing.curbWeightKg;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _batteryCtrl.dispose();
    _maxKwCtrl.dispose();
    _tankCtrl.dispose();
    _fuelTypeCtrl.dispose();
    _minSocCtrl.dispose();
    _maxSocCtrl.dispose();
    _vinCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  /// Shared validator for the optional numeric inputs on the form. Empty
  /// values are accepted (they map to `null` in the saved profile); only
  /// non-empty values that fail to parse get an error message.
  String? _validateOptionalNumber(String? v) {
    final l = AppLocalizations.of(context);
    if (v == null || v.trim().isEmpty) return null;
    return _parseDouble(v) == null
        ? (l?.fieldInvalidNumber ?? 'Invalid number')
        : null;
  }

  int _parseIntOr(String text, int fallback) {
    final parsed = int.tryParse(text.trim());
    return parsed ?? fallback;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final profile = VehicleProfile(
      id: _existingId ?? _uuid.v4(),
      name: _nameCtrl.text.trim(),
      type: _type,
      batteryKwh:
          _type == VehicleType.combustion ? null : _parseDouble(_batteryCtrl.text),
      maxChargingKw:
          _type == VehicleType.combustion ? null : _parseDouble(_maxKwCtrl.text),
      supportedConnectors:
          _type == VehicleType.combustion ? <ConnectorType>{} : {..._connectors},
      tankCapacityL:
          _type == VehicleType.ev ? null : _parseDouble(_tankCtrl.text),
      preferredFuelType: _type == VehicleType.ev
          ? null
          : (_fuelTypeCtrl.text.trim().isEmpty
              ? null
              : _fuelTypeCtrl.text.trim()),
      chargingPreferences: ChargingPreferences(
        minSocPercent: _parseIntOr(_minSocCtrl.text, 20).clamp(0, 100),
        maxSocPercent: _parseIntOr(_maxSocCtrl.text, 80).clamp(0, 100),
      ),
      obd2AdapterMac: _adapterMac,
      obd2AdapterName: _adapterName,
      vin: _vinCtrl.text.trim().isEmpty ? null : _vinCtrl.text.trim(),
      engineDisplacementCc: _engineDisplacementCc,
      engineCylinders: _engineCylinders,
      curbWeightKg: _curbWeightKg,
    );

    await ref.read(vehicleProfileListProvider.notifier).save(profile);

    // #710 — auto-set this vehicle as the profile's default and sync
    // the profile's `preferredFuelType` to the vehicle's fuel when:
    //   (a) no default is currently set, OR
    //   (b) the user is editing the vehicle already flagged as default.
    // This eliminates the bug where the preferences step's fuel chips
    // ignored the just-configured vehicle.
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile != null) {
        final shouldBecomeDefault =
            activeProfile.defaultVehicleId == null ||
                activeProfile.defaultVehicleId == profile.id;
        if (shouldBecomeDefault) {
          final derived = _deriveFuelTypeFromVehicle(profile);
          final updated = activeProfile.copyWith(
            defaultVehicleId: profile.id,
            preferredFuelType: derived ?? activeProfile.preferredFuelType,
          );
          await profileRepo.updateProfile(updated);
          ref.read(activeProfileProvider.notifier).refresh();
        }
      }
    } catch (e) {
      debugPrint('EditVehicleScreen: profile sync failed: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Decode the value currently in [_vinCtrl] via the VIN decoder
  /// provider (#812 phase 2). On a successful decode the user sees a
  /// confirmation dialog summarising the decoded data; accepting it
  /// auto-fills the engine-parameter fields on the profile. Invalid
  /// input surfaces as a snackbar — the dialog is skipped entirely
  /// so the user isn't prompted to "confirm" an empty summary.
  Future<void> _decodeVin() async {
    final l = AppLocalizations.of(context);
    final vin = _vinCtrl.text.trim();
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
    if (outcome == VinConfirmOutcome.confirm) {
      _applyDecodedVin(decoded);
    }
  }

  /// Copy non-null engine fields from [data] into the form state
  /// (#812 phase 2). Displacement is in litres on [VinData] and must
  /// be converted to cubic centimetres for [VehicleProfile].
  ///
  /// GVWR (pounds) is the vPIC stand-in for curb weight — a real
  /// curb weight is GVWR minus payload, but vPIC doesn't expose
  /// payload, so we approximate. The profile stores the value as an
  /// integer kilogram, and the conversion factor is 1 lb = 0.4536 kg
  /// (`lbs / 2.205`).
  void _applyDecodedVin(VinData data) {
    setState(() {
      if (data.displacementL != null) {
        _engineDisplacementCc = (data.displacementL! * 1000).round();
      }
      if (data.cylinderCount != null) {
        _engineCylinders = data.cylinderCount;
      }
      if (data.gvwrLbs != null) {
        // Approx — GVWR is gross weight, not curb weight. Phase 3
        // will swap this for a real curb-weight lookup.
        _curbWeightKg = (data.gvwrLbs! / 2.205).round();
      }
    });
  }

  /// Reset the learned η_v for this vehicle (#815). Shows a confirm
  /// dialog first — destructive actions should always be explicit —
  /// then writes the default (0.85) back through the repository and
  /// clears the sample counter. Safe to call before _save because
  /// the user hasn't necessarily pressed Save on their other
  /// changes; the reset targets the stored profile independently.
  Future<void> _resetVolumetricEfficiency() async {
    final id = _existingId;
    if (id == null) return;
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l?.veResetConfirmTitle ?? 'Reset calibration?'),
        content: Text(
          l?.veResetConfirmBody ??
              'This will discard the learned per-vehicle calibration '
                  'and restore the default value (0.85).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l?.veResetAction ?? 'Reset calibration'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      final list = ref.read(vehicleProfileListProvider);
      final existing = list.where((v) => v.id == id).firstOrNull;
      if (existing == null) return;
      final cleared = existing.copyWith(
        volumetricEfficiency: 0.85,
        volumetricEfficiencySamples: 0,
      );
      await ref.read(vehicleProfileListProvider.notifier).save(cleared);
    } catch (e) {
      debugPrint('EditVehicleScreen: VE reset failed: $e');
    }
  }

  /// Latest odometer reading logged for [vehicleId], picked from the
  /// fill-up history (#584). Falls back to null so the reminder
  /// section can prompt the user for a manual entry.
  double? _latestOdometerKm(String vehicleId) {
    try {
      final fillUps = ref.watch(fillUpListProvider);
      final forVehicle = fillUps.where((f) => f.vehicleId == vehicleId);
      if (forVehicle.isEmpty) return null;
      final latest = forVehicle.reduce(
        (a, b) => a.odometerKm > b.odometerKm ? a : b,
      );
      return latest.odometerKm;
    } catch (e) {
      debugPrint('EditVehicleScreen: odometer lookup failed: $e');
      return null;
    }
  }

  /// Translates a vehicle's type + stored `preferredFuelType` into the
  /// canonical [FuelType] the rest of the app uses (#710). EV always
  /// maps to electric; combustion parses via [FuelType.fromString].
  /// Hybrid keeps the vehicle's combustion fuel as the default until
  /// #704 ships `hybridFuelChoice`.
  FuelType? _deriveFuelTypeFromVehicle(VehicleProfile v) {
    if (v.type == VehicleType.ev) return FuelType.electric;
    final raw = v.preferredFuelType;
    if (raw == null || raw.trim().isEmpty) return null;
    return FuelType.fromString(raw);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEdit = _existingId != null || widget.vehicleId != null;
    final showEv = _type != VehicleType.combustion;
    final showCombustion = _type != VehicleType.ev;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? (l?.vehicleEditTitle ?? 'Edit vehicle')
            : (l?.vehicleAddTitle ?? 'Add vehicle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l?.save ?? 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l?.vehicleNameLabel ?? 'Name',
                hintText: l?.vehicleNameHint ?? 'e.g. My Tesla Model 3',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (l?.fieldRequired ?? 'Required')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vinCtrl,
              decoration: InputDecoration(
                labelText: l?.vinLabel ?? 'VIN (optional)',
                suffixIcon: _decodingVin
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: l?.vinDecodeTooltip ?? 'Decode VIN',
                        onPressed: _decodeVin,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _TypeSelector(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 24),
            if (showEv) ...[
              VehicleEvSection(
                batteryController: _batteryCtrl,
                maxChargingKwController: _maxKwCtrl,
                minSocController: _minSocCtrl,
                maxSocController: _maxSocCtrl,
                connectors: _connectors,
                onToggleConnector: (c) => setState(() {
                  if (_connectors.contains(c)) {
                    _connectors.remove(c);
                  } else {
                    _connectors.add(c);
                  }
                }),
                numberValidator: _validateOptionalNumber,
              ),
              const SizedBox(height: 24),
            ],
            if (showCombustion)
              VehicleCombustionSection(
                tankController: _tankCtrl,
                fuelTypeController: _fuelTypeCtrl,
                numberValidator: _validateOptionalNumber,
              ),
            // OBD2 adapter pairing section (#779). Shown for saved
            // vehicles only — pairing needs a stable vehicle id so
            // the adapter MAC attaches to something that already
            // exists in storage.
            if (_existingId != null) ...[
              const SizedBox(height: 24),
              VehicleAdapterSection(
                adapterMac: _adapterMac,
                adapterName: _adapterName,
                onPaired: (name, mac) {
                  setState(() {
                    _adapterName = name;
                    _adapterMac = mac;
                  });
                  _save();
                },
                onForget: () {
                  setState(() {
                    _adapterName = null;
                    _adapterMac = null;
                  });
                  _save();
                },
              ),
            ],
            // Baseline calibration section (#779). Only meaningful
            // for saved vehicles that might already have learned
            // baselines from previous OBD2 trips — hide it during
            // the Add flow to avoid confusing the first-run UX.
            if (_existingId != null) ...[
              const SizedBox(height: 24),
              VehicleBaselineSection(vehicleId: _existingId!),
            ],
            // η_v calibration reset (#815). Lives in the same
            // "learned calibration" band as the baseline section
            // above — a user who wants to wipe one will often want
            // to wipe the other.
            if (_existingId != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _resetVolumetricEfficiency,
                icon: const Icon(Icons.restart_alt_outlined),
                label: Text(l?.veResetAction ?? 'Reset calibration'),
              ),
            ],
            // Service reminders (#584). Needs a stable vehicle id —
            // the id is the foreign key stored on each reminder — so
            // the section only renders for saved vehicles. Users
            // adding a new vehicle hit Save first, then return to
            // edit and see this section.
            if (_existingId != null) ...[
              const SizedBox(height: 24),
              ServiceReminderSection(
                vehicleId: _existingId!,
                currentOdometerKm: _latestOdometerKm(_existingId!),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(l?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SegmentedButton<VehicleType>(
      segments: [
        ButtonSegment(
          value: VehicleType.combustion,
          label: Text(l?.vehicleTypeCombustion ?? 'Combustion'),
          icon: const Icon(Icons.local_gas_station),
        ),
        ButtonSegment(
          value: VehicleType.hybrid,
          label: Text(l?.vehicleTypeHybrid ?? 'Hybrid'),
          icon: const Icon(Icons.directions_car_filled),
        ),
        ButtonSegment(
          value: VehicleType.ev,
          label: Text(l?.vehicleTypeEv ?? 'Electric'),
          icon: const Icon(Icons.electric_car),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}
