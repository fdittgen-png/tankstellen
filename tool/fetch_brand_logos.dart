// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Brand-logo audit + fetch (#3940, under epic #3929).
//
// Resolves every canonical `BrandRegistry` brand to its Wikidata item,
// reads that item's `P154` (logo image), verifies the Wikimedia Commons
// file's licence INDIVIDUALLY, and bundles only the files whose licence
// is public domain or CC-BY / CC-BY-SA / CC0. Everything else — every
// "non-free logo" / fair-use file, and every brand whose current mark is
// above the threshold of originality and therefore simply not on Commons
// — is rejected and keeps the offline monogram mark of #3930.
//
// Design constraints:
//  - Pure `dart:io` / `dart:convert`: runs on the plain Dart VM
//    (`dart run tool/fetch_brand_logos.dart`), no Flutter import, so the
//    audit is re-runnable in CI or on a bare checkout.
//  - The brand -> Wikidata mapping is CURATED, not searched at run time.
//    `wbsearchentities` is riddled with homonyms for these names — "Avia"
//    is a Czech truck maker, "Casino" is the 1995 Scorsese film, "Système
//    U" is a 1980s cycling team, "Sprint" is a US telco. Each id below was
//    verified by hand against the item's description and P31; a search at
//    run time would silently swap one of them back in.
//  - RASTER, not SVG: the app has no SVG renderer (`flutter_svg` is not a
//    dependency) so the tool asks MediaWiki's own thumbnailer for a PNG
//    rendering at [_thumbWidthPx], comfortably above the 48 dp x 3 that
//    `BrandLogo` renders. No local rasteriser, no new package.
//
// Outputs (both rewritten from scratch on every run):
//   assets/brand_logos/<slug>.png            the accepted logo files
//   lib/core/domain/brand_logo_manifest_data.dart   the generated manifest
//
// Usage:
//   dart run tool/fetch_brand_logos.dart [--dry-run] [--report-out=<path>]
//
// `--dry-run` performs the full licence audit and prints the verdict table
// without downloading anything or rewriting the manifest.

import 'dart:convert';
import 'dart:io';

/// The thumbnail width to ask Commons for.
///
/// `BrandLogo` renders at most 48 dp and phones top out at
/// devicePixelRatio 3, so 144 px would be the exact budget — but
/// Wikimedia only serves a fixed set of thumbnail widths (a request for
/// 144 px comes back HTTP 400; 120 and 250 are the neighbouring buckets
/// that render). 250 is the one that clears the budget, so it is what
/// lands in the bundle: still ~9 kB per logo.
const int _thumbWidthPx = 250;

/// Bucket used for portrait logos, whose long edge is their HEIGHT — at
/// [_thumbWidthPx] they would come back 250 x 300+.
const int _portraitWidthPx = 120;

const String _userAgent =
    'tankstellen-brand-logo-audit/1.0 (https://github.com/fdittgen-png/tankstellen)';

const String _assetDir = 'assets/brand_logos';
const String _manifestOut = 'lib/core/domain/brand_logo_manifest_data.dart';

