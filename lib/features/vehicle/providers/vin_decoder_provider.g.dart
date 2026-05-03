// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vin_decoder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared [VinDecoder] instance (#812 phase 2).
///
/// `keepAlive: true` so the Dio rate-limiter and its cache of in-flight
/// requests survives between decode attempts — a user may paste the
/// wrong VIN, correct it, and hit decode again within seconds. We
/// don't want to re-create the whole HTTP stack each time.

@ProviderFor(vinDecoder)
final vinDecoderProvider = VinDecoderProvider._();

/// Shared [VinDecoder] instance (#812 phase 2).
///
/// `keepAlive: true` so the Dio rate-limiter and its cache of in-flight
/// requests survives between decode attempts — a user may paste the
/// wrong VIN, correct it, and hit decode again within seconds. We
/// don't want to re-create the whole HTTP stack each time.

final class VinDecoderProvider
    extends $FunctionalProvider<VinDecoder, VinDecoder, VinDecoder>
    with $Provider<VinDecoder> {
  /// Shared [VinDecoder] instance (#812 phase 2).
  ///
  /// `keepAlive: true` so the Dio rate-limiter and its cache of in-flight
  /// requests survives between decode attempts — a user may paste the
  /// wrong VIN, correct it, and hit decode again within seconds. We
  /// don't want to re-create the whole HTTP stack each time.
  VinDecoderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vinDecoderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vinDecoderHash();

  @$internal
  @override
  $ProviderElement<VinDecoder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VinDecoder create(Ref ref) {
    return vinDecoder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VinDecoder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VinDecoder>(value),
    );
  }
}

String _$vinDecoderHash() => r'7577674da37299c1f3c94f0c8edcb332ec2fb578';

/// VIN decoder for the auto-population flow (#1399). Honors the
/// `vinOnlineDecode` GDPR consent toggle: when the user has not opted
/// in, the network call is skipped entirely and the decoder runs in
/// offline-only mode (WMI + position-10 year).
///
/// Distinct from [vinDecoderProvider] — that decoder is for the
/// existing manual VIN-entry flow on the edit-vehicle screen, where
/// the user has explicitly typed a VIN and tapped "decode" so the
/// online lookup is implicitly consented to. The auto-population flow
/// runs silently on adapter pair, so it must respect the explicit
/// consent toggle.
///
/// NOT keepAlive: rebuilds when the consent toggles so the next
/// adapter-pair flow honors the freshest setting without an app
/// restart.

@ProviderFor(consentAwareVinDecoder)
final consentAwareVinDecoderProvider = ConsentAwareVinDecoderProvider._();

/// VIN decoder for the auto-population flow (#1399). Honors the
/// `vinOnlineDecode` GDPR consent toggle: when the user has not opted
/// in, the network call is skipped entirely and the decoder runs in
/// offline-only mode (WMI + position-10 year).
///
/// Distinct from [vinDecoderProvider] — that decoder is for the
/// existing manual VIN-entry flow on the edit-vehicle screen, where
/// the user has explicitly typed a VIN and tapped "decode" so the
/// online lookup is implicitly consented to. The auto-population flow
/// runs silently on adapter pair, so it must respect the explicit
/// consent toggle.
///
/// NOT keepAlive: rebuilds when the consent toggles so the next
/// adapter-pair flow honors the freshest setting without an app
/// restart.

final class ConsentAwareVinDecoderProvider
    extends $FunctionalProvider<VinDecoder, VinDecoder, VinDecoder>
    with $Provider<VinDecoder> {
  /// VIN decoder for the auto-population flow (#1399). Honors the
  /// `vinOnlineDecode` GDPR consent toggle: when the user has not opted
  /// in, the network call is skipped entirely and the decoder runs in
  /// offline-only mode (WMI + position-10 year).
  ///
  /// Distinct from [vinDecoderProvider] — that decoder is for the
  /// existing manual VIN-entry flow on the edit-vehicle screen, where
  /// the user has explicitly typed a VIN and tapped "decode" so the
  /// online lookup is implicitly consented to. The auto-population flow
  /// runs silently on adapter pair, so it must respect the explicit
  /// consent toggle.
  ///
  /// NOT keepAlive: rebuilds when the consent toggles so the next
  /// adapter-pair flow honors the freshest setting without an app
  /// restart.
  ConsentAwareVinDecoderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentAwareVinDecoderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentAwareVinDecoderHash();

  @$internal
  @override
  $ProviderElement<VinDecoder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VinDecoder create(Ref ref) {
    return consentAwareVinDecoder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VinDecoder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VinDecoder>(value),
    );
  }
}

