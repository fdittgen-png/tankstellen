import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/feedback/feedback_consent.dart';
import '../../../../core/feedback/github_issue_reporter.dart';
import '../../../../core/feedback/github_issue_reporter_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/receipt_scan_service.dart';

/// Test seam for the consent prompt. Production code uses
/// [FeedbackConsentDialog.show]; widget tests can replace it with a
/// stub that returns a pre-canned [FeedbackConsentChoice].
typedef ConsentPrompter = Future<FeedbackConsentChoice> Function(
    BuildContext context);

/// Test seam for the persisted consent state. Production code reads
/// from `shared_preferences` via [FeedbackConsent.read].
typedef ConsentReader = Future<FeedbackConsentState> Function();

/// Test seam for persisting a consent choice. Production code writes
/// to `shared_preferences` via [FeedbackConsent.write].
typedef ConsentWriter = Future<void> Function(FeedbackConsentState state);

/// Share callback signature so widget tests can substitute the
/// [SharePlus] platform channel with a Dart-only fake. Production
/// code passes [_defaultShareFallback].
typedef ShareFallback = Future<void> Function(ShareParams params);

/// URL-launcher callback signature, same rationale as [ShareFallback].
typedef UrlLauncher = Future<bool> Function(Uri uri);

/// Reads the raw bytes of the scanned image. Defaults to
/// `File(path).readAsBytes()`; widget tests inject a Dart-only fake.
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
/// #953 generalised the sheet to also handle failed pump-display scans.
/// Pass [scan] for the receipt path, or [pumpScan] for the pump-display
/// path; exactly one must be non-null and [kind] selects which.
class BadScanReportSheet extends ConsumerStatefulWidget {
  /// Selects the rendering + GitHub issue title. Defaults to
  /// [ScanKind.receipt] for backward compatibility with the original
  /// (#751 / #952) callers — existing code that passes only [scan]
  /// continues to render the receipt diff table unchanged.
  final ScanKind kind;

  /// Receipt-side scan outcome. Required when [kind] is
  /// [ScanKind.receipt]; ignored when [kind] is [ScanKind.pumpDisplay].
  final ReceiptScanOutcome? scan;

  /// Pump-display scan outcome (#953). Required when [kind] is
  /// [ScanKind.pumpDisplay]; ignored when [kind] is [ScanKind.receipt].
  final PumpDisplayScanOutcome? pumpScan;

  final double? enteredLiters;
  final double? enteredTotalCost;
  final String appVersion;

  /// Injected for widget tests. In production the default implementation
  /// forwards to `SharePlus.instance.share(...)`.
  @visibleForTesting
  final ShareFallback? shareFallback;

  /// Injected for widget tests. In production the default implementation
  /// forwards to `launchUrl(...)`.
  @visibleForTesting
  final UrlLauncher? urlLauncher;

  /// Injected for widget tests. In production the default implementation
  /// reads the scan image off the local filesystem.
  @visibleForTesting
  final ImageBytesReader? imageBytesReader;

  /// Injected for widget tests. In production this calls
  /// [FeedbackConsentDialog.show].
  @visibleForTesting
  final ConsentPrompter? consentPrompter;

  /// Injected for widget tests. In production this calls
  /// [FeedbackConsent.read].
  @visibleForTesting
  final ConsentReader? consentReader;

  /// Injected for widget tests. In production this calls
  /// [FeedbackConsent.write].
  @visibleForTesting
  final ConsentWriter? consentWriter;

  const BadScanReportSheet({
    super.key,
    this.kind = ScanKind.receipt,
    this.scan,
    this.pumpScan,
    required this.enteredLiters,
    required this.enteredTotalCost,
    required this.appVersion,
    this.shareFallback,
    this.urlLauncher,
    this.imageBytesReader,
    this.consentPrompter,
    this.consentReader,
    this.consentWriter,
  })  : assert(
          kind == ScanKind.receipt
              ? scan != null
              : pumpScan != null,
          'BadScanReportSheet: scan must be set for ScanKind.receipt, '
          'pumpScan must be set for ScanKind.pumpDisplay.',
        );

