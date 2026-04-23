# Tankstellen — Brand Asset Specification

**Status:** living document. Generator-ready spec for every brand asset
in the repo. Placeholders ship today (#589, #590, #593) so the app
identity is coherent; production versions drop into the same paths
once the generator prompts below are run.

**Audience:** the human designer, a downstream LLM-driven image
generator (DALL-E 3, Midjourney, SDXL), or a Figma-based pipeline. Each
section is a standalone contract: path, dimensions, palette,
composition, symbolism, style constraints, generator prompt, acceptance.

---

## How to use this spec

1. Open the section for the asset you need to produce.
2. Copy the **Generator prompt** verbatim into your image tool. If the
   tool supports reference images, attach the placeholder currently
   living at the **Filename / target path**.
3. Verify the output against the **Acceptance criteria**.
4. Drop the rasterized file at the documented path, replacing the
   placeholder. For vectors, overwrite the `.xml` / `.svg`.
5. Run `flutter analyze` and `flutter test`, then `git commit`.
6. For adaptive icons: run `flutter pub run flutter_launcher_icons`
   (already configured in `pubspec.yaml`) if your production asset
   comes in as PNG. For vector XML drops, no regeneration needed.

---

## Brand palette

Pulled from the existing Material theme (`lib/app/theme.dart`, which
uses `FlexScheme.bahamaBlue` from `flex_color_scheme`). These are the
hex values the placeholders target; production generators MUST use
these values unless a future redesign supersedes this document.

| Token | Hex (light) | Hex (dark) | Where it shows up |
| --- | --- | --- | --- |
| `primary` | `#4059AD` | `#8FB2F5` | Brand glyph fills, buttons, illustration heroes |
| `onPrimary` | `#FFFFFF` | `#0E2A5A` | Glyph on primary (e.g. drop inside shield) |
| `secondary` | `#6B8AEE` | `#B7C8F0` | Chip accents (rarely in brand assets) |
| `surface` | `#F6F8FF` | `#11131B` | Illustration soft backdrop (inner radial stop) |
| `surfaceContainerLow` | `#ECEFF8` | `#181A23` | Illustration soft backdrop (outer radial stop) |
| `onSurface` | `#1B1D24` | `#E3E5ED` | Illustration body text / sparkline |

**Brand accent (privacy green):** `#2E7D32` — currently wired to
`ic_launcher_background` in `android/app/src/main/res/values/colors.xml`.
**TODO:** the launcher background should migrate to `primary` (`#4059AD`)
once the full icon redesign ships. Until then, the two greens (`#2E7D32`
launcher backdrop, `#388E3C` dark-mode success indicator) stay put for
visual continuity with existing screenshots on the Play Store.

---

## 1. Android adaptive icon — foreground

- **Filename / target path:** `android/app/src/main/res/drawable/ic_launcher_foreground.xml` (vector) + `android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png` through `drawable-xxxhdpi/ic_launcher_foreground.png` (generated from PNG).
- **Dimensions & format:** 108dp × 108dp canvas, 72dp safe zone, PNG densities 108px (mdpi) / 162px (hdpi) / 216px (xhdpi) / 324px (xxhdpi) / 432px (xxxhdpi). Vector XML version currently ships as the placeholder.
- **Palette:** white (`#FFFFFF`) glyph. Background delegated to `ic_launcher_background.xml`.
- **Composition:** Fuel drop (teardrop) vertically centered inside a shield outline. Shield silhouette: top flat (38% width), tapering to a rounded point at the bottom; stroke only. Drop fills the upper two-thirds of the shield's interior. All geometry within the 72dp safe zone (18dp inset on every side).
- **Symbolism:** Fuel drop = the product (fuel price comparison). Shield = the privacy pledge (no Google Play Services, user-provided API keys). Same motif repeats on the splash and the onboarding privacy step — unified identity.
- **Style constraints:** flat 2-tone; no gradients; no text; no drop shadow; no outer bleed into the mask area (Android launchers crop in circles, squircles, squares — design must survive every mask).
- **Generator prompt:**
  > Flat vector adaptive Android app icon foreground, 108×108dp canvas with 72dp safe zone centered. Subject: a white fuel drop (teardrop shape) nested inside a white shield outline (stroke only, 4dp stroke width, soft corners). The drop is vertically centered in the shield, occupying 55% of the shield's height. Pictogram style, no text, no gradient, no drop shadow, transparent background. 2-color palette: white (`#FFFFFF`) on transparent. Export as PNG at 1× (108px), 1.5× (162px), 2× (216px), 3× (324px), 4× (432px) densities.
- **Acceptance:** renders legibly at 48dp (emulator launcher); survives circle, squircle, square, rounded-square masks; no content touches the outer 18dp bleed zone; passes [Android adaptive icon guidelines](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive).

---

## 2. Android adaptive icon — background

- **Filename / target path:** `android/app/src/main/res/values/colors.xml` (entry `<color name="ic_launcher_background">`).
- **Dimensions & format:** single solid color; no PNG needed.
- **Value today:** `#2E7D32` (privacy green, ties to existing Play Store screenshots).
- **Migration target:** `#4059AD` (theme primary) once the full icon redesign ships.
- **Style constraints:** must be opaque (adaptive icon spec); no gradient; no pattern.
- **Generator prompt:** N/A (hex only).
- **Acceptance:** `flutter run` shows the launcher icon with matching backdrop; Android Studio preview renders both at every mask.

---

## 3. Legacy square icon (pre-API-26 devices)

- **Filename / target path:** `android/app/src/main/res/mipmap-<density>/ic_launcher.png` for each of `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`.
- **Dimensions & format:** PNG, 24-bit, transparent corners optional. Sizes: 48×48 (mdpi), 72×72 (hdpi), 96×96 (xhdpi), 144×144 (xxhdpi), 192×192 (xxxhdpi).
- **Palette:** same drop-in-shield glyph on a `#2E7D32` rounded-rect backdrop (24px corner radius on mdpi, scaled for densities).
- **Composition:** center the drop-in-shield glyph; glyph height 60% of the icon height.
- **Symbolism:** same as § 1.
- **Style constraints:** flat; no text; no drop shadow. Legacy devices don't mask, so the rounded-rect backdrop IS the final shape the user sees.
- **Generator prompt:**
  > Flat Android launcher icon, 192×192 PNG, rounded-square (24px corner radius on 192px canvas), background color `#2E7D32`. Centered white fuel drop (teardrop) inside a white shield outline (stroke only, 5px stroke). Glyph occupies 60% of icon height. 2-color palette: white on `#2E7D32`. Pictogram style, no text, no gradient, no drop shadow. Export at 48×48, 72×72, 96×96, 144×144, 192×192.
- **Acceptance:** legacy Android (API 25-) emulator shows the icon rendered as a rounded square without any clipping; passes Play Store icon scan.
- **TODO:** replace the legacy PNGs when the real adaptive icon lands so the two stay visually aligned.

---

## 4. Play Store high-res icon

- **Filename / target path:** `assets/play_store_icon_512.png` (already exists; replace in place).
- **Dimensions & format:** 512 × 512 PNG, 24-bit, no alpha (Google Play requirement).
- **Palette:** primary `#4059AD` backdrop, white fuel drop inside a white shield outline. (The Play Store listing is the first impression; use the full brand primary here, not the interim privacy green — Play Store assets and launcher icons don't need to match.)
- **Composition:** Centered glyph on full-bleed color backdrop. Glyph height = 56% of canvas. No rounded corners (Google Play rounds on render).
- **Symbolism:** same as § 1.
- **Style constraints:** 24-bit, **no alpha channel**, no drop shadow, no text, no outer stroke, no gradient.
- **Generator prompt:**
  > Flat app icon for Google Play Store, 512×512 PNG, 24-bit, no alpha. Solid background `#4059AD`. Centered composition: white fuel drop (teardrop) nested inside a white shield outline, stroke-only, 12px stroke width. Drop vertically centered inside the shield, 55% of the shield's height. Glyph height = 56% of canvas. Pictogram style, 2-color palette (white on `#4059AD`), no text, no gradient, no drop shadow, no background texture. Export as PNG without alpha.
- **Acceptance:** passes Play Console upload validation (no alpha); renders crisply when Play rounds it to a squircle.

---

## 5. Play Store feature graphic

- **Filename / target path:** `assets/feature_graphic.png` (already exists; replace in place).
- **Dimensions & format:** 1024 × 500 PNG, 24-bit, no alpha.
- **Palette:** primary `#4059AD` gradient (top-left to bottom-right, 100% → 80%) with the drop-in-shield glyph at left ~240px from edge, white, glyph height 360px. Right side: app wordmark "Tankstellen" in Roboto Bold 96px white, subtitle "Smarter pump. Smarter drive." Roboto Regular 32px with 70% white.
- **Composition:** glyph left-anchored, text right-anchored, 48px outer safe margin (Play may overlay a "Play" button at the center — keep the midline clean).
- **Symbolism:** glyph + slogan communicate the dual savings lenses (pump + drive).
- **Style constraints:** 24-bit no alpha; Roboto or system-fallback typeface; no drop shadow.
- **Generator prompt:**
  > Google Play feature graphic, 1024×500 PNG, no alpha. Background: subtle diagonal gradient from `#4059AD` (top-left) to `#32498F` (bottom-right). Left 40%: centered white fuel-drop-inside-shield glyph (stroke-only shield, 14px stroke), 360px tall, vertically centered, 240px from the left edge. Right 60%: two lines of white text. Line 1: "Tankstellen" in Roboto Bold 96px, left-aligned. Line 2 below with 16px gap: "Smarter pump. Smarter drive." in Roboto Regular 32px at 70% white. 48px safe margin on all edges. Keep the horizontal midline between x=380 and x=640 free of critical content (Play Store overlays a Play button there).
- **Acceptance:** Play Console accepts without a validation warning; text is legible on a 1024×500 preview and readable when cropped to 16:9 for carousels.

---

## 6. Notification icon

- **Filename / target path:** `android/app/src/main/res/drawable/ic_notification.xml` (vector; committed placeholder).
- **Dimensions & format:** 24dp × 24dp Android vector drawable.
- **Palette:** white only (`#FFFFFF`). Android tints notification icons via the system accent — never embed color.
- **Composition:** shield outline + fuel drop, same silhouette as § 1 but drawn stroke-only at 1.4dp so the form reads against the status bar.
- **Symbolism:** same as § 1.
- **Style constraints:** single color white; no gradient; no anti-alias hacks. Android strips non-white pixels and tints the result against `notification.color`.
- **Generator prompt:**
  > 24dp Android notification icon as a vector drawable. White silhouette (`#FFFFFF`) only — no other colors. Subject: a shield outline (stroke-only, 1.4dp stroke) containing a fuel drop (filled) vertically centered inside. Pictogram style, no text, transparent background. Export as Android Vector Drawable XML targeting viewportWidth=24, viewportHeight=24.
- **Acceptance:** Android status bar renders the icon with the system accent tint; no color bleed; no visible background; readable at 24dp against both light and dark status bar.

---

## 7. Splash screen

- **Filename / target path:** `android/app/src/main/res/drawable/launch_background.xml` (and `drawable-v21/launch_background.xml`) today. If the project adds `flutter_native_splash` later, the target becomes the `flutter_native_splash:` section in `pubspec.yaml` + generated platform assets.
- **Dimensions & format:** Android window background layer-list; vector glyph rendered at 192dp × 192dp centered on a solid color backdrop.
- **Palette:** backdrop = `@color/ic_launcher_background` (`#2E7D32` today, `#4059AD` post-migration). Glyph = white, sourced from `@drawable/ic_launcher_foreground`.
- **Composition:** color fill first, then a gravity-center vector at 192dp on every device.
- **Symbolism:** continuity with the launcher icon press — tapping the icon visually flows into the splash.
- **Style constraints:** no text on the splash (Google's recommendation); no progress spinner; no animation; exactly one glyph centered.
- **Migration to flutter_native_splash (post-placeholder):**
  1. Add `flutter_native_splash: ^2.4.0` to `dev_dependencies` in `pubspec.yaml`.
  2. Add config:
     ```yaml
     flutter_native_splash:
       color: "#2E7D32"
       color_dark: "#0E2A5A"
       image: assets/icon_foreground.png
       image_dark: assets/icon_foreground.png
       android_12:
         color: "#2E7D32"
         image: assets/icon_foreground.png
     ```
  3. Run `dart run flutter_native_splash:create` on a machine with the Android toolchain available.
  4. Commit the generated platform files.
- **Generator prompt for the splash glyph (if separate asset is required):**
  > 192dp square vector drawable: white fuel drop inside white shield outline, stroke-only shield (4dp stroke), drop filled. Centered; transparent background. Same glyph as the Android adaptive icon foreground.
- **Acceptance:** cold-start Flash shows the green (or primary) backdrop + centered white glyph; no white/black frame before or after; transition into the first Flutter frame is seamless.

---

## 8. Onboarding illustration 1 — globe

- **Filename / target path:** `lib/features/setup/presentation/widgets/illustrations/globe_illustration.dart` (widget). No binary asset — the illustration is composed at runtime from Material icons + a radial gradient.
- **Dimensions & format:** 200dp × 200dp (default); the widget accepts a `size` override.
- **Palette:** `theme.colorScheme.primary` for the globe + markers; `theme.colorScheme.surface` → `surfaceContainerLow` for the radial backdrop.
- **Composition:** soft circular radial-gradient backdrop; centered `Icons.public` at 60% size; three small `Icons.local_gas_station` markers arranged at roughly 10, 2, and 6 o'clock around the globe, each in a 14% circle with a 15%-alpha primary fill.
- **Symbolism:** "multi-country fuel-price coverage." Markers are abstract — no national flags, keeps the illustration equally relevant for any of the 11 live countries.
- **Style constraints:** flat; no drop shadow; no text; works in both light and dark mode (the radial gradient derives from theme `surface` colors).
- **Generator prompt (if a raster replacement is desired later):**
  > Flat vector illustration, 200×200 transparent PNG / SVG. Central globe icon in `#4059AD` (or dark-mode equivalent `#8FB2F5`), stylized like Material Symbols "public". Soft radial backdrop from `#F6F8FF` (center, 30% stop) to `#ECEFF8` (edge, 100% stop). Three small fuel-pump markers arranged around the globe at 10 o'clock, 2 o'clock, and 6 o'clock positions, each a filled circle (`#4059AD` at 15% alpha) containing a primary-colored fuel pump pictogram. Pictogram style, no text, no drop shadow.
- **Acceptance:** the `GlobeIllustration` widget test asserts the widget renders with `Icons.public` as a primary-colored `Icon`; contrast ≥ 4.5:1 in both light and dark mode against its backdrop.

---

## 9. Onboarding illustration 2 — fuel pump

- **Filename / target path:** `lib/features/setup/presentation/widgets/illustrations/fuel_pump_illustration.dart` (widget).
- **Dimensions & format:** 200dp × 200dp (default); `size` override available.
- **Palette:** `theme.colorScheme.primary` for the pump + sparkline; `theme.colorScheme.surfaceContainerLow` for the ticker backdrop.
- **Composition:** centered `Icons.local_gas_station` at 65% canvas size, offset 18% upward so a horizontal "price ticker" rounded rectangle fits below it. Ticker contains a short polyline sparkline (descending, 6 segments) rendered by a `CustomPaint`.
- **Symbolism:** pump = the product, sparkline = "prices going down" (the pump lens of the product leitmotiv).
- **Style constraints:** flat; sparkline stroke 2.5dp with rounded caps; no drop shadow; no literal numerals.
- **Generator prompt:**
  > Flat vector illustration, 200×200 transparent PNG / SVG. Central fuel-pump pictogram in `#4059AD`, stylized like Material Symbols "local_gas_station", occupying 65% of canvas, vertically offset upward by 18%. Below the pump: a rounded rectangle "price ticker" (80% of canvas width, 22% canvas height, 28% corner radius, fill `#ECEFF8`, border `#4059AD` at 20% alpha). Inside the ticker: a descending 6-segment sparkline polyline in `#4059AD`, 2.5px stroke, rounded caps. Pictogram style, no text, no drop shadow, transparent background.
- **Acceptance:** widget test renders `Icons.local_gas_station` as a primary-colored `Icon`; sparkline renders without error; contrast ≥ 4.5:1 in light and dark mode.

---

## 10. Onboarding illustration 3 — shield / privacy

- **Filename / target path:** `lib/features/setup/presentation/widgets/illustrations/shield_illustration.dart` (widget).
- **Dimensions & format:** 200dp × 200dp (default); `size` override available.
- **Palette:** `theme.colorScheme.primary` for the shield; `theme.colorScheme.onPrimary` for the inset fuel drop; `surface` → `surfaceContainerLow` for the radial backdrop.
- **Composition:** soft circular radial-gradient backdrop; centered `Icons.verified_user` (shield with checkmark) at 72% canvas size in primary; a `Icons.water_drop` nested inside at 26% canvas size in `onPrimary`, positioned at the shield's center.
- **Symbolism:** shield = privacy (the no-Google, no-Firebase promise). Drop inside the shield = "your fuel data is protected." Exact same motif as the app icon — reinforces the brand at the last step of onboarding.
- **Style constraints:** flat; no drop shadow; no text; works in both light and dark mode.
- **Generator prompt:**
  > Flat vector illustration, 200×200 transparent PNG / SVG. Soft radial backdrop from `#F6F8FF` (center) to `#ECEFF8` (edge). Centered: a shield pictogram in `#4059AD` (stylized like Material Symbols "verified_user", filled, occupying 72% of canvas). Nested inside the shield, slightly above geometric center: a white (`#FFFFFF`) fuel-drop pictogram, 26% canvas size. Pictogram style, no text, no drop shadow.
- **Acceptance:** widget test renders `Icons.verified_user` as a primary-colored `Icon` and `Icons.water_drop` as an `onPrimary` `Icon`; contrast ratios ≥ 4.5:1 in both modes.

---

## Assets directory map (repo → final path)

| Asset | Repo path (placeholder today) | Production target |
| --- | --- | --- |
| Adaptive icon foreground (vector) | `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | replace with generator-produced vector OR per-density PNGs |
| Adaptive icon background | `android/app/src/main/res/values/colors.xml` (`ic_launcher_background`) | update hex only |
| Legacy launcher PNGs | `android/app/src/main/res/mipmap-*/ic_launcher.png` | replace with 48/72/96/144/192 PNGs |
| Play Store icon | `assets/play_store_icon_512.png` | overwrite (512×512 PNG, no alpha) |
| Play Store feature graphic | `assets/feature_graphic.png` | overwrite (1024×500 PNG, no alpha) |
| Notification icon | `android/app/src/main/res/drawable/ic_notification.xml` | overwrite vector |
| Splash backdrop + glyph | `android/app/src/main/res/drawable*/launch_background.xml` | re-render or migrate to flutter_native_splash |
| Onboarding globe | `lib/features/setup/presentation/widgets/illustrations/globe_illustration.dart` | keep widget; replace with raster only if the Flutter version proves insufficient |
| Onboarding fuel pump | `lib/features/setup/presentation/widgets/illustrations/fuel_pump_illustration.dart` | keep widget (see above) |
| Onboarding shield | `lib/features/setup/presentation/widgets/illustrations/shield_illustration.dart` | keep widget (see above) |
| App icon (Flutter-rendered SVG) | `assets/icon.svg`, `assets/icon_foreground.svg` | overwrite with new drop-in-shield SVG once generated |
| flutter_launcher_icons source | `assets/icon.png`, `assets/icon_foreground.png` | 1024×1024 PNG regenerated from the new SVG |
