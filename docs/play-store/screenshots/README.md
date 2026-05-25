<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Play Store Screenshots — drop zone + canonical set

Two-step workflow:

1. **You drop raw captures** into `inbox/`. Whatever filename your phone / tooling produced — no need to rename.
2. **`/play-store-shots` skill** classifies each capture into one of the 8 slots below, renames it to the canonical slot filename, mirrors it into the fastlane-supply tree under `docs/play-store/metadata/android/*/images/phoneScreenshots/`, and clears the inbox.

After step 2, the canonical slot images live under `published/` and the per-locale fastlane copies live under `../metadata/android/{en-US,de-DE,fr-FR}/images/phoneScreenshots/`. The CI workflow at `.github/workflows/play-store-listing.yml` uploads from there.

## Slot conventions

Phone screenshots — Google Play accepts 2–8 images, 16:9 or 9:16, 320–3840 px on the long edge. Suggested set, in display order:

| Slot | Canonical filename | Shows |
|---|---|---|
| 1 | `01-search-results-unified.png` | Unified fuel + EV search results around the user's location |
| 2 | `02-station-detail-with-history.png` | Station detail screen with the 30-day price chart + best-time banner |
| 3 | `03-map-with-cheapest-pin.png` | Map view with the cheapest-pin highlighted |
| 4 | `04-favorites-and-alerts.png` | Favorites list + the price-alert configuration sheet |
| 5 | `05-trip-recording-active.png` | Trip-recording screen mid-recording (live OBD2 stats) |
| 6 | `06-trip-history-with-insights.png` | Trip detail with hard-accel markers + driving insights card |
| 7 | `07-cross-border-suggestion.png` | Cross-border savings hint (e.g. FR → DE / DE → CZ) |
| 8 | `08-settings-and-themes.png` | Profile / settings showing language + theme chooser |

Skip slots that do not yet have a clean shot — the listing tolerates 2–8 images. **Slot 1 is mandatory** (Play Store search-result thumbnail).

## Format requirements

- PNG, 1080 × 1920 (or 1080 × 2400 for tall phones) — Play Console rejects images outside the 320–3840 px range on the long edge.
- File size ≤ 8 MB per Play Console.
- Replace files in place when refreshing — same canonical filename, new image. Do NOT add suffixes like `01-search-results-unified-v2.png`; git history is the version axis.

## Filename hints for the classifier

When you drop a capture into `inbox/`, the `/play-store-shots` skill first tries to slot it from the filename. To make that easy, name the capture with any one of these substrings:

- `search` / `results` / `unified` → slot 1
- `detail` / `history` / `chart` / `best-time` → slot 2
- `map` / `cheapest` / `pin` → slot 3
- `favorit` / `alert` → slot 4 (NB: covers `favorite`, `favorites`, `favoritos`, etc.)
- `recording` / `obd2` / `live` → slot 5
- `trip` / `accel` / `insight` → slot 6
- `cross-border` / `border` / `savings` → slot 7
- `settings` / `theme` / `language` → slot 8

If no substring matches, the skill prompts you for the slot number.

## Refresh cadence

- After every change to a screen visible above (search results layout, trip-recording UI, settings).
- Before every Play Console listing update — the listing-refresh tracker is **#1473**, label `area/play-store`.
- Dark-mode variants live under `published/dark/<same-filenames>` if we choose to ship a dark-mode listing later.

## What lives where

```
docs/play-store/
├── DATA_SAFETY.md                              # Play Console Data Safety form responses
├── metadata/android/                           # fastlane supply structure (CI uploads from here)
│   ├── en-US/
│   │   ├── title.txt
│   │   ├── short_description.txt
│   │   ├── full_description.txt
│   │   ├── changelogs/default.txt
│   │   └── images/phoneScreenshots/<NN>_*.png  # mirrored from published/ by the skill
│   ├── de-DE/  (same shape)
│   └── fr-FR/  (same shape)
└── screenshots/
    ├── README.md       (this file)
    ├── inbox/          # drop your raw captures here — any filename
    └── published/      # canonical slot-named images, source of truth
```

The feature graphic (`docs/play-store/feature-graphic.png`, 1024 × 500) and app icon (`docs/icon.png`, 512 × 512) live one level up — they are not phone screenshots and are tracked separately.
