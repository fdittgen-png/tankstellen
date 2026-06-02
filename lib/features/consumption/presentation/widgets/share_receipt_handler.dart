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
import '../../providers/pending_shared_receipt_provider.dart';

part 'share_receipt_handler.g.dart';

/// Routes an inbound OS share ([SharedMedia]) onto the live app: an
/// image attachment is stashed in [pendingSharedReceiptProvider] and the
/// router is pushed to `/consumption/add`, where the Add-fill-up screen
/// consumes the stash and OCRs the receipt via `runSharedReceiptScan`
/// (#2734). A non-image attachment (e.g. a shared PDF) shows a graceful
/// "unsupported format — coming soon" message; PDF rasterisation is a
/// separate child (#2737) that will reuse the same `shareReceipt
/// UnsupportedFormat` key.
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

  ShareReceiptHandler(this._ref);

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
      // user can re-share the rest. A non-image first attachment (PDF /
      // file) takes the unsupported-format branch.
      final image = attachments
          .where((a) => a.type == SharedAttachmentType.image)
          .firstOrNull;
      if (image == null) {
        _showUnsupportedFormat();
        return;
      }

      _ref
          .read(pendingSharedReceiptProvider.notifier)
          .set(image.path);
      debugPrint('ShareReceiptHandler.handle stashed image ${image.path}');
      _push('/consumption/add');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'ShareReceiptHandler.handle',
      }));
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
}

@riverpod
ShareReceiptHandler shareReceiptHandler(Ref ref) => ShareReceiptHandler(ref);
