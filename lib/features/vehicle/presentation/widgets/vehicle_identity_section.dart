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
/// When the active profile has a paired OBD2 adapter, the section
/// also shows a "Read VIN from car" button that triggers a Mode 09
/// PID 02 read against the adapter (#1162). The button is hidden
/// otherwise so users without an adapter don't see a no-op control.
class VehicleIdentitySection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController vinController;
  final FocusNode vinFocus;
  final Color accent;
  final bool decodingVin;
  final VoidCallback onDecodeVin;
  final VoidCallback onShowVinInfo;

  /// Optional — when non-null, render the "Read VIN from car" button
  /// (#1162). The screen passes the active profile's
  /// `pairedAdapterMac` here; null hides the button entirely.
  final String? pairedAdapterMac;

  /// Callback fired when the user taps the "Read VIN from car" button
  /// (#1162). Required when [pairedAdapterMac] is non-null.
  final VoidCallback? onReadVinFromCar;

  /// True while the OBD2 VIN read is in flight (#1162). Disables the
  /// button and swaps the icon for a spinner so the user has visible
  /// feedback during the ~3 s read window.
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
    this.pairedAdapterMac,
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
        // "Read VIN from car" — only visible when a paired adapter is
        // available (#1162). Renders below the VIN row so the visual
        // grouping mirrors the relationship: this button writes into
        // the VIN field above. Disabled while a read is in flight to
        // prevent double-taps spawning concurrent OBD2 sessions.
        if (pairedAdapterMac != null && onReadVinFromCar != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('vehicleReadVinFromCar'),
              onPressed: readingVinFromCar ? null : onReadVinFromCar,
              icon: readingVinFromCar
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Tooltip(
                message: l?.vehicleReadVinFromCarTooltip ??
                    'Read VIN from the paired OBD2 adapter',
                child: Text(
                  l?.vehicleReadVinFromCarButton ?? 'Read VIN from car',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
