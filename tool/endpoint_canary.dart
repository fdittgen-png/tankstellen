// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Country-endpoint canary (#3199, under epic #3186).
//
// Live-probes each shipped country service's endpoint (HEAD / minimal GET
// reachability + a minimal response-shape check) so a silent endpoint
// death (the CL-404 / GR-NXDOMAIN / RO-404 / UK-withdrawal class of rot)
// is caught in days, not months. Run weekly by
// `.github/workflows/endpoint-canary.yml`, which opens/updates a single
// tracking issue when any active endpoint is dead.
//
// Design constraints:
//  - Pure `dart:io` / `dart:convert` — no `package:flutter` imports, so it
//    runs on the plain Dart VM (`dart tool/endpoint_canary.dart`). That is
//    why the probe URLs are declared HERE rather than imported from the
//    service classes: every country service imports Flutter. Each entry
//    documents the service file whose `defaultBaseUrl` it mirrors — keep
//    them in sync when an endpoint constant changes.
//  - "Needs key" / "known geo-blocked" / "no live endpoint" targets are
//    SKIPPED, not failed — a canary that cries wolf weekly gets muted.
//    Probes that work keyless (e.g. the public Tankerkönig demo key, or
//    OPINET's envelope-on-any-key behaviour) stay active.
//  - Exit codes: 0 = every active endpoint healthy, 1 = at least one dead,
//    2 = usage error. `--dry-run` prints the probe plan without touching
//    the network and always exits 0.
//
// Usage:
//   dart tool/endpoint_canary.dart [--dry-run] [--timeout=25]
//       [--markdown-out=<path>]

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Why a target is excluded from live probing.
enum SkipReason {
  /// Endpoint requires a registered API key / OAuth credentials that the
  /// canary must not carry (no secrets in this workflow).
  needsKey,

  /// Endpoint is known to be unreachable from EU-based runners.
  geoBlocked,

  /// Country ships static/regulated data — there is no live endpoint.
  noEndpoint,
}

class CanaryTarget {
  const CanaryTarget({
    required this.country,
    required this.name,
    this.url,
    this.method = 'GET',
    this.bodyMarker,
    this.headers = const {},
    this.skip,
    this.note = '',
  });

  /// ISO country code as used by `buildRawCountryService`.
  final String country;

  /// Human-readable provider name.
  final String name;

  /// Probe URL (null only for skipped targets without an endpoint).
  final String? url;

  /// `GET` or `HEAD`. HEAD for bulk files where a body read is wasteful.
  final String method;

  /// Substring expected in the first 64 KiB of a GET body — the minimal
  /// shape check that catches a "200 but the API moved" soft-404.
  final String? bodyMarker;

  /// Extra request headers, for endpoints that content-negotiate (#3457 —
  /// the RO WCF backend serves XML unless `Accept: application/json`).
  final Map<String, String> headers;

  /// Non-null → target is skipped (reported, never failed).
  final SkipReason? skip;

  /// Context: issue refs, key requirements, source service file.
  final String note;
}

