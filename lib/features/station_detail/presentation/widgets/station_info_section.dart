import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/presentation/widgets/amenity_chips.dart';
import '../../../search/presentation/widgets/payment_method_chips.dart';

/// Address, opening hours, fuels, services, and location info for a station.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address
        Text(l10n?.address ?? 'Address', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(
            '${station.street}${station.houseNumber != null ? ' ${station.houseNumber}' : ''}',
          ),
          subtitle: Text('${station.postCode} ${station.place}'),
          trailing: IconButton(
            icon: const Icon(Icons.directions),
            onPressed: () => NavigationUtils.openInMaps(
              station.lat, station.lng,
              label: station.displayName,
            ),
            tooltip: l10n?.navigate ?? 'Navigate',
          ),
        ),
        const SizedBox(height: 24),

        // Opening times
        Text(l10n?.openingHours ?? 'Opening hours', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (station.is24h)
          ListTile(
            leading: Icon(Icons.schedule, color: DarkModeColors.success(context)),
            title: Text(l10n?.automate24h ?? '24h/24 — Automate'),
          )
        else if (station.openingHoursText != null && station.openingHoursText!.isNotEmpty)
          ...station.openingHoursText!.split('\n').map((line) => ListTile(
                dense: true,
                leading: const Icon(Icons.schedule),
                title: Text(line.trim()),
              ))
        else if (detail.openingTimes.isNotEmpty)
          ...detail.openingTimes.map((ot) => ListTile(
                dense: true,
                leading: const Icon(Icons.schedule),
                title: Text(ot.text),
                trailing: Text('${ot.start.substring(0, 5)} – ${ot.end.substring(0, 5)}'),
              ))
        else
          const ListTile(
            dense: true,
            leading: Icon(Icons.schedule),
            title: Text('—'),
          ),
        const SizedBox(height: 24),

        // Location info
        if (station.department != null || station.region != null) ...[
          Text(l10n?.zone ?? 'Zone', style: theme.textTheme.titleMedium),
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
          const SizedBox(height: 24),
        ],

        // Amenities (icon chips) — at the bottom
        if (station.amenities.isNotEmpty) ...[
          Text(l10n?.amenities ?? 'Amenities', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          AmenityChips(amenities: station.amenities, maxVisible: 8),
          const SizedBox(height: 24),
        ],

        // Payment methods (inferred from brand — no API data available)
        if (station.brand.trim().isNotEmpty) ...[
          Text(
            l10n?.paymentMethods ?? 'Payment methods',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          PaymentMethodChips(brand: station.brand, maxVisible: 8),
          const SizedBox(height: 24),
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
