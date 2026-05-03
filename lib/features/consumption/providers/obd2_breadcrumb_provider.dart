import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2/obd2_breadcrumb_collector.dart';

part 'obd2_breadcrumb_provider.g.dart';

/// Riverpod-backed wrapper around [Obd2BreadcrumbCollector] so widgets
/// (the in-app diagnostic overlay, tests) can subscribe to fuel-rate
/// breadcrumb updates without poking the collector directly (#1395).
///
/// `keepAlive: true` because the breadcrumbs are most useful AFTER
/// the trip ends (the user opens the overlay to inspect the trace
/// that produced a suspicious L/100 km figure on the summary). An
/// auto-disposing provider would throw the trace away the moment the
/// recording screen popped, defeating the diagnostic purpose.
///
/// The notifier implements [Obd2BreadcrumbRecorder] so the trip
/// recording controller and [Obd2Service] can write through ONE
/// reference and have every push republish the (immutable) entries
/// list to the overlay listeners. Tests that don't need Riverpod
/// reach for the raw [Obd2BreadcrumbCollector] instead.
@Riverpod(keepAlive: true)
class Obd2BreadcrumbsNotifier extends _$Obd2BreadcrumbsNotifier
    implements Obd2BreadcrumbRecorder {
  late final Obd2BreadcrumbCollector _collector;

  @override
  List<Obd2Breadcrumb> build() {
    _collector = Obd2BreadcrumbCollector();
    return const [];
  }

  /// Pushes a fuel-rate breadcrumb into the underlying ring buffer
  /// and republishes the (immutable) entries list so listeners
  /// rebuild. Mirrors [Obd2BreadcrumbCollector.record] arg-for-arg so
  /// callers don't have to import the collector type to push samples.
  @override
  void record({
    required Obd2BranchTag branch,
    double? fuelRateLPerHour,
    double? pid5ELPerHour,
    double? mafGramsPerSecond,
    double? mapKpa,
    double? iatCelsius,
    double? rpm,
    double? afr,
    double? fuelDensityGPerL,
    double? engineDisplacementCc,
    double? volumetricEfficiency,
    String? flag,
    String? flagDetail,
  }) {
    _collector.record(
      branch: branch,
      fuelRateLPerHour: fuelRateLPerHour,
      pid5ELPerHour: pid5ELPerHour,
      mafGramsPerSecond: mafGramsPerSecond,
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
      afr: afr,
      fuelDensityGPerL: fuelDensityGPerL,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
      flag: flag,
      flagDetail: flagDetail,
    );
    state = _collector.entries;
  }

  /// Records a sanity flag against the most-recent breadcrumb. Used
  /// by the cross-check sanity bound when PID 5E and MAF disagree.
  @override
  void recordFlag(String flag, String detail) {
    _collector.recordFlag(flag, detail);
    state = _collector.entries;
  }

  /// Snapshot + reset of the running suspicion counters, called by
  /// [TripRecordingController] at trip-end to roll the
  /// `fuelRateSuspect` bit onto [TripSummary]. Delegates to the
  /// underlying collector unchanged — no state republish needed; the
  /// entry list is preserved so the overlay continues showing the
  /// trace after the recording screen pops.
  @override
  ({int total, int suspicious}) snapshotAndResetCounters() =>
      _collector.snapshotAndResetCounters();

  /// Drops every recorded breadcrumb AND resets the running flag
  /// counters. Called from the overlay's "Clear" button and at the
  /// start of every fresh recording.
  void clear() {
    _collector.clear();
    state = const [];
  }
}
