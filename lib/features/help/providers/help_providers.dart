// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4007 — the compiled guide and its anchor map, read once and kept.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'help_providers.g.dart';

/// The languages the wiki carries. The app speaks 23; the other sixteen
/// read the English guide, which is what they get on GitHub today.
const helpLocales = {'da', 'de', 'en', 'es', 'fr', 'it', 'pt'};

/// The compiled guide for [languageCode], falling back to English.
String helpAssetFor(String languageCode) =>
    'assets/help/${helpLocales.contains(languageCode) ? languageCode : 'en'}.md';

/// The anchor map beside that guide: anchor id → the heading it names,
/// in that guide's language.
String helpAnchorAssetFor(String languageCode) =>
    'assets/help/${helpLocales.contains(languageCode) ? languageCode : 'en'}'
    '.anchors.json';

/// The guide text. Kept alive: it is a third of a megabyte of markdown
/// that never changes between releases, and re-reading it on every push
/// of `/help` is a visible stutter.
@Riverpod(keepAlive: true)
Future<String> helpDocument(Ref ref, String languageCode) =>
    rootBundle.loadString(helpAssetFor(languageCode));

/// The anchor map. Error-tolerant on purpose: a missing or malformed
/// map costs the reader an exact jump, not the guide — so it answers
/// with an empty map rather than an error screen.
@Riverpod(keepAlive: true)
Future<Map<String, String>> helpAnchors(Ref ref, String languageCode) async {
  try {
    final raw = await rootBundle.loadString(helpAnchorAssetFor(languageCode));
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries) entry.key: '${entry.value}',
    };
  } on Object {
    return const {};
  }
}
