// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Promotes a captured OCR trace package to a committed regression test
// (#2519, Epic #2516 — the final child / "regression bridge").
//
// ## Why this exists
//
// ML Kit needs a platform channel and cannot run under `flutter test`, so
// a real pump / receipt failure can't be reproduced offline by re-running
// the recogniser. The gated OCR tester (#2518) instead BAKES the recognised
// blocks into a trace package (`<slug>.ocrpkg.json`, schema 1). This tool
// reads that package, rebuilds the `List<RecognizedTextBlock>` from
// `mlkit.blocks`, and GENERATES a pure-Dart regression test (a structural
// twin of `label_anchored_extractor_test.dart`) that replays those blocks
// through `extractByLabelAnchor` and asserts the package's `expected`
// totalCost / liters / pricePerLiter / derived. The generated test runs
// green in CI with no device.
//
// ## Usage
//
//   dart run tool/promote_ocr_fixture.dart <path/to/slug.ocrpkg.json>
//
// The package is expected to live under `test/fixtures/pump_displays/`
// (or a sibling receipt dir), next to its `<slug>.jpg` source image. The
// generated test is written to
// `test/features/consumption/data/ocr/fixtures/<slug>_fixture_test.dart`.
//
// Idempotent: re-running on the same package overwrites the generated
// test byte-for-byte (so it can be regenerated and the diff committed if
// the package or template changes).
//
// Pure Dart — no Flutter, no ML Kit. Runnable as `dart run` in CI.

import 'dart:convert';
import 'dart:io';

