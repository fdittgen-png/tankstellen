// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// The five GDPR consent switches, one row each (#3909, Epic #3907).
///
/// Reads [gdprConsentProvider] and writes through its `save()` — the
/// write path is unchanged from the former `ConsentSettingsSection`:
/// every row re-saves the other four values as they are.
///
/// #1479 phase 1 — the `Sync trip recordings` row is gated on the
/// master `Cloud Sync` consent; disabling Cloud Sync force-clears it at
/// the provider layer (`effectiveSyncTrips`).
///
/// Every subtitle wraps freely (no `maxLines`), so no row ever
/// truncates — the former one-line collapse with a "Show details"
/// toggle is gone; the subtitles are the short forms.
class ConsentSwitchRows extends ConsumerWidget {
  const ConsentSwitchRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(gdprConsentProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notifier = ref.read(gdprConsentProvider.notifier);

    Text subtitle(String text) =>
        Text(text, style: theme.textTheme.bodySmall);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('consentLocationToggle'),
          secondary: const Icon(Icons.my_location, size: 20),
          title: Text(l10n.gdprLocationTitle),
          subtitle: subtitle(l10n.gdprLocationShort),
          value: consent.location,
          onChanged: (v) => notifier.save(
            location: v,
            errorReporting: consent.errorReporting,
            cloudSync: consent.cloudSync,
            vinOnlineDecode: consent.vinOnlineDecode,
            syncTrips: consent.syncTrips,
          ),
        ),
        SwitchListTile(
          key: const Key('consentErrorReportingToggle'),
          secondary: const Icon(Icons.bug_report_outlined, size: 20),
          title: Text(l10n.gdprErrorReportingTitle),
          subtitle: subtitle(l10n.gdprErrorReportingShort),
          value: consent.errorReporting,
          onChanged: (v) => notifier.save(
            location: consent.location,
            errorReporting: v,
            cloudSync: consent.cloudSync,
            vinOnlineDecode: consent.vinOnlineDecode,
            syncTrips: consent.syncTrips,
          ),
        ),
        SwitchListTile(
          key: const Key('consentCloudSyncToggle'),
          secondary: const Icon(Icons.cloud_outlined, size: 20),
          title: Text(l10n.gdprCloudSyncTitle),
          subtitle: subtitle(l10n.gdprCloudSyncShort),
          value: consent.cloudSync,
          onChanged: (v) => notifier.save(
            location: consent.location,
            errorReporting: consent.errorReporting,
            cloudSync: v,
            vinOnlineDecode: consent.vinOnlineDecode,
            syncTrips: consent.syncTrips,
          ),
        ),
        SwitchListTile(
          key: const Key('consentVinDecodeToggle'),
          secondary: const Icon(Icons.directions_car_outlined, size: 20),
          title: Text(l10n.gdprVinOnlineDecodeTitle),
          subtitle: subtitle(l10n.gdprVinOnlineDecodeShort),
          value: consent.vinOnlineDecode,
          onChanged: (v) => notifier.save(
            location: consent.location,
            errorReporting: consent.errorReporting,
            cloudSync: consent.cloudSync,
            vinOnlineDecode: v,
            syncTrips: consent.syncTrips,
          ),
        ),
        // #1665/#3448/#3884 — the trip-sync consent sits next to the
        // Cloud Sync master it depends on (one home per parameter). An
        // anonymous UUID is a full identity (#3448), so there is no email
        // requirement. Disabled (with a hint) while Cloud Sync is off.
        SwitchListTile(
          key: const Key('tripsSyncToggle'),
          secondary: const Icon(Icons.route_outlined, size: 20),
          title: Text(l10n.consentSyncTripsTitle),
          subtitle: subtitle(
            consent.cloudSync
                ? l10n.consentSyncTripsSubtitle
                : l10n.consentSyncTripsDisabledHint,
          ),
          value: consent.syncTrips,
          onChanged: consent.cloudSync
              ? (v) => notifier.save(
                    location: consent.location,
                    errorReporting: consent.errorReporting,
                    cloudSync: consent.cloudSync,
                    vinOnlineDecode: consent.vinOnlineDecode,
                    syncTrips: v,
                  )
              : null,
        ),
      ],
    );
  }
}
