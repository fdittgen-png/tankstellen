// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pip_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single app-wide [PipController] (#1977).
///
/// Picture-in-Picture is Activity-bound and the `tankstellen/pip`
/// MethodChannel admits exactly one handler, so the controller must be
/// a singleton — every consumer reads this provider rather than
/// constructing its own (two controllers raced on the channel handler).

@ProviderFor(pipController)
final pipControllerProvider = PipControllerProvider._();

/// The single app-wide [PipController] (#1977).
///
/// Picture-in-Picture is Activity-bound and the `tankstellen/pip`
/// MethodChannel admits exactly one handler, so the controller must be
/// a singleton — every consumer reads this provider rather than
/// constructing its own (two controllers raced on the channel handler).

final class PipControllerProvider
    extends $FunctionalProvider<PipController, PipController, PipController>
    with $Provider<PipController> {
  /// The single app-wide [PipController] (#1977).
  ///
  /// Picture-in-Picture is Activity-bound and the `tankstellen/pip`
  /// MethodChannel admits exactly one handler, so the controller must be
  /// a singleton — every consumer reads this provider rather than
  /// constructing its own (two controllers raced on the channel handler).
  PipControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pipControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pipControllerHash();

  @$internal
  @override
  $ProviderElement<PipController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PipController create(Ref ref) {
    return pipController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PipController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PipController>(value),
    );
  }
}

String _$pipControllerHash() => r'986a3ad52327b423b85aa5a69ca6793eed9019bb';

/// Whether the OS currently has the app shrunk into a Picture-in-
/// Picture tile (#1977).
///
/// App-wide so `TripRecordingBanner` — which wraps every screen via
/// `MaterialApp.builder` — can collapse the UI down to the compact
/// trip tile in PiP, regardless of which route was visible when PiP
/// fired. Before this, the compact tile only rendered when the user
/// happened to be on `/trip-recording`, so auto-PiP from a shell
/// branch shrank the whole shell — bottom nav bar and all — into the
/// tile.

@ProviderFor(PipMode)
final pipModeProvider = PipModeProvider._();

/// Whether the OS currently has the app shrunk into a Picture-in-
/// Picture tile (#1977).
///
/// App-wide so `TripRecordingBanner` — which wraps every screen via
/// `MaterialApp.builder` — can collapse the UI down to the compact
/// trip tile in PiP, regardless of which route was visible when PiP
/// fired. Before this, the compact tile only rendered when the user
/// happened to be on `/trip-recording`, so auto-PiP from a shell
/// branch shrank the whole shell — bottom nav bar and all — into the
/// tile.
final class PipModeProvider extends $NotifierProvider<PipMode, bool> {
  /// Whether the OS currently has the app shrunk into a Picture-in-
  /// Picture tile (#1977).
  ///
  /// App-wide so `TripRecordingBanner` — which wraps every screen via
  /// `MaterialApp.builder` — can collapse the UI down to the compact
  /// trip tile in PiP, regardless of which route was visible when PiP
  /// fired. Before this, the compact tile only rendered when the user
  /// happened to be on `/trip-recording`, so auto-PiP from a shell
  /// branch shrank the whole shell — bottom nav bar and all — into the
  /// tile.
  PipModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pipModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pipModeHash();

  @$internal
  @override
  PipMode create() => PipMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pipModeHash() => r'bceb9916a8bf8e765014dddb154e6b11c6f3a6d4';

/// Whether the OS currently has the app shrunk into a Picture-in-
/// Picture tile (#1977).
///
/// App-wide so `TripRecordingBanner` — which wraps every screen via
/// `MaterialApp.builder` — can collapse the UI down to the compact
/// trip tile in PiP, regardless of which route was visible when PiP
/// fired. Before this, the compact tile only rendered when the user
/// happened to be on `/trip-recording`, so auto-PiP from a shell
/// branch shrank the whole shell — bottom nav bar and all — into the
/// tile.

abstract class _$PipMode extends $Notifier<bool> {
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
