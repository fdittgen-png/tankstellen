import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Guards against undeclared package imports.
///
/// Background: a transitive dependency can disappear at any \`flutter pub
/// upgrade\` if the package that pulled it in stops depending on it. Code
/// that imports such a package then breaks the build (or, worse for code
/// running in the background isolate, breaks at runtime). This test walks
/// every \`.dart\` source file under \`lib/\` and \`test/\` and asserts that
/// every \`import 'package:NAME/...'\` resolves to a package that is
/// explicitly declared in \`pubspec.yaml\`.
///
/// See issue #421 for the original incident (\`path_provider\` and \`meta\`
/// imported but not declared).
void main() {
  /// Packages that ship with Flutter / Dart and don't need to appear in
  /// pubspec.yaml.
  const builtins = <String>{
    'flutter',
    'flutter_test',
    'flutter_driver',
    'flutter_localizations',
    'flutter_web_plugins',
    'integration_test',
    // The current package itself — \`import 'package:tankstellen/...'\`.
    'tankstellen',
  };

  late Set<String> declared;

  setUpAll(() {
    final pubspec =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    declared = <String>{
      ..._collectDependencyNames(pubspec['dependencies']),
      ..._collectDependencyNames(pubspec['dev_dependencies']),
    };
  });

  test('every package: import in lib/ is declared in pubspec.yaml', () {
    final undeclared = _findUndeclaredImports(
      Directory('lib'),
      declared: declared,
      builtins: builtins,
    );
    expect(
      undeclared,
      isEmpty,
      reason:
          'Undeclared imports found in lib/. Add them to pubspec.yaml '
          '(see issue #421):\n${_formatViolations(undeclared)}',
    );
  });

  test('every package: import in test/ is declared in pubspec.yaml', () {
    final undeclared = _findUndeclaredImports(
      Directory('test'),
      declared: declared,
      builtins: builtins,
    );
    expect(
      undeclared,
      isEmpty,
      reason:
          'Undeclared imports found in test/. Add them to dev_dependencies '
          '(see issue #421):\n${_formatViolations(undeclared)}',
    );
  });
}

/// Reads dependency names out of a pubspec dependencies map. Skips entries
/// whose value is a map containing \`sdk:\` (e.g. \`flutter: { sdk: flutter }\`
/// is still represented by the key \`flutter\`).
Set<String> _collectDependencyNames(Object? section) {
  if (section is! YamlMap) return const <String>{};
  return section.keys.cast<String>().toSet();
}

/// Returns a map of relative file path → set of undeclared package names.
Map<String, Set<String>> _findUndeclaredImports(
  Directory root, {
  required Set<String> declared,
  required Set<String> builtins,
}) {
  final allowed = <String>{...declared, ...builtins};
  final violations = <String, Set<String>>{};

  if (!root.existsSync()) return violations;

  final importPattern = RegExp(
    r'''^\s*import\s+['"]package:([a-zA-Z0-9_]+)/''',
    multiLine: true,
  );

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (!path.endsWith('.dart')) continue;
    // Generated files mirror their owner's imports, no need to double-check.
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    if (path.endsWith('.config.dart') || path.endsWith('.gen.dart')) continue;

    final source = entity.readAsStringSync();
    for (final match in importPattern.allMatches(source)) {
      final pkg = match.group(1)!;
      if (!allowed.contains(pkg)) {
        violations.putIfAbsent(path, () => <String>{}).add(pkg);
      }
    }
  }

  return violations;
}

String _formatViolations(Map<String, Set<String>> violations) {
  final entries = violations.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries
      .map((e) => '  ${e.key}: ${(e.value.toList()..sort()).join(", ")}')
      .join('\n');
}
