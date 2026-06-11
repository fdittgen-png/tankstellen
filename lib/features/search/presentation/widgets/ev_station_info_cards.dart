// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/ev/charging_station.dart';
import '../../../../core/domain/ev/ev_access_cost.dart';
import '../../../../core/domain/ev/ev_price.dart';
import 'ev_connector_tile.dart';

/// Address card for an EV charging station.
class EVAddressCard extends StatelessWidget {
  final ChargingStation station;

  const EVAddressCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postCode = station.postCode ?? '';
    final place = station.place ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.address ?? '',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (postCode.isNotEmpty || place.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  '$postCode $place'.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                PriceFormatter.formatDistance(station.dist),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connectors card showing all available connectors for an EV station.
class EVConnectorsCard extends StatelessWidget {
  final ChargingStation station;
  final Color evColor;

  const EVConnectorsCard({
    super.key,
    required this.station,
    required this.evColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.electrical_services, color: evColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.evConnectors(station.totalPoints),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...station.connectors.map((c) => EVConnectorTile(connector: c)),
            if (station.connectors.isEmpty)
              Text(
                l10n.evNoConnectors,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pricing card for an EV station.
class EVPricingCard extends StatelessWidget {
  final ChargingStation station;
  final Color evColor;

  const EVPricingCard({
    super.key,
    required this.station,
    required this.evColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final cost = station.accessCost;
    final usageCost = station.usageCost?.trim() ?? '';
    final hasUsageCost = usageCost.isNotEmpty;

    // #2616 — structured per-kWh / per-session price hint, mirroring the
    // list-card pattern (`ev_station_card.dart`). `EvPrice.label` returns null
    // for free / unparseable strings, so those keep falling through to the
    // existing neutral raw-text rendering below.
    final evPrice = EvPrice.parse(usageCost);
    final priceLabel = evPrice.label(
      perKwhUnit: l10n.refuelUnitPerKwh,
      perSessionUnit: l10n.refuelUnitPerSession,
    );

    // Honest-UX (#2618): the structured free/paid/membership chip is the
    // only confirmed signal — it gets the leading badge. The raw scraped
    // `usageCost` text is rendered NEUTRALLY (never as a bold colored
    // price) and always carries the operator-declared disclaimer so it
    // can never masquerade as a verified comparison price.
    if (cost.isKnown || hasUsageCost) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments, color: evColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.evUsageCost,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (cost.isKnown) ...[
                const SizedBox(height: 12),
                _EvPriceBadge(kind: cost.kind),
              ],
              if (hasUsageCost) ...[
                // #2616 — when the raw text parses to a structured per-kWh /
                // per-session amount, surface it as a prominent labelled line
                // (prefixed with the "Indicative price" qualifier) ABOVE the
                // neutral raw text. Free / unparseable strings leave
                // [priceLabel] null and skip straight to the raw rendering.
                if (priceLabel != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${l10n.evPriceIndicative}: '
                    '$priceLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: evColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  usageCost,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.evPriceDeclaredByOperator,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                // #2616 — best-effort attribution for OCM-sourced pricing. The
                // IRVE line (below) and this caption are mutually exclusive:
                // IRVE stations carry the IRVE attribution, every other usage-
                // cost station gets this best-effort line.
                if (!station.isFranceIrveEnriched) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.evPriceBestEffortOcm,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
              if (station.isFranceIrveEnriched) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.evPriceFranceAttribution,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(Icons.payments, color: theme.colorScheme.outline),
        title: Text(l10n.evUsageCost),
        subtitle: Text(
          l10n.evPricingUnavailable,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Confirmed free/paid/membership access chip for an EV station (#2618).
///
/// The ONLY place the bold, colour-coded price style is used — the raw
/// scraped `usageCost` text never gets this treatment (honest-UX).
class _EvPriceBadge extends StatelessWidget {
  final EvAccessCostKind kind;

  const _EvPriceBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final (IconData icon, String label, Color fg, Color bg) = switch (kind) {
      EvAccessCostKind.free => (
        Icons.money_off,
        l10n.evPriceFree,
        // Eco / green — reuse the tertiary "positive" surface.
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
      ),
      EvAccessCostKind.paid => (
        Icons.payments,
        l10n.evPricePayAtLocation,
        scheme.onErrorContainer,
        scheme.errorContainer,
      ),
      EvAccessCostKind.membership => (
        Icons.card_membership,
        l10n.evPriceMembership,
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
      // Never rendered — the caller gates on `cost.isKnown`.
      EvAccessCostKind.unknown => (
        Icons.help_outline,
        '',
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Last updated card with attribution for an EV station.
class EVLastUpdatedCard extends StatelessWidget {
  final ChargingStation station;

  const EVLastUpdatedCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.update, size: 20),
                const SizedBox(width: 8),
                Text(l10n.evLastUpdated),
                const Spacer(),
                Text(
                  station.updatedAt ?? (l10n.evUnknown),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.evDataAttribution,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.evStatusDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
