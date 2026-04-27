import 'package:flutter/material.dart';

import '../../../../core/widgets/form_section_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Identity card on the edit-vehicle form — name + VIN.
///
/// Carries the VIN decode-button + VIN info-sheet affordances
/// introduced in #812 / #895 / #900. The parent form owns the
/// controllers, focus node, and the callbacks for decode / info —
/// this widget is intentionally dumb so all VIN-decoder state stays
/// at the screen level where the provider already lives.
///
/// When the parent passes [onReadVinFromCar] (the profile has a paired
/// OBD2 adapter), an outlined "Read VIN from car" button is rendered
/// below the VIN field — tapping it triggers the Mode 09 PID 02 read
/// in the parent (#1162). When the callback is null, the button is
/// not rendered at all so users without an adapter never see an
/// affordance that wouldn't work.
class VehicleIdentitySection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController vinController;
  final FocusNode vinFocus;
  final Color accent;
  final bool decodingVin;
  final VoidCallback onDecodeVin;
  final VoidCallback onShowVinInfo;

  /// Tap handler for the "Read VIN from car" button (#1162). When null,
  /// the button is hidden — the parent gates this on
  /// `obd2AdapterMac != null`, so the button only appears when there's
  /// an adapter to read from.
  final VoidCallback? onReadVinFromCar;

  /// True while a VIN read is in flight (#1162). Disables the button
  /// and shows a progress indicator in its place to prevent
  /// double-taps while the adapter is responding.
  final bool readingVinFromCar;

  const VehicleIdentitySection({
    super.key,
    required this.nameController,
    required this.vinController,
    required this.vinFocus,
    required this.accent,
    required this.decodingVin,
    required this.onDecodeVin,
    required this.onShowVinInfo,
    this.onReadVinFromCar,
    this.readingVinFromCar = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormSectionCard(
      title: l?.vehicleSectionIdentityTitle ?? 'Identity',
      subtitle: l?.vehicleSectionIdentitySubtitle ?? 'Name & VIN',
      icon: Icons.badge_outlined,
      accent: accent,
      children: [
        FormFieldTile(
          icon: Icons.directions_car_outlined,
          color: accent,
          content: TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l?.vehicleNameLabel ?? 'Name',
              hintText: l?.vehicleNameHint ?? 'e.g. My Tesla Model 3',
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (l?.fieldRequired ?? 'Required')
                : null,
          ),
        ),
        // VIN row — the FormFieldTile keeps the existing input layout,
        // and a trailing info icon button (#895) opens the in-place
        // explanation sheet. Tooltip + Semantics satisfy
        // androidTapTargetGuideline and TalkBack announcement
        // requirements.
        Row(
          children: [
            Expanded(
              child: FormFieldTile(
                icon: Icons.qr_code_2_outlined,
                color: accent,
                content: TextFormField(
                  controller: vinController,
                  focusNode: vinFocus,
                  decoration: InputDecoration(
                    labelText: l?.vinLabel ?? 'VIN (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: decodingVin
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: l?.vinDecodeTooltip ?? 'Decode VIN',
                            onPressed: onDecodeVin,
                          ),
                  ),
                ),
              ),
            ),
            Semantics(
              label: l?.vinInfoTooltip ?? 'What is a VIN?',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: l?.vinInfoTooltip ?? 'What is a VIN?',
                onPressed: onShowVinInfo,
              ),
            ),
          ],
        ),
        // "Read VIN from car" — outlined button rendered only when a
        // paired adapter is available (#1162). Hidden entirely when
        // [onReadVinFromCar] is null so users without an adapter
        // never see an affordance that wouldn't work.
        if (onReadVinFromCar != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Tooltip(
                message: l?.vehicleReadVinFromCarButton ?? 'Read VIN from car',
                child: OutlinedButton.icon(
                  onPressed: readingVinFromCar ? null : onReadVinFromCar,
                  icon: readingVinFromCar
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(
                    l?.vehicleReadVinFromCarButton ?? 'Read VIN from car',
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
