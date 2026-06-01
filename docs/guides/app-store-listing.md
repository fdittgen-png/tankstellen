<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# App Store listing publish (#2593)

The iOS App Store text metadata lives in the repo under
`ios/fastlane/metadata/<locale>/` (added in #2560). The
`.github/workflows/app-store-listing.yml` workflow pushes it to App Store
Connect via `fastlane deliver` — without rebuilding or uploading a binary.
This is the Apple mirror of `play-store-listing.yml`; before it existed the
copy lived in the repo but was never published, exactly like Play was.

## Metadata layout

```
ios/fastlane/metadata/
├── copyright.txt
├── en-US/
│   ├── name.txt              # App name (max 30 chars)
│   ├── subtitle.txt          # Subtitle (max 30 chars)
│   ├── keywords.txt          # ASO keywords, comma-separated (max 100 chars total)
│   ├── description.txt        # Full description (max 4000 chars)
│   ├── promotional_text.txt   # Promo text, editable without review (max 170 chars)
│   └── release_notes.txt      # "What's New" for the next version (max 4000 chars)
├── de-DE/ …
├── fr-FR/ …
├── es-ES/ …
└── it-IT/ …
```

`deliver` discovers these automatically relative to `ios/fastlane/Deliverfile`.
The five locales (en-US, de-DE, fr-FR, es-ES, it-IT) are the launch markets;
App Store Connect auto-falls-back to en-US for any locale not present.

### ASO / keywords fields

- **`keywords.txt`** is the App Store search-ranking field — comma-separated,
  100 chars total, no spaces after commas (each space costs a character).
  Don't repeat words already in `name`/`subtitle`; Apple indexes those too.
- **`subtitle.txt`** (30 chars) appears under the app name on the product page
  and is also indexed for search — use it for a high-value keyword phrase.
- **`promotional_text.txt`** (170 chars) sits above the description and can be
  changed **any time without a new app version or review** — useful for
  time-bound messaging.
- **`description.txt`** is the long-form copy. Not indexed for search ranking;
  it's for conversion once the user is on the page.

## Secrets

The workflow authenticates with the same App Store Connect API key as
`ios-testflight.yml`. These already exist in repo Actions secrets — verify
with `gh secret list`:

| Secret | Purpose |
|---|---|
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 of the `.p8` key file |
| `APP_STORE_CONNECT_API_KEY_ID`     | the key's Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID`  | the issuer ID |

`deliver --api_key_path` does **not** take a raw `.p8` plus separate
key-id/issuer-id flags (those are not deliver parameters). It expects
fastlane's *App Store Connect API key JSON* wrapper, whose `key` field holds
the full PEM contents of the `.p8`. The workflow therefore decodes the
base64 secret to a temp `.p8`, then `jq`-assembles
`{key_id, issuer_id, key, in_house:false}` into a temp JSON file and passes
that. Both temp files live in `$RUNNER_TEMP` and are removed in an `always()`
cleanup step.

## Safety

`ios/fastlane/Deliverfile` is configured so `deliver` can only ever stage
**text** metadata — it can never submit the app, release a build, or touch the
binary or screenshots:

- `submit_for_review(false)`, `automatic_release(false)`
- `force(false)`, `skip_binary_upload(true)`, `skip_screenshots(true)`

The workflow passes the same flags explicitly (`--skip_binary_upload true
--skip_screenshots true`, plus `--force true` so CI never hangs on the
interactive HTML-preview confirmation). `--submit_for_review true` is sent
**only** when the maintainer explicitly sets the `submit` input; the default
keeps it `false`, so a human still presses "Submit for Review" in the console.

## How to run

The workflow is **`workflow_dispatch` only** — it never auto-fires on push.
Apple listing changes are tied to a specific app version + the review process,
so an auto-publish on every metadata commit (the way Play does) is too risky.

1. **Validate first (dry run).** Dispatch with `dry_run` = **true** (the
   default). This runs `deliver --verify_only`, which validates the metadata
   against App Store Connect — checks lengths, locale coverage, forbidden
   content — **without uploading anything**.
2. **Real run.** Dispatch with `dry_run` = **false** to upload the text
   metadata. Leave `submit` = false (the default) so the copy is *staged*
   for the editable version and a human reviews + submits in the console.
3. **Submit (optional, rare).** Only set `submit` = true if you intend the
   run itself to submit the app for review. On a dry run this input is ignored.

```
gh workflow run app-store-listing.yml -f dry_run=true            # validate
gh workflow run app-store-listing.yml -f dry_run=false           # stage metadata
gh workflow run app-store-listing.yml -f dry_run=false -f submit=true   # stage + submit
```

## Prerequisite — a version in "Prepare for Submission"

`deliver` can only update localized metadata when the app has a version in the
**"Prepare for Submission"** state in App Store Connect (an *editable* version).
If no editable version exists, the run fails with a clear error such as
`Could not find an editable version` / `app version ... not found`.

To create one: App Store Connect → your app → **+ Version** (or open the
in-flight version), so a version sits in "Prepare for Submission". Then dispatch
the workflow. The metadata you stage attaches to that version; `release_notes`
becomes its "What's New".

## Screenshots are NOT included

The workflow passes `--skip_screenshots true` and ships no images. Apple
requires screenshots at **exact device-pixel sizes** per device class (e.g.
6.7" iPhone 1290×2796, 6.5" 1242×2688, 12.9" iPad 2048×2732), unlike Play's
auto-scaling. Producing those is a separate task; until then the listing's
existing screenshots are left untouched and only text metadata is updated.

## Companion

- `play-store-listing.yml` + `docs/guides/PLAY-STORE-LISTING-REFRESH.md` —
  the Android equivalent this workflow mirrors.
- `ios-testflight.yml` — the binary-upload pipeline; the API-key auth pattern
  here is copied from it.
