// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

/// Regenerates `docs/wiki/images.manifest` from a local clone of the wiki
/// repository (#4044).
///
/// The wiki markdown lives in this repo and its images live in
/// `github.com/fdittgen-png/tankstellen.wiki.git`. Nothing in this repo
/// could therefore check that a page points at an image that exists —
/// `wiki_parity_test` bailed out whenever the image folders were absent,
/// which here is always, so the check never ran.
///
/// The manifest is the hermetic stand-in: committed here, verified against
/// the real wiki whenever a clone is at hand.
///
/// ```
/// git clone https://github.com/fdittgen-png/tankstellen.wiki.git /tmp/wiki
/// dart run tool/wiki_image_manifest.dart --write --wiki=/tmp/wiki
/// ```
///
/// Without `--write` it reports drift and exits non-zero, which is what
/// the publish step should run.
const _manifestPath = 'docs/wiki/images.manifest';

/// Capture-pipeline state (`manifest.json`, `README.txt`) — not page images.
const _excludedPrefix = 'guide/_tooling/';

void main(List<String> args) {
  final wikiArg = args.firstWhere(
    (a) => a.startsWith('--wiki='),
    orElse: () => '--wiki=../tankstellen.wiki',
  );
  final wiki = Directory(wikiArg.substring('--wiki='.length));
  if (!wiki.existsSync()) {
    stderr.writeln('wiki clone not found: ${wiki.path}\n'
        'git clone https://github.com/fdittgen-png/tankstellen.wiki.git '
        '${wiki.path}');
    exit(2);
  }

  final found = <String>[];
  for (final folder in const ['guide', 'screenshots']) {
    final dir = Directory('${wiki.path}/$folder');
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final rel = entity.path
          .substring(wiki.path.length + 1)
          .replaceAll(r'\', '/');
      if (rel.startsWith(_excludedPrefix)) continue;
      found.add(rel);
    }
  }
  found.sort();

  final header = File(_manifestPath)
      .readAsLinesSync()
      .takeWhile((l) => l.startsWith('#'))
      .toList();
  final rendered = '${[...header, ...found].join('\n')}\n';
  final current = File(_manifestPath).readAsStringSync();

  if (rendered == current) {
    stdout.writeln('manifest is current (${found.length} images)');
    return;
  }
  if (!args.contains('--write')) {
    stderr.writeln('manifest is STALE — rerun with --write');
    exit(1);
  }
  File(_manifestPath).writeAsStringSync(rendered);
  stdout.writeln('manifest rewritten (${found.length} images)');
}
