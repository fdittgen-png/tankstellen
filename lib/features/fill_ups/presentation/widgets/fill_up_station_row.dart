// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';

/// #3899 — the station row of the "Where you were" section on the Add
/// fill-up form. Shows the station chosen on the picker screen (name +
/// address) as a read-only field with a "Change" text action that
/// re-opens the picker; without a station it reads "Pick a station" and
/// tapping it opens the picker too. Replaces the old banner above the
/// cards (#581 / #751) so the station lives in ONE place — next to the
/// odometer and notes the section header promises.
class FillUpStationRow extends StatelessWidget {
  /// Station name (brand) — null when the form was opened without one.
  final String? stationName;

  /// One-line address, null when the station is unknown to the app
  /// (e.g. a fill-up logged from a station that is not cached).
  final String? address;

  /// Opens the station picker.
  final VoidCallback onChange;

  const FillUpStationRow({
    super.key,
    required this.stationName,
    required this.address,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = stationName;
    final addressLine = address;
    final hasStation = name != null && name.isNotEmpty;
    return Semantics(
      button: true,
      child: InkWell(
        key: const Key('fill_up_station_row'),
        onTap: onChange,
        borderRadius: AppRadius.md,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l.fillUpStationLabel,
            prefixIcon: const Icon(Icons.local_gas_station_outlined),
            border: const OutlineInputBorder(),
            suffix: Text(
              hasStation ? l.fillUpStationChange : '',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            suffixIcon: hasStation ? null : const Icon(Icons.chevron_right),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasStation ? name : l.pickStationTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasStation && addressLine != null && addressLine.isNotEmpty)
                Text(
                  addressLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