String _$consentAwareVinDecoderHash() =>
    r'85926c4c59bc47084043169d0a7e9780b6159340';

/// Async family that decodes a given [vin] into [VinData] via the
/// shared [VinDecoder] (#812 phase 2).
///
/// Keyed by the trimmed, upper-cased VIN so two screens that ask for
/// the same VIN in the same session share a single decoded response.
/// Empty or short strings return `null` without touching the network —
/// the UI should gate the provider read behind a length check, but we
/// short-circuit here too as a safety net.
///
/// `keepAlive: true` so the result is cached for the session. When
/// the user edits the VIN field, the widget reads a different family
/// key and triggers a fresh decode; the previous family entry stays
/// in memory until the ProviderScope is torn down.

@ProviderFor(decodedVin)
final decodedVinProvider = DecodedVinFamily._();

/// Async family that decodes a given [vin] into [VinData] via the
/// shared [VinDecoder] (#812 phase 2).
///
/// Keyed by the trimmed, upper-cased VIN so two screens that ask for
/// the same VIN in the same session share a single decoded response.
/// Empty or short strings return `null` without touching the network —
/// the UI should gate the provider read behind a length check, but we
/// short-circuit here too as a safety net.
///
/// `keepAlive: true` so the result is cached for the session. When
/// the user edits the VIN field, the widget reads a different family
/// key and triggers a fresh decode; the previous family entry stays
/// in memory until the ProviderScope is torn down.

final class DecodedVinProvider
    extends
        $FunctionalProvider<AsyncValue<VinData?>, VinData?, FutureOr<VinData?>>
    with $FutureModifier<VinData?>, $FutureProvider<VinData?> {
  /// Async family that decodes a given [vin] into [VinData] via the
  /// shared [VinDecoder] (#812 phase 2).
  ///
  /// Keyed by the trimmed, upper-cased VIN so two screens that ask for
  /// the same VIN in the same session share a single decoded response.
  /// Empty or short strings return `null` without touching the network —
  /// the UI should gate the provider read behind a length check, but we
  /// short-circuit here too as a safety net.
  ///
  /// `keepAlive: true` so the result is cached for the session. When
  /// the user edits the VIN field, the widget reads a different family
  /// key and triggers a fresh decode; the previous family entry stays
  /// in memory until the ProviderScope is torn down.
  DecodedVinProvider._({
    required DecodedVinFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'decodedVinProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$decodedVinHash();

  @override
  String toString() {
    return r'decodedVinProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VinData?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<VinData?> create(Ref ref) {
    final argument = this.argument as String;
    return decodedVin(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DecodedVinProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$decodedVinHash() => r'6f114b8fadcbb3a0981e22cab723cd7df61f59fe';

/// Async family that decodes a given [vin] into [VinData] via the
/// shared [VinDecoder] (#812 phase 2).
///
/// Keyed by the trimmed, upper-cased VIN so two screens that ask for
/// the same VIN in the same session share a single decoded response.
/// Empty or short strings return `null` without touching the network —
/// the UI should gate the provider read behind a length check, but we
/// short-circuit here too as a safety net.
///
/// `keepAlive: true` so the result is cached for the session. When
/// the user edits the VIN field, the widget reads a different family
/// key and triggers a fresh decode; the previous family entry stays
/// in memory until the ProviderScope is torn down.

final class DecodedVinFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VinData?>, String> {
  DecodedVinFamily._()
    : super(
        retry: null,
        name: r'decodedVinProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Async family that decodes a given [vin] into [VinData] via the
  /// shared [VinDecoder] (#812 phase 2).
  ///
  /// Keyed by the trimmed, upper-cased VIN so two screens that ask for
  /// the same VIN in the same session share a single decoded response.
  /// Empty or short strings return `null` without touching the network —
  /// the UI should gate the provider read behind a length check, but we
  /// short-circuit here too as a safety net.
  ///
  /// `keepAlive: true` so the result is cached for the session. When
  /// the user edits the VIN field, the widget reads a different family
  /// key and triggers a fresh decode; the previous family entry stays
  /// in memory until the ProviderScope is torn down.

  DecodedVinProvider call(String vin) =>
      DecodedVinProvider._(argument: vin, from: this);

  @override
  String toString() => r'decodedVinProvider';
}
