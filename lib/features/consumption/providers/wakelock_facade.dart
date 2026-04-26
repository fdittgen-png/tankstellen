import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'wakelock_facade.g.dart';

/// Thin seam over `wakelock_plus` so the trip-recording pin toggle
/// (#891) can be unit-tested without pulling the plugin's platform
/// channel into widget tests. The default implementation in
/// [wakelockFacadeProvider] delegates to [WakelockPlus.enable] /
/// [WakelockPlus.disable]; tests inject a fake via
/// `overrideWithValue(FakeWakelockFacade())`.
abstract class WakelockFacade {
  /// Keep the screen awake until [disable] is called. Safe to call
  /// multiple times — implementations are idempotent.
  Future<void> enable();

  /// Release a previously acquired wake lock. Safe to call when the
  /// lock was never enabled — treated as a no-op.
  Future<void> disable();
}

/// Production implementation backed by `wakelock_plus`. Swallows
/// plugin errors (e.g. unsupported platforms in widget tests) so the
/// pin toggle never crashes the recording screen; a failed plugin
/// call just means the screen may dim on schedule — not ideal, but
/// no worse than the pre-#891 behaviour.
class RealWakelockFacade implements WakelockFacade {
  const RealWakelockFacade();

  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (e, st) {
      debugPrint('WakelockFacade.enable failed: $e\n$st');
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (e, st) {
      debugPrint('WakelockFacade.disable failed: $e\n$st');
    }
  }
}

/// Provider seam — override in tests with a fake. `keepAlive: true`
/// because the pin toggle on [TripRecordingScreen] is ephemeral UI
/// state but the underlying facade has no per-screen state worth
/// rebuilding.
@Riverpod(keepAlive: true)
WakelockFacade wakelockFacade(Ref ref) => const RealWakelockFacade();
