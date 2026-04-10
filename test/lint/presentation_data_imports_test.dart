import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the clean-architecture boundary introduced by issue #56.
///
/// Presentation code (anything under `lib/features/*/presentation/`) must not
/// import from `data/models/`, `data/repositories/`, or `data/dto/`. Shared
/// types belong in `lib/features/*/domain/entities/`, and repositories must be
/// accessed via providers in `lib/features/*/providers/`.
///
/// This test complements `scripts/check_module_boundaries.sh` so the boundary
/// is also enforced on Windows CI without a bash dependency.
void main() {
  test('no presentation file imports from data/models|repositories|dto', () {
    final featuresDir = Directory('lib/features');
    expect(featuresDir.existsSync(), isTrue,
        reason: 'lib/features must exist at project root');

    final violations = <String>[];
    final dataImportPattern = RegExp(
      r'''^\s*import\s+['"][^'"]*data/(models|repositories|dto)/''',
      multiLine: true,
    );

    for (final entity in featuresDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart')) continue;
      if (path.endsWith('.freezed.dart')) continue;
      if (!path.contains('/presentation/')) continue;

      final contents = entity.readAsStringSync();
      for (final match in dataImportPattern.allMatches(contents)) {
        violations.add('$path: ${match.group(0)!.trim()}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Presentation layer must not import data/ types directly.\n'
          'Move or re-export the type via domain/entities/, and access '
          'repositories via providers/.\n\nViolations:\n'
          '${violations.join('\n')}',
    );
  });
}
