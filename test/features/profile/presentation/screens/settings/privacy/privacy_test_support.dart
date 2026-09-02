// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';

/// Stub TraceStorage that doesn't touch Hive — the privacy screens read
/// `count` from the provider during build, and the production
/// implementation calls `Hive.box('error_traces')` which fails in widget
/// tests where Hive isn't initialised.
class StubTraceStorage extends TraceStorage {
  StubTraceStorage({
    this.stubCount = 0,
    this.stubParsedCount = 0,
    this.stubUnparsedCount = 0,
    this.stubExport = '{"traceCount":0,"traces":[]}',
  });

  final int stubCount;
  final int stubParsedCount;
  final int stubUnparsedCount;
  final String stubExport;

  @override
  int get count => stubCount;

  @override
  int get parsedCount => stubParsedCount;

  @override
  int get unparsedCount => stubUnparsedCount;

  @override
  String exportAsJson() => stubExport;

  /// Records the clear-error-log tap without touching Hive.
  bool clearAllCalled = false;

  @override
  Future<void> clearAll() async {
    clearAllCalled = true;
  }
}

/// SyncState pinned to "no sync configured".
class DisabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}

/// SyncState pinned to a connected configuration.
class EnabledSyncState extends SyncState {
  EnabledSyncState({
    this.mode = SyncMode.community,
    this.email,
    this.userId = 'user-abcdef12-3456-7890-abcd-ef1234567890',
    this.url = 'https://test.supabase.co',
  });

  final SyncMode mode;
  final String? email;
  final String userId;
  final String url;

  @override
  SyncConfig build() => SyncConfig(
        enabled: true,
        supabaseUrl: url,
        supabaseAnonKey: 'test-key',
        userId: userId,
        userEmail: email,
        mode: mode,
      );
}
