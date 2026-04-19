import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_shell_branch_provider.g.dart';

/// Exposes the currently-visible bottom-nav branch (0 = Search, 1 = Map,
/// 2 = Favorites, 3 = Settings). Updated by [ShellScreen] on every
/// `goBranch` so observers can react to tab visibility changes without
/// reaching into the shell's private state (#696).
///
/// MapScreen listens to this to trigger a tile-viewport recompute every
/// time the Map tab becomes visible — the IndexedStack pre-mounts every
/// branch with degenerate constraints, so without this hook the map
/// stays blank until the user manually pans or zooms.
@Riverpod(keepAlive: true)
class CurrentShellBranch extends _$CurrentShellBranch {
  @override
  int build() => 0;

  void set(int index) => state = index;
}
