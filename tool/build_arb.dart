// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Merges ARB fragment files into the canonical `app_<locale>.arb` templates.
//
// Rationale: during parallel-worker sessions, every worker appending new
// localization keys to `lib/l10n/app_en.arb` + `lib/l10n/app_de.arb`
// produces trivial-but-unavoidable merge conflicts at the end of the file.
// This script lets each feature keep its keys in its own fragment file
// (`lib/l10n/_fragments/<feature>_<locale>.arb`) — fragments never collide.
// A short post-merge step rebuilds the canonical ARB files that Flutter's
// gen-l10n consumes.
//
// After merging app_en / app_de this script also fans out to the 21 other
// shipped locales via `tool/autofill_locales.dart`, machine-filling any
// key they lack from English so the #1699 completeness gate can never be
// tripped by an en+de-only fragment addition (#2335).
//
// #4402 — a THIRD step, for locales that have hand-written fragments but
// are not rebuilt from scratch. Before it, 55 `_fragments/*_fr.arb` files
// existed and not one was read: `_locales` was a two-element list, so the
// documented three-command pipeline left a hand-written French value on
// disk and `app_fr.arb` holding whatever autofill had put there. The
// fold happened by hand, every time, and was written down nowhere. Now
// `_applyOverlayFragments` applies those fragments onto the already
// filled locale file — value wins, MT marker cleared — so the fragment
// is the source of truth for the keys it covers and the round trip is
// idempotent.
//
// Usage:
//   dart run tool/build_arb.dart
//   flutter gen-l10n   # consumes the merged files as before
//
// Rules:
//   * `_base_<locale>.arb` provides the `@@locale`/`@@author`/`@@last_modified`
//     header plus the canonical key ordering for everything that has not yet
//     been extracted into a feature fragment.
//   * `<feature>_<locale>.arb` fragments contain ONLY that feature's keys.
//     Fragments are merged in alphabetical order by feature filename,
//     producing a deterministic output.
//   * If the same key appears in two fragments for the same locale, the
//     script aborts with a clear error — rename one of the fragments'
//     keys to resolve.
//   * The generated `app_<locale>.arb` files are regular JSON with 2-space
//     indentation and a trailing newline. Humans MUST NOT edit them
//     directly — edit the fragments instead and rerun this script.
//   * A locale is handled in exactly ONE of two ways, and which one is an
//     explicit declaration, not an accident of a list nobody reads:
//       - [_sourceLocales] are REBUILT from `_base_<locale>.arb` + their
//         fragments. Everything not in a fragment is gone.
//       - every other locale is AUTOFILLED from English and then
//         OVERLAID with its fragments, if it has any. The rest of the
//         file — the hand-maintained majority — is left alone.
//     So adding `_fragments/<feature>_it.arb` starts overlaying Italian
//     with no code change, and `app_it.arb`'s other 3000 keys survive.

import 'dart:convert';
import 'dart:io';

import 'autofill_locales.dart' as autofill;

/// Locales rebuilt WHOLESALE from `_base_<locale>.arb` + their fragments.
/// Everything they ship must live in a fragment.
const List<String> _sourceLocales = <String>['en', 'de'];
const String _l10nDir = 'lib/l10n';
const String _fragmentsDir = 'lib/l10n/_fragments';

/// The metadata fields `autofill_locales.dart` stamps on a machine-filled
/// entry. A key a human has now translated must not keep claiming it
/// needs a native review, so the overlay strips exactly these.
const String _mtMarkerField = 'x-mt';
const String _mtDescription = 'MT — needs native review';

void main(List<String> args) {
  // 1. Merge the human source-of-truth fragments into app_en / app_de.
  for (final locale in _sourceLocales) {
    _buildLocale(locale);
  }
  stdout.writeln(
      'ARB fragments merged for locales: ${_sourceLocales.join(', ')}');

  // 2. Fan out app_en into the 21 other shipped locales, machine-filling
  //    any key they are missing (#2335). Skip with --no-autofill so a
  //    caller can stage the en/de merge in isolation if they need to.
  if (args.contains('--no-autofill')) {
    stdout.writeln('autofill skipped (--no-autofill).');
    return;
  }
  autofill.main(const <String>[]);

  // 3. #4402 — apply the fragments of every OTHER locale that has them.
  //    Must run after autofill: autofill re-emits the whole file, so an
  //    overlay written before it would be reverted.
  _applyOverlayFragments();
}

