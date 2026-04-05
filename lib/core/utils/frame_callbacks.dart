import 'package:flutter/widgets.dart';

/// Post-frame callback helper that guards against `setState`-after-dispose.
///
/// `WidgetsBinding.instance.addPostFrameCallback` fires one frame later, which
/// is long enough for the widget to be unmounted. Callers that reach for
/// `setState` or `ref.read`/`ref.watch` from inside the callback must therefore
/// re-check `mounted` first. This extension centralises that guard so callers
/// no longer have to remember.
extension SafePostFrameCallbackOnState on State {
  /// Runs [callback] after the next frame, but only if this [State] is still
  /// mounted at that point.
  void safePostFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback();
    });
  }
}
