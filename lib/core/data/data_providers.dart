import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_repository.dart';
import 'impl/supabase_auth_repository.dart';
import 'impl/supabase_sync_repository.dart';
import 'sync_repository.dart';

part 'data_providers.g.dart';

/// Provides the sync repository implementation.
///
/// Override this in tests with a mock:
/// ```dart
/// syncRepositoryProvider.overrideWithValue(MockSyncRepository())
/// ```
///
/// To switch from Supabase to another backend (Firebase, custom):
/// replace SupabaseSyncRepository with your implementation.
@Riverpod(keepAlive: true)
SyncRepository syncRepository(SyncRepositoryRef ref) {
  return SupabaseSyncRepository();
}

/// Provides the auth repository implementation.
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return SupabaseAuthRepository();
}
