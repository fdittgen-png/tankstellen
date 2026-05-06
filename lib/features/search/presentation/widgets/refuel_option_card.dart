import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/refuel/refuel_availability.dart';
import '../../../../core/refuel/refuel_option.dart';
import '../../../../core/refuel/refuel_price.dart';
import '../../../../core/refuel/refuel_provider.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../ev/domain/entities/charging_station.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/station.dart';
import 'amenity_chips.dart';

/// Coarse-grained discriminator for [RefuelAvailability]. The sealed
/// class's subtypes are private (`_Open`, `_Closed`, `_Limited`,
/// `_Unknown`) — phase 1 deliberately exposed only the public
/// singletons + factories, so this widget cannot pattern-match on the
/// concrete subtype. We bridge that here with a lightweight string
/// dispatch on the deterministic `toString` prefix; phase 4 may
/// promote this to a public enum on the sealed class itself.
enum _AvailabilityKind { open, limited, closed, unknown }

_AvailabilityKind _kindOf(RefuelAvailability availability) {
  if (availability == RefuelAvailability.open) return _AvailabilityKind.open;
  if (availability == RefuelAvailability.unknown) {
    return _AvailabilityKind.unknown;
  }
  // The remaining cases (`_Closed` / `_Limited`) have deterministic
  // `toString` prefixes. They cannot collide with the singletons above
  // because the equality short-circuits handled those already.
  final repr = availability.toString();
  if (repr.startsWith('RefuelAvailability.limited')) {
    return _AvailabilityKind.limited;
  }
  if (repr.startsWith('RefuelAvailability.closed')) {
    return _AvailabilityKind.closed;
  }
  return _AvailabilityKind.unknown;
}

/// Best-effort reason text for the [RefuelAvailability] subtypes that
/// carry one (`_Limited` always, `_Closed` optionally). Returns `null`
/// when the subtype carries no reason, so the caller can fall back to
/// a generic localized label.
String? _reasonOf(RefuelAvailability availability) {
  // toString format: `RefuelAvailability.<kind>(reason: <reason>)`
  final repr = availability.toString();
  final match = RegExp(r'\(reason: (.*)\)$').firstMatch(repr);
  if (match == null) return null;
  final raw = match.group(1);
  if (raw == null || raw == 'null' || raw.isEmpty) return null;
  return raw;
}

/// Polymorphic card that renders any [RefuelOption] — fuel pump or EV
/// charger — with a single visual shape.
///
/// Phase 3b of the fuel/EV unification (#1116). Phase 3a's
/// `unifiedSearchResultsProvider` returns `List<RefuelOption>`; this is
/// the visual building block phase 3c will wire into the search-results
/// list (behind the `unifiedSearchResultsEnabled` flag).
///
/// The widget reads ONLY the abstract [RefuelOption] interface — no
/// downcasts to [Station] / [ChargingStation]. The icon, availability
/// chip, and price suffix all branch on [RefuelProviderKind] /
/// [RefuelPriceUnit] from the contract surface phase 1 introduced.
///
/// ### What is and isn't shown
///
/// * **Title**: [RefuelProvider.name]. When the provider is unknown
///   (empty name, e.g. a station with no upstream brand) the card falls
///   back to the kind label so the row never collapses to an empty
///   string.
/// * **Leading**: [Icons.local_gas_station] for fuel,
///   [Icons.ev_station] for EV (and mixed-site `both` providers).
/// * **Availability**: small coloured dot mirroring the
///   `EVStationCard` / `StationCard` palette — green for open, amber
///   for limited, red for closed, neutral for unknown.
/// * **Trailing**: numeric price + unit suffix when the option exposes
///   a price; em-dash placeholder otherwise (matches
///   [PriceFormatter.formatPriceCompact]).
///
/// ### Phase-4 enrichment (#1116)
///
/// The abstract [RefuelOption] interface now exposes [address],
/// [distanceMeters], [is24h], and [lastUpdated]. The card renders all
/// four so fuel pumps and EV chargers reach visual parity with the
/// legacy `StationCard`. [showDistanceAtRight] still controls whether
/// the distance label appears under the title — kept as a parameter
/// for the handful of forward-compat call sites that already pass it.
class RefuelOptionCard extends ConsumerWidget {
  /// The unified [RefuelOption] this card renders.
  final RefuelOption option;

  /// Optional tap handler — wraps the card in an [InkWell] when set.
  final VoidCallback? onTap;

  /// Forward-compat gate for the trailing distance widget (phase 4).
  /// Defaults to `true` so future call sites get distance for free
  /// once the interface exposes it.
  final bool showDistanceAtRight;

  const RefuelOptionCard({
    super.key,
    required this.option,
    this.onTap,
    this.showDistanceAtRight = true,
  });

