// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/permissions/battery_optimization_permissions.dart';
import 'package:tankstellen/features/consumption/providers/recording_battery_exemption.dart';

/// #3313 — the one-time, FGS-gated battery-optimization-exemption prompt
/// fired from a manual recording start.
class _FakePermissions implements BatteryOptimizationPermissions {
  bool exempt = false;
  int isExemptCalls = 0;
  int requestCalls = 0;

  @override
  Future<bool> isExempt() async {
    isExemptCalls++;
    return exempt;
  }

  @override
  Future<void> requestExemption() async {
    requestCalls++;
  }
}

void main() {
  late _FakePermissions perms;
  late bool asked;

  RecordingBatteryExemption build({required bool fgsEnabled}) {
    return RecordingBatteryExemption(
      permissions: perms,
      alreadyAsked: () => asked,
      markAsked: () async => asked = true,
      fgsEnabled: fgsEnabled,
    );
  }

  setUp(() {
    perms = _FakePermissions();
    asked = false;
  });

  test('FGS disabled (default build) → never prompts, never marks', () async {
    await build(fgsEnabled: false).maybePrompt();
    expect(perms.isExemptCalls, 0);
    expect(perms.requestCalls, 0);
    expect(asked, isFalse);
  });

  test('first manual start (FGS on, not exempt) → marks then requests', () async {
    await build(fgsEnabled: true).maybePrompt();
    expect(asked, isTrue, reason: 'asked flag persisted');
    expect(perms.requestCalls, 1, reason: 'system dialog requested once');
  });

  test('already asked → never re-prompts (no nag)', () async {
    asked = true;
    await build(fgsEnabled: true).maybePrompt();
    expect(perms.isExemptCalls, 0);
    expect(perms.requestCalls, 0);
  });

  test('already exempt → marks asked but does NOT show the dialog', () async {
    perms.exempt = true;
    await build(fgsEnabled: true).maybePrompt();
    expect(asked, isTrue);
    expect(perms.isExemptCalls, 1);
    expect(perms.requestCalls, 0, reason: 'no point prompting when whitelisted');
  });

  test('a throwing dialog is swallowed (best-effort, never throws into the '
      'recording path) and the asked flag still sticks (#2349)', () async {
    final c = RecordingBatteryExemption(
      permissions: _ThrowingOnRequest(),
      alreadyAsked: () => asked,
      markAsked: () async => asked = true,
      fgsEnabled: true,
    );
    // Fault injected (the request dialog throws): the call must still
    // complete normally — never rethrow into the start path.
    await expectLater(c.maybePrompt(), completes);
    // And the asked flag was set BEFORE the throwing request, so a second
    // start is a no-op (no nag).
    expect(asked, isTrue);
  });
}

class _ThrowingOnRequest implements BatteryOptimizationPermissions {
  @override
  Future<bool> isExempt() async => false;

  @override
  Future<void> requestExemption() async => throw Exception('dialog blew up');
}
