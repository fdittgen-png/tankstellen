// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/error_logger.dart';

/// Clipboard writes for SENSITIVE payloads (IBAN + beneficiary from a
/// scanned Girocode, the privacy-dashboard / error-log JSON exports)
/// with automatic hygiene (#3611): [copy] behaves exactly like
/// `Clipboard.setData`, then schedules a one-shot clear [clearDelay]
/// (60 s) later so the payload does not linger for every other app's
/// clipboard listener.
///
/// ## Clear policy
/// Before clearing, the pending timer reads the clipboard back:
/// - clipboard still holds OUR text → cleared (empty string written);
/// - the user has since copied something else → left untouched;
/// - the read fails or returns nothing (Android 10+ restricts clipboard
///   reads to the foregrounded app, and some OEM clipboard managers
///   throw on the platform channel) → cleared **unconditionally**: a
///   spuriously emptied clipboard is a nuisance, a lingering IBAN is a
///   leak.
///
/// Only the LATEST copy is tracked — a newer [copy] cancels the
/// previous pending clear (the older payload was already overwritten
/// on the platform clipboard by the newer write).
class SensitiveClipboard {
  SensitiveClipboard._();

  /// How long the sensitive payload may stay on the clipboard.
  static const Duration clearDelay = Duration(seconds: 60);

  /// Test seam for `Clipboard.setData`.
  @visibleForTesting
  static Future<void> Function(ClipboardData data) writer = _defaultWriter;

  /// Test seam for `Clipboard.getData`.
  @visibleForTesting
  static Future<ClipboardData?> Function() reader = _defaultReader;

  static Timer? _pendingClear;

  static Future<void> _defaultWriter(ClipboardData data) =>
      Clipboard.setData(data);

  static Future<ClipboardData?> _defaultReader() =>
      Clipboard.getData(Clipboard.kTextPlain);

  /// Reset the seams and cancel any pending clear. Call from `tearDown`.
  @visibleForTesting
  static void resetForTesting() {
    writer = _defaultWriter;
    reader = _defaultReader;
    _pendingClear?.cancel();
    _pendingClear = null;
  }

  /// Whether a clear is currently scheduled (test observability).
  @visibleForTesting
  static bool get hasPendingClear => _pendingClear?.isActive ?? false;

  /// Copies [text] to the system clipboard and schedules the hygiene
  /// clear. The write itself surfaces failures to the caller exactly
  /// like a raw `Clipboard.setData` (call sites keep their existing
  /// error handling); only the deferred clear is fire-and-forget.
  static Future<void> copy(String text) async {
    await writer(ClipboardData(text: text));
    _pendingClear?.cancel();
    _pendingClear = Timer(clearDelay, () {
      unawaited(_clearIfStillOurs(text));
    });
  }

  /// Clears the clipboard when it still holds [copied] (or when that
  /// cannot be determined — see the class doc's clear policy).
  ///
  /// Never throws: the clear runs from a timer with no user waiting on
  /// it, so every failure is logged and swallowed.
  static Future<void> _clearIfStillOurs(String copied) async {
    try {
      var stillOurs = true;
      try {
        final current = await reader();
        // A readable clipboard that holds someone else's content is the
        // ONLY case where we stand down; `null` (unreadable / emptied
        // by the platform) falls through to the unconditional clear.
        if (current?.text != null && current!.text != copied) {
          stillOurs = false;
        }
      } catch (e, st) {
        // Read failed (backgrounded app, OEM platform-channel quirk) —
        // note it and clear unconditionally, per the class contract.
        unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
          'where': 'SensitiveClipboard: read-back failed, clearing anyway',
        }));
      }
      if (stillOurs) {
        await writer(const ClipboardData(text: ''));
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'SensitiveClipboard: deferred clear failed',
      }));
    }
  }
}
