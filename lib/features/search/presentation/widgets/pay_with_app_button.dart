import 'package:flutter/material.dart';

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

  const PayWithAppButton({
    super.key,
    required this.brand,
    this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final app = paymentAppForBrand(brand);
    if (app == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final label = l10n?.payWithApp(app.displayName) ??
        'Pay with ${app.displayName}';

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
      debugPrint('PayWithAppButton launch failed: $e\n$st');
    }
  }
}
