// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

/// Which bound a frame broke when it arrived but decoded to an
/// implausible value (#4325).
///
/// The kinds name the SIGNAL, not the PID, so the diagnostics above the
/// adapter never learn which request carried the frame.
enum ImplausibleFrameKind {
  /// An `ATRV` reply outside 5–20 V.
  batteryVoltage,

  /// An odometer frame (standard or manufacturer) of 0 km or above
  /// 2,000,000 km.
  odometer,
}

/// The outcome of decoding one adapter reply (#4325): a [value], nothing
/// (NO DATA, a malformed or mismatched frame), or a frame that arrived but
/// falls outside its plausible bounds.
///
/// Consumers keep reading [value], which is null for both of the latter —
/// the numbers they produce do not change. The distinction exists so a
/// rejected-but-present frame, which is evidence of an adapter or ECU
/// fault, is counted as that instead of disappearing into "no data".
@immutable
final class FrameDecode<T extends Object> {
  /// A plausible decoded value.
  const FrameDecode.value(T this.value) : implausible = null;

  /// No usable frame: NO DATA, an error placeholder, or a malformed reply.
  const FrameDecode.absent()
      : value = null,
        implausible = null;

  /// A frame arrived, but its value broke the [kind] bound.
  const FrameDecode.implausible(ImplausibleFrameKind kind)
      : value = null,
        implausible = kind;

  /// The decoded value; null when absent or implausible.
  final T? value;

  /// The bound the frame broke; null unless the frame was implausible.
  final ImplausibleFrameKind? implausible;

  /// [value], after handing an implausible outcome to [onImplausible].
  T? valueReporting(void Function(ImplausibleFrameKind kind) onImplausible) {
    final kind = implausible;
    if (kind != null) onImplausible(kind);
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is FrameDecode<T> &&
      other.value == value &&
      other.implausible == implausible;

  @override
  int get hashCode => Object.hash(value, implausible);

  @override
  String toString() => implausible != null
      ? 'FrameDecode.implausible(${implausible!.name})'
      : 'FrameDecode($value)';
}
