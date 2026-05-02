import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Section widget for changing GDPR consent choices in Settings.
///
/// Reads current consent state from [gdprConsentProvider] and allows
/// the user to toggle individual consents on/off.
class ConsentSettingsSection extends ConsumerWidget {
  const ConsentSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(gdprConsentProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
              ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_outlined, size: 20),
          title: Text(l10n?.gdprCloudSyncTitle ?? 'Cloud Sync'),
          subtitle: Text(
            l10n?.gdprCloudSyncShort ??
                'Sync favorites and alerts across devices',
            style: theme.textTheme.bodySmall,
          ),
          value: consent.cloudSync,
          onChanged: (v) => ref.read(gdprConsentProvider.notifier).save(
                location: consent.location,
                errorReporting: consent.errorReporting,
                cloudSync: v,
                communityWaitTime: consent.communityWaitTime,
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
          ),
          value: consent.communityWaitTime,
          onChanged: (v) => ref.read(gdprConsentProvider.notifier).save(
                location: consent.location,
                errorReporting: consent.errorReporting,
                cloudSync: consent.cloudSync,
                communityWaitTime: v,
              ),
        ),
      ],
    );
  }
}
