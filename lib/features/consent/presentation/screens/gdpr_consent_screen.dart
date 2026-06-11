// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/gdpr_consent_form_provider.dart';

/// First-launch GDPR consent screen.
///
/// Shows before any data collection with toggles for:
/// - Location access
/// - Error reporting (Sentry)
/// - Cloud sync (TankSync)
///
/// Consent choices are persisted in HiveStorage and respected
/// throughout the app. Users can change choices later in Settings.
///
/// Pending toggle state lives in [gdprConsentFormControllerProvider];
/// the persisted consent lives in `gdprConsentProvider`.
class GdprConsentScreen extends ConsumerWidget {
  const GdprConsentScreen({super.key});

  Future<void> _acceptSelected(BuildContext context, WidgetRef ref) async {
    final form = ref.read(gdprConsentFormControllerProvider);
    await ref
        .read(gdprConsentProvider.notifier)
        .save(
          location: form.locationConsent,
          errorReporting: form.errorReportingConsent,
          cloudSync: form.cloudSyncConsent,
          vinOnlineDecode: form.vinOnlineDecodeConsent,
        );
    if (context.mounted) context.go(RoutePaths.setup);
  }

  Future<void> _acceptAll(BuildContext context, WidgetRef ref) async {
    await ref
        .read(gdprConsentProvider.notifier)
        .save(
          location: true,
          errorReporting: true,
          cloudSync: true,
          vinOnlineDecode: true,
        );
    if (context.mounted) context.go(RoutePaths.setup);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(gdprConsentFormControllerProvider);
    final notifier = ref.read(gdprConsentFormControllerProvider.notifier);

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
                      l10n.gdprTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.gdprSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Location consent
                    _ConsentToggle(
                      icon: Icons.my_location,
                      title: l10n.gdprLocationTitle,
                      description: l10n.gdprLocationDescription,
                      value: form.locationConsent,
                      onChanged: notifier.setLocation,
                    ),
                    const SizedBox(height: 16),

                    // Error reporting consent
                    _ConsentToggle(
                      icon: Icons.bug_report_outlined,
                      title: l10n.gdprErrorReportingTitle,
                      description: l10n.gdprErrorReportingDescription,
                      value: form.errorReportingConsent,
                      onChanged: notifier.setErrorReporting,
                    ),
                    const SizedBox(height: 16),

                    // Cloud sync consent
                    _ConsentToggle(
                      icon: Icons.cloud_outlined,
                      title: l10n.gdprCloudSyncTitle,
                      description: l10n.gdprCloudSyncDescription,
                      value: form.cloudSyncConsent,
                      onChanged: notifier.setCloudSync,
                    ),
                    const SizedBox(height: 16),

                    // VIN online decode consent (#1399)
                    _ConsentToggle(
                      icon: Icons.directions_car_outlined,
                      title: l10n.gdprVinOnlineDecodeTitle,
                      description: l10n.gdprVinOnlineDecodeDescription,
                      value: form.vinOnlineDecodeConsent,
                      onChanged: notifier.setVinOnlineDecode,
                    ),
                    const SizedBox(height: 24),

                    // Legal basis
                    Text(
                      l10n.gdprLegalBasis,
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
                  // #1691 — granular choice is the primary action;
                  // "Accept All" is de-emphasised so the consent screen
                  // does not nudge toward blanket consent.
                  FilledButton(
                    onPressed: () => _acceptSelected(context, ref),
                    child: Text(l10n.gdprAcceptSelected),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _acceptAll(context, ref),
                    child: Text(l10n.gdprAcceptAll),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
