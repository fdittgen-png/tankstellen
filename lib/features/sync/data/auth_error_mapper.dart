import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/error_logger.dart';
import '../../../l10n/app_localizations.dart';

/// Maps a raw [error] thrown from a Supabase / network auth call into a
/// localized, user-safe message suitable for the auth-screen error pill.
///
/// Why this exists (#1186):
///   The auth screen previously called `_formNotifier.setError(e.toString())`
///   in every catch block. For a `gotrue` retryable fetch failure that
///   produces a string like
///   `AuthRetryableFetchException: ClientException: ... uri=https://klelxnkzrxlpzuddhpfg.supabase.co/...`
///   — leaking the project URL into the UI and confronting the user with
///   exception type names. This function classifies the error first by
///   runtime type (network / DNS / Supabase auth), then by substring on
///   the message for the well-known Supabase error codes
///   (`invalid_credentials`, `user_already_exists`, `email_not_confirmed`),
///   and falls back to a generic "Something went wrong" string.
///
/// The original error (and stack trace, if available) is always logged
/// via [errorLogger] so observability is preserved — only the *display*
/// is sanitized. Callers should pass `stackTrace` when they have one.
///
/// The function is pure with respect to its non-logging output: given the
/// same `error` and `l10n`, it returns the same string. This makes the
/// mapper trivially unit-testable without a Riverpod or widget harness.
String mapAuthErrorToLocalized(
  Object error,
  AppLocalizations l10n, {
  StackTrace? stackTrace,
}) {
  // Always log the original error — observability must outlive the
  // friendly translation. Fire-and-forget; ErrorLogger.log is documented
  // as never-throwing.
  // ignore: discarded_futures
  errorLogger.log(
    ErrorLayer.sync,
    error,
    stackTrace,
    context: <String, Object?>{'phase': 'auth'},
  );

  // 1. Network / DNS classes — show "no network" before drilling into
  //    Supabase-specific messages. AuthRetryableFetchException is the
  //    common gotrue wrapper for "could not reach the server", so it
  //    belongs in this bucket rather than "generic".
  if (error is SocketException ||
      error is http.ClientException ||
      error is AuthRetryableFetchException) {
    return l10n.authErrorNoNetwork;
  }

  // OS errno=7 (`No address associated with hostname` on Android) bubbles
  // up wrapped in different exception types depending on the http stack.
  // A substring match on the error's `toString()` catches the cases we
  // do not classify by runtime type above.
  final message = error.toString();
  if (message.contains('errno = 7') ||
      message.contains('Failed host lookup') ||
      message.contains('SocketException') ||
      message.contains('Network is unreachable') ||
      message.contains('ClientException')) {
    return l10n.authErrorNoNetwork;
  }

  // 2. Supabase-known auth error codes — substring match on the message
  //    field of the AuthException (or the toString if a non-typed error
  //    leaked through).
  if (message.contains('invalid_credentials') ||
      message.contains('Invalid login credentials')) {
    return l10n.authErrorInvalidCredentials;
  }
  if (message.contains('user_already_exists') ||
      message.contains('already registered') ||
      message.contains('User already registered')) {
    return l10n.authErrorUserAlreadyExists;
  }
  if (message.contains('email_not_confirmed') ||
      message.contains('Email not confirmed')) {
    return l10n.authErrorEmailNotConfirmed;
  }

  // 3. Default — never expose `toString()` to the user.
  return l10n.authErrorGeneric;
}
