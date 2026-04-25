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
