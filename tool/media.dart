// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// The screenshot pipeline (#1017): ingest what the owner posted, merge
// several captures of one form, cut the *Ausschnitte* that explain a
// single object, and keep the guides' images and the app's copies in
// step — under names that let a new screenshot replace the legacy one
// without touching a single link.
//
//   dart run tool/media.dart ingest  --screen <id> [--from <dir>] <file…>
//   dart run tool/media.dart merge   --screen <id> [--trim-top N] [--trim-bottom N] [--overlap N]
//   dart run tool/media.dart crop    --screen <id> --object <name> --rect x,y,w,h [--callout n@x,y…]
//   dart run tool/media.dart frame   --screen <id>|--all
//   dart run tool/media.dart redact  --file <path> --rect x,y,w,h [--rect …]
//   dart run tool/media.dart describe --image <name> --text "what it shows"
//   dart run tool/media.dart index
//   dart run tool/media.dart check
//
// Pure Dart: no Flutter, no l10n — the pipeline runs in CI and from a
// bare `dart run`.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// The originals, dated, never edited — provenance for every guide image.
const sourceDir = 'docs/media/source';

/// What the guides link — the source of truth for every documentation
/// image. `tool/build_help.dart` owns the app's downscaled copies under
/// `assets/help/images/`; this tool never writes there.
const wikiDir = 'docs/wiki/guide';

/// NOT in git (see .gitignore): the working index of what each image
/// shows, rewritten whenever new screenshots arrive.
const workbenchDir = '.media-workbench';

/// The 82 images already in the guides are 720 px wide; new ones match
/// them, so a page never mixes two scales.
const wikiWidth = 720;

/// JPEG, like the 82 images already in the guides — `build_help` copies
/// `*.jpg` and nothing else.
const wikiQuality = 84;

int main(List<String> argv) {
  final args = _Args(argv);
  return switch (args.command) {
    'ingest' => _ingest(args),
    'merge' => _merge(args),
    'crop' => _crop(args),
    'frame' => _frame(args),
    'redact' => _redact(args),
    'describe' => _describe(args),
    'index' => _index(),
    'check' => _check(),
    'list' => _list(),
    'slots' => _slots(),
    _ => _usage(),
  };
}

int _usage() {
  stdout.writeln('''
media — the screenshot pipeline (#1017)

  ingest   --screen <id> [--date yyyy-MM-dd] <file…>   store originals under their screen id
  merge    --screen <id> [--trim-top N] [--trim-bottom N] [--overlap N] [--sources a,b] [--out name]
                                                       stitch this screen's captures into <screen>-full.jpg
  crop     --screen <id> --object <name> --rect x,y,w,h [--callout n@x,y]…
                                                       an Ausschnitt of one object
  frame    --screen <id> | --all                       re-derive the wiki and app copies
  redact   --file <path> --rect x,y,w,h [--rect …]     pixelate a band
  describe --image <name> --text "what it shows"       set the index entry's description
  index                                                rebuild $workbenchDir/index.{json,md}
  check                                                images ↔ guide references ↔ app copies
  list                                                 what exists, per screen
  slots                                                image slots a guide still waits for

A screen id is the anchor with dots turned into dashes:
  user.money.invoice.detail-sheet  ->  user-money-invoice-detail-sheet
''');
  return 64;
}

// ── ingest ───────────────────────────────────────────────────────────
int _ingest(_Args a) {
  final screen = a.required('screen');
  final date = a.option('date') ?? _today();
  final files = <File>[
    for (final p in a.positionals) File(p),
    if (a.option('from') case final dir?)
      ...Directory(dir)
          .listSync()
          .whereType<File>()
          .where((f) => _isImage(f.path)),
  ]..sort((x, y) => x.path.compareTo(y.path));
  if (files.isEmpty) {
    stderr.writeln('media: nothing to ingest');
    return 65;
  }
  Directory(sourceDir).createSync(recursive: true);
  var n = _nextIndex(screen, date);
  final stored = <String>[];
  for (final file in files) {
    if (!file.existsSync()) {
      stderr.writeln('media: missing ${file.path}');
      return 66;
    }
    final ext = file.path.split('.').last.toLowerCase();
    final target = '$sourceDir/$date--$screen--$n.$ext';
    File(target).writeAsBytesSync(file.readAsBytesSync());
    stored.add(target);
    n++;
  }
  for (final s in stored) {
    stdout.writeln('stored $s');
  }
  return 0;
}