/// One probe target per shipped country (mirrors the `buildRawCountryService`
/// switch in `lib/core/services/country_raw_service_builder.dart`). URLs
/// mirror each service's `defaultBaseUrl` — see the file referenced in each
/// note. Markers were calibrated against the live responses on 2026-06-10.
const List<CanaryTarget> targets = [
  CanaryTarget(
    country: 'DE',
    name: 'Tankerkönig',
    url: 'https://creativecommons.tankerkoenig.de/json/list.php'
        '?lat=52.521&lng=13.438&rad=2&sort=dist&type=all'
        '&apikey=00000000-0000-0000-0000-000000000002',
    bodyMarker: '"ok"',
    note: 'germany/tankerkoenig_station_service.dart — uses the public '
        'documented demo key, not a secret.',
  ),
  CanaryTarget(
    country: 'FR',
    name: 'Prix-Carburants (data.economie.gouv.fr)',
    url: 'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets'
        '/prix-des-carburants-en-france-flux-instantane-v2/records?limit=1',
    bodyMarker: '"total_count"',
    note: 'france/prix_carburants_station_service.dart (shipped legacy '
        'path; the flux bulk variant is flag-gated off).',
  ),
  CanaryTarget(
    country: 'AT',
    name: 'E-Control Spritpreisrechner',
    url: 'https://api.e-control.at/sprit/1.0/search/gas-stations/by-address'
        '?latitude=48.2082&longitude=16.3738&fuelType=DIE&includeClosed=false',
    bodyMarker: '"location"',
    note: 'austria/econtrol_station_service.dart',
  ),
  CanaryTarget(
    country: 'ES',
    name: 'Geoportal Gasolineras (MITECO)',
    url: 'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes'
        '/PreciosCarburantes/Listados/Provincias/',
    bodyMarker: '"Provincia"',
    note: 'spain/miteco_station_service.dart — probes the small Provincias '
        'listing instead of the multi-MB station dump.',
  ),
  CanaryTarget(
    country: 'IT',
    name: 'Osservaprezzi (MISE/MIMIT)',
    url: 'https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv',
    method: 'HEAD',
    note: 'italy/mise_station_service.dart — HEAD only, the CSV is large.',
  ),
  CanaryTarget(
    country: 'DK',
    name: 'OK mobility prices',
    url: 'https://mobility-prices.ok.dk/api/v1/fuel-prices',
    bodyMarker: '"items"',
    note: 'denmark/denmark_station_service.dart (primary of the two '
        'Danish feeds).',
  ),
  CanaryTarget(
    country: 'AR',
    name: 'Energía Argentina (datos.energia.gob.ar)',
    url: 'https://datos.energia.gob.ar/dataset/',
    skip: SkipReason.geoBlocked,
    note: 'argentina/argentina_station_service.dart — connection times out '
        'from EU networks (verified 2026-06-10); see #3199.',
  ),
  CanaryTarget(
    country: 'PT',
    name: 'DGEG Preços Combustíveis',
    url: 'https://precoscombustiveis.dgeg.gov.pt/api/PrecoComb'
        '/PesquisarPostos?idsTiposComb=3201&qtdPorPagina=1&pagina=1',
    bodyMarker: '"resultado"',
    note: 'portugal/portugal_station_service.dart',
  ),
  CanaryTarget(
    country: 'GB',
    name: 'UK retailer feeds (legacy fan-out, Applegreen sentinel)',
    url: 'https://applegreenstores.com/fuel-prices/data.json',
    bodyMarker: '"stations"',
    note: 'uk/uk_station_service.dart — probes one keyless retailer feed of '
        'the legacy fan-out (now the GB fallback path, #3190). NOTE: '
        'reachability only; the voluntary CMA scheme was withdrawn and feeds '
        'may serve stale data. The statutory Fuel Finder primary '
        '(www.fuel-finder.service.gov.uk/api/v1/pfs, '
        'uk_fuel_finder_feed.dart) requires OAuth2 client credentials, so it '
        'cannot be probed keylessly.',
  ),
  CanaryTarget(
    country: 'AU',
    name: 'NSW FuelCheck',
    skip: SkipReason.needsKey,
    note: 'australia/australia_station_service.dart — service is documented '
        'unavailable (#804): the replacement api.nsw.gov.au product needs '
        'OAuth2 client credentials.',
  ),
  CanaryTarget(
    country: 'MX',
    name: 'CRE México (publicacionexterna)',
    url: 'https://publicacionexterna.azurewebsites.net/publicaciones/prices',
    bodyMarker: '<places',
    note: 'mexico/mexico_station_service.dart — GET reading only the first '
        '64 KiB of the multi-MB XML (the server rejects HEAD with 405).',
  ),
  CanaryTarget(
    country: 'LU',
    name: 'Luxembourg (regulated prices)',
    skip: SkipReason.noEndpoint,
    note: 'luxembourg/luxembourg_station_service.dart — static decree '
        'prices, no live endpoint by design (#574).',
  ),
  CanaryTarget(
    country: 'SI',
    name: 'goriva.si',
    url: 'https://goriva.si/api/v1/search/?position=Ljubljana&radius=5000',
    bodyMarker: '"results"',
    note: 'slovenia/slovenia_station_service.dart',
  ),
  CanaryTarget(
    country: 'KR',
    name: 'OPINET (KNOC)',
    url: 'https://www.opinet.co.kr/api/aroundAll.do'
        '?out=json&x=127.0287&y=37.4997&radius=3000&prodcd=B027&sort=1'
        '&code=canary',
    bodyMarker: '"RESULT"',
    note: 'south_korea/south_korea_station_service.dart — OPINET answers '
        'any key with the RESULT envelope (verified 2026-06-10), so the '
        'path + shape are probeable keylessly. Coordinate gap: #3192.',
  ),
  CanaryTarget(
    country: 'CL',
    name: 'CNE Bencina en Línea',
    url: 'https://api.cne.cl/api/v4/estaciones',
    skip: SkipReason.needsKey,
    note: 'chile/chile_station_service.dart — official v4 API requires an '
        'Authorization: Bearer token (#3200).',
  ),
  CanaryTarget(
    country: 'GR',
    name: 'Self-published GR fuel prices (fuel-gr release, #3549)',
    // The app's PRIMARY Greek source: our own release asset, rebuilt
    // business-daily by gr-fuel-publish.yml from the official ministry
    // PDFs. Same row shape as the mirror below, so the same bodyMarker
    // probes it. A DEAD here means the publish pipeline broke — the app
    // degrades to the mirror automatically, but fix the workflow.
    url: 'https://github.com/fdittgen-png/tankstellen/releases/download/'
        'fuel-gr/latest.json',
    bodyMarker: 'AUTOMOTIVE_DIESEL',
    note: 'greece/greece_station_service.dart — defaultSelfPublishedUrl '
        '(#3549). Publisher: .github/workflows/gr-fuel-publish.yml + '
        'tool/gr_fuel/.',
  ),
  CanaryTarget(
    country: 'GR',
    name: 'FuelPricesGreeceAPI community mirror',
    // Fixed historical window: probes reachability + shape (not
    // freshness) without needing a dynamic date. The x-api-key is the
    // PUBLIC one from the project README (see greece_station_service).
    url: 'https://5fcbs3i0z4.execute-api.eu-west-3.amazonaws.com/v2/data'
        '?start_date=2026-07-01&end_date=2026-07-09&offset=0',
    headers: {'x-api-key': 'VH5AaWqgBchJw3a8yOkq5i5nVJ0hNMl5mwzkPMm1'},
    bodyMarker: 'AUTOMOTIVE_DIESEL',
    note: 'greece/greece_station_service.dart — #3539 restore after '
        'fuelpricesgr.com died NXDOMAIN (#3194). Hobbyist-run mirror of '
        'the ministry bulletins; since #3549 it is the FALLBACK behind '
        'the self-published release asset above.',
  ),
  CanaryTarget(
    country: 'RO',
    name: 'Monitorul Prețurilor (monitorulpreturilor.info)',
    url: 'https://monitorulpreturilor.info/pmonsvc/Gas/GetGasItemsByLatLon'
        '?lon=26.10&lat=44.43&buffer=5000&CSVGasCatalogProductIds=11'
        '&OrderBy=dist',
    headers: {'Accept': 'application/json'},
    bodyMarker: '"Stations"',
    skip: SkipReason.geoBlocked,
    note: 'romania/romania_station_service.dart — the endpoint is ALIVE for '
        'real users (verified 2026-07-09 via Dart HttpClient from a '
        'residential network: HTTP 200 + full Stations payload) but the WCF '
        'front-end rejects the TLS handshake from GitHub-runner/datacenter '
        'IPs (HandshakeException on 2026-07-06 AND 2026-07-09 runs — two '
        'consecutive false DEADs, #3508). Same probeable-not-from-CI family '
        'as the AR geo-block; re-probe manually from a residential network '
        'when touching the RO service (#3457 has the probe recipe).',
  ),
];

