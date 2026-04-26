import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/qr_payment_decoder.dart';

/// Outcome returned by [ScanPaymentDispatcher.handle] so the UI knows
/// what feedback to surface (snackbar, confirmation dialog, fallback
/// sheet). Kept separate from the sealed [QrPaymentTarget] because the
/// target describes the QR contents, while this describes what actually
/// happened after the dispatch.
enum ScanPaymentOutcome {
  /// An external app or browser was launched successfully.
  launched,

  /// An EPC SEPA Girocode was decoded and the confirmation dialog was
  /// shown. Actual banking-app hand-off happens after user confirms.
  confirmEpc,

  /// The code could not be classified into an actionable category —
  /// UI should show the raw value with copy / report options.
  unknown,

  /// Launcher returned false (no resolving app on the device).
  launchFailed,
}

/// Result of attempting to hand an EPC Girocode off to a banking app.
enum EpcLaunchOutcome {
  /// A banking-app URI handler was found and launched.
  launched,

  /// No handler was available, but the IBAN + amount were copied to
  /// the clipboard so the user can paste them manually.
  copiedToClipboard,

  /// Neither launch nor clipboard write succeeded — the caller should
  /// show an error snackbar and keep the dialog open.
  failed,
}

/// Dispatches a decoded QR payment target to the right side-effect —
/// url_launcher for web URLs and known payment app schemes, a
/// confirmation dialog for EPC SEPA Girocodes, a fallback sheet for
/// unknown content.
///
/// Pure-ish: only touches `url_launcher` and the supplied
/// [BuildContext]. Tests override [launcher] / [probe] to avoid the
/// real plugin, just like [PaymentAppLauncher] in
/// `lib/core/utils/payment_app_launcher.dart`.
class ScanPaymentDispatcher {
  ScanPaymentDispatcher._();

  @visibleForTesting
  static Future<bool> Function(Uri uri, {LaunchMode mode}) launcher =
      _defaultLauncher;

  @visibleForTesting
  static Future<bool> Function(Uri uri) probe = _defaultProbe;

  /// Clipboard side-effect, isolated so tests don't need the Flutter
  /// test binding's platform channel.
  @visibleForTesting
  static Future<void> Function(String text) clipboardWriter =
      _defaultClipboardWriter;

  @visibleForTesting
  static void resetForTesting() {
    launcher = _defaultLauncher;
    probe = _defaultProbe;
    clipboardWriter = _defaultClipboardWriter;
  }

  static Future<void> _defaultClipboardWriter(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  static Future<bool> _defaultLauncher(Uri uri, {LaunchMode? mode}) =>
      launchUrl(uri, mode: mode ?? LaunchMode.externalApplication);

  static Future<bool> _defaultProbe(Uri uri) => canLaunchUrl(uri);

  /// Dispatch [target] to the appropriate side-effect. Returns the
  /// outcome so the caller can show feedback.
  ///
  /// Context is optional — the dispatcher never tries to show UI
  /// itself for the `launched` / `launchFailed` paths; callers wire
  /// the EPC confirmation dialog + unknown-fallback sheet on the
  /// returned enum.
  static Future<ScanPaymentOutcome> handle(QrPaymentTarget target) async {
    switch (target) {
      case QrPaymentUrl(:final url):
        return _tryLaunch(Uri.parse(url));
      case QrPaymentAppLink(:final uri):
        return _tryLaunch(Uri.parse(uri));
      case QrPaymentEpc():
        return ScanPaymentOutcome.confirmEpc;
      case QrPaymentUnknown():
        return ScanPaymentOutcome.unknown;
    }
  }

  static Future<ScanPaymentOutcome> _tryLaunch(Uri uri) async {
    try {
      final ok = await launcher(uri, mode: LaunchMode.externalApplication);
      return ok
          ? ScanPaymentOutcome.launched
          : ScanPaymentOutcome.launchFailed;
    } on Exception catch (e, st) {
      debugPrint('ScanPaymentDispatcher launch failed: $e\n$st');
      return ScanPaymentOutcome.launchFailed;
    }
  }

  /// Attempts to hand an EPC Girocode [epc] off to a banking app.
  /// Strategy, in order:
  /// 1. `sepa://transfer?...` — the community-convention scheme a few
  ///    open-source banking apps accept.
  /// 2. `iban://<IBAN>?...` — broader fallback that some German apps
  ///    (e.g. banking-4) advertise.
  /// 3. Copy the IBAN + amount + beneficiary to the clipboard so the
  ///    user can paste into their bank app manually.
  ///
  /// Returns the [EpcLaunchOutcome] so the UI can pick the right
  /// snackbar. The caller remains responsible for showing feedback.
  static Future<EpcLaunchOutcome> tryLaunchEpc(QrPaymentEpc epc) async {
    final iban = epc.iban?.trim();
    if (iban == null || iban.isEmpty) return EpcLaunchOutcome.failed;

    final amountStr = epc.amountEur?.toStringAsFixed(2);
    final params = <String, String>{
      'iban': iban,
      if (epc.beneficiary != null && epc.beneficiary!.isNotEmpty)
        'name': epc.beneficiary!,
      'amount': ?amountStr,
    };

    for (final scheme in const ['sepa', 'iban']) {
      final uri = Uri(scheme: scheme, host: 'transfer', queryParameters: params);
      try {
        if (await probe(uri)) {
          final launched = await launcher(uri,
              mode: LaunchMode.externalApplication);
          if (launched) return EpcLaunchOutcome.launched;
        }
      } on Exception catch (e, st) {
        debugPrint('tryLaunchEpc $scheme failed: $e\n$st');
      }
    }

    final clipboard = [
      if (epc.beneficiary != null && epc.beneficiary!.isNotEmpty)
        'Beneficiary: ${epc.beneficiary}',
      'IBAN: $iban',
      if (amountStr != null) 'Amount: $amountStr EUR',
    ].join('\n');
    try {
      await clipboardWriter(clipboard);
      return EpcLaunchOutcome.copiedToClipboard;
    } on Exception catch (e, st) {
      debugPrint('tryLaunchEpc clipboard failed: $e\n$st');
      return EpcLaunchOutcome.failed;
    }
  }

  /// Build the confirmation dialog content for an EPC SEPA Girocode.
  /// Separated from [handle] so widget tests can render the dialog
  /// without running the full launcher machinery.
  static Widget buildEpcDialog(BuildContext context, QrPaymentEpc epc) {
    final l10n = AppLocalizations.of(context);
    final items = <Widget>[
      if (epc.beneficiary != null && epc.beneficiary!.isNotEmpty)
        ListTile(
          dense: true,
          title: Text(l10n?.qrPaymentBeneficiary ?? 'Beneficiary'),
          subtitle: Text(epc.beneficiary!),
        ),
      if (epc.iban != null && epc.iban!.isNotEmpty)
        ListTile(
          dense: true,
          title: const Text('IBAN'),
          subtitle: Text(epc.iban!),
        ),
      if (epc.amountEur != null)
        ListTile(
          dense: true,
          title: Text(l10n?.qrPaymentAmount ?? 'Amount'),
          subtitle: Text('${epc.amountEur!.toStringAsFixed(2)} €'),
        ),
    ];
    return AlertDialog(
      title: Text(l10n?.qrPaymentEpcTitle ?? 'SEPA payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.isEmpty
            ? [Text(l10n?.qrPaymentEpcEmpty ?? 'No fields decoded')]
            : items,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n?.qrPaymentOpenInBank ?? 'Open in bank app'),
        ),
      ],
    );
  }
}
