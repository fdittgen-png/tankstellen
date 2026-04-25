import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/location/user_position_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/entities/radius_alert.dart';
import '../../providers/radius_alerts_provider.dart';
import 'radius_alert_map_picker.dart';

/// Signature of the map-picker opener. Production code pushes
/// [RadiusAlertMapPicker.push]; tests inject a stub that returns a
/// pre-baked [LatLng] so the picker's own widget tree doesn't need to
/// be built under `pumpApp` (#578 phase 3).
typedef RadiusAlertMapPickerOpener = Future<LatLng?> Function(
  BuildContext context,
);

/// Bottom sheet that creates a new [RadiusAlert] (#578 phase 2 + 3).
///
/// Phase 2 shipped the form shell (label, fuel, threshold, radius, GPS
/// center). Phase 3 adds the "Pick on map" button that pushes
/// [RadiusAlertMapPicker] and binds the returned [LatLng] as the alert
/// center so the background evaluator has real coordinates.
class RadiusAlertCreateSheet extends ConsumerStatefulWidget {
  /// Injection hook so widget tests can swap the id generator for a
  /// deterministic string. Production callers leave this unset.
  final String Function()? idGenerator;

  /// Injection hook so widget tests can stub the map-picker push
  /// without standing up the full map widget tree. Production callers
  /// leave this unset; the sheet falls back to [RadiusAlertMapPicker.push].
  final RadiusAlertMapPickerOpener? mapPickerOpener;

  const RadiusAlertCreateSheet({
    super.key,
    this.idGenerator,
    this.mapPickerOpener,
  });

  /// Convenience opener used by both the alerts-screen CTA and the
  /// radius-section header button so the same entry point shows up
  /// everywhere the user expects it.
  static Future<void> show(
    BuildContext context, {
    String Function()? idGenerator,
    RadiusAlertMapPickerOpener? mapPickerOpener,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: RadiusAlertCreateSheet(
          idGenerator: idGenerator,
          mapPickerOpener: mapPickerOpener,
        ),
      ),
    );
  }

  @override
  ConsumerState<RadiusAlertCreateSheet> createState() =>
      _RadiusAlertCreateSheetState();
}

class _RadiusAlertCreateSheetState
    extends ConsumerState<RadiusAlertCreateSheet> {
  final _labelController = TextEditingController();
  final _thresholdController = TextEditingController(text: '1.500');
  final _postalCodeController = TextEditingController();

  FuelType _fuelType = FuelType.diesel;
  double _radiusKm = 10;
  int _frequencyPerDay = 1;

  double? _centerLat;
  double? _centerLng;
  String? _centerSource;

  @override
  void dispose() {
    _labelController.dispose();
    _thresholdController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _useMyLocation() {
    final pos = ref.read(userPositionProvider);
    if (pos == null) {
      SnackBarHelper.showError(
        context,
        AppLocalizations.of(context)?.errorTitleLocation ??
            'Location unavailable',
      );
      return;
    }
    setState(() {
      _centerLat = pos.lat;
      _centerLng = pos.lng;
      _centerSource = pos.source;
    });
  }

  Future<void> _pickOnMap() async {
    final opener = widget.mapPickerOpener ??
        (ctx) => RadiusAlertMapPicker.push(
              ctx,
              initialCenter: _centerLat != null && _centerLng != null
                  ? LatLng(_centerLat!, _centerLng!)
                  : null,
            );
    final picked = await opener(context);
    if (!mounted || picked == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _centerLat = picked.latitude;
      _centerLng = picked.longitude;
      _centerSource =
          l10n?.radiusAlertCenterFromMap ?? 'Map location';
    });
  }

  bool get _canSave {
    if (_labelController.text.trim().isEmpty) return false;
    final threshold = _parseThreshold();
    if (threshold == null || threshold <= 0) return false;
    // A center is required. GPS wins; otherwise postal code must be
    // non-empty so the phase-3 worker has something to geocode.
    final hasGps = _centerLat != null && _centerLng != null;
    final hasPostal = _postalCodeController.text.trim().isNotEmpty;
    return hasGps || hasPostal;
  }

  double? _parseThreshold() {
    final raw = _thresholdController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _save() async {
    final threshold = _parseThreshold();
    if (threshold == null) return;

    // Postal-code-only entries are parked at (0,0) until the phase-3
    // worker geocodes them. The stored postal code lives in the
    // label so the user can see what they asked for; the coordinates
    // are filled in once the geocoding lands.
    final lat = _centerLat ?? 0.0;
    final lng = _centerLng ?? 0.0;

    final alert = RadiusAlert(
      id: (widget.idGenerator ?? _defaultId)(),
      fuelType: _fuelType.apiValue,
      threshold: threshold,
      centerLat: lat,
      centerLng: lng,
      radiusKm: _radiusKm,
      label: _labelController.text.trim(),
      createdAt: DateTime.now(),
      frequencyPerDay: _frequencyPerDay,
    );

    await ref.read(radiusAlertsProvider.notifier).add(alert);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  static String _defaultId() => const Uuid().v4();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.alertsRadiusCreateTitle ?? 'Create radius alert',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              hintText: l10n?.alertsRadiusLabelHint ?? 'Label',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<FuelType>(
            initialValue: _fuelType,
            decoration: InputDecoration(
              labelText: l10n?.alertsRadiusFuelType ?? 'Fuel type',
              border: const OutlineInputBorder(),
            ),
            items: FuelType.values
                .where((t) => t != FuelType.all)
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _fuelType = v);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n?.alertsRadiusThreshold ?? 'Threshold (€/L)',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                l10n?.alertsRadiusKm ?? 'Radius (km)',
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '${_radiusKm.round()} km',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          Slider(
            value: _radiusKm.clamp(1, 50),
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_radiusKm.round()} km',
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _frequencyPerDay,
            decoration: InputDecoration(
              labelText: l10n?.alertsRadiusFrequencyLabel ??
                  'Check frequency',
              border: const OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int>>[
              DropdownMenuItem(
                value: 1,
                child: Text(l10n?.alertsRadiusFrequencyDaily ??
                    'Once a day'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(
                    l10n?.alertsRadiusFrequencyTwiceDaily ??
                        'Twice a day'),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text(
                    l10n?.alertsRadiusFrequencyThriceDaily ??
                        'Three times a day'),
              ),
              DropdownMenuItem(
                value: 4,
                child: Text(
                    l10n?.alertsRadiusFrequencyFourTimesDaily ??
                        'Four times a day'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _frequencyPerDay = v);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.my_location),
                  onPressed: _useMyLocation,
                  label: Text(
                    l10n?.alertsRadiusCenterGps ?? 'Use my location',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: _pickOnMap,
                  label: Text(
                    l10n?.radiusAlertPickOnMap ?? 'Pick on map',
                  ),
                ),
              ),
            ],
          ),
          if (_centerSource != null) ...[
            const SizedBox(height: 8),
            Text(
              _centerSource!,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _postalCodeController,
            decoration: InputDecoration(
              labelText:
                  l10n?.alertsRadiusCenterPostalCode ?? 'Postal code',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n?.alertsRadiusCancel ?? 'Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: Text(l10n?.alertsRadiusSave ?? 'Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
