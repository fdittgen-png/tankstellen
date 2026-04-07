import 'package:flutter/material.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact price legend showing the cheap-to-expensive color gradient.
class PriceLegend extends StatelessWidget {
  const PriceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
        ],
      ),
      child: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconForPriceTier(PriceTier.cheap), size: 12, color: Colors.green),
          Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(l10n?.cheap ?? 'cheap', style: const TextStyle(fontSize: 10)),
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green, Colors.orange, Colors.red]),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          Text(l10n?.expensive ?? 'expensive', style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle)),
          Icon(iconForPriceTier(PriceTier.expensive), size: 12, color: Colors.red),
        ],
      );
      }),
    );
  }
}

/// Circular zoom/location control button for the map.
class ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ZoomButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}
