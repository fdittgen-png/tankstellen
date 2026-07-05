// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Libre / F-Droid no-op stub for `mobile_scanner` (#3477, epic #3473).
///
/// Provides the exact Dart surface `qr_scanner_screen.dart` compiles against so
/// the libre flavor builds, while carrying NO native code and NO
/// `com.google.mlkit.*` references. It is never reached at runtime on libre:
/// [QrScannerScreen] selects the FOSS `ZxingScannerView` when
/// `AppFlavor.isLibre` and never constructs this controller or widget — this
/// only needs to COMPILE.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Torch (flashlight) state — mirrors the real enum. On the stub the state is
/// always [unavailable], so the AppBar torch button renders nothing (and on
/// libre it is never built anyway).
enum TorchState { off, on, unavailable }

/// Value stand-in for the real `MobileScannerState`. Only [torchState] is read.
class MobileScannerState {
  const MobileScannerState({this.torchState = TorchState.unavailable});

  final TorchState torchState;
}

/// No-op stand-in for `MobileScannerController`. Implements
/// [ValueListenable] so it can be handed to the torch `ValueListenableBuilder`,
/// and exposes the async `toggleTorch` / `dispose` the screen awaits.
class MobileScannerController implements ValueListenable<MobileScannerState> {
  @override
  MobileScannerState get value =>
      const MobileScannerState(torchState: TorchState.unavailable);

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  Future<void> toggleTorch() async {}

  Future<void> dispose() async {}
}

/// A single decoded barcode. Only [rawValue] is read by the app.
class Barcode {
  const Barcode({this.rawValue});

  final String? rawValue;
}

/// A decode event carrying zero or more [barcodes].
class BarcodeCapture {
  const BarcodeCapture({this.barcodes = const []});

  final List<Barcode> barcodes;
}

/// No-op stand-in for the `MobileScanner` camera-preview widget. Renders
/// nothing and never emits a decode — never built on libre.
class MobileScanner extends StatelessWidget {
  const MobileScanner({
    super.key,
    this.controller,
    this.onDetect,
  });

  final MobileScannerController? controller;
  final void Function(BarcodeCapture)? onDetect;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
