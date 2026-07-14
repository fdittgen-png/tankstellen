#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT
"""#3549 — self-published Greek fuel prices.

Fetches the Greek ministry's official daily-prefecture PDF bulletins
(`IMERISIO_DELTIO_ANA_NOMO_<DD_MM_YYYY>.pdf` on fuelprices.gr) for the
last LOOKBACK_DAYS, parses them with the vendored mavroprovato/fuelpricesgr
parser (MIT), and writes `latest.json` with rows shaped EXACTLY like the
emvouvakis FuelPricesGreeceAPI mirror's `/v2/data` response — so
`GreeceStationService` consumes either source with the same codec:

    {"DATE": "2026-07-13", "REGION": "N. ATHINON",
     "UNLEADED_95_Octane": 1.956, "UNLEADED_100_OCTANE": 2.165,
     "AUTOMOTIVE_DIESEL": 1.839, "AUTOGAS": 0.899,
     "HOME_HEATING_DIESEL": null, "Super": null}

The REGION codes are the observatory's transliterated prefecture codes the
app's `GreekPrefecture.apiName` values already match. The mapping below was
DERIVED FROM DATA, not transliteration: for 2026-07-13 every one of the 51
parsed PDF price vectors matched exactly one mirror row's vector (51/51
unique matches, zero ambiguity).

Run: python3 (>= 3.10, the parser uses `match`) publish_gr_fuel.py [outfile]
Deps: pypdf
"""

import datetime
import json
import sys
import urllib.error
import urllib.request

from fuelpricesgr import enums, parser

PDF_URL = (
    'https://www.fuelprices.gr/files/deltia/'
    'IMERISIO_DELTIO_ANA_NOMO_{d:%d_%m_%Y}.pdf'
)

# Business-daily bulletins can lag over weekends / holidays; a week of
# lookback mirrors GreeceStationService.lookback.
LOOKBACK_DAYS = 7

# Parser FuelType value -> mirror column name. DIESEL_HEATING / SUPER are
# published for shape parity but ignored by the app (droppedObservatoryKeys).
FUEL_COLUMNS = {
    'UNLEADED_95': 'UNLEADED_95_Octane',
    'UNLEADED_100': 'UNLEADED_100_OCTANE',
    'DIESEL': 'AUTOMOTIVE_DIESEL',
    'GAS': 'AUTOGAS',
    'DIESEL_HEATING': 'HOME_HEATING_DIESEL',
    'SUPER': 'Super',
}

# Parser Prefecture value -> observatory REGION code (data-derived, see
# module docstring). All 51 prefectures.
REGIONS = {
    'ACHAEA': 'N. ACHAIAS',
    'AETOLIA_ACARNANIA': 'N. ETOLOAKARNANIAS',
    'ARGOLIS': 'N. ARGOLIDAS',
    'ARKADIAS': 'N. ARKADIAS',
    'ARTA': 'N. ARTAS',
    'ATTICA': 'N. ATHINON',
    'BOEOTIA': 'N. VIOTIAS',
    'CEPHALONIA': 'N. KEFALLONIAS',
    'CHALKIDIKI': 'N. CHALKIDIKIS',
    'CHANIA': 'N. CHANION',
    'CHIOS': 'N. CHIOU',
    'CORINTHIA': 'N. KORINTHOU',
    'CYCLADES': 'N. KYKLADON',
    'DODECANESE': 'N. DODEKANISON',
    'DRAMA': 'N. DRAMAS',
    'ELIS': 'N. ILIAS',
    'EUBOEA': 'N. EVVIAS',
    'EVROS': 'N. EVROU',
    'EVRYTANIA': 'N. EVRYTANIAS',
    'FLORINA': 'N. FLORINAS',
    'GREVENA': 'N. GREVENON',
    'HERAKLION': 'N. IRAKLIOU',
    'IMATHIA': 'N. IMATHIAS',
    'IOANNINA': 'N. IOANNINON',
    'KARDITSA': 'N. KARDITSAS',
    'KASTORIA': 'N. KASTORIAS',
    'KAVALA': 'N. KAVALAS',
    'KERKYRA': 'N. KERKYRAS',
    'KILKIS': 'N. KILKIS',
    'KOZANI': 'N. KOZANIS',
    'LACONIA': 'N. LAKONIAS',
    'LARISSA': 'N. LARISAS',
    'LASITHI': 'N. LASITHIOU',
    'LEFKADA': 'N. LEFKADAS',
    'LESBOS': 'N. LESVOU',
    'MAGNESIA': 'N. MAGNISIAS',
    'MESSENIA': 'N. MESSINIAS',
    'PELLA': 'N. PELLAS',
    'PHOCIS': 'N. FOKIDAS',
    'PHTHIOTIS': 'N. FTHIOTIDAS',
    'PIERIA': 'N. PIERIAS',
    'PREVEZA': 'N. PREVEZAS',
    'RETHYMNO': 'N. RETHYMNOU',
    'RHODOPE': 'N. RODOPIS',
    'SAMOS': 'N. SAMOU',
    'SERRES': 'N. SERRON',
    'THESPROTIA': 'N. THESPROTIAS',
    'THESSALONIKI': 'N. THESSALONIKIS',
    'TRIKALA': 'N. TRIKALON',
    'XANTHI': 'N. XANTHIS',
    'ZAKYNTHOS': 'N. ZAKYNTHOU',
}


