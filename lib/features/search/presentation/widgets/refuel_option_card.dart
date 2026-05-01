import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/refuel/refuel_availability.dart';
import '../../../../core/refuel/refuel_option.dart';
import '../../../../core/refuel/refuel_price.dart';
import '../../../../core/refuel/refuel_provider.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';

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
/// ### Phase-1/2 limitations the widget intentionally inherits
///
/// * The abstract [RefuelOption] interface does NOT (yet) expose a
///   street address or a precomputed distance. This widget therefore
///   does not render either. The [showDistanceAtRight] flag is plumbed
///   for forward compatibility — phase 4 may add `distanceMeters` to
///   the interface and the gate will then control visibility without a
///   breaking change to call sites that already pass the flag today.
/// * Adding those fields to [RefuelOption] would be a phase-1/2 change
///   and is out of scope here (see issue #1116 phase plan).
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
              _AvailabilityDot(availability: option.availability),
              const SizedBox(width: 12),
              Icon(
                _kindIcon,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                    const SizedBox(height: 2),
                    Text(
                      _availabilityLabel(option.availability, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PriceColumn(price: option.price, l10n: l10n),
              // Distance placeholder — phase-4 hook (see class doc).
              if (showDistanceAtRight) const _DistanceSlot(),
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

/// Coloured availability dot. Mirrors the success / warning / error
/// palette the existing `EVStationCard` and `StationCard` use so the
/// unified card sits visually flush in a mixed list.
class _AvailabilityDot extends StatelessWidget {
  final RefuelAvailability availability;

  const _AvailabilityDot({required this.availability});

  @override
  Widget build(BuildContext context) {
    final color = switch (_kindOf(availability)) {
      _AvailabilityKind.open => DarkModeColors.success(context),
      _AvailabilityKind.limited => DarkModeColors.warning(context),
      _AvailabilityKind.closed => DarkModeColors.error(context),
      _AvailabilityKind.unknown =>
        Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
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

/// Phase-4 placeholder for the trailing distance widget. The
/// [RefuelOption] interface does not expose distance today; this
/// reserves the layout slot so the gate's visibility behaviour is
/// stable when the field lands.
class _DistanceSlot extends StatelessWidget {
  const _DistanceSlot();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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
