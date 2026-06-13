// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../consumption/domain/direct_fuel_rate_detector.dart';
import '../../../consumption/providers/trip_history_provider.dart';
import '../../data/reference_vehicle_catalog_provider.dart';
import '../../data/vehicle_profile_catalog_matcher.dart';
import '../../domain/entities/reference_vehicle.dart';
import '../../providers/vehicle_providers.dart';
import 'auto_record_section.dart';
import 'calibration_section.dart';
import 'obd2_capability_section.dart';
import 'vehicle_drivetrain_section.dart';
import 'vehicle_extras_section.dart';
import 'vehicle_form_controllers.dart';
import 'vehicle_header.dart';
import 'vehicle_identity_section.dart';
import 'vehicle_save_actions.dart';
import 'vehicle_save_bar.dart';
import '../../../consumption/presentation/widgets/broken_map_widgets.dart';

/// #3234 — the `EditVehicleScreen` form body (the `PageScaffold` + the scrolling
/// stack of section cards) extracted out of `_EditVehicleScreenState.build` as
/// a stateless [ConsumerWidget]. It owns no state: the screen passes the live
/// form values + pre-built callbacks (the `setState` closures are created in
/// the State), so this is a pure view. The screen keeps only the load/dispose
/// lifecycle, the `ref.listen` prepop-refill, the discard `PopScope`, and the
/// imperative actions (in the `_VehicleEditActions` part mixin).
class VehicleEditForm extends ConsumerWidget {
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
    required this.onAdapterPaired,
    required this.onAdapterForget,
    required this.onResetVolumetricEfficiency,
    required this.obd2CardKey,
    required this.obd2HighlightAnimation,
    required this.onScrollToObd2Card,
    required this.onOpenCatalogPicker,
    required this.onSave,
    required this.onDisplacementChanged,
    required this.onVolumetricEfficiencyChanged,
    required this.onAfrChanged,
    required this.onFuelDensityChanged,
    required this.onResetLearner,
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
  final void Function(String? name, String? mac) onAdapterPaired;
  final VoidCallback onAdapterForget;
  final VoidCallback onResetVolumetricEfficiency;
  final GlobalKey obd2CardKey;
  final Animation<double>? obd2HighlightAnimation;
  final Future<void> Function() onScrollToObd2Card;
  final VoidCallback onOpenCatalogPicker;
  final VoidCallback onSave;
  final ValueChanged<double?> onDisplacementChanged;
  final ValueChanged<double?> onVolumetricEfficiencyChanged;
  final ValueChanged<double?> onAfrChanged;
  final ValueChanged<double?> onFuelDensityChanged;
  final VoidCallback onResetLearner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PageScaffold(
      title: isEdit ? (l.vehicleEditTitle) : (l.vehicleAddTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.check),
          tooltip: l.save,
          onPressed: onSave,
        ),
      ],
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
            // Extras for saved vehicles — adapter, baselines, VE reset, service
            // reminders. All need a stable id. Spread a List<Widget> (not a
            // Column) so scrollUntilVisible still works on the rows below the
            // fold (see feedback_ci_column_in_listview.md).
            if (existingId != null) ...[
              ...VehicleExtrasSection.build(
                context: context,
                vehicleId: existingId!,
                adapterMac: adapterMac,
                adapterName: adapterName,
                onAdapterPaired: onAdapterPaired,
                onAdapterForget: onAdapterForget,
                onResetVolumetricEfficiency: onResetVolumetricEfficiency,
                currentOdometerKm: ref.latestOdometerKm(existingId!),
                obd2CardKey: obd2CardKey,
                obd2HighlightAnimation: obd2HighlightAnimation,
              ),
              // Hands-free auto-record settings (#1004 phase 6 / #1400).
              const SizedBox(height: 16),
              AutoRecordSection(
                vehicleId: existingId!,
                onScrollToObd2Card: onScrollToObd2Card,
              ),
              // #1401 phase 6 — adapter capability tier card (collapses to
              // SizedBox.shrink when no adapter is connected).
              const SizedBox(height: 16),
              const Obd2CapabilitySection(),
              // #1622 — broken-MAP + adapter-blocklist diagnostics (collapses
              // when there's nothing to show).
              const SizedBox(height: 16),
              BrokenMapDiagnosticsCard(vehicleId: existingId),
              const SizedBox(height: 16),
              // #1397 — collapsed-by-default override tile for the four physics
              // constants the OBD2 estimator uses. Each row labels its source.
              Builder(builder: (context) {
                final profile = ref
                    .watch(vehicleProfileListProvider)
                    .where((v) => v.id == existingId)
                    .firstOrNull;
                if (profile == null) return const SizedBox.shrink();
                // #1422 phase 2 — resolve the matching ReferenceVehicle (by slug,
                // else via the matcher) for the η_v origin tag. Catalog provider
                // is keep-alive, so this watch is cheap.
                final catalog =
                    ref.watch(referenceVehicleCatalogProvider).value ??
                        const <ReferenceVehicle>[];
                ReferenceVehicle? referenceVehicle;
                if (profile.referenceVehicleId != null) {
                  for (final entry in catalog) {
                    if (VehicleProfileCatalogMatcher.slugFor(entry) ==
                        profile.referenceVehicleId) {
                      referenceVehicle = entry;
                      break;
                    }
                  }
                }
                referenceVehicle ??= VehicleProfileCatalogMatcher.bestMatch(
                  profile: profile,
                  catalog: catalog,
                );
                // #2837 — when this vehicle reports fuel rate directly (PID 5E /
                // MAF), the η_v calibration is irrelevant; de-emphasise it.
                final directFuelRate = vehicleReportsDirectFuelRate(
                  ref.watch(tripHistoryRepositoryProvider)?.loadAll() ??
                      const [],
                  vehicleId: profile.id,
                );
                return CalibrationSection(
                  profile: profile,
                  referenceVehicle: referenceVehicle,
                  directFuelRateSupported: directFuelRate,
                  onDisplacementChanged: onDisplacementChanged,
                  onVolumetricEfficiencyChanged: onVolumetricEfficiencyChanged,
                  onAfrChanged: onAfrChanged,
                  onFuelDensityChanged: onFuelDensityChanged,
                  onResetLearner: onResetLearner,
                );
              }),
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
