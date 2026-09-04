// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/dark_mode_colors.dart';
import '../../../../../core/theme/fuel_colors.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../core/domain/consumption_unit.dart';
import '../../../../../core/widgets/animated_price_text.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/all_prices_comparison_model.dart';

/// One cell of the all-prices fuel comparison table (#3933).
///
/// Always occupies its column, whatever the station sells — a blank cell
/// is what keeps the grid aligned across cards. Reading order top to
/// bottom: fuel grade, pump price, delta against the cheapest of the
/// current results, and the cost of 100 km on that fuel for the active
/// vehicle.
///
/// Emphasis grammar (explained once by the help bubble, never left a
/// mystery):
/// * filled in the fuel colour — cheapest for this fuel in these results;
/// * dimmed — the active vehicle cannot be filled with this fuel;
/// * `+0,06` — how much dearer than the cheapest of these results;
/// * `≈ 9,61 €` in the muted italic label style — the cost per 100 km is
///   MODELLED (#3945): the vehicle has no pure tank of this fuel, so the
///   figure is its measured consumption on another fuel converted by
///   energy content. A measured figure is bold and fuel-coloured; the two
///   must never look alike.
class FuelComparisonCell extends StatelessWidget {
  final FuelCellData data;

  /// The consumption unit the user reads figures in (Settings › Units).
  /// Used only in the spoken semantics label — the visible cell shows
  /// money, which has no unit ambiguity.
  final ConsumptionUnit consumptionUnit;

  const FuelComparisonCell({
    super.key,
    required this.data,
    this.consumptionUnit = ConsumptionUnit.lPer100Km,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final fuelColor = FuelColors.forType(data.fuel);

    final isChampion = data.isBestInResults && data.isUsable;
    final isDimmed = !data.isUsable || data.isUnavailable || data.isBlank;

    final background = isChampion
        ? fuelColor
        : isDimmed
        ? theme.colorScheme.surfaceContainerHighest
        : FuelColors.forTypeLight(data.fuel);

    final foreground = isChampion
        ? Colors.white
        : isDimmed
        ? DarkModeColors.mutedText(context)
        : theme.colorScheme.onSurface;

    return Semantics(
      label: _semanticsLabel(l10n),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isChampion
                ? fuelColor
                : isDimmed
                ? theme.colorScheme.outlineVariant
                : fuelColor.withValues(alpha: 0.45),
            width: isChampion ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _line(
              data.label,
              TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isChampion
                    ? Colors.white
                    : isDimmed
                    ? DarkModeColors.mutedText(context)
                    : fuelColor,
              ),
            ),
            const SizedBox(height: 1),
            AnimatedPriceText(
              price: data.isUnavailable ? null : data.price,
              child: _line(
                _priceText(l10n),
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
              ),
            ),
            _line(
              _deltaText(l10n),
              TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isChampion
                    ? Colors.white
                    : DarkModeColors.mutedText(context),
              ),
            ),
            if (data.costPer100km != null) ...[
              const SizedBox(height: 1),
              _line(_costText(l10n), _costStyle(context, isChampion, fuelColor)),
            ],
          ],
        ),
      ),
    );
  }

  /// The cost-per-100 km line: the plain money figure when measured, the
  /// ≈-prefixed form (ARB) when modelled.
  String _costText(AppLocalizations l10n) {
    final cost = PriceFormatter.formatTotal(data.costPer100km);
    return data.isCostEstimated ? l10n.allPricesEstimatedCost(cost) : cost;
  }

  /// Measured: bold, in the fuel colour (white on a champion cell). Modelled
  /// (#3945): the muted `AppText.label` role in italics, so a model never
  /// carries the visual weight of a measurement; the champion cell keeps
  /// white for contrast on its filled background.
  TextStyle _costStyle(BuildContext context, bool isChampion, Color fuelColor) {
    if (data.isCostEstimated) {
      final label = AppText.label(context).copyWith(
        fontSize: _costFontSize,
        fontStyle: FontStyle.italic,
      );
      return isChampion ? label.copyWith(color: Colors.white) : label;
    }
    return TextStyle(
      fontSize: _costFontSize,
      fontWeight: FontWeight.w700,
      color: isChampion ? Colors.white : fuelColor,
    );
  }

  /// One size for both provenances so the row height never depends on
  /// whether a figure was measured or modelled.
  static const double _costFontSize = 11;

  /// A single value line that shrinks rather than overflowing — the whole
  /// table has to survive en_XA at 320 dp and a 1.3x text scale, where a
  /// fixed-width column has no room to negotiate.
  Widget _line(String text, TextStyle style) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, style: style, maxLines: 1),
  );

  String _priceText(AppLocalizations l10n) {
    if (data.isUnavailable) return l10n.outOfStock;
    if (data.price == null) return l10n.allPricesNoPriceMask;
    return PriceFormatter.formatPriceCompact(data.price);
  }

  String _deltaText(AppLocalizations l10n) {
    final delta = data.deltaToBest;
    if (delta == null || data.isUnavailable) return '';
    if (delta <= 0) return l10n.allPricesBestMarker;
    return l10n.allPricesDelta(PriceFormatter.formatPriceCompact(delta));
  }

  String _semanticsLabel(AppLocalizations l10n) {
    if (data.isUnavailable) {
      return l10n.allPricesCellUnavailableSemantics(data.label);
    }
    if (data.price == null) {
      return l10n.allPricesCellNoPriceSemantics(data.label);
    }
    if (!data.isUsable) {
      return l10n.allPricesCellUnusableSemantics(data.label);
    }
    final cost = data.costPer100km;
    final l100 = data.litersPer100km;
    final price = PriceFormatter.formatPriceCompact(data.price);
    if (cost == null || l100 == null) {
      return l10n.allPricesCellPriceSemantics(data.label, price);
    }
    if (data.isCostEstimated) {
      return l10n.allPricesCellEstimatedSemantics(
        data.label,
        price,
        PriceFormatter.formatTotal(cost),
        UnitFormatter.formatConsumptionLocalized(l100, consumptionUnit),
      );
    }
    return l10n.allPricesCellCostSemantics(
      data.label,
      price,
      PriceFormatter.formatTotal(cost),
      UnitFormatter.formatConsumptionLocalized(l100, consumptionUnit),
    );
  }
}
