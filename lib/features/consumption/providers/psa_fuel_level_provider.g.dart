// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'psa_fuel_level_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Override seam for the live [Obd2Service] (#1418).
///
/// Returns `null` in production — the live service is currently
/// owned by `Obd2ConnectionService` / the trip-recording stack and
/// is not exposed through Riverpod. The follow-up epic that
/// elevates the live service into Riverpod will replace this
/// default; until then [psaFuelLevelProvider] emits an empty stream
/// (the gate falls through to the `null` branch below).
///
/// Tests override this with a service backed by a fake transport so
/// they can exercise the gate + decoder pipe without touching real
/// Bluetooth.
///
/// ### Completion path (#1705, investigated 2026-05-16)
///
/// The decoder ([PsaFuelLevelCanDecoder]) is complete — this seam is
/// the only gap. To wire it: have `Obd2ConnectionService` (already a
/// provider — `obd2Connection`) hold and expose its active
/// `Obd2Service?` (it constructs one per connection in `connect()`),
/// then point this provider at that instead of `null`. No hardware is
/// needed for the wiring — only validating the decoder's big-endian
/// `0x0E6` assumption against a real PSA trace is hardware-blocked.
/// This is the same `Obd2Service`-ownership problem as epic #1665. The
/// keep / remove decision is tracked by #1705.

@ProviderFor(psaFuelLevelObd2Service)
final psaFuelLevelObd2ServiceProvider = PsaFuelLevelObd2ServiceProvider._();

/// Override seam for the live [Obd2Service] (#1418).
///
/// Returns `null` in production — the live service is currently
/// owned by `Obd2ConnectionService` / the trip-recording stack and
/// is not exposed through Riverpod. The follow-up epic that
/// elevates the live service into Riverpod will replace this
/// default; until then [psaFuelLevelProvider] emits an empty stream
/// (the gate falls through to the `null` branch below).
///
/// Tests override this with a service backed by a fake transport so
/// they can exercise the gate + decoder pipe without touching real
/// Bluetooth.
///
/// ### Completion path (#1705, investigated 2026-05-16)
///
/// The decoder ([PsaFuelLevelCanDecoder]) is complete — this seam is
/// the only gap. To wire it: have `Obd2ConnectionService` (already a
/// provider — `obd2Connection`) hold and expose its active
/// `Obd2Service?` (it constructs one per connection in `connect()`),
/// then point this provider at that instead of `null`. No hardware is
/// needed for the wiring — only validating the decoder's big-endian
/// `0x0E6` assumption against a real PSA trace is hardware-blocked.
/// This is the same `Obd2Service`-ownership problem as epic #1665. The
/// keep / remove decision is tracked by #1705.

final class PsaFuelLevelObd2ServiceProvider
    extends $FunctionalProvider<Obd2Service?, Obd2Service?, Obd2Service?>
    with $Provider<Obd2Service?> {
  /// Override seam for the live [Obd2Service] (#1418).
  ///
  /// Returns `null` in production — the live service is currently
  /// owned by `Obd2ConnectionService` / the trip-recording stack and
  /// is not exposed through Riverpod. The follow-up epic that
  /// elevates the live service into Riverpod will replace this
  /// default; until then [psaFuelLevelProvider] emits an empty stream
  /// (the gate falls through to the `null` branch below).
  ///
  /// Tests override this with a service backed by a fake transport so
  /// they can exercise the gate + decoder pipe without touching real
  /// Bluetooth.
  ///
  /// ### Completion path (#1705, investigated 2026-05-16)
  ///
  /// The decoder ([PsaFuelLevelCanDecoder]) is complete — this seam is
  /// the only gap. To wire it: have `Obd2ConnectionService` (already a
  /// provider — `obd2Connection`) hold and expose its active
  /// `Obd2Service?` (it constructs one per connection in `connect()`),
  /// then point this provider at that instead of `null`. No hardware is
  /// needed for the wiring — only validating the decoder's big-endian
  /// `0x0E6` assumption against a real PSA trace is hardware-blocked.
  /// This is the same `Obd2Service`-ownership problem as epic #1665. The
  /// keep / remove decision is tracked by #1705.
  PsaFuelLevelObd2ServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'psaFuelLevelObd2ServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$psaFuelLevelObd2ServiceHash();

  @$internal
  @override
  $ProviderElement<Obd2Service?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Obd2Service? create(Ref ref) {
    return psaFuelLevelObd2Service(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2Service? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2Service?>(value),
    );
  }
}

