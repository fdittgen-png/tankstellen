// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/utils/payment_app_launcher.dart';
import '../../../../l10n/app_localizations.dart';

/// A "Pay with X" button surfaced on the station detail screen when
/// the station's brand has a known branded payment app.
///
/// Renders nothing when the brand is unknown or blank. Tap opens the
/// app if installed, otherwise falls back to the Play Store so users
/// can install it. Layout matches the filled-tonal affordance used
/// elsewhere in the detail screen.
class PayWithAppButton extends StatelessWidget {
  final String brand;

  /// Override for tests; production uses [PaymentAppLauncher.open].
  final Future<bool> Function(PaymentApp app)? onLaunch;

  const PayWithAppButton({super.key, required this.brand, this.onLaunch});

  @override
  Widget build(BuildContext context) {
    final app = paymentAppForBrand(brand);
    if (app == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final label = l10n.payWithApp(app.displayName);

    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        onPressed: () => _launch(app),
        icon: const Icon(Icons.open_in_new),
        label: Text(label),
      ),
    );
  }

  Future<void> _launch(PaymentApp app) async {
    final launcher = onLaunch ?? PaymentAppLauncher.open;
    try {
      await launcher(app);
    } on Exception catch (e, st) {
      // #2146 — route to the exportable log so a missing deep-link
      // handler is visible from a bug report.
      unawaited(
        errorLogger.log(
          ErrorLayer.ui,
          e,
          st,
          context: {
            'where': 'PayWithAppButton._launch',
            'app': app.displayName,
          },
        ),
      );
    }
  }
}
