import 'package:flutter/widgets.dart';

/// Maturity stage of a [FeatureClass].
///
/// Drives a "BETA" badge on the Settings tile and informs the preset
/// profile bundles — beta features are never auto-enabled by a wizard
/// preset; the user must opt in deliberately.
///
/// Graduating a feature is a code change: bump the const from
/// `FeatureMaturity.beta` to `FeatureMaturity.production`, possibly
/// flip `defaultEnabled` to `true`. The existing legacy-toggle
/// migration system preserves explicit user preferences, so promotion
/// never silently changes the state of users who already toggled.
enum FeatureMaturity {
  /// Engineering preview. Settings tile shows a "BETA" badge.
  /// Excluded from every preset profile bundle by default.
  beta,

  /// Production-ready. Preset bundles may include it.
  production,
}

/// Identifier of a top-level Settings section a [FeatureClass] can
/// register parameter UI into.
///
/// Kept as a closed enum (not a free-form string) so a typo at the
/// declaration site is a compile error rather than a silently-misfiled
/// tile. Add a new value whenever a new top-level Settings section
/// lands.
enum SettingsSection {
  /// Settings → Profile (user account, currency, language).
  profile,

  /// Settings → Location (GPS, postal code).
  location,

  /// Settings → TankSync (cross-device sync).
  tankSync,

  /// Settings → Theme (light / dark / system).
  theme,

  /// Settings → Consumption (the largest section — vehicles, fuel
  /// logs, OBD2, calibration, eco-coach, etc.).
  consumption,

  /// Settings → Storage & cache.
  storage,

  /// Settings → Search & map (visibility filters, unified results,
  /// route planning).
  search,

  /// Settings → About / diagnostics (telemetry consent, feedback PAT,
  /// version info).
  about,
}

/// Registration of a parameter / configuration UI block that a
/// [FeatureClass] contributes to a [SettingsSection].
///
/// The Settings screen iterates the [FeatureRegistry] for each
/// section, sorts the bindings by [order], and renders [builder] only
/// when the feature is effectively enabled. This is what couples the
/// "active surface" (whatever the feature renders on its main screen,
/// e.g. the Trajets tab inside the Conso screen) with the "parameter
/// surface" (the Trajets options inside Settings → Consumption): both
/// disappear when the feature toggles off, by construction.
@immutable
class ParameterBinding {
  final SettingsSection section;
  final WidgetBuilder builder;

  /// Sort key within the section. Lower values render first. Stable
  /// integers (10, 20, 30 …) leave gaps for future inserts.
  final int order;

  const ParameterBinding({
    required this.section,
    required this.builder,
    required this.order,
  });
}

/// Declarative description of a single application feature.
///
/// One `const FeatureClass` instance per feature, declared in the
/// feature's own module file (or in `known_features.dart` for the
/// legacy enum migration). The instance is the single source of
/// truth for:
/// - persistence id (stable across feature renames)
/// - presentation hierarchy ([parent]) — where the tile appears
///   inside the Settings tree
/// - activation dependencies ([requires]) — which other features
///   must be on for this one to be effectively enabled
/// - default state at first install
/// - maturity (beta / production)
/// - localized labels via [displayKey] / [descriptionKey] ARB lookup
/// - optional parameter UI bindings into Settings sections
///
/// `parent` vs `requires` deliberately split:
/// - `parent` is presentation-only. The Settings UI nests the tile
///   under its parent in the tree view. Two siblings under the same
///   parent render under the same group header.
/// - `requires` is activation-only. A feature with an unmet require
///   is *effectively disabled* even when its own bit is on, per
///   `isEffectivelyEnabled`. Disabling a parent cascades: children
///   stay stored-enabled but stop surfacing until the parent comes
///   back. Restoring the parent restores the children's prior state
///   without forcing the user to re-toggle.
///
/// They often point at the same feature (a child feature lives both
/// in its parent's Settings group AND requires the parent to be on),
/// but the two axes can diverge — e.g. a feature can be presented in
/// one section but require something declared in another.
@immutable
class FeatureClass {
  /// Stable persistence key. MUST match the existing enum value name
  /// for any feature that's migrating from the v1 `Feature` enum, so
  /// the Hive-backed flag set reads the same record. For new
  /// features, use camelCase matching the const name (drop `kFeature`
  /// prefix).
  final String id;

  /// Presentation parent — the feature this one nests under in the
  /// Settings tree view. `null` for top-level features.
  ///
  /// Late-bound via getter (rather than a direct `FeatureClass?`
  /// field) so two features can declare each other in the same const
  /// graph without Dart's const evaluator complaining about forward
  /// references.
  final FeatureClass? Function() _parent;
  FeatureClass? get parent => _parent();

  /// Activation prerequisites — features that must be on for this
  /// one to be effectively enabled.
  ///
  /// Same late-binding rationale as [parent].
  final Set<FeatureClass> Function() _requires;
  Set<FeatureClass> get requires => _requires();

  /// Initial state on a fresh install. The legacy-toggle migration
  /// preserves explicit user preferences across upgrades.
  final bool defaultEnabled;

  /// Maturity stage. `beta` features render a "BETA" badge in
  /// Settings and are excluded from every preset profile bundle.
  final FeatureMaturity maturity;

  /// ARB key for the user-facing display name.
  ///
  /// Convention: `feature_<id>_name`. The Settings tile uses
  /// `AppLocalizations` to resolve at render time; English fallback
  /// is the [displayName] field below.
  final String displayKey;

  /// English-fallback display name. Used when an ARB lookup misses
  /// (test fixtures, locale that hasn't been translated yet).
  final String displayName;

  /// ARB key for the user-facing description.
  ///
  /// Convention: `feature_<id>_description`. Same fallback pattern as
  /// [displayKey] → [description].
  final String descriptionKey;

  /// English-fallback description.
  final String description;

  /// Parameter UI bindings for this feature. Empty when the feature
  /// has no per-feature configuration (a pure on/off toggle).
  final List<ParameterBinding> parameterBuilders;

  const FeatureClass({
    required this.id,
    required FeatureClass? Function() parent,
    required Set<FeatureClass> Function() requires,
    required this.defaultEnabled,
    required this.maturity,
    required this.displayKey,
    required this.displayName,
    required this.descriptionKey,
    required this.description,
    this.parameterBuilders = const [],
  })  : _parent = parent,
        _requires = requires;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FeatureClass && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FeatureClass(id: $id)';
}
