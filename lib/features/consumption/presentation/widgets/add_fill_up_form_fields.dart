import 'package:flutter/material.dart';

import '../../../../core/widgets/form_section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../domain/add_fill_up_validators.dart';
import 'fill_up_import_buttons_pair.dart';
import 'fill_up_notes_field.dart';
import 'fill_up_numeric_field.dart';
import 'fill_up_price_per_liter_readout.dart';
import 'fill_up_station_pre_fill_banner.dart';
import 'fill_up_vehicle_dropdown.dart';
import 'fill_up_vehicle_fuel_picker.dart';

/// All the input rows on the Add-Fill-up form, composed in the
/// canonical order: optional station-prefill banner, "What you filled"
/// card (date, vehicle, fuel, liters, total + price/liter readout),
/// "Where you were" card (odometer, notes, optional report-bad-scan
/// button). Pulled out of `add_fill_up_screen.dart` (#563 extraction)
/// so the screen file drops well below 300 LOC and the form layout
/// can be exercised as a single widget in tests.
///
/// All controllers, the form's `_formKey`, and the busy/scan state are
/// owned by the screen — this widget is a pure stateless layout that
/// renders the user-visible structure and dispatches all callbacks
/// back to the parent.
class AddFillUpFormFields extends StatelessWidget {
  /// Busy flag for the "Receipt" import button — drives its spinner.
  final bool scanningReceipt;

  /// Busy flag for the "Pump display" import button.
  final bool scanningPump;
  final VoidCallback onScanReceipt;
  final VoidCallback onScanPumpDisplay;

  /// Optional station pre-fill banner — non-null station name renders
  /// the banner above the cards, otherwise the slot is omitted.
  final String? stationName;

  /// Formatted `YYYY-MM-DD` date string shown on the date row.
  final String dateLabel;
  final VoidCallback onPickDate;

  final String? vehicleId;
  final List<VehicleProfile> vehicles;
  final void Function(String id, VehicleProfile selected) onVehicleChanged;

  final FuelType fuelType;
  final ValueChanged<FuelType> onFuelChanged;
  final VoidCallback onOpenVehicle;

  final TextEditingController litersCtrl;
  final TextEditingController costCtrl;
  final TextEditingController odoCtrl;
  final TextEditingController notesCtrl;

  /// When non-null, shown after the notes field as an affordance to
  /// flag a wrong receipt scan. Null when the form was filled in
  /// manually.
  final VoidCallback? onReportBadScan;

  const AddFillUpFormFields({
    super.key,
    required this.scanningReceipt,
    required this.scanningPump,
    required this.onScanReceipt,
    required this.onScanPumpDisplay,
    required this.stationName,
    required this.dateLabel,
    required this.onPickDate,
    required this.vehicleId,
    required this.vehicles,
    required this.onVehicleChanged,
    required this.fuelType,
    required this.onFuelChanged,
    required this.onOpenVehicle,
    required this.litersCtrl,
    required this.costCtrl,
    required this.odoCtrl,
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
          scanningPump: scanningPump,
          onScanReceipt: onScanReceipt,
          onScanPumpDisplay: onScanPumpDisplay,
        ),
        const SizedBox(height: 16),
        // Station pre-fill callout — rendered above the cards so it's
        // unmissable when the user opened the form from a station
        // detail screen (#751 phase 2 keeps the original #581
        // affordance; it simply graduated from a ListTile card to the
        // restyled header band).
        if (stationName != null) ...[
          FillUpStationPreFillBanner(
            stationName: stationName!,
            label: l?.stationPreFilled ?? 'Station pre-filled',
          ),
          const SizedBox(height: 16),
        ],
        // Card 1: "What you filled" — date, vehicle, fuel, liters, cost.
        FormSectionCard(
          title: l?.fillUpSectionWhatTitle ?? 'What you filled',
          subtitle: l?.fillUpSectionWhatSubtitle ?? 'Fuel, amount, price',
          icon: Icons.local_gas_station_outlined,
          children: [
            FormFieldTile(
              icon: Icons.calendar_today_outlined,
              content: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l?.fillUpDate ?? 'Date',
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(dateLabel),
                ),
              ),
            ),
            FormFieldTile(
              icon: Icons.directions_car_outlined,
              content: FillUpVehicleDropdown(
                vehicleId: vehicleId,
                vehicles: vehicles,
                onChanged: onVehicleChanged,
              ),
            ),
            if (vehicleId != null)
              FormFieldTile(
                icon: Icons.water_drop_outlined,
                content: FillUpVehicleFuelPicker(
                  vehicles: vehicles,
                  vehicleId: vehicleId!,
                  fuelType: fuelType,
                  onChanged: onFuelChanged,
                  onOpenVehicle: onOpenVehicle,
                ),
              ),
            FormFieldTile(
              icon: Icons.opacity_outlined,
              content: FillUpNumericField(
                controller: litersCtrl,
                label: l?.liters ?? 'Liters',
                icon: Icons.water_drop_outlined,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
            ),
            FormFieldTile(
              icon: Icons.euro,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FillUpNumericField(
                    controller: costCtrl,
                    label: l?.totalCost ?? 'Total cost',
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
          ],
        ),
        const SizedBox(height: 16),
        // Card 2: "Where you were" — odometer, notes.
        FormSectionCard(
          title: l?.fillUpSectionWhereTitle ?? 'Where you were',
          subtitle:
              l?.fillUpSectionWhereSubtitle ?? 'Station, odometer, notes',
          icon: Icons.place_outlined,
          children: [
            FormFieldTile(
              icon: Icons.speed_outlined,
              content: FillUpNumericField(
                controller: odoCtrl,
                label: l?.odometerKm ?? 'Odometer (km)',
                icon: Icons.speed,
                validator: (v) => AddFillUpValidators.positiveNumber(v, l),
              ),
            ),
            FormFieldTile(
              icon: Icons.edit_note_outlined,
              content: FillUpNotesField(controller: notesCtrl),
            ),
            if (onReportBadScan != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onReportBadScan,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(
                    l?.reportScanError ?? 'Report scan error',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
