import 'package:flutter/material.dart';

/// Placeholder onboarding illustration for the Country/Language step (#593).
///
/// "Minimal real, app-style close" — not a provisional SPLASH-text box.
/// Uses pure Flutter primitives (Icon + radial gradient container) so it
/// rasterizes correctly at any density and reacts to both light and dark
/// Material themes via [ColorScheme.primary] / [ColorScheme.surface]. The
/// three small fuel-pump markers arranged around the globe suggest the
/// multi-country nature of the app without encoding any one nation.
///
/// See `docs/design/ASSET_SPEC.md` § "Onboarding illustration 1 — globe"
/// for the production-generation workflow.
class GlobeIllustration extends StatelessWidget {
  /// Target size of the illustration (square). Defaults to 200dp to match
  /// the rest of the onboarding step layouts.
  final double size;

  const GlobeIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Globe with fuel station markers',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft radial backdrop — anchors the illustration without a
            // hard border.
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
            // Central globe glyph.
            Icon(
              Icons.public,
              size: size * 0.6,
              color: scheme.primary,
            ),
            // Three location markers arranged at 10 / 2 / 6 o'clock around
            // the globe to hint at "multi-country coverage".
            Positioned(
              top: size * 0.1,
              left: size * 0.2,
              child: _Marker(color: scheme.primary, size: size * 0.14),
            ),
            Positioned(
              top: size * 0.15,
              right: size * 0.18,
              child: _Marker(color: scheme.primary, size: size * 0.12),
            ),
            Positioned(
              bottom: size * 0.12,
              child: _Marker(color: scheme.primary, size: size * 0.13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small fuel-pump marker rendered as a filled circle with a pump icon.
class _Marker extends StatelessWidget {
  final Color color;
  final double size;

  const _Marker({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.local_gas_station,
        size: size * 0.65,
        color: color,
      ),
    );
  }
}
