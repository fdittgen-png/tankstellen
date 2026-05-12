import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'effective_feature_flags_provider.dart';
import 'feature_class.dart';

/// Renders [child] iff [feature] is effectively enabled.
///
/// The primitive that couples a feature's "active surface"
/// (whatever it renders on its main screen, e.g. the Trajets tab
/// inside the Conso screen) with its "parameter surface" (the
/// Trajets options inside Settings → Consumption). Both wrap their
/// respective widgets in `FeatureGate(feature: kFeatureTrajets, …)`;
/// the same `effectiveFeatureFlagsProvider` lookup drives both, so
/// the two surfaces appear and disappear together by construction.
///
/// Reads `effectiveFeatureFlagsProvider` via `select` so this widget
/// only rebuilds when *this* feature's effective-enabled state
/// changes — toggling an unrelated feature won't churn the subtree.
class FeatureGate extends ConsumerWidget {
  final FeatureClass feature;
  final Widget child;

  /// Optional fallback rendered when [feature] is off. Defaults to
  /// [SizedBox.shrink] — the gate disappears entirely. Pass a
  /// non-null fallback when the slot must keep its space in a row /
  /// column (e.g. a disabled-state placeholder).
  final Widget? fallback;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      effectiveFeatureFlagsProvider.select(
        (m) => m[feature.id] ?? false,
      ),
    );
    if (enabled) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Builder variant — useful when the gated subtree is expensive to
/// construct and you don't want to allocate it on disabled rebuilds.
/// Mirrors Riverpod's `Consumer.builder` shape.
class FeatureGateBuilder extends ConsumerWidget {
  final FeatureClass feature;
  final WidgetBuilder builder;
  final Widget? fallback;

  const FeatureGateBuilder({
    super.key,
    required this.feature,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      effectiveFeatureFlagsProvider.select(
        (m) => m[feature.id] ?? false,
      ),
    );
    if (enabled) return builder(context);
    return fallback ?? const SizedBox.shrink();
  }
}