  bool get _isEv =>
      option.provider.kind == RefuelProviderKind.ev ||
      option.provider.kind == RefuelProviderKind.both;

  IconData get _kindIcon =>
      _isEv ? Icons.ev_station : Icons.local_gas_station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final providerName = option.provider.name;
    final title = providerName.isNotEmpty
        ? providerName
        : _kindFallbackLabel(l10n);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: theme.brightness == Brightness.dark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusColumn(
                availability: option.availability,
                is24h: option.is24h,
              ),
              const SizedBox(width: 12),
              Icon(
                _kindIcon,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailsColumn(
                  title: title,
                  option: option,
                  showDistance: showDistanceAtRight,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 8),
              _PriceColumn(price: option.price, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }

  String _kindFallbackLabel(AppLocalizations? l10n) {
    // Fallback to a non-localized neutral string if l10n isn't bound.
    if (l10n == null) return _isEv ? 'EV' : 'Fuel';
    return _isEv ? l10n.evUnknown : l10n.unavailable;
  }
}

/// Coloured status dot with an optional `24h` badge underneath.
/// Mirrors the legacy `StationCard._StatusColumn` so the unified card
/// sits visually flush in a mixed list.
class _StatusColumn extends StatelessWidget {
  final RefuelAvailability availability;
  final bool is24h;

