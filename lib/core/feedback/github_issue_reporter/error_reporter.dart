// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/snackbar_helper.dart';
import 'error_report_formatter.dart';
import 'error_report_payload.dart';
import '../../../core/logging/error_logger.dart';

/// Launches a URL in the external browser.
///
/// Type aliased so tests can inject a fake that records the URL
/// without actually opening anything.
typedef UrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _defaultLauncher(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Consent-gated entry point for filing a GitHub issue from inside the
/// app.
///
/// The caller passes an [ErrorReportPayload] built from whatever error
/// they want to report. We show a dialog explaining *exactly* what
/// will be sent (no GPS, no API keys, no personal data) and only
/// open the browser if the user confirms.
///
/// Returns `true` when the user confirmed and the URL was launched,
/// `false` otherwise.
///
/// Production callers should always use the default
/// `requireConsent: true` — the flag exists solely so tests can skip
/// the dialog without tapping through it.
class ErrorReporter {
  final UrlLauncher _launcher;

  const ErrorReporter({UrlLauncher launcher = _defaultLauncher})
      : _launcher = launcher;

  /// Recently-reported error fingerprints — a process-lifetime ring
  /// buffer so the same failure reported twice in a session does not
  /// compose a second GitHub issue (#1606). Three of the six
  /// not-planned issues in the backlog were byte-identical duplicates
  /// filed through this path.
  static final List<String> _recentFingerprints = <String>[];
  static const int _dedupRingSize = 20;

  static void _rememberFingerprint(String fingerprint) {
    _recentFingerprints
      ..remove(fingerprint)
      ..add(fingerprint);
    if (_recentFingerprints.length > _dedupRingSize) {
      _recentFingerprints.removeAt(0);
    }
  }

  /// Test seam — whether [fingerprint] is in the dedup ring.
  @visibleForTesting
  static bool hasRecentlyReported(String fingerprint) =>
      _recentFingerprints.contains(fingerprint);

  /// Test seam — clears the dedup ring so each test starts fresh.
  @visibleForTesting
  static void resetDedupRingForTest() => _recentFingerprints.clear();

  Future<bool> reportError(
    BuildContext context,
    ErrorReportPayload payload, {
    bool requireConsent = true,
  }) async {
    // #1606 — client-side dedup. A fingerprint already in the ring
    // buffer means this exact failure was reported before; don't
    // compose a second issue URL, just tell the user it's already
    // filed.
    if (_recentFingerprints.contains(payload.fingerprint)) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.show(
          context,
          l10n?.reportAlreadySent ?? 'You already reported this issue.',
        );
      }
      return false;
    }

    if (requireConsent) {
      final confirmed = await _showConsentDialog(context, payload);
      if (confirmed != true) return false;
    }

    final url = ErrorReportFormatter.buildIssueUrl(payload);
    try {
      final launched = await _launcher(url);
      if (launched) _rememberFingerprint(payload.fingerprint);
      return launched;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'ErrorReporter launch failed'}));
      return false;
    }
  }

  Future<bool?> _showConsentDialog(
    BuildContext context,
    ErrorReportPayload payload,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n?.reportConsentTitle ?? 'Report to GitHub?'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.reportConsentBody ??
                      'This will open a public GitHub issue with the '
                          'error details shown below. No GPS coordinates, '
                          'API keys, or personal data are included.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _consentPreview(payload),
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n?.reportConsentCancel ?? 'Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n?.reportConsentConfirm ?? 'Open GitHub'),
            ),
          ],
        );
      },
    );
  }

  /// Short, human-readable preview of what will end up in the issue
  /// body — shown in the consent dialog so users can see exactly
  /// what's being sent before tapping Confirm.
  @visibleForTesting
  static String consentPreview(ErrorReportPayload p) => _consentPreview(p);

  static String _consentPreview(ErrorReportPayload p) {
    final lines = <String>[
      if (p.sourceLabel != null) 'Source: ${p.sourceLabel}',
      'Error: ${p.errorType}',
      if (p.statusCode != null) 'HTTP: ${p.statusCode}',
      'App: ${p.appVersion}',
      'Platform: ${p.platform}',
      'Locale: ${p.locale}',
    ];
    return lines.join('\n');
  }
}
