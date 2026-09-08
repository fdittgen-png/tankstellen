// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4007 — compiles the wiki into the app.
//
// `docs/wiki/User-<lang>-*.md` is the source of truth for the user
// guide. This turns each language's pages into one bundled document
// (`assets/help/<lang>.md`) plus the anchor map the help screen scrolls
// with (`assets/help/<lang>.anchors.json`).
//
// Why compile rather than ship the pages as they are: a wiki page is
// written for GitHub — it links sibling pages by name, it embeds images
// from `guide/`, and it opens with a language switcher that means
// nothing inside the app. The compiler keeps the prose and drops the
// scaffolding.
//
// Run it after editing any page, and commit what it writes: the assets
// are generated, and the clean-codegen rule covers them.
import 'dart:convert';
import 'dart:io';

/// The languages the wiki carries. Everything else — the app speaks 23 —
/// falls back to English, which is what a reader gets on GitHub today.
const languages = ['da', 'de', 'en', 'es', 'fr', 'it', 'pt'];

/// The pages, in reading order. A language compiles the pages it HAS: a
/// page added in English and not yet translated joins the English bundle
/// and waits, rather than mixing two languages in one document.
const pages = <String>[
  'Home',
  'Getting-Started',
  'How-It-Works',
  'Finding-Stations',
  'Route-Planning',
  'EV-Charging',
  'Favorites-And-Alerts',
  'Price-History-And-Predictions',
  'Fuel-And-Consumption',
  'Consumption-And-OBD2',
  'Vehicles-And-OBD2',
  'Trips-And-Coaching',
  'Privacy-Profiles-Sync',
  'Settings-Reference',
  'Troubleshooting-FAQ',
];

const wikiDir = 'docs/wiki';
const outDir = 'assets/help';

/// `<!-- anchor: search.criteria.radius -->` on the line above a
/// heading. An HTML comment renders as nothing on GitHub and as nothing
/// in the app, so one source serves the wiki and the bundled guide.
final anchorComment =
    RegExp(r'<!--\s*anchor:\s*([a-z][a-z0-9]*(?:\.[a-z0-9-]+)+)\s*-->');

/// `<img src="guide/x.jpg" width="240">` — the wiki keeps its images;
/// the bundle drops them rather than growing the APK by 27 MB.
final htmlImg = RegExp(r'<img\s+src="(?:guide|screenshots)/[^"]+"[^>]*>');

/// `[Label](User-en-Finding-Stations)` and `[Label](User-en-X#heading)` —
/// a wiki page link. Inside the bundle every page is one document, so
/// the label survives and the link does not.
final wikiLink =
    RegExp(r'\[([^\]]+)\]\((?![a-z]+://)User-[a-z]{2}-[A-Za-z0-9-]+(?:#[^)]*)?\)');

/// anchor → the text of the heading it names, in this page's language.
Map<String, String> anchorsOf(String source) {
  final anchors = <String, String>{};
  final lines = source.split('\n');
  for (var i = 0; i < lines.length - 1; i++) {
    final match = anchorComment.firstMatch(lines[i]);
    if (match == null) continue;
    // The heading it names is the next non-empty line, and it must be
    // one: an anchor floating above a paragraph names nothing.
    var j = i + 1;
    while (j < lines.length && lines[j].trim().isEmpty) {
      j++;
    }
    if (j >= lines.length || !lines[j].startsWith('#')) continue;
    anchors[match.group(1)!] =
        lines[j].replaceFirst(RegExp(r'^#+\s*'), '').trim();
  }
  return anchors;
}

String compile(String source) {
  var text = source;

  // The anchors are lifted into their own asset; the text loses them.
  text = text.replaceAll(anchorComment, '');

  // Images stay in the wiki. A `<p>` that held only an image is now an
  // empty shell, and the caption under it read as a label for something
  // that is no longer there.
  text = text.replaceAll(htmlImg, '');
  text = text.replaceAll(RegExp(r'</?p[^>]*>'), '');

  // Wiki-internal page links: keep the label, lose the dead link.
  text = text.replaceAllMapped(wikiLink, (m) => m[1]!);

  // The language switcher line, which is a wiki affordance only.
  text = text.replaceAll(
      RegExp(r'^\s*\*?\s*(?:🌍|Languages?:).*$', multiLine: true), '');

  // Collapse the blank-line runs the removals leave behind.
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return '${text.trim()}\n';
}

void main() {
  Directory(outDir).createSync(recursive: true);
  final english = <String, String>{};

  for (final language in languages) {
    final sources = pages
        .map((page) => File('$wikiDir/User-$language-$page.md'))
        .where((f) => f.existsSync())
        .toList();
    if (sources.isEmpty) {
      stderr.writeln('No user guide for $language in $wikiDir');
      exitCode = 1;
      return;
    }
    final raw = sources.map((f) => f.readAsStringSync()).join('\n\n---\n\n');
    File('$outDir/$language.md').writeAsStringSync(compile(raw));
    final anchors = anchorsOf(raw);
    if (language == 'en') english.addAll(anchors);
    File('$outDir/$language.anchors.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(anchors)}\n');
    stdout.writeln('wrote $outDir/$language.md — ${sources.length} page(s), '
        '${anchors.length} anchors');
  }

  // A language that carries a page but not its anchors is the failure
  // this reports: the symbol would resolve in English and land nowhere
  // for that reader.
  for (final language in languages) {
    if (language == 'en') continue;
    final theirs = jsonDecode(
        File('$outDir/$language.anchors.json').readAsStringSync()) as Map;
    final missing = english.keys.where((a) => !theirs.containsKey(a)).toList();
    if (missing.isNotEmpty) {
      stdout.writeln('  $language is missing ${missing.length} anchor(s): '
          '${missing.take(5).join(', ')}${missing.length > 5 ? '…' : ''}');
    }
  }
}
