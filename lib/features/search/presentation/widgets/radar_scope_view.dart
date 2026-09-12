// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/sensors/imu_sensor_source.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import 'radar_scope_geometry.dart';

/// #3342 — a PPI ("plan position indicator") radar-scope view of nearby fuel
/// stations: concentric range rings + crosshair, a rotating light-blue sweep
/// (the refresh), and a green PRICE chip per station placed by distance
/// (radius, clamped to the rim = the search radius) and bearing.
///
/// #3354 — the scope shows the PRICE for the active fuel type instead of a bare
/// dot (overlapping chips collapse to the cheapest), the cheapest in view is
/// highlighted, and the whole scope orients HEADING-UP: the direction you face
/// is at the top.
///
/// #3364 — the orientation now follows the DEVICE COMPASS
/// ([compassHeadingProvider], magnetometer) so it tracks the phone pointing in
/// different directions even at a standstill — a real radar. GPS course
/// ([gpsCourseDeg]) is the fallback when no compass is available (it only
/// exists while moving), and North-up the last resort.
class RadarScopeView extends ConsumerStatefulWidget {
  const RadarScopeView({
    super.key,
    required this.stations,
    required this.centerLat,
    required this.centerLng,
    required this.rangeKm,
    required this.fuelType,
    this.gpsCourseDeg,
    this.onStationTap,
  });

  final List<Station> stations;
  final double centerLat;
  final double centerLng;
  final double rangeKm;

  /// Active fuel type — the price shown per station (#3354).
  final FuelType fuelType;

  /// Live GPS course (deg clockwise from North) — the FALLBACK orientation when
  /// the device has no compass reading yet. Null → North-up (#3364).
  final double? gpsCourseDeg;

  final void Function(Station station)? onStationTap;

  /// Padding (px) between the outer ring and the widget edge — shared by the
  /// painter and the tap hit-test so chip positions line up.
  static const double pad = 22.0;

  /// Min on-scope separation (unit-radius) below which chips collapse to the
  /// cheapest, so price labels never pile up (#3354).
  static const double clusterSeparation = 0.18;

  @override
  ConsumerState<RadarScopeView> createState() => _RadarScopeViewState();
}

