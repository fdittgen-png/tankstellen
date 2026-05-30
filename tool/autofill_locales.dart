// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Auto-fills the 21 non-en/de shipped locales from `app_en.arb` (#2335).
//
// Problem this solves
// -------------------
// `app_en.arb` + `app_de.arb` are the human source of truth — built from
// `lib/l10n/_fragments/` by `tool/build_arb.dart`. The other 21 shipped
// locales (`app_<locale>.arb`) used to be hand-maintained: every new ARB
// key had to be copied into 21 standalone files in a bulk follow-up
// commit, or the `#1699` completeness gate
// (`test/l10n/localization_completeness_test.dart`, which requires every
// locale to hold 100% of `app_en.arb`'s keys) would fail CI. That
// two-step pattern repeatedly tripped the gate and guaranteed ARB
// fan-out merge conflicts.
//
// What this does
// --------------
// For each of the 21 other shipped locales, it diffs `app_en.arb` against
// the locale file and INJECTS any translatable key that is present in
// English but MISSING in that locale, using the English value as a
// machine-translation placeholder (English fallback beats a runtime
// crash / a tripped gate). Each injected key carries a findable marker so
// translators can locate machine-filled entries:
//
//   "@<key>": { "x-mt": "needs-native-review", "description": "$marker" }
//
// (any placeholder metadata the English `@<key>` block carries is merged
// in too, so ICU `plural` / `select` / `{placeholder}` skeletons still
// parse under `flutter gen-l10n`).
//
// Guarantees
// ----------
//   * EXISTING human translations are never overwritten or reordered — a
//     key already present in a locale is left exactly where it is, value
//     and `@key` metadata untouched. Append-only: missing keys land at the
//     END of the file in template order, mirroring the old manual fixups,
//     so an already-complete locale is rewritten byte-identical (a no-op)
//     and a locale with gaps gets the smallest possible diff.
//   * Idempotent + deterministic: re-running produces the same bytes, so
//     it is safe in CI and pre-push (`git diff --exit-code` stays clean).
//   * `@@locale` is preserved; stray locale-only keys that no longer
//     exist in English are dropped (keeps the fan-out a strict subset).
//
// Usage:
//   dart run tool/autofill_locales.dart         # fill all 21
//   dart run tool/autofill_locales.dart --check # exit 1 if any would change
//
// Normally invoked transitively by `dart run tool/build_arb.dart`, which
// owns the en/de source-of-truth merge and then calls this to fan out.

import 'dart:convert';
import 'dart:io';

const String l10nDir = 'lib/l10n';

/// The English template every other locale is filled from.
const String templateLocale = 'en';

/// The two human-authored source locales. They are produced by
/// `tool/build_arb.dart` from fragments and are NEVER autofilled here.
const Set<String> sourceLocales = <String>{'en', 'de'};

/// The synthetic text-expansion pseudo-locale. Generated separately by
/// `tool/gen_pseudo_arb.dart`; this tool must not touch it.
const String pseudoLocale = 'en_XA';

/// Marker stamped into the `@<key>` metadata of every machine-filled
/// entry so translators (and a grep) can find entries awaiting a native
/// review. Stable — changing it would churn every locale file once.
const String mtMarkerField = 'x-mt';
const String mtMarkerValue = 'needs-native-review';
const String mtDescription = 'MT — needs native review';

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final root = Directory(l10nDir);
  if (!root.existsSync()) {
    stderr.writeln('ERROR: $l10nDir not found — run from the repo root.');
    exit(1);
  }

  final template = _loadArb(File('$l10nDir/app_$templateLocale.arb'));
  // Translatable keys in template order (skip @@locale + @key metadata).
  final templateKeys = template.keys
      .where((k) => !k.startsWith('@'))
      .toList(growable: false);

  final targets = _discoverTargets(root);
  var changed = 0;
  var filledTotal = 0;

  for (final file in targets) {
    final result = _autofillLocale(
      file: file,
      template: template,
      templateKeys: templateKeys,
      checkOnly: checkOnly,
    );
    filledTotal += result.filled;
    if (result.changed) {
      changed++;
      final locale = _localeOf(file);
      if (checkOnly) {
        stderr.writeln(
          '  WOULD CHANGE app_$locale.arb '
          '(${result.filled} key(s) to machine-fill)',
        );
      } else {
        stdout.writeln(
          '  wrote app_$locale.arb '
          '(machine-filled ${result.filled} key(s) from $templateLocale)',
        );
      }
    }
  }

  if (checkOnly) {
    if (changed > 0) {
      stderr.writeln(
        'autofill_locales --check: $changed locale file(s) out of date. '
        'Run `dart run tool/build_arb.dart` and commit.',
      );
      exit(1);
    }
    stdout.writeln('autofill_locales --check: all ${targets.length} '
        'locale(s) complete and idempotent.');
    return;
  }

  stdout.writeln(
    'autofill_locales: ${targets.length} locale(s) processed, '
    '$filledTotal key(s) machine-filled, $changed file(s) rewritten.',
  );
}

