// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The manifest entries of the two fleet capabilities (#4212, Epic
/// #4211), kept out of `feature_manifest.dart` so registering a slice of
/// the fleet epic does not push that file past the 400-line cap.
///
/// Spread into [FeatureManifest.defaultManifest]; the registry stays
/// single — this file is a section of it, not a second one.
///
/// Both entries are **beta-only** on purpose (ADR 0025 D6, #4339 S11):
/// the manager dashboard does not exist yet, so production must not be
/// able to switch fleet mode on at all. Availability widens to
/// production in the slice that ships the dashboard, together with the
/// single privacy-policy bump.
library;

import 'build_channel.dart';
import 'feature.dart';
import 'feature_manifest_entry.dart';

/// Fleet capabilities, keyed by feature — merged into the default
/// manifest. `defaultEnabledChannels` is empty on both: opt-in even in
/// beta.
const Map<Feature, FeatureManifestEntry> fleetManifestEntries =
    <Feature, FeatureManifestEntry>{
  Feature.fleetMode: FeatureManifestEntry(
    feature: Feature.fleetMode,
    availableChannels: {BuildChannel.beta},
    requires: {Feature.tankSync},
    displayName: 'Fleet mode',
    description: 'Company-vehicle mode: your fleet assignment, the org '
        'vehicle directory, and an explicit current-vehicle switcher.',
  ),
  Feature.fleetManagerTools: FeatureManifestEntry(
    feature: Feature.fleetManagerTools,
    availableChannels: {BuildChannel.beta},
    requires: {Feature.fleetMode},
    displayName: 'Fleet manager tools',
    description: 'Aggregate fleet cost and efficiency views for a '
        'manager — totals and exceptions, never per-employee journeys.',
  ),
};
