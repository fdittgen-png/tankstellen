// Lists petrol-only catalog entries that have a popular European diesel
// sibling but no matching diesel row in `vehicles.json` (#1396).
//
// Run manually as a development check:
//
//   dart run tool/audit_catalog_diesel_gaps.dart
//
// Output is a markdown table the maintainer can paste into a tracking
// issue or a PR comment. The script intentionally is NOT wired into CI
// — the curated "popular diesels" list below is opinionated and would
// need ongoing maintenance to keep up with new model years; failing CI
// on every drift would be more noise than signal.
//
// Schema match: each row in [_popularEuDiesels] must agree with the
// catalog's `make` / `model` capitalisation (case-insensitive
// comparison happens inside the script). When a model with a known
// popular diesel exists in the catalog only as a petrol/hybrid, the
// script flags it.

import 'dart:convert';
import 'dart:io';

const String _catalogPath = 'assets/reference_vehicles/vehicles.json';

/// Hand-curated list of popular EU diesel powertrains. Each entry is
/// `(make, model, engine_code)` — the engine code is purely
/// informational (it lands in the audit table) and the make/model
/// pair is what the script joins against the catalog.
///
/// Sourced from new-car registration data 2015-2024 across DE / FR /
/// IT / ES / UK markets. Entries err on the side of "still on the
/// road in volume" rather than current-year sales — the goal is
/// catching gaps in the install-base profile of the user's catalog
/// hits, not perfectly mirroring 2024 dealer stocks.
const List<(String make, String model, String engineCode)> _popularEuDiesels = [
  // Renault / Dacia 1.5 dCi K9K family — by far the most common
  // small-diesel in France and across Eastern EU.
  ('Renault', 'Clio', '1.5 dCi 90'),
  ('Renault', 'Megane', '1.5 dCi 115'),
  ('Renault', 'Captur', '1.5 dCi 90'),
  ('Renault', 'Kadjar', '1.5 dCi / 1.7 dCi'),
  ('Renault', 'Scenic', '1.5 dCi'),
  ('Dacia', 'Sandero', '1.5 dCi 90'),
  ('Dacia', 'Duster', '1.5 dCi 115'),
  ('Dacia', 'Logan', '1.5 dCi 90'),
  // PSA 1.5 BlueHDi DV5R + earlier 1.6 HDi.
  ('Peugeot', '208', '1.5 BlueHDi 100'),
  ('Peugeot', '308', '1.5 BlueHDi 130'),
  ('Peugeot', '2008', '1.5 BlueHDi 100'),
  ('Peugeot', '3008', '1.5 BlueHDi 130'),
  ('Citroen', 'C3', '1.5 BlueHDi 100'),
  ('Citroen', 'C4', '1.5 BlueHDi 130'),
  ('Citroen', 'C5 Aircross', '1.5 BlueHDi 130'),
  ('Citroen', 'Berlingo', '1.5 BlueHDi'),
  // VAG 1.6 / 2.0 TDI EA288.
  ('Volkswagen', 'Polo', '1.6 TDI'),
  ('Volkswagen', 'Golf', '2.0 TDI'),
  ('Volkswagen', 'Passat', '2.0 TDI'),
  ('Volkswagen', 'Tiguan', '2.0 TDI'),
  ('Volkswagen', 'T-Roc', '2.0 TDI'),
  ('Skoda', 'Fabia', '1.6 TDI'),
  ('Skoda', 'Octavia', '2.0 TDI'),
  ('Skoda', 'Karoq', '2.0 TDI'),
  // Opel post-2017 PSA platforms share the BlueHDi family.
  ('Opel', 'Corsa', '1.5 Diesel 102'),
  ('Opel', 'Astra', '1.5 Diesel 130'),
  ('Opel', 'Mokka', '1.5 Diesel'),
  // Ford Duratorq family — still a healthy install base in UK / IE.
  ('Ford', 'Fiesta', '1.5 TDCi'),
  ('Ford', 'Focus', '1.5 EcoBlue'),
  ('Ford', 'Kuga', '1.5 / 2.0 EcoBlue'),
  ('Ford', 'Puma', '1.5 EcoBlue'),
  // Hyundai / Kia 1.6 CRDi — popular in DE / NL fleet.
  ('Hyundai', 'Tucson', '1.6 CRDi'),
  ('Hyundai', 'i30', '1.6 CRDi'),
  ('Kia', 'Ceed', '1.6 CRDi'),
  ('Kia', 'Sportage', '1.6 CRDi'),
  // Fiat 1.3 / 1.6 Multijet.
  ('Fiat', '500X', '1.6 Multijet'),
  ('Fiat', 'Tipo', '1.6 Multijet'),
];

