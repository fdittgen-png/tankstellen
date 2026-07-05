// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

/// FOSS QR camera surface for the libre / F-Droid build (#3477, epic #3473).
///
/// The GMS-free replacement for the `mobile_scanner` (ML Kit) camera preview:
/// `flutter_zxing`'s [ReaderWidget] wraps libzxing (FFI) over the `camera`
/// plugin, so it carries ZERO `com.google.*` code. Selected only when
/// [AppFlavor.isLibre] — Play + iOS keep `mobile_scanner` untouched.
///
/// This is intentionally thin: the hosting [QrScannerScreen] owns the camera
/// permission gate, the decode timeout, the frame overlay and the guidance
/// caption (all plugin-agnostic), so this widget only turns a decoded QR into
/// a single [onValue] callback with the raw string. The parent's `_scanned`
/// latch de-dupes, so emitting once per frame is fine.
class ZxingScannerView extends StatelessWidget {
  const ZxingScannerView({super.key, required this.onValue});

  /// Called with the raw text of the first valid QR decode.
  final ValueChanged<String> onValue;

  @override
  Widget build(BuildContext context) {
    return ReaderWidget(
      // QR only — the app scans TankSync-pairing / payment QR codes, never
      // 1D barcodes; narrowing the format speeds decoding and avoids false
      // positives.
      codeFormat: Format.qrCode,
      // The parent draws [QrScanFrameOverlay] + the guidance caption and owns
      // the permission/timeout chrome, so suppress zxing's own overlay and the
      // gallery / camera-toggle buttons. Keep the flashlight toggle — the
      // libre build has no AppBar torch button (that one is mobile_scanner's).
      showScannerOverlay: false,
      showGallery: false,
      showToggleCamera: false,
      onScan: (Code code) {
        final text = code.text;
        if (code.isValid && text != null && text.isNotEmpty) {
          onValue(text);
        }
      },
    );
  }
}
