import 'package:flutter/material.dart';

/// Placeholder onboarding illustration for the Completion / privacy step
/// (#593). Same fuel-drop-inside-shield motif as the adaptive app icon
/// — the identity is consistent across icon, splash, and onboarding so
/// the privacy story reads as a single brand gesture.
///
/// See `docs/design/ASSET_SPEC.md` § "Onboarding illustration 3 —
/// shield/privacy" for the production-generation workflow.
class ShieldIllustration extends StatelessWidget {
  /// Target size of the illustration (square). Defaults to 200dp.
  final double size;

  const ShieldIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Privacy shield with fuel drop',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft radial backdrop for the hero glyph.
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.surface,
                    scheme.surfaceContainerLow,
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            // Shield — the privacy pledge.
            Icon(
              Icons.verified_user,
              size: size * 0.72,
              color: scheme.primary,
            ),
            // Fuel drop — nested inside the shield, white so it reads
            // against the primary-tinted shield fill.
            Padding(
              padding: EdgeInsets.only(top: size * 0.03),
              child: Icon(
                Icons.water_drop,
                size: size * 0.26,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
