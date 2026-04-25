import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/feedback/github_issue_reporter.dart';
import '../../../../core/feedback/github_issue_reporter_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/receipt_scan_service.dart';

/// Share callback signature so widget tests can substitute the
/// [SharePlus] platform channel with a Dart-only fake. Production
/// code passes [_defaultShareFallback].
typedef ShareFallback = Future<void> Function(ShareParams params);

/// URL-launcher callback signature, same rationale as [ShareFallback].
typedef UrlLauncher = Future<bool> Function(Uri uri);

/// Reads the raw bytes of the scanned image. Defaults to
/// `File(path).readAsBytes()`; widget tests inject a Dart-only fake.
typedef ImageBytesReader = Future<Uint8List> Function(String path);

/// Bottom sheet the user opens when the scanned receipt values are
/// wrong. Two submit paths:
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
/// Phase 2 does NOT introduce the token-entry UI or the consent dialog
/// — both ship in #952 phase 3 alongside EXIF stripping.
class BadScanReportSheet extends ConsumerStatefulWidget {
  final ReceiptScanOutcome scan;
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

  const BadScanReportSheet({
    super.key,
    required this.scan,
    required this.enteredLiters,
    required this.enteredTotalCost,
    required this.appVersion,
    this.shareFallback,
    this.urlLauncher,
    this.imageBytesReader,
  });

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
    final p = widget.scan.parse;
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
              l?.badScanReportTitle ?? 'Report a scan error',
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
              _DiffTable(
                rows: [
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
                ],
              ),
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
        // sheet (phase 2 behaviour). Phase 3 adds a token-entry UI.
        await _runShareFallback(showSnackbar: false);
        return;
      }

      final url = await reporter.reportBadScan(
        kind: ScanKind.receipt,
        rawOcrText: widget.scan.ocrText,
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
      files: [XFile(widget.scan.imagePath)],
      text: _buildShareBody(),
      subject: 'Tankstellen receipt scan issue',
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
    final p = widget.scan.parse;
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
    return reader(widget.scan.imagePath);
  }

  String _buildShareBody() {
    final p = widget.scan.parse;
    final buffer = StringBuffer()
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
      ..writeln('Date:     ${p.date?.toIso8601String() ?? '—'}')
      ..writeln()
      ..writeln('Raw OCR text')
      ..writeln('------------')
      ..writeln(widget.scan.ocrText);
    return buffer.toString();
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
