# App Store metadata (`fastlane deliver`)

This directory holds the **text** metadata for the Sparkilo iOS App Store
listing in the [`fastlane deliver`](https://docs.fastlane.tools/actions/deliver/)
standard layout. It contains **no binary and no screenshots** — see the note at
the bottom.

## Layout

```
ios/fastlane/metadata/
├── copyright.txt                 # global, shown on every listing
├── <locale>/
│   ├── name.txt                  # app name            (Apple limit: 30 chars)
│   ├── subtitle.txt              # tagline / ASO field (Apple limit: 30 chars)
│   ├── keywords.txt              # comma-separated, no spaces (limit: 100 chars)
│   ├── description.txt           # full description    (limit: 4000 chars)
│   ├── promotional_text.txt      # short hook, editable w/o review (limit: 170)
│   └── release_notes.txt         # "What's New" for the current version
```

Locales present: `en-US`, `de-DE`, `fr-FR`, `es-ES`, `it`, `pt-PT`.

> **Locale codes:** App Store Connect's code for Italian is `it`, **not**
> `it-IT` — `deliver` skips an unrecognised code, so the folder must be `it`
> (see `deliver/lib/deliver/languages.rb` and #2611). Portuguese (Portugal) is
> `pt-PT`.

There is also a global `primary_category.txt` at the root of this directory
(App Store Connect category enum, `NAVIGATION`) that `deliver` applies to the
listing.

### ASO notes

- `keywords.txt` is the primary App Store Optimisation lever. It is a single
  comma-separated line with **no spaces** (spaces count toward the 100-char
  limit) and intentionally does **not** repeat words already in `name.txt` or
  `subtitle.txt` (Apple indexes those too, so repeating is wasted budget).
- `subtitle.txt` carries the top search intent per language
  (e.g. EN "Cheapest fuel & EV charging", DE "Billig tanken & Preisvergleich").
- Files are stored without a trailing newline because a trailing newline would
  count against the tight character limits.

## How it ships

`fastlane deliver` (a.k.a. the `upload_metadata` lane in `ios/fastlane/Fastfile`)
uploads this text to App Store Connect. It is run **manually by the maintainer**
with App Store Connect API credentials — it is not part of any CI workflow.

The `ios/fastlane/Deliverfile` pins it to a safe mode: it can only ever **stage**
text metadata. It never submits for review, never auto-releases, and never
touches the binary or screenshots (`submit_for_review(false)`,
`automatic_release(false)`, `skip_binary_upload(true)`,
`skip_screenshots(true)`). A human still presses "Submit for Review" in the
App Store Connect console afterwards.

```sh
cd ios
bundle exec fastlane upload_metadata   # stages text metadata only
```

## Still needed: screenshots

This listing has **no screenshots yet**. The App Store requires screenshots at
Apple's exact device-pixel resolutions (e.g. 6.7"/6.9" and 6.5" iPhone, plus
iPad sizes); the existing 1080×2316 phone shots do not match any of them.
Device-framed screenshots at Apple's required resolutions must be produced
before the visual part of the listing is complete. They are intentionally out
of scope here.