/// Canonical `BrandRegistry` brand -> Wikidata item id.
///
/// Verified by hand on 2026-09-02 against each item's label, description
/// and `P31`. A brand absent from this map is in [noFreeLogoReasons].
const Map<String, String> brandWikidataIds = {
  // International oil majors
  'TotalEnergies': 'Q154037',
  'Shell': 'Q154950',
  'BP': 'Q152057',
  'Esso': 'Q867662',
  // NOT Q27143 (Avia, the Czech truck/aircraft maker) — the fuel brand is
  // the Swiss AVIA International co-operative.
  'AVIA': 'Q300147',
  'ENI': 'Q565594',
  'Q8': 'Q4119207',
  'Tamoil': 'Q706793',
  'Lukoil': 'Q329347',
  'Gulf': 'Q5617505',
  'Texaco': 'Q775060',

  // France
  'E.Leclerc': 'Q1273376',
  'Intermarché': 'Q3153200',
  'Auchan': 'Q758603',
  // NOT Q220910 — that is the 1995 Martin Scorsese film "Casino".
  'Casino': 'Q2670967',
  // The fuel brand "Netto" is the French Les-Mousquetaires chain; the
  // Danish (Q552652) and German (Q879858) Nettos are food-only.
  'Netto': 'Q2720988',
  'Dyneff': 'Q16630266',

  // Germany / Austria
  'Aral': 'Q565734',
  'Orlen': 'Q971649',
  'bft': 'Q1009104',
  'OIL!': 'Q2007561',
  'OMV': 'Q168238',
  'Turmöl': 'Q1473279',

  // Spain / Portugal / Italy
  'Repsol': 'Q174747',
  // Cepsa rebranded to Moeve; the Cepsa file is deprecated-rank upstream.
  'Cepsa': 'Q608819',
  'Galp': 'Q1492739',
  'Ballenoil': 'Q110743569',
  // Plenoil renamed itself Plenergy in Dec 2024 (all stations by Apr 2025).
  'Plenoil': 'Q127497985',
  'Meroil': 'Q62292559',
  'IP': 'Q3788748',
  'Prio': 'Q62530421',

  // Nordics
  'Circle K': 'Q3268010',
  'Uno-X': 'Q3362746',

  // United Kingdom
  'Tesco': 'Q487494',
  "Sainsbury's": 'Q152096',
  'Asda': 'Q297410',
  'Morrisons': 'Q922344',

  // Australia / Americas
  '7-Eleven': 'Q259340',
  'Puma Energy': 'Q7259769',
  'Pemex': 'Q871308',
  // OXXO Gas forecourts carry the parent OXXO wordmark.
  'Oxxo Gas': 'Q1342538',
  'Chevron': 'Q319642',
  'Arco': 'Q304769',
  'Valero': 'Q1283291',
  'Mobil': 'Q3088656',
  'YPF': 'Q2006989',
  'Axion Energy': 'Q107363755',

  // European charging networks (#3931)
  'Ionity': 'Q42717773',
  'Fastned': 'Q19935749',
  'Allego': 'Q75560554',
  'EnBW': 'Q644304',
  'Powerdot': 'Q123574541',
  'Atlante': 'Q126913632',
  'Be Charge': 'Q113289535',
  'Enel X Way': 'Q116116836',
  'Vattenfall InCharge': 'Q157675',
  'Tesla': 'Q17089620',
  'Shell Recharge': 'Q105883058',
  'E.ON Drive': 'Q126650419',
  'Lidl': 'Q151954',
  'Kaufland': 'Q685967',
};

/// Why a canonical brand has no bundled logo. Recorded so the partial
/// coverage is auditable rather than looking like an oversight — these
/// brands render the #3930 monogram mark, which is the honest outcome.
const Map<String, String> noFreeLogoReasons = {
  'Carrefour': 'Wikidata item Q217599 carries no P154; the chevron mark is '
      'above the threshold of originality, so Commons cannot host it.',
  'Système U': 'Coopérative U (Q2529029) has no P154 — the stylised U is '
      'copyrighted. Commons holds only an obsolete 1988-2009 promo file.',
  'Vito': 'No Wikidata item for the French station chain.',
  'JET': 'No Wikidata item for JET Tankstellen with a logo.',
  'HEM': 'No Wikidata item with a logo.',
  'Westfalen': 'Westfalen AG has no Wikidata logo; every search hit is a '
      'Dortmund venue or a railway company.',
  'Sprint': 'Only the US telco Sprint Corporation resolves; the German '
      'station chain has no item.',
  'Raiffeisen':
      'Ambiguous — every Wikidata hit is a bank, not the Austrian '
          'Lagerhaus forecourt brand.',
  'IQ': 'No Wikidata item.',
  'Disa': 'Only the US Defense Information Systems Agency resolves.',
  'Bonarea': 'bonÀrea has no P154.',
  'OK': 'OK a.m.b.a. has no Wikidata logo (the search hits are airlines).',
  'F24': 'No Wikidata item with a logo.',
  "Go'On": 'No Wikidata item with a logo.',
  'Ampol': 'Q4748526 carries no P154.',
  'United': 'Ambiguous name — United Petroleum has no item with a logo.',
  'Liberty': 'Ambiguous name — Liberty Oil has no item with a logo.',
  'Metro Petroleum': 'Q-item exists but carries no P154.',
  'G500': 'No Wikidata item with a logo.',
  'Hidrosina': 'Wikidata item carries no P154.',
  'Petro-7': 'Wikidata item carries no P154.',
  'Dapsa': 'No Wikidata item with a logo.',
  'Refinor': 'Wikidata item carries no P154.',
  'Maes': 'No Wikidata item with a logo.',
  'DATS 24': 'Wikidata item carries no P154.',
  'Octa+': 'Wikidata item carries no P154.',
  'Power': 'Ambiguous name — the Belgian chain has no item with a logo.',
  'Goedert': 'No Wikidata item with a logo.',
  'Electra': 'No Wikidata item with a logo.',
  'Izivia': 'Wikidata item carries no P154.',
  'Freshmile': 'Wikidata item carries no P154.',
  'Driveco': 'Wikidata item carries no P154.',
  'Bump': 'No Wikidata item with a logo.',
  'Engie Vianeo': 'Wikidata item carries no P154.',
  'Zunder': 'No Wikidata item with a logo.',
  'TotalEnergies Charge': 'No Wikidata item at all.',
  'Mer': 'No Wikidata item with a logo.',
  'Aldi': 'Q125054 splits P154 by country (Aldi Nord / Aldi Süd) and the '
      'registry carries a single "Aldi" brand — no one current mark.',
};

