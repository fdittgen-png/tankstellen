// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'background_adapter_listener.dart';
import 'foreground_promotion.dart';
import '../../../../../core/utils/event_channel_cancel.dart';
import '../../../../core/logging/app_log.dart';
import '../../../../core/logging/error_logger.dart';

// #4355 — the promotion contract is part of this listener's public surface
// (it is what `arm` returns), so callers need one import, not two.
export 'foreground_promotion.dart';

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
/// `AutoRecordOrchestrator` selects this listener on Android and binds
/// the [AutoTripCoordinator] to it (phase 2b-2). Note the Kotlin
/// `<service>` is absent from default-build manifests pending the
/// Google Play "Foreground Service Use" form (#1498) — it ships in the
/// gated `AndroidManifestFgsApproved.xml` play overlay enabled by the
/// `FGS_FORM_APPROVED` define (#3173) — so `start(mac)` is effectively
/// a no-op in shipped builds until the form clears; the
/// foreground-active arming fallback (#2282 concern 1) covers engine
/// detection while the app is in front.
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

  /// #4355 — outer bound on waiting for the native promotion acknowledgement.
  /// Deliberately longer than the native side's own bound
  /// (`BackgroundAdapterChannel.PROMOTION_ACK_TIMEOUT_MS`, 5 s) so the native
  /// timeout normally wins and Dart reports the accurate native reason; this
  /// only fires when the platform thread is wedged.
  final Duration promotionAckTimeout;

  /// Default constructor for production use. Channel names match the
  /// strings in [BackgroundAdapterChannel] on the Kotlin side; keep
  /// them in sync.
  AndroidBackgroundAdapterListener()
      : _methods = const MethodChannel('tankstellen/auto_record/methods'),
        _events = const EventChannel('tankstellen/auto_record/events'),
        promotionAckTimeout = kForegroundPromotionAckTimeout;

  /// Test-only constructor that injects custom channels. Useful when
  /// running multiple isolation-level tests in parallel — each test
  /// owns its own channel name and so its own
  /// [TestDefaultBinaryMessenger] handler.
  @visibleForTesting
  AndroidBackgroundAdapterListener.withChannels({
    required MethodChannel methodChannel,
    required EventChannel eventChannel,
    this.promotionAckTimeout = kForegroundPromotionAckTimeout,
  })  : _methods = methodChannel,
        _events = eventChannel;

  @override
  Stream<BackgroundAdapterEvent> get events => _controller.stream;

  /// #3699 — engine-start hints from the native `BtAclEngineStartReceiver`
  /// (`{"type": "aclConnected"}` payloads on the same events channel).
  /// STATIC: the hint is a process-wide signal (the phone linked to SOME
  /// Bluetooth device — in the car, that's the audio system at ignition
  /// on), not a per-adapter transition, so it deliberately bypasses the
  /// sealed [BackgroundAdapterEvent] hierarchy and the per-coordinator
  /// MAC filter. Emits the native event timestamp; the consumer
  /// ([engineStartHintWake]) applies the staleness gate — the native
  /// ring buffer can replay minutes-old hints on (re)subscribe.
  static final StreamController<DateTime> _hintController =
      StreamController<DateTime>.broadcast();

  /// Broadcast stream of ACL engine-start hint timestamps (#3699).
  static Stream<DateTime> get engineStartHints => _hintController.stream;

  /// #4355 — promotion acknowledgements / refusals. STATIC for the same
  /// reason as the hint stream: a foreground-service promotion is a
  /// process-wide platform fact, not a per-adapter transition, so it
  /// deliberately bypasses the sealed [BackgroundAdapterEvent] hierarchy and
  /// the per-coordinator MAC filter (the payloads carry no MAC at all).
  static final StreamController<ForegroundPromotionEvent>
      _promotionController =
      StreamController<ForegroundPromotionEvent>.broadcast();

  /// Broadcast stream of [ForegroundPromotionEvent]s (#4355).
  static Stream<ForegroundPromotionEvent> get promotionEvents =>
      _promotionController.stream;

  /// #3505 — localized notification title/body handed to the native FGS at
  /// arm time (null keeps the built-in English fallback). Settable fields
  /// (not `start` params) so the [BackgroundAdapterListener] interface and
  /// its iOS/fake implementations stay untouched.
  String? notificationTitle;
  String? notificationText;

  /// #4355 — the outcome of the most recent [arm]. `null` until the first
  /// attempt. Diagnostics-only here; #4352 owns the recorder's own protection
  /// verdict and must never read a *presence* watcher's state as evidence
  /// that a recording is protected.
  ForegroundPromotionOutcome? lastPromotion;

  @override
  Future<void> start({required String mac}) async {
    await arm(mac: mac);
  }

  /// #4355 — arms the native presence watcher and reports what the OS
  /// actually did.
  ///
  /// The native `start` reply is parked until the service posts its promotion
  /// acknowledgement, so a returned [ForegroundPromotionOutcome.promoted] now
  /// means the OS promoted the service — not merely that a `ComponentName`
  /// came back, which only ever proved the service was *created*.
  ///
  /// Bounded on both sides: the native side times its parked reply out, and
  /// [promotionAckTimeout] here is the outer net for a wedged platform
  /// thread. Every path resolves to a typed outcome; this never throws.
  Future<ForegroundPromotionOutcome> arm({required String mac}) async {
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

    // #3246 — the native arm can legitimately fail: shipped builds gate the
    // foreground <service> out of the manifest (FGS_FORM_APPROVED off, #3173)
    // so it is `unavailable`, or it `cannot start fgs from background`. The
    // native side now reports those honestly instead of a phantom success;
    // degrade silently here (recording falls back to the GPS-only / foreground
    // path) rather than crashing the auto-record coordinator.
    ForegroundPromotionOutcome outcome;
    try {
      final armed = await _methods
          .invokeMethod<bool>('start', <String, Object?>{
            'mac': mac,
            // #3505 — localized FGS notification copy; the native side
            // persists it so a CDM cold start (app process dead) still shows
            // the user's language instead of the hard-coded English fallback.
            if (notificationTitle != null) 'notifTitle': notificationTitle,
            if (notificationText != null) 'notifText': notificationText,
          })
          .timeout(promotionAckTimeout);
      if (armed == true) {
        outcome = ForegroundPromotionOutcome.promoted;
      } else {
        // A non-true reply is not an acknowledgement. Never treat it as one.
        outcome = ForegroundPromotionOutcome.refused;
        debugPrint('AndroidBackgroundAdapterListener: FGS not armed (native '
            'returned $armed)');
      }
    } on PlatformException catch (e, st) {
      outcome = foregroundPromotionOutcomeForCode(e.code, e.message);
      log.warn(
          'AndroidBackgroundAdapterListener: FGS arm failed '
          '(${outcome.name}) — degrading to no-FGS recording',
          error: e,
          stack: st,
          layer: ErrorLayer.background);
    } on TimeoutException catch (e, st) {
      // The native bound should always fire first; this is the outer net for
      // a wedged platform thread, and it must not hang the coordinator.
      outcome = ForegroundPromotionOutcome.timedOut;
      log.warn(
          'AndroidBackgroundAdapterListener: FGS promotion was not '
          'acknowledged — degrading to no-FGS recording',
          error: e,
          stack: st,
          layer: ErrorLayer.background);
    }
    lastPromotion = outcome;
    return outcome;
  }

  @override
  Future<void> stop() async {
    await _methods.invokeMethod<bool>('stop');
    await _platformSubscription?.safeCancel();
    _platformSubscription = null;
  }

  /// Whether the native foreground service is currently PROMOTED. Useful
  /// for diagnostics and for an idempotent "start if not started" flow
  /// in the production coordinator wiring (phase 2b-2). Best-effort —
  /// the OS may have killed the service since the last call.
  ///
  /// #4355 — the native flag behind this is now set by the service's
  /// promotion acknowledgement, not by `startForegroundService` returning a
  /// `ComponentName`. It is still only a *presence* watcher's state, never
  /// evidence that a recording is protected.
  Future<bool> isRunning() async {
    final ok = await _methods.invokeMethod<bool>('isRunning');
    return ok ?? false;
  }

  /// #4355 — routes a promotion acknowledgement / refusal to the static
  /// [promotionEvents] stream. A malformed payload is dropped, never
  /// upgraded into a claim that the service was promoted.
  void _emitPromotion(String type, Map<Object?, Object?> raw, Object? atMillis) {
    final at = _parseAtMillis(atMillis, raw);
    if (at == null) return;
    final outcome = type == kFgsPromotedEvent
        ? ForegroundPromotionOutcome.promoted
        : foregroundPromotionOutcomeForReason(raw['reason'] as String?);
    final generation = raw['generation'];
    _promotionController.add(ForegroundPromotionEvent(
      outcome: outcome,
      at: at,
      generation: generation is int ? generation : null,
    ));
  }

  /// Shared `atMillis` decoding — some channels round-trip ints as doubles.
  /// Returns null (and logs) for a payload that carries no usable timestamp.
  static DateTime? _parseAtMillis(Object? atMillis, Object? raw) {
    if (atMillis is int) return DateTime.fromMillisecondsSinceEpoch(atMillis);
    if (atMillis is num) {
      return DateTime.fromMillisecondsSinceEpoch(atMillis.toInt());
    }
    debugPrint(
      'AndroidBackgroundAdapterListener: dropping event with bad '
      'atMillis (${atMillis.runtimeType}): $raw',
    );
    return null;
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
    // #4355 — promotion acknowledgements carry NO mac (they are a
    // process-wide platform fact), so they are routed before the mac check.
    if (type == kFgsPromotedEvent || type == kFgsStartFailedEvent) {
      _emitPromotion(type! as String, raw, atMillis);
      return null;
    }
    if (type is! String || mac is! String) {
      debugPrint(
        'AndroidBackgroundAdapterListener: dropping event with bad '
        'type/mac fields: $raw',
      );
      return null;
    }
    final at = _parseAtMillis(atMillis, raw);
    if (at == null) return null;
    switch (type) {
      case 'connect':
        return AdapterConnected(mac: mac, at: at);
      case 'disconnect':
        return AdapterDisconnected(mac: mac, at: at);
      // #3699 — process-wide engine-start hint, not an adapter event:
      // routed to the static hint stream, never to the coordinator.
      case 'aclConnected':
        _hintController.add(at);
        return null;
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
