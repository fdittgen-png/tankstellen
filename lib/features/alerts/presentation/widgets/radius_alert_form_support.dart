// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/radius_alert_validators.dart';

/// Pure helpers + small widgets behind the zone-alert sheet's #3905
/// intuitiveness pass: the price-based default threshold, the
/// "why is Save disabled" line and the chosen-location chip.

/// Discount applied to the local reference price to seed the threshold:
/// an alert that fires "5 % below what the fuel costs around me today".
const double kRadiusAlertThresholdDiscount = 0.05;

/// Seed threshold when no local price is known (the pre-#3905 constant).
const double kRadiusAlertFallbackThreshold = 1.5;

/// Where the alert centre came from — drives the chip label.
enum RadiusAlertCenterKind { gps, map, postal }

/// The first unmet Save requirement, in the order
/// [RadiusAlertValidators.canSave] checks them.
enum RadiusAlertSaveBlocker { label, threshold, location }

/// Mirrors [RadiusAlertValidators.canSave] but answers WHICH rule fails
/// first (`null` when Save is allowed), so the sheet can say why instead
/// of greying out the button silently.
RadiusAlertSaveBlocker? firstSaveBlocker({
  required String label,
  required String thresholdRaw,
  required double? centerLat,
  required double? centerLng,
}) {
  if (label.trim().isEmpty) return RadiusAlertSaveBlocker.label;
  final threshold = RadiusAlertValidators.parseThreshold(thresholdRaw);
  if (threshold == null || threshold <= 0) {
    return RadiusAlertSaveBlocker.threshold;
  }
  if (centerLat == null || centerLng == null) {
    return RadiusAlertSaveBlocker.location;
  }
  return null;
}

/// "Current local price minus 5 %, rounded DOWN to 3 decimals" for [fuel]
/// over [stations], or `null` when no station carries a positive price
/// for it. The local price is the MEDIAN of the sample — robust to one
/// motorway outlier or a stale zero — so the seed sits just under what
/// most stations around the user charge today.
double? suggestedThreshold(Iterable<Station> stations, FuelType fuel) {
  final prices = [
    for (final s in stations)
      if (s.priceFor(fuel) case final p? when p > 0) p,
  ]..sort();
  if (prices.isEmpty) return null;
  final mid = prices.length ~/ 2;
  final median = prices.length.isOdd
      ? prices[mid]
      : (prices[mid - 1] + prices[mid]) / 2;
  return floorToThreeDecimals(median * (1 - kRadiusAlertThresholdDiscount));
}

/// Rounds DOWN to 3 decimals (the per-litre price grain). Floors rather
/// than rounds so the seed never lands ABOVE the discounted price. A
/// binary-float artefact just under a whole thousandth (2.1 × 0.95 =
/// 1.99499999…) counts as that thousandth, not the one below.
double floorToThreeDecimals(double value) {
  final scaled = value * 1000;
  final nearest = scaled.roundToDouble();
  final base = (nearest - scaled).abs() < 1e-6 ? nearest : scaled.floorToDouble();
  return base / 1000;
}

/// Formats a threshold for the text field with the active locale's
/// decimal separator ("1,499" in FR / DE, "1.499" in GB) — the same
/// [UnitFormatter] path every other price figure in the app uses.
String formatThreshold(double value) =>
    UnitFormatter.formatDecimal(value, fractionDigits: 3);

/// Chip naming the chosen alert centre ("My position" / "Map point" /
/// "Postal code 34550") with a clear action, shown under the two
/// location buttons so the user can see WHAT is bound before saving.
class RadiusAlertCenterChip extends StatelessWidget {
  const RadiusAlertCenterChip({
    super.key,
    required this.kind,
    required this.onClear,
    this.postalCode = '',
  });

  final RadiusAlertCenterKind kind;
  final VoidCallback onClear;
  final String postalCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, icon) = switch (kind) {
      RadiusAlertCenterKind.gps => (
        l10n.radiusAlertCenterChipGps,
        Icons.my_location,
      ),
      RadiusAlertCenterKind.map => (
        l10n.radiusAlertCenterChipMap,
        Icons.place_outlined,
      ),
      RadiusAlertCenterKind.postal => (
        l10n.radiusAlertCenterChipPostal(postalCode),
        Icons.markunread_mailbox_outlined,
      ),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InputChip(
        key: const Key('radius_alert_center_chip'),
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onDeleted: onClear,
        deleteButtonTooltipMessage: l10n.radiusAlertCenterClear,
      ),
    );
  }
}

/// One-line helper under the location buttons naming the FIRST unmet
/// Save requirement. Renders nothing when Save is enabled.
class RadiusAlertSaveBlockerHint extends StatelessWidget {
  const RadiusAlertSaveBlockerHint({super.key, required this.blocker});

  final RadiusAlertSaveBlocker? blocker;

  @override
  Widget build(BuildContext context) {
    final blocker = this.blocker;
    if (blocker == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = switch (blocker) {
      RadiusAlertSaveBlocker.label => l10n.radiusAlertBlockerLabel,
      RadiusAlertSaveBlocker.threshold => l10n.radiusAlertBlockerThreshold,
      RadiusAlertSaveBlocker.location => l10n.radiusAlertBlockerLocation,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              key: const Key('radius_alert_save_blocker'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
