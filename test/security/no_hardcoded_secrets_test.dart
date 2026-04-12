import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('No hardcoded secrets', () {
    late List<File> dartFiles;

    setUp(() {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ directory must exist');

      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('.g.dart'))
          .where((f) => !f.path.endsWith('.freezed.dart'))
          .toList();
    });

    test('found Dart source files to scan', () {
      expect(dartFiles, isNotEmpty,
          reason: 'Should find at least one .dart file in lib/');
      expect(dartFiles.length, greaterThan(10));
    });

    test('no hardcoded API key assignments', () {
      // Pattern: apiKey = "actual-value" or apiKey: "actual-value"
      // Excludes empty strings and placeholder hints.
      final apiKeyPattern = RegExp(
        r'''(?:apiKey|api_key|apikey)\s*[:=]\s*['"][a-zA-Z0-9_\-]{8,}['"]''',
        caseSensitive: false,
      );

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (apiKeyPattern.hasMatch(line)) {
            // Exclude l10n getter names (label translations, not actual keys)
            if (line.contains('openChargeMapApiKey')) continue;
            // Exclude hint text and label text (UI strings)
            if (line.contains('hintText') || line.contains('labelText')) {
              continue;
            }
            // Exclude storage key constants (names, not values)
            if (line.contains("static const String") &&
                line.contains("= '") &&
                RegExp(r"= '[a-z_]+'").hasMatch(line)) {
              continue;
            }
            // Exclude comments
            if (line.trimLeft().startsWith('//')) continue;
            // Exclude default EV API key (intentionally public, shared key)
            if (line.contains('defaultEvApiKey')) continue;
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} potential hardcoded API key(s):\n'
          '${violations.join('\n')}',
        );
      }
    });

    test('no hardcoded JWT tokens', () {
      // JWT format: eyJ<base64>.<base64>.<base64>
      final jwtPattern = RegExp(
        r'''['"]eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}['"]''',
      );

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (jwtPattern.hasMatch(line)) {
            // Skip comments
            if (line.trimLeft().startsWith('//')) continue;
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} potential hardcoded JWT(s):\n'
          '${violations.join('\n')}',
        );
      }
    });

    test('no hardcoded UUIDs used as secret values', () {
      // UUIDs in assignments that look like secrets (not IDs or keys used for lookups)
      // Pattern: secret/password/token = "uuid"
      final uuidSecretPattern = RegExp(
        r'''(?:secret|password|token|credential)\s*[:=]\s*['"][0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}['"]''',
        caseSensitive: false,
      );

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (uuidSecretPattern.hasMatch(line)) {
            if (line.trimLeft().startsWith('//')) continue;
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} potential hardcoded secret UUID(s):\n'
          '${violations.join('\n')}',
        );
      }
    });

    test('no Supabase URLs or anon keys hardcoded', () {
      // Supabase anon keys are JWTs starting with eyJ...
      // Supabase project URLs match: https://<project-ref>.supabase.co
      final supabaseUrlPattern = RegExp(
        r'''['"]https://[a-z0-9]+\.supabase\.co['"]''',
      );

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (supabaseUrlPattern.hasMatch(line)) {
            // Skip comments
            if (line.trimLeft().startsWith('//')) continue;
            // Skip env/config loading patterns
            if (line.contains('env') || line.contains('ENV')) continue;
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} potential hardcoded Supabase URL(s):\n'
          '${violations.join('\n')}',
        );
      }
    });

    test('network_security_config restricts cleartext to Argentina only', () {
      final configFile = File(
        'android/app/src/main/res/xml/network_security_config.xml',
      );
      expect(configFile.existsSync(), isTrue,
          reason: 'network_security_config.xml must exist');

      final content = configFile.readAsStringSync();

      // Base config must deny cleartext
      expect(content, contains('cleartextTrafficPermitted="false"'));

      // Only datos.energia.gob.ar should have cleartext permitted
      final cleartextDomains = RegExp(
        r'<domain-config\s+cleartextTrafficPermitted="true">'
        r'[\s\S]*?<domain[^>]*>([^<]+)</domain>',
      ).allMatches(content).map((m) => m.group(1)).toList();

      expect(cleartextDomains, hasLength(1));
      expect(cleartextDomains.first, 'datos.energia.gob.ar');
    });

    test('CarAppService does not use ALLOW_ALL_HOSTS_VALIDATOR in release', () {
      final carAppFile = File(
        'android/app/src/main/kotlin/de/tankstellen/tankstellen/TankstellenCarAppService.kt',
      );
      expect(carAppFile.existsSync(), isTrue,
          reason: 'CarAppService.kt must exist');

      final content = carAppFile.readAsStringSync();
      final lines = content.split('\n');

      // Find lines that use ALLOW_ALL_HOSTS_VALIDATOR outside the debug block
      // The only acceptable use is inside the debug-only if-branch
      var inDebugBlock = false;
      final violations = <String>[];

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Track when we enter the debug-only branch
        if (line.contains('FLAG_DEBUGGABLE')) {
          inDebugBlock = true;
          continue;
        }
        if (inDebugBlock && line.contains('ALLOW_ALL_HOSTS_VALIDATOR')) {
          inDebugBlock = false; // consume the debug-only usage
          continue;
        }
        if (line.contains('ALLOW_ALL_HOSTS_VALIDATOR')) {
          violations.add('Line ${i + 1}: $line');
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'ALLOW_ALL_HOSTS_VALIDATOR used outside debug block:\n'
          '${violations.join('\n')}\n'
          'Release builds must use HostValidator.Builder with allowlisted hosts.',
        );
      }
    });

    test('no private keys or PEM blocks', () {
      final pemPattern = RegExp(
        r'-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----',
      );

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (pemPattern.hasMatch(content)) {
          violations.add(file.path);
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found private key PEM block(s) in:\n'
          '${violations.join('\n')}',
        );
      }
    });
  });
}
