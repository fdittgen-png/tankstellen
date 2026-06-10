// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/sync/sync_config.dart';

part 'sync_setup_provider.g.dart';

enum SyncSetupStep { mode, credentials, auth, adopt, done }

/// UI-only state for the clean 3-step sync setup screen. Text input values
/// live in [TextEditingController]s owned by the screen itself; wizard step,
/// selected mode, loading/error state and the show-key toggle live here.
class SyncSetupState {
  final SyncSetupStep step;
  final SyncMode selectedMode;
  final bool isLoading;
  final String? error;
  final bool showKey;

  /// Sub-step (0-2) of the guided "create your own database" flow shown
  /// in the credentials step for [SyncMode.private] (#1703). Ignored for
  /// every other mode. Reset to 0 each time a mode is (re)selected.
  final int createDbStep;

  /// Email read from a scanned share-QR that carried an `email` field
  /// (#3080) — the first device's account that this device should *adopt*
  /// (join via sign-in, keeping the existing UUID). Non-null drives the
  /// flow into [SyncSetupStep.adopt] instead of the normal auth step.
  final String? adoptEmail;

  /// Show/hide toggle for the adoption-step password field (#3080).
  final bool showPassword;

  const SyncSetupState({
    this.step = SyncSetupStep.mode,
    this.selectedMode = SyncMode.none,
    this.isLoading = false,
    this.error,
    this.showKey = false,
    this.createDbStep = 0,
    this.adoptEmail,
    this.showPassword = false,
  });

  SyncSetupState copyWith({
    SyncSetupStep? step,
    SyncMode? selectedMode,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? showKey,
    int? createDbStep,
    String? adoptEmail,
    bool clearAdoptEmail = false,
    bool? showPassword,
  }) {
    return SyncSetupState(
      step: step ?? this.step,
      selectedMode: selectedMode ?? this.selectedMode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      showKey: showKey ?? this.showKey,
      createDbStep: createDbStep ?? this.createDbStep,
      adoptEmail: clearAdoptEmail ? null : (adoptEmail ?? this.adoptEmail),
      showPassword: showPassword ?? this.showPassword,
    );
  }
}

@riverpod
class SyncSetupController extends _$SyncSetupController {
  @override
  SyncSetupState build() => const SyncSetupState();

  void goToStep(SyncSetupStep step) => state = state.copyWith(step: step);

  void selectMode(SyncMode mode) {
    state = state.copyWith(
      selectedMode: mode,
      step: mode == SyncMode.community
          ? SyncSetupStep.auth
          : SyncSetupStep.credentials,
      // Restart the guided create-database flow whenever a mode is picked.
      createDbStep: 0,
    );
  }

  /// Advances the guided create-database flow (#1703) one sub-step.
  void nextCreateDbStep() =>
      state = state.copyWith(createDbStep: state.createDbStep + 1);

  /// Steps the guided create-database flow (#1703) back one sub-step,
  /// clamped at 0.
  void prevCreateDbStep() => state = state.copyWith(
        createDbStep: state.createDbStep > 0 ? state.createDbStep - 1 : 0,
      );

  void toggleKeyVisibility() =>
      state = state.copyWith(showKey: !state.showKey);

  void togglePasswordVisibility() =>
      state = state.copyWith(showPassword: !state.showPassword);

  /// Enter the QR-join adoption flow (#3080): a scanned share-QR carried an
  /// `email`, so route to [SyncSetupStep.adopt] to sign into that account
  /// instead of the normal auth step. Defaults the mode to [joinExisting]
  /// since the user is joining someone else's database.
  void startAdoption(String email) => state = state.copyWith(
        adoptEmail: email,
        selectedMode: SyncMode.joinExisting,
        step: SyncSetupStep.adopt,
        clearError: true,
      );

  /// Abandon the adoption flow and fall back to the normal auth step
  /// (e.g. the user wants their own account, not the QR owner's).
  void cancelAdoption() => state = state.copyWith(
        clearAdoptEmail: true,
        step: SyncSetupStep.auth,
        clearError: true,
      );

  void startLoading() =>
      state = state.copyWith(isLoading: true, clearError: true);

  void stopLoading() => state = state.copyWith(isLoading: false);

  void setError(String message) =>
      state = state.copyWith(error: message, isLoading: false);

  /// Rebuild signal for text-controller-driven UI (e.g. enabling the
  /// continue button once URL/key are non-empty).
  void touch() => state = state.copyWith();
}