void _buildLocale(String locale) {
  final baseFile = File('$_fragmentsDir/_base_$locale.arb');
  if (!baseFile.existsSync()) {
    stderr.writeln('ERROR: missing base fragment: ${baseFile.path}');
    exit(1);
  }

  final merged = <String, dynamic>{};
  final keySource = <String, String>{};

  // 1. Base fragment — preserves canonical header + legacy key ordering.
  _mergeFragment(baseFile, merged, keySource);

  // 2. Feature fragments — deterministic (alphabetical) order.
  final featureFragments = _findFeatureFragments(locale);
  for (final fragment in featureFragments) {
    _mergeFragment(fragment, merged, keySource);
  }

  // 3. Write the merged output.
  final outFile = File('$_l10nDir/app_$locale.arb');
  const encoder = JsonEncoder.withIndent('  ');
  final body = encoder.convert(merged);
  outFile.writeAsStringSync('$body\n');
  stdout.writeln(
    '  wrote ${outFile.path} '
    '(${merged.length} entries, '
    '${featureFragments.length} feature fragment${featureFragments.length == 1 ? '' : 's'})',
  );
}

List<File> _findFeatureFragments(String locale) {
  final dir = Directory(_fragmentsDir);
  final suffix = '_$locale.arb';
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) {
        final name = f.uri.pathSegments.last;
        // Skip the base fragment — already merged first.
        if (name.startsWith('_base_')) return false;
        return name.endsWith(suffix);
      })
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

void _mergeFragment(
  File file,
  Map<String, dynamic> merged,
  Map<String, String> keySource,
) {
  final raw = file.readAsStringSync();
  final Map<String, dynamic> parsed;
  try {
    parsed = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('ERROR: ${file.path} is not valid JSON: $e');
    exit(1);
  }

  final fragmentName = file.uri.pathSegments.last;
  for (final entry in parsed.entries) {
    if (merged.containsKey(entry.key)) {
      final prior = keySource[entry.key] ?? '(unknown)';
      stderr.writeln(
        'ERROR: duplicate ARB key `${entry.key}` in both '
        '`$prior` and `$fragmentName` — rename one.',
      );
      exit(1);
    }
    merged[entry.key] = entry.value;
    keySource[entry.key] = fragmentName;
  }
}

/// #4402 — applies `_fragments/*_<locale>.arb` onto an already-autofilled
/// `app_<locale>.arb`, for every locale that is not rebuilt from scratch.
///
/// The fragment is the source of truth for the keys it names and for
/// nothing else: the value is replaced in place (no reordering, so the
/// diff is exactly the keys that moved), and the entry stops advertising
/// itself as machine-filled. Keys the fragment does not mention keep
/// whatever `app_<locale>.arb` already held — that file carries thousands
/// of hand-maintained translations that were never fragmented, and
/// rebuilding it from fragments would delete them.
void _applyOverlayFragments() {
  final locales = _overlayLocales();
  if (locales.isEmpty) return;
  for (final locale in locales) {
    _applyOverlayFragment(locale);
  }
}

/// Every locale with at least one fragment that is not a source locale.
/// Derived from what is on disk, so a new locale's fragments are picked
/// up the moment they exist.
List<String> _overlayLocales() {
  final seen = <String>{};
  final re = RegExp(r'^(?!_base_).+_([A-Za-z]{2}(?:_[A-Za-z]+)?)\.arb$');
  for (final f in Directory(_fragmentsDir).listSync().whereType<File>()) {
    final match = re.firstMatch(f.uri.pathSegments.last);
    if (match == null) continue;
    final locale = match.group(1)!;
    if (_sourceLocales.contains(locale)) continue;
    seen.add(locale);
  }
  return seen.toList()..sort();
}

