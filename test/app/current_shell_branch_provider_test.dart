import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/current_shell_branch_provider.dart';

/// #696 — The current-branch provider is what MapScreen listens to in
/// order to nudge its tile viewport every time the Carte tab becomes
/// visible. If this provider stops emitting changes on tab flip, the
/// map regression returns — pin the contract with tests so a future
/// refactor of ShellScreen cannot silently break it.
void main() {
  group('currentShellBranchProvider', () {
    test('initial state is 0 (Search tab)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(currentShellBranchProvider), 0);
    });

    test('set(index) publishes the new branch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentShellBranchProvider.notifier).set(1);
      expect(container.read(currentShellBranchProvider), 1);

      container.read(currentShellBranchProvider.notifier).set(3);
      expect(container.read(currentShellBranchProvider), 3);
    });

    test('listeners fire on EVERY set (even when moving to the same branch '
        'and back), so the map nudge runs on every tab flip to Carte', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final observed = <int>[];
      container.listen<int>(
        currentShellBranchProvider,
        (prev, next) => observed.add(next),
        fireImmediately: false,
      );

      container.read(currentShellBranchProvider.notifier).set(1); // → Carte
      container.read(currentShellBranchProvider.notifier).set(0); // → Search
      container.read(currentShellBranchProvider.notifier).set(1); // → Carte again
      expect(observed, [1, 0, 1],
          reason: 'Every flip must notify — otherwise the Carte-nudge '
              'fires only once and the map stays blank on repeat visits');
    });
  });
}
