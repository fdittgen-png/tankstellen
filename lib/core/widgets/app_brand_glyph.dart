// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/spacing.dart';

/// The app's own mark — the shield outline with a fuel drop inside —
/// drawn as a path rather than loaded as an image.
///
/// Extracted from the splash screen at #4128, where it had been a
/// private painter since #795. Two surfaces show the mark now (the
/// splash and the home screen's app bar) and there must be exactly ONE
/// definition of it: a second hand-drawn copy beside the first is a
/// divergence waiting to happen the next time the launcher icon is
/// redrawn.
///
/// Painted in code on purpose. `assets/` is deliberately not wildcarded
/// and `assets/icon.png` is build-time art for the launcher-icon tooling,
/// never bundled (#1776), so an asset here would mean shipping the art
/// twice. The geometry mirrors the adaptive-icon vector in
/// `android/app/src/main/res/drawable/ic_launcher_foreground.xml` so the
/// mark is the same shape the user just tapped on their launcher.
class AppBrandGlyph extends StatelessWidget {
  const AppBrandGlyph({super.key, required this.size, this.color});

  /// Side length of the (square) mark.
  final double size;

  /// Ink for the mark. Defaults to the surrounding text colour, which is
  /// what makes the glyph usable in an app bar: the splash paints it in
  /// one fixed light-on-brand-green, but chrome has to follow light /
  /// dark / eco.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: size,
      height: size,
      // The surrounding text already names the app; a mark that
      // announced the brand again would read it twice.
      child: ExcludeSemantics(
        child: CustomPaint(painter: AppBrandGlyphPainter(ink)),
      ),
    );
  }
}

/// The home screen's app-bar title: the mark, then the brand word.
///
/// #4128 — the app bar named the app in text while the mark it belongs
/// to lived only on a splash screen visible for under a second. The mark
/// sizes off the title text rather than a constant, because the bar is
/// 40 dp tall in landscape and a fixed glyph would either overflow there
/// or look lost in portrait.
class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = DefaultTextStyle.of(context).style;
    // 1.25× the cap height reads as "the same size as the word" — a glyph
    // matched to the font size alone sits visibly small beside it.
    final glyphSize = (style.fontSize ?? 20) * 1.25;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBrandGlyph(size: glyphSize),
        const SizedBox(width: Spacing.sm),
        // `PageScaffold` hands the header role to the caller whenever the
        // custom title slot is used, so it is stated here.
        Semantics(
          header: true,
          child: Text(
            l10n.appTitle, // i18n-ignore: brand name
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Paints [AppBrandGlyph]'s shield-and-drop path in [ink].
///
/// Public so the resolved ink is assertable — whether the mark followed
/// the surrounding text or an explicit override is the whole point of
/// the widget above, and a private painter can only be checked by
/// scraping `toString`.
class AppBrandGlyphPainter extends CustomPainter {
  const AppBrandGlyphPainter(this.ink);

  /// The colour the mark is drawn in, already resolved.
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    // Work in a 108×108 coordinate system that mirrors the adaptive icon
    // viewport so the strokes line up 1:1 with the launcher icon.
    final scale = size.width / 108.0;
    canvas.save();
    canvas.scale(scale);

    final strokePaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;

    // Shield outline.
    final shield = Path()
      ..moveTo(54, 24)
      ..lineTo(78, 32)
      ..lineTo(78, 58)
      ..cubicTo(78, 72, 68, 82, 54, 86)
      ..cubicTo(40, 82, 30, 72, 30, 58)
      ..lineTo(30, 32)
      ..close();
    canvas.drawPath(shield, strokePaint);

    // Fuel drop.
    final drop = Path()
      ..moveTo(54, 38)
      ..cubicTo(54, 38, 42, 52, 42, 62)
      ..cubicTo(42, 69.18, 47.37, 75, 54, 75)
      ..cubicTo(60.63, 75, 66, 69.18, 66, 62)
      ..cubicTo(66, 52, 54, 38, 54, 38)
      ..close();
    canvas.drawPath(drop, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AppBrandGlyphPainter oldDelegate) =>
      oldDelegate.ink != ink;
}
