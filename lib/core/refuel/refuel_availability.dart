import 'package:meta/meta.dart';

/// Whether a refueling option can be used right now.
///
/// Phase 1 of the fuel/EV unification (#1116). Modeled as a sealed
/// class so callers exhaust the cases at compile time (Dart 3 sealed
/// classes give us this without pulling freezed into a multi-factory
/// union).
///
/// [isOperational] is the single boolean the UI most often reads —
/// "should I render this option as actionable?" — and short-circuits
/// the case-by-case render when callers don't care about the reason.
sealed class RefuelAvailability {
  const RefuelAvailability();

  /// True when the option is currently usable. Only [Open] returns
  /// true; [Limited] is intentionally `false` because the UI should
  /// still surface the limitation reason rather than treat the
  /// option as fully available.
  bool get isOperational => this is _Open;

  /// Currently open and accepting customers / sessions.
  static const RefuelAvailability open = _Open();

  /// Currently closed (outside opening hours, scheduled maintenance,
  /// permanently shut, …). [reason] is optional free-form context
  /// the UI may surface as a subtitle.
  factory RefuelAvailability.closed({String? reason}) = _Closed;

  /// Partially available — e.g. some pumps out of service, EV bay
  /// occupied, queue forming. [reason] is required so the UI can
  /// explain the limitation.
  factory RefuelAvailability.limited({required String reason}) = _Limited;

  /// Upstream didn't tell us — the most common case for ad-hoc
  /// fuel APIs that don't expose opening-hours data.
  static const RefuelAvailability unknown = _Unknown();
}

/// Currently open. Singleton — use [RefuelAvailability.open].
@immutable
final class _Open extends RefuelAvailability {
  const _Open();

  @override
  bool operator ==(Object other) => other is _Open;

  @override
  int get hashCode => (_Open).hashCode;

  @override
  String toString() => 'RefuelAvailability.open';
}

/// Currently closed. Construct via [RefuelAvailability.closed].
@immutable
final class _Closed extends RefuelAvailability {
  final String? reason;

  const _Closed({this.reason});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _Closed && other.reason == reason;

  @override
  int get hashCode => Object.hash(_Closed, reason);

  @override
  String toString() => 'RefuelAvailability.closed(reason: $reason)';
}

/// Partial availability. Construct via [RefuelAvailability.limited].
@immutable
final class _Limited extends RefuelAvailability {
  final String reason;

  const _Limited({required this.reason});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _Limited && other.reason == reason;

  @override
  int get hashCode => Object.hash(_Limited, reason);

  @override
  String toString() => 'RefuelAvailability.limited(reason: $reason)';
}

/// Upstream didn't say — singleton. Use [RefuelAvailability.unknown].
@immutable
final class _Unknown extends RefuelAvailability {
  const _Unknown();

  @override
  bool operator ==(Object other) => other is _Unknown;

  @override
  int get hashCode => (_Unknown).hashCode;

  @override
  String toString() => 'RefuelAvailability.unknown';
}