/// Commons files used INSTEAD of the item's `P154`, with the reason.
///
/// `P154` is the logo of the *item*, which for a retail group is the
/// group's corporate mark — Casino's carries the "Nourrir un monde de
/// diversité" strapline, illegible in a 48 dp tile and not what is on the
/// forecourt. The store brand's own file has no Wikidata item to hang
/// off, so it is named here. The licence of an overridden file is
/// verified by exactly the same audit as every other.
const Map<String, String> overrideFiles = {
  'Casino': 'Logo of Casino Supermarchés.svg',
  // Q871308's current P154 is the 2019 government-branded lockup, whose
  // "Por el rescate de la soberanía" strapline is a grey smudge at 48 dp.
  // The neutral eagle-and-drop mark in use since 1988 is what is on the
  // forecourt, and carries the same {{PD-Coa-Mexico}} tag.
  'Pemex': 'Logo neutral de Petróleos Mexicanos (desde 1988).svg',
  // Q758603's P154 is the "Auchan | RETAIL" divisional lockup; the
  // forecourt says "Auchan". Same PD-shape licence.
  'Auchan': 'Auchan wordmark.svg',
};

/// Which `P154` value to take when an item offers several current ones.
const Map<String, String> preferredFiles = {
  // Q154950 also lists a cropped photo of a pecten sign at preferred rank.
  'Shell': 'Shell wordmark 2019.svg',
  // Q3268010 lists the 2015 wordmark and the bare logotype, both normal.
  'Circle K': 'Circle K logo 2015.svg',
};

/// A file whose licence cleared the audit, ready to bundle.
class LogoRecord {
  const LogoRecord({
    required this.brand,
    required this.wikidataId,
    required this.commonsFile,
    required this.licence,
    required this.licenceTemplate,
    required this.author,
    required this.sourceUrl,
    required this.thumbUrl,
    required this.slug,
  });

  final String brand;
  final String wikidataId;
  final String commonsFile;
  final String licence;
  final String licenceTemplate;
  final String author;
  final String sourceUrl;
  final String thumbUrl;
  final String slug;

  String get assetFile => '$slug.png';
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final reportArg = args.firstWhere(
    (a) => a.startsWith('--report-out='),
    orElse: () => '',
  );

  final client = HttpClient()..userAgent = _userAgent;
  final report = StringBuffer();
  final accepted = <LogoRecord>[];
  final rejected = <String, String>{};

