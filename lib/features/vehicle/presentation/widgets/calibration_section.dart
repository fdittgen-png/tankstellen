import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';

/// One of the four manual-override calibration fields surfaced by
/// [CalibrationSection] (#1397).
enum _CalibrationField {
  displacement,
  volumetricEfficiency,
  afr,
  fuelDensity,
}

/// Source-of-truth indicator for a single resolved calibration value
/// (#1397). Drives both the helper-text suffix on each input row and
/// the colouring of the inline label.
enum CalibrationValueSource {
  /// The user typed this value into the field — `manual<X>Override` is
  /// non-null on the [VehicleProfile].
  manual,

  /// The value comes from a VIN decode — `detected<X>` is set.
  detected,

  /// The value comes from a reference-catalog row (`referenceVehicleId`
  /// is non-null on the profile and the field is unset on the profile).
  catalog,

  /// No higher-priority source set the value — it's the generic default
  /// constant baked into the OBD2 estimator.
  defaultConstant,
}

/// Resolves the source of a single calibration field — the same chain
/// the OBD2 estimator walks at runtime, but encoded once for the UI.
@visibleForTesting
CalibrationValueSource resolveCalibrationSource({
  required bool manualSet,
  required bool detectedSet,
  required bool catalogResolved,
}) {
  if (manualSet) return CalibrationValueSource.manual;
  if (detectedSet) return CalibrationValueSource.detected;
  if (catalogResolved) return CalibrationValueSource.catalog;
  return CalibrationValueSource.defaultConstant;
}

/// Collapsed-by-default "Advanced calibration" ExpansionTile on the
/// edit-vehicle screen (#1397).
///
/// Surfaces the four manual override fields
/// (`manual<X>Override` on [VehicleProfile]) plus a live readout of
/// the auto-learned η_v and a "Reset learner" button. Each field
/// labels its origin so users know whether the value they're seeing
/// came from VIN decoding, the catalog, the auto-learner or their
/// own keyboard.
class CalibrationSection extends StatefulWidget {
  /// The current vehicle profile. Drives both the prefilled values
  /// and every "(detected / catalog / default / manual)" badge.
  final VehicleProfile profile;

  /// Persist the new manual displacement override (or `null` to clear).
  final void Function(double?) onDisplacementChanged;

  /// Persist the new manual VE override (or `null` to clear).
  final void Function(double?) onVolumetricEfficiencyChanged;

  /// Persist the new manual AFR override (or `null` to clear).
  final void Function(double?) onAfrChanged;

  /// Persist the new manual fuel-density override (or `null` to clear).
  final void Function(double?) onFuelDensityChanged;

  /// Tapping "Reset learner" calls this with the active vehicle's id —
  /// the screen is responsible for resetting `volumetricEfficiency` +
  /// `volumetricEfficiencySamples`.
  final VoidCallback onResetLearner;

  const CalibrationSection({
    super.key,
    required this.profile,
    required this.onDisplacementChanged,
    required this.onVolumetricEfficiencyChanged,
    required this.onAfrChanged,
    required this.onFuelDensityChanged,
    required this.onResetLearner,
  });

  @override
  State<CalibrationSection> createState() => _CalibrationSectionState();
}

class _CalibrationSectionState extends State<CalibrationSection> {
  late final TextEditingController _displacementCtrl;
  late final TextEditingController _veCtrl;
  late final TextEditingController _afrCtrl;
  late final TextEditingController _fuelDensityCtrl;

  @override
  void initState() {
    super.initState();
    _displacementCtrl = TextEditingController(
      text: _initialText(_CalibrationField.displacement),
    );
    _veCtrl = TextEditingController(
      text: _initialText(_CalibrationField.volumetricEfficiency),
    );
    _afrCtrl = TextEditingController(
      text: _initialText(_CalibrationField.afr),
    );
    _fuelDensityCtrl = TextEditingController(
      text: _initialText(_CalibrationField.fuelDensity),
    );
  }