  /// Path of the scanned image on disk. Resolves to either the receipt
  /// or the pump-display capture depending on [kind].
  String get _imagePath =>
      kind == ScanKind.receipt ? scan!.imagePath : pumpScan!.imagePath;

  /// Raw OCR text. Same kind dispatch as [_imagePath].
  String get _ocrText =>
      kind == ScanKind.receipt ? scan!.ocrText : pumpScan!.ocrText;

  @override
  ConsumerState<BadScanReportSheet> createState() =>
      _BadScanReportSheetState();
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
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _resolveTitle(l),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l?.badScanReportHint ??
                  "We'll share the receipt photo and both sets of values so "
                      'the next build can learn this layout.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_createdIssueUrl == null) ...[
              _DiffTable(rows: _buildDiffRows(l)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _handleCreateTicket,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bug_report_outlined),
                label: Text(
                  l?.badScanReportCreateTicket ?? 'Create issue',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(),
                child: Text(l?.cancel ?? 'Cancel'),
              ),
            ] else
              _IssueCreatedSurface(
                issueUrl: _createdIssueUrl!,
                onOpenInBrowser: _handleOpenInBrowser,
                onClose: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateTicket() async {
    setState(() => _submitting = true);
    try {
      final reporter =
          await ref.read(githubIssueReporterProvider.future);
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
        final prompter =
            widget.consentPrompter ?? FeedbackConsentDialog.show;
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
        parsedFields: _parsedFields(),
        userCorrections: _userCorrections(),
        imageBytes: await _readImageBytes(),
      );

      if (!mounted) return;
      setState(() => _createdIssueUrl = url);
    } on GithubReporterException catch (e) {
      debugPrint('BadScanReportSheet: GitHub submission failed: $e');
      await _runShareFallback(showSnackbar: true);
    } catch (e) {
      // Secure-storage / image-read / unexpected errors — still fall
      // back so the user can always ship a report.
      debugPrint('BadScanReportSheet: unexpected failure: $e');
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
      text: _buildShareBody(),
      subject: widget.kind == ScanKind.receipt
          ? 'Tankstellen receipt scan issue'
          : 'Tankstellen pump-display scan issue',
    );

    // Show the snackbar before awaiting share() so the message is
    // visible behind / above the system share sheet depending on the
    // platform. The messenger is tied to the Scaffold root, so it
    // outlives this modal sheet.
    if (showSnackbar) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l?.badScanReportFallbackToShare ??
                'Submission failed — manual share',
          ),
        ),
      );
    }

    try {
      await share(params);
    } catch (e) {
      debugPrint('BadScanReportSheet: share fallback itself failed: $e');
    }
  }

  Future<void> _handleOpenInBrowser() async {
    final url = _createdIssueUrl;
    if (url == null) return;
    final launcher = widget.urlLauncher ?? _defaultUrlLauncher;
    try {
      await launcher(url);
    } catch (e) {
      debugPrint('BadScanReportSheet: launchUrl failed: $e');
    }
  }

  Map<String, String?> _parsedFields() {
    if (widget.kind == ScanKind.receipt) {
      final p = widget.scan!.parse;
      return <String, String?>{
        'brandLayout': p.brandLayout,
        'liters': p.liters?.toStringAsFixed(2),
        'totalCost': p.totalCost?.toStringAsFixed(2),
        'pricePerLiter': p.pricePerLiter?.toStringAsFixed(3),
        'stationName': p.stationName,
        'fuelType': p.fuelType?.apiValue,
        'date': p.date?.toIso8601String(),
      };
    }
    final p = widget.pumpScan!.parse;
    return <String, String?>{
      'liters': p.liters?.toStringAsFixed(2),
      'totalCost': p.totalCost?.toStringAsFixed(2),
      'pricePerLiter': p.pricePerLiter?.toStringAsFixed(3),
      'pumpNumber': p.pumpNumber?.toString(),
      'confidence': p.confidence.toStringAsFixed(2),
    };
  }

  Map<String, String?> _userCorrections() {
    return <String, String?>{
      'liters': widget.enteredLiters?.toStringAsFixed(2),
      'totalCost': widget.enteredTotalCost?.toStringAsFixed(2),
    };
  }

  Future<Uint8List> _defaultImageBytesReader(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (e) {
      debugPrint('BadScanReportSheet: could not read scan image: $e');
      return Uint8List(0);
    }
  }

  Future<Uint8List> _readImageBytes() {
    final reader = widget.imageBytesReader ?? _defaultImageBytesReader;
    return reader(widget._imagePath);
  }

  String _buildShareBody() {
    final buffer = StringBuffer();
    if (widget.kind == ScanKind.receipt) {
      final p = widget.scan!.parse;
      buffer
        ..writeln('Tankstellen receipt scan report')
        ..writeln('================================')
        ..writeln('App version: ${widget.appVersion}')
        ..writeln('Brand layout: ${p.brandLayout}')
        ..writeln()
        ..writeln('Scanned → Corrected')
        ..writeln('-------------------')
        ..writeln('Liters:   ${p.liters?.toStringAsFixed(2) ?? '—'}'
            '   →   ${widget.enteredLiters?.toStringAsFixed(2) ?? '(please fill)'}')
        ..writeln('Total:    ${p.totalCost?.toStringAsFixed(2) ?? '—'}'
            '   →   ${widget.enteredTotalCost?.toStringAsFixed(2) ?? '(please fill)'}')
        ..writeln('Price/L:  ${p.pricePerLiter?.toStringAsFixed(3) ?? '—'}')
        ..writeln('Station:  ${p.stationName ?? '—'}')
        ..writeln('Fuel:     ${p.fuelType?.apiValue ?? '—'}')
        ..writeln('Date:     ${p.date?.toIso8601String() ?? '—'}');
    } else {
      final p = widget.pumpScan!.parse;
      buffer
        ..writeln('Tankstellen pump-display scan report')
        ..writeln('=====================================')
        ..writeln('App version: ${widget.appVersion}')
        ..writeln()
        ..writeln('Scanned → Corrected')
        ..writeln('-------------------')
        ..writeln('Liters:   ${p.liters?.toStringAsFixed(2) ?? '—'}'
            '   →   ${widget.enteredLiters?.toStringAsFixed(2) ?? '(please fill)'}')
        ..writeln('Total:    ${p.totalCost?.toStringAsFixed(2) ?? '—'}'
            '   →   ${widget.enteredTotalCost?.toStringAsFixed(2) ?? '(please fill)'}')
        ..writeln('Price/L:  ${p.pricePerLiter?.toStringAsFixed(3) ?? '—'}')
        ..writeln('Pump #:   ${p.pumpNumber?.toString() ?? '—'}')
        ..writeln('Confidence: ${p.confidence.toStringAsFixed(2)}');
    }
    buffer
      ..writeln()
      ..writeln('Raw OCR text')
      ..writeln('------------')
      ..writeln(widget._ocrText);
    return buffer.toString();
  }

  /// Resolves the kind-aware sheet title. Falls back to the original
  /// "Report a scan error" string for both kinds when localization is
  /// not available, then layers per-kind suffixes on top via the
  /// kind-specific keys (#953).
  String _resolveTitle(AppLocalizations? l) {
    switch (widget.kind) {
      case ScanKind.receipt:
        return l?.badScanReportTitleReceipt ??
            l?.badScanReportTitle ??
            'Report a scan error — Receipt';
      case ScanKind.pumpDisplay:
        return l?.badScanReportTitlePumpDisplay ??
            'Report a scan error — Pump display';
    }
  }

  /// Builds the field-by-field diff table rendered above the action
  /// buttons. Receipt shows the rich layout (brand, station, fuel,
  /// date); pump-display shows only the three transaction numbers
  /// plus the pump number when available (#953).
  List<_DiffRow> _buildDiffRows(AppLocalizations? l) {
    if (widget.kind == ScanKind.receipt) {
      final p = widget.scan!.parse;
      return [
        _DiffRow(
          l?.badScanReportFieldBrandLayout ?? 'Brand layout',
          p.brandLayout,
          p.brandLayout,
        ),
        _DiffRow(
          l?.liters ?? 'Liters',
          p.liters?.toStringAsFixed(2) ?? '—',
          widget.enteredLiters?.toStringAsFixed(2) ?? '—',
        ),
        _DiffRow(
          l?.badScanReportFieldTotal ?? 'Total',
          p.totalCost?.toStringAsFixed(2) ?? '—',
          widget.enteredTotalCost?.toStringAsFixed(2) ?? '—',
        ),
        _DiffRow(
          l?.badScanReportFieldPricePerLiter ?? 'Price/L',
          p.pricePerLiter?.toStringAsFixed(3) ?? '—',
          '—',
        ),
        _DiffRow(
          l?.badScanReportFieldStation ?? 'Station',
          p.stationName ?? '—',
          '—',
        ),
        _DiffRow(
          l?.badScanReportFieldFuel ?? 'Fuel',
          p.fuelType?.displayName ?? '—',
          '—',
        ),
        _DiffRow(
          l?.badScanReportFieldDate ?? 'Date',
          p.date?.toIso8601String().split('T').first ?? '—',
          '—',
        ),
      ];
    }
    final p = widget.pumpScan!.parse;
    return [
      _DiffRow(
        l?.liters ?? 'Liters',
        p.liters?.toStringAsFixed(2) ?? '—',
        widget.enteredLiters?.toStringAsFixed(2) ?? '—',
      ),
      _DiffRow(
        l?.badScanReportFieldTotal ?? 'Total',
        p.totalCost?.toStringAsFixed(2) ?? '—',
        widget.enteredTotalCost?.toStringAsFixed(2) ?? '—',
      ),
      _DiffRow(
        l?.badScanReportFieldPricePerLiter ?? 'Price/L',
        p.pricePerLiter?.toStringAsFixed(3) ?? '—',
        '—',
      ),
    ];
  }
}

