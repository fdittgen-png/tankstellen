// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:xml/xml.dart';

import 'backup_xml_reader.dart' show BackupXmlReadException;

/// Typed accessors over one backup `XmlElement` — the "read a field"
/// half of `BackupXmlReader`, split out (#4071) so the reader keeps to
/// the document structure and the schema, and every field-level rule
/// (required, numeric, non-negative) lives in one place.

String? readText(XmlElement parent, String name) =>
    parent.findElements(name).firstOrNull?.innerText;

String reqText(XmlElement parent, String name) {
  final v = readText(parent, name);
  if (v == null) {
    throw BackupXmlReadException('missing required <$name>');
  }
  return v;
}

double? readDouble(XmlElement parent, String name) {
  final v = readText(parent, name);
  return v == null ? null : double.tryParse(v);
}

double reqDouble(XmlElement parent, String name) {
  final v = readDouble(parent, name);
  if (v == null) {
    throw BackupXmlReadException('missing/invalid required <$name>');
  }
  return v;
}

/// #4071 — a quantity that cannot be negative. `TankPeriod` asserts
/// `liters >= 0`; a hand-edited or corrupt backup must be refused at
/// the boundary, not construct an invalid report past the assert.
double reqNonNegativeDouble(XmlElement parent, String name) {
  final v = reqDouble(parent, name);
  if (v < 0) {
    throw BackupXmlReadException('negative <$name>');
  }
  return v;
}

int? readInt(XmlElement parent, String name) {
  final v = readText(parent, name);
  if (v == null) return null;
  // Numbers are written via `.toString()`, so a double-typed field
  // that happens to hold a whole number is still safe to read as int.
  return int.tryParse(v) ?? double.tryParse(v)?.toInt();
}

int reqInt(XmlElement parent, String name) {
  final v = readInt(parent, name);
  if (v == null) {
    throw BackupXmlReadException('missing/invalid required <$name>');
  }
  return v;
}

bool? readBool(XmlElement parent, String name) {
  final v = readText(parent, name);
  if (v == null) return null;
  return v.toLowerCase() == 'true';
}

DateTime? readDate(XmlElement parent, String name) {
  final v = readText(parent, name);
  if (v == null) return null;
  return DateTime.tryParse(v);
}

DateTime reqDate(XmlElement parent, String name) {
  final v = readDate(parent, name);
  if (v == null) {
    throw BackupXmlReadException('missing/invalid required <$name>');
  }
  return v;
}
