// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../screens/topics/vehicle_edit_topic.dart';
import 'vehicle_drivetrain_section.dart';
import 'vehicle_form_controllers.dart';
import 'vehicle_header.dart';
import 'vehicle_identity_section.dart';
import 'vehicle_save_bar.dart';
import 'vehicle_topic_tiles.dart';

/// #3234 — the `EditVehicleScreen` form body (the `PageScaffold` + the scrolling
/// stack of section cards) extracted out of `_EditVehicleScreenState.build` as
/// a stateless widget. It owns no state: the screen passes the live form
/// values + pre-built callbacks (the `setState` closures are created in the
/// State), so this is a pure view. The screen keeps only the load/dispose
/// lifecycle, the `ref.listen` prepop-refill, the discard `PopScope`, and the
/// imperative actions (in the `_VehicleEditActions` part mixin).
///
/// #3900 — a topic tree, not one long page: identity & engine stay inline;
/// everything a saved vehicle grows (OBD2 adapter, calibration, service
/// reminders, auto-record) is a tappable [VehicleTopicTiles] row opening its
/// own sub-screen. The pinned Save stays here on the top level.
class VehicleEditForm extends StatelessWidget {
  const VehicleEditForm({
    super.key,
    required this.formKey,
    required this.scrollController,
    required this.isEdit,
    required this.accent,
    required this.ctrl,
    required this.type,
    required this.onTypeChanged,
    required this.decodingVin,
    required this.onDecodeVin,
    required this.onShowVinInfo,
    required this.adapterMac,
    required this.onReadVinFromCar,
    required this.readingVinFromCar,
    required this.connectors,
    required this.onToggleConnector,
    required this.multiFuelCapable,
    required this.onMultiFuelCapableChanged,
    required this.onFuelTypeChanged,
    required this.numberValidator,
    required this.existingId,
    required this.adapterName,
    required this.onOpenTopic,
    required this.onOpenCatalogPicker,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final ScrollController scrollController;
  final bool isEdit;
  final Color accent;
  final VehicleFormControllers ctrl;
  final VehicleType type;
  final ValueChanged<VehicleType> onTypeChanged;
  final bool decodingVin;
  final VoidCallback onDecodeVin;
  final VoidCallback onShowVinInfo;
  final String? adapterMac;
  final VoidCallback? onReadVinFromCar;
  final bool readingVinFromCar;
  final Set<ConnectorType> connectors;
  final ValueChanged<ConnectorType> onToggleConnector;
  final bool multiFuelCapable;
  final ValueChanged<bool> onMultiFuelCapableChanged;
  final ValueChanged<FuelType?> onFuelTypeChanged;
  final String? Function(String?) numberValidator;
  final String? existingId;
  final String? adapterName;

  /// #3900 — opens the topic sub-screen for a saved vehicle.
  final ValueChanged<VehicleEditTopic> onOpenTopic;
  final VoidCallback onOpenCatalogPicker;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageScaffold(
      title: isEdit ? (l.vehicleEditTitle) : (l.vehicleAddTitle),
      // #3899 — ONE save affordance: the pinned bottom bar. The former
      // AppBar check-mark duplicated it and read as a second, different
      // action.
      bodyPadding: EdgeInsets.zero,
      body: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 96),
          children: [
            // Big brand-tinted header — #751 §3.
            VehicleHeader(
              name: ctrl.nameController.text,
              accent: accent,
              type: type,
            ),
            const SizedBox(height: 16),
            // #1372 phase 3 — reference-catalog picker entry point. Visible only
            // when creating a new vehicle; hiding it in edit mode prevents a tap
            // from silently overwriting the user's manually-tweaked fields.
            if (!isEdit) ...[
              OutlinedButton.icon(
                onPressed: onOpenCatalogPicker,
                icon: const Icon(Icons.directions_car_outlined),
                label: Text(l.pickerButtonLabel),
              ),
              const SizedBox(height: 4),
              Text(
                l.pickerHelpText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            // Card 1: Identity (name + VIN).
            VehicleIdentitySection(
              nameController: ctrl.nameController,
              vinController: ctrl.vinController,
              vinFocus: ctrl.vinFocusNode,
              accent: accent,
              decodingVin: decodingVin,
              onDecodeVin: onDecodeVin,
              onShowVinInfo: onShowVinInfo,
              // #1328 / #1339 — always show "Read VIN from car"; null callback
              // (no adapter selected) renders it disabled with a hint.
              adapterMac: adapterMac,
              onReadVinFromCar: onReadVinFromCar,
              readingVinFromCar: readingVinFromCar,
            ),
            const SizedBox(height: 16),
            // Card 2: Drivetrain (type + type-specific fields).
            VehicleDrivetrainSection(
              type: type,
              onTypeChanged: onTypeChanged,
              accent: accent,
              batteryController: ctrl.batteryController,
              maxChargingKwController: ctrl.maxChargingKwController,
              minSocController: ctrl.minSocController,
              maxSocController: ctrl.maxSocController,
              connectors: connectors,
              onToggleConnector: onToggleConnector,
              tankController: ctrl.tankController,
              fuelTypeController: ctrl.fuelTypeController,
              powerKwController: ctrl.powerKwController,
              multiFuelCapable: multiFuelCapable,
              onMultiFuelCapableChanged: onMultiFuelCapableChanged,
              // #2885 — rebuild so the multi-fuel switch shows / hides as the
              // preferred fuel moves in and out of the E10 / E85 set.
              onFuelTypeChanged: onFuelTypeChanged,
              numberValidator: numberValidator,
            ),
            // #3900 — topics for a saved vehicle: adapter, calibration,
            // reminders, auto-record. Each opens its own sub-screen; all
            // need a stable id, so the Add flow shows none.
            if (existingId != null) ...[
              const SizedBox(height: 16),
              VehicleTopicTiles(
                vehicleId: existingId!,
                adapterName: adapterName,
                adapterMac: adapterMac,
                onOpenTopic: onOpenTopic,
              ),
            ],
          ],
        ),
      ),
      // Pinned bottom Save (#751 §3) — always in the tree regardless of scroll,
      // which tests and TalkBack rely on.
      bottomNavigationBar: VehicleSaveBar(onSave: onSave),
    );
  }
}