const String _userAgent =
    'tankstellen-endpoint-canary/1.0 (+https://github.com/fdittgen-png)';

/// Max body bytes read for the marker check — enough for every calibrated
/// marker (all appear in the first KB) without downloading bulk payloads.
const int _maxBodyBytes = 64 * 1024;

class ProbeResult {
  const ProbeResult(this.target, {required this.ok, required this.detail});
  final CanaryTarget target;
  final bool ok;
  final String detail;
}

Future<ProbeResult> probe(CanaryTarget t, Duration timeout) async {
  final client = HttpClient()..userAgent = _userAgent;
  client.connectionTimeout = timeout;
  try {
    final uri = Uri.parse(t.url!);
    final request = await client.openUrl(t.method, uri).timeout(timeout);
    request.followRedirects = true;
    t.headers.forEach(request.headers.set);
    final response = await request.close().timeout(timeout);
    final status = response.statusCode;

    if (status < 200 || status >= 300) {
      await response.drain<void>().catchError((_) {});
      return ProbeResult(t, ok: false, detail: 'HTTP $status');
    }

    if (t.method == 'HEAD' || t.bodyMarker == null) {
      await response.drain<void>().catchError((_) {});
      return ProbeResult(t, ok: true, detail: 'HTTP $status');
    }

    // Read at most [_maxBodyBytes], then stop — bulk endpoints (MX XML)
    // serve multi-MB payloads whose first bytes already carry the marker.
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(timeout)) {
      buffer.add(chunk);
      if (buffer.length >= _maxBodyBytes) break;
    }
    final body = utf8.decode(buffer.takeBytes(), allowMalformed: true);
    if (!body.contains(t.bodyMarker!)) {
      return ProbeResult(t,
          ok: false,
          detail: 'HTTP $status but marker ${t.bodyMarker} missing '
              '(soft-404 / shape drift?)');
    }
    return ProbeResult(t, ok: true, detail: 'HTTP $status, marker found');
  } on TimeoutException {
    return ProbeResult(t,
        ok: false, detail: 'timeout after ${timeout.inSeconds}s');
  } catch (e) {
    return ProbeResult(t, ok: false, detail: e.toString().split('\n').first);
  } finally {
    client.close(force: true);
  }
}

