// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/error_logger.dart';
import '../../data/share/share_intent_channel.dart';
import '../../data/share/shared_receipt_intent.dart';
import 'share_receipt_handler.dart';

/// Listens for an inbound OS share intent and routes the shared receipt to
/// the Add-fill-up form (#2735 / Epic #2687).
///
/// GMS-free: reads from the in-repo [ShareIntentChannel] (an app-internal
/// MethodChannel/EventChannel on `MainActivity`) rather than the dropped
/// `share_handler` plugin, so the F-Droid build pulls no extra share
/// dependency that could drag in Play Services.
///
/// Two code paths — mirrors [NotificationLaunchListener] exactly:
///
/// 1. **Cold start** — the user shared a receipt while Sparkilo was killed.
///    [ShareIntentChannel.getInitialShare] surfaces the share the OS handed
///    the freshly-launched activity. The router may not have attached its
///    Navigator yet, so the dispatch is deferred to `addPostFrameCallback`
///    (same race the home-widget cold-launch stash fixed at #widget-deeplink).
/// 2. **Warm share** — the app is already running. [ShareIntentChannel.shareStream]
///    emits the share and we dispatch immediately.
///
/// Both paths funnel through [ShareReceiptHandler] so the routing /
/// feature-gating logic has a single, tested entry point.
///
/// **Never throws** (#2349): the cold-launch probe and the stream
/// subscription are each wrapped so a platform-channel fault or a throwing
/// downstream handler routes through [errorLogger] instead of crashing.
class ShareReceiptListener extends ConsumerStatefulWidget {
  final Widget child;

  /// Test seam — supplies the channel the listener reads cold / warm shares
  /// from. Production passes `null` and the listener uses
  /// [ShareIntentChannel.instance]; widget tests inject a fake whose stream +
  /// initial share they control (and whose stream can be made to throw, for
  /// the #2349 fault-injection contract).
  final ShareIntentChannel? shareChannel;

  const ShareReceiptListener({
    super.key,
    required this.child,
    this.shareChannel,
  });

  @override
  ConsumerState<ShareReceiptListener> createState() =>
      _ShareReceiptListenerState();
}

class _ShareReceiptListenerState extends ConsumerState<ShareReceiptListener> {
  StreamSubscription<SharedReceiptIntent>? _subscription;

  ShareIntentChannel get _channel =>
      widget.shareChannel ?? ShareIntentChannel.instance;

  @override
  void initState() {
    super.initState();
    _handleColdShare();
    _listenWarmShares();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  /// Reads the share the OS delivered on cold launch (if any) and dispatches
  /// it after the first frame so the router's Navigator is attached. A null
  /// initial share is a no-op.
  Future<void> _handleColdShare() async {
    try {
      final intent = await _channel.getInitialShare();
      WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch(intent));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'ShareReceiptListener: cold-share probe failed',
      }));
    }
  }

  /// Subscribes to warm shares. `onError` is wired so a platform-channel
  /// error event on the stream never escapes as an unhandled async error
  /// (#2349) — it is logged and the subscription keeps listening.
  void _listenWarmShares() {
    try {
      _subscription = _channel.shareStream.listen(
        _dispatch,
        onError: (Object e, StackTrace st) {
          unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
            'where': 'ShareReceiptListener: warm-share stream error',
          }));
        },
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'ShareReceiptListener: stream subscribe failed',
      }));
    }
  }

  void _dispatch(SharedReceiptIntent? intent) {
    if (!mounted) return;
    if (intent == null) return;
    // The handler is itself never-throws, but guard the provider read too so
    // a disposed container during teardown can't surface an error.
    try {
      ref.read(shareReceiptHandlerProvider).handle(intent);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'ShareReceiptListener._dispatch',
      }));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
