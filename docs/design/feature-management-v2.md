# Feature Management v2 — Design

D365FO-inspired declarative feature system. Phase 1 (this design doc
+ the matching code) ships the compatibility layer alongside the
existing `Feature` enum so we can adopt the new API incrementally
without breaking anything.

## Goals (recap of the asks from product)

1. **Class-per-feature** — each feature is a single declarative
   object, the way D365FO does it. Settings tile, dependencies,
   parameter UI, persistence id, ARB keys all anchored to one
   declaration site.
2. **Presentation hierarchy separate from activation DAG** — the
   Settings tree-view nesting (parent) can diverge from "which
   feature must be on for this one to surface" (requires).
3. **Active-surface ↔ parameter-surface coupling** — when a feature
   is enabled, both its main-screen surface AND its Settings
   parameter block appear; when disabled, both disappear. Coupled by
   construction, not by every site checking the same flag.
4. **Beta / production maturity** — features can ship beta-flagged,
   render a badge in Settings, and graduate to production with a
   one-line const flip.
5. **Multi-language labels** — preserved via the existing ARB pipeline
   (`_base_{en,de}.arb` fragments).
6. **Wizard can flip features in bulk** — preset profile bundles
   continue to work; presets never auto-enable beta features.
7. **No performance impact** — per-widget reads are O(1) map
   lookups, not requires-DAG walks.
8. **Existing code enriches without rewrite** — Phase 1 is purely
   additive. Existing call sites work unchanged.

## Core types

```dart
class FeatureClass {
  final String id;                                    // stable Hive key
  final FeatureClass? parent;                         // presentation tree
  final Set<FeatureClass> requires;                   // activation DAG
  final bool defaultEnabled;
  final FeatureMaturity maturity;                     // beta | production
  final String displayKey;                            // ARB lookup
  final String displayName;                           // English fallback
  final String descriptionKey;
  final String description;
  final List<ParameterBinding> parameterBuilders;     // Settings UI bindings
}

enum FeatureMaturity { beta, production }

enum SettingsSection { profile, location, tankSync, theme,
                       consumption, storage, search, about }

class ParameterBinding {
  final SettingsSection section;
  final WidgetBuilder builder;
  final int order;
}
```

Late-binding caveat: `parent` and `requires` are stored as `Function()`
returns rather than direct references. Lets two consts in the same
library reference each other without Dart's const evaluator
complaining about forward references.

## How a feature is declared

One const per feature, in the feature's own module file:

```dart
// lib/features/consumption/feature_trajets.dart
import '../feature_management/v2/feature_class.dart';
import 'feature_obd2.dart';

const kFeatureTrajets = FeatureClass(
  id: 'trajets',
  parent: _consumption,                  // Settings tree parent
  requires: _obd2,                       // activation dependency
  defaultEnabled: false,
  maturity: FeatureMaturity.production,
  displayKey: 'feature_trajets_name',
  displayName: 'Trajets',
  descriptionKey: 'feature_trajets_description',
  description: 'Trip recording + history.',
  parameterBuilders: [
    ParameterBinding(
      section: SettingsSection.consumption,
      builder: (_) => const TrajetsParameterBlock(),
      order: 20,
    ),
  ],
);

FeatureClass _consumption() => kFeatureConsumption;
Set<FeatureClass> _obd2() => {kFeatureObd2TripRecording};
```

Then register in `feature_registry.dart`:

```dart
const featureRegistry = <FeatureClass>[
  // … existing …
  kFeatureTrajets,
];
```

That's the full surface area for adding a feature. Settings tile,
parameter UI placement, dependency cascade, profile-bundle eligibility,
ARB-localized labels, persistence — all live on this one declaration.

## How code refers to a feature

### Active surface — wrap the widget

```dart
FeatureGate(
  feature: kFeatureTrajets,
  child: const TrajetsTab(),
)
```

`FeatureGate` reads `effectiveFeatureFlagsProvider.select((m) =>
m[feature.id])` so it rebuilds only when *this* feature's effective
state flips.

### Parameter surface — registered automatically

The Settings screen iterates the registry. For each section it
renders all `ParameterBinding`s whose feature is effectively enabled,
sorted by `order`. No call site needed; the binding declared on the
`FeatureClass` does the routing.

This is the coupling primitive: the **same** `featureGate` check
drives both the active surface (manual call) and the parameter
surface (automatic via registry iteration). They appear and disappear
together by construction.

### Reading state imperatively

```dart
final m = ref.watch(effectiveFeatureFlagsProvider);
if (m.isOnV2(kFeatureTrajets)) { … }
```

Or the v1-enum compatibility extension:

```dart
if (m.isOn(Feature.trajets)) { … }
```

Both lookups read the same map.

## Performance contract

`effectiveFeatureFlagsProvider` is `keepAlive: true`. It rebuilds
**only** when `featureFlagsProvider` (the underlying Hive-backed
enabled set) changes — i.e. when the user toggles a flag. Per-widget
reads are a single `Map<String, bool>` lookup. No requires-DAG walk
at read time.

For a 1000-widget screen reading 5 distinct flags after a single user
toggle, the cost is:
- One DAG walk over the 20-entry registry (O(N²) worst case, ~400
  comparisons) when the flag set changes.
- One `Map.select` rebuild per dependent widget (Riverpod's select
  pre-filters; widgets read the same value short-circuit).