  const _StatusColumn({required this.availability, required this.is24h});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (_kindOf(availability)) {
      _AvailabilityKind.open => DarkModeColors.success(context),
      _AvailabilityKind.limited => DarkModeColors.warning(context),
      _AvailabilityKind.closed => DarkModeColors.error(context),
      _AvailabilityKind.unknown =>
        Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        if (is24h)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '24h',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Title + address + (distance · updated-ago) block. Mirrors the
/// legacy `StationCard._StationDetails` line stack so a fuel pump and
/// an EV charger render with the same density.
class _DetailsColumn extends StatelessWidget {
  final String title;
  final RefuelOption option;
  final bool showDistance;
  final AppLocalizations? l10n;

  const _DetailsColumn({
    required this.title,
    required this.option,
    required this.showDistance,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addr = option.address;
    final hasAddr = addr.isNotEmpty;
    final secondaryRow = _secondaryRowParts(context);
    final source = option.source;
    // Fuel-only extra: the rich amenity-icon chip strip the legacy
    // StationCard renders. We downcast `source` for this kind-specific
    // bit per the phase-5 (#1116) seam — generic consumers must still
    // not depend on the concrete type.
    final fuelAmenities = source is Station ? source.amenities : null;
    // EV-only extra: connector summary row (max kW + connector status
    // count + connector types). Driven entirely off the wrapped
    // ChargingStation; null for fuel-side options.
    final evStats =
        source is ChargingStation ? _evStatsOf(source) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasAddr) ...[
          const SizedBox(height: 2),
          Text(
            addr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Always show at least one info row — when no distance / updated /
        // address are present we fall back to the availability label so
        // the card never collapses to a single bare title line.
        const SizedBox(height: 2),
        secondaryRow.isEmpty
            ? Text(
                _availabilityLabel(option.availability, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Row(
                children: secondaryRow,
              ),
        if (evStats != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _EvStatsRow(stats: evStats),
          ),
        if (fuelAmenities != null && fuelAmenities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AmenityChips(amenities: fuelAmenities),
          ),
      ],
    );
  }

  List<Widget> _secondaryRowParts(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <Widget>[];

    final distMeters = option.distanceMeters;
    if (showDistance && distMeters != null) {
      parts.add(
        Flexible(
          child: Text(
            PriceFormatter.formatDistance(distMeters / 1000.0),
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final updated = option.lastUpdated;
    if (updated != null) {
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 8));
      parts.add(Icon(
        Icons.update,
        size: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ));
      parts.add(const SizedBox(width: 2));
      parts.add(Flexible(
        child: Text(
          _formatRelative(updated, l10n),
          style: theme.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    return parts;
  }
}

/// Compact "X min" / "X h" / "X d" formatter for the updated-at
/// marker. Units are abbreviated to single letters that read the same
/// across all 23 supported locales — avoids adding a new l10n key
/// (and the corresponding French-completeness test edits) for what is
/// essentially a one-character glyph next to the [Icons.update] icon.
String _formatRelative(DateTime when, AppLocalizations? l10n) {
  final delta = DateTime.now().difference(when);
  if (delta.inMinutes < 1) return '<1 min';
  if (delta.inMinutes < 60) return '${delta.inMinutes} min';
  if (delta.inHours < 24) return '${delta.inHours} h';
  return '${delta.inDays} d';
}

/// Cheap value object the EV stats row consumes. Computed inline by
/// [_evStatsOf]; not exported because the unified card is the only
/// renderer that needs it.
class _EvStats {
  final double maxPowerKw;
  final int totalConnectors;
  final int availableConnectors;
  final List<String> connectorTypeLabels;

  const _EvStats({
    required this.maxPowerKw,
    required this.totalConnectors,
    required this.availableConnectors,
    required this.connectorTypeLabels,
  });
}

/// Derive the EV stats row data from the wrapped [ChargingStation].
/// Lives here (rather than on the adapter) because it is purely a
/// rendering concern — the adapter contract stays kind-agnostic.
_EvStats _evStatsOf(ChargingStation station) {
  final connectors = station.connectors;
  double maxKw = 0;
  var available = 0;
  final typeKeys = <String>{};
  for (final c in connectors) {
    if (c.maxPowerKw > maxKw) maxKw = c.maxPowerKw;
    if (c.status == ConnectorStatus.available) available++;
    typeKeys.add(c.type.key.toUpperCase());
  }
  // [ChargingStation.totalPoints] sometimes carries the upstream's
  // bay count, but per-row connector data is more reliable. Fall back
  // to totalPoints only when the connector list is empty (sparse
  // OpenChargeMap rows).
  final total = connectors.isNotEmpty
      ? connectors.length
      : station.totalPoints;
  return _EvStats(
    maxPowerKw: maxKw,
    totalConnectors: total,
    availableConnectors: available,
    connectorTypeLabels: typeKeys.toList()..sort(),
  );
}

/// Compact one-line summary for an EV charger:
/// `350 kW · 2 / 4 · CCS, Type2`. Lives under the distance/updated row
/// on EV cards so the user sees the EV-relevant numbers (kW, available
/// connectors, types) without tapping through to detail.
class _EvStatsRow extends StatelessWidget {
  final _EvStats stats;

  const _EvStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    if (stats.maxPowerKw > 0) {
      // Render kW as integer when whole, one decimal otherwise — keeps
      // "350 kW" tidy while still surfacing "22.5 kW" if the upstream
      // uses fractional values.
      final kw = stats.maxPowerKw;
      final kwText = kw == kw.roundToDouble()
          ? kw.toStringAsFixed(0)
          : kw.toStringAsFixed(1);
      parts.add('$kwText kW');
    }
    if (stats.totalConnectors > 0) {
      parts.add('${stats.availableConnectors} / ${stats.totalConnectors}');
    }
    if (stats.connectorTypeLabels.isNotEmpty) {
      // Cap the connector-type list at three to keep the row from
      // wrapping on small screens — extras are summarised as "+N".
      final visible = stats.connectorTypeLabels.take(3).join(', ');
      final extra = stats.connectorTypeLabels.length - 3;
      parts.add(extra > 0 ? '$visible +$extra' : visible);
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(
          Icons.electrical_services,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            parts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Right-side numeric price + unit suffix.
class _PriceColumn extends StatelessWidget {
  final RefuelPrice? price;
  final AppLocalizations? l10n;

  const _PriceColumn({required this.price, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = price;
    if (p == null) {
      return Text(
        '--',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // [RefuelPrice.value] is in cents; the formatter expects the major
    // currency unit (e.g. EUR), so divide by 100 before passing in.
    final majorUnit = p.value / 100.0;
    final priceText =
        PriceFormatter.formatPriceCompact(majorUnit);
    final unit = _unitLabel(p.unit, l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          priceText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String _availabilityLabel(
  RefuelAvailability availability,
  AppLocalizations? l10n,
) {
  final reason = _reasonOf(availability);
  return switch (_kindOf(availability)) {
    _AvailabilityKind.open => l10n?.open ?? 'Open',
    _AvailabilityKind.limited => reason ?? l10n?.unavailable ?? 'Limited',
    _AvailabilityKind.closed => reason ?? l10n?.closed ?? 'Closed',
    _AvailabilityKind.unknown => l10n?.evUnknown ?? 'Unknown',
  };
}

String _unitLabel(RefuelPriceUnit unit, AppLocalizations? l10n) {
  if (l10n == null) {
    return switch (unit) {
      RefuelPriceUnit.centsPerLiter => '/L',
      RefuelPriceUnit.centsPerKwh => '/kWh',
      RefuelPriceUnit.perSession => '/session',
    };
  }
  return switch (unit) {
    RefuelPriceUnit.centsPerLiter => l10n.refuelUnitPerLiter,
    RefuelPriceUnit.centsPerKwh => l10n.refuelUnitPerKwh,
    RefuelPriceUnit.perSession => l10n.refuelUnitPerSession,
  };
}