/// Directory the generated fixture tests land in (relative to repo root).
const String _generatedTestDir =
    'test/features/consumption/data/ocr/fixtures';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/promote_ocr_fixture.dart '
        '<path/to/slug.ocrpkg.json>');
    exitCode = 64; // EX_USAGE
    return;
  }
  final packagePath = args.single;
  final packageFile = File(packagePath);
  if (!packageFile.existsSync()) {
    stderr.writeln('error: package not found: $packagePath');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  final Map<String, dynamic> pkg;
  try {
    pkg = jsonDecode(packageFile.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    stderr.writeln('error: $packagePath is not valid JSON: ${e.message}');
    exitCode = 65; // EX_DATAERR
    return;
  }

  final report = generateFixtureTest(pkg: pkg, packagePath: packagePath);
  if (report.error != null) {
    stderr.writeln('error: ${report.error}');
    exitCode = 65;
    return;
  }

  final outDir = Directory(_generatedTestDir);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outFile = File('$_generatedTestDir/${report.slug}_fixture_test.dart');
  outFile.writeAsStringSync(report.source!);

  stdout.writeln('promoted ${report.slug} -> ${outFile.path}');
  stdout.writeln('  source image: ${report.imageRef ?? '(none committed)'}');
  stdout.writeln('  replay: extractByLabelAnchor(${report.blockCount} blocks, '
      'profile: ${report.country ?? 'null'})');
}

/// The outcome of a generation attempt — either an [error] or the
/// generated test [source] plus a few facts for the CLI banner. Returned
/// (rather than written directly) so a unit test can assert the output
/// without touching the filesystem.
class FixtureGenReport {
  final String? error;
  final String? source;
  final String slug;
  final String? country;
  final int blockCount;
  final String? imageRef;

  const FixtureGenReport.failure(this.error)
      : source = null,
        slug = '',
        country = null,
        blockCount = 0,
        imageRef = null;

  const FixtureGenReport.success({
    required this.source,
    required this.slug,
    required this.country,
    required this.blockCount,
    required this.imageRef,
  }) : error = null;
}

/// Builds the regression-test source for [pkg] (already decoded from the
/// `<slug>.ocrpkg.json` at [packagePath]). Pure: no I/O, so it is unit
/// testable. Returns a [FixtureGenReport].
FixtureGenReport generateFixtureTest({
  required Map<String, dynamic> pkg,
  required String packagePath,
}) {
  final schema = pkg['schema'];
  if (schema is! int || schema != 1) {
    return FixtureGenReport.failure(
        'unsupported package schema: $schema (expected 1)');
  }
  final kind = pkg['kind'];
  if (kind != 'pump') {
    // The replay harness drives `extractByLabelAnchor`, which is the
    // pump-display path. Receipt promotion is out of scope here (the
    // receipt path is not a pure block→triple function).
    return FixtureGenReport.failure(
        'kind "$kind" is not supported — only "pump" packages can be '
        'promoted to a label-anchored replay test');
  }

  final mlkit = pkg['mlkit'];
  if (mlkit is! Map || mlkit['blocks'] is! List) {
    return const FixtureGenReport.failure(
        'package has no mlkit.blocks to replay');
  }
  final rawBlocks = (mlkit['blocks'] as List).cast<dynamic>();
  final blocks = <_Block>[];
  for (final raw in rawBlocks) {
    if (raw is! Map) continue;
    final text = raw['text'];
    final box = raw['box'];
    if (text is! String || box is! List || box.length != 4) continue;
    blocks.add(_Block(
      text: text,
      left: (box[0] as num).toDouble(),
      top: (box[1] as num).toDouble(),
      right: (box[2] as num).toDouble(),
      bottom: (box[3] as num).toDouble(),
    ));
  }
  if (blocks.isEmpty) {
    return const FixtureGenReport.failure(
        'package mlkit.blocks is empty — nothing to replay');
  }

  final expected = pkg['expected'];
  if (expected is! Map ||
      (expected['totalCost'] == null &&
          expected['liters'] == null &&
          expected['pricePerLiter'] == null)) {
    return const FixtureGenReport.failure(
        'package has no `expected` values — fill expected.totalCost / '
        '.liters / .pricePerLiter (hand-correct the captured result) '
        'before promoting');
  }

  final input = pkg['input'];
  final country = (input is Map && input['country'] is String)
      ? input['country'] as String
      : null;
  final profileJson =
      (input is Map && input['profile'] is Map) ? input['profile'] as Map : null;

  final slug = _slugFromPath(packagePath);
  final imageRef = _siblingImageRef(packagePath, pkg);

  final source = _renderTest(
    slug: slug,
    packagePath: _repoRelative(packagePath),
    country: country,
    profileJson: profileJson,
    blocks: blocks,
    expected: expected,
    imageRef: imageRef,
    capturedAt: pkg['capturedAt'] as String?,
  );

  return FixtureGenReport.success(
    source: source,
    slug: slug,
    country: country,
    blockCount: blocks.length,
    imageRef: imageRef,
  );
}

/// One recognised block, rebuilt from `mlkit.blocks[i]`.
class _Block {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  const _Block({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

/// The slug is the package file name without the `.ocrpkg.json` suffix,
/// sanitised to a valid Dart identifier stem.
String _slugFromPath(String path) {
  var name = path.replaceAll('\\', '/').split('/').last;
  if (name.endsWith('.ocrpkg.json')) {
    name = name.substring(0, name.length - '.ocrpkg.json'.length);
  } else if (name.endsWith('.json')) {
    name = name.substring(0, name.length - '.json'.length);
  }
  final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  return RegExp(r'^[0-9]').hasMatch(cleaned) ? 'f_$cleaned' : cleaned;
}

/// The committed source image reference, if the package names one and a
/// sibling file exists. Used only for the test's "image is committed"
/// assertion + the CLI banner.
String? _siblingImageRef(String packagePath, Map<String, dynamic> pkg) {
  final dir = _repoRelative(packagePath)
      .replaceAll('\\', '/')
      .split('/')
    ..removeLast();
  final base = dir.join('/');
  final image = pkg['image'];
  if (image is Map && image['fileName'] is String) {
    final candidate = '$base/${image['fileName']}';
    if (File(candidate).existsSync()) return candidate;
  }
  // Fall back to a `<slug>.jpg` next to the package.
  final slug = _slugFromPath(packagePath);
  for (final ext in const ['jpg', 'jpeg', 'png']) {
    final candidate = '$base/$slug.$ext';
    if (File(candidate).existsSync()) return candidate;
  }
  return null;
}

/// Normalises [path] to a forward-slash, repo-rooted relative path so the
/// generated test reads identically regardless of the invoking CWD.
String _repoRelative(String path) {
  final norm = path.replaceAll('\\', '/');
  final idx = norm.indexOf('test/fixtures/');
  return idx >= 0 ? norm.substring(idx) : norm;
}

String _renderTest({
  required String slug,
  required String packagePath,
  required String? country,
  required Map<dynamic, dynamic>? profileJson,
  required List<_Block> blocks,
  required Map<dynamic, dynamic> expected,
  required String? imageRef,
  required String? capturedAt,
}) {
  final b = StringBuffer();
  b.writeln('// Copyright (c) 2026 Florian DITTGEN');
  b.writeln('// SPDX-License-Identifier: MIT');
  b.writeln();
  b.writeln('// GENERATED by `tool/promote_ocr_fixture.dart` (#2519) from');
  b.writeln('// `$packagePath`.');
  b.writeln('// DO NOT EDIT BY HAND — re-run the generator and commit the');
  b.writeln('// diff to refresh. A structural twin of');
  b.writeln('// `label_anchored_extractor_test.dart`: it replays the BAKED');
  b.writeln('// ML Kit blocks through the pure-Dart `extractByLabelAnchor`');
  b.writeln('// (no platform channel, runs in CI) and asserts the package\'s');
  b.writeln('// `expected` read.');
  if (capturedAt != null) {
    b.writeln('//');
    b.writeln('// Captured: $capturedAt');
  }
  b.writeln();
  b.writeln("import 'dart:io';");
  b.writeln();
  b.writeln("import 'package:flutter_test/flutter_test.dart';");
  b.writeln("import 'package:tankstellen/features/consumption/data/ocr/"
      "label_anchored_extractor.dart';");
  b.writeln("import 'package:tankstellen/features/consumption/data/ocr/"
      "pump_ocr_config.dart';");
  b.writeln("import 'package:tankstellen/features/consumption/data/ocr/"
      "recognized_text_block.dart';");
  b.writeln();
  b.writeln('void main() {');
  b.writeln('  // --- baked ML Kit blocks (rebuilt from mlkit.blocks) -------');
  b.writeln('  List<RecognizedTextBlock> bakedBlocks() => '
      'const <RecognizedTextBlock>[');
  for (final blk in blocks) {
    b.writeln('        RecognizedTextBlock(');
    b.writeln('          text: ${_dartString(blk.text)},');
    b.writeln('          box: OcrBox('
        'left: ${_num(blk.left)}, top: ${_num(blk.top)}, '
        'right: ${_num(blk.right)}, bottom: ${_num(blk.bottom)}),');
    b.writeln('        ),');
  }
  b.writeln('      ];');
  b.writeln();

  // Profile literal (or null).
  if (profileJson != null) {
    b.writeln('  const profile = OcrLocaleProfile(');
    b.writeln('    country: ${_dartString(profileJson['country'] as String? ?? country ?? '')},');
    b.writeln('    currency: ${_dartString(profileJson['currency'] as String? ?? 'EUR')},');
    b.writeln('    decimalSeparator: ${_dartString(profileJson['decimalSeparator'] as String? ?? ',')},');
    b.writeln('    priceMin: ${_num(_d(profileJson['priceMin']))},');
    b.writeln('    priceMax: ${_num(_d(profileJson['priceMax']))},');
    b.writeln('    volumeMax: ${_num(_d(profileJson['volumeMax']))},');
    b.writeln('    totalMax: ${_num(_d(profileJson['totalMax']))},');
    b.writeln('  );');
  } else {
    b.writeln('  const OcrLocaleProfile? profile = null;');
  }
  b.writeln();

  final group = country != null
      ? '#2519 fixture replay — $slug ($country)'
      : '#2519 fixture replay — $slug';
  b.writeln("  group('${_dartGroupString(group)}', () {");
  b.writeln("    test('replays baked blocks through extractByLabelAnchor', "
      '() {');
  b.writeln('      final blocks = bakedBlocks();');
  b.writeln('      final r = extractByLabelAnchor(blocks, profile: profile);');
  final total = _d(expected['totalCost']);
  final liters = _d(expected['liters']);
  final price = _d(expected['pricePerLiter']);
  if (total != null) {
    b.writeln('      expect(r.totalCost, closeTo(${_num(total)}, 0.001));');
  }
  if (liters != null) {
    b.writeln('      expect(r.liters, closeTo(${_num(liters)}, 0.001));');
  }
  if (price != null) {
    b.writeln('      expect(r.pricePerLiter, closeTo(${_num(price)}, 0.001));');
  }
  // Derived assertion: the package carries the result.derived field-name
  // set; map each name to its PumpField and assert membership.
  final derivedFields = _derivedPumpFields(expected);
  if (derivedFields.isNotEmpty) {
    for (final f in derivedFields) {
      b.writeln('      expect(r.derived, contains(PumpField.$f),');
      b.writeln("          reason: '$f was DERIVED by the cross-check');");
    }
  } else {
    b.writeln('      // No field flagged DERIVED in the expected read.');
    b.writeln('      expect(r.derived, isEmpty);');
  }
  b.writeln('    });');
  b.writeln();

  if (imageRef != null) {
    b.writeln("    test('source image is committed alongside the package', "
        '() {');
    b.writeln("      expect(File('${_dartGroupString(imageRef)}').existsSync(), "
        'isTrue,');
    b.writeln("          reason: 'the captured source frame must be "
        "committed as the fixture');");
    b.writeln('    });');
  }
  b.writeln('  });');
  b.writeln('}');
  return b.toString();
}

/// Maps the package's `expected.derived` field-name list (which uses the
/// result keys `totalCost`/`liters`/`pricePerLiter`) onto [PumpField]
/// enum-value names, ignoring any unknown entry. Empty when absent.
List<String> _derivedPumpFields(Map<dynamic, dynamic> expected) {
  final raw = expected['derived'];
  if (raw is! List) return const [];
  const mapping = {
    'totalCost': 'total',
    'liters': 'volume',
    'pricePerLiter': 'pricePerLitre',
    // Tolerate the enum-name form too, in case a hand edit used it.
    'total': 'total',
    'volume': 'volume',
    'pricePerLitre': 'pricePerLitre',
  };
  final out = <String>[];
  for (final e in raw) {
    final mapped = mapping[e];
    if (mapped != null && !out.contains(mapped)) out.add(mapped);
  }
  return out;
}

double? _d(Object? v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

/// Renders a double as a Dart literal, dropping a trailing `.0` only when
/// it stays an integer-valued double the analyzer still accepts in a
/// `double` context (we keep `.0` so the field type is unambiguous).
String _num(double? v) {
  if (v == null) return '0';
  if (v == v.roundToDouble() && v.abs() < 1e15) {
    return '${v.toInt()}.0';
  }
  return v.toString();
}

/// Single-quoted Dart string literal with the few chars that matter
/// escaped. Block text is short OCR fragments, so this is sufficient.
String _dartString(String s) {
  final escaped = s
      .replaceAll('\\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll(r'$', r'\$');
  return "'$escaped'";
}

/// Like [_dartString] but for text that is embedded inside an already
/// single-quoted string (group / reason / path) — escapes the same chars
/// without re-wrapping.
String _dartGroupString(String s) => s
    .replaceAll('\\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('\n', ' ')
    .replaceAll(r'$', r'\$');
