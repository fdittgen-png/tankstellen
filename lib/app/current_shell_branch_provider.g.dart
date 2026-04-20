// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_shell_branch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes the currently-visible bottom-nav branch (0 = Search, 1 = Map,
/// 2 = Favorites, 3 = Settings). Updated by [ShellScreen] on every
/// `goBranch` so observers can react to tab visibility changes without
/// reaching into the shell's private state (#696).
///
/// MapScreen listens to this to trigger a tile-viewport recompute every
/// time the Map tab becomes visible — the IndexedStack pre-mounts every
/// branch with degenerate constraints, so without this hook the map
/// stays blank until the user manually pans or zooms.

@ProviderFor(CurrentShellBranch)
final currentShellBranchProvider = CurrentShellBranchProvider._();

/// Exposes the currently-visible bottom-nav branch (0 = Search, 1 = Map,
/// 2 = Favorites, 3 = Settings). Updated by [ShellScreen] on every
/// `goBranch` so observers can react to tab visibility changes without
/// reaching into the shell's private state (#696).
///
/// MapScreen listens to this to trigger a tile-viewport recompute every
/// time the Map tab becomes visible — the IndexedStack pre-mounts every
/// branch with degenerate constraints, so without this hook the map
/// stays blank until the user manually pans or zooms.
final class CurrentShellBranchProvider
    extends $NotifierProvider<CurrentShellBranch, int> {
  /// Exposes the currently-visible bottom-nav branch (0 = Search, 1 = Map,
  /// 2 = Favorites, 3 = Settings). Updated by [ShellScreen] on every
  /// `goBranch` so observers can react to tab visibility changes without
  /// reaching into the shell's private state (#696).
  ///
  /// MapScreen listens to this to trigger a tile-viewport recompute every
  /// time the Map tab becomes visible — the IndexedStack pre-mounts every
  /// branch with degenerate constraints, so without this hook the map
  /// stays blank until the user manually pans or zooms.
  CurrentShellBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentShellBranchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentShellBranchHash();

  @$internal
  @override
  CurrentShellBranch create() => CurrentShellBranch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$currentShellBranchHash() =>
    r'092b87f79222ed19d229e3b41c8b58a575e6bcba';

/// Exposes the currently-visible bottom-nav branch (0 = Search, 1 = Map,
/// 2 = Favorites, 3 = Settings). Updated by [ShellScreen] on every
/// `goBranch` so observers can react to tab visibility changes without
/// reaching into the shell's private state (#696).
///
/// MapScreen listens to this to trigger a tile-viewport recompute every
/// time the Map tab becomes visible — the IndexedStack pre-mounts every
/// branch with degenerate constraints, so without this hook the map
/// stays blank until the user manually pans or zooms.

abstract class _$CurrentShellBranch extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