void _applyOverlayFragment(String locale) {
  final target = File('$_l10nDir/app_$locale.arb');
  if (!target.existsSync()) {
    stderr.writeln('ERROR: fragments exist for `$locale` but '
        '${target.path} does not — add the locale file first.');
    exit(1);
  }
  // English is the key universe: autofill drops any key the template does
  // not have, so a fragment key unknown to English would be written here
  // and silently deleted on the next run. Fail loudly instead.
  final template = jsonDecode(
      File('$_l10nDir/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

  final overlay = <String, dynamic>{};
  final keySource = <String, String>{};
  for (final fragment in _findFeatureFragments(locale)) {
    _mergeFragment(fragment, overlay, keySource);
  }
  if (overlay.isEmpty) return;

  final current =
      jsonDecode(target.readAsStringSync()) as Map<String, dynamic>;
  final unknown = overlay.keys
      .where((k) => !k.startsWith('@'))
      .where((k) => !template.containsKey(k))
      .toList()
    ..sort();
  if (unknown.isNotEmpty) {
    stderr.writeln('ERROR: ${unknown.length} key(s) in the `$locale` '
        'fragments do not exist in app_en.arb, so they would be dropped:');
    for (final k in unknown) {
      stderr.writeln('  - $k (${keySource[k]})');
    }
    exit(1);
  }

  var applied = 0;
  final out = <String, dynamic>{};
  for (final entry in current.entries) {
    final key = entry.key;
    if (key.startsWith('@@')) {
      out[key] = entry.value;
      continue;
    }
    if (key.startsWith('@')) {
      final underlying = key.substring(1);
      if (!overlay.containsKey(key) && !overlay.containsKey(underlying)) {
        out[key] = entry.value;
        continue;
      }
      final merged = _mergeMeta(entry.value, overlay[key]);
      // An entry whose only metadata WAS the machine-fill claim keeps no
      // empty block — `"@key": {}` is churn, not information.
      if (merged is Map && merged.isEmpty) continue;
      out[key] = merged;
      continue;
    }
    if (overlay.containsKey(key)) {
      if (entry.value != overlay[key]) applied++;
      out[key] = overlay[key];
      // A fragment value with no `@key` in the target still needs the
      // fragment's own metadata carried over — the branch above only
      // runs for blocks that already exist.
      if (!current.containsKey('@$key') && overlay.containsKey('@$key')) {
        out['@$key'] = overlay['@$key'];
      }
      continue;
    }
    out[key] = entry.value;
  }

  const encoder = JsonEncoder.withIndent('  ');
  final body = '${encoder.convert(out)}\n';
  final changed = body != target.readAsStringSync();
  if (changed) target.writeAsStringSync(body);
  stdout.writeln(
    '  overlaid app_$locale.arb from '
    '${_findFeatureFragments(locale).length} fragment(s): '
    '${overlay.keys.where((k) => !k.startsWith('@')).length} key(s) owned, '
    '$applied value(s) changed${changed ? '' : ' (no-op)'}',
  );
}

/// The `@key` block for an overlaid entry: what the target already had,
/// minus the machine-fill claim, plus whatever the fragment declares.
///
/// A key a human has now translated must stop advertising that it needs a
/// native review, so `x-mt` and the autofill description go. Everything
/// else the target carried stays — placeholder and ICU metadata is what
/// `gen-l10n` parses the value with, and losing it is a build failure,
/// not a cosmetic diff. The fragment overrides field by field rather than
/// replacing the block, so a fragment that declares only `placeholders`
/// cannot silently delete a `description` it never mentioned.
dynamic _mergeMeta(dynamic existing, dynamic fromFragment) {
  if (existing is! Map && fromFragment == null) return existing;
  final out = <String, dynamic>{};
  if (existing is Map) {
    for (final entry in existing.entries) {
      final k = entry.key as String;
      if (k == _mtMarkerField) continue;
      if (k == 'description' && entry.value == _mtDescription) continue;
      out[k] = entry.value;
    }
  }
  if (fromFragment is Map) {
    for (final entry in fromFragment.entries) {
      out[entry.key as String] = entry.value;
    }
  }
  return out;
}
