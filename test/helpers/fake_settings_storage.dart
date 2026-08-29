// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/permissions/permission_rationale_dialog.dart';

/// Minimal in-memory [SettingsStorage] for widget tests that only need the
/// narrow settings interface (#3872 — the pre-permission rationale reads and
/// writes its once-per-kind flag through it).
class FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  FakeSettingsStorage();

  /// A storage on which every [PermissionRationaleKind] is already
  /// acknowledged — for tests that exercise the surface BEHIND the rationale
  /// and must not be blocked by it.
  factory FakeSettingsStorage.rationalesShown() {
    final storage = FakeSettingsStorage();
    for (final kind in PermissionRationaleKind.values) {
      storage.data[PermissionRationaleDialog.storageKeyFor(kind)] = true;
    }
    return storage;
  }

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
