// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Centred icon + message + actions shown by [PumpDisplayCameraScreen]
/// when the camera can't run — permission denied or hardware failure
/// (#1868). Extracted from the screen so the camera file stays focused
/// on capture and orientation logic (#2477).
///
/// Always offers a Cancel button (pops the route); shows an optional
/// retry button when [onRetry] is supplied.
class PumpCameraMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Future<void> Function()? onRetry;
  final String? retryLabel;

  const PumpCameraMessage({
    super.key,
    required this.icon,
    required this.text,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (retry != null) ...[
                  OutlinedButton(
                    onPressed: () => retry(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      retryLabel ?? AppLocalizations.of(context).retry,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
