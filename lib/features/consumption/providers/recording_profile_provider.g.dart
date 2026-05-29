// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide owner of the persisted [RecordingProfile] (#2274 concern 1).
///
/// Holds the GLOBAL profile as its state and reads/writes per-vehicle
/// overrides on demand. Both live in the unencrypted `settings` Hive box
/// (the profile is a handful of bools, not PII) keyed by
/// [StorageKeys.recordingProfile] and
/// [StorageKeys.recordingProfileVehicleOverridePrefix]`<vehicleId>`.
///
/// `keepAlive: true` because the profile is read on every recording-screen
/// mount; rebuilding it on every listener churn would re-read Hive for
/// nothing. Every field defaults OFF, so a fresh install — and a
/// pre-#2274 install with no persisted payload — behaves exactly as the
/// app did before this provider existed (opt-in pinning each drive).

@ProviderFor(RecordingProfileController)
final recordingProfileControllerProvider =
    RecordingProfileControllerProvider._();

/// App-wide owner of the persisted [RecordingProfile] (#2274 concern 1).
///
/// Holds the GLOBAL profile as its state and reads/writes per-vehicle
/// overrides on demand. Both live in the unencrypted `settings` Hive box
/// (the profile is a handful of bools, not PII) keyed by
/// [StorageKeys.recordingProfile] and
/// [StorageKeys.recordingProfileVehicleOverridePrefix]`<vehicleId>`.
///
/// `keepAlive: true` because the profile is read on every recording-screen
/// mount; rebuilding it on every listener churn would re-read Hive for
/// nothing. Every field defaults OFF, so a fresh install — and a
/// pre-#2274 install with no persisted payload — behaves exactly as the
/// app did before this provider existed (opt-in pinning each drive).
final class RecordingProfileControllerProvider
    extends $NotifierProvider<RecordingProfileController, RecordingProfile> {
  /// App-wide owner of the persisted [RecordingProfile] (#2274 concern 1).
  ///
  /// Holds the GLOBAL profile as its state and reads/writes per-vehicle
  /// overrides on demand. Both live in the unencrypted `settings` Hive box
  /// (the profile is a handful of bools, not PII) keyed by
  /// [StorageKeys.recordingProfile] and
  /// [StorageKeys.recordingProfileVehicleOverridePrefix]`<vehicleId>`.
  ///
  /// `keepAlive: true` because the profile is read on every recording-screen
  /// mount; rebuilding it on every listener churn would re-read Hive for
  /// nothing. Every field defaults OFF, so a fresh install — and a
  /// pre-#2274 install with no persisted payload — behaves exactly as the
  /// app did before this provider existed (opt-in pinning each drive).
  RecordingProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingProfileControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingProfileControllerHash();

  @$internal
  @override
  RecordingProfileController create() => RecordingProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingProfile>(value),
    );
  }
}

String _$recordingProfileControllerHash() =>
    r'55bcd8fe66a99e4d292a43f9bcf2e82c657d40ca';

/// App-wide owner of the persisted [RecordingProfile] (#2274 concern 1).
///
/// Holds the GLOBAL profile as its state and reads/writes per-vehicle
/// overrides on demand. Both live in the unencrypted `settings` Hive box
/// (the profile is a handful of bools, not PII) keyed by
/// [StorageKeys.recordingProfile] and
/// [StorageKeys.recordingProfileVehicleOverridePrefix]`<vehicleId>`.
///
/// `keepAlive: true` because the profile is read on every recording-screen
/// mount; rebuilding it on every listener churn would re-read Hive for
/// nothing. Every field defaults OFF, so a fresh install — and a
/// pre-#2274 install with no persisted payload — behaves exactly as the
/// app did before this provider existed (opt-in pinning each drive).

abstract class _$RecordingProfileController
    extends $Notifier<RecordingProfile> {
  RecordingProfile build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RecordingProfile, RecordingProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecordingProfile, RecordingProfile>,
              RecordingProfile,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