class _RadarScopeViewState extends ConsumerState<RadarScopeView>
    with SingleTickerProviderStateMixin {
  /// #4072 — label painters reused across sweep frames; lives with the
  /// state (the prices change with the data, not with the frames).
  final Map<String, TextPainter> _labelCache = {};
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8), // #3372 — slower, calmer sweep
  )..repeat();

  // Scope palette — a dark-green PPI face so the green grid/chips and the
  // light-blue sweep read as a radar, independent of the app's light theme.
  static const Color _backdrop = Color(0xFF0A2A14);
  static const Color _grid = Color(0xFF3DDC84);
  static const Color _blip = Color(0xFF6EF2A6);
  static const Color _cheapest = Color(0xFFB9FF66);
  static const Color _sweepColor = Color(0xFF40C4FF);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  List<RadarBlip> _blips() {
    final raw = radarScopeBlips(
      widget.stations,
      widget.centerLat,
      widget.centerLng,
      widget.rangeKm,
      priceOf: (s) => s.priceFor(widget.fuelType),
    );
    return aggregateOverlapping(raw,
        minSeparation: RadarScopeView.clusterSeparation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blips = _blips()
      // #4072 — farthest-first so nearer chips paint on top; sorted ONCE
      // per build here, not on every frame of the 8 s sweep.
      ..sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
    // #3364 — compass-first (tracks the phone pointing), GPS course as the
    // fallback (driving), North-up the last resort.
    final heading =
        ref.watch(compassHeadingProvider).value ?? widget.gpsCourseDeg ?? 0;
    // The cheapest priced station in view — highlighted on the scope.
    double? cheapest;
    for (final b in blips) {
      final p = b.price;
      if (p != null && (cheapest == null || p < cheapest)) cheapest = p;
    }
    final rangeLabel = PriceFormatter.formatDistance(widget.rangeKm);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = min(constraints.maxWidth, constraints.maxHeight);
          final size = Size(side, side);
          return GestureDetector(
            onTapUp: (details) =>
                _handleTap(details.localPosition, size, blips, heading),
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (_, _) => CustomPaint(
                size: size,
                painter: _RadarScopePainter(
                  blips: blips,
                  sweepT: _sweep.value,
                  headingDeg: heading,
                  cheapest: cheapest,
                  backdrop: _backdrop,
                  grid: _grid,
                  blip: _blip,
                  cheapestColor: _cheapest,
                  sweep: _sweepColor,
                  rangeLabel: rangeLabel,
                  labelCache: _labelCache,
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: _grid,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(color: _grid, fontSize: 10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(
      Offset pos, Size size, List<RadarBlip> blips, double heading) {
    final cb = widget.onStationTap;
    if (cb == null || blips.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - RadarScopeView.pad;
    RadarBlip? nearest;
    var bestDist = 32.0; // px hit tolerance
    for (final b in blips) {
      final p = center + b.unitOffset(headingDeg: heading) * radius;
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
  /// #4072 — laid-out label painters, keyed by text + colour, owned by the
  /// widget state so they survive across the sweep's frames. A price chip
  /// used to lay out a fresh TextPainter on every tick of an 8 s
  /// repeating controller; the text only changes when the prices do.
  final Map<String, TextPainter> labelCache;

  _RadarScopePainter({
    required this.blips,
    required this.sweepT,
    required this.headingDeg,
    required this.cheapest,
    required this.backdrop,
    required this.grid,
    required this.blip,
    required this.cheapestColor,
    required this.sweep,
    required this.rangeLabel,
    required this.labelCache,
    required this.labelStyle,
  });

  final List<RadarBlip> blips;
  final double sweepT;
  final double headingDeg;
  final double? cheapest;
  final Color backdrop;
  final Color grid;
  final Color blip;
  final Color cheapestColor;
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
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
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

    // Station price chips — already farthest-first (sorted once per
    // build, #4072) so nearer, more relevant chips paint on top.
    for (final b in blips) {
      _paintChip(canvas, center, radius, b);
    }

    // "Ahead" marker — a fixed up-pointing caret at the centre showing the
    // driving direction is UP, plus the rotating North tick (#3354).
    _paintHeadingMarkers(canvas, center, radius);

    // Range label at the top of the outer ring.
    final tp = _label('range|$rangeLabel', rangeLabel, labelStyle);
    tp.paint(canvas, Offset(center.dx + 6, center.dy - radius - tp.height));
  }

  void _paintChip(Canvas canvas, Offset center, double radius, RadarBlip b) {
    final pos = center + b.unitOffset(headingDeg: headingDeg) * radius;
    final isCheapest =
        b.price != null && cheapest != null && b.price == cheapest;
    final a = b.beyondRange ? 0.55 : 1.0;
    final label = b.price == null
        ? '?'
        : PriceFormatter.formatPriceCompact(b.price);

    final chipColor = isCheapest ? const Color(0xFF06210F) : _ink(a);
    final tp = _label(
      'chip|$label|${chipColor.toARGB32()}',
      label,
      TextStyle(
        color: chipColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    const padX = 5.0, padY = 2.0;
    final w = tp.width + padX * 2;
    final h = tp.height + padY * 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(7),
    );
    final fill = isCheapest ? cheapestColor : blip.withValues(alpha: 0.16 * a);
    canvas.drawRRect(rect, Paint()..color = fill);
    if (!isCheapest) {
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = blip.withValues(alpha: 0.6 * a),
      );
    }
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));

    // A small "+N" when this chip stands in for an overlapping cluster.
    if (b.aggregatedCount > 1) {
      final badgeText = '+${b.aggregatedCount - 1}';
      final badge = _label(
        'badge|$badgeText|${_ink(a).toARGB32()}',
        badgeText,
        TextStyle(color: _ink(a), fontSize: 8, fontWeight: FontWeight.w700),
      );
      badge.paint(canvas, Offset(rect.right - 2, rect.top - badge.height + 2));
    }
  }

  Color _ink(double a) => cheapestColor.withValues(alpha: a);

  /// A laid-out painter for [text], reused across frames (#4072).
  TextPainter _label(String key, String text, TextStyle? style) =>
      labelCache.putIfAbsent(
        key,
        () => TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
      );

  void _paintHeadingMarkers(Canvas canvas, Offset center, double radius) {
    // Fixed up-caret at the centre — "ahead" is always the top.
    final caret = Path()
      ..moveTo(center.dx, center.dy - 11)
      ..lineTo(center.dx - 6, center.dy + 4)
      ..lineTo(center.dx + 6, center.dy + 4)
      ..close();
    canvas.drawPath(caret, Paint()..color = sweep.withValues(alpha: 0.9));

    // Rotating "N" tick — North sits at screen angle (0 − heading) from up.
    final nAngle = (-headingDeg) * pi / 180;
    final nPos = Offset(
      center.dx + (radius - 8) * sin(nAngle),
      center.dy - (radius - 8) * cos(nAngle),
    );
    final nTp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: grid.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nTp.paint(canvas, nPos - Offset(nTp.width / 2, nTp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RadarScopePainter old) =>
      old.sweepT != sweepT ||
      old.headingDeg != headingDeg ||
      !identical(old.blips, blips);
}
