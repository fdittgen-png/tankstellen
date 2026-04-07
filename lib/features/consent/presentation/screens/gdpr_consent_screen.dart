import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// First-launch GDPR consent screen.
///
/// Shows before any data collection with toggles for:
/// - Location access
/// - Error reporting (Sentry)
/// - Cloud sync (TankSync)
///
/// Consent choices are persisted in HiveStorage and respected
/// throughout the app. Users can change choices later in Settings.
class GdprConsentScreen extends ConsumerStatefulWidget {
  const GdprConsentScreen({super.key});

  @override
  ConsumerState<GdprConsentScreen> createState() => _GdprConsentScreenState();
}

class _GdprConsentScreenState extends ConsumerState<GdprConsentScreen> {
  bool _locationConsent = false;
  bool _errorReportingConsent = false;
  bool _cloudSyncConsent = false;

  Future<void> _acceptSelected() async {
    await ref.read(gdprConsentProvider.notifier).save(
          location: _locationConsent,
          errorReporting: _errorReportingConsent,
          cloudSync: _cloudSyncConsent,
        );
    if (mounted) context.go('/setup');
  }

  Future<void> _acceptAll() async {
    await ref.read(gdprConsentProvider.notifier).save(
          location: true,
          errorReporting: true,
          cloudSync: true,
        );
    if (mounted) context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Header
                    Icon(
                      Icons.privacy_tip_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.gdprTitle ?? 'Your Privacy',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.gdprSubtitle ??
                          'This app respects your privacy. Choose which data you want to share. You can change these settings anytime.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Location consent
                    _ConsentToggle(
                      icon: Icons.my_location,
                      title: l10n?.gdprLocationTitle ?? 'Location Access',
                      description: l10n?.gdprLocationDescription ??
                          'Your coordinates are sent to the fuel price API to find nearby stations. Location data is never stored on a server and is not used for tracking.',
                      value: _locationConsent,
                      onChanged: (v) =>
                          setState(() => _locationConsent = v),
                    ),
                    const SizedBox(height: 16),

                    // Error reporting consent
                    _ConsentToggle(
                      icon: Icons.bug_report_outlined,
                      title: l10n?.gdprErrorReportingTitle ??
                          'Error Reporting',
                      description: l10n?.gdprErrorReportingDescription ??
                          'Anonymous crash reports help improve the app. No personal data is included. Reports are sent via Sentry only when configured.',
                      value: _errorReportingConsent,
                      onChanged: (v) =>
                          setState(() => _errorReportingConsent = v),
                    ),
                    const SizedBox(height: 16),

                    // Cloud sync consent
                    _ConsentToggle(
                      icon: Icons.cloud_outlined,
                      title: l10n?.gdprCloudSyncTitle ?? 'Cloud Sync',
                      description: l10n?.gdprCloudSyncDescription ??
                          'Sync favorites and alerts across devices via TankSync. Uses anonymous authentication. Your data is encrypted in transit.',
                      value: _cloudSyncConsent,
                      onChanged: (v) =>
                          setState(() => _cloudSyncConsent = v),
                    ),
                    const SizedBox(height: 24),

                    // Legal basis
                    Text(
                      l10n?.gdprLegalBasis ??
                          'Legal basis: Art. 6(1)(a) GDPR (Consent). You can withdraw consent anytime in Settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _acceptAll,
                    child: Text(l10n?.gdprAcceptAll ?? 'Accept All'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _acceptSelected,
                    child: Text(
                        l10n?.gdprAcceptSelected ?? 'Accept Selected'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single consent toggle with icon, title, description, and switch.
class _ConsentToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentToggle({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
