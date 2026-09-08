# Contributing

Tankstellen is MIT-licensed open source. Contributions of every size are welcome — translations, bug fixes, country APIs, whole features, docs, test coverage.

## Ways to contribute (ranked by easiness)

1. **Use the app and report issues** — an honest bug report with repro steps is worth gold.
2. **Translate** — we support 23 languages. ARB files live in `lib/l10n/`. See [Localization](Dev-Localization-ARB).
3. **Fix a typo / small bug** — great first PRs.
4. **Add a new country API** — see [Adding a Country](Dev-Adding-A-Country).
5. **Build a feature** — open an issue first to align, then go.
6. **Self-host TankSync** — deploy the Supabase schema and share your instance with the community.

## Setup

### Prerequisites

- **Flutter 3.41.5** (pinned — use [FVM](https://fvm.app/) if you juggle versions)
- **Dart 3.11.3** (comes with Flutter)
- **Android SDK + JDK 17** — for Android builds
- **Git** — obviously

On Windows:

```bash
export PATH="/c/dev/flutter/bin:$PATH"
export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-17.0.18.8-hotspot"
export ANDROID_HOME="$LOCALAPPDATA/Android/Sdk"
```

### Clone & bootstrap

```bash
git clone https://github.com/fdittgen-png/tankstellen.git
cd tankstellen
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
flutter run -d emulator-5554   # Android emulator
```

### Test

```bash
flutter test                   # whole suite (~40 s)
flutter test --coverage        # with coverage
flutter analyze                # must return zero warnings before commit
```

### Optional: Supabase (for TankSync development)

```bash
supabase start                 # local Supabase stack (Docker required)
supabase db push               # apply migrations to local DB
supabase functions deploy      # deploy Edge Functions
```

## Rules of thumb

- **Never commit to `master`.** Always branch off.
- **Every code change includes tests.** No exceptions — the suite is the regression net.
- **Every PR is under 400 lines changed** (excluding generated files). Split if larger.
- **Zero `flutter analyze` warnings** before commit.
- **Conventional commits** — `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:`, `ci:`.
- **One concern per PR.** Don't bundle a fix and a refactor.
- **Link an issue** via `Closes #NN` in the PR body.

## Your first PR

1. **Pick an issue** labelled `good first issue` if you want a gentle start.
2. **Comment on the issue** saying you're taking it (avoids double work).
3. **Fork + branch**: `feat/YY-short-description` where `YY` is the issue number.
4. **Make the change.** Write the test first (TDD), then the fix.
5. **Run**: `flutter analyze && flutter test`.
6. **Push + PR** with the template filled out.
7. **Respond to review** — usually quick, we're friendly.

## What gets accepted

Contributions that **serve the leitmotiv**: *pay less at the pump* or *burn less behind the wheel*.

Convenience features (UI polish, accessibility, deep links, payment shortcuts) are fine, but we won't accept:

- Anything that requires Google Play Services or Firebase
- Anything that introduces third-party tracking
- Features that transmit user data without an explicit opt-in
- GPL dependencies
- Breaking changes to the public data model without a migration
- "Gamification" that doesn't help the user save money or fuel

When in doubt, open a Feature Request issue first.

## What if I want to fork for personal use?

MIT means you can. Typical personal customizations:

- Add your own brand logos to the Android launcher
- Pre-configure your TankSync anon key so family members don't need to paste it
- Pin your preferred profile as default
- Bundle an extra country API specific to where you live
- Swap in a paid routing service you prefer

See [Adding a Country](Dev-Adding-A-Country) for the pattern; it's the same mechanic for any private extension.

If you think your customization would benefit the public, consider PR'ing it upstream.

## Community

- **Discussions**: [GitHub Discussions](https://github.com/fdittgen-png/tankstellen/discussions)
- **Bugs**: [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues)
- **Privacy questions**: see [PRIVACY.md](https://github.com/fdittgen-png/tankstellen/blob/master/PRIVACY.md)
- **Security reports**: see [SECURITY.md](https://github.com/fdittgen-png/tankstellen/blob/master/SECURITY.md) for private disclosure

## Code of Conduct

Be kind. Assume good faith. Disagree about code, not people. Full text in [CODE_OF_CONDUCT.md](https://github.com/fdittgen-png/tankstellen/blob/master/CODE_OF_CONDUCT.md).

## Related

- [GitHub Workflow](Dev-GitHub-Workflow) — Git flow specifics
- [Creating Issues](Dev-Creating-Issues) — templates + triage
- [Testing & TDD](Dev-Testing-TDD-Pyramid) — the TDD protocol
- [Adding a Country](Dev-Adding-A-Country) — the most common first-feature PR