  try {
    final logoFiles = await _resolveLogoFiles(client);
    final brands = brandWikidataIds.keys.toList()..sort();
    for (final brand in brands) {
      final file = logoFiles[brand];
      if (file == null) {
        rejected[brand] = 'no P154 on ${brandWikidataIds[brand]}';
        continue;
      }
      final verdict = await _auditFile(client, brand, file);
      if (verdict.record != null) {
        accepted.add(verdict.record!);
      } else {
        rejected[brand] = verdict.reason;
      }
    }

    report.writeln('# Brand-logo licence audit (#3940)');
    report.writeln();
    report.writeln('| Brand | Wikidata | Commons file | Licence | Template '
        '| Author |');
    report.writeln('|---|---|---|---|---|---|');
    for (final r in accepted) {
      report.writeln('| ${r.brand} | ${r.wikidataId} | ${r.commonsFile} | '
          '${r.licence} | ${r.licenceTemplate} | ${r.author} |');
    }
    report.writeln();
    report.writeln('## Rejected / no free logo');
    report.writeln();
    for (final entry in rejected.entries) {
      report.writeln('- ${entry.key}: ${entry.value}');
    }
    for (final entry in noFreeLogoReasons.entries) {
      report.writeln('- ${entry.key}: ${entry.value}');
    }

    stdout.writeln(report);
    stdout.writeln('accepted: ${accepted.length}  '
        'rejected: ${rejected.length}  '
        'no-item: ${noFreeLogoReasons.length}');

    if (dryRun) return;

    await _download(client, accepted);
    _writeManifest(accepted);
    if (reportArg.isNotEmpty) {
      File(reportArg.split('=').last).writeAsStringSync(report.toString());
    }
  } finally {
    client.close(force: true);
  }
}

/// `brand -> Commons file name`, from each item's `P154` statements.
Future<Map<String, String>> _resolveLogoFiles(HttpClient client) async {
  final ids = brandWikidataIds.values.toSet().toList();
  final entities = <String, Map<String, Object?>>{};
  for (var i = 0; i < ids.length; i += 45) {
    final chunk = ids.sublist(i, i + 45 > ids.length ? ids.length : i + 45);
    final json = await _getJson(
      client,
      Uri.parse('https://www.wikidata.org/w/api.php?action=wbgetentities'
          '&format=json&props=claims&ids=${chunk.join('|')}'),
    );
    final got = json['entities'];
    if (got is Map<String, Object?>) {
      got.forEach((k, v) {
        if (v is Map<String, Object?>) entities[k] = v;
      });
    }
  }

  final out = <String, String>{...overrideFiles};
  brandWikidataIds.forEach((brand, qid) {
    if (out.containsKey(brand)) return;
    final entity = entities[qid];
    if (entity == null) return;
    final claims = entity['claims'];
    if (claims is! Map<String, Object?>) return;
    final statements = claims['P154'];
    if (statements is! List<Object?>) return;
    final picked = _pickCurrentLogo(brand, statements);
    if (picked != null) out[brand] = picked;
  });
  return out;
}

/// Choose the CURRENT logo among an item's `P154` statements.
///
/// Deprecated statements are dropped outright; a statement carrying an end
/// time (`P582`) is a historical variant and only used when nothing else
/// remains; a `preferred` rank wins over `normal`; ties break on the latest
/// start time (`P580`). [preferredFiles] overrides the whole ordering for
/// the handful of items that publish two equally-current marks.
String? _pickCurrentLogo(String brand, List<Object?> statements) {
  final override = preferredFiles[brand];
  final candidates = <({String file, bool preferred, bool ended, String start})>[];
  for (final raw in statements) {
    if (raw is! Map<String, Object?>) continue;
    if (raw['rank'] == 'deprecated') continue;
    final snak = raw['mainsnak'];
    if (snak is! Map<String, Object?>) continue;
    if (snak['snaktype'] != 'value') continue;
    final value = (snak['datavalue'] as Map<String, Object?>?)?['value'];
    if (value is! String) continue;
    if (override != null && value == override) return value;
    final quals = raw['qualifiers'];
    final qualMap =
        quals is Map<String, Object?> ? quals : const <String, Object?>{};
    candidates.add((
      file: value,
      preferred: raw['rank'] == 'preferred',
      ended: qualMap.containsKey('P582'),
      start: _timeQualifier(qualMap['P580']),
    ));
  }
  if (candidates.isEmpty) return null;
  final live = candidates.where((c) => !c.ended).toList();
  final pool = live.isEmpty ? candidates : live;
  pool.sort((a, b) {
    if (a.preferred != b.preferred) return a.preferred ? -1 : 1;
    return b.start.compareTo(a.start);
  });
  return pool.first.file;
}

String _timeQualifier(Object? qualifier) {
  if (qualifier is! List<Object?> || qualifier.isEmpty) return '';
  final first = qualifier.first;
  if (first is! Map<String, Object?>) return '';
  final value = (first['datavalue'] as Map<String, Object?>?)?['value'];
  if (value is! Map<String, Object?>) return '';
  final time = value['time'];
  return time is String ? time : '';
}

