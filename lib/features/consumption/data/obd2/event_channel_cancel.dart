import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// EventChannel-aware [StreamSubscription.cancel] wrapper.
///
/// EventChannel-backed broadcast streams raise a benign
/// `PlatformException("No active stream to cancel")` when the platform
/// side has already cleared the broadcast (background foreground-service
/// kills, lifecycle race during tab navigation). The platform IS already
/// torn down — there is nothing to do, but Flutter still rethrows the
/// exception through the cancel future, where it bubbles up into the
/// privacy-dashboard error log and masks real bugs (#1323).
///
/// Use this extension at every call site that cancels an EventChannel
/// subscription. Every other error type and every other PlatformException
/// message is rethrown unchanged.
extension SafeEventChannelCancel<T> on StreamSubscription<T> {
  /// Cancels this subscription, swallowing the benign EventChannel
  /// "No active stream to cancel" PlatformException only.
  Future<void> safeCancel() async {
    try {
      await cancel();
    } on PlatformException catch (e) {
      if (e.message == 'No active stream to cancel') {
        debugPrint(
          'EventChannel safeCancel: swallowed benign '
          'PlatformException(${e.code}: ${e.message})',
        );
        return;
      }
      rethrow;
    }
  }
}
