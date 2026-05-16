// Reproducible generator for the Sparkilo Play Store listing icon (#1756).
//
// Renders the canonical app glyph — the white shield + fuel-drop from the
// Android adaptive-icon vector `android/app/.../drawable/ic_launcher_foreground.xml`
// on the `#2E7D32` green background — to a 512x512 PNG, and writes it to
// every Play Store listing-icon path so `fastlane supply` publishes the
// icon users actually see on-device.
//
// This is NOT a CI test — it lives in `tool/` (CI only runs `test/`). Run
// it by hand whenever the launcher glyph changes:
//
//   flutter test tool/render_app_icon.dart
//
// The geometry below is a 1:1 transcription of `ic_launcher_foreground.xml`
// (108x108 viewport); keep the two in sync.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Play Store listing-icon targets — all kept byte-identical.
const _targets = <String>[
  'assets/play_store_icon_512.png',
  'fastlane/metadata/android/en-US/images/icon.png',
  'fastlane/metadata/android/fr-FR/images/icon.png',
  'fastlane/metadata/android/de-DE/images/icon.png',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render the 512x512 Sparkilo shield+drop Play Store icon', () async {
    const px = 512;
    const viewport = 108.0; // ic_launcher_foreground.xml viewport
    const scale = px / viewport;

    const green = ui.Color(0xFF2E7D32); // ic_launcher_background
    const white = ui.Color(0xFFFFFFFF);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Full-bleed green background — Play Console applies its own mask.
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 512, 512),
      ui.Paint()..color = green,
    );
    canvas.scale(scale);

    // Shield outline — white stroke, 4dp, rounded joins.
    final shield = ui.Path()
      ..moveTo(54, 24)
      ..lineTo(78, 32)
      ..lineTo(78, 58)
      ..cubicTo(78, 72, 68, 82, 54, 86)
      ..cubicTo(40, 82, 30, 72, 30, 58)
      ..lineTo(30, 32)
      ..close();
    canvas.drawPath(
      shield,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..isAntiAlias = true
        ..color = white,
    );

    // Fuel drop — white teardrop fill.
    final drop = ui.Path()
      ..moveTo(54, 38)
      ..cubicTo(54, 38, 42, 52, 42, 62)
      ..cubicTo(42, 69.18, 47.37, 75, 54, 75)
      ..cubicTo(60.63, 75, 66, 69.18, 66, 62)
      ..cubicTo(66, 52, 54, 38, 54, 38)
      ..close();
    canvas.drawPath(drop, ui.Paint()..isAntiAlias = true..color = white);

    // Liquid highlight inside the drop — green at 25% alpha.
    final highlight = ui.Path()
      ..moveTo(50, 60)
      ..cubicTo(50, 57, 51.5, 55, 53, 55)
      ..cubicTo(54.5, 55, 55, 57, 54, 60)
      ..cubicTo(53, 62, 51.5, 62.5, 50.5, 62)
      ..cubicTo(49.8, 61.5, 49.8, 60.8, 50, 60)
      ..close();
    canvas.drawPath(
      highlight,
      ui.Paint()
        ..isAntiAlias = true
        ..color = green.withValues(alpha: 0.25),
    );

    final image = await recorder.endRecording().toImage(px, px);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull, reason: 'PNG encoding must succeed');
    final png = data!.buffer.asUint8List();

    for (final path in _targets) {
      File(path).writeAsBytesSync(png);
      // ignore: avoid_print
      print('wrote $path (${png.length} bytes)');
    }
  });
}
