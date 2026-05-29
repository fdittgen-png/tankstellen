// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/notifications/notification_providers.dart';
import '../../../../../core/storage/storage_providers.dart';
import '../../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../../core/widgets/page_scaffold.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../alerts/data/test_alert_runner.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/build_channel.dart';
import '../../../../feature_management/domain/feature.dart';
import '../../widgets/error_log_export_row.dart';
import 'developer_diagnostics.dart';

/// Developer / Debug-mode tools screen (#2248). Reachable from the
/// Developer tools tile on the Settings screen, which is itself gated on
/// [Feature.debugMode]. Hosts dev-only diagnostics:
///
///  * **Error log** — the single-write export/save (reuses
///    [ErrorLogExportRow], the #2236-correct path) plus a raw in-app
///    trace viewer.
///  * **Alerts & notifications** — fire a test notification (verifies
///    POST_NOTIFICATIONS + the Android channel + delivery) and run the
///    radius-alert pipeline end-to-end against a synthetic match
///    ([TestAlertRunner]).
///  * **Diagnostics** — a feature-flag inspector, a clear-caches action,
///    and a copy-diagnostics action.
///  * **Build info** — read-only app version + build channel.
///
/// The screen guards itself defensively too: when [Feature.debugMode] is
/// off it renders an empty scaffold, so a stale deep-link can never
/// expose the tools to a production user.
class DeveloperToolsScreen extends ConsumerWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debugOn =
        ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);

    if (!debugOn) {
      // Defensive: a stale deep-link must never expose dev tools.
      return PageScaffold(
        title: l?.developerToolsSectionTitle ?? 'Developer tools',
        body: const SizedBox.shrink(),
      );
    }

    return PageScaffold(
      title: l?.developerToolsSectionTitle ?? 'Developer tools',
      body: ListView(
        children: [
          Text(
            l?.developerToolsSubtitle ??
                'Diagnostics and tools for debugging — only visible in '
                    'Developer / Debug mode.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // --- Error log -------------------------------------------------
          SectionHeader(
            leadingIcon: Icons.bug_report_outlined,
            title: l?.developerToolsErrorLogGroupTitle ?? 'Error log',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          ErrorLogExportRow(
            onView: () => context.push('/developer-tools/error-log'),
          ),
          const SizedBox(height: 16),

          // --- Alerts & notifications ------------------------------------
          SectionHeader(
            leadingIcon: Icons.notifications_active_outlined,
            title: l?.developerToolsAlertsGroupTitle ??
                'Alerts & notifications',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-fire-test-notification'),
            onPressed: () => _fireTestNotification(context, ref),
            icon: const Icon(Icons.notifications_outlined),
            label: Text(
              l?.developerToolsFireTestNotification ??
                  'Fire test notification',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-run-test-alert'),
            onPressed: () => _runTestAlert(context, ref),
            icon: const Icon(Icons.crisis_alert_outlined),
            label: Text(
              l?.developerToolsRunTestAlert ?? 'Run test alert pipeline',
            ),
          ),
          const SizedBox(height: 16),

          // --- Diagnostics ----------------------------------------------
          SectionHeader(
            leadingIcon: Icons.analytics_outlined,
            title: l?.developerToolsDiagnosticsGroupTitle ?? 'Diagnostics',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-feature-flag-dump'),
            onPressed: () => context.push('/developer-tools/flags'),
            icon: const Icon(Icons.flag_outlined),
            label: Text(
              l?.developerToolsFeatureFlagDump ?? 'Feature flag inspector',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-clear-caches'),
            onPressed: () => _clearCaches(context, ref),
            icon: const Icon(Icons.cached_outlined),
            label: Text(l?.developerToolsClearCaches ?? 'Clear caches'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-copy-diagnostics'),
            onPressed: () => _copyDiagnostics(context, ref),
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(
              l?.developerToolsCopyDiagnostics ?? 'Copy diagnostics',
            ),
          ),
          const SizedBox(height: 16),

          // --- Build info -----------------------------------------------
          SectionHeader(
            leadingIcon: Icons.info_outline,
            title: l?.developerToolsBuildInfoGroupTitle ?? 'Build info',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _BuildInfoRows(channel: ref.watch(buildChannelProvider)),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Future<void> _fireTestNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(notificationServiceProvider);
    final granted = await notifier.requestPermission();
    if (!context.mounted) return;
    if (!granted) {
      SnackBarHelper.showError(
        context,
        l?.developerToolsTestNotificationBlocked ??
            'Notifications are blocked — enable them in system settings, '
                'then retry.',
      );
      return;
    }
    await notifier.showPriceAlert(
      id: 'debug:test-notification'.hashCode,
      title: l?.developerToolsTestNotificationTitle ?? 'Test notification',
      body: l?.developerToolsTestNotificationBody ??
          'If you can read this, notifications are working.',
    );
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(
      context,
      l?.developerToolsTestNotificationSent ?? 'Test notification sent.',
    );
  }

  Future<void> _runTestAlert(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final runner = TestAlertRunner(
      notifier: ref.read(notificationServiceProvider),
    );
    final count = await runner.run(
      title: l?.developerToolsTestAlertTitle ?? 'Test price alert',
      body: l?.developerToolsTestAlertBody ??
          'Synthetic match: a station below your target was found nearby.',
    );
    if (!context.mounted) return;
    if (count == 0) {
      SnackBarHelper.showError(
        context,
        l?.developerToolsTestNotificationBlocked ??
            'Notifications are blocked — enable them in system settings, '
                'then retry.',
      );
      return;
    }
    SnackBarHelper.showSuccess(
      context,
      l?.developerToolsTestAlertFired(count) ??
          'Test alert fired — pipeline delivered $count notification(s).',
    );
  }

  Future<void> _clearCaches(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final storageMgmt = ref.read(storageManagementProvider);
    await storageMgmt.clearCache();
    await storageMgmt.clearPriceHistory();
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(
      context,
      l?.developerToolsCachesCleared ?? 'Caches cleared.',
    );
  }

  Future<void> _copyDiagnostics(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final blob = buildDeveloperDiagnostics(
      channel: ref.read(buildChannelProvider),
      enabledFeatures: ref.read(enabledFeaturesProvider),
      errorTraceCount: ref.read(traceStorageProvider).count,
    );
    await Clipboard.setData(ClipboardData(text: blob));
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(
      context,
      l?.developerToolsDiagnosticsCopied ??
          'Diagnostics copied to clipboard.',
    );
  }
}

/// Read-only app version + build channel rows.
class _BuildInfoRows extends StatelessWidget {
  final BuildChannel channel;

  const _BuildInfoRows({required this.channel});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l?.developerToolsBuildVersion ?? 'App version'),
          trailing: Text(AppConstants.appVersion),
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l?.developerToolsBuildChannel ?? 'Build channel'),
          trailing: Text(channel.name),
        ),
      ],
    );
  }
}
