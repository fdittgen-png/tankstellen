// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the Tankerkoenig API key is configured.

@ProviderFor(hasApiKey)
final hasApiKeyProvider = HasApiKeyProvider._();

/// Whether the Tankerkoenig API key is configured.

final class HasApiKeyProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the Tankerkoenig API key is configured.
  HasApiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasApiKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasApiKeyHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasApiKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasApiKeyHash() => r'6ba26caa7bf1dff6250a00525aa89c809746261a';

/// Whether a custom EV API key is configured.

@ProviderFor(hasCustomEvApiKey)
final hasCustomEvApiKeyProvider = HasCustomEvApiKeyProvider._();

/// Whether a custom EV API key is configured.

final class HasCustomEvApiKeyProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a custom EV API key is configured.
  HasCustomEvApiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasCustomEvApiKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasCustomEvApiKeyHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasCustomEvApiKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasCustomEvApiKeyHash() => r'faa5e8b46e227a417ff7f77dedc493e20a24e1a8';

/// Whether the app setup (API key or skip) is complete.

@ProviderFor(isSetupComplete)
final isSetupCompleteProvider = IsSetupCompleteProvider._();

/// Whether the app setup (API key or skip) is complete.

final class IsSetupCompleteProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the app setup (API key or skip) is complete.
  IsSetupCompleteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isSetupCompleteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isSetupCompleteHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isSetupComplete(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isSetupCompleteHash() => r'fb0038e02bad17d5f9836dd6cf57c9e564523ac5';

/// Whether the app is in demo mode (setup skipped, no API key).

@ProviderFor(isDemoMode)
final isDemoModeProvider = IsDemoModeProvider._();

/// Whether the app is in demo mode (setup skipped, no API key).

final class IsDemoModeProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the app is in demo mode (setup skipped, no API key).
  IsDemoModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isDemoModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isDemoModeHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isDemoMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isDemoModeHash() => r'30ebd662324ba53ee87c57d135bd2282ae14cc08';

/// Whether location consent has been given.

@ProviderFor(hasLocationConsent)
final hasLocationConsentProvider = HasLocationConsentProvider._();

/// Whether location consent has been given.

final class HasLocationConsentProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether location consent has been given.
  HasLocationConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasLocationConsentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasLocationConsentHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasLocationConsent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasLocationConsentHash() =>
    r'2ba6bd77ff5b05913c3904a4550165740a60731e';

/// Record location consent.

@ProviderFor(LocationConsent)
final locationConsentProvider = LocationConsentProvider._();

/// Record location consent.
final class LocationConsentProvider
    extends $NotifierProvider<LocationConsent, bool> {
  /// Record location consent.
  LocationConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationConsentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationConsentHash();

  @$internal
  @override
  LocationConsent create() => LocationConsent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$locationConsentHash() => r'bf7800cc44bf31cc8690f86647211ad4861f1b2b';

/// Record location consent.

abstract class _$LocationConsent extends $Notifier<bool> {
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

/// Auto-switch profile setting.

@ProviderFor(AutoSwitchProfile)
final autoSwitchProfileProvider = AutoSwitchProfileProvider._();

/// Auto-switch profile setting.
final class AutoSwitchProfileProvider
    extends $NotifierProvider<AutoSwitchProfile, bool> {
  /// Auto-switch profile setting.
  AutoSwitchProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoSwitchProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoSwitchProfileHash();

  @$internal
  @override
  AutoSwitchProfile create() => AutoSwitchProfile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$autoSwitchProfileHash() => r'ea721a5762558ca12b20d343e87401241d7072cd';

/// Auto-switch profile setting.

abstract class _$AutoSwitchProfile extends $Notifier<bool> {
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

/// Aggregated storage stats — used by config verification and storage section.

@ProviderFor(storageStats)
final storageStatsProvider = StorageStatsProvider._();

/// Aggregated storage stats — used by config verification and storage section.

final class StorageStatsProvider
    extends $FunctionalProvider<StorageStats, StorageStats, StorageStats>
    with $Provider<StorageStats> {
  /// Aggregated storage stats — used by config verification and storage section.
  StorageStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageStatsHash();

  @$internal
  @override
  $ProviderElement<StorageStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageStats create(Ref ref) {
    return storageStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageStats>(value),
    );
  }
}

String _$storageStatsHash() => r'91eca83a16b105fe7bfb91f0ab4d43bed045ca12';
