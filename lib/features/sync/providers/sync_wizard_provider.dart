import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_wizard_provider.g.dart';

enum SyncWizardMode { choose, createNew, joinExisting, auth, schema }

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
  }) {
    state = state.copyWith(
      mode: SyncWizardMode.schema,
      schemaStatus: schema,
      migrationSql: migrationSql,
    );
  }

  void updateSchemaStatus(Map<String, bool>? schema) {
    state = state.copyWith(
      schemaStatus: schema,
      clearSchemaStatus: schema == null,
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
