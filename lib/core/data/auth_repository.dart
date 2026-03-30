/// Abstract interface for authentication.
///
/// ## Reusability
/// Decouples auth from Supabase. Implementations can use
/// Firebase Auth, custom JWT, or any auth provider.
///
/// ## Security
/// Passwords are never stored or logged. Only the resulting
/// user ID and session token are persisted via StorageRepository.
abstract class AuthRepository {
  /// Initialize the auth backend with URL and credentials.
  Future<void> init({required String url, required String anonKey});

  /// Whether the auth backend is initialized and a session exists.
  bool get isConnected;

  /// Sign in anonymously (UUID-only, no email).
  Future<String?> signInAnonymously();

  /// Sign up with email and password.
  Future<String?> signUpWithEmail(String email, String password);

  /// Sign in with existing email account.
  Future<String?> signInWithEmail(String email, String password);

  /// Sign out and clear the session.
  Future<void> signOut();

  /// Current user's email (null for anonymous).
  String? get currentEmail;

  /// Whether the current user has an email account.
  bool get hasEmailAccount;
}
