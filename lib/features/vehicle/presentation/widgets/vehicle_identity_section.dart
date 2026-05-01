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
/// The section also shows a "Read VIN from car" button that triggers a
/// Mode 09 PID 02 read against the paired OBD2 adapter (#1162). The
/// button is always rendered (#1328); when no adapter is paired
/// ([pairedAdapterMac] is null OR [onReadVinFromCar] is null) it is
/// shown visibly disabled with a small helper text, so users discover
/// the feature even before pairing.
class VehicleIdentitySection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController vinController;
  final FocusNode vinFocus;
  final Color accent;
  final bool decodingVin;
  final VoidCallback onDecodeVin;
  final VoidCallback onShowVinInfo;

  /// The active profile's paired adapter MAC (#1162). When null AND
  /// [onReadVinFromCar] is null, the "Read VIN from car" button is
  /// rendered disabled with a helper hint instead of being hidden — see
  /// #1328 for why discoverability beats minimalism here.
  final String? pairedAdapterMac;

  /// Callback fired when the user taps the "Read VIN from car" button
  /// (#1162). When null, the button is rendered visibly disabled
  /// (Flutter's stock OutlinedButton handling) with a small helper
  /// hint underneath telling the user to pair an adapter first.
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
        // "Read VIN from car" — always visible (#1328). When no
        // adapter is paired, the button is rendered disabled with a
        // small helper text so users discover the feature even before
        // pairing. Renders below the VIN row so the visual grouping
        // mirrors the relationship: this button writes into the VIN
        // field above. Disabled while a read is in flight to prevent
        // double-taps spawning concurrent OBD2 sessions.
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('vehicleReadVinFromCar'),
            onPressed: (onReadVinFromCar == null || readingVinFromCar)
                ? null
                : onReadVinFromCar,
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
        // Helper text shown when the button is disabled because no
        // adapter is paired yet (#1328). Tells the user how to enable
        // the auto-read flow without forcing them to discover the
        // pairing screen blindly. Wrapped in `Semantics(container: true)`
        // so the label doesn't merge with the sibling info-icon
        // Semantics annotation above (which would break the existing
        // `bySemanticsLabel('What is a VIN?')` test in #895).
        if (onReadVinFromCar == null) ...[
          const SizedBox(height: 4),
          Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                l?.vehicleReadVinNoAdapterHint ??
                    'Pair an OBD2 adapter first to read VIN automatically',
                key: const Key('vehicleReadVinNoAdapterHint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
