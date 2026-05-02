// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the Tankerkoenig API key is configured.
///
/// Since #521 this is always true — the app ships a community
/// default. Use [hasCustomApiKey] to tell whether the user set their
/// own key.

@ProviderFor(hasApiKey)
final hasApiKeyProvider = HasApiKeyProvider._();

/// Whether the Tankerkoenig API key is configured.
///
/// Since #521 this is always true — the app ships a community
/// default. Use [hasCustomApiKey] to tell whether the user set their
/// own key.

final class HasApiKeyProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the Tankerkoenig API key is configured.
  ///
  /// Since #521 this is always true — the app ships a community
  /// default. Use [hasCustomApiKey] to tell whether the user set their
  /// own key.
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

String _$hasApiKeyHash() => r'9927ae0b513afe69898707f03a015b769948e062';

/// Whether the user has set their **own** Tankerkoenig key, distinct
/// from the community default bundled in the app (#521).

@ProviderFor(hasCustomApiKey)
final hasCustomApiKeyProvider = HasCustomApiKeyProvider._();

/// Whether the user has set their **own** Tankerkoenig key, distinct
/// from the community default bundled in the app (#521).

final class HasCustomApiKeyProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the user has set their **own** Tankerkoenig key, distinct
  /// from the community default bundled in the app (#521).
  HasCustomApiKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasCustomApiKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasCustomApiKeyHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasCustomApiKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasCustomApiKeyHash() => r'c1825c86532b5661179d05a09d9a079cc6d6abc0';

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

String _$hasCustomEvApiKeyHash() => r'5b58e9c3a30dbd76727b5e940c51c57c76a5e93a';

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

String _$isSetupCompleteHash() => r'ed2c5f5152a724dd00ef88c3070746e00f19d7e3';

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

String _$isDemoModeHash() => r'36e1fc7f0ba8650fba7bfb3eab5cb284ab5a90f7';

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
    r'a6178ce1dcc1a981a60588415802c2c19301ce89';

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

String _$locationConsentHash() => r'4c60c0829286038445f3fdc8e3417943823b2d51';

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

String _$autoSwitchProfileHash() => r'd9ca4989633b5d2e0734810d113d179a8493523f';

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

/// Whether GDPR consent has been given (any choices made).

@ProviderFor(hasGdprConsent)
final hasGdprConsentProvider = HasGdprConsentProvider._();

/// Whether GDPR consent has been given (any choices made).

final class HasGdprConsentProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether GDPR consent has been given (any choices made).
  HasGdprConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasGdprConsentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasGdprConsentHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasGdprConsent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasGdprConsentHash() => r'712d0d516ea832af3bc75b97776e595ce699d2dc';

/// GDPR consent state: location, error reporting, cloud sync,
/// community wait-time pings (#1119).

@ProviderFor(GdprConsent)
final gdprConsentProvider = GdprConsentProvider._();

/// GDPR consent state: location, error reporting, cloud sync,
/// community wait-time pings (#1119).
final class GdprConsentProvider
    extends
        $NotifierProvider<
          GdprConsent,
          ({
            bool cloudSync,
            bool communityWaitTime,
            bool errorReporting,
            bool location,
          })
        > {
  /// GDPR consent state: location, error reporting, cloud sync,
  /// community wait-time pings (#1119).
  GdprConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gdprConsentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gdprConsentHash();

  @$internal
  @override
  GdprConsent create() => GdprConsent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({
      bool cloudSync,
      bool communityWaitTime,
      bool errorReporting,
      bool location,
    })
    value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({
              bool cloudSync,
              bool communityWaitTime,
              bool errorReporting,
              bool location,
            })
          >(value),
    );
  }
}

String _$gdprConsentHash() => r'e08e226d7aea82864ce1a8371d949f92be135975';

/// GDPR consent state: location, error reporting, cloud sync,
/// community wait-time pings (#1119).

abstract class _$GdprConsent
    extends
        $Notifier<
          ({
            bool cloudSync,
            bool communityWaitTime,
            bool errorReporting,
            bool location,
          })
        > {
  ({bool cloudSync, bool communityWaitTime, bool errorReporting, bool location})
  build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({
                bool cloudSync,
                bool communityWaitTime,
                bool errorReporting,
                bool location,
              }),
              ({
                bool cloudSync,
                bool communityWaitTime,
                bool errorReporting,
                bool location,
              })
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({
                  bool cloudSync,
                  bool communityWaitTime,
                  bool errorReporting,
                  bool location,
                }),
                ({
                  bool cloudSync,
                  bool communityWaitTime,
                  bool errorReporting,
                  bool location,
                })
              >,
              ({
                bool cloudSync,
                bool communityWaitTime,
                bool errorReporting,
                bool location,
              }),
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

String _$storageStatsHash() => r'0bd96d7fdac0c73e4cb62e88007daea25f2c0c94';
