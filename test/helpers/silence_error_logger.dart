// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';

/// #2146 — many catches now route through `errorLogger.log`. In tests
/// Hive isn't initialised, so the spool's default path throws and the
/// test framework's zone-error guard fails the test. Silence the spool
/// for the current group by calling this once at the top of the
/// suite's `main()` (or inside a `group` block).
///
/// Pairs `setUp` + `tearDown` automatically; no caller bookkeeping
/// needed. The override is process-wide (the test seam is a static),
/// so calling it twice in nested groups is harmless — the second
/// `setUp` re-installs the no-op, and the matching `tearDown` resets.
void silenceErrorLoggerSpool() {
  setUp(() {
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};
  });
  tearDown(errorLogger.resetForTest);
}
