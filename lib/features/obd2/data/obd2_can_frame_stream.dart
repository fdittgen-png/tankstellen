// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'obd2_transport.dart';
import '../../../core/logging/error_logger.dart';

/// PSA instrument-cluster broadcast frame ID (#1418). Mirrors
/// `PsaFuelLevelCanDecoder.frameId` — kept as a private constant
/// here so the data layer doesn't import the decoder (decoder
/// depends on stream shape, not the other way around).
const int _psaFuelLevelFrameId = 0x0E6;

/// Set the ELM327's CAN receive-address filter to the PSA
/// instrument-cluster frame `0x0E6` (#1418). Only frames matching
/// this 11-bit ID are surfaced by the next `STMA`.
const String _atCraPsaFuelLevelCommand = 'ATCRA 0E6\r';

/// STN listen-mode start (#1418). After this returns OK, the
/// adapter starts emitting frame lines on the raw byte channel
/// without the trailing `>` prompt that `sendCommand` normally
/// waits on.
const String _stmaCommand = 'STMA\r';

/// STN listen-mode stop (#1418). Sent via
/// [Obd2ListenModeTransport.sendListenModeStop] on stream cancel — the
/// prompt won't come back until the adapter exits listen-mode, so the
/// regular `sendCommand` path can't carry it.
const String _stmpCommand = 'STMP\r';

/// Open a passive CAN-frame stream filtered to the PSA
/// instrument-cluster broadcast frame `0x0E6` (#1418; extracted from
/// [Obd2Service] in #3540 — the service's `canFrameStream()` delegates
/// here unchanged).
///
/// Sends [`ATCRA 0E6`] (CAN receive-address filter for frame ID
/// `0x0E6`, the PSA EMP2 BSI broadcast) followed by [`STMA`] (STN
/// listen-mode start) on first listen, then parses each
/// listen-mode line of the form `0E6 D <len> <byte0> <byte1> …`
/// into a `(int id, List<int> payload)` record. On
/// stream-subscription cancel, sends [`STMP`] so the adapter
/// returns to normal mode.
///
/// The output is a broadcast stream so the high-level
/// `psaFuelLevelProvider` can subscribe + cancel without disturbing
/// the underlying channel — multiple consumers (e.g. the trip
/// recorder + a diagnostic overlay) can share one listen-mode
/// session in a future epic.
///
/// **Pre-conditions** (caller's responsibility):
///   * The ELM channel must be open (`connect` succeeded).
///   * The adapter must report
///     [Obd2AdapterCapability.passiveCanCapable]. The high-level
///     [`psaFuelLevelProvider`] enforces this gate; the data layer
///     here stays dumb so a future caller that knows what it is
///     doing (e.g. a debug screen on an STN clone) can opt in
///     without re-implementing the gate.
///
/// **What this function does NOT do**:
///   * It does not block on the [`PsaFuelLevelCanDecoder`]; it
///     emits raw `(id, payload)` tuples. The decoder's
///     [`PsaFuelLevelCanDecoder.filterFuelLevelStream`] consumer
///     transforms tuples into litres.
///   * It does not validate the listen-mode response — malformed
///     lines (wrong frame id, short payload, non-hex bytes) are
///     silently dropped so a buffer-overflow burst doesn't kill
///     the stream.
///
/// Phase 5 of #1401 (PR #1417) shipped the pure-data decoder; this
/// function is the streaming-transport wiring the decoder docstring
/// promised. Errors on the underlying line stream propagate to the
/// returned stream — the gating provider downgrades on failure.
Stream<({int id, List<int> payload})> psaCanFrameStream(
  Obd2Transport transport,
) {
  if (transport is! Obd2ListenModeTransport) {
    // The transport doesn't support raw line streaming — surface a
    // clear error rather than silently emitting nothing. The
    // capability gate at the provider layer should already have
    // caught this; surfacing it here makes the failure mode
    // obvious if a future caller bypasses the gate.
    return Stream.error(
      UnsupportedError(
        'psaCanFrameStream requires an '
        'Obd2ListenModeTransport (e.g. on STN-chip adapters). '
        'Current transport: ${transport.runtimeType}',
      ),
    );
  }
  // Capture the promoted reference so the closures below see the
  // listen-mode interface. Dart's flow analysis won't carry the
  // `is!` promotion through a `final` capture into function
  // literals — a typed cast is the cleanest way to fix it.
  final listenTransport = transport as Obd2ListenModeTransport;
  late StreamController<({int id, List<int> payload})> controller;
  StreamSubscription<String>? sub;

  Future<void> setup() async {
    try {
      // Setup: filter then start listen mode. Both commands respond
      // with OK + `>` so the regular sendCommand path is fine.
      await transport.sendCommand(_atCraPsaFuelLevelCommand);
      await transport.sendCommand(_stmaCommand);
      // Subscribe to raw lines AFTER STMA so we don't accidentally
      // consume the OK reply as a frame.
      sub = listenTransport.openListenLineStream().listen(
        (line) {
          final frame = parseListenModeLine(line);
          if (frame != null && !controller.isClosed) {
            controller.add(frame);
          }
        },
        onError: (Object e, StackTrace st) {
          if (!controller.isClosed) controller.addError(e, st);
        },
        onDone: () {
          if (!controller.isClosed) unawaited(controller.close());
        },
      );
    } catch (e, st) {
      // Any setup failure surfaces on the stream so the caller
      // sees it — never silently swallow.
      if (!controller.isClosed) {
        controller.addError(e, st);
        await controller.close();
      }
    }
  }

  Future<void> teardown() async {
    // Unhook the listener BEFORE sending STMP so the adapter's exit
    // ack (if any) doesn't show up as a stray `frame line`.
    await sub?.cancel();
    sub = null;
    try {
      await listenTransport.sendListenModeStop(_stmpCommand);
    } catch (e, st) {
      // Best-effort: the user has already cancelled, no point
      // crashing on a STMP write that might fail because the
      // channel is mid-disconnect.
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'OBD2 canFrameStream STMP failed'}));
    }
  }

  controller = StreamController<({int id, List<int> payload})>.broadcast(
    onListen: setup,
    onCancel: teardown,
  );
  return controller.stream;
}

