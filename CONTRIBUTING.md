<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Contributing to Sparkilo

Thank you — issues, reproductions and patches are all welcome.

## The licence, and why it matters to you

Sparkilo is **AGPL-3.0-or-later** ([`LICENSE`](LICENSE)). Every source
file says so in an SPDX header, and
`test/lint/spdx_headers_test.dart` fails if a file is missing one or
declares anything else. A new file needs:

```dart
// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
```

(`#` for YAML, shell and Python; `--` for SQL.)

**By opening a pull request you agree that your contribution is licensed
under AGPL-3.0-or-later.**

This is not boilerplate. A commercial exception to the licence is
offered ([`COMMERCIAL-LICENCE.md`](COMMERCIAL-LICENCE.md)), and a
maintainer cannot sell an exception to *your* copyright. If a
contribution arrives under any other terms, the dual licence stops being
offerable and the patch cannot be merged — so please do not send code
you are not free to license this way.

Sign off each commit to record it:

```bash
git commit -s -m "feat(fleet): ..."
```

`-s` appends a `Signed-off-by:` line, which is a statement that you
wrote the patch or otherwise have the right to submit it under those
terms — the [Developer Certificate of Origin](https://developercertificate.org/).

## Before you write code

**Every change traces to a GitHub issue.** Large, multi-PR or
multi-subsystem work is an Epic: file the Epic parent first and get the
breakdown validated before filing children. This is not ceremony — it is
how the project keeps a reviewable history of *why*, not just *what*.

## The rules that will fail your build

These are enforced, in CI and by a local pre-push hook. The full text is
in [`docs/AGENT_RULES.md`](docs/AGENT_RULES.md).

1. **No hard-coded user-facing text.** Every visible string comes from
   ARB. Add keys to `lib/l10n/_fragments/<feature>_{en,de}.arb` (and
   `_fr.arb` if you can write the French), then run the pipeline below.
   Brand names, URLs and format masks are the only exemptions, each with
   an inline `// i18n-ignore: <reason>`.
2. **Regenerate from clean before you push.**
   ```bash
   dart run build_runner clean
   dart run build_runner build --delete-conflicting-outputs
   ```
   Commit every `*.g.dart` / `*.freezed.dart` the run produces. Stale
   generated code is a defect, not a follow-up.
3. **Fan the ARB out to all 23 locales.**
   ```bash
   dart run tool/build_arb.dart
   dart tool/gen_pseudo_arb.dart
   flutter gen-l10n
   ```
   Never edit `lib/l10n/app_*.arb` by hand — they are generated.
4. **A local synced-schema change must reach the Supabase schema too.**
   A new synced table or explicit column means updating
   `lib/core/sync/schema_verifier.dart`, the wizard SQL and
   `kSupabaseSchemaVersion`, or self-hosters get silent per-table sync
   failures.

Install the hook once per clone:

```bash
bash scripts/install_hooks.sh
```

## Getting set up

Flutter is pinned — check `.github/workflows/ci.yml` for the exact
version rather than assuming your local SDK matches.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

## Pull requests

- Short-lived branch, conventional-commit title, squash merge.
- **One commit per closed issue**, even inside a bundled PR: the title
  summarises, the commit log preserves the per-issue reasoning.
- Run `flutter analyze` (the whole repo, including `test/`) and the
  relevant `flutter test` before every commit.
- Structural widget tests, never locally-generated golden PNGs — goldens
  are Linux-baselined and a macOS-generated one fails CI.
- Say what you verified and what you did not. A PR that reports a
  skipped step honestly is worth more than one that implies coverage it
  does not have.
