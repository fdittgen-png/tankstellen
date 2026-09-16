// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/storage/storage_keys.dart';
import 'feature.dart';
import 'feature_manifest.dart';

/// What the capability registry does NOT yet cover (#4224).
///
/// #4223's acceptance asks for a "registry coverage report [that] lists
/// unmapped existing feature flags/settings", because the registry can
/// only be *the* source of truth once you can see what is outside it.
///
/// ## Measured, not asserted
///
/// The audit on #4224 listed six settings from memory. Checked against
/// master, two of them — the haptic eco-coach and baseline sync — DO
/// have `Feature` values (`Feature.hapticEcoCoach`, `Feature.baselineSync`)
/// and are registered; their `StorageKeys` entries survive only as
/// migration sources in `legacy_toggle_migrator.dart`. The list below is
/// what actually has no `Feature` behind it.
///
/// Each entry says what it is and why it is outside, because "unmapped"
/// alone would invite someone to mechanically add 8 enum values — and
/// three of these should never become user-facing capabilities.
enum RegistryGap {
  /// A developer diagnostic, not a capability. Belongs behind debug
  /// mode, never in the process taxonomy.
  obd2DebugOverlay(
    key: StorageKeys.obd2DebugOverlayEnabled,
    what: 'OBD2 debug overlay',
    classification: GapClassification.internalImplementationState,
  ),

  /// A per-screen UI preference (#2785): "always pin when the radar
  /// starts". A parameter of the radar capability, not a capability.
  radarAutoPin(
    key: StorageKeys.radarAutoPin,
    what: 'Radar auto-pin',
    classification: GapClassification.capabilityParameter,
  ),

  /// Privacy plumbing: whether map tiles route through the proxy.
  /// Owned by the privacy consent model, which is its own registry
  /// (#3865) — deliberately not duplicated here.
  tileProxy(
    key: StorageKeys.tileProxyEnabled,
    what: 'Tile proxy',
    classification: GapClassification.ownedByConsentModel,
  ),

  /// Same: whether brand logos are fetched remotely.
  remoteBrandLogos(
    key: StorageKeys.remoteBrandLogos,
    what: 'Remote brand logos',
    classification: GapClassification.ownedByConsentModel,
  ),

  /// A real user-facing capability with no registry entry: show EV
  /// charge points on the map. The clearest candidate to migrate.
  evShowOnMap(
    key: StorageKeys.evShowOnMap,
    what: 'Show charge points on the map',
    classification: GapClassification.unmappedUserCapability,
  ),

  /// Automatic profile switching. User-facing, unmapped.
  autoSwitchProfile(
    key: StorageKeys.autoSwitchProfile,
    what: 'Switch profile automatically',
    classification: GapClassification.unmappedUserCapability,
  ),

  /// Which recording profile a trip uses. A parameter of trip
  /// recording, whose capability (`Feature.obd2TripRecording`) IS
  /// registered.
  recordingProfile(
    key: StorageKeys.recordingProfile,
    what: 'Recording profile',
    classification: GapClassification.capabilityParameter,
  ),

  /// The saved search defaults (#2592). Parameters of the search
  /// capability — and the surface #4138 turns into named intents.
  searchDefaults(
    key: StorageKeys.defaultOpenOnly,
    what: 'Saved search defaults',
    classification: GapClassification.capabilityParameter,
  );

  const RegistryGap({
    required this.key,
    required this.what,
    required this.classification,
  });

  /// The `StorageKeys` constant this setting persists under.
  final String key;

  /// What the user would call it.
  ///
  /// Deliberately a plain literal, not an ARB key: this is a developer
  /// report about registry coverage, never rendered to a user. HARD
  /// RULE #1's lint keys on widget sinks (`Text(`, `Semantics(`) and
  /// correctly ignores it — do not "fix" these into localisations.
  final String what;

  final GapClassification classification;
}

/// Why a setting is outside the registry — the distinction #4224's rule
/// "technical capabilities are not exposed as primary user choices"
/// depends on.
enum GapClassification {
  /// Not a capability at all; internal state. Stays out.
  internalImplementationState,

  /// A parameter OWNED BY a registered capability. The registry models
  /// it as `owned parameters` of that capability, not as its own entry.
  capabilityParameter,

  /// Governed by the GDPR consent registry (#3865), which is a separate
  /// source of truth on purpose.
  ownedByConsentModel,

  /// A genuine user-facing capability with no `Feature`. These are the
  /// migration backlog.
  unmappedUserCapability,
}

/// The gaps that should become registry entries — the actual backlog.
Iterable<RegistryGap> get unmappedUserCapabilities => RegistryGap.values
    .where((g) => g.classification == GapClassification.unmappedUserCapability);

/// Every [Feature] the manifest declares, as the report's other half:
/// coverage is only meaningful beside what IS covered.
int registeredCapabilityCount(FeatureManifest manifest) =>
    manifest.entries.length;

/// True when every [Feature] value has a manifest entry — the registry's
/// own completeness, distinct from the gaps above.
bool registryIsComplete(FeatureManifest manifest) =>
    Feature.values.every(manifest.entries.containsKey);
