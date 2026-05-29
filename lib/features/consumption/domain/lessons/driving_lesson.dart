// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

/// One post-trip "lesson learned" surfaced on the trip-detail Insights
/// group and embedded in the GPX recording export (#2251).
///
/// A lesson is the firing output of a [DrivingLessonRule]: a single,
/// self-contained piece of coaching ("you idled 8 % of the trip — turn
/// the engine off at long stops"). It carries everything both the UI
/// and the GPX exporter need:
///
///   * a stable [id] (e.g. `'idling'`, `'highRpm'`) used as the GPX
///     extension attribute and the widget [ValueKey] — never localized;
///   * an [impact] ranking the registry sorts lessons by (higher =
///     surfaced first / waste-dominant);
///   * the [metricValue] that triggered the rule (litres wasted, idle
///     seconds, event count …) — written verbatim into the GPX so each
///     recording is self-auditing;
///   * a [title] headline + a "how to improve" [advice] sentence, both
///     already resolved through `AppLocalizations` by the rule. The
///     value type stays UI-/locale-agnostic itself — it holds the
///     resolved strings, it does not resolve them.
///
/// The class deliberately mirrors the shape of the legacy
/// [DrivingInsight] cost line so the migration is a faithful
/// re-expression rather than a behaviour change: the same trips produce
/// the same lessons. The registry/strategy split (#2251) means a new
/// lesson is one new [DrivingLessonRule] file + a registry entry — no
/// edits to the calculator or the card.
@immutable
class DrivingLesson {
  /// Stable, non-localized identifier. Doubles as the GPX
  /// `<tankstellen:lesson id="...">` attribute and the insight tile
  /// [ValueKey]. Examples: `'idling'`, `'highRpm'`, `'hardAccel'`,
  /// `'lowGear'`.
  final String id;

  /// Ranking weight — the registry returns firing lessons sorted by
  /// this descending. For the migrated cost lines this is the litres
  /// wasted (so the existing "ranked by waste" order is preserved); for
  /// metric-only lessons (low gear) it is a fixed high weight so the
  /// most actionable coaching surfaces first, matching the legacy card
  /// which renders the gear row above the cost lines.
  final double impact;

  /// The raw metric value that fired the rule, in the lesson's natural
  /// unit (litres wasted, idle seconds, hard-accel event count, seconds
  /// below optimal gear …). Surfaced verbatim in the GPX
  /// `value="..."` attribute so a downstream tool can recompute or
  /// audit without re-deriving from the track.
  final double metricValue;

  /// Localized headline — identical copy to what the trip-detail
  /// Insights card showed before #2251 (resolved by the rule from the
  /// existing ARB keys). Empty only for a defensively-constructed
  /// lesson; production rules always resolve a non-empty title.
  final String title;

  /// Localized "how to improve" advice. May be empty when a migrated
  /// lesson has no dedicated advice ARB key yet — the UI renders the
  /// title alone in that case, exactly as the legacy card did (the
  /// legacy cost-line tiles had no advice sub-line). Carried into the
  /// GPX `<tankstellen:message>` element.
  final String advice;

  /// Localized secondary caption the trip-detail card renders beneath
  /// the [title] (e.g. "12% of trip" for the cost lines). Null for
  /// lessons that render the title alone (the low-gear row had no
  /// caption). Presentation-only — NOT written to the GPX.
  final String? subtitle;

  /// Localized trailing badge the trip-detail card renders to the right
  /// of the tile (e.g. "+0.6 L" for the cost lines). Null for lessons
  /// with no badge (the low-gear row had none). Presentation-only — NOT
  /// written to the GPX.
  final String? trailing;

  const DrivingLesson({
    required this.id,
    required this.impact,
    required this.metricValue,
    required this.title,
    this.advice = '',
    this.subtitle,
    this.trailing,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivingLesson &&
        other.id == id &&
        other.impact == impact &&
        other.metricValue == metricValue &&
        other.title == title &&
        other.advice == advice &&
        other.subtitle == subtitle &&
        other.trailing == trailing;
  }

  @override
  int get hashCode =>
      Object.hash(id, impact, metricValue, title, advice, subtitle, trailing);

  @override
  String toString() => 'DrivingLesson('
      'id: $id, '
      'impact: ${impact.toStringAsFixed(3)}, '
      'metricValue: ${metricValue.toStringAsFixed(3)}, '
      'title: "$title", '
      'advice: "$advice", '
      'subtitle: "$subtitle", '
      'trailing: "$trailing")';
}
