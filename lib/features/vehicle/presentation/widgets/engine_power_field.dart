// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/reference_vehicle.dart';

/// Rated-engine-power input for the edit-vehicle form's Combustion
/// section (Epic #3015).
///
/// Bound to the form's `powerKwController`, which is pre-filled from the
/// matched [ReferenceVehicle.powerKw] on a catalog pick (no-clobber) and
/// is fully user-overridable. The value is canonical kW; the metric
/// horsepower (PS) equivalent is derived live via [powerKwToPs] and
/// shown as the field's helper text so the user sees both units without
/// either being persisted twice.
///
/// Stateful so the PS helper text re-renders on every keystroke — a
/// [StatelessWidget] would not rebuild the helper as the kW value
/// changes.
class EnginePowerField extends StatefulWidget {
  final TextEditingController controller;

  const EnginePowerField({
    super.key,
    required this.controller,
  });

  @override
  State<EnginePowerField> createState() => _EnginePowerFieldState();
}

class _EnginePowerFieldState extends State<EnginePowerField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kw = int.tryParse(widget.controller.text.trim());
    final ps = powerKwToPs(kw);
    // Live PS equivalent in the helper text — only when the kW value
    // parses to a positive number, so an empty / bogus field doesn't
    // show a meaningless "≈ 0 PS".
    final helper = (ps != null && ps > 0)
        ? (l?.vehiclePowerHelper(ps.toString()) ?? '≈ $ps PS')
        : null;
    return TextFormField(
      key: const Key('vehicle_engine_power_field'),
      controller: widget.controller,
      keyboardType: const TextInputType.numberWithOptions(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: l?.vehiclePowerLabel ?? 'Engine power (kW)',
        helperText: helper,
      ),
      // Engine power is optional — an empty field must never block Save.
      // The `digitsOnly` formatter already prevents non-numeric input,
      // so no further validation is needed.
      validator: (_) => null,
    );
  }
}
