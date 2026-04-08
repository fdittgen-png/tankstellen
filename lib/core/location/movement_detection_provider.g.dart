// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides movement detection state for driving mode.
///
/// When active, monitors GPS position changes and determines when the user
/// has moved far enough to warrant a station refresh. Consumers should
/// watch this provider and trigger their own search when
/// [MovementDetectionState.lastRefreshTime] changes.

@ProviderFor(MovementDetection)
final movementDetectionProvider = MovementDetectionProvider._();

/// Provides movement detection state for driving mode.
///
/// When active, monitors GPS position changes and determines when the user
/// has moved far enough to warrant a station refresh. Consumers should
/// watch this provider and trigger their own search when
/// [MovementDetectionState.lastRefreshTime] changes.
final class MovementDetectionProvider
    extends $NotifierProvider<MovementDetection, MovementDetectionState> {
  /// Provides movement detection state for driving mode.
  ///
  /// When active, monitors GPS position changes and determines when the user
  /// has moved far enough to warrant a station refresh. Consumers should
  /// watch this provider and trigger their own search when
  /// [MovementDetectionState.lastRefreshTime] changes.
  MovementDetectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'movementDetectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$movementDetectionHash();

  @$internal
  @override
  MovementDetection create() => MovementDetection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MovementDetectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MovementDetectionState>(value),
    );
  }
}

String _$movementDetectionHash() => r'7b2830093b581101f9d647c7d6616c33e99490b6';

/// Provides movement detection state for driving mode.
///
/// When active, monitors GPS position changes and determines when the user
/// has moved far enough to warrant a station refresh. Consumers should
/// watch this provider and trigger their own search when
/// [MovementDetectionState.lastRefreshTime] changes.

abstract class _$MovementDetection extends $Notifier<MovementDetectionState> {
  MovementDetectionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<MovementDetectionState, MovementDetectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MovementDetectionState, MovementDetectionState>,
              MovementDetectionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
