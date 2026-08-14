// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_engine_start_hint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #3699 — turn Bluetooth ACL connects into reconnect wakes.
///
/// The stand-down escalation is correct while the car is parked (the
/// adapter sleeps; every probe is a doomed 23 s timeout), but before
/// this wiring NOTHING broke the hold at engine start with the phone
/// pocketed: `wake()` fired only on app resume and on GPS movement
/// during an already-running recording. Field shape (2026-08-11):
/// overnight misses escalated the hold past an hour and the morning
/// drive got no hands-free connect until the app was opened.
///
/// The phone linking to ANY Bluetooth device — in the car, the audio
/// system, at exactly ignition-on when the vLinker wakes from its 3 mA
/// sleep — is the cheapest engine-start signal Android offers without
/// new permissions. The native receiver already rate-limits to one hint
/// per 5 min; here we drop hints older than [staleness] (the native
/// ring can replay buffered hints on resubscribe) and nudge `wake()`,
/// which is a no-op in every state where waking is meaningless and an
/// immediate dial in `engineOff` / held-`reconnecting`.

@ProviderFor(engineStartHintWake)
final engineStartHintWakeProvider = EngineStartHintWakeProvider._();

/// #3699 — turn Bluetooth ACL connects into reconnect wakes.
///
/// The stand-down escalation is correct while the car is parked (the
/// adapter sleeps; every probe is a doomed 23 s timeout), but before
/// this wiring NOTHING broke the hold at engine start with the phone
/// pocketed: `wake()` fired only on app resume and on GPS movement
/// during an already-running recording. Field shape (2026-08-11):
/// overnight misses escalated the hold past an hour and the morning
/// drive got no hands-free connect until the app was opened.
///
/// The phone linking to ANY Bluetooth device — in the car, the audio
/// system, at exactly ignition-on when the vLinker wakes from its 3 mA
/// sleep — is the cheapest engine-start signal Android offers without
/// new permissions. The native receiver already rate-limits to one hint
/// per 5 min; here we drop hints older than [staleness] (the native
/// ring can replay buffered hints on resubscribe) and nudge `wake()`,
/// which is a no-op in every state where waking is meaningless and an
/// immediate dial in `engineOff` / held-`reconnecting`.

final class EngineStartHintWakeProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// #3699 — turn Bluetooth ACL connects into reconnect wakes.
  ///
  /// The stand-down escalation is correct while the car is parked (the
  /// adapter sleeps; every probe is a doomed 23 s timeout), but before
  /// this wiring NOTHING broke the hold at engine start with the phone
  /// pocketed: `wake()` fired only on app resume and on GPS movement
  /// during an already-running recording. Field shape (2026-08-11):
  /// overnight misses escalated the hold past an hour and the morning
  /// drive got no hands-free connect until the app was opened.
  ///
  /// The phone linking to ANY Bluetooth device — in the car, the audio
  /// system, at exactly ignition-on when the vLinker wakes from its 3 mA
  /// sleep — is the cheapest engine-start signal Android offers without
  /// new permissions. The native receiver already rate-limits to one hint
  /// per 5 min; here we drop hints older than [staleness] (the native
  /// ring can replay buffered hints on resubscribe) and nudge `wake()`,
  /// which is a no-op in every state where waking is meaningless and an
  /// immediate dial in `engineOff` / held-`reconnecting`.
  EngineStartHintWakeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engineStartHintWakeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engineStartHintWakeHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return engineStartHintWake(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$engineStartHintWakeHash() =>
    r'c571dee3267a3c0ef80e46c23ea6048d5ecc51d6';
