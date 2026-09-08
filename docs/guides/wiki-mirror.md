<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# The wiki lives in the repository

`docs/wiki/` is the **source of truth** for every user and developer
page. The GitHub wiki is a mirror of it.

## Why it moved

The wiki was written directly on GitHub, which meant three things it
should not have meant:

- **Nothing compared the seven languages.** A page added in English and
  forgotten in Danish looked exactly like a page that was never meant to
  exist in Danish. `test/lint/wiki_parity_test.dart` now says so.
- **A page could not change in the same pull request as the code it
  describes.** The screen shipped, the page followed a week later, or
  never.
- **A page could not be reviewed.** Wiki edits have no diff a reviewer
  reads and no CI that runs.

## The rule

Edit `docs/wiki/*.md` in the pull request that changes the behaviour the
page describes. The mirror is a consequence, never a place to type.

## Mirroring

```bash
git clone https://github.com/fdittgen-png/tankstellen.wiki.git /tmp/wiki
cp docs/wiki/*.md /tmp/wiki/
cd /tmp/wiki && git add -A && git commit -m "…" && git push
```

**Images stay in the wiki.** `guide/` (74 tutorial captures) and
`screenshots/` (23 store captures) are ~27 MB; putting them in the
repository would put them in its history for ever. The markdown is
1.4 MB and carries all the review value, so only the markdown moved.

If the images should move too, run them through the pipeline first
rather than copying them raw:

```bash
dart run tool/media.dart ingest ~/Desktop/shots      # originals → docs/media/source
dart run tool/media.dart index                       # rebuild the workbench index
```

`tool/media.dart` writes 720-pixel-wide JPEGs at quality 84, which is
what a wiki page needs; the 1080 × 2316 PNGs currently in
`screenshots/` are roughly ten times the bytes a reader downloads.

## What is not here yet

The **in-app help** — a symbol beside a field that opens the guide at
that exact field — is a separate piece of work. It needs an anchor
vocabulary shared by the app and the guide, a compiled help asset, and a
`/help` route. The method is written up in
[DesKilo's `docs/guides/help-framework.md`](https://github.com/fdittgen-png/deskilo/blob/master/docs/guides/help-framework.md),
which is deliberately project-agnostic.
