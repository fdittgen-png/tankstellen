// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/router.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/root_navigator_key.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../data/ereceipt/ereceipt_text_parser.dart';
import '../../data/ocr/receipt_pdf_rasterizer.dart';
import '../../data/share/shared_receipt_intent.dart';
import '../../providers/pending_shared_receipt_provider.dart';
import '../../providers/pending_shared_receipt_text_provider.dart';

part 'share_receipt_handler.g.dart';

/// Routes an inbound OS share ([SharedReceiptIntent]) onto the live app
/// (#2735, GMS-free rewrite — the `share_handler` plugin was dropped to keep
/// the F-Droid build free of any Play-Services risk; the share now arrives
/// via the in-repo [ShareIntentChannel]).
///
/// Three input shapes, one prefill destination — the Add-fill-up form:
///
///   * **image** (`image/*`): stashed in [pendingSharedReceiptProvider] and
///     the router pushed to `/consumption/add`, where the screen consumes the
///     stash and OCRs the receipt via `runSharedReceiptScan` (#2734).
///   * **PDF** (`application/pdf`, #2737): rasterised on-device to a JPEG via
///     [ReceiptPdfRasterizer] and then taking the EXACT same stash + route +
///     OCR path as an image — `parseReceiptImage` never knows the bitmap came
///     from a PDF. A failed rasterisation shows the graceful
///     `shareReceiptFailed` message.
///   * **text** (`EXTRA_TEXT` / `text/*`, #2838): parsed at receive time by
///     the pure-Dart [EReceiptTextParser] (no OCR, no file). The parsed
///     result is stashed in [pendingSharedReceiptTextProvider] and the screen
///     prefills the form through the SAME `applyReceiptOutcome` body — so a
///     text e-receipt fills the form with zero drift from a photo scan.
///
/// Any other attachment type (video / arbitrary file) shows
/// `shareReceiptUnsupportedFormat`.
///
/// Split out from `ShareReceiptListener` so the routing + gating logic is
/// unit-testable without pumping the full widget tree — the same shape as
/// [NotificationLaunchHandler]. Reading the router from the provider (not
/// `GoRouter.of(context)`) sidesteps the `InheritedGoRouter`-above-the-builder
/// trap.
///
/// **Never throws** (#2349): every public entry is wrapped so a decode /
/// push / snackbar / parse failure routes through [errorLogger] and the user
/// is never crashed back to the launcher by a malformed share.
class ShareReceiptHandler {
  final Ref _ref;
  final ReceiptPdfRasterizer _pdfRasterizer;
  final EReceiptTextParser _textParser;

  ShareReceiptHandler(
    this._ref, {
    ReceiptPdfRasterizer? pdfRasterizer,
    EReceiptTextParser textParser = const EReceiptTextParser(),
  })  : _pdfRasterizer = pdfRasterizer ?? const ReceiptPdfRasterizer(),
        _textParser = textParser;

