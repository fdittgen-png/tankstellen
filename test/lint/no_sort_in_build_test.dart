// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'build_method_scan.dart';

/// Sorting inside `build()` (#3985, epic #3952).
///
/// ## The definition
///
/// A violation is `.sort(`, `..sort(` or `.sorted(` appearing anywhere
/// inside the brace-matched body of a `Widget build(BuildContext …)`.
///
/// `build` runs on every rebuild — a theme change, a keyboard opening, a
/// parent `setState` — not on every data change. A sort there re-does
/// the same work each time and, worse, hides a derivation where no test
/// can reach it without pumping a widget.
///
/// ## The baseline
///
/// **8**, measured with the scan below after #3985 hoisted the three
/// whose inputs come from a provider or a constant:
/// `tripsForVehicleProvider`, `sortedBlockedAuthorsProvider` and the
/// module-level `_featuresByName`.
///
/// The remaining eight are leaf widgets sorting their OWN constructor
/// arguments — a chart's data series, a five-element preset list. Their
/// inputs change whenever the parent rebuilds them, so caching would
/// add state without removing work. They stay, capped: this ratchet
/// exists to stop the NEXT one, and to be lowered whenever a derivation
/// genuinely belongs in a provider.
///
/// Decrease-only. NEVER raise it.
const _baseline = 8;

void main() {
  test('no new sort inside a build() method (#3985)', () {
    final offenders = <String>[];
    for (final file in libFiles()) {
      final src = file.readAsStringSync();
      for (final (start, body) in buildBodies(src)) {
        for (final m in _sortCall.allMatches(body)) {
          offenders.add('${posixPath(file)}:${lineAt(src, start + m.start)}');
        }
      }
    }

    expect(
      offenders.length,
      lessThanOrEqualTo(_baseline),
      reason: 'Sorts inside build(): ${offenders.length} (baseline '
          '$_baseline, decrease-only). Move the derivation to a provider '
          '(or a module-level constant when the input never changes) so it '
          'runs per data change, not per frame — see #3985.\n'
          '${offenders.join("\n")}',
    );
  });

  test('the scan still matches what it claims to — fidelity check', () {
    // #2348 — a scanner that silently stops matching reads as a clean
    // repo. Pin both directions against synthetic source.
    const src = '''
class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final xs = items.toList()..sort();
    return Column(children: [
      for (final x in xs) Text(x),
    ]);
  }
}

class B extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(sortedElsewhere.first);
  }
}

List<int> notABuild() => [3, 1]..sort();
''';
    final found = <String>[];
    for (final (_, body) in buildBodies(src)) {
      for (final m in _sortCall.allMatches(body)) {
        found.add(m.group(0)!);
      }
    }
    // Exactly one: A's, not B's (no sort) and not the top-level
    // function's (not a build method).
    expect(found, ['..sort(']);

    // Brace matching must swallow the nested widget tree; a body cut at
    // the first `}` would miss a sort placed after it.
    final bodies = buildBodies(src).map((e) => e.$2).toList();
    expect(bodies, hasLength(2));
    expect(bodies.first, contains('return Column'));
  });
}

final _sortCall = RegExp(r'\.\.?sort\(|\.sorted\(');