def fetch_pdf(date: datetime.date) -> bytes | None:
    """Download one day's bulletin; None when it does not exist.

    A missing date returns a small HTML error page, so besides HTTP
    errors we verify the PDF magic bytes.
    """
    url = PDF_URL.format(d=date)
    req = urllib.request.Request(url, headers={'User-Agent': 'tankstellen-gr-fuel/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
    except (urllib.error.URLError, TimeoutError) as ex:
        print(f'  {date}: fetch failed ({ex})', file=sys.stderr)
        return None
    if not data.startswith(b'%PDF'):
        print(f'  {date}: no bulletin (non-PDF body, {len(data)} bytes)')
        return None
    return data


def rows_for(date: datetime.date, pdf: bytes) -> list[dict]:
    """Parse one bulletin into mirror-shaped rows."""
    parsed = parser.Parser.get(enums.DataFileType.DAILY_PREFECTURE).parse(date, pdf)
    per_prefecture: dict[str, dict] = {}
    for entry in parsed.get(enums.DataType.DAILY_PREFECTURE, []):
        region = REGIONS[entry['prefecture']]
        column = FUEL_COLUMNS[entry['fuel_type']]
        row = per_prefecture.setdefault(region, {
            'DATE': date.isoformat(),
            'REGION': region,
            'UNLEADED_95_Octane': None,
            'UNLEADED_100_OCTANE': None,
            'AUTOMOTIVE_DIESEL': None,
            'AUTOGAS': None,
            'HOME_HEATING_DIESEL': None,
            'Super': None,
        })
        row[column] = float(entry['price'])
    return sorted(per_prefecture.values(), key=lambda r: r['REGION'])


def main() -> int:
    outfile = sys.argv[1] if len(sys.argv) > 1 else 'latest.json'
    today = datetime.date.today()
    rows: list[dict] = []
    days_found = 0
    for back in range(LOOKBACK_DAYS):
        date = today - datetime.timedelta(days=back)
        pdf = fetch_pdf(date)
        if pdf is None:
            continue
        day_rows = rows_for(date, pdf)
        print(f'  {date}: {len(day_rows)} prefectures')
        rows.extend(day_rows)
        days_found += 1
    if days_found == 0:
        print('FATAL: no bulletin found in the whole lookback window',
              file=sys.stderr)
        return 1
    with open(outfile, 'w', encoding='utf-8') as f:
        json.dump(rows, f, ensure_ascii=False, separators=(',', ':'))
    print(f'wrote {outfile}: {len(rows)} rows from {days_found} day(s)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
