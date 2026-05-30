// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The capture button on the pump-display camera screen.
///
/// Owns the capture gate so it can be unit-tested without a live camera
/// (#2477): the button is disabled while a capture is already running
/// **or** while the phone is held portrait — a portrait shot lands the
/// wide pump display's digits sideways and small, so it must be blocked
/// until the user rotates to landscape.
class PumpShutterButton extends StatelessWidget {
  /// `true` while a capture is in flight.
  final bool isCapturing;

  /// `true` while the device is portrait (capture blocked).
  final bool isPortrait;

  /// Fired only when capture is allowed.
  final VoidCallback onCapture;

  const PumpShutterButton({
    super.key,
    required this.isCapturing,
    required this.isPortrait,
    required this.onCapture,
  });

  /// Whether the shutter currently accepts a tap.
  bool get enabled => !isCapturing && !isPortrait;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: enabled ? onCapture : null,
      icon: const Icon(Icons.camera_alt),
      label: Text(l10n?.pumpCameraCapture ?? 'Capture'),
    );
  }
}
