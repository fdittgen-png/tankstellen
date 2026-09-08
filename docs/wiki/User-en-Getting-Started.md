# Getting Started

Ten minutes from install to your first saved euro. If you only read one other page afterwards, make it [How Sparkilo Works](User-en-How-It-Works).

---

## 1. Install

### Google Play (Android)

Install from the **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — the public production release.

> **Coming from the beta?** Play keeps serving beta builds once you have joined Open Testing (the listing shows a *(beta)* tag). To move to production: open the [Play listing](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Leave the programme** → uninstall → reinstall.
>
> **Want features first?** Stay in the beta instead — every build reaches the beta channel before production.

### F-Droid (Android, Google-free)

A fully **GMS-free** build ships through its own F-Droid repository (OpenStreetMap maps, no Google services). In F-Droid open **Settings → Repositories → +** and add:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Then search for **Sparkilo**. If the Play build is installed, uninstall it first — different signing key, so it cannot update over it.

### Other ways

- **APK** — from [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — TestFlight beta; request an invite via [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) until the App Store listing is live.

**Minimum Android** 7.0 (API 24), target Android 15. **Minimum iOS** 15.5, target iOS 18.

No account, no sign-up, no e-mail. The app is fully usable the moment it finishes installing.

---

## 2. First launch — consent

Before any other screen, the app shows a **GDPR consent screen**. It is not a cookie banner: it lists each processing purpose, and the app proceeds only when you accept.

<img src="screenshots/privacy-consent.png" width="340" alt="First-launch consent screen listing each processing purpose">

*Every consent shown here is listed again later in Settings → Privacy & data, with the date you gave it and the policy version you saw.*

| Item | Why | If you decline |
|---|---|---|
| **Location** *(while in use)* | Nearby search, route start, trip recording | Search by postal code or pick a point on the map |
| **Notifications** | Price alerts only | Alerts never fire |
| **Diagnostics** | Crash traces to Sentry — **off by default** | Nothing is sent; you can still save the error log yourself |

Before each *system* permission prompt (camera, Bluetooth, notifications) the app shows its own short explanation first, so you know what you are agreeing to before Android asks.

Full text: **[Privacy policy v3, 29 August 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. Country, language and your home area

Both are auto-detected from your system locale, and both live **inside your profile** — see [How Sparkilo Works → Profiles](User-en-How-It-Works#profiles-one-context-one-set-of-defaults).

<img src="guide/profile-edit-6.jpg" width="340" alt="Language picker and home postal code inside the profile editor">

*Settings → Profiles & region → edit your profile. The home postal code lets you search a fixed area without ever handing over GPS.*

Changing the country **clears cached station data**, because prices from the previous country's provider don't apply to the new one. Expect the next search to take a moment longer.

---

## 4. Pick a use mode

This is the single most consequential setting, because it decides how much app you get.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Use-mode presets: Basic, Medium, Full, Custom">

*Settings → Features & use mode. Start on **Basic** if you only want cheaper fuel; move up when you want to know why your car drinks.*

- **Basic** — find cheap fuel and charging, favourites, alerts, routes.
- **Medium** — adds the **Fuel** tab: log fill-ups, see real consumption and cost. No hardware needed.
- **Full** — adds the **Trips** tab: automatic recording, driving scores, loyalty cards. An OBD2 adapter is optional even here — trips record on GPS alone.

You can move between presets any time, and any individual switch you flip afterwards puts you on **Custom**. The full list of switches, and what each one costs you in battery, data or privacy, is in [Settings Reference → Features & use mode](User-en-Settings-Reference#features--use-mode).

---

## 5. Germany only: the free API key

16 of the 17 countries work instantly. **Germany's** official price service issues a per-user key.

<img src="guide/data-sources-location.jpg" width="340" alt="Data sources screen with the Tankerkönig and OpenChargeMap key slots">

*Settings → Data sources & location. A red cross here is the reason a German search returns nothing.*

1. Open [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/), request a key (short form, free).
2. Copy it — it is a UUID like `00000000-0000-0000-0000-000000000002`.
3. Paste it into the **Fuel prices (Tankerkoenig)** slot.

The key is kept in the hardware-backed vault (Android Keystore / iOS Keychain) and is only ever sent to the German price service. The **EV charging** slot below already carries a shared built-in key, so charging data works without any setup.

---

## 6. The bottom bar

<img src="guide/favorites.jpg" width="340" alt="Favourites tab with the bottom bar and the raised central Search button">

*The raised green **Search** button in the middle notch is the only search trigger in the entire app.*

- ⭐ **Favourites** — saved stations and your price alerts
- 🗺️ **Map** — every nearby station as a price-coloured pin
- 🔍 **Search** *(centre)* — nearby or along a route
- ⛽ **Fuel** — tank, consumption, fill-ups *(Medium and up)*
- 🛣️ **Trips** — logbook and coaching *(Full)*

Settings is **not** a tab: it is the gear icon in the top-right of the main screens. On a tablet, or a phone held sideways, the app splits into two columns so a list and the map (or a detail) are visible at once.

---

## 7. Your first search

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Search criteria sheet for a nearby search">

*Tap **Search** → the criteria sheet opens pre-filled from your profile. Adjust, then tap **Search** again to run it.*

You get a list sorted cheapest-first (or by distance — your choice), each card showing price, trend, distance and how fresh the number is. Tap any card for the full station detail. The complete tour is in [Finding Stations](User-en-Finding-Stations).

**Tip:** tap **Save as defaults** at the bottom of the sheet once you have the criteria you use most — every future search starts there.

---

## 8. Two settings worth changing on day one

<img src="guide/units-and-display-1.jpg" width="340" alt="Units and display with theme, distance unit and consumption unit">

*Settings → Units & display. **Consumption unit** is *Automatic* by default (mpg in the UK, L/100 km elsewhere); pick L/100 km, km/L or mpg explicitly if you prefer.*

The second is **Settings → Driving & consumption → Live consumption window** (3 / 5 / 10 / 30 s). It controls the big live figure on the recording screen: a longer window is steadier to read while driving, a shorter one reacts faster to your right foot.

---

## 9. Choose what the app opens on

**Settings → Profiles & region → Start screen**: *Nearby* (instant search with your last criteria), *Nearest station*, *Favourites*, or *Map*. Pick the one that matches why you open the app.

---

## 10. Where everything lives

Settings is a two-level tree with a keyword search at the top — type "radius", "OBD2" or "theme" and the matching tile surfaces.

<img src="guide/settings-root-1.jpg" width="340" alt="Settings root: topic tiles with a search field">

*Twelve topics, one home per parameter. The full map is [Settings Reference](User-en-Settings-Reference).*

---

**Next:** [How Sparkilo Works →](User-en-How-It-Works)
