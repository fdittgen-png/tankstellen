// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/form_section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../domain/add_fill_up_validators.dart';
import 'fill_up_import_buttons_pair.dart';
import 'fill_up_notes_field.dart';
import 'fill_up_numeric_field.dart';
import 'fill_up_price_per_liter_readout.dart';
import 'fill_up_station_row.dart';
import 'fill_up_vehicle_dropdown.dart';
import 'fill_up_vehicle_fuel_picker.dart';

/// All the input rows on the Add-Fill-up form, composed in the
/// canonical order: "What you filled" card (date, vehicle, fuel,
/// liters, total + price/liter readout, full-tank toggle), "Where you
/// were" card (station, odometer, notes, optional report-bad-scan
/// button). Pulled out of `add_fill_up_screen.dart` (#563 extraction)
/// so the screen file drops well below 300 LOC and the form layout
/// can be exercised as a single widget in tests.
///
/// #3899 — every row carries its icon ONCE (the field's own prefix
/// icon); the decorative leading tile column is gone. Only the two
/// section headers keep a leading icon tile. The chosen station moved
/// from a banner above the cards into the "Where you were" section as
/// a read-only row with a "Change" action.
///
/// All controllers, the form's `_formKey`, and the busy/scan state are
/// owned by the screen — this widget is a pure stateless layout that
/// renders the user-visible structure and dispatches all callbacks
/// back to the parent.
class AddFillUpFormFields extends StatelessWidget {
  /// Busy flag for the "Receipt" import button — drives its spinner.
  final bool scanningReceipt;

  final VoidCallback onScanReceipt;

  /// #2687 — opens the manual paste-receipt-text dialog (on-device,
  /// no camera / no cloud). Threaded to [FillUpImportButtonsPair].
  final VoidCallback onPasteReceipt;

  /// Station chosen on the picker screen — null renders the
  /// "Pick a station" row instead (#3899).
  final String? stationName;

  /// One-line address of [stationName] when the app knows the station.
  final String? stationAddress;

  /// Re-opens the station picker (#3899).
  final VoidCallback onChangeStation;

  /// Localized date string shown on the date row.
  final String dateLabel;
  final VoidCallback onPickDate;

  final String? vehicleId;
  final List<VehicleProfile> vehicles;
  final void Function(String id, VehicleProfile selected) onVehicleChanged;

  final FuelType fuelType;
  final ValueChanged<FuelType> onFuelChanged;
  final VoidCallback onOpenVehicle;

  /// Whether this fill-up topped the tank up to capacity (#1195).
  /// Drives the tank-level estimator's reset behaviour — see
  /// [FillUp.isFullTank].
  final bool isFullTank;
  final ValueChanged<bool> onIsFullTankChanged;

  final TextEditingController litersCtrl;
  final TextEditingController costCtrl;
  final TextEditingController odoCtrl;

  /// #3877 / #3899 — provenance helper text under the odometer field
  /// ("From your car · …", "Pre-filled from your last fill-up");
  /// null = none.
  final String? odometerNote;
  final TextEditingController notesCtrl;

  /// When non-null, shown after the notes field as an affordance to
  /// flag a wrong receipt scan. Null when the form was filled in
  /// manually.
  final VoidCallback? onReportBadScan;

  const AddFillUpFormFields({
    super.key,
    required this.scanningReceipt,
    required this.onScanReceipt,
    required this.onPasteReceipt,
    required this.stationName,
    this.stationAddress,
    required this.onChangeStation,
    required this.dateLabel,
    required this.onPickDate,
    required this.vehicleId,
    required this.vehicles,
    required this.onVehicleChanged,
    required this.fuelType,
    required this.onFuelChanged,
    required this.onOpenVehicle,
    required this.isFullTank,
    required this.onIsFullTankChanged,
    required this.litersCtrl,
    required this.costCtrl,
    required this.odoCtrl,
    this.odometerNote,
    required this.notesCtrl,
    required this.onReportBadScan,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        // #951 — restored to two visible buttons after the single
        // "Import from…" chip was rolled back. The OBD-II adapter
        // import path was removed from this screen because odometer
        // reading via PID 0xA6 is unreliable on real hardware (Peugeot
        // 107 / generic ELM327). The full OBD-II trip flow remains
        // accessible from the Consumption screen.
        FillUpImportButtonsPair(
          scanningReceipt: scanningReceipt,
          onScanReceipt: onScanReceipt,
          onPasteReceipt: onPasteReceipt,
        ),
        const SizedBox(height: 16),
        // Card 1: "What you filled" — date, vehicle, fuel, liters, cost.
        FormSectionCard(
          title: l.fillUpSectionWhatTitle,
          subtitle: l.fillUpSectionWhatSubtitle,
          icon: Icons.local_gas_station_outlined,
          children: [
            FormFieldTile(
              content: InkWell(
                onTap: onPickDate,
                borderRadius: AppRadius.md,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.fillUpDate,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(dateLabel),
                ),
              ),
            ),
            FormFieldTile(
              content: FillUpVehicleDropdown(
                vehicleId: vehicleId,
                vehicles: vehicles,
                onChanged: onVehicleChanged,
              ),
            ),
            if (vehicleId != null)
              FormFieldTile(
                content: FillUpVehicleFuelPicker(
                  vehicles: vehicles,
                  vehicleId: vehicleId!,
                  fuelType: fuelType,
                  onChanged: onFuelChanged,
                  onOpenVehicle: onOpenVehicle,
                ),
              ),
            FormFieldTile(
              content: FillUpNumericField(
                controller: litersCtrl,
                label: l.liters,
                icon: Icons.water_drop_outlined,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
            ),
            FormFieldTile(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FillUpNumericField(
                    controller: costCtrl,
                    label: l.totalCost,
                    icon: Icons.euro,
                    validator: (v) => AddFillUpValidators.positiveNumber(v, l),
                  ),
                  // Live-derived price/L — #751 §2 bullet 4.
                  FillUpPricePerLiterReadout(
                    litersController: litersCtrl,
                    costController: costCtrl,
                  ),
                ],
              ),
            ),
            // #1195 / #1360 — Full-tank toggle. Defaults ON because the
            // typical pattern is a "plein". Off = partial top-up; the
            // tank-level estimator now honours the flag and branches
            // on `previous_level + liters_added` (#1360 lands the
            // partial-fill path the original v1 left as a TODO).
            FormFieldTile(
              content: SwitchListTile(
                key: const Key('add_fill_up_is_full_tank_toggle'),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.local_gas_station_outlined),
                title: Text(l.addFillUpIsFullTankLabel),
                subtitle: Text(l.addFillUpIsFullTankSubtitle),
                value: isFullTank,
                onChanged: onIsFullTankChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Card 2: "Where you were" — station, odometer, notes.
        FormSectionCard(
          title: l.fillUpSectionWhereTitle,
          subtitle: l.fillUpSectionWhereSubtitle,
          icon: Icons.place_outlined,
          children: [
            FormFieldTile(
              content: FillUpStationRow(
                stationName: stationName,
                address: stationAddress,
                onChange: onChangeStation,
              ),
            ),
            FormFieldTile(
              content: FillUpNumericField(
                controller: odoCtrl,
                label: l.odometerKm,
                icon: Icons.speed,
                helperText: odometerNote,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
            ),
            FormFieldTile(
              content: FillUpNotesField(controller: notesCtrl),
            ),
            if (onReportBadScan != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onReportBadScan,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(l.reportScanError),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
