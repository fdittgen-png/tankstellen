// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// A [ShapeBorder] that carves a concave half-circle notch into the top
/// edge of the bottom bar so the central FAB docks into it (#2552).
///
/// The notch is a [CircularNotchedRectangle] scallop whose guest circle is
/// centred on the bar's TOP edge, cutting a smooth concave half-circle the
/// FAB nests into. When [notchRadius] is `<= 0` the border degenerates to a
/// plain rectangle (landscape, where the bar stays flat).
///
/// Hosted on a [Material]: the host both clips the notch and casts a shadow
/// that follows the notched silhouette (it derives its elevation shadow
/// from this border's path), so the border itself paints nothing.
class NotchedBarBorder extends ShapeBorder {
  final double notchRadius;
  final double notchMargin;

  const NotchedBarBorder({
    required this.notchRadius,
    required this.notchMargin,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (notchRadius <= 0) return Path()..addRect(rect);
    final guest = Rect.fromCircle(
      center: Offset(rect.center.dx, rect.top),
      radius: notchRadius,
    );
    return const CircularNotchedRectangle().getOuterPath(rect, guest);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => NotchedBarBorder(
        notchRadius: notchRadius * t,
        notchMargin: notchMargin * t,
      );
}
