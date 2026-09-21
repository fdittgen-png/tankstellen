// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan ratchet (#4388): inside an **auto-dispose** Riverpod
/// Notifier, the notifier's own `ref` must not be used after an `await`
/// unless a `ref.mounted` check sits between them.
///
/// **Why.** Riverpod 3 throws `StateError` (`Cannot use the Ref of the
/// provider after it has been disposed`) the moment a disposed
/// provider's `Ref` is touched. An auto-dispose provider is disposed as
/// soon as its last listener goes — a popped screen, a rebuilt scope —
/// which routinely happens while a network or GPS `await` is still
/// pending. The resume then either raises an uncaught async error or,
/// where a broad `catch` sits around the call (as in
/// `link_device_provider`'s per-alert import), silently drops the work
/// with no trace at all.
///
/// This is a **different** hazard from #4381, whose `Ref` outlived its
/// own element while being used by someone else, and from #3159
/// (`no_ref_after_await_test.dart`), which covers a widget's `WidgetRef`.
/// The three guards are deliberately separate.
///
/// **The one sanctioned pattern** is `if (!ref.mounted) return;` — the
/// same guard #1321 already put through `search_provider.dart`. At each
/// site the author decides, in a comment where it is not obvious,
/// whether the resumed work is *dropped* (guard and return) or must
/// *complete without state writes* (resolve everything it needs from
/// `ref` BEFORE the first await, then guard only the `state =` write).
///
/// **What counts as a violation** (the scanner's own definition, which is
/// what the baseline below is measured with):
/// - the file is under `lib/`, is not generated (`.g.dart`,
///   `.freezed.dart`), and contains `extends _$` — i.e. it declares a
///   codegen Notifier;
/// - the enclosing class is **auto-dispose**: annotated `@riverpod`, or
///   `@Riverpod(...)` without `keepAlive: true`. A keepAlive notifier
///   cannot lose this race and is skipped;
/// - inside that class, a body opened by `async {` / `async* {` is
///   walked line by line after `//` comments are stripped. An `await`
///   arms a "dirty" flag once its statement's parentheses have closed
///   (so `await ref.read(x).save(...)` spanning lines does not flag its
///   own arguments), any `ref.mounted` clears it, and a
///   `ref.<anything-but-mounted>` on a dirty line is one violation.
///
/// The heuristic is path-insensitive and line-based, exactly like its
/// #3159 sibling: it is a backstop, not a proof engine. The count is
/// exact both ways — the baseline is **0** and may never be raised.
void main() {
  const expectedViolations = 0;

  final extendsGenerated = RegExp(r'\bextends\s+_\$\w+');
  final classLine = RegExp(r'^class\s+(\w+)\b');
  final refUse = RegExp(r'\bref\s*\.\s*(?!mounted\b)\w+');
  final refMounted = RegExp(r'\bref\s*\.\s*mounted\b');
  final awaitRe = RegExp(r'\bawait\b');
  final asyncOpen = RegExp(r'\basync\*?\s*\{');
  final lineComment = RegExp(r'//.*');

  int braces(String s) => '{'.allMatches(s).length - '}'.allMatches(s).length;
  int parens(String s) => '('.allMatches(s).length - ')'.allMatches(s).length;
  String code(String line) => line.replaceAll(lineComment, '');

  /// `[start, end]` line indices of every auto-dispose notifier class.
  List<List<int>> autoDisposeClasses(List<String> lines) {
    final out = <List<int>>[];
    for (var i = 0; i < lines.length; i++) {
      if (!extendsGenerated.hasMatch(lines[i])) continue;
      // `class X\n    extends _$X {` is a real spelling in this repo.
      var ci = i;
      while (ci >= 0 && !classLine.hasMatch(lines[ci])) {
        ci--;
      }
      if (ci < 0) continue;

      bool? autoDispose;
      for (var k = ci - 1; k >= 0 && k >= ci - 15; k--) {
        final t = lines[k].trim();
        if (t.startsWith('@riverpod')) {
          autoDispose = true;
          break;
        }
        if (t.startsWith('@Riverpod(')) {
          var ann = t;
          var j = k;
          while (!ann.contains(')') && j + 1 < lines.length) {
            j++;
            ann += lines[j];
          }
          autoDispose = !ann.contains('keepAlive: true');
          break;
        }
        if (t.isEmpty || t.startsWith('//') || t.startsWith('@')) continue;
        break;
      }
      if (autoDispose != true) continue;

      var depth = 0;
      var opened = false;
      var j = ci;
      while (j < lines.length) {
        depth += braces(code(lines[j]));
        if (depth > 0) opened = true;
        if (opened && depth <= 0) break;
        j++;
      }
      out.add([ci, j]);
    }
    return out;
  }

  /// Violations in [src], attributed to [path]. Pure, so the mutation
  /// checks below can hand it a synthetic offender instead of a file.
  List<String> scanSource(String path, String src) {
    final violations = <String>[];
    if (!src.contains(r'extends _$')) return violations;
    final lines = src.split('\n');
    for (final range in autoDisposeClasses(lines)) {
      var i = range[0];
      while (i <= range[1] && i < lines.length) {
        if (!asyncOpen.hasMatch(code(lines[i]))) {
          i++;
          continue;
        }
        var depth = braces(code(lines[i]));
        var j = i + 1;
        var dirty = false;
        var pending = false;
        var parenDepth = 0;
        while (j < lines.length && depth > 0) {
          final line = code(lines[j]);
          if (refMounted.hasMatch(line)) {
            dirty = false;
            pending = false;
          } else if (dirty && refUse.hasMatch(line)) {
            violations.add('$path:${j + 1}: ${line.trim()}');
          }
          parenDepth += parens(line);
          if (awaitRe.hasMatch(line)) pending = true;
          if (pending && parenDepth <= 0) {
            dirty = true;
            pending = false;
          }
          depth += braces(line);
          j++;
        }
        i = j;
      }
    }
    return violations;
  }

  List<File> notifierFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
        final p = f.path.replaceAll(r'\', '/');
        return p.endsWith('.dart') &&
            !p.endsWith('.g.dart') &&
            !p.endsWith('.freezed.dart');
      })
      .where((f) => f.readAsStringSync().contains(r'extends _$'))
      .toList();

  test(
      'an auto-dispose Notifier never uses its own ref after an await '
      'without a ref.mounted check (#4388)', () {
    final violations = <String>[];
    for (final file in notifierFiles()) {
      final path = file.path.replaceAll(r'\', '/');
      violations.addAll(scanSource(path, file.readAsStringSync()));
    }

    expect(
      violations.length,
      expectedViolations,
      reason: 'An auto-dispose provider can be disposed while its await is '
          'pending; touching `ref` on the resume throws "Cannot use the Ref '
          '… after it has been disposed" (#4388). Add '
          '`if (!ref.mounted) return;` after the await, or resolve what you '
          'need from `ref` before it. The baseline is 0 and may never be '
          'raised.\nViolations:\n${violations.join('\n')}',
    );
  });

  test('the scan actually reaches the auto-dispose notifiers', () {
    // Guard against a vacuous green: a broken cwd, walk or `extends _$`
    // filter would leave the assertion above passing on an empty set.
    final files = notifierFiles();
    expect(files.length, greaterThan(50),
        reason: 'expected the repo\'s ~110 codegen notifier files, found '
            '${files.length}');

    var autoDisposeCount = 0;
    for (final f in files) {
      autoDisposeCount +=
          autoDisposeClasses(f.readAsStringSync().split('\n')).length;
    }
    // 42 of the ~138 codegen notifier classes are auto-dispose; the rest
    // are `@Riverpod(keepAlive: true)` and out of scope.
    expect(autoDisposeCount, greaterThan(30),
        reason: 'the @riverpod/@Riverpod annotation reader found only '
            '$autoDisposeCount auto-dispose notifier classes');
  });

  test('MUTATION CHECK: the scanner flags an injected offender', () {
    const offender = r'''
@riverpod
class Thing extends _$Thing {
  @override
  int build() => 0;

  Future<void> go() async {
    await Future<void>.delayed(Duration.zero);
    state = ref.read(otherProvider);
  }
}
''';
    expect(scanSource('synthetic.dart', offender), hasLength(1),
        reason: 'a bare post-await ref.read in an auto-dispose notifier '
            'must be flagged');

    // The guard must be the notifier's own `ref.mounted`, not any
    // `mounted` in scope — a Notifier has no bare `mounted`.
    const reArmed = r'''
@riverpod
class Thing extends _$Thing {
  Future<void> go() async {
    await one();
    if (!ref.mounted) return;
    ref.read(a);
    await two();
    ref.read(b);
  }
}
''';
    expect(scanSource('synthetic.dart', reArmed), hasLength(1),
        reason: 'the second await re-arms the guard; only the ref.read '
            'after it is a violation');
  });

  test('MUTATION CHECK: the scanner does not flag the sanctioned shapes',
      () {
    const guarded = r'''
@riverpod
class Thing extends _$Thing {
  Future<void> go() async {
    await Future<void>.delayed(Duration.zero);
    if (!ref.mounted) return;
    state = ref.read(otherProvider);
  }
}
''';
    expect(scanSource('synthetic.dart', guarded), isEmpty);

    const capturedBeforeAwait = r'''
@riverpod
class Thing extends _$Thing {
  Future<void> go() async {
    final service = ref.read(serviceProvider);
    await service.work();
    service.finish();
  }
}
''';
    expect(scanSource('synthetic.dart', capturedBeforeAwait), isEmpty);

    // keepAlive notifiers cannot lose this race.
    const keepAlive = r'''
@Riverpod(keepAlive: true)
class Thing extends _$Thing {
  Future<void> go() async {
    await Future<void>.delayed(Duration.zero);
    state = ref.read(otherProvider);
  }
}
''';
    expect(scanSource('synthetic.dart', keepAlive), isEmpty,
        reason: 'a keepAlive provider is not disposed out from under its '
            'own await');

    // The awaited expression's own arguments are evaluated before the
    // suspension, so they are not "after" it.
    const refInsideTheAwait = r'''
@riverpod
class Thing extends _$Thing {
  Future<void> go() async {
    await ref
        .read(serviceProvider)
        .work();
  }
}
''';
    expect(scanSource('synthetic.dart', refInsideTheAwait), isEmpty);
  });
}
