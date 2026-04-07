# ADR 0006: 23-language i18n strategy

**Status:** Accepted
**Date:** 2024-10-01

## Context

The app serves users across 7+ European countries. While German is the
primary language (largest fuel price API coverage), users in France, Italy,
Spain, Belgium, Luxembourg, and Austria speak diverse languages. A
credible pan-European app must support the major languages of its target
markets.

Flutter's built-in `intl` / ARB localization system provides a structured
approach, but scaling to many languages requires discipline: every
user-facing string must go through the localization layer, and no hardcoded
strings should appear in widget code.

## Decision

Support **23 languages** using Flutter's ARB-based localization:

- All user-facing strings are defined in ARB files under `lib/l10n/`.
- German (`de`) is the primary development language; English (`en`) is the
  secondary fallback.
- Widget code accesses strings via
  `AppLocalizations.of(context)?.key ?? 'English fallback'`.
- No hardcoded German or English strings in Dart source files.
- New strings are added to all ARB files simultaneously (even if initially
  only translated into DE/EN, with other languages following).

## Consequences

- **Broad accessibility**: Users in all target countries see the app in
  their native language.
- **Maintenance overhead**: Every new feature requires updating 23 ARB
  files. Mitigated by tooling that flags missing keys.
- **Translation quality**: Community/AI translations may be imperfect;
  accepted as better than no translation.
- **Bundle size**: Minimal impact; ARB strings compile to efficient Dart
  code with tree-shaking.

## Alternatives Considered

- **DE + EN only**: Simpler but alienates non-German-speaking European
  users, undermining the pan-European value proposition.
- **Server-side translations (e.g., Crowdin)**: Better for community
  contributions but adds a runtime dependency; ARB keeps everything local.
- **gettext / .po files**: More familiar to web developers but not the
  Flutter convention; ARB integrates natively with `gen-l10n`.
