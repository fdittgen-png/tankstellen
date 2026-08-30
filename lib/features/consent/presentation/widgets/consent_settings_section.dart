// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Section widget for changing GDPR consent choices in Settings.
///
/// Reads current consent state from [gdprConsentProvider] and allows
/// the user to toggle individual consents on/off.
///
/// #1479 phase 1 — adds the `Sync trip recordings` toggle, gated on
/// the master `Cloud Sync` consent. Disabling Cloud Sync also force-
/// disables Sync trips at the provider layer (`save()`'s
/// `effectiveSyncTrips`), so the UI stays in sync with the persisted
/// state without an extra round-trip.
///
/// #1529 — subtitle compaction. The first two consents (Location +
/// Error Reporting) keep their full description because they're the
/// most consequential / most likely to be touched on a given visit.
/// The other four collapse their subtitle to a single ellipsised
/// line by default, with a "Show details" / "Hide details" affordance
/// at the bottom of the section to flip every collapsed row open at
/// once. Saves ~250 dp on subsequent visits while keeping the toggle
/// surface tap-friendly.
class ConsentSettingsSection extends ConsumerStatefulWidget {
  const ConsentSettingsSection({super.key});

  @override
  ConsumerState<ConsentSettingsSection> createState() =>
      _ConsentSettingsSectionState();
}

class _ConsentSettingsSectionState
    extends ConsumerState<ConsentSettingsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(gdprConsentProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Helper for the 4 collapsible subtitles: when _expanded, render
    // full text; otherwise constrain to a single ellipsised line.
    int? collapsedMaxLines() => _expanded ? null : 1;
    TextOverflow? collapsedOverflow() =>
        _expanded ? null : TextOverflow.ellipsis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.gdprSettingsHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          secondary: const Icon(Icons.my_location, size: 20),
          title: Text(l10n.gdprLocationTitle),
          subtitle: Text(
            l10n.gdprLocationShort,
            style: theme.textTheme.bodySmall,
          ),
          value: consent.location,
          onChanged: (v) => ref
              .read(gdprConsentProvider.notifier)
              .save(
                location: v,
                errorReporting: consent.errorReporting,
                cloudSync: consent.cloudSync,
                vinOnlineDecode: consent.vinOnlineDecode,
                syncTrips: consent.syncTrips,
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.bug_report_outlined, size: 20),
          title: Text(l10n.gdprErrorReportingTitle),
          subtitle: Text(
            l10n.gdprErrorReportingShort,
            style: theme.textTheme.bodySmall,
          ),
          value: consent.errorReporting,
          onChanged: (v) => ref
              .read(gdprConsentProvider.notifier)
              .save(
                location: consent.location,
                errorReporting: v,
                cloudSync: consent.cloudSync,
                vinOnlineDecode: consent.vinOnlineDecode,
                syncTrips: consent.syncTrips,
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_outlined, size: 20),
          title: Text(l10n.gdprCloudSyncTitle),
          subtitle: Text(
            l10n.gdprCloudSyncShort,
            style: theme.textTheme.bodySmall,
            maxLines: collapsedMaxLines(),
            overflow: collapsedOverflow(),
          ),
          value: consent.cloudSync,
          onChanged: (v) => ref
              .read(gdprConsentProvider.notifier)
              .save(
                location: consent.location,
                errorReporting: consent.errorReporting,
                cloudSync: v,
                vinOnlineDecode: consent.vinOnlineDecode,
                syncTrips: consent.syncTrips,
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.directions_car_outlined, size: 20),
          title: Text(l10n.gdprVinOnlineDecodeTitle),
          subtitle: Text(
            l10n.gdprVinOnlineDecodeShort,
            style: theme.textTheme.bodySmall,
            maxLines: collapsedMaxLines(),
            overflow: collapsedOverflow(),
          ),
          value: consent.vinOnlineDecode,
          onChanged: (v) => ref
              .read(gdprConsentProvider.notifier)
              .save(
                location: consent.location,
                errorReporting: consent.errorReporting,
                cloudSync: consent.cloudSync,
                vinOnlineDecode: v,
                syncTrips: consent.syncTrips,
              ),
        ),
        // #1665/#3448/#3884 — the trajet-sync consent is back HERE, next to
        // the Cloud Sync master it depends on (one home per parameter;
        // #3884). An anonymous UUID is a full identity (#3448), so there
        // is no email requirement — the TankSync section keeps a
        // cross-link to this screen instead of a second switch. Disabled
        // (with a hint) while Cloud Sync is off; the provider also
        // force-clears it when Cloud Sync is revoked (`effectiveSyncTrips`).
        SwitchListTile(
          key: const Key('tripsSyncToggle'),
          secondary: const Icon(Icons.route_outlined, size: 20),
          title: Text(l10n.consentSyncTripsTitle),
          subtitle: Text(
            consent.cloudSync
                ? l10n.consentSyncTripsSubtitle
                : l10n.consentSyncTripsDisabledHint,
            style: theme.textTheme.bodySmall,
            maxLines: collapsedMaxLines(),
            overflow: collapsedOverflow(),
          ),
          value: consent.syncTrips,
          onChanged: consent.cloudSync
              ? (v) => ref.read(gdprConsentProvider.notifier).save(
                    location: consent.location,
                    errorReporting: consent.errorReporting,
                    cloudSync: consent.cloudSync,
                    vinOnlineDecode: consent.vinOnlineDecode,
                    syncTrips: v,
                  )
              : null,
        ),
        // #1529 — section-level expand toggle for the 3 collapsed
        // subtitles (Cloud Sync, Community Wait Times, VIN online
        // decode). The first two consents
        // (Location, Error Reporting) keep their full text always
        // because they're the ones a user is most likely to revisit.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('consentSubtitleExpandToggle'),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            label: Text(
              _expanded ? (l10n.consentHideDetails) : (l10n.consentShowDetails),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        // #3866 (Epic #3865) — the consent record (Art. 7(1): demonstrable
        // consent) and the policy it refers to, one tap away.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            consent.recordedAt == null
                ? l10n.consentNotRecorded
                : l10n.consentRecordedAt(
                    MaterialLocalizations.of(context).formatMediumDate(
                        consent.recordedAt!.toLocal()),
                    consent.policyVersion),
            key: const Key('consentRecordFooter'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('consentPolicyLink'),
            onPressed: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl),
                mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.gdprPolicyLink(AppConstants.privacyPolicyVersion)),
          ),
        ),
      ],
    );
  }
}
