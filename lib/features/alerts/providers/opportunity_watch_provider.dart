// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/opportunity_watch_store.dart';
import '../domain/opportunity.dart';

part 'opportunity_watch_provider.g.dart';

/// The kinds of opportunity the user wants to hear about (#4154).
///
/// A synchronous read of one already-open Hive row, like
/// [opportunityFeedProvider]. Defaults to every kind: an upgrade that
/// silently stopped alerting would be the bug #4149 warns about.
@riverpod
class OpportunityWatch extends _$OpportunityWatch {
  static const OpportunityWatchStore _store = OpportunityWatchStore();

  @override
  Set<OpportunityKind> build() => _store.read();

  /// Watch or stop watching one kind.
  Future<void> setWatched(OpportunityKind kind, {required bool watched}) async {
    state = await _store.toggle(kind, watched: watched);
  }
}
