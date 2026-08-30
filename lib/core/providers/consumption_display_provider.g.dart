// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'consumption_display_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted consumption-display preference (#3883). Device-local like
/// the theme choice, so it lives in SharedPreferences and is readable
/// before any Hive box opens.

@ProviderFor(ConsumptionDisplaySetting)
final consumptionDisplaySettingProvider = ConsumptionDisplaySettingProvider._();

/// Persisted consumption-display preference (#3883). Device-local like
/// the theme choice, so it lives in SharedPreferences and is readable
/// before any Hive box opens.
final class ConsumptionDisplaySettingProvider
    extends $NotifierProvider<ConsumptionDisplaySetting, ConsumptionDisplay> {
  /// Persisted consumption-display preference (#3883). Device-local like
  /// the theme choice, so it lives in SharedPreferences and is readable
  /// before any Hive box opens.
  ConsumptionDisplaySettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consumptionDisplaySettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consumptionDisplaySettingHash();

  @$internal
  @override
  ConsumptionDisplaySetting create() => ConsumptionDisplaySetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsumptionDisplay value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsumptionDisplay>(value),
    );
  }
}

String _$consumptionDisplaySettingHash() =>
    r'cd36dde74622de153786d55b41eb6a1402062eb4';

/// Persisted consumption-display preference (#3883). Device-local like
/// the theme choice, so it lives in SharedPreferences and is readable
/// before any Hive box opens.

abstract class _$ConsumptionDisplaySetting
    extends $Notifier<ConsumptionDisplay> {
  ConsumptionDisplay build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConsumptionDisplay, ConsumptionDisplay>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConsumptionDisplay, ConsumptionDisplay>,
              ConsumptionDisplay,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
