// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the cloud sync connection state.
///
/// ## Reusability
/// This provider is app-agnostic. It manages Supabase connection lifecycle
/// and persists credentials to Hive. The sync mode (community/private/join)
/// is a UI concept stored alongside the credentials.
///
/// Any app can use this by:
/// 1. Providing its own `CommunityConfig` (or skipping community mode)
/// 2. Calling `connect()` with URL + key
/// 3. Reading `syncStateProvider` to check connection status

@ProviderFor(SyncState)
final syncStateProvider = SyncStateProvider._();

/// Manages the cloud sync connection state.
///
/// ## Reusability
/// This provider is app-agnostic. It manages Supabase connection lifecycle
/// and persists credentials to Hive. The sync mode (community/private/join)
/// is a UI concept stored alongside the credentials.
///
/// Any app can use this by:
/// 1. Providing its own `CommunityConfig` (or skipping community mode)
/// 2. Calling `connect()` with URL + key
/// 3. Reading `syncStateProvider` to check connection status
final class SyncStateProvider extends $NotifierProvider<SyncState, SyncConfig> {
  /// Manages the cloud sync connection state.
  ///
  /// ## Reusability
  /// This provider is app-agnostic. It manages Supabase connection lifecycle
  /// and persists credentials to Hive. The sync mode (community/private/join)
  /// is a UI concept stored alongside the credentials.
  ///
  /// Any app can use this by:
  /// 1. Providing its own `CommunityConfig` (or skipping community mode)
  /// 2. Calling `connect()` with URL + key
  /// 3. Reading `syncStateProvider` to check connection status
  SyncStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStateHash();

  @$internal
  @override
  SyncState create() => SyncState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncConfig>(value),
    );
  }
}

String _$syncStateHash() => r'5e4b05167e93e50daff104b9216da4426205ae22';

/// Manages the cloud sync connection state.
///
/// ## Reusability
/// This provider is app-agnostic. It manages Supabase connection lifecycle
/// and persists credentials to Hive. The sync mode (community/private/join)
/// is a UI concept stored alongside the credentials.
///
/// Any app can use this by:
/// 1. Providing its own `CommunityConfig` (or skipping community mode)
/// 2. Calling `connect()` with URL + key
/// 3. Reading `syncStateProvider` to check connection status

abstract class _$SyncState extends $Notifier<SyncConfig> {
  SyncConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SyncConfig, SyncConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncConfig, SyncConfig>,
              SyncConfig,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
