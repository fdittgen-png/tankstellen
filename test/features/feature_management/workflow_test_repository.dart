// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

class WorkflowTestRepository implements FeatureFlagsRepository {
  WorkflowTestRepository(this.stored);
  Set<Feature> stored;
  int writes = 0;
  bool fail = false;

  @override
  bool get isEmpty => stored.isEmpty;
  @override
  Future<Set<Feature>> loadEnabled([
    BuildChannel channel = BuildChannel.production,
  ]) async => {...stored};
  @override
  Future<void> saveEnabled(Set<Feature> enabled) async {
    if (fail) throw Exception('fixture write failure');
    writes++;
    stored = {...enabled};
  }
}
