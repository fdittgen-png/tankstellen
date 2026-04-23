# ARB-Fragment Build Pattern

## One-line summary

New localization keys go into **per-feature fragment files** under
`lib/l10n/_fragments/`, not directly into `lib/l10n/app_en.arb` /
`lib/l10n/app_de.arb`. A tiny build script merges the fragments back
into the canonical ARB files that Flutter's `gen-l10n` consumes.

## Why

Every parallel-worker session ends in ARB merge conflicts: two workers
each append five keys at the end of `app_en.arb`, and the rebase is
unavoidable. In the 2026-04-22 `/tankstellenfix` run this cost about
six rebase cycles (roughly an hour of wall-clock).

Fragment files are per-feature — two workers touching different features
cannot collide. The merged `app_en.arb` / `app_de.arb` are regenerated
mechanically, so the "conflict" is shifted to a deterministic script
that never produces an ambiguous diff.

## Files

Under `lib/l10n/_fragments/`:

- `_base_en.arb` / `_base_de.arb` — the ARB header (`@@locale`, etc.)
  plus every key that has not yet been extracted into a feature fragment.
  All existing keys start their life here and migrate out opportunistically.
- `<feature>_en.arb` / `<feature>_de.arb` — one pair per feature
  (e.g. `vehicle_en.arb`, `vehicle_de.arb`). Each fragment contains only
  that feature's keys.

Under `lib/l10n/`:

- `app_en.arb` / `app_de.arb` — **GENERATED**. The merged output of the
  fragments. Flutter's `gen-l10n` reads these. **Humans must not edit
  them directly** — edit the fragments.

## How to add a new localization key (as a worker)

1. Pick (or create) a fragment for the feature you're working on.

   - Existing fragment: `lib/l10n/_fragments/vehicle_en.arb` +
     `lib/l10n/_fragments/vehicle_de.arb`.
   - New feature: create both files at once. Start with a minimal
     two-line JSON object:

     ```json
     {
       "myNewKey": "English value"
     }
     ```

     Both the `_en` and the `_de` file MUST define the same set of keys.
     The consistency test fails if one locale is missing a key that
     exists in the other.

2. Add your key + German translation to both fragments.

3. Regenerate the merged ARBs:

   ```bash
   dart run tool/build_arb.dart
   flutter gen-l10n
   ```

4. Use the new key in code via `AppLocalizations.of(context)!.myNewKey`,
   exactly as before.

5. Commit the two fragment files **and** the regenerated `app_en.arb` /
   `app_de.arb` (they must stay in sync with the fragments — the test
   in `test/lint/arb_fragments_consistency_test.dart` enforces this).

## The duplicate-key error

If the same key appears in two fragments, the build script aborts:

```
ERROR: duplicate ARB key `priceWin` in both `achievements_en.arb`
and `alerts_en.arb` — rename one.
```

Rename the newer key (e.g. `alertsPriceWin`) to disambiguate. Features
that genuinely share a string should move the key into `_base_<locale>.arb`.

## Migrating existing keys to a fragment

The big bang migration (moving all ~1000 keys out of `_base_*.arb` into
per-feature fragments) is deliberately NOT part of the initial rollout —
too large to review, too disruptive. Existing keys migrate opportunistically:

- When a PR already touches a key, move it (and its `@<key>` metadata
  block if any) from `_base_<locale>.arb` to `<feature>_<locale>.arb`.
- Do this for BOTH `en` and `de` in the same PR.
- Re-run `dart run tool/build_arb.dart` — the regenerated `app_en.arb` /
  `app_de.arb` should change only in the relative position of the moved
  keys (the JSON ordering follows fragment merge order).

## Validation

`test/lint/arb_fragments_consistency_test.dart` enforces three rules:

1. Every `<feature>_en.arb` has a matching `<feature>_de.arb` with the
   same key set.
2. Running `build_arb.dart` produces output byte-identical to the
   committed `app_en.arb` / `app_de.arb` (catches hand-edits to the
   generated files).
3. No two fragments share a key name (redundant with the build-script
   check, but catches fragments that were added without the script
   being rerun).

CI runs this test like any other unit test.
