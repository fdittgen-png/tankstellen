import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Dialog shown when a scanned QR code doesn't match any classification
/// (not a URL, not a known payment scheme, not an EPC Girocode). Lets
/// the user copy the raw text and share a report so the scheme catalog
/// can grow in the next release (#725).
class UnknownQrDialog extends StatelessWidget {
  final String raw;

  /// Clipboard side-effect, injectable for tests. When `null`, the
  /// widget uses [Clipboard.setData] directly.
  final Future<void> Function(String text)? clipboardWriter;

  /// Share side-effect, injectable for tests. Returning normally
  /// counts as "shared".
  final Future<void> Function(String text, String subject)? onShare;

  const UnknownQrDialog({
    super.key,
    required this.raw,
    this.clipboardWriter,
    this.onShare,
  });

  Future<void> _writeClipboard(String text) {
    final fn = clipboardWriter;
    if (fn != null) return fn(text);
    return Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n?.qrPaymentUnknownTitle ?? 'Unrecognised code'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: SingleChildScrollView(
          child: SelectableText(raw),
        ),
      ),
      actions: [
        TextButton.icon(
          key: const Key('unknownQrCopy'),
          onPressed: () async {
            await _writeClipboard(raw);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            SnackBarHelper.showSuccess(
              context,
              l10n?.qrPaymentCopiedRaw ?? 'Copied to clipboard',
            );
          },
          icon: const Icon(Icons.copy),
          label: Text(l10n?.qrPaymentCopyRaw ?? 'Copy raw text'),
        ),
        TextButton.icon(
          key: const Key('unknownQrReport'),
          onPressed: () async {
            final share = onShare;
            Navigator.of(context).pop();
            final body = _buildReportBody(raw);
            if (share != null) {
              await share(body, 'Tankstellen: unrecognised payment QR');
            }
          },
          icon: const Icon(Icons.flag_outlined),
          label: Text(l10n?.qrPaymentReport ?? 'Report this scan'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
      ],
    );
  }

  static String _buildReportBody(String raw) {
    return 'Tankstellen unrecognised payment QR\n'
        '===================================\n'
        'App version: ${AppConstants.appVersion}\n'
        '\n'
        'Raw QR contents\n'
        '---------------\n'
        '$raw\n';
  }
}