int _nextIndex(String screen, String date) {
  final dir = Directory(sourceDir);
  if (!dir.existsSync()) return 1;
  final prefix = '$date--$screen--';
  var max = 0;
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.startsWith(prefix)) continue;
    final n = int.tryParse(name.substring(prefix.length).split('.').first);
    if (n != null && n > max) max = n;
  }
  return max + 1;
}

// ── merge ────────────────────────────────────────────────────────────
int _merge(_Args a) {
  final screen = a.required('screen');
  final sources = a.option('sources')?.split(',') ?? _capturesOf(screen);
  if (sources.isEmpty) {
    stderr.writeln('media: no captures for $screen in $sourceDir');
    return 65;
  }
  final trimTop = int.tryParse(a.option('trim-top') ?? '0') ?? 0;
  final trimBottom = int.tryParse(a.option('trim-bottom') ?? '0') ?? 0;
  final forced = int.tryParse(a.option('overlap') ?? '');
  final minOverlap = int.tryParse(a.option('min-overlap') ?? '') ?? 60;

  var canvas = _trim(_load(sources.first), trimTop, trimBottom);
  for (final path in sources.skip(1)) {
    final next = _trim(_load(path), trimTop, trimBottom);
    final width = math.min(canvas.width, next.width);
    final a1 = canvas.width == width ? canvas : img.copyResize(canvas, width: width);
    final b1 = next.width == width ? next : img.copyResize(next, width: width);
    final found = forced != null
        ? Overlap(forced, 0, 0)
        : findOverlap(a1, b1, minOverlap: minOverlap);
    stdout.writeln('merge: ${_name(path)} overlaps by ${found.rows} px '
        '(score ${found.score.toStringAsFixed(2)}, '
        'runner-up ${found.runnerUp.toStringAsFixed(2)})');
    canvas = stitch(a1, b1, found.rows);
  }
  // A stitched whole form is `<screen>-full.jpg` — the name the guides
  // already give the images they hide inside `<details>` (#765), so a
  // merge never grows the in-app help by a 13000-pixel block.
  final name = a.option('out') ?? (sources.length > 1 ? '$screen-full' : screen);
  _writeDerived(name, canvas);
  stdout.writeln('merged ${sources.length} capture(s) → '
      '$wikiDir/$name.jpg (${canvas.width}×${canvas.height})');
  return 0;
}

List<String> _capturesOf(String screen) {
  final dir = Directory(sourceDir);
  if (!dir.existsSync()) return const [];
  final all = dir
      .listSync()
      .whereType<File>()
      .map((f) => f.path)
      .where((p) => _isImage(p) && _name(p).contains('--$screen--'))
      .toList()
    ..sort();
  if (all.isEmpty) return const [];
  // The newest capture session wins: same date prefix as the last file.
  final date = _name(all.last).split('--').first;
  return all.where((p) => _name(p).startsWith('$date--')).toList();
}

/// How far [b] slides up over [a] before the two agree.
///
/// Rows are reduced to one luminance value each, so the search is a walk
/// over two short vectors instead of two bitmaps. A band with no
/// contrast matches everything, so its variance is what disqualifies it.
Overlap findOverlap(img.Image a, img.Image b, {int minOverlap = 60}) {
  final sa = _rowSignature(a);
  final sb = _rowSignature(b);
  final maxOverlap = math.min(a.height, b.height);
  var best = const Overlap(0, double.infinity, double.infinity);
  var second = double.infinity;
  for (var o = minOverlap; o <= maxOverlap; o++) {
    var sum = 0.0;
    var min = 255.0;
    var max = 0.0;
    for (var i = 0; i < o; i++) {
      final va = sa[a.height - o + i];
      final vb = sb[i];
      sum += (va - vb).abs();
      min = math.min(min, va);
      max = math.max(max, va);
    }
    // A flat band (a blank scroll gap) is not evidence of an overlap.
    if (max - min < 6) continue;
    final score = sum / o;
    if (score < best.score) {
      second = best.score;
      best = Overlap(o, score, second);
    } else if (score < second) {
      second = score;
      best = Overlap(best.rows, best.score, second);
    }
  }
  // Nothing agreed: the captures do not overlap, so they simply follow.
  if (best.score > 12) return Overlap(0, best.score, second);
  return best;
}