/// Parse one STN listen-mode line of the form
/// `0E6 D 8 12 34 56 78 9A BC DE F0` (frame id, `D`ata indicator,
/// length, then [length] hex byte tokens) into the decoder's
/// `(id, payload)` record (#1418).
///
/// Returns `null` for any malformed line — wrong frame id (only
/// the PSA fuel-level frame is wanted here), missing length, length
/// mismatch, or non-hex byte tokens. The stream silently drops
/// nulls so a malformed burst doesn't kill the consumer.
({int id, List<int> payload})? parseListenModeLine(String line) {
  final tokens = line.trim().split(RegExp(r'\s+'));
  // Need at minimum: id, "D", length, plus one byte = 4 tokens.
  if (tokens.length < 4) return null;
  final parsedId = int.tryParse(tokens[0], radix: 16);
  if (parsedId != _psaFuelLevelFrameId) return null;
  if (tokens[1].toUpperCase() != 'D') return null;
  final length = int.tryParse(tokens[2], radix: 16);
  if (length == null) return null;
  final byteTokens = tokens.sublist(3);
  if (byteTokens.length != length) return null;
  final payload = <int>[];
  for (final token in byteTokens) {
    final byte = int.tryParse(token, radix: 16);
    if (byte == null || byte < 0 || byte > 0xFF) return null;
    payload.add(byte);
  }
  // The `parsedId != _psaFuelLevelFrameId` early-return above
  // proves non-null here, but the record-field type system can't
  // track that proof — fall back to the local constant which is
  // both non-null and equal.
  return (id: _psaFuelLevelFrameId, payload: payload);
}
