// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Per-isolate registry of Hive boxes the **main isolate** opened and owns
/// for the whole app lifetime (#2670).
///
/// Hive's box registry is a single global per *isolate*, not per logical
/// "worker". When a background scan runs inside the **foreground** isolate
/// (the Android home-widget refresh + foreground-service runners — see
/// `ErrorLayer.background`, "tasks running inside the foreground isolate"),
/// `HiveBoxes.initInIsolate` / `closeIsolateBoxes` operate on those very same
/// global handles. Before #2670, `closeIsolateBoxes`'s `finally` therefore
/// closed the live `cache` box the main `init()` had opened, and the next
/// foreground `StationServiceChain` cache read hit a closed file
/// (`FileSystemException: File closed, path='…/cache.hive'`, 43× in field).
///
/// The fix: `closeIsolateBoxes` never closes a box recorded here. A box is
/// recorded only when the main lifecycle opener (`init` / `initDeferred` /
/// `initForTest`) ran *in this isolate*, so a **true spawned `dart:isolate`**
/// worker — which never calls `init()` — sees an empty registry and still
/// closes its own `initInIsolate` handles to release OS file descriptors. The
/// guard is thus a no-op for the only case it must not touch (the shared
/// foreground handles) and inert everywhere else.
class HiveIsolateOwnership {
  HiveIsolateOwnership._();

  static final Set<String> _owned = <String>{};

  /// Records [names] as main-isolate-owned. Idempotent.
  static void markOwned(Iterable<String> names) => _owned.addAll(names);

  /// Whether [name] is owned by the main isolate and must survive
  /// `closeIsolateBoxes`.
  static bool isOwned(String name) => _owned.contains(name);

  /// Clears the registry (#2670). Test-only hook so a test can simulate a
  /// **spawned-worker** isolate — where `init()` never ran — and assert
  /// `closeIsolateBoxes` still closes the `initInIsolate` handles.
  @visibleForTesting
  static void resetForTest() => _owned.clear();
}
