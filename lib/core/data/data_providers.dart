import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_repository.dart';
import 'impl/supabase_auth_repository.dart';
import 'impl/supabase_sync_repository.dart';
import 'sync_repository.dart';

part 'data_providers.g.dart';

/// Provides the sync repository implementation.
@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) {
  return SupabaseSyncRepository();
}

/// Provides the auth repository implementation.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository();
}
