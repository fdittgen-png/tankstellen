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

import 'dart:convert';
import 'dart:io';

const List<String> _locales = <String>['en', 'de'];
const String _l10nDir = 'lib/l10n';
const String _fragmentsDir = 'lib/l10n/_fragments';

void main(List<String> args) {
  for (final locale in _locales) {
    _buildLocale(locale);
  }
  stdout.writeln('ARB fragments merged for locales: ${_locales.join(', ')}');
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
