// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_toggle_migration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot Riverpod hook that runs [migrateLegacyToggles] once after
/// app startup (#1373 phase 3a).
///
/// Returns a [Future] that completes when the migration finishes (or
/// resolves immediately to `null` when either the settings box or the
/// central feature-flags repository is not yet available — in tests
/// without Hive, or before [HiveBoxes.init] runs in production).
///
/// The migration itself is idempotent and gated on the
/// [hapticEcoCoachMigratedKey] flag, so re-firing this provider in
/// tests / hot-reload is safe.
///
/// `keepAlive: true` so the migration runs at most once per app
/// lifetime — Riverpod will not rebuild the provider unless one of
/// its dependencies changes (in this case, `featureFlagsRepository`,
/// which itself is `keepAlive`).
///
/// Wiring: any provider / widget can `ref.watch(...)` this to
/// guarantee the migration has run before they read
/// [featureFlagsProvider]. The default app-init path watches it from
/// the central feature-flags screen so the migration runs the first
/// time the user navigates there — there is no requirement to run it
/// at app start. (#1373 phase 3a defers the explicit startup wire-up
/// because that path lives in `app_initializer.dart`, which is on the
/// hot-file list.)

@ProviderFor(legacyToggleMigration)
final legacyToggleMigrationProvider = LegacyToggleMigrationProvider._();

/// One-shot Riverpod hook that runs [migrateLegacyToggles] once after
/// app startup (#1373 phase 3a).
///
/// Returns a [Future] that completes when the migration finishes (or
/// resolves immediately to `null` when either the settings box or the
/// central feature-flags repository is not yet available — in tests
/// without Hive, or before [HiveBoxes.init] runs in production).
///
/// The migration itself is idempotent and gated on the
/// [hapticEcoCoachMigratedKey] flag, so re-firing this provider in
/// tests / hot-reload is safe.
///
/// `keepAlive: true` so the migration runs at most once per app
/// lifetime — Riverpod will not rebuild the provider unless one of
/// its dependencies changes (in this case, `featureFlagsRepository`,
/// which itself is `keepAlive`).
///
/// Wiring: any provider / widget can `ref.watch(...)` this to
/// guarantee the migration has run before they read
/// [featureFlagsProvider]. The default app-init path watches it from
/// the central feature-flags screen so the migration runs the first
/// time the user navigates there — there is no requirement to run it
/// at app start. (#1373 phase 3a defers the explicit startup wire-up
/// because that path lives in `app_initializer.dart`, which is on the
/// hot-file list.)

final class LegacyToggleMigrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// One-shot Riverpod hook that runs [migrateLegacyToggles] once after
  /// app startup (#1373 phase 3a).
  ///
  /// Returns a [Future] that completes when the migration finishes (or
  /// resolves immediately to `null` when either the settings box or the
  /// central feature-flags repository is not yet available — in tests
  /// without Hive, or before [HiveBoxes.init] runs in production).
  ///
  /// The migration itself is idempotent and gated on the
  /// [hapticEcoCoachMigratedKey] flag, so re-firing this provider in
  /// tests / hot-reload is safe.
  ///
  /// `keepAlive: true` so the migration runs at most once per app
  /// lifetime — Riverpod will not rebuild the provider unless one of
  /// its dependencies changes (in this case, `featureFlagsRepository`,
  /// which itself is `keepAlive`).
  ///
  /// Wiring: any provider / widget can `ref.watch(...)` this to
  /// guarantee the migration has run before they read
  /// [featureFlagsProvider]. The default app-init path watches it from
  /// the central feature-flags screen so the migration runs the first
  /// time the user navigates there — there is no requirement to run it
  /// at app start. (#1373 phase 3a defers the explicit startup wire-up
  /// because that path lives in `app_initializer.dart`, which is on the
  /// hot-file list.)
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
    r'1014cf980f258759b3ce53c929150ec4d8658670';