class _IssueCreatedSurface extends StatelessWidget {
  final Uri issueUrl;
  final Future<void> Function() onOpenInBrowser;
  final VoidCallback onClose;

  const _IssueCreatedSurface({
    required this.issueUrl,
    required this.onOpenInBrowser,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                issueUrl.toString(),
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onOpenInBrowser,
          icon: const Icon(Icons.open_in_new),
          label: Text(
            l?.badScanReportOpenInBrowser ?? 'Open in browser',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClose,
          child: Text(l?.close ?? 'Close'),
        ),
      ],
    );
  }
}

class _DiffRow {
  final String label;
  final String scanned;
  final String real;
  const _DiffRow(this.label, this.scanned, this.real);
}

class _DiffTable extends StatelessWidget {
  final List<_DiffRow> rows;
  const _DiffTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration:
              BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
          children: [
            _cell(l?.badScanReportHeaderField ?? 'Field',
                bold: true, theme: theme),
            _cell(l?.badScanReportHeaderScanned ?? 'Scanned',
                bold: true, theme: theme),
            _cell(l?.badScanReportHeaderYouTyped ?? 'You typed',
                bold: true, theme: theme),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _cell(row.label, theme: theme),
              _cell(row.scanned, theme: theme),
              _cell(row.real, theme: theme),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
        ),
      ),
    );
  }
}
