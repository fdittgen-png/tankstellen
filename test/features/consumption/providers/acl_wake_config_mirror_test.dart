// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/providers/acl_wake_config_mirror.dart';

/// #3756 — the ACL-wake prefs mirror feeding the native
/// `AdapterWakeReceiver` (dead-process wake notification). Includes the
/// #2349 fault-injection case backing the never-throws docstring.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  /// Runs [body] with a live [Ref] (provider-scoped, the only sanctioned
  /// way to obtain one).
  Future<void> withRef(Future<void> Function(Ref ref) body) async {
    final probe = FutureProvider<void>((ref) => body(ref));
    await container.read(probe.future);
  }

  setUp(() {
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _SilentRecorder();
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    errorLogger.testRecorderOverride = null;
    errorLogger.resetForTest();
  });

  test('never-throws (#2349): a broken prefs channel is swallowed — '
      'arming must proceed', () async {
    // No setMockInitialValues: the platform channel has no handler, so
    // SharedPreferences.getInstance() throws inside the mirror. The
    // documented contract is that this NEVER reaches the caller.
    await withRef((ref) async {
      await expectLater(
          mirrorAclWakeConfig(ref, 'D4:E9:5E:A8:CD:7E'), completes);
    });
    await expectLater(clearAclWakeConfig(), completes);
  });

  test('mirrors mac + localized copy into prefs', () async {
    SharedPreferences.setMockInitialValues({});
    await withRef((ref) => mirrorAclWakeConfig(ref, 'D4:E9:5E:A8:CD:7E'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('acl_wake_mac'), 'D4:E9:5E:A8:CD:7E');
    expect(prefs.getString('acl_wake_title'), isNotEmpty);
    expect(prefs.getString('acl_wake_body'), isNotEmpty);
  });

  test('a null mac clears the pinned key (disarm), clear helper too',
      () async {
    SharedPreferences.setMockInitialValues({'acl_wake_mac': 'AA:BB'});
    await withRef((ref) => mirrorAclWakeConfig(ref, null));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('acl_wake_mac'), isNull);

    await clearAclWakeConfig();
    expect(prefs.getString('acl_wake_mac'), isNull);
  });
}

class _SilentRecorder implements TraceRecorder {
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
