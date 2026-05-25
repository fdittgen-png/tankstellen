// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/presentation/widgets/amenity_chips.dart';
import '../../../search/presentation/widgets/pay_with_app_button.dart';
import '../../../search/presentation/widgets/payment_method_chips.dart';

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
    // The opening-hours section now also short-circuits when there's
    // nothing meaningful to say (not 24h, no `openingHoursText`, empty
    // `detail.openingTimes`). The previous behaviour rendered a full
    // ListTile with a literal `—`, costing ~60 dp of vertical space for
    // zero user value. With both blocks gone in the common French-API
    // case (no opening hours surfaced by the upstream feed), the screen
    // fits inside the viewport on a Pixel-class device.
    final hasOpeningInfo = station.is24h ||
        (station.openingHoursText != null &&
            station.openingHoursText!.isNotEmpty) ||
        detail.openingTimes.isNotEmpty;

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
          if (station.is24h)
            ListTile(
              leading:
                  Icon(Icons.schedule, color: DarkModeColors.success(context)),
              title: Text(l10n?.automate24h ?? '24h/24 — Automate'),
            )
          else if (station.openingHoursText != null &&
              station.openingHoursText!.isNotEmpty)
            ...station.openingHoursText!.split('\n').map((line) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.schedule),
                  title: Text(line.trim()),
                ))
          else
            ...detail.openingTimes.map((ot) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.schedule),
                  title: Text(ot.text),
                  trailing: Text(
                      '${ot.start.substring(0, 5)} – ${ot.end.substring(0, 5)}'),
                )),
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
