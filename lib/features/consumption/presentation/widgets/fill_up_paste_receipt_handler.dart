// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/ereceipt/ereceipt_text_parser.dart';
import '../../data/receipt_scan_service.dart';
import 'fill_up_scan_handlers.dart';
import 'fill_up_share_scan_handlers.dart';

/// Manual "paste receipt text" entry point for the Add-Fill-up form
/// (#2687 — the autonomous, on-device slice of the e-receipt epic).
///
/// The camera ([runReceiptScan]), image-share ([runSharedReceiptScan]) and
/// text-share ([scheduleSharedReceiptTextIfPending]) paths all already exist;
/// this is the *manual* sibling for the very common case where a digital fuel
/// receipt arrived as plain text the user can copy — an e-mail body, an SMS
/// confirmation, or the selectable text of a PDF — but no app offered to
/// "share" it into Sparkilo. The user pastes it here.
///
/// Fully on-device + free: the text is parsed by the pure-Dart
/// [EReceiptTextParser] (no camera, no OCR, no network, no paid service) and
/// pre-fills the SAME form fields through [applyReceiptOutcome], so a pasted
/// receipt fills the form identically to a scanned one — and is NEVER
/// auto-saved. The user reviews and taps Save exactly as with any other
/// import. Mirrors the share-text snackbar mapping (no-data vs success).
const EReceiptTextParser _textParser = EReceiptTextParser();

/// Opens the paste dialog, parses whatever the user pasted with the
/// on-device [EReceiptTextParser], and pre-fills the host form when fuel
/// data was found. A no-op when the dialog is cancelled or the field is
/// blank. Shows the no-data snackbar when the text carried nothing
/// actionable, and the shared success message (with station hint) otherwise.
///
/// Never throws (#2349): a parse fault is logged and surfaced as the
/// no-data snackbar rather than crashing the form.
Future<void> runPasteReceiptText(
  BuildContext context,
  FillUpScanHostState state, {
  EReceiptTextParser parser = _textParser,
}) async {
  final l = AppLocalizations.of(context);
  final text = await showPasteReceiptDialog(context);
  if (text == null || text.trim().isEmpty || !state.isMounted()) return;

  try {
    // #2687 — thread the active country so the currency-aware extractors
    // read totals/prices in the right currency, identical to the camera /
    // share paths. Unknown country falls back to EUR inside the parser.
    final parsed = parser.parse(text, countryCode: state.activeCountry);
    if (!parsed.hasData) {
      if (state.isMounted() && context.mounted) {
        SnackBarHelper.show(context, l.pasteReceiptNoData);
      }
      return;
    }

    // Wrap in a synthetic outcome (no photo to report) so the pasted text
    // flows through the identical prefill body the camera / share paths
    // use — zero drift between sources. NOT auto-saved.
    final outcome = ReceiptScanOutcome(
      parse: parsed,
      ocrText: text,
      imagePath: '',
    );
    applyReceiptOutcome(state, outcome);
    if (state.isMounted() && context.mounted) {
      SnackBarHelper.show(context, receiptScanSuccessMessage(l, outcome));
    }
  } catch (e, st) {
    unawaited(
      errorLogger.log(
        ErrorLayer.ui,
        e,
        st,
        context: const {'where': 'AddFillUp: paste-receipt parse failed'},
      ),
    );
    if (state.isMounted() && context.mounted) {
      SnackBarHelper.show(context, l.pasteReceiptNoData);
    }
  }
}

/// Shows the multiline paste dialog and returns the entered text, or null
/// when the user cancels / dismisses it. Pure UI — extracted so the
/// orchestration in [runPasteReceiptText] stays free of widget state and
/// the dialog can be exercised on its own. Returns the raw text; trimming
/// and parsing are the caller's job.
Future<String?> showPasteReceiptDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => const _PasteReceiptDialog(),
  );
}

class _PasteReceiptDialog extends StatefulWidget {
  const _PasteReceiptDialog();

  @override
  State<_PasteReceiptDialog> createState() => _PasteReceiptDialogState();
}

class _PasteReceiptDialogState extends State<_PasteReceiptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.pasteReceiptDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.pasteReceiptDialogHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('paste_receipt_text_field'),
              controller: _controller,
              autofocus: true,
              maxLines: 8,
              minLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l.pasteReceiptFieldHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('paste_receipt_confirm_button'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l.pasteReceiptParseAction),
        ),
      ],
    );
  }
}
