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

    test('it runs the SDK-bundled server, not a pinned copy', () {
      expect(servers['dart']['command'], 'dart');
      expect((servers['dart']['args'] as List).first, 'mcp-server');
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
}
