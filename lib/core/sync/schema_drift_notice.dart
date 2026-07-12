// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// #3560 — session-scoped record of synced tables whose server schema
/// rejected our columns/tables (a self-hoster on an outdated TankSync
/// schema).
///
/// `EntitySync.merge` notes a table here instead of ERROR-logging the
/// same PostgrestException on every sync run (three days of field logs
/// were >80% this one condition), and the TankSync settings section
/// watches [tables] to render the "schema outdated — re-run the wizard
/// SQL" warning tile. Deliberately NOT persisted: a re-run of the wizard
/// SQL fixes the server, and the next app session starts clean.
class SchemaDriftNotice {
  SchemaDriftNotice._();

  static final SchemaDriftNotice instance = SchemaDriftNotice._();

  /// Synced table names that hit a schema-drift failure this session.
  final ValueNotifier<Set<String>> tables = ValueNotifier(const <String>{});

  /// Note a drift on [table]. Returns true the FIRST time this session
  /// (callers use it to emit their one actionable breadcrumb), false on
  /// repeats so the log stays quiet.
  bool note(String table) {
    if (tables.value.contains(table)) return false;
    tables.value = {...tables.value, table};
    return true;
  }

  /// Test seam — reset between tests.
  @visibleForTesting
  void reset() => tables.value = const <String>{};
}

/// #3560 — whether [error] is the outdated-self-host-schema signature: the
/// server rejecting a column (42703 / PGRST204) or a whole table (42P01 /
/// PGRST205) that a newer app schema version added. String-matched (the
/// sync layer sees the exception through the transport, mirroring the
/// #3331 deletions-absent detection).
bool isSchemaDriftError(Object error) {
  final message = error.toString();
  if (message.contains('42703') || message.contains('PGRST204')) {
    // Undefined column — but only when the server names one, so an
    // unrelated error embedding the code string can't false-match.
    return message.toLowerCase().contains('column');
  }
  if (message.contains('42P01') || message.contains('PGRST205')) {
    return message.toLowerCase().contains('table') ||
        message.toLowerCase().contains('relation');
  }
  return false;
}
