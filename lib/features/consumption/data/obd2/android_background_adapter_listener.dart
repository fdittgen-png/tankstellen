import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'background_adapter_listener.dart';
import 'event_channel_cancel.dart';

/// Production [BackgroundAdapterListener] backed by the native Android
/// foreground service shipped in #1004 phase 2b-1.
///
/// The Kotlin side ([AutoRecordForegroundService] +
/// [BackgroundAdapterChannel]) registers two platform channels:
///  * `tankstellen/auto_record/methods` — `start(mac)` / `stop()` /
///    `isRunning()` to control the foreground service from Dart.
///  * `tankstellen/auto_record/events` — broadcast stream of
///    `{"type": "connect"|"disconnect", "mac": "...", "atMillis": <ms>}`
///    payloads, one per BLE GATT transition for the armed adapter.
///
/// This file is the bridge file. Phase 2b-1 ships it present-but-unused
/// so the existing [AutoTripCoordinator] (Refs #1004 phase 2a) has a
/// real listener to bind against in phase 2b-2 — this PR does NOT wire
/// it into any production Riverpod provider yet.
///
/// Channels are constructor-injected so unit tests can swap the names
/// to per-test channels and exercise the parsing without colliding
/// with another test running in parallel.
class AndroidBackgroundAdapterListener implements BackgroundAdapterListener {
  /// Platform channel exposing `start` / `stop` / `isRunning`.
  final MethodChannel _methods;

  /// Platform channel that streams `{type, mac, atMillis}` maps.
  final EventChannel _events;

  /// Single in-process broadcast stream that fans the parsed events out
  /// to the coordinator. We translate each platform map into a
  /// [BackgroundAdapterEvent] subclass exactly once so every subscriber
  /// sees the same instance.
  final StreamController<BackgroundAdapterEvent> _controller =
      StreamController<BackgroundAdapterEvent>.broadcast();

  /// Native EventChannel subscription, opened on the first [start] call
  /// and closed on [stop]. We keep at most one open subscription —
  /// re-arming with a different MAC does NOT churn the EventChannel.
  StreamSubscription<dynamic>? _platformSubscription;

  /// Default constructor for production use. Channel names match the
  /// strings in [BackgroundAdapterChannel] on the Kotlin side; keep
  /// them in sync.
  AndroidBackgroundAdapterListener()
      : _methods = const MethodChannel('tankstellen/auto_record/methods'),
        _events = const EventChannel('tankstellen/auto_record/events');

  /// Test-only constructor that injects custom channels. Useful when
  /// running multiple isolation-level tests in parallel — each test
  /// owns its own channel name and so its own
  /// [TestDefaultBinaryMessenger] handler.
  @visibleForTesting
  AndroidBackgroundAdapterListener.withChannels({
    required MethodChannel methodChannel,
    required EventChannel eventChannel,
  })  : _methods = methodChannel,
        _events = eventChannel;

  @override
  Stream<BackgroundAdapterEvent> get events => _controller.stream;

  @override
  Future<void> start({required String mac}) async {
    // Ensure we're listening to the EventChannel BEFORE the service
    // arms — otherwise an early connect event from a fast adapter
    // could beat us to the EventChannel and be dropped. The native
    // ring buffer mitigates this further but the cheapest defence is
    // to subscribe first.
    _platformSubscription ??= _events
        .receiveBroadcastStream()
        .listen(
          _onPlatformEvent,
          onError: (Object error, StackTrace stack) {
            // Non-fatal: native side reported a stream error. We do
            // NOT close the broadcast stream — coordinator restart
            // would otherwise miss every subsequent event.
            debugPrint(
              'AndroidBackgroundAdapterListener: platform stream error: $error',
            );
          },
        );

    await _methods.invokeMethod<bool>('start', <String, Object?>{'mac': mac});
  }

  @override
  Future<void> stop() async {
    await _methods.invokeMethod<bool>('stop');
    await _platformSubscription?.safeCancel();
    _platformSubscription = null;
  }

  /// Whether the native foreground service is currently armed. Useful
  /// for diagnostics and for an idempotent "start if not started" flow
  /// in the production coordinator wiring (phase 2b-2). Best-effort —
  /// the OS may have killed the service since the last call.
  Future<bool> isRunning() async {
    final ok = await _methods.invokeMethod<bool>('isRunning');
    return ok ?? false;
  }

  void _onPlatformEvent(Object? raw) {
    // Malformed events are dropped via debugPrint inside [_parseEvent]
    // — never silenced. A bad payload is a real bug on the native side;
    // we want it visible in the Flutter run / test log so it shows up
    // during device testing without crashing the stream.
    final event = _parseEvent(raw);
    if (event == null) return;
    _controller.add(event);
  }

  /// Returns a typed [BackgroundAdapterEvent], or `null` if the payload
  /// is malformed. Pulled out to keep [_onPlatformEvent] readable and
  /// to give tests a deterministic place to assert parsing rules.
  BackgroundAdapterEvent? _parseEvent(Object? raw) {
    if (raw is! Map) {
      debugPrint(
        'AndroidBackgroundAdapterListener: dropping non-Map event '
        '(${raw.runtimeType})',
      );
      return null;
    }
    final type = raw['type'];
    final mac = raw['mac'];
    final atMillis = raw['atMillis'];
    if (type is! String || mac is! String) {
      debugPrint(
        'AndroidBackgroundAdapterListener: dropping event with bad '
        'type/mac fields: $raw',
      );
      return null;
    }
    DateTime at;
    if (atMillis is int) {
      at = DateTime.fromMillisecondsSinceEpoch(atMillis);
    } else if (atMillis is num) {
      // Some platforms (and JSON channels) round-trip ints as doubles.
      at = DateTime.fromMillisecondsSinceEpoch(atMillis.toInt());
    } else {
      debugPrint(
        'AndroidBackgroundAdapterListener: dropping event with bad '
        'atMillis (${atMillis.runtimeType}): $raw',
      );
      return null;
    }
    switch (type) {
      case 'connect':
        return AdapterConnected(mac: mac, at: at);
      case 'disconnect':
        return AdapterDisconnected(mac: mac, at: at);
      default:
        debugPrint(
          'AndroidBackgroundAdapterListener: dropping event with '
          'unknown type "$type"',
        );
        return null;
    }
  }

  /// Test-only hook to drain resources between tests.
  @visibleForTesting
  Future<void> dispose() async {
    await _platformSubscription?.safeCancel();
    _platformSubscription = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
