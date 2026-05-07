# Play Store Screenshots

Drop fresh device screenshots here. The Play Console listing in the issue tracker references the file paths in this directory, so the same set is reused across en-US / de-DE / fr-FR locales.

## Slot conventions

Phone screenshots — Google Play allows 2–8 images, 16:9 or 9:16, 320–3840 px on the long edge. Suggested set, in display order:

| Slot | Filename | Shows |
|---|---|---|
| 1 | `01-search-results-unified.png` | Unified fuel + EV search results around the user's location |
| 2 | `02-station-detail-with-history.png` | Station detail screen with the 30-day price chart + best-time banner |
| 3 | `03-map-with-cheapest-pin.png` | Map view with the cheapest-pin highlighted |
| 4 | `04-favorites-and-alerts.png` | Favorites list + the price-alert configuration sheet |
| 5 | `05-trip-recording-active.png` | Trip-recording screen mid-recording (live OBD2 stats) |
| 6 | `06-trip-history-with-insights.png` | Trip detail with hard-accel markers + driving insights card |
| 7 | `07-cross-border-suggestion.png` | Cross-border savings hint (e.g. FR → DE / DE → CZ) |
| 8 | `08-settings-and-themes.png` | Profile / settings showing language + theme chooser |

Skip slots that do not yet have a clean shot — the listing tolerates 2–8 images. Slot 1 is the **most important** (Play Store search-result thumbnail).

## Naming + format

- PNG, 1080 × 1920 (or 1080 × 2400 for tall phones) — Play Console rejects images outside the 320–3840 px range on the long edge.
- Snake-case, prefixed with the slot number so the directory listing matches the upload order.
- Replace files in place when refreshing — same filename, new image. Do NOT add suffixes like `01-search-results-unified-v2.png`; git history is the version axis.

## Refresh cadence

- After every change to a screen visible above (search results layout, trip-recording UI, settings).
- After every theme system update (a screenshot of the dark variant lives under `dark/<same-filenames>` if we choose to ship a dark-mode listing too — currently single-theme-only).
- Before every Play Console listing update. The listing-update issue (see GitHub Issues, label `area/play-store`) is the trigger.

## Feature graphic + icon

Lives one level up at `docs/play-store/feature-graphic.png` (1024 × 500) and `docs/icon.png` (512 × 512) respectively — those are sized for Play Console's hero slots and are not phone screenshots.

This `screenshots/` subdirectory is **only** for the rotating phone screenshot set above.
