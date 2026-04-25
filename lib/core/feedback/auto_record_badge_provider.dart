import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auto_record_badge_service.dart';

part 'auto_record_badge_provider.g.dart';

/// Process-wide singleton for the auto-record badge counter
/// (#1004 phase 5).
///
/// `keepAlive` because the badge needs to stay coherent for the
/// lifetime of the app — the trip-save path may call `increment`
/// from a background isolate hand-off and the detail screen may
/// `decrement` minutes later. Re-creating the service per-route
/// would lose in-flight writes.
///
/// Returned as `AsyncValue<AutoRecordBadgeService>` because resolving
/// `SharedPreferences` is asynchronous. Callers that need immediate
/// access should await the future; UI consumers can `when` over it.
@Riverpod(keepAlive: true)
Future<AutoRecordBadgeService> autoRecordBadgeService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AutoRecordBadgeService(prefs: prefs);
}

/// Reactive counter mirroring [AutoRecordBadgeService.count] for UI
/// consumers (#1004 phase 6). The service writes to
/// `SharedPreferences` synchronously but does not notify; this
/// provider re-reads the value on demand and on `markAllAsRead`
/// invocations so the trip-history AppBar badge stays in step with
/// the launcher icon.
@Riverpod(keepAlive: true)
class AutoRecordBadgeCount extends _$AutoRecordBadgeCount {
  @override
  int build() {
    // Initial best-effort read. The service future may not have
    // resolved yet on cold start — return 0 in that case and the
    // service-side increment/decrement will refresh us via
    // [refresh] once a real value is known.
    final asyncService = ref.watch(autoRecordBadgeServiceProvider);
    return asyncService.maybeWhen(
      data: (service) => service.count,
      orElse: () => 0,
    );
  }

  /// Re-read the counter from the service. Called after explicit
  /// mutations (mark-all-as-read, decrement-on-view) so any other
  /// widget watching this provider rebuilds without waiting for a
  /// route change.
  Future<void> refresh() async {
    try {
      final service = await ref.read(autoRecordBadgeServiceProvider.future);
      state = service.count;
    } catch (e) {
      debugPrint('AutoRecordBadgeCount refresh: $e');
    }
  }

  /// Reset the underlying counter to 0 and refresh local state.
  /// Backs the trip-history "Mark all as read" affordance.
  Future<void> markAllAsRead() async {
    try {
      final service = await ref.read(autoRecordBadgeServiceProvider.future);
      await service.markAllAsRead();
      state = service.count;
    } catch (e) {
      debugPrint('AutoRecordBadgeCount markAllAsRead: $e');
    }
  }
}
