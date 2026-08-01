// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The error-handling boilerplate this codebase repeats at ~630 call
/// sites, collapsed into four helpers.
///
/// ## Why this file exists
///
/// A duplication scan of `lib/` (excluding generated code) found the
/// same six-line block in **26 files**:
///
/// ```dart
/// } catch (e, st) {
///   unawaited(
///     errorLogger.log(
///       ErrorLayer.ui,
///       e,
///       st,
///       context: const {'where': 'SomeScreen: something failed'},
///     ),
///   );
///   if (messenger == null) return;
///   messenger.showSnackBar(SnackBarHelper.errorSnackBar(scheme, errorMsg));
/// }
/// ```
///
/// Seven lines of ceremony around one fact. Worse, the ceremony is
/// where the bugs live: a forgotten `unawaited` trips
/// `discarded_futures`, a forgotten `, st` trips `catch_no_st`, a
/// forgotten `context.mounted` check throws on an unmounted widget,
/// and a caller that ignores the failure falls straight through into
/// the success path.
///
/// Making the correct path the *shortest* path is the only reliable fix
/// — a rule that costs ten lines to obey will be disobeyed. Each helper
/// below folds the required behaviour in so no call site can omit it:
///
/// | Helper            | Shape it replaces                                 |
/// |-------------------|---------------------------------------------------|
/// | [logFailure]      | `unawaited(errorLogger.log(layer, e, st, …))`      |
/// | [guard]           | sync read that must not fail the build             |
/// | [guardAsync]      | async read with a fallback value                   |
/// | [runGuarded]      | async mutation + optional error snackbar           |
///
/// ## Contract
///
/// Every helper here **never throws**. They are called from `catch`
/// blocks and from `build()`; a helper that throws would replace a
/// recoverable error with an unrecoverable one at exactly the moment
/// the system is already degraded. Fault-injection coverage lives in
/// `test/core/error/guarded_test.dart`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../logging/error_logger.dart';
import '../widgets/snackbar_helper.dart';

/// Log [error] under [layer], tagged with [where], without awaiting.
///
/// The one-line replacement for the seven-line
/// `unawaited(errorLogger.log(...))` block. [where] is the free-text
/// locator that ends up in the trace's `context` map — use the same
/// `'ClassName: what failed'` convention the codebase already uses.
///
/// Pass [extra] for additional context entries; they are merged after
/// `where`, so a caller may not accidentally overwrite it.
///
/// Never throws.
void logFailure(
  Object error,
  StackTrace stack, {
  required String where,
  ErrorLayer layer = ErrorLayer.ui,
  Map<String, Object?>? extra,
}) {
  try {
    unawaited(
      errorLogger.log(
        layer,
        error,
        stack,
        context: {...?extra, 'where': where},
      ),
    );
  } catch (e, st) {
    // The logger already promises never to throw; this guard exists so
    // that a future change to it cannot derail a catch block.
    debugPrint('logFailure($where) itself failed: $e\n$st');
  }
}

/// Run a synchronous [action], returning [fallback] if it throws.
///
/// Replaces the defensive-lookup shape used throughout `build()`
/// methods, where a provider read may throw in an isolated widget test
/// that has not wired storage and the widget should degrade rather than
/// take the screen down:
///
/// ```dart
/// final profile = guard(
///   () => ref.watch(vehicleProfileListProvider).firstWhere((v) => v.id == id),
///   where: 'AutoRecordSection: profile lookup failed',
///   fallback: const VehicleProfile(id: '', name: ''),
/// );
/// ```
///
/// Never throws.
T guard<T>(
  T Function() action, {
  required String where,
  required T fallback,
  ErrorLayer layer = ErrorLayer.ui,
}) {
  try {
    return action();
  } catch (e, st) {
    logFailure(e, st, where: where, layer: layer);
    return fallback;
  }
}

/// Await [action], returning [fallback] if it throws.
///
/// The asynchronous sibling of [guard], for a read whose failure must
/// not propagate — a cache probe, an optional enrichment, a
/// best-effort platform call.
///
/// Never throws.
Future<T> guardAsync<T>(
  Future<T> Function() action, {
  required String where,
  required T fallback,
  ErrorLayer layer = ErrorLayer.ui,
}) async {
  try {
    return await action();
  } catch (e, st) {
    logFailure(e, st, where: where, layer: layer);
    return fallback;
  }
}

/// Run a mutating [action], logging any failure and — when [errorText]
/// is given and [context] is still mounted — surfacing it as an error
/// snackbar. Returns whether the action succeeded.
///
/// ```dart
/// if (!await runGuarded(
///   context,
///   where: 'FavoritesScreen: share image',
///   errorText: l10n.favoritesShareError,
///   action: () => shareService.shareImage(bytes),
/// )) {
///   return;
/// }
/// ```
///
/// Three properties fall out of putting this in one place, each of
/// which was individually forgotten at some call site:
///
/// * the `context.mounted` check cannot be skipped;
/// * [where] is required, so no trace lands untagged;
/// * the boolean return makes "the mutation failed" impossible to fall
///   through — the pattern that produced silent no-ops.
///
/// The snackbar is read *before* the await where possible — pass an
/// already-resolved [errorText] rather than a closure over
/// `AppLocalizations.of(context)`, so a widget unmounted during the
/// await cannot trigger a lookup on a dead element.
///
/// Never throws.
Future<bool> runGuarded(
  BuildContext? context, {
  required String where,
  required Future<void> Function() action,
  String? errorText,
  ErrorLayer layer = ErrorLayer.ui,
}) async {
  try {
    await action();
    return true;
  } catch (e, st) {
    logFailure(e, st, where: where, layer: layer);
    if (errorText != null && context != null && context.mounted) {
      // `maybeOf`, NOT `SnackBarHelper.showError`: showError resolves the
      // messenger with `ScaffoldMessenger.of`, which THROWS when the
      // context has no messenger ancestor (a bare test pump, a dialog
      // route above the app scaffold) — and a throw out of this catch
      // block would break the never-throws contract at exactly the
      // moment the caller is relying on it. No messenger → no toast,
      // but the failure is already traced and the caller still gets
      // `false`.
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBarHelper.errorSnackBar(Theme.of(context).colorScheme, errorText),
      );
    }
    return false;
  }
}
