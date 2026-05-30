<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Agent HARD RULES

These are the non-negotiable rules for any contributor — human or AI — working
in this repository. They must **never** be violated under any circumstances.

> **Why this file exists.** `CLAUDE.md` (which a Claude Code session auto-loads)
> is deliberately gitignored (`.gitignore`, decision #296), so the HARD RULES
> living there are local-only and do **not** propagate to a fresh clone or
> another machine. This file is the version-controlled mirror: it travels with
> the repo so the rules survive fresh checkouts everywhere (#2355). `CLAUDE.md`
> stays gitignored and references this file — #296 is not reversed.

## 1. No hard-coded user-facing text

Every string a user can see — `Text`, `Tooltip`, `SnackBar`, `hintText`,
`labelText`, `helperText`, `semanticLabel`, button labels, dialog text, AppBar
titles, user-facing error/exception messages — **must** come from
`AppLocalizations` (ARB). Never inline a translatable literal, not even "just
for now".

- Add new strings to the matching `lib/l10n/_fragments/` fragment (en + de),
  then run `dart tool/build_arb.dart`, `dart tool/gen_pseudo_arb.dart`
  (regenerates the `en_XA` text-expansion pseudo-locale, #1699) and
  `flutter gen-l10n`.
- The only exemptions are brand names / proper nouns (e.g. `GitHub`, `PayPal`,
  `TankSync`), URLs, and language-neutral format masks. Each exemption must
  carry an inline `// i18n-ignore: <reason>` comment.
- Enforcement: `test/lint/no_hardcoded_ui_strings_test.dart`. Its baseline may
  only ever **decrease**; the target is **0**. Never raise it.
- Legacy cleanup is tracked by epic #1657.

## 2. Never develop without an issue

Every change traces to a GitHub issue. Large / multi-PR / multi-subsystem work
is an Epic — file the Epic parent, get the breakdown validated by the
maintainer, and only then file child issues.

## 3. Clean-codegen-before-push (never ship stale generated code)

Before every push, regenerate **from clean** — never incrementally — and commit
**all** resulting drift. An incremental `build_runner build` keeps stale hashes
that CI's clean run flags; the only safe sequence is:

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
git add -- '*.g.dart' '*.freezed.dart'   # commit every change it produced
```

- A push that leaves any `*.g.dart` / `*.freezed.dart` diff uncommitted is a
  **defect**, full stop — codegen drift has reached CI 4+ times in one session
  (plus #2245), each costing a ~13-min round-trip. Never "fix it in the next
  push".
- Don't `dart format` whole generated files; commit only the codegen diff.

## 4. Every new en ARB key must reach all 23 locales before push

Adding a key to `app_en.arb` (or any `_fragments/` en fragment) and **not**
fanning it out to every other locale is a **defect** — en+de-only additions
trip the #1699 coverage gate in CI. The full pipeline must run and its output be
committed before push:

```bash
dart run tool/build_arb.dart       # merge fragments -> canonical app_<locale>.arb
dart tool/gen_pseudo_arb.dart      # regenerate the en_XA expansion pseudo-locale
flutter gen-l10n                   # regenerate Dart bindings
git add -- lib/l10n/               # commit the full fan-out
```

- Every locale ARB must contain every `app_en.arb` key. The autofill pipeline
  (`tool/autofill_locales.dart`, run by `build_arb.dart`, #2335) carries new
  keys to all 23 shipped locales (plus the `en_XA` pseudo-locale), machine-
  filling any locale that lacks a key so the #1699 gate cannot be tripped.
- A push that leaves an `lib/l10n/` diff uncommitted, or any locale below 100%
  coverage, is a defect — never raise the baseline to "make it pass".
- Enforcement: `test/l10n/localization_completeness_test.dart` makes it
  CI-fatal. The handful of core French-reachable surfaces that must carry real
  (not machine-filled) French translations are declared in
  `test/l10n/french_required_prefixes.dart`.

## Install the local pre-push gate

HARD RULES #3 and #4 are enforced **locally**, before the ~13-minute CI
round-trip, by an installable pre-push hook. Run this once after cloning (and
again whenever the installer changes):

```bash
bash scripts/install_hooks.sh
```

The hook regenerates codegen + l10n from clean and **rejects the push** on any
`*.g.dart` / `*.freezed.dart` / `lib/l10n/` drift. Emergency bypass — you then
own the resulting CI red — is `SKIP_PREPUSH=1 git push`.

---

For everything beyond these four rules — architecture, the service-chain
pattern, the TDD pyramid, GitHub flow, the feature-enum cascade and the
autonomous-agent batching doctrine — see the `tankstellen-conventions` skill.
