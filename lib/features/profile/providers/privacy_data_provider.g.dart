// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Collects a snapshot of all locally stored user data.

@ProviderFor(privacyData)
final privacyDataProvider = PrivacyDataProvider._();

/// Collects a snapshot of all locally stored user data.

final class PrivacyDataProvider
    extends
        $FunctionalProvider<
          PrivacyDataSnapshot,
          PrivacyDataSnapshot,
          PrivacyDataSnapshot
        >
    with $Provider<PrivacyDataSnapshot> {
  /// Collects a snapshot of all locally stored user data.
  PrivacyDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyDataHash();

  @$internal
  @override
  $ProviderElement<PrivacyDataSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PrivacyDataSnapshot create(Ref ref) {
    return privacyData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrivacyDataSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrivacyDataSnapshot>(value),
    );
  }
}

String _$privacyDataHash() => r'c004c1b4d435170de05f841b7fa0b8a90ff4db2d';

/// Exports all user data as a JSON string for GDPR data portability.
///
/// Excludes API keys for security — the user re-enters those on import.
/// Excludes cache data because it is ephemeral and reconstructable.

@ProviderFor(exportPrivacyData)
final exportPrivacyDataProvider = ExportPrivacyDataProvider._();

/// Exports all user data as a JSON string for GDPR data portability.
///
/// Excludes API keys for security — the user re-enters those on import.
/// Excludes cache data because it is ephemeral and reconstructable.

final class ExportPrivacyDataProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Exports all user data as a JSON string for GDPR data portability.
  ///
  /// Excludes API keys for security — the user re-enters those on import.
  /// Excludes cache data because it is ephemeral and reconstructable.
  ExportPrivacyDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportPrivacyDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportPrivacyDataHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return exportPrivacyData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$exportPrivacyDataHash() => r'0734ab85ebe78e42069067342530347b7414e25c';