/// [a] on top, [b] below, the [overlap] rows counted once.
img.Image stitch(img.Image a, img.Image b, int overlap) {
  final height = a.height + b.height - overlap;
  final out = img.Image(width: a.width, height: height);
  img.fill(out, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(out, a, dstX: 0, dstY: 0);
  img.compositeImage(out, b,
      dstX: 0,
      dstY: a.height - overlap,
      srcY: 0,
      srcH: b.height);
  return out;
}

List<double> _rowSignature(img.Image im, {int step = 8}) {
  final sig = List<double>.filled(im.height, 0);
  for (var y = 0; y < im.height; y++) {
    var sum = 0.0;
    var n = 0;
    for (var x = 0; x < im.width; x += step) {
      final p = im.getPixel(x, y);
      sum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      n++;
    }
    sig[y] = n == 0 ? 0 : sum / n;
  }
  return sig;
}

/// How far the second capture slides up over the first, and how sure.
class Overlap {
  const Overlap(this.rows, this.score, this.runnerUp);
  final int rows;
  final double score;
  final double runnerUp;
}

// ── crop ─────────────────────────────────────────────────────────────
int _crop(_Args a) {
  final screen = a.required('screen');
  final object = a.required('object');
  final rect = _rect(a.required('rect'));
  final from = a.option('from') ??
      [
        '$wikiDir/$screen-full.jpg',
        '$wikiDir/$screen.jpg',
      ].firstWhere((p) => File(p).existsSync(), orElse: () => '$wikiDir/$screen.jpg');
  final source = _load(from);
  var out = img.copyCrop(source,
      x: rect[0].clamp(0, source.width - 1),
      y: rect[1].clamp(0, source.height - 1),
      width: rect[2].clamp(1, source.width),
      height: rect[3].clamp(1, source.height));
  for (final callout in a.options('callout')) {
    final parts = callout.split('@');
    final at = _rect('${parts.length > 1 ? parts[1] : "0,0"},0,0');
    out = _badge(out, parts.first, at[0], at[1]);
  }
  _writeDerived('$screen--$object', out);
  stdout.writeln('cropped $wikiDir/$screen--$object.jpg '
      '(${out.width}×${out.height}) from ${_name(from)}');
  return 0;
}

/// A numbered disc the caption can point at ("① the rate, ② its group").
img.Image _badge(img.Image on, String label, int x, int y) {
  const r = 16;
  img.fillCircle(on,
      x: x + r, y: y + r, radius: r, color: img.ColorRgb8(197, 92, 60));
  img.drawString(on, label,
      font: img.arial24,
      x: x + r - 6 * label.length ~/ 2,
      y: y + r - 12,
      color: img.ColorRgb8(255, 255, 255));
  return on;
}

// ── frame / redact ───────────────────────────────────────────────────
int _frame(_Args a) {
  final names = a.flag('all')
      ? _images(wikiDir).map((p) => _name(p).replaceAll('.jpg', '')).toList()
      : [a.required('screen')];
  for (final name in names) {
    _writeDerived(name, _load('$wikiDir/$name.jpg'));
  }
  stdout.writeln('framed ${names.length} image(s)');
  return 0;
}

int _redact(_Args a) {
  final path = a.required('file');
  final im = _load(path);
  for (final spec in a.options('rect')) {
    final r = _rect(spec);
    final patch = img.pixelate(
      img.copyCrop(im, x: r[0], y: r[1], width: r[2], height: r[3]),
      size: 12,
    );
    img.compositeImage(im, patch, dstX: r[0], dstY: r[1]);
  }
  File(path).writeAsBytesSync(img.encodeJpg(im, quality: wikiQuality));
  stdout.writeln('redacted $path');
  return 0;
}

/// The one copy the guides link. The app's small copy is derived from it
/// by `tool/build_help.dart`, so there is exactly one owner per folder.
void _writeDerived(String name, img.Image image) {
  Directory(wikiDir).createSync(recursive: true);
  final wiki =
      image.width > wikiWidth ? img.copyResize(image, width: wikiWidth) : image;
  File('$wikiDir/$name.jpg')
      .writeAsBytesSync(img.encodeJpg(wiki, quality: wikiQuality));
}

// ── index (NOT in git) ───────────────────────────────────────────────
int _describe(_Args a) {
  final image = a.required('image');
  final text = a.required('text');
  final index = _readIndex();
  (index[image] ??= <String, Object?>{})['description'] = text;
  _writeIndex(index);
  stdout.writeln('described $image');
  return 0;
}

int _index() {
  final index = _readIndex();
  final seen = <String>{};
  for (final file in _images(wikiDir)) {
    final name = _name(file).replaceAll('.jpg', '');
    seen.add(name);
    final entry = index[name] ??= <String, Object?>{};
    final image = _load(file);
    entry['name'] = '$name.jpg';
    entry['wiki'] = '$wikiDir/$name.jpg';
    entry['app'] = File('assets/help/images/$name.jpg').existsSync()
        ? 'assets/help/images/$name.jpg'
        : null;
    entry['size'] = '${image.width}×${image.height}';
    entry['bytes'] = File(file).lengthSync();
    entry['anchor'] =
        name.split('--').first.replaceAll('-full', '').replaceAll('-', '.');
    entry['object'] = name.contains('--') ? name.split('--').last : null;
    entry['sources'] = _capturesOf(name.split('--').first.replaceAll('-full', ''))
        .map(_name)
        .toList();
    entry['description'] ??= '';
  }
  index.removeWhere((k, _) => !seen.contains(k));
  _writeIndex(index);
  stdout.writeln('indexed ${index.length} image(s) → $workbenchDir/index.md');
  return 0;
}

Map<String, Map<String, Object?>> _readIndex() {
  final file = File('$workbenchDir/index.json');
  if (!file.existsSync()) return {};
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      e.key: Map<String, Object?>.from(e.value as Map),
  };
}

