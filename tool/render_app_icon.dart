// Reproducible generator for the Sparkilo app icon (#1756).
//
// Renders the canonical app glyph — the white shield + fuel-drop from the
// Android adaptive-icon vector `android/app/.../drawable/ic_launcher_foreground.xml`
// on the `#2E7D32` green background — and writes it to:
//   * the Play Store listing icons (512x512), and
//   * every size in the iOS `AppIcon.appiconset`.
// so both stores publish the icon users actually see on-device.
//
// This is NOT a CI test — it lives in `tool/` (CI only runs `test/`). Run
// it by hand whenever the launcher glyph changes:
//
//   flutter test tool/render_app_icon.dart
//
// The geometry below is a 1:1 transcription of `ic_launcher_foreground.xml`
// (108x108 viewport); keep the two in sync. Icons are full-bleed and
// fully opaque — the App Store rejects alpha, and both stores apply
// their own corner mask.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Play Store listing-icon targets — 512x512, all byte-identical.
const _playStoreTargets = <String>[
  'assets/play_store_icon_512.png',
  'fastlane/metadata/android/en-US/images/icon.png',
  'fastlane/metadata/android/fr-FR/images/icon.png',
  'fastlane/metadata/android/de-DE/images/icon.png',
];

/// iOS `AppIcon.appiconset` files → their pixel size.
const _iosIconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _iosIcons = <String, int>{
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-50x50@1x.png': 50,
  'Icon-App-50x50@2x.png': 100,
  'Icon-App-57x57@1x.png': 57,
  'Icon-App-57x57@2x.png': 114,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-72x72@1x.png': 72,
  'Icon-App-72x72@2x.png': 144,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

const _green = ui.Color(0xFF2E7D32); // ic_launcher_background
const _white = ui.Color(0xFFFFFFFF);
const _viewport = 108.0; // ic_launcher_foreground.xml viewport

/// Renders the shield+drop icon at [px] x [px] and returns opaque PNG bytes.
Future<Uint8List> _renderIcon(int px) async {
  final scale = px / _viewport;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Full-bleed opaque green background.
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()),
    ui.Paint()..color = _green,
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
      ..color = _white,
  );

  // Fuel drop — white teardrop fill.
  final drop = ui.Path()
    ..moveTo(54, 38)
    ..cubicTo(54, 38, 42, 52, 42, 62)
    ..cubicTo(42, 69.18, 47.37, 75, 54, 75)
    ..cubicTo(60.63, 75, 66, 69.18, 66, 62)
    ..cubicTo(66, 52, 54, 38, 54, 38)
    ..close();
  canvas.drawPath(
    drop,
    ui.Paint()
      ..isAntiAlias = true
      ..color = _white,
  );

  // Liquid highlight inside the drop — green at 25% alpha (over white).
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
      ..color = _green.withValues(alpha: 0.25),
  );

  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    throw StateError('PNG encoding failed for ${px}px icon');
  }
  // `dart:ui` always encodes RGBA. The App Store rejects an alpha
  // channel on the marketing icon, so re-encode as opaque truecolor
  // (no alpha) — every pixel is opaque already (full-bleed background).
  final decoded = img.decodePng(data.buffer.asUint8List());
  if (decoded == null) {
    throw StateError('PNG decode failed for ${px}px icon');
  }
  return Uint8List.fromList(
    img.encodePng(decoded.convert(numChannels: 3)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render the Play Store + iOS Sparkilo shield+drop icons', () async {
    final icon512 = await _renderIcon(512);
    for (final path in _playStoreTargets) {
      File(path).writeAsBytesSync(icon512);
      // ignore: avoid_print
      print('wrote $path (512px, ${icon512.length} bytes)');
    }

    for (final entry in _iosIcons.entries) {
      final png = await _renderIcon(entry.value);
      File('$_iosIconDir/${entry.key}').writeAsBytesSync(png);
      // ignore: avoid_print
      print('wrote $_iosIconDir/${entry.key} (${entry.value}px)');
    }
  });
}
