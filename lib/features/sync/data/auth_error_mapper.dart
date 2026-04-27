import '../../../l10n/app_localizations.dart';

/// Maps a raw auth-failure exception to a localized, user-facing
/// message. Replaces the inline `e.toString()` paths in
/// `auth_screen.dart` (#1186) which were leaking
/// `AuthRetryableFetchException(...)` and the hardcoded Supabase URL
/// straight into the error pill.
///
/// Pure function — no Riverpod, no I/O. The full exception is still
/// expected to be logged by the caller via `errorLogger.log` for
/// diagnostics; only the user-facing string is sanitized here.
String friendlyAuthError(Object error, AppLocalizations? l) {
  final raw = error.toString();

  // Network family: DNS NXDOMAIN, dropped sockets, retryable fetch.
  // The supabase_flutter client wraps these in AuthRetryableFetchException
  // with a SocketException inside. Match on the substrings the user
  // would otherwise see — same approach as the existing email-error
  // mapping but for the connectivity surface the bug report flagged.
  if (raw.contains('SocketException') ||
      raw.contains('AuthRetryableFetchException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('errno = 7') ||
      raw.contains('Network is unreachable') ||
      raw.contains('Connection refused')) {
    return l?.authErrorNoNetwork ??
        'No network connection. Try again later.';
  }

  // Supabase auth-specific error codes surfaced through AuthException.
  if (raw.contains('invalid_credentials')) {
    return l?.authErrorInvalidCredentials ??
        'Invalid email or password. Check your credentials.';
  }
  if (raw.contains('user_already_exists') ||
      raw.contains('already registered')) {
    return l?.authErrorUserAlreadyExists ??
        'This email is already registered. Try signing in instead.';
  }
  if (raw.contains('email_not_confirmed')) {
    return l?.authErrorEmailNotConfirmed ??
        'Please check your email and confirm your account first.';
  }

  return l?.authErrorGeneric ?? 'Sign-in failed. Please try again.';
}
