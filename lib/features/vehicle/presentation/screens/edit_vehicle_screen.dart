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
import '../../providers/vehicle_providers.dart';
import '../widgets/service_reminder_section.dart';
import '../widgets/vehicle_combustion_section.dart';
import '../widgets/vehicle_ev_section.dart';

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

  // Combustion is the dominant case; start there and let the user
  // flip to Hybrid/Electric if needed (#710).
  VehicleType _type = VehicleType.combustion;
  final Set<ConnectorType> _connectors = {};
  String? _existingId;
  String? _adapterMac;
  String? _adapterName;

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
