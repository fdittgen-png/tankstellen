import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/payment_method.dart';

/// Displays the payment methods a station likely accepts as compact
/// icon chips. Infers the methods from the station brand.
///
/// Grouped under a single `Semantics(label: ...)` so screen readers
/// announce one coherent phrase ("Accepts: cash, card, Shell App")
/// instead of a stream of isolated chip texts (#566).
class PaymentMethodChips extends StatelessWidget {
  final String brand;

  /// Maximum number of chips to display. Extra methods show a "+N" chip.
  final int maxVisible;

  const PaymentMethodChips({
    super.key,
    required this.brand,
    this.maxVisible = 6,
  });

  @override
  Widget build(BuildContext context) {
    final methods = inferPaymentMethods(brand).toList();
    if (methods.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final appName = brandAppName(brand);

    final visible = methods.take(maxVisible).toList();
    final overflow = methods.length - maxVisible;

    final labels = visible
        .map((m) => _localizedLabel(m, l10n, appName: appName))
        .toList();

    return Semantics(
      label: '${l10n?.paymentMethods ?? 'Payment methods'}: '
          '${labels.join(', ')}',
      container: true,
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            for (var i = 0; i < visible.length; i++)
              _PaymentMethodChip(
                method: visible[i],
                label: labels[i],
                theme: theme,
              ),
            if (overflow > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$overflow',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _localizedLabel(
    PaymentMethod method,
    AppLocalizations? l10n, {
    String? appName,
  }) {
    return switch (method) {
      PaymentMethod.cash => l10n?.paymentMethodCash ?? 'Cash',
      PaymentMethod.card => l10n?.paymentMethodCard ?? 'Card',
      PaymentMethod.contactless =>
        l10n?.paymentMethodContactless ?? 'Contactless',
      PaymentMethod.fuelCard => l10n?.paymentMethodFuelCard ?? 'Fuel Card',
      PaymentMethod.app => appName ?? l10n?.paymentMethodApp ?? 'App',
    };
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final PaymentMethod method;
  final String label;
  final ThemeData theme;

  const _PaymentMethodChip({
    required this.method,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paymentMethodIcon(method),
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
