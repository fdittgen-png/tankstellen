// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import '../logging/error_logger.dart';
import '../logging/app_log.dart';

/// Identity of the backend + account a piece of local sync state belongs
/// to (#4047).
///
/// ## Why local sync state needs an identity at all
///
/// Some sync state outlives a single session on purpose — a queued
/// deletion that could not be uploaded (#3123), or the ids this device
/// kept locally after a server-side wipe (#4046). Both are *intents*
/// recorded against a particular account on a particular backend.
///
/// Stored under one global key, they silently apply to whoever signs in
/// next. Favourites make that concrete: a favourite's id is the station
/// id, the SAME string for every user, so account A's queued delete of
/// station `de-12345` replays cleanly — and wrongly — under account B.
///
/// A context key is `<backend host>|<user id>`. Backend as well as user
/// because a self-hoster can point the app at a different Supabase
/// project with the same account id space, and neither half alone
/// separates those.
extension type const SyncContextKey(String value) {
  /// The context a transport is currently operating in. [backendUrl] may
  /// be null in tests and on the default hosted backend; it collapses to
  /// a stable placeholder rather than an empty string so a null backend
  /// and a backend literally named "" can never alias.
  factory SyncContextKey.of({required String? backendUrl, required String userId}) =>
      SyncContextKey('${_host(backendUrl)}|$userId');

  /// Host only — the full URL carries a scheme and sometimes a trailing
  /// slash, and neither distinguishes two projects.
  ///
  /// #4058 — accepts a BARE host as well as a URL. Production hands us
  /// `TankSyncClient.backendHost`, which is `uri.host` — no scheme — and
  /// `Uri.parse('abc.supabase.co').host` is `''` because a scheme-less
  /// string parses as a path. The first cut only handled URLs, so every
  /// production key collapsed to `|<userId>` and the backend half of the
  /// scoping was inert; the tests passed because they fed `https://…`.
  static String _host(String? url) {
    if (url == null || url.isEmpty) return '(default)';
    final parsed = Uri.tryParse(url)?.host;
    if (parsed != null && parsed.isNotEmpty) return parsed.toLowerCase();
    // Not a URL: take it as a host. Strip anything a hand-typed value
    // might carry that `uri.host` never would.
    final bare = url.toLowerCase().trim();
    final slash = bare.indexOf('/');
    return slash == -1 ? bare : bare.substring(0, slash);
  }

  /// Safe inside a JSON object key.
  String get asMapKey => value;
}

/// A `context → table → ids` map, persisted as JSON, with every read and
/// write scoped to one [SyncContextKey] (#4047).
///
/// Shared by the pending-deletion journal and the after-wipe retention
/// set: both are "ids that mean something to exactly one account on
/// exactly one backend", and both were previously global.
///
/// **Contract: no method throws.** These back resilience features; a
/// persistence fault must never derail the operation that recorded the
/// intent.
class ScopedIdSets {
  ScopedIdSets(this.load, this.persist);

  /// Injectable persistence seams so tests run in memory.
  final String? Function() load;
  final Future<void> Function(String json) persist;

  Map<String, Map<String, Set<String>>> _decode() {
    try {
      final raw = load();
      if (raw == null || raw.isEmpty) return {};
      final outer = jsonDecode(raw);
      if (outer is! Map) return {};
      return {
        for (final ctx in outer.entries)
          if (ctx.value is Map)
            ctx.key.toString(): {
              for (final tbl in (ctx.value as Map).entries)
                if (tbl.value is List)
                  tbl.key.toString(): {
                    for (final id in tbl.value as List) id.toString(),
                  },
            },
      };
    } catch (e, st) {
      // A malformed blob degrades to "nothing recorded" — the pre-#3123
      // fail-open behaviour — rather than taking the caller down. It is
      // still a fault worth seeing: it means recorded intents were lost.
      log.warn('ScopedIdSets: unreadable blob — treating as empty',
          tag: 'sync', error: e, stack: st, layer: ErrorLayer.sync);
      return {};
    }
  }

  /// Ids recorded for [table] in [context]. Empty on any fault.
  Set<String> idsFor(SyncContextKey context, String table) =>
      _decode()[context.asMapKey]?[table] ?? const {};

  /// Every table that has ids recorded in [context].
  Map<String, Set<String>> tablesFor(SyncContextKey context) =>
      _decode()[context.asMapKey] ?? const {};

  /// Record [ids] for [table] in [context]. Never throws.
  Future<void> add(
    SyncContextKey context,
    String table,
    Iterable<String> ids,
  ) async {
    if (ids.isEmpty) return;
    try {
      final all = _decode();
      final byTable = all.putIfAbsent(context.asMapKey, () => {});
      byTable.putIfAbsent(table, () => <String>{}).addAll(ids);
      await _write(all);
    } catch (e, st) {
      _swallow('add', table, e, st);
    }
  }

  /// Forget [ids] for [table] in [context]. Never throws.
  Future<void> remove(
    SyncContextKey context,
    String table,
    Iterable<String> ids,
  ) async {
    try {
      final all = _decode();
      final byTable = all[context.asMapKey];
      final set = byTable?[table];
      if (set == null) return;
      set.removeAll(ids);
      if (set.isEmpty) byTable!.remove(table);
      if (byTable != null && byTable.isEmpty) all.remove(context.asMapKey);
      await _write(all);
    } catch (e, st) {
      _swallow('remove', table, e, st);
    }
  }

  /// Drop everything recorded for [context] — used when an account is
  /// erased, so its intents do not outlive it.
  Future<void> clearContext(SyncContextKey context) async {
    try {
      final all = _decode()..remove(context.asMapKey);
      await _write(all);
    } catch (e, st) {
      _swallow('clearContext', '(all)', e, st);
    }
  }

  /// Contexts other than [keep] that still hold ids — the signal that a
  /// previous account left intents behind.
  Iterable<String> foreignContexts(SyncContextKey keep) =>
      _decode().keys.where((k) => k != keep.asMapKey);

  /// The class contract is "no method throws"; that is not a licence to
  /// lose the reason. Every swallow lands in the exportable log.
  void _swallow(String op, String table, Object e, StackTrace st) =>
      log.warn('ScopedIdSets.$op failed — intent not persisted',
          tag: 'sync',
          error: e,
          stack: st,
          layer: ErrorLayer.sync,
          context: {'table': table});

  Future<void> _write(Map<String, Map<String, Set<String>>> all) =>
      persist(jsonEncode({
        for (final ctx in all.entries)
          ctx.key: {
            for (final tbl in ctx.value.entries) tbl.key: tbl.value.toList(),
          },
      }));
}