/// The 21 shipped locales that get auto-filled — every `app_<locale>.arb`
/// that is not a source locale and not the pseudo-locale. Sorted for
/// deterministic processing order.
List<File> _discoverTargets(Directory root) {
  final files = root
      .listSync()
      .whereType<File>()
      .where((f) {
        final name = f.uri.pathSegments.last;
        if (!name.startsWith('app_') || !name.endsWith('.arb')) return false;
        final locale = _localeOf(f);
        if (sourceLocales.contains(locale)) return false;
        if (locale == pseudoLocale) return false;
        return true;
      })
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

class _FillResult {
  const _FillResult({required this.changed, required this.filled});
  final bool changed;
  final int filled;
}

/// Brings a single locale ARB up to 100% of the template — APPEND-ONLY so
/// an already-complete locale is left byte-identical (a true no-op):
///   * `@@locale` stays first;
///   * every existing entry keeps its exact current position (human
///     translations and their `@key` metadata are never reordered or
///     overwritten) — except an entry whose underlying key no longer
///     exists in the template, which is dropped (keeps the file a strict
///     subset of English, satisfying the parity gate);
///   * any template key the locale lacks is appended at the END, in
///     template order, machine-filled from English and marked for review.
/// Append-at-end mirrors the old manual bulk fixups, so diffs stay small
/// and the result is deterministic + idempotent.
_FillResult _autofillLocale({
  required File file,
  required Map<String, dynamic> template,
  required List<String> templateKeys,
  required bool checkOnly,
}) {
  final existing = _loadArb(file);
  final locale = _localeOf(file);

  final templateRealKeys = templateKeys.toSet();
  final existingRealKeys = existing.keys
      .where((k) => !k.startsWith('@'))
      .toSet();

  final out = <String, dynamic>{'@@locale': locale};

  // 1. Re-emit existing entries IN ORDER, dropping any whose key (or whose
  //    `@key`'s underlying key) no longer exists in the template.
  for (final entry in existing.entries) {
    final k = entry.key;
    if (k == '@@locale') continue; // already emitted first
    if (k.startsWith('@@')) {
      out[k] = entry.value; // preserve any other global metadata
      continue;
    }
    if (k.startsWith('@')) {
      final underlying = k.substring(1);
      if (templateRealKeys.contains(underlying)) out[k] = entry.value;
      continue;
    }
    if (templateRealKeys.contains(k)) out[k] = entry.value;
  }

  // 2. Append every template key the locale is missing, in template order.
  var filled = 0;
  for (final key in templateKeys) {
    if (existingRealKeys.contains(key)) continue;
    out[key] = template[key];
    out['@$key'] = _buildMarkerMeta(template['@$key']);
    filled++;
  }

  const encoder = JsonEncoder.withIndent('  ');
  final body = '${encoder.convert(out)}\n';
  final current = file.existsSync() ? file.readAsStringSync() : '';
  final changed = body != current;

  if (changed && !checkOnly) {
    file.writeAsStringSync(body);
  }
  return _FillResult(changed: changed, filled: filled);
}

/// Builds the `@<key>` metadata block for a machine-filled entry: the
/// findable MT marker, plus any placeholder/ICU metadata the English
/// template carries (so `flutter gen-l10n` still parses the value).
Map<String, dynamic> _buildMarkerMeta(dynamic templateMeta) {
  final meta = <String, dynamic>{
    mtMarkerField: mtMarkerValue,
    'description': mtDescription,
  };
  if (templateMeta is Map) {
    // Carry placeholders / type info forward; keep `description` as the
    // marker so the entry stays grep-able, but let real placeholder
    // metadata win for fields gen-l10n needs.
    for (final entry in templateMeta.entries) {
      final k = entry.key as String;
      if (k == 'description') continue; // keep our marker description
      meta[k] = entry.value;
    }
  }
  return meta;
}

Map<String, dynamic> _loadArb(File file) {
  if (!file.existsSync()) {
    stderr.writeln('ERROR: missing ARB file: ${file.path}');
    exit(1);
  }
  try {
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('ERROR: ${file.path} is not valid JSON: $e');
    exit(1);
  }
}

String _localeOf(File f) {
  final name = f.uri.pathSegments.last; // app_xx.arb
  return name.replaceFirst('app_', '').replaceFirst('.arb', '');
}
