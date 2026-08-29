// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'app_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the Tankerkoenig (DE) API key is configured.
///
/// #3746 — API keys are per-country now; this app-level provider keeps
/// its historical meaning (the DE Tankerkönig key that gates setup /
/// demo mode) by reading the 'de' slot explicitly.

@ProviderFor(hasApiKey)
final hasApiKeyProvider = HasApiKeyProvider._();

/// Whether the Tankerkoenig (DE) API key is configured.
///
/// #3746 — API keys are per-country now; this app-level provider keeps
/// its historical meaning (the DE Tankerkönig key that gates setup /
/// demo mode) by reading the 'de' slot explicitly.

final class HasApiKeyProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the Tankerkoenig (DE) API key is configured.
  ///
  /// #3746 — API keys are per-country now; this app-level provider keeps
  /// its historical meaning (the DE Tankerkönig key that gates setup /
  /// demo mode) by reading the 'de' slot explicitly.
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

String _$hasApiKeyHash() => r'53fab8dc64c7307ace922e4d6e33e5b6a668a379';

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

String _$hasCustomApiKeyHash() => r'5508011b0f42596dd0b335306f1b45851fce8914';

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

String _$isDemoModeHash() => r'951153908f7b04b2262cf54193b5123ddd510dd1';

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

/// In-app OBD2 fuel-rate diagnostic overlay flag (#1395).
///
/// `kDebugMode` always shows the overlay; this Hive-backed flag flips
/// it on for release builds when the user enables it via the hidden
/// 5-tap gesture on the trip-recording screen title. Persisted so the
/// overlay stays visible across launches once the user has opted in.

@ProviderFor(Obd2DebugOverlay)
final obd2DebugOverlayProvider = Obd2DebugOverlayProvider._();

/// In-app OBD2 fuel-rate diagnostic overlay flag (#1395).
///
/// `kDebugMode` always shows the overlay; this Hive-backed flag flips
/// it on for release builds when the user enables it via the hidden
/// 5-tap gesture on the trip-recording screen title. Persisted so the
/// overlay stays visible across launches once the user has opted in.
final class Obd2DebugOverlayProvider
    extends $NotifierProvider<Obd2DebugOverlay, bool> {
  /// In-app OBD2 fuel-rate diagnostic overlay flag (#1395).
  ///
  /// `kDebugMode` always shows the overlay; this Hive-backed flag flips
  /// it on for release builds when the user enables it via the hidden
  /// 5-tap gesture on the trip-recording screen title. Persisted so the
  /// overlay stays visible across launches once the user has opted in.
  Obd2DebugOverlayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2DebugOverlayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2DebugOverlayHash();

  @$internal
  @override
  Obd2DebugOverlay create() => Obd2DebugOverlay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$obd2DebugOverlayHash() => r'47e78a455f432ced81b0204c4077f074edb9817a';

/// In-app OBD2 fuel-rate diagnostic overlay flag (#1395).
///
/// `kDebugMode` always shows the overlay; this Hive-backed flag flips
/// it on for release builds when the user enables it via the hidden
/// 5-tap gesture on the trip-recording screen title. Persisted so the
/// overlay stays visible across launches once the user has opted in.

abstract class _$Obd2DebugOverlay extends $Notifier<bool> {
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

String _$autoSwitchProfileHash() => r'59a8d30ec90be2598bebfdfe12081ff0665be4f6';

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

/// Whether GDPR consent has been given against the CURRENT policy
/// version (#3866 — a policy bump re-surfaces the consent screen once).

@ProviderFor(hasGdprConsent)
final hasGdprConsentProvider = HasGdprConsentProvider._();

/// Whether GDPR consent has been given against the CURRENT policy
/// version (#3866 — a policy bump re-surfaces the consent screen once).

final class HasGdprConsentProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether GDPR consent has been given against the CURRENT policy
  /// version (#3866 — a policy bump re-surfaces the consent screen once).
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

String _$hasGdprConsentHash() => r'629f99cb27b36f919e214dd1e6800c6a23319641';

/// GDPR consent state: location, error reporting, cloud sync,
/// community wait-time pings (#1119), VIN online decode (#1399),
/// trip-sync to TankSync (#1479 phase 1).

@ProviderFor(GdprConsent)
final gdprConsentProvider = GdprConsentProvider._();

/// GDPR consent state: location, error reporting, cloud sync,
/// community wait-time pings (#1119), VIN online decode (#1399),
/// trip-sync to TankSync (#1479 phase 1).
final class GdprConsentProvider
    extends
        $NotifierProvider<
          GdprConsent,
          ({
            bool cloudSync,
            bool errorReporting,
            bool location,
            int policyVersion,
            DateTime? recordedAt,
            bool syncTrips,
            bool vinOnlineDecode,
          })
        > {
  /// GDPR consent state: location, error reporting, cloud sync,
  /// community wait-time pings (#1119), VIN online decode (#1399),
  /// trip-sync to TankSync (#1479 phase 1).
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
      bool errorReporting,
      bool location,
      int policyVersion,
      DateTime? recordedAt,
      bool syncTrips,
      bool vinOnlineDecode,
    })
    value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({
              bool cloudSync,
              bool errorReporting,
              bool location,
              int policyVersion,
              DateTime? recordedAt,
              bool syncTrips,
              bool vinOnlineDecode,
            })
          >(value),
    );
  }
}

String _$gdprConsentHash() => r'9c17016c37b961bb52f51bdbca6c5a286c0ad8b3';

/// GDPR consent state: location, error reporting, cloud sync,
/// community wait-time pings (#1119), VIN online decode (#1399),
/// trip-sync to TankSync (#1479 phase 1).

abstract class _$GdprConsent
    extends
        $Notifier<
          ({
            bool cloudSync,
            bool errorReporting,
            bool location,
            int policyVersion,
            DateTime? recordedAt,
            bool syncTrips,
            bool vinOnlineDecode,
          })
        > {
  ({
    bool cloudSync,
    bool errorReporting,
    bool location,
    int policyVersion,
    DateTime? recordedAt,
    bool syncTrips,
    bool vinOnlineDecode,
  })
  build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({
                bool cloudSync,
                bool errorReporting,
                bool location,
                int policyVersion,
                DateTime? recordedAt,
                bool syncTrips,
                bool vinOnlineDecode,
              }),
              ({
                bool cloudSync,
                bool errorReporting,
                bool location,
                int policyVersion,
                DateTime? recordedAt,
                bool syncTrips,
                bool vinOnlineDecode,
              })
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({
                  bool cloudSync,
                  bool errorReporting,
                  bool location,
                  int policyVersion,
                  DateTime? recordedAt,
                  bool syncTrips,
                  bool vinOnlineDecode,
                }),
                ({
                  bool cloudSync,
                  bool errorReporting,
                  bool location,
                  int policyVersion,
                  DateTime? recordedAt,
                  bool syncTrips,
                  bool vinOnlineDecode,
                })
              >,
              ({
                bool cloudSync,
                bool errorReporting,
                bool location,
                int policyVersion,
                DateTime? recordedAt,
                bool syncTrips,
                bool vinOnlineDecode,
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

String _$storageStatsHash() => r'2d452fed9014e4011428af10cb6a83ea1f353851';
