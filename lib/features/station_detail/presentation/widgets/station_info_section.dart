import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/presentation/widgets/amenity_chips.dart';

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
            title: const Text('24h/24 — Automate'),
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

        // Available fuels
        if (station.availableFuels.isNotEmpty) ...[
          Text(l10n?.fuels ?? 'Fuels', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...station.availableFuels.map((f) => Chip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: DarkModeColors.successSurface(context),
                    side: BorderSide(color: DarkModeColors.success(context).withValues(alpha: 0.4)),
                  )),
              ...station.unavailableFuels.map((f) => Chip(
                    label: Text(f, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, decoration: TextDecoration.lineThrough)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  )),
            ],
          ),
          const SizedBox(height: 24),
        ],

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

        // Services (raw text from API) — at the bottom
        if (station.services.isNotEmpty) ...[
          Text(l10n?.services ?? 'Services', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
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
      ],
    );
  }
}
