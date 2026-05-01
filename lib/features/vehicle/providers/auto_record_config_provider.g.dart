// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_record_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-vehicle auto-record configuration (#1004 phase 1).
///
/// Reads the [VehicleProfile] identified by [vehicleProfileId] from
/// [vehicleProfileListProvider] and projects it into a small
/// immutable [AutoRecordConfig] value. Returning a narrow projection
/// (instead of the whole profile) keeps the phase 2+ background-
/// isolate API minimal and prevents accidental coupling to unrelated
/// fields like baselines or aggregates.
///
/// When the profile id is not found in the list, the provider
/// returns [AutoRecordConfig.defaults] — that way callers do not
/// need a separate "is this vehicle known yet?" branch.

@ProviderFor(autoRecordConfig)
final autoRecordConfigProvider = AutoRecordConfigFamily._();

/// Per-vehicle auto-record configuration (#1004 phase 1).
///
/// Reads the [VehicleProfile] identified by [vehicleProfileId] from
/// [vehicleProfileListProvider] and projects it into a small
/// immutable [AutoRecordConfig] value. Returning a narrow projection
/// (instead of the whole profile) keeps the phase 2+ background-
/// isolate API minimal and prevents accidental coupling to unrelated
/// fields like baselines or aggregates.
///
/// When the profile id is not found in the list, the provider
/// returns [AutoRecordConfig.defaults] — that way callers do not
/// need a separate "is this vehicle known yet?" branch.

final class AutoRecordConfigProvider
    extends
        $FunctionalProvider<
          AutoRecordConfig,
          AutoRecordConfig,
          AutoRecordConfig
        >
    with $Provider<AutoRecordConfig> {
  /// Per-vehicle auto-record configuration (#1004 phase 1).
  ///
  /// Reads the [VehicleProfile] identified by [vehicleProfileId] from
  /// [vehicleProfileListProvider] and projects it into a small
  /// immutable [AutoRecordConfig] value. Returning a narrow projection
  /// (instead of the whole profile) keeps the phase 2+ background-
  /// isolate API minimal and prevents accidental coupling to unrelated
  /// fields like baselines or aggregates.
  ///
  /// When the profile id is not found in the list, the provider
  /// returns [AutoRecordConfig.defaults] — that way callers do not
  /// need a separate "is this vehicle known yet?" branch.
  AutoRecordConfigProvider._({
    required AutoRecordConfigFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'autoRecordConfigProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$autoRecordConfigHash();

  @override
  String toString() {
    return r'autoRecordConfigProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AutoRecordConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AutoRecordConfig create(Ref ref) {
    final argument = this.argument as String;
    return autoRecordConfig(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoRecordConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoRecordConfig>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AutoRecordConfigProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$autoRecordConfigHash() => r'e7933f50bf4f726f5a597ba1e1a3de4e7869435e';

/// Per-vehicle auto-record configuration (#1004 phase 1).
///
/// Reads the [VehicleProfile] identified by [vehicleProfileId] from
/// [vehicleProfileListProvider] and projects it into a small
/// immutable [AutoRecordConfig] value. Returning a narrow projection
/// (instead of the whole profile) keeps the phase 2+ background-
/// isolate API minimal and prevents accidental coupling to unrelated
/// fields like baselines or aggregates.
///
/// When the profile id is not found in the list, the provider
/// returns [AutoRecordConfig.defaults] — that way callers do not
/// need a separate "is this vehicle known yet?" branch.

final class AutoRecordConfigFamily extends $Family
    with $FunctionalFamilyOverride<AutoRecordConfig, String> {
  AutoRecordConfigFamily._()
    : super(
        retry: null,
        name: r'autoRecordConfigProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-vehicle auto-record configuration (#1004 phase 1).
  ///
  /// Reads the [VehicleProfile] identified by [vehicleProfileId] from
  /// [vehicleProfileListProvider] and projects it into a small
  /// immutable [AutoRecordConfig] value. Returning a narrow projection
  /// (instead of the whole profile) keeps the phase 2+ background-
  /// isolate API minimal and prevents accidental coupling to unrelated
  /// fields like baselines or aggregates.
  ///
  /// When the profile id is not found in the list, the provider
  /// returns [AutoRecordConfig.defaults] — that way callers do not
  /// need a separate "is this vehicle known yet?" branch.

  AutoRecordConfigProvider call(String vehicleProfileId) =>
      AutoRecordConfigProvider._(argument: vehicleProfileId, from: this);

  @override
  String toString() => r'autoRecordConfigProvider';
}
