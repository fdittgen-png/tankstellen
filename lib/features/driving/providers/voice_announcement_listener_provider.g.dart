// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_announcement_listener_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live call site that wires the dormant [AnnouncementEngine] into the
/// real driving flow (#2569).
///
/// This is the ONE integration listener the feature needs. It piggybacks
/// on the existing live geofence (`approachStateProvider`) the approach
/// overlay already drives — no second GPS subscription, no second poll
/// loop. On every [ApproachInRadius] transition it hands the imminent
/// station to [AnnouncementEngine.evaluateAndAnnounce] with the user's
/// persisted [AnnouncementConfig]; the engine then enforces the price
/// threshold, the (voice-specific) proximity radius, and the per-station
/// repeat cooldown that already prevent over-announcing. The engine
/// short-circuits when its `enabled` flag is false, and this provider
/// never subscribes at all while the feature gate is off — so the flag
/// is honoured at two layers.
///
/// `keepAlive: true` because a trip + its approach stream outlive widget
/// rebuilds as the driver navigates the app mid-trip.

@ProviderFor(VoiceAnnouncementListener)
final voiceAnnouncementListenerProvider = VoiceAnnouncementListenerProvider._();

/// Live call site that wires the dormant [AnnouncementEngine] into the
/// real driving flow (#2569).
///
/// This is the ONE integration listener the feature needs. It piggybacks
/// on the existing live geofence (`approachStateProvider`) the approach
/// overlay already drives — no second GPS subscription, no second poll
/// loop. On every [ApproachInRadius] transition it hands the imminent
/// station to [AnnouncementEngine.evaluateAndAnnounce] with the user's
/// persisted [AnnouncementConfig]; the engine then enforces the price
/// threshold, the (voice-specific) proximity radius, and the per-station
/// repeat cooldown that already prevent over-announcing. The engine
/// short-circuits when its `enabled` flag is false, and this provider
/// never subscribes at all while the feature gate is off — so the flag
/// is honoured at two layers.
///
/// `keepAlive: true` because a trip + its approach stream outlive widget
/// rebuilds as the driver navigates the app mid-trip.
final class VoiceAnnouncementListenerProvider
    extends $NotifierProvider<VoiceAnnouncementListener, void> {
  /// Live call site that wires the dormant [AnnouncementEngine] into the
  /// real driving flow (#2569).
  ///
  /// This is the ONE integration listener the feature needs. It piggybacks
  /// on the existing live geofence (`approachStateProvider`) the approach
  /// overlay already drives — no second GPS subscription, no second poll
  /// loop. On every [ApproachInRadius] transition it hands the imminent
  /// station to [AnnouncementEngine.evaluateAndAnnounce] with the user's
  /// persisted [AnnouncementConfig]; the engine then enforces the price
  /// threshold, the (voice-specific) proximity radius, and the per-station
  /// repeat cooldown that already prevent over-announcing. The engine
  /// short-circuits when its `enabled` flag is false, and this provider
  /// never subscribes at all while the feature gate is off — so the flag
  /// is honoured at two layers.
  ///
  /// `keepAlive: true` because a trip + its approach stream outlive widget
  /// rebuilds as the driver navigates the app mid-trip.
  VoiceAnnouncementListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceAnnouncementListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceAnnouncementListenerHash();

  @$internal
  @override
  VoiceAnnouncementListener create() => VoiceAnnouncementListener();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$voiceAnnouncementListenerHash() =>
    r'ff5052c37b2d87644165c775fe15a5b631e23266';

/// Live call site that wires the dormant [AnnouncementEngine] into the
/// real driving flow (#2569).
///
/// This is the ONE integration listener the feature needs. It piggybacks
/// on the existing live geofence (`approachStateProvider`) the approach
/// overlay already drives — no second GPS subscription, no second poll
/// loop. On every [ApproachInRadius] transition it hands the imminent
/// station to [AnnouncementEngine.evaluateAndAnnounce] with the user's
/// persisted [AnnouncementConfig]; the engine then enforces the price
/// threshold, the (voice-specific) proximity radius, and the per-station
/// repeat cooldown that already prevent over-announcing. The engine
/// short-circuits when its `enabled` flag is false, and this provider
/// never subscribes at all while the feature gate is off — so the flag
/// is honoured at two layers.
///
/// `keepAlive: true` because a trip + its approach stream outlive widget
/// rebuilds as the driver navigates the app mid-trip.

abstract class _$VoiceAnnouncementListener extends $Notifier<void> {
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
