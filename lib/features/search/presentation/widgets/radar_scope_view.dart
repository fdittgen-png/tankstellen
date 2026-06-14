// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/utils/price_formatter.dart';
import 'radar_scope_geometry.dart';

/// #3342 — a PPI ("plan position indicator") radar-scope view of nearby fuel
/// stations: concentric range rings + crosshair, a rotating light-blue sweep
/// (the refresh), and a green blip per station placed by distance (radius,
/// clamped to the rim = the search radius) and bearing (angle, North up).
///
/// A second visualization of the same radar station set — the caller toggles
/// between this and the distance-sorted list.
class RadarScopeView extends StatefulWidget {
  const RadarScopeView({
    super.key,
    required this.stations,
    required this.centerLat,
    required this.centerLng,
    required this.rangeKm,
    this.onStationTap,
  });

  final List<Station> stations;
  final double centerLat;
  final double centerLng;
  final double rangeKm;
  final void Function(Station station)? onStationTap;

  /// Padding (px) between the outer ring and the widget edge — shared by the
  /// painter and the tap hit-test so blip positions line up.
  static const double pad = 16.0;

  @override
  State<RadarScopeView> createState() => _RadarScopeViewState();
}

class _RadarScopeViewState extends State<RadarScopeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  // Scope palette — a dark-green PPI face so the green grid/blips and the
  // light-blue sweep read as a radar, independent of the app's light theme.
  static const Color _backdrop = Color(0xFF0A2A14);
  static const Color _grid = Color(0xFF3DDC84);
  static const Color _blip = Color(0xFF6EF2A6);
  static const Color _sweepColor = Color(0xFF40C4FF);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blips = radarScopeBlips(
      widget.stations,
      widget.centerLat,
      widget.centerLng,
      widget.rangeKm,
    );
    final rangeLabel = PriceFormatter.formatDistance(widget.rangeKm);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = min(constraints.maxWidth, constraints.maxHeight);
          final size = Size(side, side);
          return GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition, size, blips),
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (_, _) => CustomPaint(
                size: size,
                painter: _RadarScopePainter(
                  blips: blips,
                  sweepT: _sweep.value,
                  backdrop: _backdrop,
                  grid: _grid,
                  blip: _blip,
                  sweep: _sweepColor,
                  rangeLabel: rangeLabel,
                  labelStyle: theme.textTheme.labelSmall
                          ?.copyWith(color: _grid) ??
                      const TextStyle(color: _grid, fontSize: 10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset pos, Size size, List<RadarBlip> blips) {
    final cb = widget.onStationTap;
    if (cb == null || blips.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - RadarScopeView.pad;
    RadarBlip? nearest;
    var bestDist = 28.0; // px hit tolerance
    for (final b in blips) {
      final p = center + Offset(b.unitDx * radius, b.unitDy * radius);
      final d = (p - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        nearest = b;
      }
    }
    if (nearest != null) cb(nearest.station);
  }
}

class _RadarScopePainter extends CustomPainter {
  _RadarScopePainter({
    required this.blips,
    required this.sweepT,
    required this.backdrop,
    required this.grid,
    required this.blip,
    required this.sweep,
    required this.rangeLabel,
    required this.labelStyle,
  });

  final List<RadarBlip> blips;
  final double sweepT;
  final Color backdrop;
  final Color grid;
  final Color blip;
  final Color sweep;
  final String rangeLabel;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - RadarScopeView.pad;
    if (radius <= 0) return;

    canvas.drawCircle(center, radius, Paint()..color = backdrop);

    // Trailing sweep wedge — a SweepGradient rotated to the current angle.
    final sweepAngle = sweepT * 2 * pi;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [sweep.withValues(alpha: 0), sweep.withValues(alpha: 0.45)],
          stops: const [0.80, 1.0],
          transform: GradientRotation(sweepAngle - pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.restore();

    // Range rings + crosshair.
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = grid.withValues(alpha: 0.45);
    for (final f in const [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(center, radius * f, gridPaint);
    }
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), gridPaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), gridPaint);

    // Sweep leading line.
    final lead = Offset(
      center.dx + radius * sin(sweepAngle),
      center.dy - radius * cos(sweepAngle),
    );
    canvas.drawLine(
      center,
      lead,
      Paint()
        ..color = sweep.withValues(alpha: 0.85)
        ..strokeWidth = 2,
    );

    // Station blips.
    for (final b in blips) {
      final p = center + Offset(b.unitDx * radius, b.unitDy * radius);
      final a = b.beyondRange ? 0.5 : 1.0;
      canvas.drawCircle(p, 7, Paint()..color = blip.withValues(alpha: 0.18 * a));
      canvas.drawCircle(
          p, b.beyondRange ? 3 : 4, Paint()..color = blip.withValues(alpha: a));
    }

    // Range label at the top of the outer ring.
    final tp = TextPainter(
      text: TextSpan(text: rangeLabel, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx + 6, center.dy - radius - tp.height));
  }

  @override
  bool shouldRepaint(covariant _RadarScopePainter old) =>
      old.sweepT != sweepT || !identical(old.blips, blips);
}
