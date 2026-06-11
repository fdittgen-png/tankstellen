// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/country/country_time.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/presentation/widgets/amenity_chips.dart';
import '../../../search/presentation/widgets/pay_with_app_button.dart';
import '../../../search/presentation/widgets/payment_method_chips.dart';
import '../../domain/legacy_opening_hours_bridge.dart';
import '../../domain/opening_hours.dart';
import 'opening_hours_view.dart';

/// Address, opening hours, fuels, services, and location info for a station.
///
/// #923 phase 3f — the five plain-text `titleMedium` sub-headings
/// (Address / Opening hours / Zone / Amenities / Payment methods)
/// are rendered through the canonical [SectionHeader] so the headings
/// share the design-system role, weight, and color with every other
/// section on the screen. The body stays in a single Column — the
/// screen already owns outer card-vs-card spacing via its parent
/// [SizedBox]s and the section layout was not wrapped in a Card before
/// this migration, so no visual regressions are introduced here. The
/// bottom `ExpansionTile` for "Services (N)" keeps its own
/// `titleMedium` label because that slot is an ExpansionTile title,
/// not a stand-alone section heading.
class StationInfoSection extends StatelessWidget {
  final Station station;
  final StationDetail detail;

  const StationInfoSection({
    super.key,
    required this.station,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #1996 — the dedicated "Address" block was pure duplication: the
    // street is already in the collapsing AppBar header, the user does
    // not need to read `38 Avenue de Verdun` twice on the same screen.
    // Postal code + place + the "directions" affordance live on the
    // sliver-app-bar's brand-header / status row, so dropping the whole
    // block here is purely a compaction win — no information is lost.
    //
    // Opening hours (#2709) — the three legacy branches (is24h ListTile /
    // `openingHoursText` newline-split / `openingTimes`) are replaced by
    // the structured [OpeningHoursView]. The schedule resolves from the
    // adapter-populated `detail.openingHours` when present, falling back
    // through [legacyOpeningHoursBridge] so countries whose opening-hours
    // adapter has not yet landed still render via the migration bridge.
    // The whole section is elided when the resolved schedule carries no
    // data (the common French-API case), so the screen still fits inside
    // the viewport on a Pixel-class device.
    final WeeklyOpeningHours hours =
        detail.openingHours ?? legacyOpeningHoursBridge(detail);
    final hasOpeningInfo =
        hours.availability != OpeningHoursAvailability.notProvided;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opening times — section + content fully elided when empty.
        if (hasOpeningInfo) ...[
          SectionHeader(
            title: l10n?.openingHours ?? 'Opening hours',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          // #3198 — evaluate "open now" on the STATION's wall clock, not
          // the device's: weekly hours are local to the pump, so browsing
          // a foreign country from home used to flip every open/closed
          // status by the timezone gap. Unknown country → device clock.
          OpeningHoursView(
            hours: hours,
            now: nowInCountry(Countries.countryForStation(
              id: station.id,
              lat: station.lat,
              lng: station.lng,
            )?.code),
          ),
          const SizedBox(height: 12),
        ],

        // Location info
        if (station.department != null || station.region != null) ...[
          SectionHeader(
            title: l10n?.zone ?? 'Zone',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            leading: const Icon(Icons.map),
            title: Text([station.department, station.region]
                .whereType<String>()
                .join(', ')),
            subtitle: station.stationType == 'A'
                ? Text(l10n?.highway ?? 'Highway')
                : Text(l10n?.localStation ?? 'Local station'),
          ),
          const SizedBox(height: 12),
        ],

        // Amenities (icon chips) — at the bottom
        if (station.amenities.isNotEmpty) ...[
          SectionHeader(
            title: l10n?.amenities ?? 'Amenities',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          AmenityChips(amenities: station.amenities, maxVisible: 8),
          const SizedBox(height: 12),
        ],

        // Payment methods (inferred from brand — no API data available)
        if (station.brand.trim().isNotEmpty) ...[
          SectionHeader(
            title: l10n?.paymentMethods ?? 'Payment methods',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          PaymentMethodChips(brand: station.brand, maxVisible: 8),
          const SizedBox(height: 8),
          PayWithAppButton(brand: station.brand),
          const SizedBox(height: 12),
        ],

        // Services (raw text from API) — at the bottom, collapsed by
        // default (#483). Highway stations routinely return 10+ services
        // and previously pushed the price-history section far below the
        // fold. The ExpansionTile lets users see which services exist at
        // a glance (via the count in the title) without blowing out the
        // visual balance of the screen.
        if (station.services.isNotEmpty)
          Theme(
            // Strip the default ExpansionTile dividers so it blends
            // with the surrounding Column layout.
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const ValueKey('station-detail-services-expansion'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              initiallyExpanded: false,
              title: Semantics(
                header: true,
                child: Text(
                  '${l10n?.services ?? "Services"} '
                  '(${station.services.length})',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: station.services.map((s) => Chip(
                        avatar: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
