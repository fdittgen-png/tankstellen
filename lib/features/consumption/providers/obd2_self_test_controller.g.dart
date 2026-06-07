// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_self_test_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Orchestrates the #2645 active adapter self-test and exposes live
/// per-step progress for the OBD2 health screen.
///
/// Runs the pure [runObd2SelfTest] driver step-by-step, pushing a new
/// `state` after every step transition so the UI animates live, then
/// surfaces the pass/fail summary on completion. The driver already
/// `endSession()`s the trace into [Obd2CommDiagnostics.instance], so the
/// screen's Recent-sessions + Copy-as-JSON pick the persisted session up
/// for free — this controller only carries the live banner state.
///
/// Two guards (the highest self-test risk — the single-link adapter):
///   * reentrancy — [run] refuses while a run is already in flight;
///   * active recording — [run] refuses while a trip recording owns the
///     `Obd2Service`, since a second connect on the half-duplex link would
///     collide with the recording. It surfaces [Obd2SelfTestPhase.blockedByRecording].
///
/// `keepAlive` so the result banner survives the health screen rebuilding
/// on every collector tick (an autoDispose notifier would reset the moment
/// the screen re-runs).

@ProviderFor(Obd2SelfTestController)
final obd2SelfTestControllerProvider = Obd2SelfTestControllerProvider._();

/// Orchestrates the #2645 active adapter self-test and exposes live
/// per-step progress for the OBD2 health screen.
///
/// Runs the pure [runObd2SelfTest] driver step-by-step, pushing a new
/// `state` after every step transition so the UI animates live, then
/// surfaces the pass/fail summary on completion. The driver already
/// `endSession()`s the trace into [Obd2CommDiagnostics.instance], so the
/// screen's Recent-sessions + Copy-as-JSON pick the persisted session up
/// for free — this controller only carries the live banner state.
///
/// Two guards (the highest self-test risk — the single-link adapter):
///   * reentrancy — [run] refuses while a run is already in flight;
///   * active recording — [run] refuses while a trip recording owns the
///     `Obd2Service`, since a second connect on the half-duplex link would
///     collide with the recording. It surfaces [Obd2SelfTestPhase.blockedByRecording].
///
/// `keepAlive` so the result banner survives the health screen rebuilding
/// on every collector tick (an autoDispose notifier would reset the moment
/// the screen re-runs).
final class Obd2SelfTestControllerProvider
    extends $NotifierProvider<Obd2SelfTestController, Obd2SelfTestState> {
  /// Orchestrates the #2645 active adapter self-test and exposes live
  /// per-step progress for the OBD2 health screen.
  ///
  /// Runs the pure [runObd2SelfTest] driver step-by-step, pushing a new
  /// `state` after every step transition so the UI animates live, then
  /// surfaces the pass/fail summary on completion. The driver already
  /// `endSession()`s the trace into [Obd2CommDiagnostics.instance], so the
  /// screen's Recent-sessions + Copy-as-JSON pick the persisted session up
  /// for free — this controller only carries the live banner state.
  ///
  /// Two guards (the highest self-test risk — the single-link adapter):
  ///   * reentrancy — [run] refuses while a run is already in flight;
  ///   * active recording — [run] refuses while a trip recording owns the
  ///     `Obd2Service`, since a second connect on the half-duplex link would
  ///     collide with the recording. It surfaces [Obd2SelfTestPhase.blockedByRecording].
  ///
  /// `keepAlive` so the result banner survives the health screen rebuilding
  /// on every collector tick (an autoDispose notifier would reset the moment
  /// the screen re-runs).
  Obd2SelfTestControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2SelfTestControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2SelfTestControllerHash();

  @$internal
  @override
  Obd2SelfTestController create() => Obd2SelfTestController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2SelfTestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2SelfTestState>(value),
    );
  }
}

String _$obd2SelfTestControllerHash() =>
    r'b62379b272ad7fe3dfbf585cf38518c706d68a92';

/// Orchestrates the #2645 active adapter self-test and exposes live
/// per-step progress for the OBD2 health screen.
///
/// Runs the pure [runObd2SelfTest] driver step-by-step, pushing a new
/// `state` after every step transition so the UI animates live, then
/// surfaces the pass/fail summary on completion. The driver already
/// `endSession()`s the trace into [Obd2CommDiagnostics.instance], so the
/// screen's Recent-sessions + Copy-as-JSON pick the persisted session up
/// for free — this controller only carries the live banner state.
///
/// Two guards (the highest self-test risk — the single-link adapter):
///   * reentrancy — [run] refuses while a run is already in flight;
///   * active recording — [run] refuses while a trip recording owns the
///     `Obd2Service`, since a second connect on the half-duplex link would
///     collide with the recording. It surfaces [Obd2SelfTestPhase.blockedByRecording].
///
/// `keepAlive` so the result banner survives the health screen rebuilding
/// on every collector tick (an autoDispose notifier would reset the moment
/// the screen re-runs).

abstract class _$Obd2SelfTestController extends $Notifier<Obd2SelfTestState> {
  Obd2SelfTestState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Obd2SelfTestState, Obd2SelfTestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Obd2SelfTestState, Obd2SelfTestState>,
              Obd2SelfTestState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
