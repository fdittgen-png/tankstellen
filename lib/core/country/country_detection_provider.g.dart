// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Detects the user's country from their GPS position via reverse geocoding.
/// Watches [userPositionProvider] and updates when position changes.

@ProviderFor(DetectedCountry)
final detectedCountryProvider = DetectedCountryProvider._();

/// Detects the user's country from their GPS position via reverse geocoding.
/// Watches [userPositionProvider] and updates when position changes.
final class DetectedCountryProvider
    extends $NotifierProvider<DetectedCountry, String?> {
  /// Detects the user's country from their GPS position via reverse geocoding.
  /// Watches [userPositionProvider] and updates when position changes.
  DetectedCountryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectedCountryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectedCountryHash();

  @$internal
  @override
  DetectedCountry create() => DetectedCountry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$detectedCountryHash() => r'964c768179655a56dc2e11604370590e9710e5a5';

/// Detects the user's country from their GPS position via reverse geocoding.
/// Watches [userPositionProvider] and updates when position changes.

abstract class _$DetectedCountry extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
