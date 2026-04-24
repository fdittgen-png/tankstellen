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

Pulled from the existing Material theme (`lib/app/theme.dart`, which
uses `FlexScheme.bahamaBlue` from `flex_color_scheme`). These hex
values are what the placeholder assets and the shipped UI already use;
the table below names each `ColorScheme` slot by the role it plays in
the app, not by its Material spec name.

| Role | Hex (light) | Hex (dark) | `ColorScheme` slot | Where it shows up |
| --- | --- | --- | --- | --- |
| Brand primary | `#4059AD` | `#8FB2F5` | `primary` | App bar tint, primary buttons, brand logo fill |
| On-primary | `#FFFFFF` | `#0E2A5A` | `onPrimary` | Text / icons on primary surfaces |
| Secondary | `#6B8AEE` | `#B7C8F0` | `secondary` | Chips, secondary accents |
| Surface | `#F6F8FF` | `#11131B` | `surface` | Scaffold background |
| Surface container low | `#ECEFF8` | `#181A23` | `surfaceContainerLow` | `SectionCard` background |
| Surface container | `#E6E9F3` | `#1E212B` | `surfaceContainer` | Elevated sheet / modal background |
| On-surface | `#1B1D24` | `#E3E5ED` | `onSurface` | Body text |
| On-surface variant | `—` | `—` | `onSurfaceVariant` | Muted / secondary text |
| Outline | `—` | `—` | `outline` | Hairlines, disabled-text hint |
| Error | `#BA1A1A` | `#FFB4AB` | `error` | Destructive actions, validation |

Success and warning semantic colors are not part of the `ColorScheme`
directly — they live in `lib/core/theme/dark_mode_colors.dart`, keyed
to brightness:

| Role | Light | Dark | Source |
| --- | --- | --- | --- |
| Success | `#388E3C` | `#66BB6A` | `DarkModeColors.success(context)` |
| Warning | `#E65100` | `#FFA726` | `DarkModeColors.warning(context)` |
| Error (semantic) | `#D32F2F` | `#EF5350` | `DarkModeColors.error(context)` |

All dark-mode variants target at least 4.5:1 contrast against the
standard Material 3 dark surface. Do not hardcode `Colors.green`,
`Colors.red`, or `Colors.grey` — always call the helper.

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

Canonical tokens in `lib/core/theme/app_radius.dart`. Reuse these —
do not write `BorderRadius.circular(12)` inline.

| Token | Pixels | Use for |
| --- | --- | --- |
| `AppRadius.sm` / `radiusSm` | `4` | Tight corners: small chips, dense inputs |
| `AppRadius.md` / `radiusMd` | `8` | Default filled card (Material 3 filled-card rule) |
| `AppRadius.lg` / `radiusLg` | `12` | Elevated card / sheet rounding — **matches the theme's `cardRadius: 12.0`**. Canonical `SectionCard` radius. |
| `AppRadius.xl` / `radiusXl` | `16` | Dialog + bottom-sheet corner |
| `AppRadius.xxl` / `radiusXxl` | `24` | Hero surfaces (onboarding tiles, splash) |

**Canonical card radius: `AppRadius.lg` (12).** This matches what
`flex_color_scheme` already applies to every `Card` via
`subThemesData.cardRadius: 12.0` — so `SectionCard` does not need to
override a shape. Do not raise the radius above 16 for cards; reserve
`xxl` for hero / onboarding surfaces only.

---

## Elevation scale

Three levels, nothing else. Anything higher must be justified in the
PR body.

| Level | Use for |
| --- | --- |
| `0` | Flat: `SectionCard`, every card inside a scrollable screen, `SettingsMenuTile`. We rely on a `surfaceContainerLow` tint, not a shadow, to separate cards from scaffold. |
| `1` | Raised: `AppBar` surface-tinted elevation on scroll (handled by Material 3), sticky headers that overlap content. |
| `3` | Modal / menu: `BottomSheet`, `PopupMenu`, `Dialog`, `DropdownMenu`. Anything that floats above the current screen. |

**Rule:** `SectionCard` ships with `elevation: 0` + a tinted
background. Shadows at elevation 2 or above are reserved for modal
contexts. If a card "needs" a shadow to be visible, the surrounding
background is wrong — fix that instead.

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

Beyond the palette, three color layers carry app-specific meaning.

### Status semantics

Use `DarkModeColors` (see palette table) — never `Colors.green` /
`Colors.red` / `Colors.grey` directly. The helper switches on
`Theme.of(context).brightness` so dark-mode contrast stays ≥ 4.5:1.
Chip backgrounds: `DarkModeColors.successSurface(context)` /
`errorSurface` / `warningSurface`.

### Fuel-type semantics

`lib/core/theme/fuel_colors.dart` exposes one color per
`FuelType` — reuse for chart legends, fuel badges, map pins. Summary:

| `FuelType` | Color | Role |
| --- | --- | --- |
| `FuelTypeE5` | `#4CAF50` green | Regular-E5 petrol |
| `FuelTypeE10` | `#2196F3` blue | E10 petrol |
| `FuelTypeE98` | `#9C27B0` purple | Premium E98 |
| `FuelTypeDiesel` | `#FF9800` orange | Diesel |
| `FuelTypeDieselPremium` | `#FF5722` deep orange | Premium diesel |
| `FuelTypeE85` | `#8BC34A` light green | E85 |
| `FuelTypeLpg` | `#00BCD4` cyan | LPG |
| `FuelTypeCng` | `#607D8B` blue-grey | CNG |
| `FuelTypeHydrogen` | `#03A9F4` light blue | Hydrogen |
| `FuelTypeElectric` | `#009688` teal | EV charging |
| `FuelTypeAll` | `#757575` grey | "Any fuel" filter marker |

`FuelColors.forType(type)` returns the base color;
`FuelColors.forTypeLight(type)` returns it at 15% alpha for chip
backgrounds / map cluster fills.

### Map overlay semantics

`DarkModeColors.mapOverlay / mapOverlayIcon / mapOverlayShadow`
provide the floating-control surface. Do not reinvent — the map
shadows are tuned for both brightness modes.

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

- **required** `title: String` — `pageTitle` role. Renders in the
  `AppBar`.
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
- `bottomNavigationBar: Widget?` — reserved for the shell; leaf
  screens do not set this.
- `toolbarHeight: double?` — optional override for the app-bar toolbar
  height (pass-through to `AppBar.toolbarHeight`). Default `null` uses
  Material's default; compact layouts (e.g. `SearchScreen` in
  landscape) pass `40`.

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

**Visual contract:**

```dart
return Card(
  margin: margin,
  clipBehavior: Clip.antiAlias,
  elevation: 0,
  color: theme.colorScheme.surfaceContainerLow,
  // `shape` omitted — theme applies AppRadius.lg globally.
  child: Padding(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          SectionHeader(
            title: title!,
            subtitle: subtitle,
            leadingIcon: leadingIcon,
            padding: EdgeInsets.zero,
          ),
        if (title != null) const SizedBox(height: Spacing.md),
        child,
      ],
    ),
  ),
);
```

**Use for:** every grouped content block on a screen.
**Do NOT use for:** a card whose shape is specifically bespoke
(e.g. `StationCard` with its price pill overlay, `BrandLogo` tile in
the map legend). Bespoke cards stay raw but must document the reason
in a file-header comment — the lint scan will carry an allow-list
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

```dart
return Material(
  color: Colors.transparent,
  child: TabBar(
    tabs: [
      for (final entry in tabs)
        Tab(
          icon: entry.icon != null ? Icon(entry.icon) : null,
          text: entry.label,
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
