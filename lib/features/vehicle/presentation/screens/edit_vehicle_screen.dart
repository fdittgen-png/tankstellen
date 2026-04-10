import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../providers/vehicle_providers.dart';

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
  final _fuelTypeCtrl = TextEditingController();
  final _minSocCtrl = TextEditingController(text: '20');
  final _maxSocCtrl = TextEditingController(text: '80');

  VehicleType _type = VehicleType.ev;
  final Set<ConnectorType> _connectors = {};
  String? _existingId;

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
    );

    await ref.read(vehicleProfileListProvider.notifier).save(profile);
    if (!mounted) return;
    Navigator.of(context).pop();
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
              Text(
                l?.vehicleEvSectionTitle ?? 'Electric',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _batteryCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l?.vehicleBatteryLabel ?? 'Battery capacity (kWh)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return _parseDouble(v) == null
                      ? (l?.fieldInvalidNumber ?? 'Invalid number')
                      : null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxKwCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      l?.vehicleMaxChargeLabel ?? 'Max charging power (kW)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return _parseDouble(v) == null
                      ? (l?.fieldInvalidNumber ?? 'Invalid number')
                      : null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l?.vehicleConnectorsLabel ?? 'Supported connectors',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ConnectorType.values.map((c) {
                  final selected = _connectors.contains(c);
                  return FilterChip(
                    label: Text(c.label),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _connectors.add(c);
                        } else {
                          _connectors.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSocCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l?.vehicleMinSocLabel ?? 'Min SoC %',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSocCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l?.vehicleMaxSocLabel ?? 'Max SoC %',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (showCombustion) ...[
              Text(
                l?.vehicleCombustionSectionTitle ?? 'Combustion',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tankCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l?.vehicleTankLabel ?? 'Tank capacity (L)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return _parseDouble(v) == null
                      ? (l?.fieldInvalidNumber ?? 'Invalid number')
                      : null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fuelTypeCtrl,
                decoration: InputDecoration(
                  labelText: l?.vehiclePreferredFuelLabel ?? 'Preferred fuel',
                  hintText: 'e.g. Diesel, E10',
                ),
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
