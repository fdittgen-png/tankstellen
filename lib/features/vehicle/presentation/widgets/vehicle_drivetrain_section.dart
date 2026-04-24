import 'package:flutter/material.dart';

import '../../../../core/widgets/form_section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';
import 'vehicle_combustion_section.dart';
import 'vehicle_ev_section.dart';
import 'vehicle_type_selector.dart';

/// Drivetrain card on the edit-vehicle form — type picker plus the
/// type-specific EV / Combustion sub-sections.
///
/// Keeps the parent form responsible for owning controllers and the
/// connector set; we only assemble the three existing building blocks
/// into the grouped `FormSectionCard` layout (#751 §3).
class VehicleDrivetrainSection extends StatelessWidget {
  final VehicleType type;
  final ValueChanged<VehicleType> onTypeChanged;
  final Color accent;

  // EV controllers / connectors — used when type != combustion.
  final TextEditingController batteryController;
  final TextEditingController maxChargingKwController;
  final TextEditingController minSocController;
  final TextEditingController maxSocController;
  final Set<ConnectorType> connectors;
  final ValueChanged<ConnectorType> onToggleConnector;

  // Combustion controllers — used when type != ev.
  final TextEditingController tankController;
  final TextEditingController fuelTypeController;

  final String? Function(String?) numberValidator;

  const VehicleDrivetrainSection({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.accent,
    required this.batteryController,
    required this.maxChargingKwController,
    required this.minSocController,
    required this.maxSocController,
    required this.connectors,
    required this.onToggleConnector,
    required this.tankController,
    required this.fuelTypeController,
    required this.numberValidator,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final showEv = type != VehicleType.combustion;
    final showCombustion = type != VehicleType.ev;
    return FormSectionCard(
      title: l?.vehicleSectionDrivetrainTitle ?? 'Drivetrain',
      subtitle:
          l?.vehicleSectionDrivetrainSubtitle ?? 'How this vehicle moves',
      icon: Icons.settings_outlined,
      accent: accent,
      children: [
        VehicleTypeSelector(selected: type, onChanged: onTypeChanged),
        const SizedBox(height: 8),
        if (showEv) ...[
          VehicleEvSection(
            batteryController: batteryController,
            maxChargingKwController: maxChargingKwController,
            minSocController: minSocController,
            maxSocController: maxSocController,
            connectors: connectors,
            onToggleConnector: onToggleConnector,
            numberValidator: numberValidator,
          ),
          const SizedBox(height: 16),
        ],
        if (showCombustion)
          VehicleCombustionSection(
            tankController: tankController,
            fuelTypeController: fuelTypeController,
            numberValidator: numberValidator,
          ),
      ],
    );
  }
}
