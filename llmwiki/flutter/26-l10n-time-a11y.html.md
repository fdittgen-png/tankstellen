**26 · Quality**

# Localisation, time & accessibility

> These three topics share a page because they share a failure mode: each works perfectly for the developer — who reads their own language, sits in one timezone, and does not use a screen reader — and breaks only for someone else. The countermeasure is the same for all three: turn the intention into a test, because nothing else survives.

**Chunk prefix** l10n **Updated** 2026-08-02 **Depends on** 01 Foundations, 03 TDD

#### On this page

1. [Every string externalised, ratchet-enforced](#externalise)
1. [The ARB fragment pipeline](#fragments)
1. [Two locale strategies, both valid](#strategies)
1. [Text-expansion survival](#expansion)
1. [ICU discipline and locale-aware formatting](#icu)
1. [The two-clock doctrine](#timezones)
1. [The injectable clock](#clockseam)
1. [Accessibility as tests](#a11y)
1. [The regulatory floor](#regulation)

<!-- chunk: l10n.externalise | tags: i18n,arb,lint,ratchet -->

## Every string externalised, ratchet-enforced

Both source projects carry the same hard rule: no hard-coded user-facing text, ever — every string goes through the generated localisations class with a defensive English fallback literal at the call site (`l10n?.key ?? 'English fallback'`), so a missing delegate degrades to English instead of crashing.

> **[RULE]**

> **The rule is a lint test, not a convention.** A repo-scanning test flags any `Text(` with a string literal that is not a `??` fallback, with a per-file baseline that may only shrink ([the ratchet pattern](03-tdd-and-testing.html#lint-tests)). Retrofitting externalisation onto a mature codebase is a months-long slog; the ratchet lets a legacy codebase adopt the rule today — existing violations are grandfathered at their current count, new ones fail CI — and the baseline reaching zero is a measurable finish line.

Two companion gates make the rule complete:

- **Key parity:** a test that every locale carries exactly the canonical locale's key set — missing keys *and* extra keys fail, because an extra key is usually a typo that silently never renders.
- **Pipeline cleanliness:** CI regenerates the localisation outputs and fails on any diff, the same [committed-codegen gate](18-github.html#codegen) as freezed/riverpod artifacts. Hand-edited generated ARB files are how two sources of truth are born.

<!-- chunk: l10n.fragments | tags: i18n,arb,fragments,pipeline -->

## The ARB fragment pipeline

A single `app_en.arb` with a thousand keys is a merge-conflict magnet and a review nightmare. Both projects instead keep **per-feature fragments** — `plan_en.arb`, `billing_fr.arb` — merged by a small tool into the aggregated per-locale files that `flutter gen-l10n` consumes.

| Pipeline property | Why it is load-bearing |
| --- | --- |
| Merge fails on duplicate keys across fragments of one locale | Two features can never silently shadow each other's strings — the collision is a build error at the merge, not a mystery at runtime |
| Fragments are the source of truth; aggregates are generated and committed | Conflicts in the aggregates are resolved by *regenerating*, never by hand-merging — the rule that saves every multi-branch ARB conflict ([page 28](28-ai-agents.html#generated)) |
| English is canonical: every key must exist in an `_en` fragment | One locale is the reference the parity gate compares against; "canonical" is a property the tool checks, not a convention |
| Fragment = feature module | A feature's strings live next to its code ownership; deleting a feature deletes its fragment, and the parity gate catches strays |

<!-- chunk: l10n.strategies | tags: i18n,locales,strategy,translation -->

## Two locale strategies, both valid

The source projects deliberately diverge here, and the comparison page's verdict stands: *either — both gate on parity, which is the part that matters*.

|   | Many locales, machine-filled | Few locales, hand-maintained |
| --- | --- | --- |
| Shape | 23 locales + a pseudo-locale; machine translation fills new keys, humans revise opportunistically | 5 locales; every new key lands in all five, human-quality, **in the same PR** |
| Cost per key | Near zero at write time; revision debt accumulates | Five translations per key, every time |
| Reads like | Fine to good; occasional machine artefacts | A native product |
| Pre-translation window | Exists — keys ship before human review, so the pseudo-locale earns its keep catching layout breaks early | Does not exist — full-length translations exist from day one, so a pseudo-locale adds little (see next section) |
| Fits when | Breadth is the product (a comparison app across 17 countries) | Depth is the product (a community app whose owner reads the locales) |

> **[WHY]**

> The strategy choice changes which *tests* pay off, which is why it belongs in an engineering wiki at all. Machine-fill needs the pseudo-locale and expansion tooling because untranslated-length text is a real production state; same-PR hand translation makes real-locale walks the honest test because the longest text a user will ever see already exists in the repo. Choosing tests without choosing the strategy first optimises the wrong risk.

<!-- chunk: l10n.expansion | tags: i18n,pseudo-locale,overflow,testing -->

## Text-expansion survival

German compounds and French phrases run 20–40% past the English a layout was eyeballed against, and an overflow in a language the developer does not read ships silently — every widget test runs in English. Two mechanisms catch it, matched to the locale strategy above.

- **A pseudo-locale** (machine-fill strategy): a generated locale that expands every string — prefix/suffix padding only, `[!! … !!]`, never touching the interior, so ICU placeholders and plural syntax survive the transformation intact. Registered under a reserved tag (Android's `en-XA` convention), it is reachable from a device's developer settings without polluting real users' locale resolution.
- **Real-locale narrow-width walks** (hand-translation strategy): a widget test pumps the app in each shipping locale at phone width (360 dp, portrait) and walks the main surfaces; any `RenderFlex` overflow fails with the locale and surface named. One source project ships exactly this, plus a growth guard asserting the navigation bar's destination count so a new surface cannot ship without joining the walk.

> **[TRAP]**

> **Symptom: the locale-walk test cannot navigate — taps miss, and `pageBack()` finds nothing.** Three mechanics, each earned: navigate **by icon, never by label** (the labels are the thing under test and change per locale); never `tester.pageBack()` (it matches the literal "Back" *tooltip*, which is localised — `find.byType(BackButton)` is not); and scope every tap to the bar it lives in, because icons repeat across surfaces and an unscoped `.first` taps the occluded copy — after which the missed-tap warning quietly hides that a surface was never visited.

Text *scaling* is the same bug class in another axis: a user's 1.3× font setting expands every string at once. The same walk run once at a raised `textScaleFactor` covers it; layouts that survive German usually survive large fonts, but "usually" is not a test.

<!-- chunk: l10n.icu | tags: i18n,icu,plurals,formatting,currency -->

## ICU discipline and locale-aware formatting

Grammar and formats are locale logic, not string logic, and the moment either is done with string concatenation the app is wrong in some language.

- **Plurals and selects live in ICU syntax inside the ARB**, never as `count == 1 ? 'item' : 'items'` in Dart — languages have plural rules English does not (one/few/many/other), and only the message format knows them.
- **Placeholders, never concatenation.** `'{name} joined {workspace}'` reorders freely per language; `name + ' joined ' + workspace` does not. A sentence assembled from two keys is a sentence some language cannot say.
- **Dates, numbers and currency render through `intl` formatters only** — both projects ban raw string formatting for these by convention and catch stragglers in review. Note the decimal-separator trap generalises beyond the app: a CI gate comparing `printf "%.1f"` output numerically silently broke under a comma-locale shell ([page 18](18-github.html)) — locale bugs are not confined to Dart.
- **Currency follows the domain, not the device.** One project renders money in the *workspace's* currency (derived from its country) regardless of the viewer's locale — the locale decides the separators, the domain decides the unit. Conflating the two shows a French viewer a German workspace's prices in the wrong currency.
- **User-generated content is not translated.** Workspace names, notes, statuses pass through verbatim; only the app's own strings localise.

One deliberate, documented exception both projects converged on: **data-interchange documents keep stable English identifiers**. An XML schema's element names and an Excel export's column headers get referenced by importers, formulas and pivots — a header that renames itself when the owner's phone changes language breaks every consumer. The surrounding UI (tiles, snackbars, the bill PDF a member receives) localises like everything else; the file format does not. Write the decision at the top of the builder, because it looks like a rule violation to anyone who has not read the why.

<!-- chunk: l10n.timezones | tags: time,timezones,utc,dst -->

## The two-clock doctrine

An app whose domain has a *place* — a coworking space, a fuel station — has two clocks: the device's and the place's. Every time bug in one source project came from conflating them, and the doctrine that ended the class is short:

| Rule | Consequence |
| --- | --- |
| **Store UTC, always** | Timestamps in the database are `timestamptz`/ISO-UTC; conversion is a render-time concern |
| **Recur in domain-local time** | A weekly 09:00 booking series stays 09:00 across DST because the recurrence is expanded in the workspace's IANA zone, not in UTC arithmetic |
| **Day-based logic runs on the domain's calendar** | "Open days", closure dates, half-day windows anchor to the workspace zone — a developer's laptop in a different zone must not shift them |
| **Windows straddle device days** | A domain-local full day (00:00–24:00 Paris) spans *two* device-local dates west of it; any cache or query keyed by device-local day must fetch both keys a half-open window touches |

> **[TRAP]**

> **Symptom: a reservation made from the plan shows on one screen and not another, or lands at 01:15 local.** Both happened, months apart, and both were the straddle rule: one surface fetched a single device-day cache key while a workspace-day window bucketed under the neighbouring key; earlier, month keys computed via UTC conversion queried June for a July calendar east of Greenwich. The fix each time was the same helper — derive the one-or-two day keys a half-open window touches, in the correct zone, in exactly one place — and a test pinned to a timezone far from the workspace's, because a test that runs in the workspace's own zone cannot see this bug class at all.

<!-- chunk: l10n.clockseam | tags: time,clock,testing,seams -->

## The injectable clock

`DateTime.now()` in widget code is untestable in the only way that matters: it agrees with the calendar of the machine that runs it. One source project had CI green on the 28th and red on the 1st with no commits between — a test asserting the literal current month name, and a fake whose seeded period matched the month the test was written in. Time bombs, not regressions; bumping the strings only resets the fuse.

> **[RULE]**

> **One clock seam, pinned in every test, guarded by a lint.** A `Clock` interface behind a provider (`SystemClock` in the app, a fixed instant in the shared test overrides — a mid-month Wednesday, so nothing lands on a weekend, month boundary or DST change by accident). The lint forbids `DateTime.now()` in *both* `lib/` and `test/` outside a shrink-only exempt list, because either half alone re-arms the bomb: a widget on the wall clock ignores the pin, a test seeding from the wall clock disagrees with it. Legitimate exemptions exist — cache-expiry measured against real time, log timestamps, OS scheduling — and each carries its reason in the list.

Two sharp edges from the migration, worth more than the happy path: a *nullable* `now` parameter with a `DateTime.now()` default is a wall-clock read wearing a parameter's clothes — making the parameter *required* found three real bugs where presence indicators used the wall clock while the surrounding screen browsed a different day. And on a cold Riverpod `AsyncNotifier`, a synchronous `.value` read is still loading and silently answers its default — `await` the `.future` when the answer gates behaviour.

<!-- chunk: l10n.a11y | tags: accessibility,semantics,tap-targets,contrast,testing -->

## Accessibility as tests

Flutter maintains a semantics tree alongside the widget tree for TalkBack and VoiceOver, and standard widgets populate it well — the gaps appear exactly where an app is most custom, which for both source projects means canvas surfaces. The discipline, again, is tests over intentions:

- **Tap targets, asserted:** every interactive screen's test suite runs `meetsGuideline(androidTapTargetGuideline)` (48×48 dp) — plus the iOS and labeled-target guidelines where adopted — and every new tappable affordance needs a big-enough target *and its own test that taps it*. The guard has real teeth: it caught a `FittedBox` silently shrinking a toolbar to 27.8 dp, and it forbids the tempting `visualDensity.compact`-plus-padding combination that caps padded hit areas at 40 dp.
- **State never by colour alone:** a seat that is free/reserved/occupied pairs every colour with an icon or pattern — the rule exists in the design system and a reviewer can check it, but the colour side is machine-checked too: a runtime contrast-guard test walks the palette against the WCAG thresholds (4.5:1 normal text, 3:1 large) in both light and dark themes.
- **Custom paint gets explicit semantics:** a floor-plan canvas is one big picture to a screen reader unless each seat contributes a labelled semantics node with its name and state. Budget for this when choosing a canvas over widgets — it is the hidden cost of custom painting.
- **Motion respects the platform setting:** centralised animation durations (one motion-tokens class, not scattered `Duration`s) make honouring reduce-motion a one-place change instead of a hunt.

> **[CHECK]**

> The five-minute audit no test replaces: turn on TalkBack or VoiceOver and complete the app's single most important flow — book the seat, record the payment — eyes closed. Every unlabelled button reads as "button", every unreachable control is simply absent, and both are findings no amount of green CI contradicts.

<!-- chunk: l10n.regulation | tags: accessibility,regulation,eaa,wcag -->

## The regulatory floor

Accessibility stopped being purely voluntary for many apps in June 2025, when the European Accessibility Act's obligations took effect for consumer-facing digital services in the EU — with member-state enforcement and fines that scale with revenue. The harmonised technical standard is EN 301 549, which for app content largely incorporates WCAG 2.1/2.2 level AA — the same contrast ratios, target sizes and semantics this page's tests already encode.

| Instrument | What it means for an app team |
| --- | --- |
| European Accessibility Act (in force for services since 2025-06) | E-commerce, banking, transport and similar consumer services in the EU must be accessible; microenterprises have carve-outs — check whether yours applies rather than assuming |
| EN 301 549 | The testable requirements — practically, WCAG AA plus platform-specific criteria; the tap-target, contrast and semantics tests above are its unit tests |
| Store review | Not currently a hard accessibility gate on either store, so *your CI is the only enforcement you have* — which is the theme of this page |

This section is regulatory context, not legal advice: scope questions (which services, which carve-outs, which member state's enforcement) belong to a lawyer. The engineering takeaway is narrower and safe: the practices above are no longer just craft — for many products they are the compliance work, already done.

#### Sources for this page

- Both projects' externalisation hard rule, ratcheting string lint, key-parity gates and ARB fragment pipelines (duplicate-key-failing merge, canonical English, committed aggregates).
- One project's 23-locale machine-fill strategy and pseudo-locale; the other's five-locale same-PR strategy and its real-locale narrow-width expansion walk with the icon-navigation, localized-tooltip and scoped-tap mechanics.
- The workspace-time doctrine and both recorded straddle incidents; the clock-seam migration including the required-parameter bug catch and the cold-provider read; the wall-clock lint with its exempt list.
- Tap-target guideline enforcement (including the FittedBox and visualDensity incidents), the runtime contrast-guard test, and the state-never-by-colour design rule.
- WCAG 2.2 thresholds, EN 301 549 and European Accessibility Act status from official Flutter accessibility documentation and current public summaries, 2026-08. The regulation section is context, explicitly not legal advice; the RTL and reduce-motion notes are recommendations, not observed practice.
