// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'station_card.dart';

/// Small badge rendered under the headline when a loyalty / fuel-club
/// card applies (#1120 pilot). Shows the per-litre discount, the
/// canonical brand name, and a struck-through raw price so the user
/// can read both the headline number and the operator's quoted price
/// at once.
class _LoyaltyDiscountBadge extends StatelessWidget {
  final Station station;
  final double discount;
  final double rawPrice;
  final String? currencyOverride;

  const _LoyaltyDiscountBadge({
    required this.station,
    required this.discount,
    required this.rawPrice,
    required this.currencyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final canonical = BrandRegistry.canonicalize(station.brand) ?? '';
    final prefix = l.loyaltyBadgePrefix;
    final discountStr = PriceFormatter.formatPrice(
      discount,
      currencyOverride: currencyOverride,
    );
    final rawStr = PriceFormatter.formatPrice(
      rawPrice,
      currencyOverride: currencyOverride,
    );
    final badgeStyle = AppText.label(context).copyWith(
      color: theme.colorScheme.onPrimaryContainer,
    );
    return Container(
      margin: const EdgeInsets.only(top: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md - Spacing.xs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '$prefix$discountStr ${canonical.isEmpty ? '' : canonical}'
                  .trim(),
              style: badgeStyle.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            rawStr,
            style: badgeStyle.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.7,
              ),
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Displays 1-5 small star icons for the user's station rating.
class _RatingStars extends StatelessWidget {
  final int rating;

  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 12,
          color: i < rating ? Colors.amber : Colors.grey.shade400,
        );
      }),
    );
  }
}
