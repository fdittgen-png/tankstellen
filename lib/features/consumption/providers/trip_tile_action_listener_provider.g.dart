// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'trip_tile_action_listener_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #3724 — routes the Android recording tile's action buttons onto the
/// SAME [TripRecording] methods the in-app controls call — zero
/// duplicated control logic. Action taps arrive as synthetic
/// `trip_action:<id>` payloads on the app-wide
/// [NotificationTapDispatcher] stream (wired in
/// LocalNotificationService).
///
/// Also sweeps a stale tile at startup: the plain notification outlives
/// a killed process, and this listener's init runs on every launch —
/// the LiveActivitySync/coordinator pair then re-shows it if (and only
/// if) a trip is actually recording.

@ProviderFor(tripTileActionListener)
final tripTileActionListenerProvider = TripTileActionListenerProvider._();

/// #3724 — routes the Android recording tile's action buttons onto the
/// SAME [TripRecording] methods the in-app controls call — zero
/// duplicated control logic. Action taps arrive as synthetic
/// `trip_action:<id>` payloads on the app-wide
/// [NotificationTapDispatcher] stream (wired in
/// LocalNotificationService).
///
/// Also sweeps a stale tile at startup: the plain notification outlives
/// a killed process, and this listener's init runs on every launch —
/// the LiveActivitySync/coordinator pair then re-shows it if (and only
/// if) a trip is actually recording.

final class TripTileActionListenerProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// #3724 — routes the Android recording tile's action buttons onto the
  /// SAME [TripRecording] methods the in-app controls call — zero
  /// duplicated control logic. Action taps arrive as synthetic
  /// `trip_action:<id>` payloads on the app-wide
  /// [NotificationTapDispatcher] stream (wired in
  /// LocalNotificationService).
  ///
  /// Also sweeps a stale tile at startup: the plain notification outlives
  /// a killed process, and this listener's init runs on every launch —
  /// the LiveActivitySync/coordinator pair then re-shows it if (and only
  /// if) a trip is actually recording.
  TripTileActionListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripTileActionListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripTileActionListenerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return tripTileActionListener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$tripTileActionListenerHash() =>
    r'e4f33bcfe9494e632f1a03c18cd86af186caf463';
