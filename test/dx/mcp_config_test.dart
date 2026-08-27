// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3810 — the repo-scoped MCP server config. These tests exist because
// two of its properties are load-bearing and silently breakable:
// the formatter exclusion (dropping it lets a mass tall-style rewrite
// through, with no format gate to catch it) and the documentation link
// (an undocumented server is one nobody can repair when it stops
// starting).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> servers;

  setUpAll(() {
    final raw = File('.mcp.json').readAsStringSync();
    servers = ((jsonDecode(raw) as Map)['mcpServers'] as Map)
        .cast<String, dynamic>();
  });

  test('.mcp.json is valid JSON and declares the expected servers', () {
    expect(servers.keys.toSet(), {'dart', 'adb', 'ocr'});
  });

  group('the dart server never formats this repo', () {
    // 2026-08-25: the SDK's tall-style formatter rewrote 20 files and
    // turned a ~700-line diff into 2 656. This repo is short-style and
    // has NO format gate, so the exclusion is the only thing stopping a
    // repeat.
    test('dart_format and dart_fix are excluded', () {
      final args = (servers['dart']['args'] as List).cast<String>();
      for (final tool in ['dart_format', 'dart_fix']) {
        final i = args.indexOf('--exclude-tool');
        expect(args, contains(tool),
            reason: '$tool must stay excluded — the tall-style formatter '
                'rewrites this short-style repo wholesale and nothing '
                'else would catch it');
        expect(i, isNot(-1));
      }
      // Every exclusion must be introduced by its own flag, or the
      // extra name is silently read as a positional argument.
      final flags = args.where((a) => a == '--exclude-tool').length;
      final excluded = ['dart_format', 'dart_fix']
          .where(args.contains)
          .length;
      expect(flags, greaterThanOrEqualTo(excluded));
    });

    test('it runs the globally-activated pub build, not the SDK-bundled one',
        () {
      // Changed deliberately from `dart mcp-server` (SDK-bundled 0.1.4).
      // The pub build is a strict superset — same 13 tools plus
      // `vm_service` — and needs Dart >= 3.12, which #3801 provides.
      // `pub global` resolves independently, so unlike a dev dependency it
      // cannot disturb this project's own dependency graph.
      expect(servers['dart']['command'], 'dart');
      expect((servers['dart']['args'] as List).take(4).toList(),
          ['pub', 'global', 'run', 'dart_mcp_server']);
    });
  });

  test('the adb server can find adb — it is NOT on the login PATH here',
      () {
    final env = (servers['adb']['env'] as Map).cast<String, String>();
    expect(env['PATH'], contains('platform-tools'),
        reason: 'without platform-tools on PATH every adb tool fails at '
            'runtime, long after the config looked fine');
    expect(env, contains('ANDROID_HOME'));
  });

  test('no absolute home path is hard-coded — \${HOME} keeps it portable',
      () {
    final raw = File('.mcp.json').readAsStringSync();
    expect(raw, isNot(contains('/Users/')),
        reason: 'a committed config with one machine\'s home directory '
            'breaks for every other checkout');
  });

  // `docs/guides/*` is deny-by-default with an explicit allowlist, so a new
  // guide is invisible to git while sitting happily on the author's disk:
  // every file-exists assertion passes locally and the same test dies on a
  // fresh CI checkout. Ask git directly instead of trusting the filesystem.
  test('the guide is actually TRACKED, not just present on this disk', () {
    const path = 'docs/guides/mcp-servers.md';
    final ignored = Process.runSync('git', ['check-ignore', path]);
    expect(ignored.exitCode, isNot(0),
        reason: '$path matches a .gitignore rule (docs/guides/* is '
            'deny-by-default) — add `!$path` to the allowlist, or CI '
            'checks out a tree without it');
    final tracked = Process.runSync('git', ['ls-files', '--error-unmatch', path]);
    expect(tracked.exitCode, 0,
        reason: '$path is un-ignored but was never committed');
  });

  test('every server is documented, with its rationale', () {
    final doc = File('docs/guides/mcp-servers.md').readAsStringSync();
    for (final name in servers.keys) {
      expect(doc, contains('`$name`'),
          reason: 'an undocumented server is one nobody can repair when '
              'it stops starting');
    }
    expect(doc, contains('dart_format'),
        reason: 'the formatter exclusion is the least obvious decision '
            'here — it must be explained, not just enforced');
  });

  // #3837 — the guide previously claimed 27 tools and named eight that the
  // configured server does not have, because it was written from an upstream
  // README rather than from a probe. A tool list without a version and a date
  // beside it cannot be checked for staleness, so it silently rots.
  test('the tool list records the version and date it was verified against',
      () {
    final doc = File('docs/guides/mcp-servers.md').readAsStringSync();
    // Must name the version of the server .mcp.json ACTUALLY runs — the
    // guide once documented the SDK-bundled 0.1.4 while the config had
    // already moved to the pub build (#3837 follow-up).
    expect(doc, contains(RegExp(r'1\.1\.1')),
        reason: 'name the server version the list was probed from');
    expect(doc, contains(RegExp(r'20\d{2}-\d{2}-\d{2}')),
        reason: 'date it, so the next reader can judge staleness');
    // Tools upstream removed must not be LISTED AS AVAILABLE. Scoped to the
    // tool table on purpose: the prose legitimately says "there is no
    // `run_tests`", and a blunt whole-document ban would forbid warning the
    // reader about the very tool that misled them.
    final table = RegExp(r'\| Group \| Tools \|[\s\S]*?\n\n')
        .firstMatch(doc)
        ?.group(0);
    expect(table, isNotNull, reason: 'the tool table must exist to be checked');
    for (final gone in ['run_tests', 'get_widget_tree', 'launch_app']) {
      expect(table!.contains(gone), isFalse,
          reason: '$gone does not exist in the configured server; listing it '
              'in the tool table is how the previous version misled');
    }
  });
}
