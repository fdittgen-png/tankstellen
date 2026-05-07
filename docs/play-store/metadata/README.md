# Play Store metadata (fastlane supply layout)

Source of truth for the Google Play Console listing copy. The CI workflow at `.github/workflows/play-store-listing.yml` uploads from this directory.

## Layout

```
metadata/android/
├── <locale>/
│   ├── title.txt                     ≤ 30 chars
│   ├── short_description.txt         ≤ 80 chars
│   ├── full_description.txt          ≤ 4000 chars
│   ├── changelogs/
│   │   ├── default.txt               fallback if no per-versionCode file
│   │   └── <versionCode>.txt         release-specific notes ≤ 500 chars
│   └── images/
│       ├── phoneScreenshots/         01_*.png … 08_*.png (mirrored from ../../../screenshots/published/ by /play-store-shots)
│       ├── featureGraphic/           1024 × 500 hero (one PNG)
│       └── icon/                     512 × 512 (one PNG)
```

Locales currently in scope: `en-US`, `de-DE`, `fr-FR`. Add more by creating a sibling directory with the same shape.

## Editing rules

- **Length budgets are enforced by Play Console upload** — over-long copy is rejected with a clear error. Keep titles tight; the long description carries the value-prop.
- **`changelogs/default.txt`** is what ships when the workflow runs without a matching `<versionCode>.txt`. Replace it before every listing refresh — Play Console exposes "What's new" prominently.
- **No HTML in `full_description.txt`** — Play Store strips it, occasionally wrong. Plain text + line breaks only.
- **Wiki link** lives at the bottom of `full_description.txt` — `https://github.com/fdittgen-png/tankstellen/wiki`. Update only if the repo URL changes.

## Sync from screenshots

Phone screenshots in `<locale>/images/phoneScreenshots/` are NOT hand-edited here — the `/play-store-shots` skill mirrors them from `../../../screenshots/published/` whenever the user drops new captures. Editing them directly will be overwritten on the next skill run.

## CI behaviour

The `play-store-listing.yml` workflow:

- Triggers on `workflow_dispatch` (manual) and on push to `master` touching `docs/play-store/metadata/**` or `docs/play-store/screenshots/published/**`.
- Reads the `PLAY_STORE_JSON_KEY` GitHub secret (Google Play Developer service-account JSON, base64-encoded).
- Defaults to the `internal` track. The manual dispatch exposes a `track` input so you can promote to `production` once the internal listing looks right.
- Uses `r0adkll/upload-google-play@v1` for the actual upload — no `fastlane` install needed in CI.

## Listing-refresh issue

Open work tracked in **#1473** — the gap between this metadata + the live listing.