void main(List<String> args) {
  final file = File(_catalogPath);
  if (!file.existsSync()) {
    stderr.writeln('audit_catalog_diesel_gaps: $_catalogPath not found.');
    stderr.writeln('Run from the project root.');
    exitCode = 1;
    return;
  }

  final entries = (json.decode(file.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  // Group catalog entries by lowercased "make|model" for fast lookup.
  final byMakeModel = <String, List<Map<String, dynamic>>>{};
  for (final entry in entries) {
    final make = (entry['make'] as String?)?.toLowerCase().trim() ?? '';
    final model = (entry['model'] as String?)?.toLowerCase().trim() ?? '';
    if (make.isEmpty || model.isEmpty) continue;
    byMakeModel.putIfAbsent('$make|$model', () => []).add(entry);
  }

  final missing = <_AuditRow>[];
  final ok = <_AuditRow>[];
  final notInCatalog = <_AuditRow>[];

  for (final (make, model, engineCode) in _popularEuDiesels) {
    final key = '${make.toLowerCase()}|${model.toLowerCase()}';
    final rows = byMakeModel[key];
    if (rows == null || rows.isEmpty) {
      notInCatalog.add(_AuditRow(make, model, engineCode, hasDiesel: null));
      continue;
    }
    final hasDiesel = rows.any((row) =>
        (row['fuelType'] as String?)?.toLowerCase() == 'diesel');
    if (hasDiesel) {
      ok.add(_AuditRow(make, model, engineCode, hasDiesel: true));
    } else {
      missing.add(_AuditRow(make, model, engineCode, hasDiesel: false));
    }
  }

  stdout.writeln('# Catalog diesel-gap audit (#1396)');
  stdout.writeln('');
  stdout.writeln(
      'Catalog has ${entries.length} entries, audited against '
      '${_popularEuDiesels.length} popular EU diesel powertrains.');
  stdout.writeln('');

  stdout.writeln('## Missing diesel siblings (${missing.length})');
  stdout.writeln('');
  if (missing.isEmpty) {
    stdout.writeln('_None — every popular diesel has a catalog row._');
  } else {
    stdout.writeln('| Make | Model | Engine code |');
    stdout.writeln('|------|-------|-------------|');
    for (final row in missing) {
      stdout.writeln('| ${row.make} | ${row.model} | ${row.engineCode} |');
    }
  }
  stdout.writeln('');

  stdout.writeln('## Already covered (${ok.length})');
  stdout.writeln('');
  if (ok.isEmpty) {
    stdout.writeln('_None covered yet._');
  } else {
    stdout.writeln('| Make | Model | Engine code |');
    stdout.writeln('|------|-------|-------------|');
    for (final row in ok) {
      stdout.writeln('| ${row.make} | ${row.model} | ${row.engineCode} |');
    }
  }
  stdout.writeln('');

  stdout.writeln(
      '## Not in catalog at all (${notInCatalog.length})');
  stdout.writeln('');
  stdout.writeln(
      'These models are listed in the popular-diesels table but the '
      'catalog has no row for them in any fuel type. Adding them is '
      'out of scope for #1396 — log a follow-up issue if the user '
      'base trends towards one of these brands.');
  stdout.writeln('');
  if (notInCatalog.isEmpty) {
    stdout.writeln('_None._');
  } else {
    stdout.writeln('| Make | Model | Engine code |');
    stdout.writeln('|------|-------|-------------|');
    for (final row in notInCatalog) {
      stdout.writeln('| ${row.make} | ${row.model} | ${row.engineCode} |');
    }
  }
}

class _AuditRow {
  final String make;
  final String model;
  final String engineCode;
  final bool? hasDiesel;
  const _AuditRow(this.make, this.model, this.engineCode,
      {required this.hasDiesel});
}
