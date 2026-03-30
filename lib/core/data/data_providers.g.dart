// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the sync repository implementation.
///
/// Override this in tests with a mock:
/// ```dart
/// syncRepositoryProvider.overrideWithValue(MockSyncRepository())
/// ```
///
/// To switch from Supabase to another backend (Firebase, custom):
/// replace SupabaseSyncRepository with your implementation.

@ProviderFor(syncRepository)
final syncRepositoryProvider = SyncRepositoryProvider._();

/// Provides the sync repository implementation.
///
/// Override this in tests with a mock:
/// ```dart
/// syncRepositoryProvider.overrideWithValue(MockSyncRepository())
/// ```
///
/// To switch from Supabase to another backend (Firebase, custom):
/// replace SupabaseSyncRepository with your implementation.

final class SyncRepositoryProvider
    extends $FunctionalProvider<SyncRepository, SyncRepository, SyncRepository>
    with $Provider<SyncRepository> {
  /// Provides the sync repository implementation.
  ///
  /// Override this in tests with a mock:
  /// ```dart
  /// syncRepositoryProvider.overrideWithValue(MockSyncRepository())
  /// ```
  ///
  /// To switch from Supabase to another backend (Firebase, custom):
  /// replace SupabaseSyncRepository with your implementation.
  SyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncRepository create(Ref ref) {
    return syncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRepository>(value),
    );
  }
}

String _$syncRepositoryHash() => r'59ffee9d75da3f3f6f7d0d148bbce2cc5b5367b2';

/// Provides the auth repository implementation.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Provides the auth repository implementation.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Provides the auth repository implementation.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'ae2a9c7c4226836cd659c3ec8f6f8a02a8913d3b';
