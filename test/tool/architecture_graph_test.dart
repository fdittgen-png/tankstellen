// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #4346 — the architecture inventory on synthetic fixtures. Every case
// builds a tiny in-memory lib/ (one runs on a temp dir to cover the disk
// scan), so the scanner's rules are executed, not just its output shape.
// The full-repository numbers are owned by feature_boundary_test and
// file_length_test, which read them from the same scanner.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_graph.dart';

ArchitectureInventory _inventory(Map<String, String> sources) =>
    ArchitectureInventory.fromSources(sources);

void main() {
  group('directive parsing', () {
    test('multi-line, show-clause and conditional directives', () {
      final directives = parseDirectives('''
import 'dart:io';
import 'package:tankstellen/features/b/api.dart'
    show Thing, Other;
export 'stub.dart'
    if (dart.library.io) 'io.dart'
    if (dart.library.html) 'web.dart';
/// import 'commented_out.dart';
''');
      expect(directives.map((d) => d.kind), ['import', 'import', 'export']);
      expect(directives[1].uris, ['package:tankstellen/features/b/api.dart']);
      expect(directives[2].uris, ['stub.dart', 'io.dart', 'web.dart']);
    });

    test('relative and package URIs resolve to the same file', () {
      expect(resolveUri('lib/features/a/x.dart', '../b/api.dart'),
          'lib/features/b/api.dart');
      expect(
          resolveUri('lib/features/a/x.dart',
              'package:tankstellen/features/b/api.dart'),
          'lib/features/b/api.dart');
      expect(resolveUri('lib/features/a/x.dart', 'package:riverpod/r.dart'),
          isNull);
    });
  });

  group('the two graphs', () {
    test('a relative reach-in and a package reach-in count the same', () {
      final inv = _inventory({
        'lib/features/a/x.dart': "import '../b/data/repo.dart';",
        'lib/features/a/y.dart':
            "import 'package:tankstellen/features/b/data/repo.dart';",
        'lib/features/b/data/repo.dart': '',
      });
      expect(inv.reachInPairs, {'a -> b': 2});
      expect(inv.featureEdges, {'a -> b': 2});
    });

    test('an api.dart import is a dependency but not a reach-in', () {
      final inv = _inventory({
        'lib/features/a/x.dart': "import '../b/api.dart';",
        'lib/features/b/api.dart': "export 'data/repo.dart';",
        'lib/features/b/data/repo.dart': '',
      });
      expect(inv.reachInPairs, isEmpty);
      expect(inv.featureEdges, {'a -> b': 1});
    });

    test('replacing a reach-in with the barrel lowers graph 1 and keeps the '
        'dependency in graph 2', () {
      const barrel = "export 'data/repo.dart';";
      final before = _inventory({
        'lib/features/a/x.dart': "import '../b/data/repo.dart';",
        'lib/features/b/api.dart': barrel,
        'lib/features/b/data/repo.dart': '',
      });
      final after = _inventory({
        'lib/features/a/x.dart': "import '../b/api.dart';",
        'lib/features/b/api.dart': barrel,
        'lib/features/b/data/repo.dart': '',
      });
      expect(before.reachInPairs, {'a -> b': 1});
      expect(after.reachInPairs, isEmpty);
      expect(after.featureEdges.keys, before.featureEdges.keys,
          reason: 'the dependency did not go away');
      expect(after.exportExpandedFeaturePairs, {'a -> b'});
    });

    test('export chains make a third feature visible', () {
      final inv = _inventory({
        'lib/features/a/x.dart': "import '../b/api.dart';",
        'lib/features/b/api.dart': "export 'data/bridge.dart';",
        'lib/features/b/data/bridge.dart': "export '../../c/model.dart';",
        'lib/features/c/model.dart': '',
      });
      expect(inv.featureEdges.keys, containsAll(['a -> b', 'b -> c']));
      expect(inv.featureEdges.containsKey('a -> c'), isFalse);
      expect(inv.exportExpandedFeaturePairs, containsAll(['a -> b', 'a -> c']));
      expect(
          inv.renderReport(),
          contains(
              '| … of which visible only through an export chain | 1 |'));
    });

    test('an export cycle terminates', () {
      final inv = _inventory({
        'lib/features/a/api.dart': "export '../b/api.dart';",
        'lib/features/b/api.dart': "export '../a/api.dart';",
      });
      expect(inv.featureMutualPairs, ['a <-> b']);
    });

    test('every branch of a conditional directive is an edge', () {
      final inv = _inventory({
        'lib/features/a/x.dart':
            "import '../b/stub.dart' if (dart.library.io) '../c/io.dart';",
      });
      expect(inv.featureEdges, {'a -> b': 1, 'a -> c': 1});
      expect(inv.reachInPairs, {'a -> b': 1, 'a -> c': 1});
    });

    test('a cycle solely through public barrels is visible in graph 2 only',
        () {
      final inv = _inventory({
        'lib/features/a/x.dart': "import '../b/api.dart';",
        'lib/features/a/api.dart': "export 'x.dart';",
        'lib/features/b/y.dart': "import '../a/api.dart';",
        'lib/features/b/api.dart': "export 'y.dart';",
      });
      expect(inv.reachInMutualPairs, isEmpty);
      expect(inv.featureMutualPairs, ['a <-> b']);
      expect(inv.featureSccs, [
        ['a', 'b'],
      ]);
    });

    test('a three-feature cycle is one SCC and zero mutual pairs', () {
      final inv = _inventory({
        'lib/features/a/x.dart': "import '../b/api.dart';",
        'lib/features/b/x.dart': "import '../c/api.dart';",
        'lib/features/c/x.dart': "import '../a/api.dart';",
        'lib/features/d/x.dart': "import '../a/api.dart';",
      });
      expect(inv.featureMutualPairs, isEmpty);
      expect(inv.featureSccs, [
        ['a', 'b', 'c'],
      ]);
    });

    test('core -> feature and feature -> shell are violations; shell -> '
        'feature is composition', () {
      final inv = _inventory({
        'lib/core/x.dart': "import '../features/a/api.dart';",
        'lib/features/a/x.dart': "import '../../app/router.dart';",
        'lib/app/router.dart': "import '../features/a/api.dart';",
        'lib/main.dart': "import 'features/b/api.dart';",
      });
      expect(inv.coreImportsByFeature, {'a': 1},
          reason: 'the barrel does not excuse core -> feature');
      expect(inv.shellImportsByFeature, {'a': 1});
      expect(inv.reachInLines, hasLength(2),
          reason: 'shell -> feature is never a reach-in');
      expect(inv.moduleEdges.keys,
          containsAll(['<shell> -> a', '<shell> -> b', '<core> -> a']));
      expect(inv.moduleSccs, [
        ['<shell>', 'a'],
      ]);
    });
  });

  group('shared-state libraries', () {
    const header = '// Copyright (c) 2026 Florian DITTGEN\n'
        '// SPDX-License-Identifier: MIT\n\n';

    Map<String, String> controllerLibrary({required bool extracted}) => {
          'lib/features/a/controller.dart': '$header'
              "part 'controller_state.dart';\n"
              "part 'controller.g.dart';\n"
              "${extracted ? '' : "part 'controller_io.dart';\n"}"
              '/// class Doc with _Io {}\n'
              'class Controller with _State${extracted ? '' : ', _Io'} {\n'
              '  int _count = 0;\n'
              "  String get label => '_notAnIdentifier';\n"
              '}\n',
          'lib/features/a/controller_state.dart':
              "${header}part of 'controller.dart';\n"
                  'mixin _State { int get _count; }\n',
          if (!extracted)
            'lib/features/a/controller_io.dart':
                "${header}part of 'controller.dart';\n"
                    'mixin _Io on _State { void _flush() => _count; }\n',
        };

    test('root, hand-written parts, lines, part mixins and the owner', () {
      final libraries =
          sharedStateLibraries(controllerLibrary(extracted: false));
      expect(libraries, hasLength(1));
      final lib = libraries.single;
      expect(lib.root, 'lib/features/a/controller.dart');
      expect(lib.parts, [
        'lib/features/a/controller_state.dart',
        'lib/features/a/controller_io.dart',
      ], reason: 'the generated part is not part of the hand-written unit');
      expect(lib.lines, 8 + 2 + 2, reason: 'SPDX headers are discounted');
      expect(lib.partMixins, ['_Io', '_State']);
      expect(lib.owners, ['Controller'],
          reason: 'a class named in a comment is not an owner');
      expect(lib.crossFilePrivates, containsAll(['_State', '_Io', '_count']));
      expect(lib.crossFilePrivates, isNot(contains('_notAnIdentifier')));
    });

    test('extracting a slice lowers ownership coupling; a part move does not',
        () {
      final before = sharedStateLibraries(controllerLibrary(extracted: false));
      final after = sharedStateLibraries(controllerLibrary(extracted: true));
      expect(after.single.partMixins.length,
          lessThan(before.single.partMixins.length));

      // Moving the same mixin into a different part file changes nothing.
      const root = 'lib/features/a/controller.dart';
      final moved = controllerLibrary(extracted: false);
      moved.remove('lib/features/a/controller_io.dart');
      moved[root] = moved[root]!.replaceFirst(
          "part 'controller_io.dart';", "part 'controller_io_moved.dart';");
      moved['lib/features/a/controller_io_moved.dart'] =
          "${header}part of 'controller.dart';\n"
          'mixin _Io on _State { void _flush() => _count; }\n';
      final afterMove = sharedStateLibraries(moved).single;
      expect(afterMove.partMixins, before.single.partMixins);
      expect(afterMove.crossFilePrivates, before.single.crossFilePrivates);
    });
  });

  test('scan reads a temp lib/ and skips generated output', () {
    final root = Directory.systemTemp.createTempSync('arch_graph_');
    addTearDown(() => root.deleteSync(recursive: true));
    void write(String path, String content) =>
        (File('${root.path}/$path')..createSync(recursive: true))
            .writeAsStringSync(content);
    write('lib/features/a/x.dart', "import '../b/api.dart';");
    write('lib/features/b/api.dart', "import '../a/x.dart';");
    write('lib/features/b/model.g.dart', "import '../c/api.dart';");
    write('lib/l10n/app_localizations.dart', "import '../features/c/x.dart';");

    final inv = ArchitectureInventory.scan(root: root.path);
    expect(inv.fileCount, 2);
    expect(inv.featureEdges.keys, unorderedEquals(['a -> b', 'b -> a']));
    final report = inv.renderReport();
    expect(report, contains('## Graph 1 — contract-compliance reach-ins'));
    expect(report, contains('## Graph 2 — feature dependency graph'));
    expect(report, contains('| Bidirectional pairs including api.dart | 1 |'));
    expect(report, contains('1. (2) a, b'));
  });

  test('effectiveLines discounts only the project SPDX header', () {
    expect(
        effectiveLines(linesOf('// Copyright (c) 2026 Florian DITTGEN\n'
            '// SPDX-License-Identifier: MIT\n\nvoid f() {}\n')),
        1);
    expect(effectiveLines(linesOf('void f() {}\nvoid g() {}\n')), 2);
  });
}
