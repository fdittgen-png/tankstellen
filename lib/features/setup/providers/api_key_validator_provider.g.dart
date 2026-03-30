// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_validator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiKeyValidator)
final apiKeyValidatorProvider = ApiKeyValidatorProvider._();

final class ApiKeyValidatorProvider
    extends
        $FunctionalProvider<ApiKeyValidator, ApiKeyValidator, ApiKeyValidator>
    with $Provider<ApiKeyValidator> {
  ApiKeyValidatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeyValidatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeyValidatorHash();

  @$internal
  @override
  $ProviderElement<ApiKeyValidator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiKeyValidator create(Ref ref) {
    return apiKeyValidator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiKeyValidator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiKeyValidator>(value),
    );
  }
}

String _$apiKeyValidatorHash() => r'e35850d4ac8042581959235190cf80ff6b6f2eb1';
