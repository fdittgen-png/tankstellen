// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/receipt_parser.dart';

part 'pending_shared_receipt_text_provider.g.dart';

/// One-shot stash for the [ReceiptParseResult] of an e-receipt **text** an
/// external app shared into Sparkilo (#2735 + #2838 / Epic #2687).
///
/// The text sibling of [pendingSharedReceiptProvider]. An image / PDF share
/// stashes a file PATH that the Add-fill-up screen OCRs on open; a shared
/// text body, by contrast, is parsed by the pure-Dart [EReceiptTextParser]
/// in the share handler at receive time — there is no file to OCR — so the
/// already-parsed result is what gets stashed here. The Add-fill-up screen
/// consumes it on open and prefills the form through the SAME
/// `applyReceiptOutcome` body the camera / image-share paths use, so a text
/// receipt fills the form with zero prefill drift.
///
/// **Lifecycle** mirrors the path stash: `set(result)` writes;
/// `consumeDeferred()` returns the value and clears via a microtask so it is
/// safe to call from the screen's `initState` (a Riverpod-locked phase).
@Riverpod(keepAlive: true)
class PendingSharedReceiptText extends _$PendingSharedReceiptText {
  @override
  ReceiptParseResult? build() => null;

  /// Stores [result] (or clears the stash when [result] is `null`).
  void set(ReceiptParseResult? result) {
    state = result;
  }

  /// Returns the pending result and clears the stash via a microtask so the
  /// caller can invoke it from inside a widget build / `initState` without
  /// tripping Riverpod's build-phase state-write assert.
  ReceiptParseResult? consumeDeferred() {
    final pending = state;
    if (pending != null) {
      unawaited(Future.microtask(() => state = null));
    }
    return pending;
  }
}
