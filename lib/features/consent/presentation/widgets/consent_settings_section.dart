import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            l10n?.gdprSettingsHint ??
                'You can change your privacy choices at any time.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          secondary: const Icon(Icons.my_location, size: 20),
          title: Text(l10n?.gdprLocationTitle ?? 'Location Access'),
          subtitle: Text(
            l10n?.gdprLocationShort ??
                'Find nearby fuel stations using your location',
            style: theme.textTheme.bodySmall,
          ),
          value: consent.location,
          onChanged: (v) => ref.read(gdprConsentProvider.notifier).save(
                location: v,
                errorReporting: consent.errorReporting,
                cloudSync: consent.cloudSync,
                communityWaitTime: consent.communityWaitTime,
                vinOnlineDecode: consent.vinOnlineDecode,
                syncTrips: consent.syncTrips,
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.bug_report_outlined, size: 20),
          title: Text(l10n?.gdprErrorReportingTitle ?? 'Error Reporting'),
          subtitle: Text(
            l10n?.gdprErrorReportingShort ??
                'Send anonymous crash reports to improve the app',
            style: theme.textTheme.bodySmall,
          ),
          value: consent.errorReporting,
          onChanged: (v) => ref.read(gdprConsentProvider.notifier).save(
                location: consent.location,
                errorReporting: v,
                cloudSync: consent.cloudSync,
                communityWaitTime: consent.communityWaitTime,
                vinOnlineDecode: consent.vinOnlineDecode,
                syncTrips: consent.syncTrips,
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_outlined, size: 20),
          title: Text(l10n?.gdprCloudSyncTitle ?? 'Cloud Sync'),
          subtitle: Text(
            l10n?.gdprCloudSyncShort ??
                'Sync favorites and alerts across devices',
            style: theme.textTheme.bodySmall,
            maxLines: collapsedMaxLines(),
            overflow: collapsedOverflow(),
          ),
          value: consent.cloudSync,
          onChanged: (v) => ref.read(gdprConsentProvider.notifier).save(
                location: consent.location,
                errorReporting: consent.errorReporting,
                cloudSync: v,
                communityWaitTime: consent.communityWaitTime,
                vinOnlineDecode: consent.vinOnlineDecode,
                syncTrips: consent.syncTrips,
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.timer_outlined, size: 20),
          title:
              Text(l10n?.gdprCommunityWaitTimeTitle ?? 'Community Wait Times'),
          subtitle: Text(
            l10n?.gdprCommunityWaitTimeShort ??
                'Anonymously share station wait times',
            style: theme.textTheme.bodySmall,
            maxLines: collapsedMaxLines(),
            overflow: collapsedOverflow(),
          ),
          value: consent.communityWaitTime,
          onChanged: (v) => ref.read(gdprConsentProvider.notifier).save(
                location: consent.location,
                errorReporting: consent.errorReporting,
                cloudSync: consent.cloudSync,
                communityWaitTime: v,
                vinOnlineDecode: consent.vinOnlineDecode,
                syncTrips: consent.syncTrips,
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.directions_car_outlined, size: 20),
          title: Text(l10n?.gdprVinOnlineDecodeTitle ?? 'VIN online decode'),
          subtitle: Text(
            l10n?.gdprVinOnlineDecodeShort ??
                "Decode the VIN via NHTSA's free public service",
            style: theme.textTheme.bodySmall,
            maxLines: collapsedMaxLines(),
            overflow: collapsedOverflow(),
          ),
          value: consent.vinOnlineDecode,
          onChanged: (v) => ref.read(gdprConsentProvider.notifier).save(
                location: consent.location,
                errorReporting: consent.errorReporting,
                cloudSync: consent.cloudSync,
                communityWaitTime: consent.communityWaitTime,
                vinOnlineDecode: v,
                syncTrips: consent.syncTrips,
              ),
        ),
        // #1479 phase 1 — trip-sync consent. Sits LAST so the
        // historical 0..4 SwitchListTile indices in older tests stay
        // stable. Gated on the master Cloud Sync above; the toggle
        // is disabled (onChanged: null) when cloudSync is off and the
        // provider's `save()` enforces effective-false when
        // cloudSync=false so the visible position stays honest.
        SwitchListTile(
          key: const Key('consentSyncTripsToggle'),
          secondary: const Icon(Icons.route_outlined, size: 20),
          title: Text(l10n?.consentSyncTripsTitle ?? 'Sync trip recordings'),
          subtitle: Text(
            consent.cloudSync
                ? (l10n?.consentSyncTripsSubtitle ??
                    'Back up OBD2 + GPS trips to TankSync. '
                        'Cross-device, opt-in.')
                : (l10n?.consentSyncTripsDisabledHint ??
                    'Enable Cloud Sync above to back up trips.'),
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
                    communityWaitTime: consent.communityWaitTime,
                    vinOnlineDecode: consent.vinOnlineDecode,
                    syncTrips: v,
                  )
              : null,
        ),
        // #1529 — section-level expand toggle for the 4 collapsed
        // subtitles (Cloud Sync, Community Wait Times, VIN online
        // decode, Sync trip recordings). The first two consents
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
              _expanded
                  ? (l10n?.consentHideDetails ?? 'Hide details')
                  : (l10n?.consentShowDetails ?? 'Show details'),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}
