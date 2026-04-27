// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievements_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hive-backed achievements store (#781). Returns null when the Hive
/// box isn't open — widget tests that skip Hive init get a silent
/// no-op instead of a thrown error.

@ProviderFor(achievementsRepository)
final achievementsRepositoryProvider = AchievementsRepositoryProvider._();

/// Hive-backed achievements store (#781). Returns null when the Hive
/// box isn't open — widget tests that skip Hive init get a silent
/// no-op instead of a thrown error.

final class AchievementsRepositoryProvider
    extends
        $FunctionalProvider<
          AchievementsRepository?,
          AchievementsRepository?,
          AchievementsRepository?
        >
    with $Provider<AchievementsRepository?> {
  /// Hive-backed achievements store (#781). Returns null when the Hive
  /// box isn't open — widget tests that skip Hive init get a silent
  /// no-op instead of a thrown error.
  AchievementsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AchievementsRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AchievementsRepository? create(Ref ref) {
    return achievementsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AchievementsRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AchievementsRepository?>(value),
    );
  }
}

String _$achievementsRepositoryHash() =>
    r'f15a16b771adc54c29adb4dfb1e90a5bedd61996';

/// Singleton engine — pure function, no state, cheap to share.

@ProviderFor(achievementEngine)
final achievementEngineProvider = AchievementEngineProvider._();

/// Singleton engine — pure function, no state, cheap to share.

final class AchievementEngineProvider
    extends
        $FunctionalProvider<
          AchievementEngine,
          AchievementEngine,
          AchievementEngine
        >
    with $Provider<AchievementEngine> {
  /// Singleton engine — pure function, no state, cheap to share.
  AchievementEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementEngineHash();

  @$internal
  @override
  $ProviderElement<AchievementEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AchievementEngine create(Ref ref) {
    return achievementEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AchievementEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AchievementEngine>(value),
    );
  }
}

String _$achievementEngineHash() => r'18e8b60750ab2c5c2a4b66ca6d19ce9b5172c84c';

/// Earned badges, newest-first. Watches the trip-history and
/// fill-up providers so that adding a trip or fill-up naturally
/// re-evaluates the rules without an explicit `refresh()` call.
///
/// Because `mergeEarned` is idempotent (only persists ids that
/// aren't already stored), re-running the evaluation on every
/// upstream change is cheap and safe.

@ProviderFor(Achievements)
final achievementsProvider = AchievementsProvider._();

/// Earned badges, newest-first. Watches the trip-history and
/// fill-up providers so that adding a trip or fill-up naturally
/// re-evaluates the rules without an explicit `refresh()` call.
///
/// Because `mergeEarned` is idempotent (only persists ids that
/// aren't already stored), re-running the evaluation on every
/// upstream change is cheap and safe.
final class AchievementsProvider
    extends $NotifierProvider<Achievements, List<EarnedAchievement>> {
  /// Earned badges, newest-first. Watches the trip-history and
  /// fill-up providers so that adding a trip or fill-up naturally
  /// re-evaluates the rules without an explicit `refresh()` call.
  ///
  /// Because `mergeEarned` is idempotent (only persists ids that
  /// aren't already stored), re-running the evaluation on every
  /// upstream change is cheap and safe.
  AchievementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementsHash();

  @$internal
  @override
  Achievements create() => Achievements();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<EarnedAchievement> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<EarnedAchievement>>(value),
    );
  }
}

String _$achievementsHash() => r'3825e61016915e7fdfd88e4317a2c3ad82fa3e4f';

/// Earned badges, newest-first. Watches the trip-history and
/// fill-up providers so that adding a trip or fill-up naturally
/// re-evaluates the rules without an explicit `refresh()` call.
///
/// Because `mergeEarned` is idempotent (only persists ids that
/// aren't already stored), re-running the evaluation on every
/// upstream change is cheap and safe.

abstract class _$Achievements extends $Notifier<List<EarnedAchievement>> {
  List<EarnedAchievement> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<EarnedAchievement>, List<EarnedAchievement>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<EarnedAchievement>, List<EarnedAchievement>>,
              List<EarnedAchievement>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