void _writeIndex(Map<String, Map<String, Object?>> index) {
  Directory(workbenchDir).createSync(recursive: true);
  final names = index.keys.toList()..sort();
  File('$workbenchDir/index.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
            for (final n in names) n: index[n],
          })}\n');
  final md = StringBuffer()
    ..writeln('# Media index')
    ..writeln()
    ..writeln('Not in git — the working index of the documentation images.')
    ..writeln('Rebuilt by `dart run tool/media.dart index`; descriptions are')
    ..writeln('kept across rebuilds. ${names.length} image(s).')
    ..writeln()
    ..writeln('| image | shows | anchor | size | wiki | app | sources |')
    ..writeln('|---|---|---|---|---|---|---|');
  for (final n in names) {
    final e = index[n]!;
    md.writeln('| `$n.jpg` | ${e['description'] ?? ''} | `${e['anchor']}` '
        '| ${e['size']} | ${e['wiki']} | ${e['app'] ?? '—'} '
        '| ${(e['sources'] as List?)?.join('<br>') ?? ''} |');
  }
  File('$workbenchDir/index.md').writeAsStringSync('$md');
}

// ── check / list ─────────────────────────────────────────────────────
int _check() {
  final problems = <String>[];
  final referenced = <String>{};
  final guides = Directory('docs/wiki')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'));
  // The guides reference images as HTML (`<img src="images/x.jpg" …>`)
  // and the compiled help as markdown — accept both.
  final link = RegExp(r'images/([A-Za-z0-9._-]+\.jpg)');
  for (final guide in guides) {
    for (final m in link.allMatches(guide.readAsStringSync())) {
      final name = m.group(1)!;
      referenced.add(name);
      if (!File('$wikiDir/$name').existsSync()) {
        problems.add('${_name(guide.path)} links images/$name — not on disk');
      }
    }
  }
  var appBytes = 0;
  for (final file in _images(wikiDir)) {
    final name = _name(file);
    if (!referenced.contains(name)) {
      problems.add('$wikiDir/$name is not referenced by any guide');
    }
  }
  for (final file in _images('assets/help/images')) {
    appBytes += File(file).lengthSync();
  }
  final appMb = appBytes / (1024 * 1024);
  stdout.writeln('check: ${referenced.length} referenced, '
      '${_images(wikiDir).length} on disk, '
      'app copies ${appMb.toStringAsFixed(1)} MB '
      '(rebuild with `dart run tool/build_help.dart`)');
  for (final p in problems) {
    stdout.writeln('  ✗ $p');
  }
  return problems.isEmpty ? 0 : 1;
}