  @override
  void didUpdateWidget(covariant CalibrationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the profile flows in fresh from disk (e.g. after the
    // post-pair auto-population race) refresh the prefilled values
    // unless the user is mid-edit (we can't tell, so the conservative
    // policy is to keep the on-screen text and let the source helper
    // re-render).
    if (oldWidget.profile != widget.profile) {
      _maybeSync(_displacementCtrl, _initialText(_CalibrationField.displacement));
      _maybeSync(_veCtrl, _initialText(_CalibrationField.volumetricEfficiency));
      _maybeSync(_afrCtrl, _initialText(_CalibrationField.afr));
      _maybeSync(_fuelDensityCtrl, _initialText(_CalibrationField.fuelDensity));
    }
  }

  void _maybeSync(TextEditingController c, String text) {
    if (c.text == text) return;
    if (!c.value.composing.isCollapsed) return; // user is composing
    c.text = text;
  }

  @override
  void dispose() {
    _displacementCtrl.dispose();
    _veCtrl.dispose();
    _afrCtrl.dispose();
    _fuelDensityCtrl.dispose();
    super.dispose();
  }

  /// Resolved value (string, in the UI's display format) for a field —
  /// uses the same priority chain that the OBD2 estimator uses but
  /// folded down to a printable representation. Returns empty when the
  /// field has no value to show (only happens for the default branch
  /// when nothing's resolved).
  String _initialText(_CalibrationField field) {
    final p = widget.profile;
    switch (field) {
      case _CalibrationField.displacement:
        if (p.manualEngineDisplacementCcOverride != null) {
          return _formatDouble(p.manualEngineDisplacementCcOverride!);
        }
        if (p.engineDisplacementCc != null) {
          return p.engineDisplacementCc!.toString();
        }
        if (p.detectedEngineDisplacementCc != null) {
          return p.detectedEngineDisplacementCc!.toString();
        }
        return '';
      case _CalibrationField.volumetricEfficiency:
        if (p.manualVolumetricEfficiencyOverride != null) {
          return _formatDouble(p.manualVolumetricEfficiencyOverride!);
        }
        return _formatDouble(p.volumetricEfficiency);
      case _CalibrationField.afr:
        if (p.manualAfrOverride != null) {
          return _formatDouble(p.manualAfrOverride!);
        }
        return '';
      case _CalibrationField.fuelDensity:
        if (p.manualFuelDensityGPerLOverride != null) {
          return _formatDouble(p.manualFuelDensityGPerLOverride!);
        }
        return '';
    }
  }

  CalibrationValueSource _sourceFor(_CalibrationField field) {
    final p = widget.profile;
    switch (field) {
      case _CalibrationField.displacement:
        return resolveCalibrationSource(
          manualSet: p.manualEngineDisplacementCcOverride != null,
          detectedSet: p.detectedEngineDisplacementCc != null,
          catalogResolved: p.referenceVehicleId != null,
        );
      case _CalibrationField.volumetricEfficiency:
        return resolveCalibrationSource(
          manualSet: p.manualVolumetricEfficiencyOverride != null,
          // The auto-learner writes back into volumetricEfficiency
          // itself; treat sample count > 0 as a "detected"-class signal
          // so the UI labels the value as something other than default.
          detectedSet: p.volumetricEfficiencySamples > 0,
          catalogResolved: p.referenceVehicleId != null,
        );
      case _CalibrationField.afr:
        return resolveCalibrationSource(
          manualSet: p.manualAfrOverride != null,
          detectedSet: p.detectedFuelType != null,
          catalogResolved: p.referenceVehicleId != null,
        );
      case _CalibrationField.fuelDensity:
        return resolveCalibrationSource(
          manualSet: p.manualFuelDensityGPerLOverride != null,
          detectedSet: p.detectedFuelType != null,
          catalogResolved: p.referenceVehicleId != null,
        );
    }
  }

  String _sourceLabel(
    AppLocalizations? l,
    CalibrationValueSource source,
  ) {
    final p = widget.profile;
    switch (source) {
      case CalibrationValueSource.manual:
        return l?.calibrationSourceManual ?? '(manual)';
      case CalibrationValueSource.detected:
        return l?.calibrationSourceDetected ?? '(detected from VIN)';
      case CalibrationValueSource.catalog:
        final makeModel = [
          if (p.make != null && p.make!.isNotEmpty) p.make,
          if (p.model != null && p.model!.isNotEmpty) p.model,
        ].whereType<String>().join(' ');
        final label = makeModel.isEmpty ? 'catalog' : makeModel;
        return l?.calibrationSourceCatalog(label) ?? '(catalog: $label)';
      case CalibrationValueSource.defaultConstant:
        return l?.calibrationSourceDefault ?? '(default)';
    }
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _commitField(_CalibrationField field, String? rawText) {
    final raw = rawText?.trim().replaceAll(',', '.');
    final parsed = (raw == null || raw.isEmpty) ? null : double.tryParse(raw);
    switch (field) {
      case _CalibrationField.displacement:
        widget.onDisplacementChanged(parsed);
        break;
      case _CalibrationField.volumetricEfficiency:
        widget.onVolumetricEfficiencyChanged(parsed);
        break;
      case _CalibrationField.afr:
        widget.onAfrChanged(parsed);
        break;
      case _CalibrationField.fuelDensity:
        widget.onFuelDensityChanged(parsed);
        break;
    }
  }

  void _resetField(_CalibrationField field) {
    setState(() {
      switch (field) {
        case _CalibrationField.displacement:
          _displacementCtrl.text = _initialFromNonManual(field);
          widget.onDisplacementChanged(null);
          break;
        case _CalibrationField.volumetricEfficiency:
          _veCtrl.text = _initialFromNonManual(field);
          widget.onVolumetricEfficiencyChanged(null);
          break;
        case _CalibrationField.afr:
          _afrCtrl.text = '';
          widget.onAfrChanged(null);
          break;
        case _CalibrationField.fuelDensity:
          _fuelDensityCtrl.text = '';
          widget.onFuelDensityChanged(null);
          break;
      }
    });
  }

  /// What the field would show with the manual override removed —
  /// equivalent to nulling the override and re-running [_initialText].
  String _initialFromNonManual(_CalibrationField field) {
    final p = widget.profile;
    switch (field) {
      case _CalibrationField.displacement:
        if (p.engineDisplacementCc != null) {
          return p.engineDisplacementCc!.toString();
        }
        if (p.detectedEngineDisplacementCc != null) {
          return p.detectedEngineDisplacementCc!.toString();
        }
        return '';
      case _CalibrationField.volumetricEfficiency:
        return _formatDouble(p.volumetricEfficiency);
      case _CalibrationField.afr:
      case _CalibrationField.fuelDensity:
        return '';
    }
  }

  String _learnerStatus(AppLocalizations? l) {
    final eta = _formatDouble(widget.profile.volumetricEfficiency);
    final samples = widget.profile.volumetricEfficiencySamples;
    if (samples == 0) {
      return l?.calibrationLearnerStatusNoSamples ??
          'η_v: 0.85 (default — no plein-complet yet)';
    }
    if (samples < 3) {
      return l?.calibrationLearnerStatusLearning(eta, samples) ??
          'η_v: $eta (learning, $samples samples)';
    }
    return l?.calibrationLearnerStatusCalibrated(eta, samples) ??
        'η_v: $eta (calibrated, $samples samples)';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        title: Text(l?.calibrationAdvancedTitle ?? 'Advanced calibration'),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _buildField(
            field: _CalibrationField.displacement,
            controller: _displacementCtrl,
            labelText: l?.calibrationDisplacementLabel ??
                'Engine displacement (cc)',
            l: l,
          ),
          const SizedBox(height: 12),
          _buildField(
            field: _CalibrationField.volumetricEfficiency,
            controller: _veCtrl,
            labelText: l?.calibrationVolumetricEfficiencyLabel ??
                'Volumetric efficiency (η_v)',
            l: l,
          ),
          const SizedBox(height: 12),
          _buildField(
            field: _CalibrationField.afr,
            controller: _afrCtrl,
            labelText: l?.calibrationAfrLabel ?? 'Air-to-fuel ratio (AFR)',
            l: l,
          ),
          const SizedBox(height: 12),
          _buildField(
            field: _CalibrationField.fuelDensity,
            controller: _fuelDensityCtrl,
            labelText: l?.calibrationFuelDensityLabel ?? 'Fuel density (g/L)',
            l: l,
          ),
          const SizedBox(height: 16),
          // Live η_v readout — text + reset button.
          Row(
            children: [
              Expanded(
                child: Text(
                  _learnerStatus(l),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onResetLearner,
                child: Text(l?.calibrationResetLearner ?? 'Reset learner'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required _CalibrationField field,
    required TextEditingController controller,
    required String labelText,
    required AppLocalizations? l,
  }) {
    final source = _sourceFor(field);
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      decoration: InputDecoration(
        labelText: labelText,
        helperText: _sourceLabel(l, source),
        suffixIcon: IconButton(
          icon: const Icon(Icons.restart_alt),
          tooltip: l?.calibrationResetToDetected ?? 'Reset to detected value',
          onPressed: () => _resetField(field),
        ),
      ),
      onChanged: (text) => _commitField(field, text),
    );
  }
}
