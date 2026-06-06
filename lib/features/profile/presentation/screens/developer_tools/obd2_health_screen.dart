// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logging/error_logger.dart';
import '../../../../../core/sharing/public_file_exporter.dart';
import '../../../../../core/widgets/page_scaffold.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../consumption/data/obd2/obd2_comm_diagnostics.dart';
import '../../../../consumption/data/obd2/obd2_session_diagnostic.dart';
import '../../../../consumption/presentation/widgets/obd2_diagnostics_card.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/feature.dart';
import 'obd2_self_test_panel.dart';

/// 'OBD2 Communication Health' developer-tools screen (#2471, TAIL of
/// Epic #2463). Gated behind [Feature.debugMode] via the Developer tools
/// screen that pushes it (route `/developer-tools/obd2-health`); the
/// screen also self-guards on the flag so a stale deep-link is inert,
/// mirroring `FeatureFlagDumpScreen`.
///
/// Hosts the [Obd2DiagnosticsCard] in a full-detail scroll — the live
/// (in-progress) session first, then the capped ring of finished
/// sessions, newest-first — plus a download-as-JSON affordance per session
/// (#2938 — the maintainer opens the saved file from the file manager to
/// read the per-PID table). The data comes from the process-wide
/// `Obd2CommDiagnostics.instance` collector the comm-path layers tee into.
///
/// The JSON exports write a FILE to the device's public Downloads folder
/// via [PublicFileExporter] (#2938), matching the backup-export /
/// data-access-trace UX (#2815/#2824) — not the clipboard. These are
/// foreground actions so the `tankstellen/public_files` channel is
/// available (the #2933 background-isolate concern does not apply).
///
/// Reads the collector once per build; it is a plain in-memory singleton,
/// so there is no provider to watch. The screen is dev-only and the
/// collector ring is small (capped at `maxSessions`), so a manual rebuild
/// on navigation is sufficient.
class Obd2HealthScreen extends ConsumerWidget {
  const Obd2HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debugOn =
        ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);

    final title = l?.obd2HealthScreenTitle ?? 'OBD2 communication health';

    if (!debugOn) {
      // Defensive: a stale deep-link must never expose dev tools.
      return PageScaffold(title: title, body: const SizedBox.shrink());
    }

    final collector = Obd2CommDiagnostics.instance;
    final enabled = collector.enabled;
    final live = collector.snapshot();
    // Newest-first so the most recent finished session reads at the top.
    final finished = collector.finishedSessions.reversed.toList();

    return PageScaffold(
      title: title,
      body: ListView(
        children: [
          Text(
            l?.obd2DiagnosticsExplain ??
                'Captured while recording to debug the dongle↔app '
                    'communication — only collected in Developer mode.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // --- Active adapter self-test (#2645) -------------------------
          const Obd2SelfTestPanel(),

          // --- Live session ---------------------------------------------
          SectionHeader(
            leadingIcon: Icons.sensors_outlined,
            title: l?.obd2HealthLiveSection ?? 'Live session',
            padding: EdgeInsets.zero,
          ),
          Obd2DiagnosticsCard(
            key: const Key('obd2_health_live_card'),
            session: live,
            enabled: enabled,
          ),
          _downloadJsonButton(
              context, l, live, const Key('obd2_health_copy_live')),
          const SizedBox(height: 16),

          // --- Recent finished sessions ---------------------------------
          SectionHeader(
            leadingIcon: Icons.history_outlined,
            title: l?.obd2HealthHistorySection ?? 'Recent sessions',
            padding: EdgeInsets.zero,
          ),
          for (var i = 0; i < finished.length; i++) ...[
            Obd2DiagnosticsCard(
              key: Key('obd2_health_finished_card_$i'),
              session: finished[i],
              enabled: enabled,
            ),
            _downloadJsonButton(
              context,
              l,
              finished[i],
              Key('obd2_health_copy_finished_$i'),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Widget _downloadJsonButton(
    BuildContext context,
    AppLocalizations? l,
    Obd2SessionDiagnostic session,
    Key key,
  ) {
    // Derive a stable sibling key for the handshake-only button from the
    // download-JSON button's key (every caller passes a `ValueKey<String>`).
    final keyValue = key is ValueKey ? key.value : key;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Wrap(
          spacing: 4,
          children: [
            // Handshake-only export: just the adapter identity + init
            // transcript + supported PIDs (#2511). Shown only when the
            // session actually captured a handshake.
            if (session.initTranscript.isNotEmpty)
              TextButton.icon(
                key: Key('${keyValue}_init'),
                onPressed: () => _downloadInitTranscript(context, l, session),
                icon: const Icon(Icons.terminal_outlined, size: 18),
                label: Text(
                  l?.obd2HealthDownloadInitTranscript ??
                      'Download init transcript only',
                ),
              ),
            TextButton.icon(
              key: key,
              onPressed: () => _downloadAsJson(context, l, session),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text(l?.obd2HealthDownloadJson ?? 'Download as JSON'),
            ),
          ],
        ),
      ),
    );
  }

  /// Write the full per-session diagnostics JSON to the public Downloads
  /// folder (#2938) and surface a single success / error snackbar. Replaces
  /// the former clipboard copy — the maintainer opens the saved file from the
  /// file manager.
  Future<void> _downloadAsJson(
    BuildContext context,
    AppLocalizations? l,
    Obd2SessionDiagnostic session,
  ) async {
    final json = const JsonEncoder.withIndent('  ').convert(session.toJson());
    await _saveJsonToDownloads(context, l, json, 'session');
  }

  /// Write ONLY the dongle-init handshake payload — adapter identity, the
  /// init transcript, MTU + the discovered-supported set — to the public
  /// Downloads folder (#2511/#2938). A focused subset of the per-session JSON
  /// for attaching a handshake to a bug report.
  Future<void> _downloadInitTranscript(
    BuildContext context,
    AppLocalizations? l,
    Obd2SessionDiagnostic session,
  ) async {
    final payload = <String, dynamic>{
      'elmVersion': session.elmVersion,
      'protocolDigit': session.protocolDigit,
      'warmStart': session.warmStart,
      'capabilityTier': session.capabilityTier,
      'mtu': session.mtu,
      'supportedPids': session.discoveredSupported,
      'initTranscript': [
        for (final line in session.initTranscript) line.toJson(),
      ],
    };
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    await _saveJsonToDownloads(context, l, json, 'init');
  }

  /// Shared download sink: write [json] to a timestamped file in the public
  /// Downloads folder via [PublicFileExporter] and show a success / error
  /// snackbar. Never throws — every failure path is caught + surfaced (the
  /// #1103 catch-with-stacktrace + never-throws contract). The
  /// `tankstellen/public_files` channel is registered in the foreground
  /// isolate this screen runs in, but a `MissingPluginException` is still
  /// handled defensively (the #2933 background-isolate degrade pattern).
  Future<void> _saveJsonToDownloads(
    BuildContext context,
    AppLocalizations? l,
    String json,
    String kind,
  ) async {
    // Capture every BuildContext-derived value BEFORE the async gap so no
    // context is touched after the await (lint: use_build_context_synchronously).
    final messenger = ScaffoldMessenger.maybeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final stamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    // i18n-ignore: language-neutral filename mask (brand + kind tag + stamp).
    final fileName = 'tankstellen-obd2-$kind-$stamp.json';
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: json,
        fileName: fileName,
        mimeType: 'application/json',
      );
      messenger?.showSnackBar(
        SnackBarHelper.successSnackBar(
          scheme,
          l?.savedToDownloadsFolder ?? 'Saved to your Downloads folder',
        ),
      );
    } on MissingPluginException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'Obd2HealthScreen download: public_files channel unavailable',
      }));
      _showDownloadError(scheme, l, messenger);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'Obd2HealthScreen download: json write',
      }));
      _showDownloadError(scheme, l, messenger);
    }
  }

  void _showDownloadError(
    ColorScheme scheme,
    AppLocalizations? l,
    ScaffoldMessengerState? messenger,
  ) {
    messenger?.showSnackBar(
      SnackBarHelper.errorSnackBar(
        scheme,
        l?.obd2HealthDownloadError ?? "Couldn't save the diagnostics file",
      ),
    );
  }
}
