import 'package:flutter/material.dart';

/// Placeholder onboarding illustration for the Preferences step (#593).
///
/// Centered fuel-pump icon sitting on a faux "price ticker" — a rounded
/// rectangle with a mini sparkline below it — suggesting the core
/// value-prop: cheapest pump + price trend. Pure Flutter widgets so the
/// asset rasterizes at every density and respects light/dark theme.
///
/// See `docs/design/ASSET_SPEC.md` § "Onboarding illustration 2 — fuel
/// pump" for the production-generation workflow.
class FuelPumpIllustration extends StatelessWidget {
  /// Target size of the illustration (square). Defaults to 200dp.
  final double size;

  const FuelPumpIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Fuel pump with price ticker',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ticker card — sits behind the pump.
            Positioned(
              bottom: size * 0.12,
              child: _PriceTicker(
                width: size * 0.8,
                height: size * 0.22,
                primary: scheme.primary,
                surface: scheme.surfaceContainerLow,
                onSurface: scheme.onSurface,
              ),
            ),
            // Pump glyph — the hero.
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.18),
              child: Icon(
                Icons.local_gas_station,
                size: size * 0.65,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceTicker extends StatelessWidget {
  final double width;
  final double height;
  final Color primary;
  final Color surface;
  final Color onSurface;

  const _PriceTicker({
    required this.width,
    required this.height,
    required this.primary,
    required this.surface,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(height * 0.28),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.4,
        vertical: height * 0.2,
      ),
      child: CustomPaint(
        painter: _SparklinePainter(color: primary),
        size: Size(width, height),
      ),
    );
  }
}

/// Minimal descending sparkline — suggests "prices going down". Kept
/// hand-drawn with a short polyline instead of real data, because this
/// is a static illustration.
class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h * 0.6);
    path.lineTo(w * 0.2, h * 0.3);
    path.lineTo(w * 0.4, h * 0.55);
    path.lineTo(w * 0.6, h * 0.25);
    path.lineTo(w * 0.8, h * 0.7);
    path.lineTo(w, h * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.color != color;
}
