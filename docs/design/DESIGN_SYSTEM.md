<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Tankstellen — Design System

**Status:** living contract (#923 phase 1). Coordinator-written
reference for every page, section, card, title, and tab in the app.
Phase 2 ships the canonical widgets described below. Phase 3+ migrates
every screen. Phase N lands the static scans that guard this document.

**Audience:** contributors writing new screens, reviewers auditing
PRs, and future coordinator agents scoping UI epics. If a screen
cannot be expressed with the tokens and widgets below, the doc is
missing something — raise an issue, don't invent a new pattern.

---

## Purpose

The app reached its current scope by letting each feature invent its
own version of "page title", "section header", "card", and "tabs". The
result works but drifts visually between screens — the app feels like
multiple apps stitched together. This document fixes the vocabulary:
what tokens exist, what canonical widgets cover which role, and what
is out of scope. It guarantees that any new screen can be assembled
from the primitives here without reaching into `Theme.of(context)` to
pick a title size or a card elevation by hand.

---

## Brand palette

The app ships a **calm forest-green** identity (#1757), not the old
`bahamaBlue`. The seed scheme is `_forestGreen` in `lib/app/theme.dart`
— a hand-tuned `FlexSchemeColor` whose `primary` is the literal
`#2E7D32` green pulled from the app icon. Three `FlexColorScheme`
builders share that one seed: `AppTheme.light()`, `AppTheme.dark()`
and `AppTheme.eco()` (see "Per-theme surface ramp" below). The
muted, semi-desaturated green sits calmly next to content; the surface
*tints* are derived per-theme by `FlexColorScheme` from a `blendLevel`,
so the exact `surface*` hexes are computed, not literals.

The seed inputs (`_forestGreen`, identical across all three themes):

| Slot | Hex | Where it shows up |
| --- | --- | --- |
| `primary` | `#2E7D32` | App-bar tint (light), primary buttons, brand fill, selected-pill outline, station accent stripe (fuel) |
| `primaryContainer` | `#B4D6B6` | Selected-pill fill, eco app-bar (tonal), `PageScaffold` banner |
| `secondary` | `#4E6B52` | Secondary accents |
| `secondaryContainer` | `#D6E4D7` | Light/dark app-bar tint (`appBarColor`), storage "price-history" segment |
| `tertiary` | `#3C6E63` | Correction accents (neutral, see semantic table), storage segment |
| `tertiaryContainer` | `#CFE3DC` | Storage "alerts" segment |
| `error` | `#B3261E` | `ColorScheme.error` — destructive chrome, validation |

The brightness-adapting `surface*` / `onSurface*` / `outline` slots are
**not** literals — `FlexColorScheme` derives them per-theme from
`blendLevel`. Read them at runtime via `Theme.of(context).colorScheme`;
never hardcode a surface hex. Roles to know:

| `ColorScheme` slot | Role in the app |
| --- | --- |
| `surface` | Scaffold background — the **lightest** base surface in all three themes (see ramp invariant) |
| `surfaceContainerLow` | `SectionCard` background — one tonal step up from the scaffold |
| `surfaceContainerHighest` | `SectionCard` hairline outline, `AppPill` default fill |
| `onSurface` | Body text |
| `onSurfaceVariant` | Muted / secondary text, unselected-pill foreground, neutral correction text |
| `outline` | Hairlines, disabled-text hint |

Success / warning / error **semantic** colours are not raw
`ColorScheme` slots — they live in `lib/core/theme/dark_mode_colors.dart`,
keyed to brightness and **widened for colourblind safety (#2492)**:

| Role | Light | Dark | Source |
| --- | --- | --- | --- |
| Success | `#388E3C` | `#66BB6A` | `DarkModeColors.success(context)` |
| Warning | `#C77800` (dark gold) | `#F9A825` (amber) | `DarkModeColors.warning(context)` |
| Error (semantic) | `#C62828` | `#EF5350` | `DarkModeColors.error(context)` |

The warning hue moved off the old deep-orange `#E65100` into the
amber/gold family so it no longer sits next to the error red; the error
red deepened to `#C62828` on light for the same separation. Both target
≥ 4.5:1 (or ≥ 3:1 large) against their surface. Do not hardcode
`Colors.green` / `Colors.red` / `Colors.grey` — always call the helper.

---

## Per-theme surface ramp

All three themes are built from the **same** `_forestGreen` seed; what
differs is the surface *ramp* — how green and how light each tonal step
is. The hard invariant, restored in **#2488**:

> **The scaffold must always be a LOWER (lighter) surface than
> `SectionCard`.** The scaffold is the lightest base surface; the green
> tint and any elevation live in the cards *on* it — the canonical
> Material direction. A card must never sit on a surface darker/greener
> than itself.

| Theme | `surfaceMode` | `blendLevel` | `cardElevation` | AppBar | Ramp reads |
| --- | --- | --- | --- | --- | --- |
| `light()` | `levelSurfacesLowScaffold` | `8` | `0` (tint-only) | surface-tinted (`secondaryContainer`) | Near-white scaffold, faint-green cards; separation is the tonal step + `SectionCard` hairline outline |
| `dark()` | `levelSurfacesLowScaffold` | `22` | `1` dp | surface-tinted | Charcoal-green scaffold, lifted cards; a 1 dp shadow is faint on dark, so the `surfaceContainerHighest` hairline outline carries the delta |
| `eco()` | `levelSurfacesLowScaffold` | `20` | `1` dp | **tonal** (`primaryContainer`) | Clearly greener than `light` (per the #2244 "recognisably green" mandate) but **no longer inverted** |

**#2488 — what changed in eco.** The #2244 redesign had used
`FlexSurfaceMode.highScaffoldLevelSurface` with `blendLevel: 40`, which
made the *scaffold more green than the cards on it* (scaffold ≈ `#9dc29f`,
cards ≈ `#d8e5d9`) — the ramp ran backwards. Green content (cheap-price
text, status dots, icons) lost contrast on the over-green page, and
`SectionCard`'s tint-only separation left cards with no delta. Eco now
uses `levelSurfacesLowScaffold` (same family as light/dark) at half the
blend (40 → 20), plus a 1 dp `cardElevation` and the `SectionCard`
hairline outline, so the ramp runs the correct direction in every theme.
The eco AppBar is now filled with **`primaryContainer`** (tonal) rather
than full `primary`, harmonising the chrome with the `PageScaffold`
banner while still reading "eco" at a glance.

The floating-SnackBar geometry (`behavior: floating`, `radius: 12`,
`elevation: 6`) is shared across all three via the
`AppTheme._floatingSnackBars` overlay — see "Component notes".

---

## Spacing scale

Canonical tokens live in `lib/core/theme/spacing.dart` as `Spacing.xs`
through `Spacing.xxxl`. Use them instead of hardcoded pixel values in
`EdgeInsets` / `SizedBox`.

| Token | Pixels | Typical usage |
| --- | --- | --- |
| `Spacing.xs` | `2` | Hairline gap (card vertical margin between list rows) |
| `Spacing.sm` | `4` | Icon-to-label inline gap; dense chip padding |
| `Spacing.md` | `8` | Between paired controls; row-gap in a form; default `cardGap` |
| `Spacing.lg` | `12` | List-item vertical padding; chip horizontal padding |
| `Spacing.xl` | `16` | Screen edge padding (`Spacing.screenPadding`); card inner padding |
| `Spacing.xxl` | `24` | Between major sections on a page |
| `Spacing.xxxl` | `32` | Hero-level breathing room (top of onboarding hero, bottom-sheet header) |

Pre-built combos in `Spacing`:

- `Spacing.screenPadding` → `EdgeInsets.all(16)` — root padding for every page body.
- `Spacing.cardPadding` → `EdgeInsets.all(16)` — inner padding inside `SectionCard`.
- `Spacing.cardMargin` → `EdgeInsets.symmetric(horizontal: 8, vertical: 2)` — between stacked cards.
- `Spacing.listItemPadding` → `EdgeInsets.symmetric(horizontal: 12, vertical: 8)` — settings rows.
- `Spacing.chipPadding` → `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` — filter chips.
- `Spacing.sectionGap` / `Spacing.cardGap` → `SizedBox(height: 8)` — vertical rhythm between sections.

**Rule:** never write `const EdgeInsets.all(16)` in a screen — use
`Spacing.screenPadding` (or `Spacing.cardPadding` inside a card). New
spacing values must be justified in PR review; preferred path is to
pick the nearest existing token.

---

## Radius scale

Canonical tokens **ship** in `lib/core/theme/app_radius.dart` (#2489).
Reuse them — do not write `BorderRadius.circular(12)` inline. Each token
exists in two forms: a raw `double` (`radius*`, for slots that want a
number) and a `BorderRadius.circular(...)` getter (`AppRadius.sm/md/lg/
xl/xxl`, for `borderRadius:` / `shape:` slots).

| Getter | `double` | Pixels | Use for |
| --- | --- | --- | --- |
| `AppRadius.sm` | `radiusSm` | `4` | Tight corners: small chips, dense inputs, `AppPill` |
| `AppRadius.md` | `radiusMd` | `8` | Default filled card (Material 3 filled-card rule) |
| `AppRadius.lg` | `radiusLg` | `12` | Elevated card / sheet rounding — canonical card radius (`SectionCard`, `StationCardShell`) |
| `AppRadius.xl` | `radiusXl` | `16` | Dialog + bottom-sheet corner; `SelectablePill`; the shared `chipRadius` (#2494) |
| `AppRadius.xxl` | `radiusXxl` | `24` | Hero surfaces (onboarding tiles, splash) |

**Canonical card radius: `AppRadius.lg` (12).** This matches what
`flex_color_scheme` already applies to every `Card` via
`subThemesData.cardRadius: 12.0` — so a plain `SectionCard` inherits it.
Do not raise the radius above 16 for cards; reserve `xxl` for hero /
onboarding surfaces only.

**Lint:** `test/lint/no_inline_border_radius_test.dart` scans all of
`lib/` for `Radius.circular(` (catching both `BorderRadius.circular(` and
a bare `Radius.circular(`) outside the token file. It carries a
**decrease-only baseline** (currently `126`) of pre-existing inline radii,
mirroring HARD RULE #1's pattern — the target is `0`. Never raise it;
drop it as call sites migrate to the `AppRadius.*` tokens.

---

## Elevation scale

Card separation is **theme-driven, not a fixed `0`** (#2488). A
`SectionCard` reads its elevation from `theme.cardTheme.elevation`, and
every theme *also* draws a hairline `surfaceContainerHighest` outline so
there is a real card↔scaffold delta even where the shadow is absent or
faint:

| Theme | Card elevation | What carries the separation |
| --- | --- | --- |
| `light()` | `0` | Tonal step (near-white scaffold vs `surfaceContainerLow` card) + the hairline outline — no shadow |
| `dark()` | `1` dp | A 1 dp shadow is faint on a dark surface, so the hairline outline does the work |
| `eco()` | `1` dp | The de-inverted tonal step + 1 dp shadow + hairline outline |

Floating surfaces still use higher levels:

| Level | Use for |
| --- | --- |
| `1` | Raised: `AppBar` surface-tinted elevation on scroll (Material 3), `SectionCard` on dark/eco, sticky headers that overlap content. |
| `2` | `StationCardShell` on light (the four station cards lift off the list; dark uses `1`). |
| `3`+ | Modal / menu: `BottomSheet`, `PopupMenu`, `Dialog`, `DropdownMenu`. Anything that floats above the current screen. The floating `SnackBar` uses `6`. |

**Rule (revised by #2488):** card↔scaffold separation no longer relies
on a tint *alone*. The earlier "tint, not a shadow" rule assumed the old
eco high-scaffold mode where the ramp was inverted; with the ramp
de-inverted, the canonical separation is **tonal step + hairline outline**
(every theme) plus a 1 dp shadow on dark/eco. If a card "needs" more lift
than that to be visible, the surrounding background is wrong — fix the
ramp, not the shadow.

---

## Text roles

Named text roles map to `TextTheme` slots so screens never have to
know which Material size they want. Each role has one canonical slot;
weight and color are applied by the canonical widget that owns the
role.

| Role | `TextTheme` slot | Weight | Color | Owner widget |
| --- | --- | --- | --- | --- |
| `pageTitle` | `headlineSmall` | `w500` | `onSurface` | `PageScaffold` app-bar title |
| `sectionHeader` | `titleMedium` | `w600` | `onSurface` | `SectionHeader.title` |
| `sectionSubhead` | `bodySmall` | `w400` | `onSurfaceVariant` | `SectionHeader.subtitle` |
| `bodyPrimary` | `bodyLarge` | `w400` | `onSurface` | Default `Text` inside a card body |
| `bodySecondary` | `bodyMedium` | `w400` | `onSurfaceVariant` | Supporting text, descriptions |
| `caption` | `bodySmall` | `w400` | `onSurfaceVariant` | Timestamps, disclaimers |
| `monoNumeric` | `titleMedium` | `w600` | `onSurface` | Price readouts, fuel amounts — apply `fontFeatures: [FontFeature.tabularFigures()]` |

**Rule:** inside feature code, never reach for
`Theme.of(context).textTheme.titleMedium.copyWith(...)` to style a
section heading. Hand the string to `SectionHeader` instead. The
allow-list for direct `TextTheme` access is exactly the canonical
widgets in `lib/core/widgets/` and the theme files in
`lib/core/theme/`. The lint scan in phase N enforces this.

---

## Semantic colors

Beyond the palette, several colour layers carry app-specific meaning.
The #2487 disambiguation gives **one distinct meaning per colour** — the
single `warning`-orange token used to carry 6+ unrelated roles (staleness,
corrections, borderline efficiency, storage dots, EV-in-use). Each role
below maps to exactly one source.

### Named semantic-role table

| Role | Colour source | When to use it |
| --- | --- | --- |
| **Warning** (attention / stale only) | `DarkModeColors.warning(context)` — gold/amber | Freshness/stale badges, genuine "needs attention". **Not** corrections, **not** storage. |
| **Error** (expensive / failure) | `DarkModeColors.error(context)` — deep red; `ColorScheme.error` for destructive chrome | Closed/expensive indicators, validation failure, Delete-all. |
| **Success** (open / cheap) | `DarkModeColors.success(context)` — green | Open/cheap indicators, positive status dots. |
| **Corrections** (informational, **neutral — NOT warning**) | `colorScheme.tertiary` (the `_CorrectionRow` accent) or `onSurfaceVariant` (the "Corrections: +X L" line) | A reconciliation correction is informational, not an alert — #2491 moved it **off** the warning-orange onto neutral tones. |
| **Storage categories** (neutral categorical) | `surfaceContainerHighest` / `secondaryContainer` / `tertiaryContainer` / `outlineVariant` / `tertiary` | Storage-bar segments + legend dots. Benign data must not read as data-loss — #2490 moved Cache off `error` and the dots off warning-orange; error-red is reserved for Delete-all. |
| **Efficiency bands** | `DarkModeColors` success/warning/error by band | Eco-score / driving-style bands. Borderline efficiency uses `warning`; it does **not** borrow the correction or storage tones. |
| **Map-overlay chrome** | `DarkModeColors.mapOverlay / mapOverlayIcon / mapOverlayShadow` | The floating-control surface (legend, zoom buttons) — tuned for both brightness modes. Do not reinvent. |

Chip backgrounds for the status trio:
`DarkModeColors.successSurface(context)` / `errorSurface` /
`warningSurface`. Never call `Colors.green` / `Colors.red` /
`Colors.grey` / `Colors.amber` directly — the helper switches on
`Theme.of(context).brightness` so dark-mode contrast holds.

### Price-band ramp (the ONE cheap→expensive system)

`lib/core/theme/price_band_colors.dart` is the **single canonical**
cheap→expensive ramp (#2492). Before it, the map markers used
`[green, yellow, orange, red]` while the legend used a 3-stop
success/warning/error gradient with no yellow — two divergent systems.
Both the markers (`station_marker.dart`) and the legend
(`price_legend.dart`) now consume `PriceBandColors.ramp`, so the legend
always describes exactly what the markers paint.

| Stop | Constant | Hex | Meaning |
| --- | --- | --- | --- |
| 0 | `PriceBandColors.cheap` | `#43A047` | Cheap (bottom third) — green = good |
| 1 | `PriceBandColors.belowAverage` | `#F9A825` | Lower-middle pivot (saturated amber) |
| 2 | `PriceBandColors.aboveAverage` | `#F57C00` | Upper-middle pivot (orange) |
| 3 | `PriceBandColors.expensive` | `#C62828` | Expensive (top third) — red = costly |

`PriceBandColors.ramp` is the 4-stop list (breakpoints at 1/3 and 2/3).
The legend's three tiers are `cheapTier` / `averageTier` (the midpoint
`lerp` of the two middle stops) / `expensiveTier`. The bright amber is
intentional here — these are *fill* colours behind dark marker text and
standalone legend swatches; the *semantic* `warning` text token darkens
the same hue for AA contrast as text.

### Fuel-type semantics

`lib/core/theme/fuel_colors.dart` exposes one **muted, deep** colour per
`FuelType` (#1757) — desaturated well below the old electric Material-500
hues so the palette sits calmly next to the forest-green theme, while
each fuel keeps a distinguishable hue and stays dark enough to read as
bold price text on a light card (WCAG AA-large).

| `FuelType` | Hex | Tone |
| --- | --- | --- |
| `FuelTypeE5` | `#4F7C44` | Muted green |
| `FuelTypeE10` | `#3B6FA0` | Muted slate-blue |
| `FuelTypeE98` | `#7B4E86` | Muted plum |
| `FuelTypeDiesel` | `#BE7C1E` | Muted ochre |
| `FuelTypeDieselPremium` | `#B5573B` | Muted terracotta |
| `FuelTypeE85` | `#73904A` | Muted olive |
| `FuelTypeLpg` | `#3C8794` | Muted teal-cyan |
| `FuelTypeCng` | `#5C7079` | Muted blue-grey |
| `FuelTypeHydrogen` | `#4589AC` | Muted sky-blue |
| `FuelTypeElectric` | `#3B8079` | Muted teal (price hue) |
| `FuelTypeAll` | `#6F6F6F` | Neutral grey ("any fuel" marker) |

`FuelColors.forType(type)` returns the base colour;
`FuelColors.forTypeLight(type)` returns it at 15% alpha for chip
backgrounds / map cluster fills. `FuelColors.stripeColor(context, type)`
is the `StationCardShell` left-stripe variant — identical to `forType`
for a concrete fuel, but resolves the all-fuels case to the theme
**primary** (forest green) instead of the near-invisible neutral grey.

**EV accent — `FuelColors.evAccent = #4FC3F7`** (crystal-blue, #2143 /
#2493). This is the **single source** for the EV-surface accent: the kW
headline, the EV card's left stripe and the connector-chip tints all
reference it. It is deliberately distinct from the muted-teal
`FuelTypeElectric` *price* hue (`#3B8079`) and replaces the three
divergent values that used to live in `ev_favorite_card.dart` (`#4FC3F7`),
`ev_station_card.dart` (teal `#009688`) and `ev_connector_chips.dart`
(`#2196F3`).

---

## Canonical widgets — contracts

Five widgets cover every "page / section / card / tab" need in the
app. Phase 2 of #923 implements the missing ones in `lib/core/widgets/`.

### 1. `PageScaffold`

**Role:** every top-level screen's outer chrome — `Scaffold` +
`AppBar` + optional primary-tinted banner below the app bar + body.
Replaces the three competing conventions for "this is what this
screen is about" identified in the #923 audit.

**Props:**

- `title: String?` — `pageTitle` role. Renders in the `AppBar` wrapped
  in `Semantics(header: true, …)`. Mutually exclusive with
  `titleWidget`: pass exactly one. The `bannerIcon` slot also requires
  this string variant since the banner shows the title text.
- `titleWidget: Widget?` — escape hatch for screens whose title cannot
  be expressed as plain text (e.g. `StationDetailScreen`'s
  Hero-flighted brand-header composition). Mutually exclusive with
  `title`. The caller owns the title's semantics (header role,
  ellipsis, etc.) when this slot is used.
- `subtitle: String?` — optional second line under the app-bar title.
- `bannerIcon: IconData?` — when non-null, renders a primary-tinted
  banner strip below the app bar carrying the icon + `title` +
  `subtitle`. Mirrors the `PrivacyDashboardScreen` / `ThemeSettingsScreen`
  convention.
- `actions: List<Widget>?` — app-bar trailing actions. Every
  `IconButton` must carry a `tooltip:` (see accessibility rules).
- **required** `body: Widget` — scrollable content. `PageScaffold`
  applies `Spacing.screenPadding` to the body by default; opt out via
  `bodyPadding: EdgeInsets.zero` for full-bleed content (map screen).
- `floatingActionButton: Widget?` — pass-through to
  [Scaffold.floatingActionButton]. Enables MapScreen's
  `DrivingModeFab` to live inside `PageScaffold`.
- `floatingActionButtonLocation: FloatingActionButtonLocation?` —
  pass-through to [Scaffold.floatingActionButtonLocation]. Default
  `null` uses `Scaffold`'s default (end-float); pass
  `FloatingActionButtonLocation.centerDocked` when pairing with a
  bottom bar.
- `bottomNavigationBar: Widget?` — pass-through to
  [Scaffold.bottomNavigationBar]. Used by form screens
  (e.g. `AddFillUpScreen`, `EditVehicleScreen`) to pin a Save button
  above the system nav inset without stealing scrollable real estate.
- `leading: Widget?` — optional leading app-bar widget. Normally the
  back button — pass a custom drawer icon when needed. Works with
  `automaticallyImplyLeading: false` when the caller wants full
  control.
- `bottom: PreferredSizeWidget?` — optional widget rendered below the
  app-bar title (pass-through to `AppBar.bottom`). Used by tabbed
  screens (e.g. `FavoritesScreen`, `ConsumptionScreen`) to host a
  `TabBar` / `TabSwitcher` under the title while keeping the rest of
  the scaffold contract intact.
- `automaticallyImplyLeading: bool` — whether the app bar shows its
  automatic leading. Default: `true`.
- `toolbarHeight: double?` — optional override for the app-bar toolbar
  height (pass-through to `AppBar.toolbarHeight`). Default `null` uses
  Material's default; compact layouts (e.g. `SearchScreen` in
  landscape) pass `40`.
- `titleTextStyle: TextStyle?` — optional override for the app-bar
  title text style (pass-through to `AppBar.titleTextStyle`). Default
  `null` uses Material's default; compact layouts (e.g. `MapScreen`
  in landscape) pass `TextStyle(fontSize: 16)`.
- `titleSpacing: double?` — optional override for the horizontal
  space between the leading widget and the title (pass-through to
  `AppBar.titleSpacing`). Default `null` uses `NavigationToolbar.kMiddleSpacing`
  (16); compact layouts (e.g. `MapScreen` in landscape) pass `12`.

**Accessibility:** the app-bar title is wrapped in
`Semantics(header: true, …)` so TalkBack/VoiceOver announce the
`pageTitle` with the heading role. Callers get this for free — no
action required.

**Visual contract:**

```dart
return Scaffold(
  appBar: AppBar(title: Text(title)),
  body: Column(
    children: [
      if (bannerIcon != null)
        _PageBanner(icon: bannerIcon!, title: title, subtitle: subtitle),
      Expanded(
        child: Padding(
          padding: bodyPadding ?? Spacing.screenPadding,
          child: body,
        ),
      ),
    ],
  ),
  floatingActionButton: floatingActionButton,
);
```

**Use for:** every screen under `lib/features/*/presentation/screens/`.
**Do NOT use for:** full-bleed content (map, onboarding hero) — those
keep a custom root for now and are exempt from the static scan by
file-path allow-list.

**Example after migration:** `ThemeSettingsScreen` and
`PrivacyDashboardScreen` already render a primary-tinted banner below
their app bar — `PageScaffold(bannerIcon: Icons.dark_mode, title: ...,
body: ...)` replaces those two hand-rolled scaffolds.

### 2. `SectionHeader`

**Role:** the 67 inline `textTheme.titleMedium` calls collapse into
one widget. A section heading = `sectionHeader` role title + optional
`sectionSubhead` subtitle + optional trailing action button.

**Props:**

- **required** `title: String`
- `subtitle: String?`
- `trailing: Widget?` — optional right-aligned action
  (`TextButton`, `IconButton` with tooltip, …).
- `leadingIcon: IconData?` — small 16 dp icon before the title, primary-tinted.
- `padding: EdgeInsets` — defaults to
  `EdgeInsets.fromLTRB(Spacing.xl, Spacing.lg, Spacing.xl, Spacing.sm)`.

**Visual contract:**

```dart
return Padding(
  padding: padding,
  child: Row(
    children: [
      if (leadingIcon != null) ...[
        Icon(leadingIcon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: Spacing.md),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            if (subtitle != null)
              Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          ],
        ),
      ),
      if (trailing != null) trailing!,
    ],
  ),
);
```

**Use for:** every inline section heading inside a screen body.
**Do NOT use for:** app-bar titles (`PageScaffold` owns that), dialog
titles (`AlertDialog.title`), or card internal headers when the card
is `FormSectionCard` / `SectionCard` — those already render their own
header from `title` / `subtitle` props.

**Example after migration:** `favorites_section_header.dart` (only
used by Favorites today) is replaced by `SectionHeader(leadingIcon:
Icons.local_gas_station, title: l10n.favoritesFuelSectionTitle)`.

### 3. `SectionCard`

**Role:** one card, one elevation, one radius, one padding. Replaces
the 86 raw `Card(...)` call sites with ad-hoc elevation/margin/color.
Same visual contract as `FormSectionCard` but generic — no mandatory
form structure.

**Props:**

- `title: String?` — when non-null, the card renders an internal
  `SectionHeader` at the top.
- `subtitle: String?`
- `leadingIcon: IconData?` — passed to the internal header.
- `accent: Color?` — defaults to `colorScheme.primary`.
- **required** `child: Widget` — the body.
- `padding: EdgeInsets` — defaults to `Spacing.cardPadding`.
- `margin: EdgeInsets` — defaults to `EdgeInsets.zero` so the
  screen's `ListView` / `Column` controls stacking.

**Visual contract (as shipped, #2488):** elevation follows the theme
(`theme.cardTheme.elevation` — light `0`, dark/eco `1` dp) and the card
draws an explicit hairline `surfaceContainerHighest` outline so the
card↔scaffold delta holds on every theme (most importantly on light,
where there is no shadow, and on dark, where a 1 dp shadow is faint):

```dart
return Card(
  margin: margin,
  clipBehavior: Clip.antiAlias,
  elevation: theme.cardTheme.elevation ?? 0,
  color: scheme.surfaceContainerLow,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12), // AppRadius.lg
    side: BorderSide(color: scheme.surfaceContainerHighest), // hairline
  ),
  child: Padding(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          SectionHeader(
            title: title!,
            subtitle: subtitle,
            leadingIcon: leadingIcon,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: Spacing.md),
        ],
        child,
      ],
    ),
  ),
);
```

**Use for:** every grouped content block on a screen.
**Do NOT use for:** a card whose shape is specifically bespoke. The four
station cards now share `StationCardShell` (see "Component notes"), not
`SectionCard`; `BrandLogo` tiles in the map legend stay raw. Bespoke
cards must document the reason in a file-header comment — the lint scan
(`test/lint/no_raw_card_in_features_test.dart`) carries an allow-list
keyed to file path, not a blanket exemption.

**Example after migration:** `FormSectionCard` in the Add-Fill-up
form stays as a specialized sub-class of `SectionCard` that knows
about `FormFieldTile` rows; plain-content cards in Carbon / Price
History / Sync use `SectionCard` directly.

### 4. `SettingsMenuTile`

**Role:** already exists at
`lib/features/profile/presentation/widgets/settings_menu_tile.dart`.
Phase 2 promotes it to `lib/core/widgets/settings_menu_tile.dart` and
re-imports existing callers. No API change.

**Props (unchanged):**

- **required** `icon: IconData`
- **required** `title: String`
- **required** `subtitle: String`
- **required** `onTap: VoidCallback`

**Visual contract (unchanged):**

```dart
return Card(
  margin: EdgeInsets.zero,
  child: ListTile(
    leading: Icon(icon, size: 20),
    title: Text(title, style: theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    )),
    subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  ),
);
```

**Use for:** every top-level navigation row on a settings-style
screen (Profile → Vehicles, Privacy Dashboard, Theme, Sync, …) plus
any similar "tap to drill in" list entry.
**Do NOT use for:** toggle rows (use a plain `SwitchListTile` inside a
`SectionCard`), destructive actions (use a `TextButton` with the
error color), or station / favorite list items (each has its own
dedicated card). The audit's "34 raw `ListTile` call sites" are the
migration target — each one falls into one of these three buckets or
becomes a `SettingsMenuTile`.

**Example after migration:** `ProfileScreen`, `SyncSetupScreen`, and
every onboarding settings page feed their menu rows through
`SettingsMenuTile` from `lib/core/widgets/`.

### 5. `TabSwitcher`

**Role:** one canonical tab row. Replaces the three implementations
found in the audit (`ConsumptionScreen` `TabBar`, `FavoritesScreen`
`TabBar` with different styling, `CarbonDashboardScreen`
`SegmentedButton`).

**Props:**

- **required** `tabs: List<TabSwitcherEntry>` — each entry carries
  `label: String`, `icon: IconData?`, and `semanticLabel: String?`.
- **required** `selectedIndex: int`
- **required** `onTabSelected: ValueChanged<int>`
- `isScrollable: bool` — default `false`. Set `true` only when labels
  overflow on narrow screens (3+ tabs with long labels in the short
  languages).

**Visual contract:**

Each tab is a **compact single row** — icon *beside* the label, not
Material's default stacked `icon:`/`text:` (which renders ~72 dp tall).
The compact row fits ~49 dp. Colours/weight stay unset on the child so
the `TabBar` theme drives the selected ↔ unselected animation for both
the Icon (via `IconTheme`) and the Text (via `DefaultTextStyle`).

```dart
return Material(
  color: Colors.transparent,
  child: TabBar(
    tabs: [
      for (final entry in tabs)
        Tab(
          child: Semantics(
            label: entry.semanticLabel ?? entry.label,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.icon != null) ...[
                  Icon(entry.icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(entry.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
    ],
    controller: DefaultTabController.of(context),
    labelColor: theme.colorScheme.primary,
    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
    indicatorColor: theme.colorScheme.primary,
    indicatorWeight: 3,
    labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    isScrollable: isScrollable,
  ),
);
```

**Use for:** any screen that presents "pick one of N full-screen
views" (`ConsumptionScreen` fuel / trips / carbon; `FavoritesScreen`
fuel / EV).
**Do NOT use for:** "choice within a section" filters — keep
`SegmentedButton` for those (e.g. the carbon dashboard's
period switcher stays a segmented button because it filters the
already-shown content, it does not switch views).

**Example after migration:** `ConsumptionScreen` and
`FavoritesScreen` wrap their view bodies in a `DefaultTabController`
and feed `TabSwitcher(tabs: [...], ...)` into the scaffold body's
header slot.

---

## Component notes (theme-level, #2487 Wave 2/3)

Beyond the five canonical scaffolding widgets, the theme layer now owns
a few shared component contracts so screens stop re-inventing them.

### Floating SnackBar

There is no docked SnackBar anywhere. `AppTheme._floatingSnackBars`
overlays `SnackBarBehavior.floating` on the `snackBarTheme` of all three
themes (FlexColorScheme sets radius/elevation via `subThemesData`
— `snackBarRadius: 12`, `snackBarElevation: 6` — but never the behavior),
so every SnackBar floats **clear of the bottom nav bar** instead of
clipping against it on full-screen routes (the "Delete radius alert?"
clip, #2488). Just call `ScaffoldMessenger.showSnackBar` — the geometry
is automatic.

### Chips, `SelectablePill`, `AppPill`

One pill family, one corner radius. The theme sets
`chipRadius: AppRadius.radiusXl` (16) on every Material `Chip` (#2494) so
chips match the two bespoke pill widgets:

- **`SelectablePill`** (`lib/core/widgets/selectable_pill.dart`) — a
  compact **toggleable** icon+label pill for binary/segmented mode
  selection (search "All / Best stops", route-map "All / Best"). Selected
  → `primaryContainer` fill + `primary` outline + bold label + `primary`
  icon; unselected → transparent with a faint `outline` border. Corner
  `AppRadius.xl`. Collapses the old `ModeChip` (r20) + `RouteViewModeChip`
  (r16) into one shape.
- **`AppPill`** (`lib/core/widgets/app_pill.dart`) — a small **static**
  (non-toggleable) labelled badge for connector / amenity / count pills.
  No selection, no tap. Defaults to the neutral
  `surfaceContainerHighest` / `onSurfaceVariant` pair (overridable for
  semantic pills); corner `AppRadius.sm` (the dense-chip token). Reach for
  `SelectablePill` when the pill toggles a mode; `AppPill` when it is a
  passive label.

### `StationCardShell`

`lib/core/widgets/station_card_shell.dart` is the **one** card frame for
all four station cards (`StationCard`, `EvFavoriteCard`, `EVStationCard`,
`AllPricesStationCard`), which previously hand-copied a drifting frame
(#2493). The shell owns: margin `symmetric(horizontal: 8, vertical: 6)`,
`Clip.antiAlias`, elevation `2` on light / `1` on dark, radius
`AppRadius.lg` (12), an `InkWell` tap target, and an optional left accent
**stripe**.

**The stripe colour is the only axis** distinguishing fuel vs EV cards —
the frame is identical:

- **Fuel** cards stripe with `FuelColors.stripeColor(context, type)` —
  the muted forest-green-family fuel hue (all-fuels → theme `primary`).
- **EV** cards stripe with `FuelColors.evAccent` (`#4FC3F7` crystal-blue).
- The all-prices card passes `stripeColor: null` (its colour lives in the
  per-fuel badges instead); the cheapest-fuel card bumps `stripeWidth`
  to `6` to emphasise the winner.

---

## Migration rules

Three rules land together in phase N of the epic:

1. **New screens MUST use `PageScaffold`.** A static scan forbids raw
   `AppBar(...)` inside any file under
   `lib/features/*/presentation/screens/` (allow-list: full-bleed map
   and onboarding-hero screens, enumerated by file path). The message
   points here.

2. **Section headings MUST use `SectionHeader`.** Inline
   `Theme.of(context).textTheme.titleMedium` / `titleLarge` /
   `headlineSmall` is forbidden in feature code except inside
   `SectionHeader` / `PageScaffold` / `SectionCard` themselves
   (allow-list by file path). Price readouts etc. that need
   `monoNumeric` use `textTheme.titleMedium` with
   `fontFeatures: [FontFeature.tabularFigures()]` — those stay on an
   explicit allow-list of files that own the numeric readout.

3. **Cards MUST use `SectionCard`** unless the shape is specifically
   bespoke (station card, map legend card, etc.). Bespoke cards
   survive by file-header comment + file-path allow-list. Raw
   `Card(...)` in a feature screen fails the scan.

---

## Lint enforcement

Phase N adds four static scans under `test/lint/`, each following the
existing pattern (file-system walk, regex match, assert on match
count). They do not do Dart analysis — they are grep-style, like
`test/lint/no_silent_catch_test.dart`:

1. `no_raw_appbar_in_features_test.dart` — forbids `AppBar(` in
   `lib/features/*/presentation/screens/*.dart` except an explicit
   allow-list. Failure message: "use PageScaffold — see
   docs/design/DESIGN_SYSTEM.md".

2. `no_inline_title_theme_test.dart` — forbids
   `textTheme.titleMedium` / `textTheme.titleLarge` /
   `textTheme.headlineSmall` outside the allow-list (core widgets,
   theme files, numeric-readout files). Failure message: "use
   SectionHeader — see docs/design/DESIGN_SYSTEM.md".

3. `no_raw_card_in_features_test.dart` — forbids `Card(` in feature
   screens. Failure message: "use SectionCard — see
   docs/design/DESIGN_SYSTEM.md".

4. `tab_switcher_canonical_test.dart` — forbids `TabBar(` outside
   `TabSwitcher` itself. Failure message: "use TabSwitcher — see
   docs/design/DESIGN_SYSTEM.md".

Each scan fails loud with file:line of the offending call + the
`docs/design/DESIGN_SYSTEM.md` URL so a dev fixing the failure lands
in the right section.

---

## Out of scope

- **Image assets** — icons, illustrations, splash, store graphics.
  Owned by `docs/design/ASSET_SPEC.md`.
- **Localized strings** — every user-facing label is produced via
  ARB files and governed by `docs/design/ARB_FRAGMENTS.md` when that
  lands. This doc only specifies the *role* a string plays (page
  title, section header, caption) — never the string itself.
- **Animations / motion** — duration curves, hero transitions, and
  state-driven animations stay per-feature. The design system
  guarantees the static visual contract; motion is a separate
  surface.
- **Accessibility specifics** — tooltip coverage, tap-target sizes,
  semantic grouping are enforced by `test/accessibility/` and the
  project CLAUDE.md accessibility section. This doc only reminds
  canonical widgets to pass `tooltip:` through and to merge
  semantics where appropriate; it does not re-specify the a11y
  rules.
