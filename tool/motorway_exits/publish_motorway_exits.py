# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT
"""#3633 — extract motorway exits per supported country from OpenStreetMap.

One Overpass query per country pulls every `highway=motorway_junction`
node (position + `ref` exit number + optional `name`) and writes a
compact JSON per country:

    {"v": 1, "cc": "FR", "generatedAt": "…", "exits":
      [{"la": 48.85123, "lo": 2.35456, "r": "36", "n": "Saint-Thibéry"}, …]}

Coordinates are rounded to 5 decimals (~1.1 m) — far below the app's
lateral thresholds — which roughly halves the payload. Exits change on
the timescale of years, so the publish cadence is monthly.

Usage: python3 publish_motorway_exits.py <out-dir> [CC …]
(default: every supported country).

Rate-limit etiquette: Overpass is donated infrastructure. One query per
country, a courtesy sleep between queries, bounded retries with backoff
across the public mirror pool, and a descriptive User-Agent.
"""

from __future__ import annotations

import json
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# The app's supported countries (lib/core/country/country_config_data*).
# KR/AU/CL/MX/AR are served too — motorway_junction tagging is global.
COUNTRIES = [
    "AR", "AT", "AU", "CL", "DE", "DK", "ES", "FR", "GB",
    "GR", "IT", "KR", "LU", "MX", "PT", "RO", "SI",
]

MIRRORS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]

USER_AGENT = (
    "tankstellen-motorway-exits/1.0 "
    "(+https://github.com/fdittgen-png/tankstellen; monthly batch)"
)

QUERY = """
[out:json][timeout:300];
area["ISO3166-1"="{cc}"][admin_level=2]->.c;
node["highway"="motorway_junction"](area.c);
out;
"""


def fetch(cc: str) -> dict:
    data = urllib.parse.urlencode({"data": QUERY.format(cc=cc)}).encode()
    last: Exception | None = None
    for attempt in range(4):
        mirror = MIRRORS[attempt % len(MIRRORS)]
        req = urllib.request.Request(
            mirror, data=data, headers={"User-Agent": USER_AGENT}
        )
        try:
            with urllib.request.urlopen(req, timeout=240) as resp:
                return json.load(resp)
        except Exception as e:  # noqa: BLE001 — retried, surfaced on exhaust
            last = e
            wait = 20 * (attempt + 1)
            print(f"  {cc}: attempt {attempt + 1} failed ({e}); "
                  f"retrying in {wait}s", flush=True)
            time.sleep(wait)
    raise RuntimeError(f"{cc}: Overpass exhausted: {last}")


def compact(cc: str, raw: dict) -> dict:
    # An Overpass timeout/overload often returns HTTP 200 with a `remark`
    # and few/no elements — a SILENT EMPTY that shipped a 77-byte
    # exits_de.json on the first run. Surface it as a failure instead.
    remark = raw.get("remark")
    if remark:
        raise RuntimeError(f"{cc}: Overpass remark: {remark}")
    exits = []
    for el in raw.get("elements", []):
        if el.get("type") != "node":
            continue
        tags = el.get("tags", {})
        entry = {
            "la": round(el["lat"], 5),
            "lo": round(el["lon"], 5),
        }
        ref = tags.get("ref")
        if ref:
            entry["r"] = ref
        name = tags.get("name")
        if name:
            entry["n"] = name
        exits.append(entry)
    exits.sort(key=lambda e: (e["la"], e["lo"]))
    return {
        "v": 1,
        "cc": cc,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "exits": exits,
    }


def main() -> int:
    out_dir = Path(sys.argv[1])
    out_dir.mkdir(parents=True, exist_ok=True)
    countries = sys.argv[2:] or COUNTRIES
    failures = []
    for cc in countries:
        print(f"{cc}: querying Overpass …", flush=True)
        try:
            payload = compact(cc, fetch(cc))
        except Exception as e:  # noqa: BLE001 — collected, run continues
            print(f"  {cc}: FAILED — {e}", flush=True)
            failures.append(cc)
            continue
        # Every supported country has a motorway network; zero exits is
        # always a query failure (area resolution / truncation), never
        # reality. Publishing an empty asset would silently downgrade
        # that country to v1 for a month — fail it instead (the app
        # keeps the previous cached copy).
        if not payload["exits"]:
            print(f"  {cc}: FAILED — query returned ZERO exits", flush=True)
            failures.append(cc)
            continue
        out = out_dir / f"exits_{cc.lower()}.json"
        out.write_text(json.dumps(payload, separators=(",", ":"),
                                  ensure_ascii=False))
        print(f"  {cc}: {len(payload['exits'])} exits → {out.name} "
              f"({out.stat().st_size} bytes)", flush=True)
        time.sleep(10)  # courtesy gap between country queries
    if failures:
        # Partial publishes are fine (each country is its own asset and
        # the app keeps its previous cached copy) — but the run must go
        # red so the gap is visible and the next run retries.
        print(f"FAILED countries: {', '.join(failures)}", flush=True)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
