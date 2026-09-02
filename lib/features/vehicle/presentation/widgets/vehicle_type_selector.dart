// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/vehicle_profile.dart';

/// Drivetrain toggle on the edit-vehicle form — a three-segment
/// [SegmentedButton] that flips the form between Combustion, Hybrid,
/// and Electric. Pure UI; owning state stays on the parent form.
///
/// #3899 — the labels must never wrap mid-word ("Thermi que",
/// "Électriq ue" at phone width in French). Material's segmented
/// button hands every segment `maxWidth / 3` once the intrinsic widths
/// overflow, and the label text then wraps inside its `Flexible`. The
/// structural fix: measure the widest label with the button's own text
/// style and scale, and when three of them cannot share the available
/// width stack the segments vertically (`direction: Axis.vertical`) so
/// each option owns the full row. The selected check-mark is off so a
/// horizontal row keeps its width budget for the words.
class VehicleTypeSelector extends StatelessWidget {
  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  const VehicleTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Horizontal chrome one segment adds around its label: the M3
  /// icon-segment padding (12 start + 16 end), the 18 dp icon and the
  /// 8 dp icon–label gap of `TextButton.icon`.
  static const double _segmentChromeWidth = 12 + 16 + 18 + 8;

  /// Extra breathing room per segment so a label that fits by a hair
  /// (sub-pixel text metrics, the 1 dp segment borders) still lands on
  /// the safe — stacked — side.
  static const double _slack = 6;

  /// Whether three segments whose widest label paints [labelWidths]
  /// wide fit side by side in [maxWidth]. Pure so the decision is unit-
  /// testable without a layout pass.
  @visibleForTesting
  static bool fitsOnOneRow({
    required double maxWidth,
    required Iterable<double> labelWidths,
  }) {
    var widest = 0.0;
    for (final w in labelWidths) {
      if (w > widest) widest = w;
    }
    return 3 * (widest + _segmentChromeWidth + _slack) <= maxWidth;
  }

  static double _paintedWidth(
    String text,
    TextStyle? style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = <({VehicleType type, String label, IconData icon})>[
      (
        type: VehicleType.combustion,
        label: l.vehicleTypeCombustion,
        icon: Icons.local_gas_station,
      ),
      (
        type: VehicleType.hybrid,
        label: l.vehicleTypeHybrid,
        icon: Icons.directions_car_filled,
      ),
      (type: VehicleType.ev, label: l.vehicleTypeEv, icon: Icons.electric_car),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // The segmented button's default label style (M3 `labelLarge`),
        // scaled the way the segment will scale it.
        final style = Theme.of(context).textTheme.labelLarge;
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final stacked = constraints.hasBoundedWidth &&
            !fitsOnOneRow(
              maxWidth: constraints.maxWidth,
              labelWidths: [
                for (final o in options)
                  _paintedWidth(o.label, style, scaler, direction),
              ],
            );
        final button = SegmentedButton<VehicleType>(
          key: const Key('vehicleTypeSelector'),
          direction: stacked ? Axis.vertical : Axis.horizontal,
          showSelectedIcon: false,
          // Horizontal: stretch the three segments across the row.
          // Vertical: a tight width (below) does the stretching — the
          // expanded mode would demand a bounded HEIGHT there, which a
          // scrolling form never gives.
          expandedInsets: stacked ? null : EdgeInsets.zero,
          segments: [
            for (final o in options)
              ButtonSegment(
                value: o.type,
                label: Text(o.label, maxLines: 1, softWrap: false),
                icon: Icon(o.icon),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (set) => onChanged(set.first),
        );
        // A tight width makes every stacked segment own the full row
        // (the segmented button honours a tight width in vertical mode)
        // so the layout reads as an option list, not a narrow pill.
        return stacked
            ? SizedBox(width: double.infinity, child: button)
            : button;
      },
    );
  }
}