/// `<!-- image: name -->` in a guide is a slot: the text is written, the
/// screenshot is not taken yet. Filling one is replacing the comment
/// with the `<img>` tag — never editing a sentence.
int _slots() {
  final slot = RegExp(r'<!--\s*image:\s*([a-z0-9-]+)\s*-->');
  var waiting = 0;
  var ready = 0;
  for (final guide in Directory('docs/wiki')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))) {
    for (final m in slot.allMatches(guide.readAsStringSync())) {
      final name = m.group(1)!;
      final have = File('$wikiDir/$name.jpg').existsSync();
      if (have) {
        ready++;
      } else {
        waiting++;
      }
      stdout.writeln('${have ? 'ready ' : 'wanted'}  ${_name(guide.path)}'
          '  $name');
    }
  }
  stdout.writeln('$waiting slot(s) waiting for a screenshot, '
      '$ready ready to be filled');
  return 0;
}

int _list() {
  for (final file in _images(wikiDir)) {
    final image = _load(file);
    stdout.writeln('${_name(file).padRight(52)} '
        '${image.width}×${image.height}  ${File(file).lengthSync() ~/ 1024} KB');
  }
  return 0;
}

// ── plumbing ─────────────────────────────────────────────────────────
List<String> _images(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return const [];
  return d
      .listSync()
      .whereType<File>()
      .map((f) => f.path)
      .where((p) => p.endsWith('.jpg'))
      .toList()
    ..sort();
}

img.Image _load(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('media: missing $path');
    exit(66);
  }
  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) {
    stderr.writeln('media: cannot decode $path');
    exit(66);
  }
  return image;
}

img.Image _trim(img.Image im, int top, int bottom) => top == 0 && bottom == 0
    ? im
    : img.copyCrop(im,
        x: 0,
        y: top,
        width: im.width,
        height: math.max(1, im.height - top - bottom));

List<int> _rect(String spec) {
  final parts = spec.split(',').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  while (parts.length < 4) {
    parts.add(0);
  }
  return parts;
}

bool _isImage(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.png') || p.endsWith('.jpg') || p.endsWith('.jpeg');
}

String _name(String path) => path.split(Platform.pathSeparator).last;

String _today() {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

/// `command --key value --flag positional…`
class _Args {
  _Args(List<String> argv) {
    if (argv.isEmpty) return;
    command = argv.first;
    for (var i = 1; i < argv.length; i++) {
      final a = argv[i];
      if (!a.startsWith('--')) {
        positionals.add(a);
        continue;
      }
      final key = a.substring(2);
      final next = i + 1 < argv.length ? argv[i + 1] : null;
      if (next == null || next.startsWith('--')) {
        flags.add(key);
      } else {
        (_options[key] ??= []).add(next);
        i++;
      }
    }
  }

  String command = '';
  final positionals = <String>[];
  final flags = <String>{};
  final _options = <String, List<String>>{};

  String? option(String key) => _options[key]?.first;
  List<String> options(String key) => _options[key] ?? const [];
  bool flag(String key) => flags.contains(key);

  String required(String key) {
    final value = option(key);
    if (value == null) {
      stderr.writeln('media: --$key is required');
      exit(64);
    }
    return value;
  }
}
