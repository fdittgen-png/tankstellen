import '../../sync/supabase_client.dart';
import '../auth_repository.dart';

/// Supabase implementation of [AuthRepository].
///
/// Delegates to [TankSyncClient] for all auth operations.
/// This wrapper enables swapping to Firebase Auth, custom JWT,
/// or any other auth provider without changing app code.
class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<void> init({required String url, required String anonKey}) =>
      TankSyncClient.init(url: url, anonKey: anonKey);

  @override
  bool get isConnected => TankSyncClient.isConnected;

  @override
  Future<String?> signInAnonymously() => TankSyncClient.signInAnonymously();

  @override
  Future<String?> signUpWithEmail(String email, String password) =>
      TankSyncClient.signUpWithEmail(email, password);

  @override
  Future<String?> signInWithEmail(String email, String password) =>
      TankSyncClient.signInWithEmail(email, password);

  @override
  Future<void> signOut() => TankSyncClient.signOut();

  @override
  String? get currentEmail => TankSyncClient.currentEmail;

  @override
  bool get hasEmailAccount => TankSyncClient.hasEmailAccount;
}
