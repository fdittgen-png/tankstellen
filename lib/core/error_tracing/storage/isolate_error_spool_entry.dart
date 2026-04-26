import 'package:freezed_annotation/freezed_annotation.dart';

part 'isolate_error_spool_entry.freezed.dart';
part 'isolate_error_spool_entry.g.dart';

/// One entry in the [IsolateErrorSpool] ring buffer (#1105).
///
/// The WorkManager isolate cannot reach Riverpod or
/// `TraceRecorder`, so failures inside `_refreshPricesAndCheckAlerts`
/// (and the velocity / radius runners it dispatches to) write a
/// minimal record to a Hive ring buffer instead. The foreground
/// `AppInitializer` drains the ring buffer once `TraceRecorder` is
/// available, replaying every stored entry through
/// `traceRecorder.record()` so background failures land in the same
/// observability pipeline as foreground errors.
///
/// `context` is intentionally a plain JSON map: the isolate has no
/// way to construct the rich [AppStateSnapshot] / [DeviceInfo]
/// collectors that live in the main isolate, so callers attach
/// whatever Hive-safe metadata they have (task name, station ids,
/// alert ids, retry attempt) and let the foreground recorder fill
/// in the rest.
@freezed
abstract class IsolateErrorSpoolEntry with _$IsolateErrorSpoolEntry {
  const factory IsolateErrorSpoolEntry({
    required DateTime timestamp,
    required String isolateTaskName,
    required String errorMessage,
    required String stack,
    @Default(<String, dynamic>{}) Map<String, dynamic> contextMap,
  }) = _IsolateErrorSpoolEntry;

  factory IsolateErrorSpoolEntry.fromJson(Map<String, dynamic> json) =>
      _$IsolateErrorSpoolEntryFromJson(json);
}
