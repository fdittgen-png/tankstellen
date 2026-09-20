// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/widgets/animated_favorite_star.dart';
import '../../../../core/widgets/animated_price_text.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/domain/refuel_comparison_selection.dart';
import '../../../../core/widgets/refuel_compare_button.dart';
import '../../../../l10n/app_localizations.dart';
import 'station_card_badges.dart';
import 'station_presentation.dart';

/// The card's headline row (#3949): brand mark, the display-role price
/// with its baseline-aligned unit and the colour-blind tier arrow, then —
/// pushed to the trailing edge — the Cheapest badge and the favourite
/// star.
///
/// The price is never truncated — it is the ONE number the card exists to
/// show. It owns the row's remaining width and, when a raised text scale
/// on a 320 dp screen leaves less room than its natural width, it scales
/// down whole (a `FittedBox`) rather than ellipsising to `1,7…`. The
/// Cheapest badge is width-capped and ellipsises first under an expanded
/// translation; the 32×32 star keeps its tap target.
class StationCardHeadlineRow extends ConsumerWidget {
  final Station station;

  /// #4133 — everything this row shows, derived once by
  /// [StationPresentation]. It used to take price, discount, currency,
  /// brand mark and fuel label as five separate arguments and re-derive
  /// the effective price from two of them.
  final StationPresentation presentation;

  final bool isFavorite;
  final bool isCheapest;
  final PriceTier? priceTier;
  final VoidCallback? onFavoriteTap;

  const StationCardHeadlineRow({
    super.key,
    required this.station,
    required this.presentation,
    required this.isFavorite,
    required this.isCheapest,
    required this.priceTier,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = presentation;
    final hasDiscount = p.hasDiscount;
    // #4363 — the comparison toggle joins the row only once a comparison
    // exists. The row sits exactly on its structural widget budget
    // (#4163, `station_row_budget_test.dart`), and a control that every
    // visible station pays for on every filter change so that some
    // drivers can compare is the wrong trade. A long press on the row
    // opens the comparison (`SwipeableStationCard`); from then on each
    // row carries the explicit toggle and its selected state.
    final comparing = ref.watch(refuelComparisonSelectionProvider
        .select((selection) => selection.isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (p.brandMark != null) ...[
              // The row's own semantic label already names the brand;
              // letting the mark announce it again would read the brand
              // twice on every card. #3940 — the slot stays SQUARE: a Row
              // lays its non-flex children out unbounded, so there is no
              // measured room for a wide wordmark here.
              ExcludeSemantics(
                child: BrandLogo(brand: station.brand, size: 34),
              ),
              const SizedBox(width: Spacing.md),
            ],
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: _PriceHeadline(
                    station: station,
                    price: p.price,
                    rawPrice: p.rawPrice,
                    hasDiscount: hasDiscount,
                    currencyOverride: p.currencySymbol,
                    priceTier: priceTier,
                    substitutedFuelLabel: p.substitutedFuelLabel,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            if (isCheapest) ...[
              ConstrainedBox(
                // #4123 — was 88, which fits the English "Cheapest" and
                // ellipsises the French superlative to "Le moins ch…".
                // "Le moins cher" cannot be shortened to "Moins cher":
                // that is the comparative (cheaper), and this badge means
                // THE cheapest. So the slot gives way, not the wording.
                // The price beside it is already `Expanded`, so it yields
                // first and nothing overflows.
                constraints: const BoxConstraints(maxWidth: 120),
                child: const _CheapestBadge(),
              ),
              const SizedBox(width: Spacing.sm),
            ],
            if (comparing)
              RefuelCompareButton(station: station, compact: true),
            // #2622 — the favourite star keeps its 32×32 tap target +
            // tooltip; #3949 moves it onto the headline row's trailing
            // edge so the price owns the row's leading edge.
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: AnimatedFavoriteStar(isFavorite: isFavorite, size: 22),
                // #2974 — a selection tick on the favourite toggle,
                // matching the everyday tap-surface haptics. selectionClick
                // only (never heavyImpact); fires only on the discrete star
                // tap, never scroll.
                onPressed: onFavoriteTap == null
                    ? null
                    : () {
                        unawaited(HapticFeedback.selectionClick());
                        onFavoriteTap!();
                      },
                tooltip: isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
              ),
            ),
          ],
        ),
        if (hasDiscount)
          StationCardLoyaltyBadge(
            station: station,
            discount: p.loyaltyDiscount!,
            rawPrice: p.rawPrice!,
            currencyOverride: p.currencySymbol,
          ),
      ],
    );
  }
}

/// The display-role price: `[↓] 1,79⁹ €/L`, number and unit on one
/// baseline ([AppText.display] + [AppText.unit]).
///
/// The number is the theme's `onSurface` — the fuel colour lives on the
/// card's stripe, the price band on the tier arrow — and greys to
/// `onSurfaceVariant` only for a KNOWN-closed station (#3198: unknown keeps
/// the full colour, the price data is valid).
class _PriceHeadline extends StatelessWidget {
  final Station station;
  final double? price;
  final double? rawPrice;
  final bool hasDiscount;
  final String? currencyOverride;
  final PriceTier? priceTier;

