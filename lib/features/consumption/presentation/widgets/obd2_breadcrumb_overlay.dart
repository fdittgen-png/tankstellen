import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2/auto_record_trace_log.dart';
import '../../data/obd2/obd2_breadcrumb_collector.dart';
import '../../data/obd2/obd2_debug_session.dart';
import '../../data/obd2/obd2_debug_session_xml.dart';
import '../../data/obd2/obd2_diagnostic_report.dart';
import '../../providers/obd2_breadcrumb_provider.dart';
import 'broken_map_widgets.dart';
import 'obd2_breadcrumb_row.dart';

/// Hook for the share-sheet handoff of the OBD2 diagnostic log
/// (#1920). Production uses `SharePlus.instance.share`; tests
/// substitute a fake via [debugObd2DiagnosticShareSinkOverride] to
/// assert the outgoing report text without launching the OS share
/// sheet. Mirrors the seam pattern in `full_backup_exporter.dart`.
typedef Obd2DiagnosticShareSink = Future<void> Function(ShareParams params);

/// Test-only override for the share sink used by the OBD2 diagnostic
/// share button. When set, the button hands the formatted report to
/// this sink instead of the real `share_plus` plugin.
@visibleForTesting
Obd2DiagnosticShareSink? debugObd2DiagnosticShareSinkOverride;

Future<void> _defaultObd2DiagnosticShareSink(ShareParams params) =>
    SharePlus.instance.share(params);

/// In-app overlay that renders the most recent fuel-rate breadcrumbs
/// captured by [Obd2BreadcrumbsNotifier] (#1395). Sibling to the map
/// debug breadcrumb overlay shipped in PR #1378.
///
/// Always visible in `kDebugMode`; in release builds the user enables
/// it via the hidden 5-tap gesture on the trip-recording screen
/// title (which flips [obd2DebugOverlayProvider]). The overlay
/// renders one row per fuel-rate sample with the resolved branch tag
/// ([5E] / [MAF] / [SD] / [--]), the L/h surfaced to the trip
/// integrator, and a smaller second line with AFR / density /
/// displacement / VE actually used. Rows are colour-coded by flag —
/// green for clean samples, amber for suspicious-low (RPM > 1500
/// AND L/h < 0.3), red for 5E-vs-MAF divergence > 50 %.
///
/// The widget self-hides when neither path is enabled, returning a
/// zero-cost [SizedBox.shrink], so the screen pays nothing for it in
/// production builds where the flag is off.
class Obd2BreadcrumbOverlay extends ConsumerWidget {
  const Obd2BreadcrumbOverlay({super.key});

  /// Format the process-wide OBD2 trace ring into a plain-text report
  /// and hand it to the OS share sheet (#1920). Best-effort — a share
  /// failure is logged and swallowed so the developer-only overlay
  /// never crashes the recording screen. Also drops a copy under
  /// `<docs>/Downloads/` so the user can grab the file from any file
  /// manager later (#1993); the saved path is reported through the
  /// messenger snackbar when [messenger] is supplied.
  Future<void> _shareDiagnosticLog(
    ScaffoldMessengerState? messenger,
    AppLocalizations? l10n,
  ) async {
    final String report = formatObd2DiagnosticReport(
      AutoRecordTraceLog.snapshot(),
    );
    final ShareParams params = ShareParams(text: report);
    final Obd2DiagnosticShareSink sink =
        debugObd2DiagnosticShareSinkOverride ??
            _defaultObd2DiagnosticShareSink;
    try {
      await sink(params);
    } catch (e, st) {
      debugPrint('Obd2BreadcrumbOverlay share diagnostic log failed: $e\n$st');
    }
    await _alsoSaveToDownloads(
      text: report,
      fileName: 'tankstellen-obd2-diagnostic.txt',
      messenger: messenger,
      l10n: l10n,
    );
  }

  /// Export the most recent OBD2 debug session as XML (#1925). Only
  /// produces real content when the user has opted into OBD2 debug
  /// logging; otherwise the latest session is null and a short note is
  /// shared so the user understands why. Best-effort, like
  /// [_shareDiagnosticLog].
  Future<void> _shareSessionXml(
    ScaffoldMessengerState? messenger,
    AppLocalizations? l10n,
  ) async {
    final Obd2DebugSession? session = Obd2DebugSessionRecorder.latestSession;
    final String payload = session == null
        ? '<!-- No OBD2 debug session recorded. Enable "OBD2 debug '
            'logging" in Settings, then reproduce the issue. -->'
        : formatObd2DebugSessionXml(session);
    final ShareParams params = ShareParams(text: payload);
    final Obd2DiagnosticShareSink sink =
        debugObd2DiagnosticShareSinkOverride ??
            _defaultObd2DiagnosticShareSink;
    try {
      await sink(params);
    } catch (e, st) {
      debugPrint('Obd2BreadcrumbOverlay share session XML failed: $e\n$st');
    }
    await _alsoSaveToDownloads(
      text: payload,
      fileName: 'tankstellen-obd2-session.xml',
      messenger: messenger,
      l10n: l10n,
    );
  }

