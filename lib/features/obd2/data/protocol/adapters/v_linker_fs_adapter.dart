// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../elm327_adapter.dart';
import '../elm327_commands.dart';

/// vLinker FS-class adapter (e.g. FS-14884). Faster, cleaner ELM327
/// implementation; the base init sequence is reliable with shorter
/// delays than the generic profile (#1330 phase 2).
class VLinkerFsAdapter implements Elm327Adapter {
  const VLinkerFsAdapter();

  @override
  String get id => 'vlinker-fs';

  @override
  List<String> get initSequence => Elm327Commands.initCommands;

  // #2969 — bumped 200 ms → 1 s. Field evidence (the "OBD2 is a total mess"
  // report) is that the real vLinker FS-class hardware — especially the cheaper
  // clones that advertise the same name over Classic SPP — needs ≥1 s to
  // re-enumerate after ATZ before it will answer the next command; a 200 ms
  // settle raced the reset and produced the unresponsive-after-connect storm.
  // This is a once-per-connect cold-start cost, not a per-command one.
  @override
  Duration get postResetDelay => const Duration(seconds: 1);

  @override
  Duration get interCommandDelay => const Duration(milliseconds: 50);

  @override
  List<String> get extraInitCommands => const [];

  @override
  String preParse(String raw) => raw;

  // #2268 concern 1 — the vLinker FS is a fast, clean implementation that
  // answers the first command immediately; no standby compensation.
  @override
  WakePolicy get wakePolicy => const WakePolicy.noop();
}
