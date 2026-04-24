# Play Store listing refresh (#594)

The Fastlane metadata under `fastlane/metadata/android/{en-US,de-DE,fr-FR}/`
was last updated when the app shipped 7 countries and 10 languages.
Current production state is 15 country configurations and 23
localisations. This doc tracks the listing refresh and the screenshot
production plan.

## What this PR does

1. Refreshes `short_description.txt` and `full_description.txt` for
   en-US, de-DE, and fr-FR with:
   - Correct country count (15).
   - Correct language count (23).
   - EV charging story (OpenChargeMap integration).
   - OBD2 / consumption logging story (Bluetooth ELM327, fill-up
     history, fuzzy calibration).
   - Updated feature list: route search, velocity alerts, vehicle
     profiles, Android home-screen widgets.
2. Adds a new entry under `changelogs/` for the next release (placeholder
   number; `build-release` bumps it at APK-build time).
3. Establishes the screenshot production plan below. The agent cannot
   render real device screenshots — the user produces them and drops
   them in `phoneScreenshots/` using the filenames listed below.

## Screenshot plan — user produces these, agent only scaffolds

Fastlane expects phone screenshots under
`fastlane/metadata/android/<locale>/images/phoneScreenshots/`. Required
dimensions: 1080x1920 (portrait) or 1920x1080 (landscape). File format
PNG or JPEG. Filename must be numerical prefix for sort order.

### Target set (8 screenshots per locale)

| # | Screen | Why it sells the app |
|---|---|---|
| 01 | Search results list with cheapest badge | Core value prop — price visible |
| 02 | Map view with marker clusters | Visual density, quick spot check |
| 03 | Station detail with price history chart | Savings timing story |
| 04 | Favorites list | Daily-use habit |
| 05 | EV charging station detail with connectors | Multi-fuel story |
| 06 | Trajets / consumption log with per-trip stats | "Save twice" — behind the wheel |
| 07 | Radius + velocity price alert settings | Smart notifications story |
| 08 | Android home-screen widget on a home screen | Glanceable |

### Locale coverage

- **en-US**, **de-DE**, **fr-FR** — mandatory (top 3 markets).
- **it-IT**, **es-ES** — nice to have; fallback to en-US is acceptable.
- Other 18 locales — Play Store auto-falls-back to en-US. Do not block
  launch on localising screenshots for every language.

### Screenshot generation options

- **Android Studio screenshot tool** — `adb exec-out screencap -p >
  file.png` on a Galaxy S23 or emulator. Raw 1080x2340; crop to
  1080x1920 or keep full-height (Play Store auto-scales).
- **screenshots.pro** — free device frames, drag-and-drop.
- **Figma with device mockup plugins** — best for a designer-polished
  look with captions.

Keep filenames stable so future listing updates only swap images:
```
fastlane/metadata/android/en-US/images/phoneScreenshots/
├── 01_search_results.png
├── 02_map_view.png
├── 03_station_detail.png
├── 04_favorites.png
├── 05_ev_station.png
├── 06_consumption_log.png
├── 07_price_alerts.png
└── 08_widget_home.png
```

### Feature graphic (1024x500)

Exists at `fastlane/metadata/android/<locale>/images/feature_graphic.png`
for all three locales but should be refreshed to include:
- The current tagline: "Smarter pump. Smarter drive. Save twice."
- Flags from 15 supported countries (or a map silhouette).
- Privacy shield badge ("No ads. No tracking.").

The existing feature graphic is a serviceable placeholder; replace it
opportunistically, not as a launch blocker.

## Autonomous agent limitation

- The agent refreshed the text (short + full descriptions, changelogs).
- The agent cannot capture app screenshots from the device. The user
  runs the app on a Galaxy S23 (per project memory), captures the eight
  scenes listed above, and drops the PNGs into `phoneScreenshots/`.
- Once the screenshots land, `fastlane supply --track production
  --skip_upload_apk` pushes the text + images to Play Console.

Until screenshots are produced the listing can still be updated with
refreshed copy; Play Console accepts metadata changes independent of
screenshots.