  /// #4124 — non-null when the price shown is NOT the fuel the user
  /// asked for: that fuel's pump code, rendered beside the number.
  final String? substitutedFuelLabel;

  const _PriceHeadline({
    required this.station,
    required this.price,
    required this.rawPrice,
    required this.hasDiscount,
    required this.currencyOverride,
    required this.priceTier,
    this.substitutedFuelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final closed = station.isOpen == false;
    final numberStyle = closed
        ? AppText.display(context).copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )
        : AppText.display(context);
    final tier = priceTier;
    final showTier = tier != null && tier != PriceTier.unknown;
    final currency = currencyOverride ?? PriceFormatter.currency;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (showTier)
          // #3926 — the ↓ / – / ↑ glyph is a PRICE TIER inside the CURRENT
          // result set (`priceTierOf` splits the listed stations' min-to-
          // max range for the selected fuel into thirds), never a movement
          // against an earlier price. It is the colour-blind reading of
          // the map's colour ramp, so it stays on the card (#3949).
          Padding(
            padding: const EdgeInsets.only(right: Spacing.xs),
            child: Tooltip(
              message: _priceTierTooltip(l10n, tier),
              child: Icon(
                iconForPriceTier(tier),
                size: 18,
                color: numberStyle.color,
                semanticLabel: _priceTierTooltip(l10n, tier),
              ),
            ),
          ),
        AnimatedPriceText(
          price: price,
          child: Tooltip(
            // #1120 — when a loyalty discount applies, the tooltip surfaces
            // the un-discounted raw price so power users can verify what
            // the operator quoted.
            message: hasDiscount
                ? l10n.loyaltyRawPriceTooltip(
                    PriceFormatter.formatPrice(
                      rawPrice,
                      currencyOverride: currencyOverride,
                    ),
                  )
                : '',
            child: RichText(
              maxLines: 1,
              text: _displayPriceSpan(price, numberStyle),
            ),
          ),
        ),
        if (price != null && price! > 0) ...[
          const SizedBox(width: Spacing.sm),
          Text(
            l10n.stationCardPriceUnit(currency),
            style: AppText.unit(context),
          ),
        ],
        // #4124 — name the fuel when it is NOT the one asked for. #2400
        // settled this question already and `shortFuelLabel` was written
        // for it; the caller that used it was lost somewhere since, which
        // is how a French E85 at 0,82 came to sit in the same column as a
        // Spanish E5 at 1,62 with nothing to tell them apart.
        //
        // Language-neutral pump code, in the unit role beside the unit:
        // this qualifies the number, it is not prose about it.
        if (substitutedFuelLabel case final label?) ...[
          const SizedBox(width: Spacing.xs),
          Tooltip(
            message: l10n.priceIsForFuel(label),
            child: Text(
              label,
              style: AppText.unit(context).copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The display number with the 9/10ths digit in superscript — the
/// standard forecourt price form (`1,79⁹`) — and NO currency: the unit is
/// rendered separately in [AppText.unit] so the number can be the display
/// role and the unit the label role, on one baseline.
///
/// Mirrors [PriceFormatter.priceTextSpan] minus its trailing ` €`, which
/// would put the currency symbol at 36 sp.
TextSpan _displayPriceSpan(double? price, TextStyle style) {
  if (price == null || price <= 0) {
    // The same language-neutral "no price" mask PriceFormatter renders.
    return TextSpan(text: '--', style: style);
  }
  final full = PriceFormatter.formatPriceCompact(price);
  final base = full.substring(0, full.length - 1);
  final tenths = full.substring(full.length - 1);
  final size = style.fontSize ?? 14;
  return TextSpan(
    style: style,
    children: [
      TextSpan(text: base),
      WidgetSpan(
        alignment: PlaceholderAlignment.top,
        child: Transform.translate(
          offset: Offset(0, -size * 0.2),
          child: Text(
            tenths,
            style: style.copyWith(
              fontSize: size * 0.65,
              fontFeatures: const [FontFeature.superscripts()],
            ),
          ),
        ),
      ),
    ],
  );
}

/// Wording for the card's price-tier glyph (#3926). The tier is relative
/// to the OTHER stations currently listed — the bottom, middle or top
/// third of their price range for the selected fuel — so every string
/// says "in this list" rather than implying a movement over time.
String _priceTierTooltip(AppLocalizations l10n, PriceTier tier) =>
    switch (tier) {
      PriceTier.cheap => l10n.searchPriceArrowCheapTooltip,
      PriceTier.average => l10n.searchPriceArrowAverageTooltip,
      PriceTier.expensive => l10n.searchPriceArrowExpensiveTooltip,
      PriceTier.unknown => '',
    };

/// The "Cheapest" badge (#2622) — success-tinted, label role, on the
/// headline row's trailing edge so it anchors the bestStops-default list
/// beside the number it qualifies.
class _CheapestBadge extends StatelessWidget {
  const _CheapestBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md - Spacing.xs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: DarkModeColors.successSurface(context),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        l10n.cheapest,
        style: AppText.label(context).copyWith(
          fontWeight: FontWeight.bold,
          color: DarkModeColors.success(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