String _skipLabel(SkipReason r) => switch (r) {
      SkipReason.needsKey => 'SKIP (needs key)',
      SkipReason.geoBlocked => 'SKIP (geo-blocked)',
      SkipReason.noEndpoint => 'SKIP (no live endpoint)',
    };

String buildMarkdown(List<ProbeResult> results, List<CanaryTarget> skipped) {
  final failed = results.where((r) => !r.ok).toList();
  final b = StringBuffer()
    ..writeln('## Endpoint canary report')
    ..writeln()
    ..writeln('Probed ${results.length} live endpoints, '
        '${skipped.length} skipped, **${failed.length} dead**.')
    ..writeln()
    ..writeln('| Country | Provider | Status | Detail |')
    ..writeln('|---|---|---|---|');
  for (final r in results) {
    b.writeln('| ${r.target.country} | ${r.target.name} | '
        '${r.ok ? 'OK' : 'DEAD'} | ${r.detail} |');
  }
  for (final t in skipped) {
    b.writeln('| ${t.country} | ${t.name} | ${_skipLabel(t.skip!)} | '
        '${t.note} |');
  }
  if (failed.isNotEmpty) {
    b
      ..writeln()
      ..writeln('### Dead endpoints')
      ..writeln();
    for (final r in failed) {
      b
        ..writeln('- **${r.target.country} — ${r.target.name}**: '
            '${r.detail}')
        ..writeln('  - `${r.target.url}`')
        ..writeln('  - ${r.target.note}');
    }
  }
  return b.toString();
}

Future<int> run(List<String> args) async {
  var dryRun = false;
  String? markdownOut;
  var timeoutSeconds = 25;

  for (final arg in args) {
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg.startsWith('--markdown-out=')) {
      markdownOut = arg.substring('--markdown-out='.length);
    } else if (arg.startsWith('--timeout=')) {
      timeoutSeconds = int.parse(arg.substring('--timeout='.length));
    } else {
      stderr.writeln('Unknown argument: $arg');
      stderr.writeln('Usage: dart tool/endpoint_canary.dart [--dry-run] '
          '[--timeout=25] [--markdown-out=<path>]');
      return 2;
    }
  }

  final active = targets.where((t) => t.skip == null).toList();
  final skipped = targets.where((t) => t.skip != null).toList();

  if (dryRun) {
    stdout.writeln('Endpoint canary probe plan '
        '(${active.length} active, ${skipped.length} skipped):');
    for (final t in active) {
      stdout.writeln('  PROBE ${t.country.padRight(3)} ${t.method.padRight(4)} '
          '${t.url}${t.bodyMarker != null ? '  [marker: ${t.bodyMarker}]' : ''}');
    }
    for (final t in skipped) {
      stdout.writeln('  ${_skipLabel(t.skip!).padRight(24)} ${t.country} — '
          '${t.note}');
    }
    return 0;
  }

  final timeout = Duration(seconds: timeoutSeconds);
  final results =
      await Future.wait(active.map((t) => probe(t, timeout)));

  for (final r in results) {
    stdout.writeln('${r.ok ? 'OK  ' : 'DEAD'} ${r.target.country.padRight(3)} '
        '${r.target.name}: ${r.detail}');
  }
  for (final t in skipped) {
    stdout.writeln('${_skipLabel(t.skip!)} ${t.country} ${t.name}');
  }

  final markdown = buildMarkdown(results, skipped);
  if (markdownOut != null) {
    File(markdownOut).writeAsStringSync(markdown);
    stdout.writeln('Markdown report written to $markdownOut');
  }

  final deadCount = results.where((r) => !r.ok).length;
  stdout.writeln('Canary summary: ${results.length - deadCount}/'
      '${results.length} live endpoints healthy, '
      '${skipped.length} skipped, $deadCount dead.');
  return deadCount == 0 ? 0 : 1;
}

Future<void> main(List<String> args) async {
  exitCode = await run(args);
}