/// The outcome of auditing one Commons file.
typedef _Verdict = ({LogoRecord? record, String reason});

/// Licences we accept: public domain in any flavour, CC0, and the
/// attribution CC licences. Everything else — most of all any "non-free
/// logo" / fair-use file — is rejected, because a bundled asset ships in
/// the F-Droid build and must carry no `NonFreeAssets` anti-feature.
bool _licenceAccepted(String machineKey) {
  final key = machineKey.toLowerCase().trim();
  if (key.isEmpty) return false;
  // NonCommercial / NoDerivatives are not free licences.
  if (RegExp(r'(^|[-_])(nc|nd)([-_]|$)').hasMatch(key)) return false;
  if (key.contains('fair') || key.contains('non-free')) return false;
  if (key == 'pd' || key == 'publicdomain' || key.startsWith('pd-')) {
    return true;
  }
  if (key == 'cc0' || key == 'cc-zero') return true;
  return key == 'cc-by' ||
      key == 'cc-by-sa' ||
      key.startsWith('cc-by-') ||
      key.startsWith('cc-by-sa-');
}

/// The Commons licence templates we recognise, so the credits screen can
/// name the actual template ("PD-textlogo") rather than the generic
/// "Public domain" that `extmetadata` reports.
///
/// Three shapes have to be caught, and each was found in the live data:
/// the bare `{{PD-textlogo}}`, the spaced variant `{{PD-text logo}}`, and
/// the CC licence hidden as a parameter of the uploader template,
/// `{{self|cc-by-sa-4.0}}` (Ballenoil). Missing the last one made the
/// manifest record the generic "CC BY-SA 4.0" display string instead of
/// the template, which the accepted-licence test then flagged.
final RegExp _licenceTemplateRe = RegExp(
  r'\{\{\s*(?:self\s*\|\s*)?'
  r'(PD[-\w ]*|Cc-zero|CC0[-\w]*|Cc-by[-\w.,]*)\s*[|}]',
  caseSensitive: false,
);

/// The licence section of a Commons file page, with the noise that
/// produced a false "non-free" hit stripped out.
///
/// Commons pastes the ORIGINAL en.wikipedia upload log at the bottom of a
/// transferred file page, `<nowiki>`-quoted. For a logo that started life
/// as a fair-use upload before someone re-tagged it `{{PD-logo}}`, that
/// quoted history still contains the string `{{Non-free use rationale}}` —
/// which is a record of what the file USED to be tagged, not what it is.
/// Scanning the raw wikitext rejected Circle K on exactly that. Truncating
/// at the upload-log heading and dropping `<nowiki>` blocks keeps the scan
/// on the live licence section.
String _licenceSection(String wikitext) {
  var text = wikitext.replaceAll(
    RegExp(r'<nowiki>.*?</nowiki>', dotAll: true),
    ' ',
  );
  final logAt = text.indexOf(RegExp(r'\{\{\s*Original upload log'));
  if (logAt > 0) text = text.substring(0, logAt);
  return text;
}