  /// Write [text] to `<docs>/Downloads/<fileName>` and, when a
  /// [messenger] is available, surface the resulting path through a
  /// snackbar (#1993). Best-effort — a write failure is logged but the
  /// share-sheet hand-off above is already complete, so the user is not
  /// stranded.
  Future<void> _alsoSaveToDownloads({
    required String text,
    required String fileName,
    required ScaffoldMessengerState? messenger,
    required AppLocalizations? l10n,
  }) async {
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: text,
        fileName: fileName,
        mimeType: 'application/json',
      );
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.savedToDownloadsFolder ?? 'Saved to your Downloads folder',
          ),
        ),
      );
    } on Object catch (e, st) {
      debugPrint('Obd2BreadcrumbOverlay save-to-downloads failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tolerate the Hive-box-not-open path — widget tests (e.g.
    // trip_recording_screen_page_scaffold_test) pump the recording
    // screen without bootstrapping Hive, and the overlay must not
    // blow up the screen. The production overlay only surfaces in
    // `kDebugMode || flag-set` — a missing flag is identical to "off"
    // from the user's perspective.
    bool flag = false;
    try {
      flag = ref.watch(obd2DebugOverlayProvider);
    } catch (e, st) {
      debugPrint('Obd2BreadcrumbOverlay flag read failed: $e\n$st');
      flag = false;
    }
    final visible = kDebugMode || flag;
    if (!visible) return const SizedBox.shrink();

    List<Obd2Breadcrumb> crumbs = const [];
    try {
      crumbs = ref.watch(obd2BreadcrumbsProvider);
    } catch (e, st) {
      debugPrint('Obd2BreadcrumbOverlay crumbs read failed: $e\n$st');
      crumbs = const [];
    }
    final l10n = AppLocalizations.of(context);

    // Wrap in ExcludeSemantics so the Android tap-target guideline
    // test (used by `active_recording_screen_pin_test`) doesn't trip
    // on the developer-only overlay's compact Clear / Close buttons.
    // The overlay is not a user-facing UI element; release builds
    // ship with the flag off and the overlay returns
    // [SizedBox.shrink], so the exclusion is debug-only in practice.
    return Positioned(
      right: 8,
      bottom: 8,
      child: ExcludeSemantics(
        child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 280,
            maxHeight: 360,
            minWidth: 200,
            minHeight: 100,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.obd2DebugOverlayTitle ?? 'OBD2 breadcrumbs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(obd2BreadcrumbsProvider.notifier)
                              .clear();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n?.obd2DebugOverlayClearButton ?? 'Clear',
                        ),
                      ),
                      // #1920 — export the OBD2 connect/drop/reconnect
                      // trace as plain text so a developer can analyse
                      // a failed recording session. The trace ring is
                      // process-wide, not tied to the fuel-rate
                      // breadcrumbs above.
                      IconButton(
                        onPressed: () => _shareDiagnosticLog(
                          ScaffoldMessenger.maybeOf(context),
                          l10n,
                        ),
                        icon: const Icon(Icons.share, size: 18),
                        color: Colors.white,
                        tooltip: l10n?.obd2DiagnosticShareLabel ??
                            'Share diagnostic log',
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      // #1925 — export the most recent OBD2 debug
                      // session (init handshake, data gaps, reconnects)
                      // as XML when the user enabled debug logging.
                      IconButton(
                        onPressed: () => _shareSessionXml(
                          ScaffoldMessenger.maybeOf(context),
                          l10n,
                        ),
                        icon: const Icon(Icons.bug_report, size: 18),
                        color: Colors.white,
                        tooltip: l10n?.obd2DebugSessionShareLabel ??
                            'Share OBD2 session log',
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(obd2DebugOverlayProvider.notifier)
                              .disable();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n?.obd2DebugOverlayCloseButton ?? 'Close',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 8),
                  // #1423 phase 5 — broken-MAP belief diagnostic row,
                  // self-hides when the active vehicle has zero
                  // observations. Appears above the breadcrumb list so
                  // the latest belief snapshot is always visible without
                  // scrolling, even on long crumb sets.
                  const BrokenMapOverlayRow(),
                  Flexible(
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Newest-first: walk reversed so the bottom
                          // of the scroll view shows the most recent
                          // sample. `reverse: true` on the scroll view
                          // keeps the freshest row pinned at bottom.
                          for (final c in crumbs.reversed)
                            Obd2BreadcrumbRow(crumb: c),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

