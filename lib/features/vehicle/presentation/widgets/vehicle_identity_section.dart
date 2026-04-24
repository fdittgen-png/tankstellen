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
class VehicleIdentitySection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController vinController;
  final FocusNode vinFocus;
  final Color accent;
  final bool decodingVin;
  final VoidCallback onDecodeVin;
  final VoidCallback onShowVinInfo;

  const VehicleIdentitySection({
    super.key,
    required this.nameController,
    required this.vinController,
    required this.vinFocus,
    required this.accent,
    required this.decodingVin,
    required this.onDecodeVin,
    required this.onShowVinInfo,
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
      ],
    );
  }
}
