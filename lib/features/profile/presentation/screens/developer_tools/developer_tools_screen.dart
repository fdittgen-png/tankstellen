// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/notifications/notification_providers.dart';
import '../../../../../core/services/diagnostics/data_access_recorder_provider.dart';
import '../../../../../core/services/diagnostics/data_access_trace_export.dart';
import '../../../../../core/storage/storage_providers.dart';
import '../../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../../core/widgets/page_scaffold.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/country/country_config.dart';
import '../../../../../core/utils/station_extensions.dart';
import '../../../../alerts/data/test_alert_runner.dart';
import '../../../../alerts/domain/radius_alert_evaluator.dart';
import '../../../../approach/presentation/widgets/approach_test_panel.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/build_channel.dart';
import '../../../../feature_management/domain/feature.dart';
import '../../../../../core/domain/search_result_item.dart';
import '../../../../../core/domain/station.dart';
import '../../../../search/providers/search_provider.dart';
import '../../widgets/error_log_export_row.dart';
import 'startup_trace_panel.dart';
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
    final debugOn = ref
        .watch(enabledFeaturesProvider)
        .contains(Feature.debugMode);

    if (!debugOn) {
      // Defensive: a stale deep-link must never expose dev tools.
      return PageScaffold(
        title: l.developerToolsSectionTitle,
        body: const SizedBox.shrink(),
      );
    }

    return PageScaffold(
      title: l.developerToolsSectionTitle,
      body: ListView(
        children: [
          Text(
            l.developerToolsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // --- Error log -------------------------------------------------
          SectionHeader(
            leadingIcon: Icons.bug_report_outlined,
            title: l.developerToolsErrorLogGroupTitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          ErrorLogExportRow(
            onView: () => context.push(RoutePaths.developerToolsErrorLog),
          ),
          const SizedBox(height: 16),

          // --- Alerts & notifications ------------------------------------
          SectionHeader(
            leadingIcon: Icons.notifications_active_outlined,
            title: l.developerToolsAlertsGroupTitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-fire-test-notification'),
            onPressed: () => _fireTestNotification(context, ref),
            icon: const Icon(Icons.notifications_outlined),
            label: Text(l.developerToolsFireTestNotification),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-run-test-alert'),
            onPressed: () => _runTestAlert(context, ref),
            icon: const Icon(Icons.crisis_alert_outlined),
            label: Text(l.developerToolsRunTestAlert),
          ),
          const SizedBox(height: 16),

          // --- Diagnostics ----------------------------------------------
          SectionHeader(
            leadingIcon: Icons.analytics_outlined,
            title: l.developerToolsDiagnosticsGroupTitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-feature-flag-dump'),
            onPressed: () => context.push(RoutePaths.developerToolsFlags),
            icon: const Icon(Icons.flag_outlined),
            label: Text(l.developerToolsFeatureFlagDump),
          ),
          const SizedBox(height: 8),
          // #2471 — OBD2 communication-health diagnostics (Epic #2463).
          OutlinedButton.icon(
            key: const ValueKey('debug-obd2-health'),
            onPressed: () => context.push(RoutePaths.developerToolsObd2Health),
            icon: const Icon(Icons.bluetooth_searching_outlined),
            label: Text(l.obd2HealthNavLabel),
          ),
          const SizedBox(height: 8),
          // #2518 — in-app OCR tester (Epic #2516 Child 2).
          OutlinedButton.icon(
            key: const ValueKey('debug-ocr-tester'),
            onPressed: () => context.push(RoutePaths.developerToolsOcrTester),
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(l.ocrTesterNavLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-clear-caches'),
            onPressed: () => _clearCaches(context, ref),
            icon: const Icon(Icons.cached_outlined),
            label: Text(l.developerToolsClearCaches),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('debug-copy-diagnostics'),
            onPressed: () => _copyDiagnostics(context, ref),
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(l.developerToolsCopyDiagnostics),
          ),
          const SizedBox(height: 8),
          // #2824 — export the recorded network-vs-cache data-access trace so
          // the cache-hit ratio + per-provider request intervals can be read
          // against each provider's rate-limit policy.
          OutlinedButton.icon(
            key: const ValueKey('debug-data-access-tracer'),
            onPressed: () => _exportDataAccessTrace(context, ref),
            icon: const Icon(Icons.network_check_outlined),
            label: Text(l.dataAccessTracerExport),
          ),
          const SizedBox(height: 16),

          // --- Startup trace (#3383) — gated by Feature.startupTrace; gating
          // stays HERE so the panel takes no feature_management dependency
          // (#3132 boundary).
          if (ref
              .watch(enabledFeaturesProvider)
              .contains(Feature.startupTrace))
            const StartupTracePanel(),

          // --- Approach overlay -----------------------------------------
          // #2382 — the approach-overlay simulator. Moved here from the
          // Privacy Dashboard: it is a test surface, not a privacy
          // control, so it belongs with the rest of the dev diagnostics.
          SectionHeader(
            leadingIcon: Icons.local_gas_station_outlined,
            title: l.approachOverlaySection,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          const ApproachTestPanel(),
          const SizedBox(height: 16),

          // --- Build info -----------------------------------------------
          SectionHeader(
            leadingIcon: Icons.info_outline,
            title: l.developerToolsBuildInfoGroupTitle,
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
        l.developerToolsTestNotificationBlocked,
      );
      return;
    }
    await notifier.showPriceAlert(
      id: 'debug:test-notification'.hashCode,
      title: l.developerToolsTestNotificationTitle,
      body: l.developerToolsTestNotificationBody,
    );
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(context, l.developerToolsTestNotificationSent);
  }

  Future<void> _runTestAlert(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    // #2408 — fire against a REAL station from the current search results
    // so the notification deep-links to a station that actually loads.
    // Without a search result there is no resolvable id, so we refuse to
    // fire a stuck synthetic deep-link and tell the user to search first.
    final station = _firstSearchStation(ref);
    if (station == null) {
      SnackBarHelper.show(context, l.developerToolsTestAlertNoStation);
      return;
    }
    final sample = StationPriceSample.fromStation(station).firstOrNull;
    if (sample == null) {
      // The station reports no priced fuel — nothing the evaluator can
      // match, so the same "search first" guidance applies.
      SnackBarHelper.show(context, l.developerToolsTestAlertNoStation);
      return;
    }
    final runner = TestAlertRunner(
      notifier: ref.read(notificationServiceProvider),
    );
    final count = await runner.run(
      title: l.developerToolsTestAlertTitle,
      body: l.developerToolsTestAlertBody(station.displayName),
      station: sample,
      country: (Countries.countryCodeForStationId(station.id) ?? 'de')
          .toLowerCase(),
    );
    if (!context.mounted) return;
    if (count == 0) {
      SnackBarHelper.showError(
        context,
        l.developerToolsTestNotificationBlocked,
      );
      return;
    }
    SnackBarHelper.showSuccess(context, l.developerToolsTestAlertFired(count));
  }

  Future<void> _clearCaches(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final storageMgmt = ref.read(storageManagementProvider);
    await storageMgmt.clearCache();
    await storageMgmt.clearPriceHistory();
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(context, l.developerToolsCachesCleared);
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
    SnackBarHelper.showSuccess(context, l.developerToolsDiagnosticsCopied);
  }

  /// #2824 — build a [DataAccessTrace] from the recorded events and write it to
  /// Downloads. When the tracer is off (production) or has recorded nothing
  /// yet, tell the user to search / use the app first.
  Future<void> _exportDataAccessTrace(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final recorder = ref.read(dataAccessRecorderProvider);
    if (recorder == null || recorder.events.isEmpty) {
      SnackBarHelper.show(context, l.dataAccessTracerEmpty);
      return;
    }
    final ok = await DataAccessTraceExport.export(recorder.build());
    if (!context.mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(context, l.dataAccessTracerExportSuccess);
    } else {
      SnackBarHelper.showError(context, l.dataAccessTracerExportFailure);
    }
  }
}

/// #2408 — the first real fuel station in the current search results, or
/// `null` when the user has not searched / the results hold no fuel
/// station. The test alert fires against this so the notification
/// deep-links to a station `stationDetailProvider` can actually resolve.
Station? _firstSearchStation(WidgetRef ref) {
  final searchState = ref.read(searchStateProvider);
  if (!searchState.hasValue) return null;
  final results = searchState.value?.data ?? const [];
  return results.whereType<FuelStationResult>().firstOrNull?.station;
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
          title: Text(l.developerToolsBuildVersion),
          trailing: Text(AppConstants.appVersion),
        ),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l.developerToolsBuildChannel),
          trailing: Text(channel.name),
        ),
      ],
    );
  }
}
