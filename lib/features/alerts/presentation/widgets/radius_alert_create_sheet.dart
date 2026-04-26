import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/location/user_position_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/entities/radius_alert.dart';
import '../../domain/radius_alert_validators.dart';
import '../../providers/radius_alerts_provider.dart';
import 'radius_alert_form_fields.dart';
import 'radius_alert_map_picker.dart';

/// Signature of the map-picker opener. Production code pushes
/// [RadiusAlertMapPicker.push]; tests inject a stub that returns a
/// pre-baked [LatLng] so the picker's own widget tree doesn't need to
/// be built under `pumpApp` (#578 phase 3).
typedef RadiusAlertMapPickerOpener = Future<LatLng?> Function(
  BuildContext context,
);

/// Bottom sheet that creates a new [RadiusAlert] (#578 phase 2 + 3,
/// refactored in #563 phase: radius_alert_create_sheet).
///
/// Phase 2 shipped the form shell (label, fuel, threshold, radius, GPS
/// center). Phase 3 added the "Pick on map" button that pushes
/// [RadiusAlertMapPicker] and binds the returned [LatLng] as the alert
/// center so the background evaluator has real coordinates.
///
/// The form sections live in `radius_alert_form_fields.dart` and the
/// pure validators / parsers live in
/// `domain/radius_alert_validators.dart`; this file owns the state,
/// lifecycle, and side-effects (GPS read, map picker, save).
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
      _centerSource = l10n?.radiusAlertCenterFromMap ?? 'Map location';
    });
  }

  bool get _canSave => RadiusAlertValidators.canSave(
        label: _labelController.text,
        thresholdRaw: _thresholdController.text,
        centerLat: _centerLat,
        centerLng: _centerLng,
        postalCode: _postalCodeController.text,
      );

  Future<void> _save() async {
    final threshold =
        RadiusAlertValidators.parseThreshold(_thresholdController.text);
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

  /// Re-run `build` so the Save button picks up the new can-save state
  /// after a text field changes. Wired into every controller-driven
  /// child via [VoidCallback].
  void _rebuild() => setState(() {});

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
          RadiusAlertLabelField(
            controller: _labelController,
            onChanged: _rebuild,
          ),
          const SizedBox(height: 16),
          RadiusAlertFuelTypeField(
            value: _fuelType,
            onChanged: (v) => setState(() => _fuelType = v),
          ),
          const SizedBox(height: 16),
          RadiusAlertThresholdField(
            controller: _thresholdController,
            onChanged: _rebuild,
          ),
          const SizedBox(height: 16),
          RadiusAlertRadiusSlider(
            value: _radiusKm,
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
          const SizedBox(height: 16),
          RadiusAlertFrequencyField(
            value: _frequencyPerDay,
            onChanged: (v) => setState(() => _frequencyPerDay = v),
          ),
          const SizedBox(height: 8),
          RadiusAlertCenterButtons(
            onUseMyLocation: _useMyLocation,
            onPickOnMap: _pickOnMap,
          ),
          if (_centerSource != null) ...[
            const SizedBox(height: 8),
            Text(
              _centerSource!,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          RadiusAlertPostalCodeField(
            controller: _postalCodeController,
            onChanged: _rebuild,
          ),
          const SizedBox(height: 24),
          RadiusAlertActionButtons(
            onCancel: () => Navigator.of(context).pop(),
            onSave: _canSave ? _save : null,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
