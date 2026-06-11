// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_coaching_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted user toggle for spoken driving coaching (#2663).
///
/// Backs a single device-local boolean onto `SharedPreferences`,
/// mirroring [GlideCoachSettingsNotifier] / [VoiceAnnouncementSettings].
/// Two deliberate departures from the voice-announcement settings:
///
///   1. **Default ON.** The issue asks coaching to speak by default
///      ("default on if no setting"); the bug was that it was silently
///      never wired, not that users opted out. The visible toggle (in
///      the coaching settings section) lets anyone mute it.
///   2. **Decoupled — no `Feature` gate.** Spoken coaching must work in
///      both OBD2 and GPS-only trips and has nothing to do with the
///      station-proximity approach overlay that gates
///      `Feature.voiceAnnouncements`. Wiring it behind that flag would
///      reproduce exactly the coupling the root-cause analysis flags.
///      Avoiding a `Feature` enum value also sidesteps the manifest +
///      feature-management-switch + count-test cascade.
///
/// The [DrivingCoachVoiceListener] reads this on every `build`; when it
/// resolves `false` the listener returns early and never subscribes — so
/// silence is guaranteed when disabled.

@ProviderFor(VoiceCoachingEnabled)
final voiceCoachingEnabledProvider = VoiceCoachingEnabledProvider._();

/// Persisted user toggle for spoken driving coaching (#2663).
///
/// Backs a single device-local boolean onto `SharedPreferences`,
/// mirroring [GlideCoachSettingsNotifier] / [VoiceAnnouncementSettings].
/// Two deliberate departures from the voice-announcement settings:
///
///   1. **Default ON.** The issue asks coaching to speak by default
///      ("default on if no setting"); the bug was that it was silently
///      never wired, not that users opted out. The visible toggle (in
///      the coaching settings section) lets anyone mute it.
///   2. **Decoupled — no `Feature` gate.** Spoken coaching must work in
///      both OBD2 and GPS-only trips and has nothing to do with the
///      station-proximity approach overlay that gates
///      `Feature.voiceAnnouncements`. Wiring it behind that flag would
///      reproduce exactly the coupling the root-cause analysis flags.
///      Avoiding a `Feature` enum value also sidesteps the manifest +
///      feature-management-switch + count-test cascade.
///
/// The [DrivingCoachVoiceListener] reads this on every `build`; when it
/// resolves `false` the listener returns early and never subscribes — so
/// silence is guaranteed when disabled.
final class VoiceCoachingEnabledProvider
    extends $NotifierProvider<VoiceCoachingEnabled, bool> {
  /// Persisted user toggle for spoken driving coaching (#2663).
  ///
  /// Backs a single device-local boolean onto `SharedPreferences`,
  /// mirroring [GlideCoachSettingsNotifier] / [VoiceAnnouncementSettings].
  /// Two deliberate departures from the voice-announcement settings:
  ///
  ///   1. **Default ON.** The issue asks coaching to speak by default
  ///      ("default on if no setting"); the bug was that it was silently
  ///      never wired, not that users opted out. The visible toggle (in
  ///      the coaching settings section) lets anyone mute it.
  ///   2. **Decoupled — no `Feature` gate.** Spoken coaching must work in
  ///      both OBD2 and GPS-only trips and has nothing to do with the
  ///      station-proximity approach overlay that gates
  ///      `Feature.voiceAnnouncements`. Wiring it behind that flag would
  ///      reproduce exactly the coupling the root-cause analysis flags.
  ///      Avoiding a `Feature` enum value also sidesteps the manifest +
  ///      feature-management-switch + count-test cascade.
  ///
  /// The [DrivingCoachVoiceListener] reads this on every `build`; when it
  /// resolves `false` the listener returns early and never subscribes — so
  /// silence is guaranteed when disabled.
  VoiceCoachingEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceCoachingEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceCoachingEnabledHash();

  @$internal
  @override
  VoiceCoachingEnabled create() => VoiceCoachingEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$voiceCoachingEnabledHash() =>
    r'15d87dcf5c85192b9e732da85214b81df3538e32';

/// Persisted user toggle for spoken driving coaching (#2663).
///
/// Backs a single device-local boolean onto `SharedPreferences`,
/// mirroring [GlideCoachSettingsNotifier] / [VoiceAnnouncementSettings].
/// Two deliberate departures from the voice-announcement settings:
///
///   1. **Default ON.** The issue asks coaching to speak by default
///      ("default on if no setting"); the bug was that it was silently
///      never wired, not that users opted out. The visible toggle (in
///      the coaching settings section) lets anyone mute it.
///   2. **Decoupled — no `Feature` gate.** Spoken coaching must work in
///      both OBD2 and GPS-only trips and has nothing to do with the
///      station-proximity approach overlay that gates
///      `Feature.voiceAnnouncements`. Wiring it behind that flag would
///      reproduce exactly the coupling the root-cause analysis flags.
///      Avoiding a `Feature` enum value also sidesteps the manifest +
///      feature-management-switch + count-test cascade.
///
/// The [DrivingCoachVoiceListener] reads this on every `build`; when it
/// resolves `false` the listener returns early and never subscribes — so
/// silence is guaranteed when disabled.

abstract class _$VoiceCoachingEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
