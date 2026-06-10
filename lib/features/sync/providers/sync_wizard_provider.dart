// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_wizard_provider.g.dart';

enum SyncWizardMode { choose, createNew, joinExisting, auth, adopt, schema }

/// UI-only state for the sync setup wizard. Text inputs live in
/// [TextEditingController]s owned by the screen.
class SyncWizardState {
  final SyncWizardMode mode;
  final int createStep;
  final bool testing;
  final bool connecting;
  final bool isSignUp;
  final bool useEmail;
  final String? testResult;
  final bool testSuccess;
  final Map<String, bool>? schemaStatus;
  final String? migrationSql;
  final bool showKey;

  /// #2929 — true when every required table exists but the database's
  /// recorded schema version is older than the build expects (a self-hoster
  /// who hasn't re-run the latest setup SQL). Drives the "schema outdated —
  /// re-run the setup SQL" banner instead of a silent per-feature break.
  final bool schemaOutdated;

  /// Email read from a scanned share-QR that carried an `email` field
  /// (#3080) — the QR owner's account this device should *adopt* (join via
  /// sign-in, keeping the existing UUID). Non-null drives the wizard into
  /// [SyncWizardMode.adopt] instead of the normal auth step.
  final String? adoptEmail;

  /// Show/hide toggle for the adoption-step password field (#3080).
  final bool showPassword;

  const SyncWizardState({
    this.mode = SyncWizardMode.choose,
    this.createStep = 0,
    this.testing = false,
    this.connecting = false,
    this.isSignUp = true,
    this.useEmail = false,
    this.testResult,
    this.testSuccess = false,
    this.schemaStatus,
    this.migrationSql,
    this.showKey = false,
    this.schemaOutdated = false,
    this.adoptEmail,
    this.showPassword = false,
  });

  SyncWizardState copyWith({
    SyncWizardMode? mode,
    int? createStep,
    bool? testing,
    bool? connecting,
    bool? isSignUp,
    bool? useEmail,
    String? testResult,
    bool clearTestResult = false,
    bool? testSuccess,
    Map<String, bool>? schemaStatus,
    bool clearSchemaStatus = false,
    String? migrationSql,
    bool clearMigrationSql = false,
    bool? showKey,
    bool? schemaOutdated,
    String? adoptEmail,
    bool clearAdoptEmail = false,
    bool? showPassword,
  }) {
    return SyncWizardState(
      mode: mode ?? this.mode,
      createStep: createStep ?? this.createStep,
      testing: testing ?? this.testing,
      connecting: connecting ?? this.connecting,
      isSignUp: isSignUp ?? this.isSignUp,
      useEmail: useEmail ?? this.useEmail,
      testResult: clearTestResult ? null : (testResult ?? this.testResult),
      testSuccess: testSuccess ?? this.testSuccess,
      schemaStatus:
          clearSchemaStatus ? null : (schemaStatus ?? this.schemaStatus),
      migrationSql:
          clearMigrationSql ? null : (migrationSql ?? this.migrationSql),
      showKey: showKey ?? this.showKey,
      schemaOutdated: schemaOutdated ?? this.schemaOutdated,
      adoptEmail: clearAdoptEmail ? null : (adoptEmail ?? this.adoptEmail),
      showPassword: showPassword ?? this.showPassword,
    );
  }
}

@riverpod
class SyncWizardController extends _$SyncWizardController {
  @override
  SyncWizardState build() => const SyncWizardState();

  void setMode(SyncWizardMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setCreateStep(int step) {
    state = state.copyWith(createStep: step);
  }

  void incrementStep() {
    state = state.copyWith(createStep: state.createStep + 1);
  }

  void decrementStep() {
    state = state.copyWith(createStep: state.createStep - 1);
  }

  void toggleKeyVisibility() {
    state = state.copyWith(showKey: !state.showKey);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  /// Enter the QR-join adoption flow (#3080): a scanned share-QR carried an
  /// `email`, so route to [SyncWizardMode.adopt] to sign into that account
  /// instead of the normal auth step.
  void startAdoption(String email) {
    state = state.copyWith(
      adoptEmail: email,
      mode: SyncWizardMode.adopt,
      clearTestResult: true,
    );
  }

  /// Abandon the adoption flow and fall back to the normal auth step.
  void cancelAdoption() {
    state = state.copyWith(
      clearAdoptEmail: true,
      mode: SyncWizardMode.auth,
      clearTestResult: true,
    );
  }

  void adoptFailed(String message) {
    state = state.copyWith(
      connecting: false,
      testResult: message,
      testSuccess: false,
    );
  }

  void setUseEmail(bool value) {
    state = state.copyWith(useEmail: value);
  }

  void toggleSignUp() {
    state = state.copyWith(isSignUp: !state.isSignUp);
  }

  void startTesting() {
    state = state.copyWith(testing: true, clearTestResult: true);
  }

  void testSucceeded(String message) {
    state = state.copyWith(
      testing: false,
      testResult: message,
      testSuccess: true,
    );
  }

  void testFailed(String message) {
    state = state.copyWith(
      testing: false,
      testResult: message,
      testSuccess: false,
    );
  }

  void setConnecting(bool value) {
    state = state.copyWith(connecting: value);
  }

  void connectFailed(String message) {
    state = state.copyWith(
      testResult: message,
      testSuccess: false,
    );
  }

  void showSchemaStep({
    required Map<String, bool> schema,
    required String migrationSql,
    bool schemaOutdated = false,
  }) {
    state = state.copyWith(
      mode: SyncWizardMode.schema,
      schemaStatus: schema,
      migrationSql: migrationSql,
      schemaOutdated: schemaOutdated,
    );
  }

  void updateSchemaStatus(Map<String, bool>? schema,
      {bool schemaOutdated = false}) {
    state = state.copyWith(
      schemaStatus: schema,
      clearSchemaStatus: schema == null,
      schemaOutdated: schemaOutdated,
    );
  }

  /// Rebuild signal for text controller changes (e.g. password field).
  void touch() {
    state = state.copyWith();
  }

  void reset() {
    state = const SyncWizardState();
  }
}
