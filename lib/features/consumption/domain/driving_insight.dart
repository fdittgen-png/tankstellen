/// One "cost line" surfaced in the trip Insights tab (#1041 phase 1).
///
/// Each insight quantifies a single behaviour-driven fuel cost so the
/// driver can see *how* the trip burned more fuel than it had to. The
/// presentation layer (#1041 phase 2) maps [labelKey] to a localized
/// string and renders [litersWasted] / [percentOfTrip] alongside it.
///
/// The class is intentionally UI-agnostic — no `BuildContext`, no
/// `AppLocalizations`. The analyzer in
/// `driving_insights_analyzer.dart` produces these from raw
/// [TripSample]s; the same value-object can be persisted, replayed,
/// or aggregated across trips later (phase 4) without touching UI
/// code.
class DrivingInsight {
  /// l10n key (e.g. `'insightHighRpm'`, `'insightHardAccel'`,
  /// `'insightIdling'`). The key is stable; phase 2 will add ARB
  /// entries that consume it. Kept as a plain `String` rather than an
  /// enum so future categories don't need a domain-layer change.
  final String labelKey;

  /// Estimated wasted fuel attributed to this cost line, in litres.
  /// Always >= the noise floor in the analyzer (0.05 L by default).
  final double litersWasted;

  /// Share of the trip relevant to this cost line, in percent (0..100).
  /// Semantics differ per category — for high-RPM it's the share of
  /// time above threshold, for idling it's the share of time idling,
  /// for hard-acceleration it's the share of distance during the
  /// counted events. The label key communicates the meaning.
  final double percentOfTrip;

  /// Free-form supporting numbers for the UI (e.g. `aboveRpm: 3000`,
  /// `eventCount: 4`). Use `num` so int and double both fit; phase 2
  /// will pull values out by key.
  final Map<String, num> metadata;

  const DrivingInsight({
    required this.labelKey,
    required this.litersWasted,
    required this.percentOfTrip,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivingInsight &&
        other.labelKey == labelKey &&
        other.litersWasted == litersWasted &&
        other.percentOfTrip == percentOfTrip &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        labelKey,
        litersWasted,
        percentOfTrip,
        // Hash the sorted entries so two equal maps with different
        // insertion order still hash the same.
        Object.hashAllUnordered(
          metadata.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );

  @override
  String toString() => 'DrivingInsight('
      'labelKey: $labelKey, '
      'litersWasted: ${litersWasted.toStringAsFixed(3)}, '
      'percentOfTrip: ${percentOfTrip.toStringAsFixed(1)}, '
      'metadata: $metadata)';

  static bool _mapEquals(Map<String, num> a, Map<String, num> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
