// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_shared_receipt_provider.g.dart';

/// One-shot stash for the file path of a receipt image an external app
/// shared into Sparkilo via the OS share sheet (#2735 / Epic #2687).
///
/// Mirrors `PendingWidgetUri` (`pending_widget_uri_provider.dart`): the
/// inbound-share listener writes the on-disk path of the shared image
/// here, the router's redirect chain consumes it to land the user on
/// `/consumption/add`, and the Add-fill-up screen consumes it again on
/// open to feed `runSharedReceiptScan` so the form is prefilled from the
/// receipt OCR.
///
/// Why a stash rather than navigating directly from the listener: on a
/// cold share (app was killed) the router has not attached its Navigator
/// when the platform reports the initial shared media, so a synchronous
/// `push` would land on an empty stack and be lost — exactly the
/// #widget-deeplink race the home-widget stash was built to remove. The
/// stash makes the destination authoritative from the first redirect
/// pass instead.
///
/// **Lifecycle**: `set(path)` writes; `consume()` returns the current
/// value and clears the field in the same call so the redirect doesn't
/// keep re-routing back to `/consumption/add`; `consumeDeferred()` is the
/// build-phase-safe variant (clears via a microtask) the router redirect
/// uses. Warm shares (app already running) flow through the same stash
/// before the listener pushes the route.
@Riverpod(keepAlive: true)
class PendingSharedReceipt extends _$PendingSharedReceipt {
  @override
  String? build() => null;

  /// Stores [path] (or clears the stash when [path] is `null`).
  void set(String? path) {
    state = path;
  }

  /// Returns the pending path and clears the stash atomically. Returning
  /// `null` means there was nothing pending — callers fall back to their
  /// default behaviour.
  String? consume() {
    final pending = state;
    if (pending != null) state = null;
    return pending;
  }

  /// Same contract as [consume] but defers the state mutation to a
  /// microtask so callers can safely invoke it from inside a widget
  /// build / Router redirect / other Riverpod-locked phase. Riverpod
  /// asserts when state is mutated while the widget tree is building;
  /// this helper sidesteps that without forcing the caller to wrap the
  /// call in `Future.microtask` itself.
  String? consumeDeferred() {
    final pending = state;
    if (pending != null) {
      unawaited(Future.microtask(() => state = null));
    }
    return pending;
  }
}
