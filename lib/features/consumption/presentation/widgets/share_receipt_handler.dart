// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_handler/share_handler.dart';

import '../../../../app/router.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/navigation/root_navigator_key.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../data/ocr/receipt_pdf_rasterizer.dart';
import '../../providers/pending_shared_receipt_provider.dart';

part 'share_receipt_handler.g.dart';

/// Routes an inbound OS share ([SharedMedia]) onto the live app: an
/// image attachment is stashed in [pendingSharedReceiptProvider] and the
/// router is pushed to `/consumption/add`, where the Add-fill-up screen
/// consumes the stash and OCRs the receipt via `runSharedReceiptScan`
/// (#2734).
///
/// A shared **PDF** (#2737) is first rasterised on-device to a JPEG via
/// [ReceiptPdfRasterizer] and then takes the EXACT same stash + route +
/// OCR path as an image — `parseReceiptImage` never knows the bitmap came
/// from a PDF. When rasterisation fails (corrupt PDF, or the native
/// renderer is unavailable) it shows the graceful #2735 `shareReceipt
/// Failed` message. Any other attachment type (video / arbitrary file)
/// still shows `shareReceiptUnsupportedFormat`.
///
/// Split out from [ShareReceiptListener] so the routing + gating logic is
/// unit-testable without pumping the full widget tree — the same shape
/// (and debugging history) as [NotificationLaunchHandler] /
/// [WidgetLaunchHandler]. Reading the router from the provider (not
/// `GoRouter.of(context)`) sidesteps the `InheritedGoRouter`-above-the-
/// builder trap those classes documented.
///
/// **Never throws** (#2349): every public entry is wrapped so a decode /
/// push / snackbar failure routes through [errorLogger] and the user is
/// never crashed back to the launcher by a malformed share. The sibling
/// `share_receipt_handler_test.dart` pins this with fault injection.
class ShareReceiptHandler {
  final Ref _ref;
  final ReceiptPdfRasterizer _pdfRasterizer;

  ShareReceiptHandler(this._ref, {ReceiptPdfRasterizer? pdfRasterizer})
      : _pdfRasterizer = pdfRasterizer ?? const ReceiptPdfRasterizer();

  /// Handle one inbound [media]. No-op for a null media, an empty
  /// attachment list, or — defensively — when the feature is gated off.
  ///
  /// Returns normally on any failure (#2349): a thrown error from the
  /// router push or a missing localized context must not propagate out
  /// of the platform stream callback.
  void handle(SharedMedia? media) {
    try {
      if (media == null) return;
      // The share-intent receiver is opt-in (#2735) — when the user has
      // not enabled it, silently drop the share rather than navigating.
      // Gated here (not only at the listener) so a direct handler call
      // from a test or a future caller honours the same flag.
      if (!_featureEnabled()) return;

      final attachments = media.attachments
              ?.whereType<SharedAttachment>()
              .toList() ??
          const <SharedAttachment>[];
      if (attachments.isEmpty) return;

      // First image wins — receipts are single photos in practice; a
      // SEND_MULTIPLE batch still prefills from the first image and the
      // user can re-share the rest.
      final image = attachments
          .where((a) => a.type == SharedAttachmentType.image)
          .firstOrNull;
      if (image != null) {
        _stashAndRoute(image.path);
        return;
      }

      // No image — a shared PDF (#2737) is rasterised to a bitmap and then
      // takes the same path. `share_handler` carries PDFs as `file`
      // attachments (it has no `pdf` type and no MIME on the attachment),
      // so we recognise them by extension. The render is async, so the
      // outcome is handled in [_rasterizeAndRoute]; `handle` stays
      // synchronous + never-throws by fire-and-forgetting it.
      final pdf = attachments
          .where((a) =>
              a.type == SharedAttachmentType.file &&
              a.path.toLowerCase().endsWith('.pdf'))
          .firstOrNull;
      if (pdf != null) {
        unawaited(_rasterizeAndRoute(pdf.path));
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
  /// `runSharedReceiptScan` (#2734). Shared by the image and PDF paths —
  /// a rasterised PDF page is just a JPEG by the time it reaches here.
  void _stashAndRoute(String path) {
    _ref.read(pendingSharedReceiptProvider.notifier).set(path);
    debugPrint('ShareReceiptHandler.handle stashed $path');
    _push('/consumption/add');
  }

  /// Rasterises the shared PDF at [path] to a JPEG (off the UI thread via
  /// the native renderer) and, on success, takes the SAME stash + route +
  /// OCR path as an image share. On failure ([ReceiptPdfRasterizer]
  /// returns null — corrupt PDF, or no native renderer) it shows the
  /// graceful #2735 `shareReceiptFailed` message. Never throws (#2349):
  /// the rasteriser already swallows its own faults, and this wrapper
  /// catches anything the route push could raise.
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
      _ref.read(routerProvider).push(path);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: {
        'where': 'ShareReceiptHandler: push failed for $path',
      }));
    }
  }

  /// Surfaces the localized "unsupported format" snackbar for a shared
  /// PDF / non-image attachment. Reaches a navigator-bearing context via
  /// the root navigator key so the message shows even though the share
  /// arrived from above the navigator. No-op when no context is mounted.
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

  /// Surfaces the localized "couldn't read the receipt" snackbar for a
  /// PDF that could not be rasterised (#2737), reusing the #2735
  /// `shareReceiptFailed` key — the file type IS supported, the read just
  /// failed, so the message asks the user to retry rather than implying
  /// the format is rejected.
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

/// The on-device PDF→bitmap rasteriser the handler feeds shared PDFs
/// through (#2737). Exposed as its own provider so a test can override it
/// with a fake — the native PdfRenderer is unavailable under `flutter
/// test`, so the PDF branch is unit-tested by injecting a fake that
/// returns a known JPEG path (success) or null (graceful fallback),
/// asserting it routes to the SAME stash+OCR path as an image.
@riverpod
ReceiptPdfRasterizer receiptPdfRasterizer(Ref ref) =>
    const ReceiptPdfRasterizer();

@riverpod
ShareReceiptHandler shareReceiptHandler(Ref ref) => ShareReceiptHandler(
      ref,
      pdfRasterizer: ref.read(receiptPdfRasterizerProvider),
    );