  /// Handle one inbound [intent]. No-op for a null intent, an empty item
  /// list, or — defensively — when the feature is gated off.
  ///
  /// Returns normally on any failure (#2349): a thrown error from the router
  /// push, the text parser, or a missing localized context must not propagate
  /// out of the platform stream callback.
  void handle(SharedReceiptIntent? intent) {
    try {
      if (intent == null || intent.isEmpty) return;
      // The share-intent receiver is opt-in (#2735) — when the user has not
      // enabled it, silently drop the share rather than navigating. Gated
      // here (not only at the listener) so a direct handler call from a test
      // or a future caller honours the same flag.
      if (!_featureEnabled()) return;

      final items = intent.items;

      // First image wins — receipts are single photos in practice; a
      // SEND_MULTIPLE batch still prefills from the first image.
      final image = items
          .where((i) => i.kind == SharedReceiptItemKind.image)
          .firstOrNull;
      if (image?.path != null) {
        _stashAndRoute(image!.path!);
        return;
      }

      // No image — a shared PDF (#2737) is rasterised to a bitmap and then
      // takes the same path. The render is async, so `handle` stays
      // synchronous + never-throws by fire-and-forgetting it.
      final pdf =
          items.where((i) => i.kind == SharedReceiptItemKind.pdf).firstOrNull;
      if (pdf?.path != null) {
        unawaited(_rasterizeAndRoute(pdf!.path!));
        return;
      }

      // No image / PDF — a shared text e-receipt (#2838) is parsed on the
      // spot and the result stashed for the form to apply.
      final text =
          items.where((i) => i.kind == SharedReceiptItemKind.text).firstOrNull;
      if (text?.text != null) {
        _parseTextAndRoute(text!.text!, intent.countryCode);
        return;
      }

      // Any other type (video / arbitrary file) is genuinely unsupported.
      _showUnsupportedFormat();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'ShareReceiptHandler.handle',
      }));
    }
  }

  /// Stashes the receipt-image [path] and routes to the Add-fill-up form,
  /// where the screen consumes the stash and OCRs it via
  /// `runSharedReceiptScan` (#2734). Shared by the image and PDF paths.
  void _stashAndRoute(String path) {
    _ref.read(pendingSharedReceiptProvider.notifier).set(path);
    debugPrint('ShareReceiptHandler.handle stashed image $path');
    _push(RoutePaths.addFillUp);
  }

  /// Rasterises the shared PDF at [path] to a JPEG and, on success, takes the
  /// SAME stash + route + OCR path as an image share. On failure shows the
  /// graceful `shareReceiptFailed` message. Never throws (#2349).
  Future<void> _rasterizeAndRoute(String path) async {
    try {
      final jpegPath = await _pdfRasterizer.rasterize(path);
      if (jpegPath == null) {
        _showReadFailed();
        return;
      }
      _stashAndRoute(jpegPath);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'ShareReceiptHandler._rasterizeAndRoute',
      }));
      _showReadFailed();
    }
  }

  /// Parses a shared e-receipt [text] body with the pure-Dart
  /// [EReceiptTextParser] (#2838) and, when it yielded fuel data, stashes the
  /// result in [pendingSharedReceiptTextProvider] and routes to the form.
  /// When nothing parseable was found it shows the graceful
  /// `shareReceiptFailed` message rather than routing to a blank form.
  void _parseTextAndRoute(String text, String? countryCode) {
    final result = _textParser.parse(text, countryCode: countryCode);
    if (!result.hasData) {
      debugPrint('ShareReceiptHandler: shared text had no parseable receipt');
      _showReadFailed();
      return;
    }
    _ref.read(pendingSharedReceiptTextProvider.notifier).set(result);
    debugPrint('ShareReceiptHandler.handle stashed parsed text result');
    _push(RoutePaths.addFillUp);
  }

  bool _featureEnabled() {
    try {
      return _ref
          .read(enabledFeaturesProvider)
          .contains(Feature.addFillUpShareIntentReceipt);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'ShareReceiptHandler._featureEnabled',
      }));
      return false;
    }
  }

  void _push(String path) {
    try {
      unawaited(_ref.read(routerProvider).push(path));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: {
        'where': 'ShareReceiptHandler: push failed for $path',
      }));
    }
  }

  /// Surfaces the localized "unsupported format" snackbar for a non-image /
  /// non-PDF / non-text attachment. Reaches a navigator-bearing context via
  /// the root navigator key. No-op when no context is mounted.
  void _showUnsupportedFormat() {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.show(
      context,
      l?.shareReceiptUnsupportedFormat ??
          'That file type can\'t be imported yet — share a photo of the '
              'receipt instead.',
    );
  }

  /// Surfaces the localized "couldn't read the receipt" snackbar for a PDF
  /// that could not be rasterised (#2737) or a shared text body with no
  /// parseable fuel data (#2838), reusing the `shareReceiptFailed` key — the
  /// format IS supported, the read just failed.
  void _showReadFailed() {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.show(
      context,
      l?.shareReceiptFailed ??
          'Couldn\'t read the shared receipt — try sharing it again or add '
              'the fill-up manually.',
    );
  }
}

/// The on-device PDF→bitmap rasteriser the handler feeds shared PDFs through
/// (#2737). Exposed as its own provider so a test can override it with a fake
/// — the native PdfRenderer is unavailable under `flutter test`.
@riverpod
ReceiptPdfRasterizer receiptPdfRasterizer(Ref ref) =>
    const ReceiptPdfRasterizer();

@riverpod
ShareReceiptHandler shareReceiptHandler(Ref ref) => ShareReceiptHandler(
      ref,
      pdfRasterizer: ref.read(receiptPdfRasterizerProvider),
    );
