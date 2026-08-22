// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/feedback/feedback_consent.dart';
import '../../../../core/feedback/github_issue_reporter.dart';
import '../../../../core/feedback/github_issue_reporter_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/receipt_scan_service.dart';
import 'bad_scan_form_view.dart';
import 'bad_scan_issue_created_surface.dart';
import 'bad_scan_report_formatters.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/sharing/share_seam.dart';

/// Test seams: widget tests substitute these for the real
/// platform-channel / secure-storage backed implementations.
typedef ConsentPrompter =
    Future<FeedbackConsentChoice> Function(BuildContext context);
typedef ConsentReader = Future<FeedbackConsentState> Function();
typedef ConsentWriter = Future<void> Function(FeedbackConsentState state);

/// Alias of the shared [ShareSink] seam — kept because widget tests
/// name this type for the sheet's constructor parameter.
typedef ShareFallback = ShareSink;
typedef UrlLauncher = Future<bool> Function(Uri uri);
typedef ImageBytesReader = Future<Uint8List> Function(String path);

/// Bottom sheet the user opens when a scanned value is wrong. Two
/// submit paths:
///
/// 1. **GitHub ticket** (#952 phase 2) — when a PAT is configured via
///    secure storage under [kGithubFeedbackTokenKey] the sheet files an
///    issue directly through [GithubIssueReporter] and shows the
///    created URL with an "Open in browser" action.
/// 2. **SharePlus fallback** — when no token is configured or the
///    GitHub POST fails, the sheet falls back to the pre-existing
///    system-share intent so the user can still deliver the report via
///    email / GitHub Mobile / any share target.
///
class BadScanReportSheet extends ConsumerStatefulWidget {
  /// Selects the rendering + GitHub issue title. Receipt-only since
  /// #3765 removed the pump-display scanner.
  final ScanKind kind;

  /// Receipt-side scan outcome.
  final ReceiptScanOutcome? scan;

  final double? enteredLiters;
  final double? enteredTotalCost;
  final String appVersion;

  // Test seams — see typedefs above. Null in production; the
  // ?? operators in the state class fall back to platform defaults.
  @visibleForTesting
  final ShareFallback? shareFallback;
  @visibleForTesting
  final UrlLauncher? urlLauncher;
  @visibleForTesting
  final ImageBytesReader? imageBytesReader;
  @visibleForTesting
  final ConsentPrompter? consentPrompter;
  @visibleForTesting
  final ConsentReader? consentReader;
  @visibleForTesting
  final ConsentWriter? consentWriter;

  const BadScanReportSheet({
    super.key,
    this.kind = ScanKind.receipt,
    this.scan,
    required this.enteredLiters,
    required this.enteredTotalCost,
    required this.appVersion,
    this.shareFallback,
    this.urlLauncher,
    this.imageBytesReader,
    this.consentPrompter,
    this.consentReader,
    this.consentWriter,
  }) : assert(
         scan != null,
         'BadScanReportSheet: scan must be set for ScanKind.receipt.',
       );

  /// Path of the scanned image on disk.
  String get _imagePath => scan!.imagePath;

  /// Raw OCR text.
  String get _ocrText => scan!.ocrText;

  @override
  ConsumerState<BadScanReportSheet> createState() => _BadScanReportSheetState();
}

class _BadScanReportSheetState extends ConsumerState<BadScanReportSheet> {
  bool _submitting = false;
  Uri? _createdIssueUrl;

  Future<void> _defaultShareFallback(ShareParams params) async {
    await SharePlus.instance.share(params);
  }

