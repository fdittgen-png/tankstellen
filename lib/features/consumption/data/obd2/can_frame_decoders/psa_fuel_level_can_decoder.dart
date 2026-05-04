import 'dart:async';

import 'package:flutter/foundation.dart';

/// Pure CAN-frame decoder for the PSA instrument-cluster broadcast
/// frame `0x0E6` (#1401 phase 5 — passive listening sibling of
/// phase 4's `PsaOemPidTable`).
///
/// On the PSA platform 2 / EMP2 generation (post-2008 Peugeot, Citroën
/// and DS — 308, 3008, 508 et al.) the instrument cluster broadcasts
/// the fuel level continuously as part of frame `0x0E6`. Reading it
/// passively avoids the 1-2 Hz active-polling round-trip cost of
/// `PsaOemPidTable` and yields a 10-20 Hz sample rate — fast enough
/// to power the variance-detection branch of the fill-up
/// reconciliation flow without saturating the bus.
///
/// ## Capability gate
///
/// Passive sniffing requires the STN-chip family
/// (`Obd2AdapterCapability.passiveCanCapable`). On a `oemPidsCapable`
/// adapter the caller falls through to the active-polling path. Phase 5
/// ships only this pure parser — the transport that produces the input
/// `(id, payload)` stream (STN listen-mode commands `STMA` / `ATCRA
/// 0E6`, line parsing, etc.) is the responsibility of a follow-up
/// issue that wires `Obd2Service.canFrameStream()` into a provider
/// gated on `passiveCanCapable`.
///
/// ## Wire format
///
/// Frame `0x0E6` carries vehicle-status data across at least 8 bytes.
/// Bytes 4 and 5 (zero-indexed) contain the fuel level encoded as an
/// unsigned 16-bit big-endian integer scaled `× 2` — i.e. the raw
/// value is litres × 2, so `litres = raw / 2.0`. A value of 90
/// (`0x00 0x5A`) therefore represents 45.0 L.
///
/// **Byte order — big-endian.** CAN payload conventions vary by OEM
/// (Motorola/big-endian for PSA, Renault, Mercedes; Intel/little-endian
/// for VAG, BMW). The PSA EMP2 instrument cluster uses big-endian
/// throughout per the platform's published CAN matrix (the same
/// convention `PsaOemPidTable` relies on for its `0x6FA / 21 51` reply
/// scaling). If a future trace shows a real PSA emitting bytes in the
/// reverse order, change the shift here AND add a regression test that
/// pins the captured frame.
///
/// ## Sanity
///
/// The parser intentionally does NOT clamp. Real PSA tanks cap around
/// 70-80 L, so a decoded value of 32767.5 L (`0xFF 0xFF`) is a wire
/// error, not an empty tank — but clamping is the caller's job
/// (cross-check against the vehicle profile's tank capacity). Treating
/// "this litres value is bigger than any tank" as a hard fault here
/// would silently swallow a real bug in our endianness assumption.
///
/// Returns `null` (never throws) when the frame cannot be decoded:
///   * `frameId != 0x0E6` (not the cluster broadcast);
///   * payload shorter than 6 bytes (bytes 4 and 5 unreadable).
class PsaFuelLevelCanDecoder {
  const PsaFuelLevelCanDecoder();

  /// PSA instrument-cluster broadcast frame ID. Standard 11-bit CAN
  /// identifier — every EMP2 BSI emits this at ~10-20 Hz while the
  /// ignition is on. Constant rather than configurable: a different
  /// frame ID would mean a different OEM, which would mean a different
  /// decoder class.
  static const int frameId = 0x0E6;

  /// Stable identifier mirroring `OemPidTable.oemKey` so logs and
  /// diagnostics can correlate active-polling and passive-listening
  /// reads on the same vehicle. Not user-facing.
  String get oemKey => 'PSA';

  /// Apply [decodeFuelLevelLitres] to every frame in [rawFrames] and
  /// emit one litres value per successfully-decoded frame. Frames with
  /// the wrong ID or a too-short payload are silently skipped — they're
  /// not errors, just other traffic on the bus.
  ///
  /// Errors on the input stream propagate to the output stream
  /// unchanged. The caller decides whether to retry or surface the
  /// failure.
  ///
  /// The output stream completes when [rawFrames] completes.
  Stream<double> filterFuelLevelStream(
    Stream<({int id, List<int> payload})> rawFrames,
  ) async* {
    await for (final frame in rawFrames) {
      final litres = decodeFuelLevelLitres(frame.id, frame.payload);
      if (litres != null) yield litres;
    }
  }
}

/// Pure decoder for the PSA `0x0E6` fuel-level field.
///
/// See [PsaFuelLevelCanDecoder] for the full wire-format / endianness
/// rationale. Exposed as a top-level function so tests can hit it
/// without instantiating the class — and so a future caller that
/// already has its own stream wiring can decode a single frame
/// without taking the streaming dependency.
///
/// Returns:
///   * `raw / 2.0` (litres) on success;
///   * `null` if [frameId] is not [PsaFuelLevelCanDecoder.frameId];
///   * `null` if [payload] is shorter than 6 bytes.
@visibleForTesting
double? decodeFuelLevelLitres(int frameId, List<int> payload) {
  if (frameId != PsaFuelLevelCanDecoder.frameId) return null;
  if (payload.length < 6) return null;
  // Big-endian uint16 across bytes 4-5. The `& 0xFF` guards against a
  // caller that hands us signed-byte ints (Dart's `List<int>` is
  // unconstrained — a value parsed from a hex string with a leading
  // `F` would already be `>=0`, but a `ByteData` slice could in
  // principle be negative on some legacy paths).
  final raw = ((payload[4] & 0xFF) << 8) | (payload[5] & 0xFF);
  return raw / 2.0;
}
