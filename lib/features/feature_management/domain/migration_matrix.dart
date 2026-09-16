// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4227's migration matrix, as code rather than a document.
///
/// The issue asks for
/// `existing flag/setting → consumers → process → subprocess →
/// capability → dependencies → parameter owner → migration action`.
/// Most of those columns already exist and are enforced elsewhere:
/// ownership in [capabilityOwner], dependencies in the manifest's
/// `requires`, the non-`Feature` settings in [RegistryGap]. Writing the
/// matrix as a markdown table would duplicate all of it into something
/// that cannot be tested and rots on the first new capability.
///
/// So the matrix is *derived*, and this file adds only the column that
/// is genuinely new: what should HAPPEN to each item.
library;

import 'capability_ownership.dart';
import 'feature.dart';
import 'process_taxonomy.dart';
import 'registry_coverage.dart';

/// What #4227 says to do with an existing setting.
enum MigrationAction {
  /// Already a registered capability with a process owner. Nothing to
  /// migrate — it arrives in the process model as-is.
  alreadyOwned,

  /// A user-facing setting with no `Feature`. Becomes a capability.
  promoteToCapability,

  /// A parameter of a capability that IS registered. The process model
  /// shows it under its owner (#4226 "parameters belong inside the
  /// process context"), not as a capability of its own.
  keepAsCapabilityParameter,

  /// Owned by the GDPR consent registry (#3865). Stays there; the
  /// process model links to it rather than copying it.
  deferToConsentModel,

  /// Internal state that must never become a user choice.
  keepInternal,
}

/// One row of the matrix.
class MigrationRow {
  const MigrationRow({
    required this.item,
    required this.action,
    this.feature,
    this.gap,
    this.subprocess,
  });

  /// What the user (or the code) calls it today.
  final String item;

  final MigrationAction action;

  /// Set when the item is a registered capability.
  final Feature? feature;

  /// Set when the item is one of the out-of-registry settings.
  final RegistryGap? gap;

  /// Where it lands in the process model. Null only for items that
  /// stay outside it ([MigrationAction.deferToConsentModel],
  /// [MigrationAction.keepInternal]).
  final SparkiloSubprocess? subprocess;

  SparkiloProcess? get process => subprocess?.owner;
}

/// Every registered capability, with its owner — the bulk of the matrix,
/// derived so it can never disagree with [capabilityOwner].
Iterable<MigrationRow> get registeredRows => Feature.values.map(
      (f) => MigrationRow(
        item: f.name,
        action: MigrationAction.alreadyOwned,
        feature: f,
        subprocess: ownerOf(f),
      ),
    );

/// The out-of-registry settings, with the action their classification
/// implies. The mapping is total by construction: adding a
/// [GapClassification] without an action is a compile error.
Iterable<MigrationRow> get unregisteredRows => RegistryGap.values.map(
      (g) => MigrationRow(
        item: g.what,
        action: switch (g.classification) {
          GapClassification.unmappedUserCapability =>
            MigrationAction.promoteToCapability,
          GapClassification.capabilityParameter =>
            MigrationAction.keepAsCapabilityParameter,
          GapClassification.ownedByConsentModel =>
            MigrationAction.deferToConsentModel,
          GapClassification.internalImplementationState =>
            MigrationAction.keepInternal,
        },
        gap: g,
        subprocess: _subprocessForGap(g),
      ),
    );

/// Where an out-of-registry setting lands once migrated.
///
/// Null for the two classes that stay outside the process model.
SparkiloSubprocess? _subprocessForGap(RegistryGap gap) => switch (gap) {
      RegistryGap.evShowOnMap => SparkiloSubprocess.findCheaperEnergy,
      RegistryGap.autoSwitchProfile => SparkiloSubprocess.accountAndProfile,
      RegistryGap.radarAutoPin => SparkiloSubprocess.favouritesAndWatchAreas,
      RegistryGap.recordingProfile => SparkiloSubprocess.recordTrip,
      RegistryGap.searchDefaults => SparkiloSubprocess.findCheaperEnergy,
      RegistryGap.obd2DebugOverlay => null,
      RegistryGap.tileProxy => null,
      RegistryGap.remoteBrandLogos => null,
    };

/// The complete matrix.
Iterable<MigrationRow> get migrationMatrix =>
    [...registeredRows, ...unregisteredRows];

/// The rows that require work — #4227's actual backlog, as opposed to
/// the rows that merely record where something already lives.
Iterable<MigrationRow> get actionableRows => migrationMatrix
    .where((r) => r.action == MigrationAction.promoteToCapability);
