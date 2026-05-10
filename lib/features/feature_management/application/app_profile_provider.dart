import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_profile_repository.dart';
import '../domain/app_profile.dart';
import '../domain/feature.dart';
import 'feature_flags_provider.dart';

part 'app_profile_provider.g.dart';

/// Hive-backed repository for the active [AppProfile] (#1517).
///
/// Returns `null` when the [AppProfileRepository.boxName] box has not
/// been opened. Tests that don't initialise Hive get a no-op so the
/// provider stays usable without persistence.
@Riverpod(keepAlive: true)
AppProfileRepository? appProfileRepository(Ref ref) {
  if (!Hive.isBoxOpen(AppProfileRepository.boxName)) return null;
  return AppProfileRepository(
    box: Hive.box<dynamic>(AppProfileRepository.boxName),
  );
}

/// Active "use mode" profile (#1517).
///
/// State is `null` when the user has never chosen on this install — the
/// onboarding wizard's profile-choice page is the gate. Otherwise the
/// state is the persisted [AppProfile].
///
/// On first build, the notifier reconciles three startup states:
/// 1. Profile box empty AND feature_flags box empty → fresh install,
///    state stays `null` until the wizard sets it.
/// 2. Profile box empty AND feature_flags box populated → pre-#1517
///    install. Persist [AppProfile.custom] so the user keeps their
///    existing flag set untouched and the Settings selector renders.
/// 3. Profile box populated → return the persisted profile.
///
/// `select(profile)` applies the corresponding bundle from
/// [appProfileBundles] to the central feature-flag store atomically.
/// Picking [AppProfile.custom] explicitly is a no-op on flags — the
/// user's current set is whatever they last persisted.
@Riverpod(keepAlive: true)
class ActiveAppProfile extends _$ActiveAppProfile {
  @override
  AppProfile? build() {
    final repo = ref.watch(appProfileRepositoryProvider);
    if (repo == null) return null;
    final persisted = repo.load();
    if (persisted != null) return persisted;
    // No profile persisted yet. Distinguish fresh vs pre-#1517 install
    // by peeking at the central feature-flags REPOSITORY (not the
    // provider state, which returns manifest defaults on the first
    // frame for both cases). An empty feature-flags box means fresh
    // install — wizard will set the profile when the user taps a card.
    // A populated box means the user has been here before — migrate
    // them to `custom` so we never silently change their flag set.
    final flagsRepo = ref.read(featureFlagsRepositoryProvider);
    if (flagsRepo == null || flagsRepo.isEmpty) return null;
    repo.save(AppProfile.custom);
    return AppProfile.custom;
  }

  /// Picks [profile] and applies its bundle to the central feature-
  /// flag store.
  ///
  /// For [AppProfile.custom] this is a flag no-op — the user's set
  /// stays whatever it was last persisted. For the three preset
  /// profiles, every Feature in [Feature.values] is either enabled (if
  /// in the bundle) or disabled (if not), so re-selecting the same
  /// profile is idempotent and switching profiles never leaves
  /// stale-on flags around.
  ///
  /// Bundle application respects the dependency graph by walking
  /// [Feature.values] in declaration order, which matches the
  /// dependency order today (parents before children) — see the
  /// declaration order comment on [Feature] for why this isn't fragile.
  Future<void> select(AppProfile profile) async {
    final repo = ref.read(appProfileRepositoryProvider);
    state = profile;
    if (repo != null) {
      await repo.save(profile);
    }

    if (profile == AppProfile.custom) return;

    final bundle = appProfileBundles[profile] ?? <Feature>{};
    final flags = ref.read(featureFlagsProvider.notifier);
    final manifest = ref.read(featureManifestProvider);
    // Two-pass apply: enable parents before children so the dependency
    // graph never rejects an enable mid-bundle. We sort by topological
    // depth — features with no `requires` first, then features whose
    // requires are already in the bundle.
    final sorted = _topologicalOrder(bundle, manifest.entries);
    for (final feature in sorted) {
      await flags.enable(feature);
    }
    // Disable everything not in the bundle. Walk in reverse topological
    // order so children are disabled before their parents (parents are
    // safe to disable at any time per the lazy-cascade contract, but
    // reverse-order keeps the persisted set tidy after each step).
    final toDisable = Feature.values
        .where((f) => !bundle.contains(f))
        .toList()
        .reversed;
    for (final feature in toDisable) {
      await flags.disable(feature);
    }
  }

  /// Recomputes the active profile after an external feature-flag
  /// toggle (i.e. the user flipped a switch in Settings → Feature
  /// management). Switches to [AppProfile.custom] when the new flag
  /// set no longer matches the current preset.
  ///
  /// Idempotent: if the new flag set still matches the current preset
  /// (rare but possible — e.g. user toggled then untoggled), the
  /// profile stays unchanged.
  Future<void> reconcileWithFlags(Set<Feature> enabled) async {
    final detected = detectProfileFromFlags(enabled);
    if (detected == state) return;
    state = detected;
    final repo = ref.read(appProfileRepositoryProvider);
    if (repo != null) {
      await repo.save(detected);
    }
  }
}

/// Returns [features] in topological order so every feature comes after
/// the features it `requires`. Used by `select()` to enable parents
/// before children regardless of declaration order in [Feature].
///
/// The manifest's `assertNoCycles` invariant guarantees termination.
List<Feature> _topologicalOrder(
  Set<Feature> features,
  Map<Feature, dynamic> manifestEntries,
) {
  final visited = <Feature>{};
  final result = <Feature>[];
  void visit(Feature node) {
    if (visited.contains(node)) return;
    visited.add(node);
    final entry = manifestEntries[node];
    if (entry != null) {
      for (final required in entry.requires as Set<Feature>) {
        if (features.contains(required)) visit(required);
      }
    }
    result.add(node);
  }

  for (final f in features) {
    visit(f);
  }
  return result;
}