Compared to today's per-call `isEffectivelyEnabled` walk: 5 walks ×
1000 widgets = 5000 walks per rebuild. The cache eliminates that.

## Maturity lifecycle

A feature lands as:

```dart
const kFeatureNew = FeatureClass(
  …,
  defaultEnabled: false,
  maturity: FeatureMaturity.beta,
);
```

Settings tile renders a "BETA" badge. The profile bundles never
auto-enable beta features (`app_profile_provider` filters by
maturity before applying). Existing users see the tile in Settings
but it's off until they opt in.

Promotion:

```dart
const kFeatureNew = FeatureClass(
  …,
  defaultEnabled: true,            // or keep false if user opt-in stays preferred
  maturity: FeatureMaturity.production,
);
```

Existing users with an explicit preference (toggled it on or off
during beta) keep their preference — the legacy-toggle migration
preserves user state across upgrades. Fresh installs after promotion
pick up the new default.

No code at call sites changes during promotion. No data migration.

## Bridge to v1 (Phase 1 — what this PR ships)

Every v1 `Feature` enum value gets a paired `FeatureClass` const in
`known_features.dart`, with `id` matching the enum's `.name`. The
`featureFlagsProvider` notifier from v1 stays the source of the
enabled set; `effectiveFeatureFlagsProvider` projects that set into
the v2 id-keyed map.

Existing code (`flags.contains(Feature.x)`, `isEffectivelyEnabled(Feature.x, manifest, enabled)`)
continues to work unchanged. New code can pick either API.

Per-feature defaults + dependency edges in v2 mirror the v1 manifest.
The `defaultEnabled mirrors the v1 manifest for every bridged feature`
test in `feature_registry_test.dart` guards the bridge so drift
fails CI loudly.

## Migration plan

### Phase 1 — compatibility layer (this PR)
- Land `FeatureClass`, `featureRegistry`, `effectiveFeatureFlagsProvider`,
  `FeatureGate`, `FeatureGateBuilder` next to the existing v1 system.
- Bridge every v1 enum value to a v2 const.
- 26 tests; whole-repo analyze clean.

### Phase 2 — incremental adoption (small follow-up PRs)
- New features added post-Phase-1 declared as `FeatureClass` directly.
- Existing features migrated one at a time as they're touched:
  - Swap `if (flags.contains(Feature.x))` for `FeatureGate(feature: kFeatureX, …)` or `m.isOnV2(kFeatureX)`.
  - Move parameter UI into `ParameterBinding` registration.
  - Add BETA badge if appropriate.
- Settings screen rewritten to iterate `featureRegistry` instead of
  hand-coding switches.
- ETA: one feature per ~30 min PR. 20 features → ~10 hours of work
  spread across whoever is touching each area.

### Phase 3 — legacy cleanup (one PR after Phase 2 finishes)
- Drop `Feature` enum.
- Drop `FeatureManifest` + `FeatureManifestEntry` map.
- Drop hand-coded `_featureLabel` / `_featureDescription` /
  `_blockedEnableMessage` switches in `feature_management_section.dart`
  (registry-driven now).
- Drop the `EffectiveFeatureFlagsCompat.isOn` v1-enum extension.

The phases are independent — Phase 1 can sit on master indefinitely
without Phase 2 starting.

## Known gating gaps (carried over from `feature-flags.md`)

The audit during Phase 1 surfaced four features whose Settings tile
toggles do not actually gate their user-facing surface:

| Feature | What still needs gating |
| --- | --- |
| `consumptionAnalytics` | analytics card renders regardless |
| `priceAlerts` | alerts pipeline runs regardless |
| `priceHistory` | chart renders + snapshots get written regardless |
| `evCharging` | OCM fetch runs regardless |

These are NOT introduced by FM v2 — they're pre-existing gaps in v1.
The migration to v2 makes them easy to fix: wrap the relevant widget
in `FeatureGate(feature: kFeatureX, …)`. Tracked as Phase 2 work,
one PR per fix.

## Risks + alternatives considered

### Risk: const-class forward references
**Mitigation**: late-binding `parent: Function()` and
`requires: Function()` pattern; registry tests assert
the closure resolves to a registered FeatureClass at boot.

### Alternative: codegen registry (build_runner step that scans
files and emits a `featureRegistry` constant)
**Why rejected**: another build step in an already-slow pipeline
(riverpod_generator + freezed + json_serializable). Manual append-one-
line registration is fine for 20 features and gets us a clean import
graph (`feature_registry.dart` imports every feature module — easy to
audit).

### Alternative: collapse `parent` and `requires` into one field
**Why rejected**: explicit user requirement — the Settings tree
("Trajets is under Conso") can diverge from the activation cascade
("Trajets requires obd2TripRecording, which is at the top level").
Splitting the axes is what makes the model expressive enough.

### Alternative: D365's `IFeatureMetadata` interface
**Why rejected**: Dart doesn't have C#-style reflection. A const
class with declarative fields gets us the same readability with
better runtime characteristics (no reflection cost, no IL emitter).

## Open follow-ups (post Phase 1)

- `releasedIn: 'v5.3'` field for changelog / "what's new" generation.
- Wizard UI for beta features — preset bundles exclude betas, but
  Settings could grow a "show preview features" filter.
- Auto-generated `feature_management_section.dart` driven by registry
  (Phase 2 will pick this up incrementally).
- Per-FeatureClass `onEnable` / `onDisable` lifecycle hooks for
  features that need to initialize / tear down services (e.g.
  starting background scanners).