Future<_Verdict> _auditFile(
  HttpClient client,
  String brand,
  String file,
) async {
  final title = Uri.encodeQueryComponent('File:$file');
  final json = await _getJson(
    client,
    Uri.parse('https://commons.wikimedia.org/w/api.php?action=query'
        '&format=json&titles=$title&prop=imageinfo|revisions'
        '&iiprop=url|size|extmetadata&iiurlwidth=$_thumbWidthPx'
        '&rvprop=content&rvslots=main'),
  );
  final pages = ((json['query'] as Map<String, Object?>?)?['pages']);
  if (pages is! Map<String, Object?> || pages.isEmpty) {
    return (record: null, reason: 'file page not found');
  }
  final page = pages.values.first;
  if (page is! Map<String, Object?>) {
    return (record: null, reason: 'file page not found');
  }
  final infos = page['imageinfo'];
  if (infos is! List<Object?> || infos.isEmpty) {
    return (record: null, reason: 'no imageinfo');
  }
  final info = infos.first;
  if (info is! Map<String, Object?>) {
    return (record: null, reason: 'no imageinfo');
  }
  final meta = info['extmetadata'];
  final metaMap =
      meta is Map<String, Object?> ? meta : const <String, Object?>{};

  String field(String name) {
    final entry = metaMap[name];
    if (entry is! Map<String, Object?>) return '';
    final value = entry['value'];
    return value is String ? _plainText(value) : '';
  }

  final machineKey = field('License');
  final shortName = field('LicenseShortName');
  if (!_licenceAccepted(machineKey)) {
    return (
      record: null,
      reason: 'licence "${shortName.isEmpty ? machineKey : shortName}" '
          'is not in the accepted set',
    );
  }

  final wikitext = _licenceSection(_revisionText(page));
  if (RegExp(r'\{\{\s*(non-free|fair ?use)', caseSensitive: false)
      .hasMatch(wikitext)) {
    return (record: null, reason: 'file carries a non-free/fair-use tag');
  }
  // `{{copyright claims}}` records that the depicted rights holder has
  // asserted a claim over the mark (Tesla's DMCA over its shield). The
  // file may still be hosted, but we do not bundle a contested one.
  if (RegExp(r'\{\{\s*copyright claims', caseSensitive: false)
      .hasMatch(wikitext)) {
    return (record: null, reason: 'file carries a {{copyright claims}} tag');
  }
  // Lower-cased: Commons treats template names case-insensitively and the
  // live pages spell the same tag three ways (`PD-textlogo`,
  // `pd-textlogo`, `PD-TextLogo`). Rendering all three in one credits
  // list reads as a bug rather than as verbatim data.
  final templateMatch = _licenceTemplateRe.firstMatch(wikitext);
  final template =
      (templateMatch?.group(1) ?? shortName).trim().toLowerCase();

  final thumbUrl = _renderUrl(info);
  if (thumbUrl.isEmpty) {
    return (record: null, reason: 'no rendered thumbnail available');
  }

  final author = field('Artist').isEmpty ? field('Credit') : field('Artist');
  return (
    record: LogoRecord(
      brand: brand,
      wikidataId: brandWikidataIds[brand]!,
      commonsFile: file,
      licence: shortName.isEmpty ? machineKey : shortName,
      licenceTemplate: template,
      // Never credit "Wikimedia Commons" as the author — Commons hosts
      // the file, it did not draw the mark. Its own rendering of an
      // absent `author=` is what goes in the manifest instead.
      author: author.isEmpty ? 'Unknown author' : author,
      sourceUrl: info['descriptionurl'] as String? ?? '',
      thumbUrl: thumbUrl,
      slug: _slug(brand),
    ),
    reason: '',
  );
}

/// The URL of the PNG rendering to bundle.
///
/// Commons renders SVG to PNG server-side, which is why the app needs no
/// SVG renderer and no local rasteriser. Two adjustments to the API's own
/// `thumburl`: the tracking query string is dropped, and a PORTRAIT logo
/// is re-pointed at the [_portraitWidthPx] bucket so its long edge — its
/// height — stays inside the budget.
String _renderUrl(Map<String, Object?> info) {
  final thumb = (info['thumburl'] as String? ?? '').split('?').first;
  if (thumb.isEmpty) return (info['url'] as String? ?? '').split('?').first;
  final width = info['width'];
  final height = info['height'];
  if (width is int && height is int && width > 0 && height > width) {
    return thumb.replaceFirst(RegExp(r'/\d+px-'), '/${_portraitWidthPx}px-');
  }
  return thumb;
}

String _revisionText(Map<String, Object?> page) {
  final revisions = page['revisions'];
  if (revisions is! List<Object?> || revisions.isEmpty) return '';
  final first = revisions.first;
  if (first is! Map<String, Object?>) return '';
  final slots = first['slots'];
  if (slots is! Map<String, Object?>) return '';
  final main = slots['main'];
  if (main is! Map<String, Object?>) return '';
  final content = main['*'] ?? main['content'];
  return content is String ? content : '';
}

/// Strip the HTML Commons wraps `Artist` / `Credit` in.
String _plainText(String html) {
  final text = html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
  final tidied = text
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s+\.$'), '.')
      .trim()
      // Commons links some `author=` values to a Template: page; the
      // namespace prefix survives the tag strip and is not part of the
      // name. Strip it AFTER trimming — the leading `<a>` tag leaves a
      // space in front of it.
      .replaceFirst(RegExp(r'^Template:'), '')
      .trim();
  return _undouble(tidied);
}

