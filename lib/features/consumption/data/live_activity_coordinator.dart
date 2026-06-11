// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import '../domain/live_activity_content.dart';
import 'live_activity_controller.dart';

/// Drives the iOS Live Activity lifecycle off the recorder's emit
/// stream (#3170): decides start / update / end and enforces the
/// ActivityKit update cadence.
///
/// The recorder emits a full state ~4×/s — pushing every emit through
/// the channel would hammer ActivityKit far past what its budgets
/// tolerate (and waste battery re-encoding identical content). The
/// elapsed timer ticks NATIVELY on the Swift side (off
/// `startedAtEpochMs`), so the activity stays visibly alive between
/// sparse content updates. Cadence rules:
///
/// * **start** — first non-null content while no activity runs;
/// * **end** — content goes null (trip stopped / discarded);
/// * **transition update** (mode flip, station change, price change,
///   pause toggle) — sent once ≥ [minTransitionGap] since the last send
///   (the next recorder emit retries, so nothing is lost);
/// * **routine update** (distance / consumption drift) — at most one
///   per [minRoutineGap];
/// * identical content is never re-sent.
///
/// A failed start (user disabled Live Activities, OS veto) silences the
/// coordinator for the REST OF THE TRIP — retrying 4×/s against a
/// definitive OS "no" is pure channel spam. The next trip tries again.
///
/// [apply] never throws — any unexpected failure is logged and
/// swallowed so the Live Activity can never take the recorder down.
class LiveActivityCoordinator {
  LiveActivityCoordinator({
    required LiveActivityController controller,
    DateTime Function()? clock,
  })  : _controller = controller,
        _clock = clock ?? DateTime.now;

  /// Floor between two sends when the CONTENT meaning changed (a radar
  /// flip / pause toggle should feel immediate but still debounced).
  static const Duration minTransitionGap = Duration(seconds: 2);

  /// Floor between two routine drift updates (distance / consumption).
  /// ~2 updates a minute keeps the surface fresh while staying far
  /// inside what ActivityKit tolerates for locally-driven activities.
  static const Duration minRoutineGap = Duration(seconds: 30);

  final LiveActivityController _controller;
  final DateTime Function() _clock;

  bool _active = false;
  bool _startVetoed = false;
  bool _applying = false;
  LiveActivityContent? _lastSent;
  DateTime? _lastSentAt;

  /// Whether the platform can host a Live Activity at all — callers use
  /// this to skip building content entirely off-iOS.
  bool get isSupported => _controller.isSupported;

  /// Whether an activity is currently believed to be live. Exposed for
  /// tests; production callers only ever call [apply].
  @visibleForTesting
  bool get isActive => _active;

  /// Reconcile the Live Activity with [content] (null = no active trip).
  ///
  /// Never throws (#3170): every controller call is best-effort and any
  /// unexpected raise is logged + swallowed — a Live Activity failure
  /// must never reach the recording pipeline.
  Future<void> apply(LiveActivityContent? content) async {
    if (!isSupported) return;
    // Re-entrancy guard: emits arrive faster than a channel round-trip;
    // overlapping applies could double-start. Skipped emits are retried
    // by the next one (~250 ms later), so nothing is lost.
    if (_applying) return;
    _applying = true;
    try {
      await _apply(content);
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.services, e, st, context: const {
        'where': 'LiveActivityCoordinator.apply',
      }));
    } finally {
      _applying = false;
    }
  }

  Future<void> _apply(LiveActivityContent? content) async {
    if (content == null) {
      _startVetoed = false; // a new trip gets a fresh attempt
      if (!_active) return;
      _active = false;
      _lastSent = null;
      _lastSentAt = null;
      await _controller.endActivity();
      return;
    }

    if (_startVetoed) return;

    final now = _clock();
    if (!_active) {
      final started = await _controller.startActivity(content.toChannelMap());
      if (started) {
        _active = true;
        _lastSent = content;
        _lastSentAt = now;
      } else {
        _startVetoed = true;
      }
      return;
    }

    final last = _lastSent;
    if (content == last) return;

    final significant = last == null ||
        content.mode != last.mode ||
        content.paused != last.paused ||
        content.stationName != last.stationName ||
        content.priceText != last.priceText;
    final gap = _lastSentAt == null
        ? minRoutineGap
        : now.difference(_lastSentAt!);
    if (gap < (significant ? minTransitionGap : minRoutineGap)) return;

    _lastSent = content;
    _lastSentAt = now;
    await _controller.updateActivity(content.toChannelMap());
  }
}