  Future<bool> _defaultUrlLauncher(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: _createdIssueUrl == null
            ? BadScanFormView(
                kind: widget.kind,
                receiptScan: widget.scan,
                enteredLiters: widget.enteredLiters,
                enteredTotalCost: widget.enteredTotalCost,
                submitting: _submitting,
                onSubmit: _handleCreateTicket,
                onCancel: () => Navigator.of(context).pop(),
              )
            : BadScanIssueCreatedSurface(
                issueUrl: _createdIssueUrl!,
                onOpenInBrowser: _handleOpenInBrowser,
                onClose: () => Navigator.of(context).pop(),
              ),
      ),
    );
  }

  Future<void> _handleCreateTicket() async {
    setState(() => _submitting = true);
    try {
      final reporter = await ref.read(githubIssueReporterProvider.future);
      if (reporter == null) {
        // No token configured — fall back silently to the system share
        // sheet. The settings screen exposes a token-entry UI
        // ([FeedbackTokenSection]); the user has chosen to skip it.
        await _runShareFallback(showSnackbar: false);
        return;
      }

      // #952 phase 3 — consent gate. Token-holders still need to opt
      // in once before we POST anything to GitHub.
      final reader = widget.consentReader ?? FeedbackConsent.read;
      final writer = widget.consentWriter ?? FeedbackConsent.write;
      var consent = await reader();
      if (consent == FeedbackConsentState.unset) {
        if (!mounted) return;
        final prompter = widget.consentPrompter ?? FeedbackConsentDialog.show;
        final choice = await prompter(context);
        switch (choice) {
          case FeedbackConsentChoice.granted:
            await writer(FeedbackConsentState.granted);
            consent = FeedbackConsentState.granted;
            break;
          case FeedbackConsentChoice.denied:
            await writer(FeedbackConsentState.denied);
            consent = FeedbackConsentState.denied;
            break;
          case FeedbackConsentChoice.later:
            // Don't persist — re-ask next attempt. Fall back silently
            // for this submission.
            break;
        }
      }

      if (consent != FeedbackConsentState.granted) {
        await _runShareFallback(showSnackbar: false);
        return;
      }

      final url = await reporter.reportBadScan(
        kind: widget.kind,
        rawOcrText: widget._ocrText,
        parsedFields: buildBadScanParsedFields(receiptScan: widget.scan),
        userCorrections: buildBadScanUserCorrections(
          enteredLiters: widget.enteredLiters,
          enteredTotalCost: widget.enteredTotalCost,
        ),
        imageBytes: await _readImageBytes(),
      );

      if (!mounted) return;
      setState(() => _createdIssueUrl = url);
    } on GithubReporterException catch (e, st) {
      logFailure(e, st, where: 'BadScanReportSheet: GitHub submission failed');
      await _runShareFallback(showSnackbar: true);
    } catch (e, st) {
      // Secure-storage / image-read / unexpected errors — still fall
      // back so the user can always ship a report.
      logFailure(e, st, where: 'BadScanReportSheet: unexpected failure');
      await _runShareFallback(showSnackbar: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _runShareFallback({required bool showSnackbar}) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final share = widget.shareFallback ?? _defaultShareFallback;

    final params = ShareParams(
      files: [XFile(widget._imagePath)],
      text: buildBadScanShareBody(
        receiptScan: widget.scan,
        enteredLiters: widget.enteredLiters,
        enteredTotalCost: widget.enteredTotalCost,
        appVersion: widget.appVersion,
        ocrText: widget._ocrText,
      ),
      subject: 'Sparkilo receipt scan issue',
    );

    // Show the snackbar before awaiting share() so the message is
    // visible behind / above the system share sheet depending on the
    // platform. The messenger is tied to the Scaffold root, so it
    // outlives this modal sheet.
    if (showSnackbar) {
      messenger?.showSnackBar(
        SnackBarHelper.infoSnackBar(l.badScanReportFallbackToShare),
      );
    }

    try {
      await share(params);
    } catch (e, st) {
      logFailure(
        e,
        st,
        where: 'BadScanReportSheet: share fallback itself failed',
      );
    }
  }

  Future<void> _handleOpenInBrowser() async {
    final url = _createdIssueUrl;
    if (url == null) return;
    final launcher = widget.urlLauncher ?? _defaultUrlLauncher;
    try {
      await launcher(url);
    } catch (e, st) {
      logFailure(e, st, where: 'BadScanReportSheet: launchUrl failed');
    }
  }

  Future<Uint8List> _defaultImageBytesReader(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (e, st) {
      logFailure(e, st, where: 'BadScanReportSheet: could not read scan image');
      return Uint8List(0);
    }
  }

  Future<Uint8List> _readImageBytes() {
    final reader = widget.imageBytesReader ?? _defaultImageBytesReader;
    return reader(widget._imagePath);
  }
}