/// Commons renders `{{unknown|author}}` as nested spans that flatten to
/// "Unknown author Unknown author". Halve any exactly-doubled string.
String _undouble(String text) {
  final words = text.split(' ');
  if (words.length < 2 || words.length.isOdd) return text;
  final half = words.length ~/ 2;
  final first = words.sublist(0, half).join(' ');
  return first == words.sublist(half).join(' ') ? first : text;
}

const Map<String, String> _transliterations = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e',
  'ë': 'e', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u',
  'ü': 'u', 'ß': 'ss', 'ñ': 'n', 'å': 'a', 'ø': 'o', 'æ': 'ae',
};

/// A stable, canonical-name-derived asset base name.
String _slug(String brand) {
  final buffer = StringBuffer();
  for (final rune in brand.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_transliterations[char] ?? char);
  }
  final ascii = buffer
      .toString()
      .replaceAll('+', ' plus ')
      .replaceAll(RegExp(r"['’]"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return ascii.replaceAll(RegExp(r'^_+|_+$'), '');
}

Future<void> _download(HttpClient client, List<LogoRecord> records) async {
  final dir = Directory(_assetDir);
  if (dir.existsSync()) {
    for (final file in dir.listSync().whereType<File>()) {
      if (file.path.endsWith('.png')) file.deleteSync();
    }
  } else {
    dir.createSync(recursive: true);
  }
  var total = 0;
  for (final record in records) {
    final bytes = await _getBytes(client, Uri.parse(record.thumbUrl));
    File('$_assetDir/${record.assetFile}').writeAsBytesSync(bytes);
    total += bytes.length;
    stdout.writeln('  ${record.assetFile}  ${bytes.length} B');
  }
  stdout.writeln('total asset weight: ${(total / 1024).toStringAsFixed(1)} kB');
}

void _writeManifest(List<LogoRecord> records) {
  final sorted = [...records]..sort((a, b) => a.brand.compareTo(b.brand));
  final out = StringBuffer()
    ..writeln('// Copyright (c) 2026 Florian DITTGEN')
    ..writeln('// SPDX-License-Identifier: MIT')
    ..writeln()
    ..writeln('// GENERATED by `dart run tool/fetch_brand_logos.dart` '
        '(#3940).')
    ..writeln('// Do not edit by hand — re-run the tool instead. Every entry '
        'was')
    ..writeln('// licence-audited file-by-file on Wikimedia Commons; only '
        'public-domain')
    ..writeln('// and CC-BY / CC-BY-SA / CC0 files are bundled.')
    ..writeln()
    ..writeln("import 'brand_logo_manifest.dart';")
    ..writeln()
    ..writeln('/// Every bundled brand logo, sorted by canonical brand name.')
    ..writeln('const List<BrandLogoAsset> bundledBrandLogos = [');
  // Three lines per entry, not one field per line: `lib/` is under a
  // 400-line-per-file cap (#1680) that this generated file would blow
  // through at ~65 brands if each entry cost six lines.
  for (final r in sorted) {
    out
      ..writeln('  BrandLogoAsset(${_dartString(r.brand)}, '
          '${_dartString(r.assetFile)}, ${_dartString(r.wikidataId)},')
      ..writeln('      ${_dartString(r.commonsFile)}, '
          '${_dartString(r.licenceTemplate)}, ${_dartString(r.author)},')
      ..writeln('      ${_dartString(r.sourceUrl)}),');
  }
  out.writeln('];');
  File(_manifestOut).writeAsStringSync(out.toString());
  stdout.writeln('wrote $_manifestOut (${sorted.length} entries)');
}

String _dartString(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return "'$escaped'";
}

Future<Map<String, Object?>> _getJson(HttpClient client, Uri uri) async {
  final body = utf8.decode(await _getBytes(client, uri));
  final decoded = jsonDecode(body);
  return decoded is Map<String, Object?> ? decoded : <String, Object?>{};
}

Future<List<int>> _getBytes(HttpClient client, Uri uri) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      final response = await request.close();
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      return chunks;
    } on Object catch (e, st) {
      if (attempt == 3) {
        stderr.writeln('GET $uri failed: $e\n$st');
        rethrow;
      }
      await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
  }
  throw StateError('unreachable');
}
