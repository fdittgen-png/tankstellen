// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pending_trip_saves.dart';

/// #4378 — the retry behind the stop's "Retry" action: the trips whose
/// history write failed, written through the same confirmed save the
/// launch pass uses. Returns how many landed.
///
/// A provider rather than a direct call so the recording screen's tap can
/// be driven in a widget test without real Hive I/O — the store's own
/// tests cover what the retry writes.
final pendingTripSaveRetryProvider = Provider<Future<int> Function()>(
  (ref) => retryPendingTripSaves,
);
