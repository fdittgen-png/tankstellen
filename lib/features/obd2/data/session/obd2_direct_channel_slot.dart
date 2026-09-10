// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/logging/app_log.dart';
import '../../../../core/logging/error_logger.dart';
import '../transport/elm_byte_channel.dart';

/// The one channel a direct (by-MAC) connect attempt has open, owned as a
/// collaborator of [Obd2ConnectionService] rather than as a bare field in
/// its shared `part` scope (#4035, epic #4032).
///
/// #2242 — the channel opened by the most recent `connectByMacDirect` is
/// retained so the NEXT direct connect can tear it down before reopening:
/// Android returns GATT_ERROR 133 if a stale GATT client for the same
/// device is still open, which would silently fall the caller back to the
/// scan path.
///
/// #3244 (BLE audit, HIGH) — there are therefore TWO teardowns, and they
/// are not interchangeable. A failure path that closed *whatever the slot
/// pointed at* could run AFTER a rival attempt had re-assigned it, and
/// close the rival's live connect mid-handshake. [releaseOwn] closes a
/// channel ONLY while the slot still points at that same instance;
/// [releasePrior] is the deliberate "clear whatever is there before I
/// open mine" teardown. The field itself is private here, so no caller
/// can pick the wrong one by writing the pointer directly — that is the
/// invariant three of the service's parts used to share by convention.
class Obd2DirectChannelSlot {
  ElmByteChannel? _channel;

  /// The retained channel, or null once torn down / never used.
  ElmByteChannel? get channel => _channel;

  /// Retain [channel] as this attempt's own.
  void hold(ElmByteChannel channel) => _channel = channel;

  /// #2907 — close + null whatever the slot holds, before opening a new
  /// direct/passive channel.
  Future<void> releasePrior() async {
    final prior = _channel;
    _channel = null;
    if (prior == null) return;
    await _close(prior, 'prior-direct-channel teardown');
  }

  /// #3244 close-by-identity: close [channel] — the calling attempt's OWN
  /// channel — and clear the slot ONLY when it still points at that same
  /// instance. A failure path that runs AFTER a rival attempt re-assigned
  /// the pointer therefore tears down only its own dead channel, never
  /// the rival's live one.
  Future<void> releaseOwn(ElmByteChannel channel) async {
    if (identical(_channel, channel)) _channel = null;
    await _close(channel, 'own-direct-channel teardown');
  }

  Future<void> _close(ElmByteChannel channel, String where) async {
    try {
      await channel.close();
    } catch (e, st) {
      // #2379 — OBD2/BLE, not local storage.
      log.error(e, st, layer: ErrorLayer.other, context: {
        'where': 'Obd2ConnectionService: $where',
      });
    }
  }
}
