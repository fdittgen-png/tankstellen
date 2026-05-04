// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_toggle_migration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot Riverpod hook that runs the legacy-toggle migrators once
/// after app startup (#1373 phase 3a + 3b).
///
/// Returns a [Future] that completes when both migrations finish (or
/// resolves immediately to `null` when either the settings box or the
/// central feature-flags repository is not yet available — in tests
/// without Hive, or before [HiveBoxes.init] runs in production).
///
/// Two migrators run in sequence:
///   1. [migrateLegacyToggles] — settings-box-backed legacy keys
///      (currently `hapticEcoCoachEnabled`).
///   2. [migrateUserProfileToggles] — UserProfile-backed legacy fields
///      (currently `gamificationEnabled`). This migrator is a no-op
///      when the active profile has not loaded yet; it re-runs on
///      subsequent launches until a profile is available, and only
///      then writes the per-feature `*Migrated` gate flag.
///
/// Each migration is idempotent and gated on its own
/// `*Migrated` flag, so re-firing this provider in tests / hot-reload
/// is safe.
///
/// `keepAlive: true` so the migration runs at most once per app
/// lifetime — Riverpod will not rebuild the provider unless one of
/// its dependencies changes (in this case, `featureFlagsRepository`
/// or `activeProfile`, both of which are `keepAlive`).
///
/// Wiring: any provider / widget can `ref.watch(...)` this to
/// guarantee the migrations have run before they read
/// [featureFlagsProvider]. The default app-init path watches it from
/// the central feature-flags screen so the migration runs the first
/// time the user navigates there — there is no requirement to run it
/// at app start. (#1373 phase 3a/3b defer the explicit startup
/// wire-up because that path lives in `app_initializer.dart`, which
/// is on the hot-file list.)

@ProviderFor(legacyToggleMigration)
final legacyToggleMigrationProvider = LegacyToggleMigrationProvider._();

/// One-shot Riverpod hook that runs the legacy-toggle migrators once
/// after app startup (#1373 phase 3a + 3b).
///
/// Returns a [Future] that completes when both migrations finish (or
/// resolves immediately to `null` when either the settings box or the
/// central feature-flags repository is not yet available — in tests
/// without Hive, or before [HiveBoxes.init] runs in production).
///
/// Two migrators run in sequence:
///   1. [migrateLegacyToggles] — settings-box-backed legacy keys
///      (currently `hapticEcoCoachEnabled`).
///   2. [migrateUserProfileToggles] — UserProfile-backed legacy fields
///      (currently `gamificationEnabled`). This migrator is a no-op
///      when the active profile has not loaded yet; it re-runs on
///      subsequent launches until a profile is available, and only
///      then writes the per-feature `*Migrated` gate flag.
///
/// Each migration is idempotent and gated on its own
/// `*Migrated` flag, so re-firing this provider in tests / hot-reload
/// is safe.
///
/// `keepAlive: true` so the migration runs at most once per app
/// lifetime — Riverpod will not rebuild the provider unless one of
/// its dependencies changes (in this case, `featureFlagsRepository`
/// or `activeProfile`, both of which are `keepAlive`).
///
/// Wiring: any provider / widget can `ref.watch(...)` this to
/// guarantee the migrations have run before they read
/// [featureFlagsProvider]. The default app-init path watches it from
/// the central feature-flags screen so the migration runs the first
/// time the user navigates there — there is no requirement to run it
/// at app start. (#1373 phase 3a/3b defer the explicit startup
/// wire-up because that path lives in `app_initializer.dart`, which
/// is on the hot-file list.)

final class LegacyToggleMigrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// One-shot Riverpod hook that runs the legacy-toggle migrators once
  /// after app startup (#1373 phase 3a + 3b).
  ///
  /// Returns a [Future] that completes when both migrations finish (or
  /// resolves immediately to `null` when either the settings box or the
  /// central feature-flags repository is not yet available — in tests
  /// without Hive, or before [HiveBoxes.init] runs in production).
  ///
  /// Two migrators run in sequence:
  ///   1. [migrateLegacyToggles] — settings-box-backed legacy keys
  ///      (currently `hapticEcoCoachEnabled`).
  ///   2. [migrateUserProfileToggles] — UserProfile-backed legacy fields
  ///      (currently `gamificationEnabled`). This migrator is a no-op
  ///      when the active profile has not loaded yet; it re-runs on
  ///      subsequent launches until a profile is available, and only
  ///      then writes the per-feature `*Migrated` gate flag.
  ///
  /// Each migration is idempotent and gated on its own
  /// `*Migrated` flag, so re-firing this provider in tests / hot-reload
  /// is safe.
  ///
  /// `keepAlive: true` so the migration runs at most once per app
  /// lifetime — Riverpod will not rebuild the provider unless one of
  /// its dependencies changes (in this case, `featureFlagsRepository`
  /// or `activeProfile`, both of which are `keepAlive`).
  ///
  /// Wiring: any provider / widget can `ref.watch(...)` this to
  /// guarantee the migrations have run before they read
  /// [featureFlagsProvider]. The default app-init path watches it from
  /// the central feature-flags screen so the migration runs the first
  /// time the user navigates there — there is no requirement to run it
  /// at app start. (#1373 phase 3a/3b defer the explicit startup
  /// wire-up because that path lives in `app_initializer.dart`, which
  /// is on the hot-file list.)
  LegacyToggleMigrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'legacyToggleMigrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$legacyToggleMigrationHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return legacyToggleMigration(ref);
  }
}

String _$legacyToggleMigrationHash() =>
    r'f56d28476cf26cc102db777b9ad413103a99d2fb';
