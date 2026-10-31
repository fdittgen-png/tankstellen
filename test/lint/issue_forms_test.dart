// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Offline validation of the form subset used here; GitHub owns its full schema.
List<String> _problems(Map<Object?, Object?> form) {
  final errors = <String>[];
  for (final key in ['name', 'description']) {
    if (form[key] is! String || (form[key] as String).trim().isEmpty) {
      errors.add('missing $key');
    }
  }
  final ids = <String>{};
  final body = form['body'];
  if (body is! List || body.isEmpty) return [...errors, 'missing body'];
  for (final field in body) {
    if (field is! Map) {
      errors.add('field is not a map');
      continue;
    }
    final type = field['type'];
    final attributes = field['attributes'];
    if (attributes is! Map) {
      errors.add('missing attributes');
      continue;
    }
    if (type == 'markdown') {
      if (attributes['value'] is! String) errors.add('missing markdown');
      continue;
    }
    if (!['input', 'textarea', 'dropdown', 'checkboxes'].contains(type)) {
      errors.add('unsupported field type');
    }
    final id = field['id'];
    if (id is! String || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      errors.add('invalid id');
    } else if (!ids.add(id)) {
      errors.add('duplicate id');
    }
    final label = attributes['label'];
    if (label is! String || label.trim().isEmpty) errors.add('missing label');
    final validations = field['validations'];
    if (validations != null &&
        (validations is! Map || validations['required'] is! bool)) {
      errors.add('invalid required');
    }
    if (type == 'dropdown') {
      final options = attributes['options'];
      if (options is! List ||
          options.isEmpty ||
          options.toSet().length != options.length) {
        errors.add('invalid options');
      }
    }
  }
  return errors;
}

bool _linksContract(String path, String text) {
  final links = RegExp(
    r'\]\(([^)]+issue-exit-contract\.md)\)',
  ).allMatches(text).map((match) => match[1]!);
  if (links.isEmpty) return false;
  final canonical = File('docs/guides/issue-exit-contract.md').absolute.uri;
  return links.every((link) {
    final uri = Uri.parse(link);
    final resolved = uri.hasScheme
        ? (link ==
                  'https://github.com/fdittgen-png/tankstellen/blob/master/docs/guides/issue-exit-contract.md'
              ? canonical
              : uri)
        : File(path).absolute.uri.resolve(link);
    return resolved == canonical && File.fromUri(resolved).existsSync();
  });
}

void main() {
  final forms = Directory('.github/ISSUE_TEMPLATE')
      .listSync()
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.yml') && !file.path.endsWith('/config.yml'),
      )
      .toList();

  test('forms have valid names, IDs and fields', () {
    expect(forms, isNotEmpty);
    final names = <String>{};
    for (final file in forms) {
      final form = loadYaml(file.readAsStringSync()) as YamlMap;
      expect(_problems(form), isEmpty, reason: file.path);
      expect(names.add(form['name'] as String), isTrue, reason: file.path);
      expect(
        _linksContract(file.path, file.readAsStringSync()),
        isTrue,
        reason: file.path,
      );
    }
  });

  test('entry points link the canonical contract', () {
    for (final path in [
      '.github/PULL_REQUEST_TEMPLATE.md',
      'CONTRIBUTING.md',
      'docs/CONTRIBUTING.md',
      'docs/AGENT_RULES.md',
      'docs/wiki/Dev-Creating-Issues.md',
      'docs/wiki/Dev-GitHub-Workflow.md',
    ]) {
      expect(
        _linksContract(path, File(path).readAsStringSync()),
        isTrue,
        reason: path,
      );
    }
  });

  test('invalid fields are rejected', () {
    final form = loadYaml(forms.first.readAsStringSync()) as YamlMap;
    final field = {
      'type': 'input',
      'id': 'same',
      'attributes': {'label': 'Example'},
    };
    void rejects(List<Map<String, Object?>> fields, String error) =>
        expect(_problems({...form, 'body': fields}), contains(error));
    rejects([field, field], 'duplicate id');
    rejects([
      {...field, 'id': 'bad id'},
    ], 'invalid id');
    rejects([
      {
        ...field,
        'attributes': {'label': ''},
      },
    ], 'missing label');
    rejects([
      {
        ...field,
        'validations': {'required': 'yes'},
      },
    ], 'invalid required');
  });

  test('missing and broken links are rejected', () {
    const path = 'CONTRIBUTING.md';
    final text = File(path).readAsStringSync();
    expect(
      _linksContract(
        path,
        text.replaceAll('issue-exit-contract.md', 'absent.md'),
      ),
      isFalse,
    );
    expect(
      _linksContract(path, text.replaceAll('docs/guides/', 'absent/')),
      isFalse,
    );
  });
}
