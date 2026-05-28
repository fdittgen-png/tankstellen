// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';

/// #2146 — many catches now route through `errorLogger.log`. In tests
/// Hive isn't initialised, so the spool's default path throws and the
/// test framework's zone-error guard fails the test. Silence the spool
/// for the current test file by calling this once at the top of `main()`.
///
/// Uses `setUpAll` (not `setUp`) so the override persists between tests
/// in the same file. Per-test `setUp`/`tearDown` would reset between
/// tests, which loses races against fire-and-forget async catches that
/// fire AFTER the test has been marked complete (`This test failed
/// after it had already completed` errors).
///
/// `tearDownAll` resets so the override doesn't leak into other test
/// files that share the process.
void silenceErrorLoggerSpool() {
  setUpAll(() {
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};
  });
  tearDownAll(errorLogger.resetForTest);
}
