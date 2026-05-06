/// User-facing settings for the glide-coach feature (#1125 phase 3a).
///
/// Wired into the runtime in phase 3b; defaulted to disabled per
/// #1125 acceptance ("Setting toggle, default OFF"). Phase 3a only
/// ships the data shape so the evaluator + tests can reference the
/// same defaults the future Riverpod provider + Hive-backed settings
/// store will hand out.
///
/// Immutable — phase 3b's settings notifier will emit a fresh
/// instance on every change rather than mutate in place.
class GlideCoachSettings {
  /// Master on/off toggle. Default `false` — the feature stays off
  /// until the user opts in, even after the kill-switch
  /// (`kGlideCoachEnabled` in `traffic_signal_repository.dart`) flips
  /// to `true`.
  final bool enabled;

  /// Throttle position (0–100) above which the evaluator considers
  /// the user "on throttle" and therefore eligible for a lift hint.
  /// Default 20.0 — slightly above the typical idle-creep
  /// throttle-by-wire reading so we don't hint while the user has
  /// already let off.
  final double throttleThresholdPercent;

  /// Minimum quiet window after firing a `lift` advice. Default 15s
  /// — long enough that two close-spaced signals don't double-buzz,
  /// short enough that a missed-then-corrected lift can re-fire on
  /// the next signal.
  final Duration cooldown;

  const GlideCoachSettings({
    this.enabled = false,
    this.throttleThresholdPercent = 20.0,
    this.cooldown = const Duration(seconds: 15),
  });

  GlideCoachSettings copyWith({
    bool? enabled,
    double? throttleThresholdPercent,
    Duration? cooldown,
  }) =>
      GlideCoachSettings(
        enabled: enabled ?? this.enabled,
        throttleThresholdPercent:
            throttleThresholdPercent ?? this.throttleThresholdPercent,
        cooldown: cooldown ?? this.cooldown,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlideCoachSettings &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          throttleThresholdPercent == other.throttleThresholdPercent &&
          cooldown == other.cooldown;

  @override
  int get hashCode =>
      Object.hash(enabled, throttleThresholdPercent, cooldown);

  @override
  String toString() =>
      'GlideCoachSettings(enabled: $enabled, '
      'throttleThresholdPercent: $throttleThresholdPercent, '
      'cooldown: $cooldown)';
}
