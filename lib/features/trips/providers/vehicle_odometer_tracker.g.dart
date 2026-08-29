// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'vehicle_odometer_tracker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #3877 — mirrors the recording's live odometer into the per-vehicle
/// snapshot store WHILE the trip runs (the fuel-level tracker's twin), so
/// a crash or a discarded trip still leaves the last known km for the
/// next fill-up. Armed by `TripRecordingBanner`; the stop path writes the
/// final value itself (`_recordEndOdometer`).
///
/// Write policy: whenever the live READING changes (a periodic refresh
/// landed — at most one per `odometerRefreshInterval`), never on the
/// estimate ticking up, so the settings box sees a handful of writes per
/// drive.

@ProviderFor(VehicleOdometerTracker)
final vehicleOdometerTrackerProvider = VehicleOdometerTrackerProvider._();

/// #3877 — mirrors the recording's live odometer into the per-vehicle
/// snapshot store WHILE the trip runs (the fuel-level tracker's twin), so
/// a crash or a discarded trip still leaves the last known km for the
/// next fill-up. Armed by `TripRecordingBanner`; the stop path writes the
/// final value itself (`_recordEndOdometer`).
///
/// Write policy: whenever the live READING changes (a periodic refresh
/// landed — at most one per `odometerRefreshInterval`), never on the
/// estimate ticking up, so the settings box sees a handful of writes per
/// drive.
final class VehicleOdometerTrackerProvider
    extends $NotifierProvider<VehicleOdometerTracker, void> {
  /// #3877 — mirrors the recording's live odometer into the per-vehicle
  /// snapshot store WHILE the trip runs (the fuel-level tracker's twin), so
  /// a crash or a discarded trip still leaves the last known km for the
  /// next fill-up. Armed by `TripRecordingBanner`; the stop path writes the
  /// final value itself (`_recordEndOdometer`).
  ///
  /// Write policy: whenever the live READING changes (a periodic refresh
  /// landed — at most one per `odometerRefreshInterval`), never on the
  /// estimate ticking up, so the settings box sees a handful of writes per
  /// drive.
  VehicleOdometerTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleOdometerTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleOdometerTrackerHash();

  @$internal
  @override
  VehicleOdometerTracker create() => VehicleOdometerTracker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$vehicleOdometerTrackerHash() =>
    r'a79946dd148d26993cfd7fd817e4989bda0711f2';

/// #3877 — mirrors the recording's live odometer into the per-vehicle
/// snapshot store WHILE the trip runs (the fuel-level tracker's twin), so
/// a crash or a discarded trip still leaves the last known km for the
/// next fill-up. Armed by `TripRecordingBanner`; the stop path writes the
/// final value itself (`_recordEndOdometer`).
///
/// Write policy: whenever the live READING changes (a periodic refresh
/// landed — at most one per `odometerRefreshInterval`), never on the
/// estimate ticking up, so the settings box sees a handful of writes per
/// drive.

abstract class _$VehicleOdometerTracker extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
