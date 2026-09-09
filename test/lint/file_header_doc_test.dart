// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'build_method_scan.dart';

/// Undocumented files (#3985, epic #3952).
///
/// ## The definition — written down BEFORE the baseline
///
/// A file is undocumented when its **first top-level declaration**
/// carries no `///` doc comment immediately above it (annotations in
/// between are fine). That declaration is what a reader meets first;
/// a sentence there answers "what is this file for" at the moment the
/// question is asked.
///
/// This definition is stated here because the audit that prompted the
/// task reported 417 undocumented files and no rule for reaching that
/// number — with the rule above the count is **64**, and neither number
/// can be checked against the other. A ratchet whose definition lives
/// only in whoever wrote it is a ratchet that fails for reasons nobody
/// can reproduce (#2348).
///
/// Files with no top-level declaration at all (barrels, `part` files)
/// are out of scope: there is nothing for the doc to be about.
///
/// ## The baseline
///
/// **64**, measured with the scan below. Decrease-only. NEVER raise it.
const _baseline = 64;

void main() {
  test('no new undocumented file in lib/ (#3985)', () {
    final offenders = <String>[];
    for (final file in libFiles()) {
      if (!hasHeaderDoc(file.readAsStringSync())) {
        offenders.add(posixPath(file));
      }
    }
    offenders.sort();

    expect(
      offenders.length,
      lessThanOrEqualTo(_baseline),
      reason: 'Files whose first top-level declaration has no /// doc: '
          '${offenders.length} (baseline $_baseline, decrease-only). Say '
          'what the file is for in one or two sentences above its first '
          'declaration — see #3985.\n${offenders.join("\n")}',
    );
  });

  test('the scan reads the doc above the first declaration, annotations '
      'and all — fidelity check', () {
    // Documented, with an annotation between doc and declaration.
    expect(
      hasHeaderDoc('''
// Copyright (c) 2026 Florian DITTGEN

import 'x.dart';

/// What this file is for.
@riverpod
class Thing {}
'''),
      isTrue,
    );

    // Undocumented: the licence header is not a doc comment.
    expect(
      hasHeaderDoc('''
// Copyright (c) 2026 Florian DITTGEN

import 'x.dart';

class Thing {}
'''),
      isFalse,
    );

    // A doc on the SECOND declaration does not document the file.
    expect(
      hasHeaderDoc('''
// Copyright (c) 2026 Florian DITTGEN

class First {}

/// Documented, but not first.
class Second {}
'''),
      isFalse,
    );

    // No top-level declaration at all — out of scope, counted as fine.
    expect(
      hasHeaderDoc('''
// Copyright (c) 2026 Florian DITTGEN

export 'a.dart';
export 'b.dart';
'''),
      isTrue,
    );
  });
}