String _$psaFuelLevelObd2ServiceHash() =>
    r'f7fafc3a855b74dbd3b72688f778df5dccdf7c15';

/// Stream of decoded litres-in-tank from the PSA instrument-cluster
/// passive-CAN broadcast frame `0x0E6` (#1418).
///
/// Emits nothing (no events, never errors) when:
///   * the live [Obd2Service] override seam is unset
///     ([psaFuelLevelObd2ServiceProvider] returns `null`), or
///   * the connected adapter's runtime capability tier is not
///     [Obd2AdapterCapability.passiveCanCapable].
///
/// Otherwise subscribes to [Obd2Service.canFrameStream] and pipes
/// the raw `(id, payload)` records through
/// [PsaFuelLevelCanDecoder.filterFuelLevelStream] which yields one
/// litres value per successfully-decoded frame.
///
/// `keepAlive: false` — listener teardown is automatic when no UI
/// subscribes, which sends `STMP` to the adapter so the bus returns
/// to normal mode. The trip-recording flow can opt in via
/// `ref.listen` in a separate epic phase.

@ProviderFor(psaFuelLevel)
final psaFuelLevelProvider = PsaFuelLevelProvider._();

/// Stream of decoded litres-in-tank from the PSA instrument-cluster
/// passive-CAN broadcast frame `0x0E6` (#1418).
///
/// Emits nothing (no events, never errors) when:
///   * the live [Obd2Service] override seam is unset
///     ([psaFuelLevelObd2ServiceProvider] returns `null`), or
///   * the connected adapter's runtime capability tier is not
///     [Obd2AdapterCapability.passiveCanCapable].
///
/// Otherwise subscribes to [Obd2Service.canFrameStream] and pipes
/// the raw `(id, payload)` records through
/// [PsaFuelLevelCanDecoder.filterFuelLevelStream] which yields one
/// litres value per successfully-decoded frame.
///
/// `keepAlive: false` — listener teardown is automatic when no UI
/// subscribes, which sends `STMP` to the adapter so the bus returns
/// to normal mode. The trip-recording flow can opt in via
/// `ref.listen` in a separate epic phase.

final class PsaFuelLevelProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  /// Stream of decoded litres-in-tank from the PSA instrument-cluster
  /// passive-CAN broadcast frame `0x0E6` (#1418).
  ///
  /// Emits nothing (no events, never errors) when:
  ///   * the live [Obd2Service] override seam is unset
  ///     ([psaFuelLevelObd2ServiceProvider] returns `null`), or
  ///   * the connected adapter's runtime capability tier is not
  ///     [Obd2AdapterCapability.passiveCanCapable].
  ///
  /// Otherwise subscribes to [Obd2Service.canFrameStream] and pipes
  /// the raw `(id, payload)` records through
  /// [PsaFuelLevelCanDecoder.filterFuelLevelStream] which yields one
  /// litres value per successfully-decoded frame.
  ///
  /// `keepAlive: false` — listener teardown is automatic when no UI
  /// subscribes, which sends `STMP` to the adapter so the bus returns
  /// to normal mode. The trip-recording flow can opt in via
  /// `ref.listen` in a separate epic phase.
  PsaFuelLevelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'psaFuelLevelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$psaFuelLevelHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return psaFuelLevel(ref);
  }
}

String _$psaFuelLevelHash() => r'd8b15ad498ab2773176d74bd464673ba9bb065e1';
