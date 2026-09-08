# Settings Reference

Every screen of the settings tree, and — more usefully — **what each switch costs you** in battery, data, accuracy or privacy.

---

## The shape of it

Settings is a **two-level tree**: a root of topic tiles, one screen per topic, and a keyword search across all of them.

<img src="guide/settings-root-1.jpg" width="340" alt="Settings root, upper half: search field and the first six topic tiles">

*Type "radius", "OBD2" or "theme" into the search field and the matching tile surfaces — you never need to remember which topic owns a parameter.*

<img src="guide/settings-root-2.jpg" width="340" alt="Settings root, lower half: features, data sources, sync, privacy, backup, advanced">

*Twelve topics in total. Reaching Settings: the gear icon in the top-right of the main screens.*

Three design rules make the tree predictable:

1. **One home per parameter.** Nothing appears in two places; cross-links point at the single owner.
2. **Scope labels.** A tile marked *this profile*, *all profiles* or *this vehicle* tells you how far a change reaches before you make it.
3. **Honest empty states.** A section whose feature is off says so and links to the switch, instead of hiding.

---

## Profiles & region

*Country, language, fuel, search radius, route planning · scope: this profile*

<img src="guide/profile-edit-1.jpg" width="340" alt="Profile editor: name, preferred fuel, default radius">

*The preferred fuel is derived from the default vehicle. To choose a fuel directly, remove the vehicle from the profile.*

| Setting | Impact |
|---|---|
| **Profile name** | Cosmetic, but it is what the profile chip shows |
| **Preferred fuel** | The headline price on every card; the default for alerts; what route search optimises |
| **Default radius** | Larger = more results and slower searches |

<img src="guide/profile-edit-2.jpg" width="340" alt="Route planning: segment, max detour, minimum saving, per-segment choice, candidates">

*Route planning defaults. **Candidates per sampling point** trades thoroughness for speed on long corridors.*

<img src="guide/profile-edit-3.jpg" width="340" alt="Display &amp; stations, station notes visibility, start screen, approach overlay radius">

*Three separate things worth knowing.*

- **Avoid motorways** changes the computed route itself, so motorway service stations stop being candidates at all — usually a saving, since motorway fuel is the dearest on any corridor.
- **Station notes** — *Local* (this device only), *Private* (synced to your own account) or *Shared* (visible to other users). This is a privacy choice, not a storage one.
- **Start screen** — what the app opens on: Nearby, Nearest station, Favourites or Map.

<img src="guide/profile-edit-4.jpg" width="340" alt="Station approach overlay radius and price mode, default vehicle, region">

*The approach overlay's radius and its **nearest vs cheapest-in-radius** rule live in the profile, so a commuting profile and a holiday profile can behave differently.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Region: country chips and language chips">

*Country decides the data provider. Changing it clears cached station data.*

<img src="guide/profile-edit-6.jpg" width="340" alt="Language chips and the home postal code field">

*A **home postal code** gives you area searches with no GPS involved at all — the cleanest way to use the app if you never want to share your location.*

---

## Vehicles & OBD2

*Your cars, tank size, adapter pairing · scope: this vehicle*

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Vehicles &amp; OBD2 hub">

*Adapters are paired per vehicle, so the adapter tile sends you into a vehicle rather than opening a global pairing screen.*

Full treatment — VIN, tank capacity, flex-fuel, calibration modes, baseline, auto-record thresholds, service reminders — is in [Vehicles & OBD2](User-en-Vehicles-And-OBD2).

---

## Driving & consumption

*Coaching, rewards, the radar, troubleshooting · scope: mixed*

<img src="guide/driving-and-consumption-1.jpg" width="340" alt="Live consumption window, approach overlay, my vehicles, coaching switches">

*The top two entries are the ones you will actually tune.*

| Setting | Impact |
|---|---|
| **Live consumption window** (3/5/10/30 s) | Longer is steadier and easier to read while driving; shorter reacts fast enough to teach you what the pedal costs |
| **Station approach overlay** | Radius, price mode, query floor and screen pinning for the active profile |
| **Real-time eco coaching** | Light haptic + on-screen cue on hard acceleration at cruising speed |
| **Spoken driving coaching** | The same advice read aloud — eyes stay on the road |
| **Glide-coach beta** | Haptic before a red light using OpenStreetMap signal positions. **Off by default — distraction risk**, and it needs network access |

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching, loyalty cards, achievements toggle, OBD2 debug logging">

*Rewards and troubleshooting.*

- **Loyalty cards** — per-litre discounts applied inside price comparisons, so a nominally dearer station can correctly rank cheaper for you.
- **Show achievements and scores** — off hides every badge, score and trophy app-wide. Nothing stops being measured; it stops being displayed.
- **OBD2 debug logging** — records every session (connection, handshake, data loss, reconnects) into an exportable XML log. **Off by default**: it writes continuously and is only worth enabling while chasing an adapter problem.

---

## Prices & alerts

*Alerts, voice announcements, history, community reports*

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Prices &amp; alerts: alerts entry, voice announcement hint, price features">

*The greyed voice-announcements block is an honest empty state: it names both switches you need and where they live.*

| Setting | Impact |
|---|---|
| **Price alerts** | Opens the alert list; the feature itself is a switch under Features & use mode |
| **Price history** | Local 30-day recording. Off = no charts, no "best time to fill" |
| **TFLite price prediction** | On-device model; features and predictions never leave the phone |
| **Community price reports** | Requires TankSync; your reports are visible to other signed-in users |
| **Scan payment QR** | Adds the QR reader to station details |

---

## Units & display

*Theme, distance unit, consumption unit, home-screen widget · scope: mixed*

<img src="guide/units-and-display-1.jpg" width="340" alt="Theme, distance unit and consumption unit">

*The **consumption unit** propagates everywhere at once — live banner, PiP tile, trip averages, statistics, widget.*

- **Distance unit** defaults to the active profile's country (km or miles).
- **Consumption unit**: *Automatic* (mpg in the UK and US, L/100 km elsewhere), or an explicit L/100 km, km/L or mpg.

<img src="guide/units-and-display-2.jpg" width="340" alt="Home-screen widget: colour scheme and content variant">

*Widget choices are stamped **this profile** and apply to every installed widget showing that profile, from the next refresh.*

**Content variant** — *current price only*, or *predictive: best time to fill up* (which needs the TFLite prediction feature).

---

## Features & use mode

*Presets and every individual switch*

<img src="guide/features-and-mode-1.jpg" width="340" alt="Use-mode presets Basic, Medium, Full and the Custom state">

*Picking a preset **overwrites** every individual switch. If you have a hand-tuned mix, stay on Custom.*

Dependencies are enforced, not hidden: a switch whose prerequisite is off stays disabled and says which prerequisite to enable.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Search &amp; map group: route planning, EV charging, show fuel, show charging, fuel calculator">

*Search & map — including whether fuel stations and charging points appear at all.*

<img src="guide/features-and-mode-3.jpg" width="340" alt="Prices &amp; alerts group: alerts, history, TFLite prediction, payment QR, community reports">

*Prices & alerts. Price history is the parent of the prediction beneath it.*

<img src="guide/features-and-mode-4.jpg" width="340" alt="Fuel Station Radar group with voice announcements and the master text-to-speech switch">

*The radar, its voice announcements, and the master **Spoken feedback** switch — with it off, the app never opens a speech engine at all.*

<img src="guide/features-and-mode-5.jpg" width="340" alt="Consumption group: mode selector plus analytics, gamification, haptic coach, glide-coach, GPS path, auto-record">

*The **Off / Fuel / Fuel + Trips** selector is the compact form of the whole consumption stack.*

| Switch | Impact |
|---|---|
| **Consumption analytics** | The analysis tab over fill-ups and trips |
| **Gamification** | Driving scores and earned badges |
| **Haptic eco-coach** | Real-time vibration feedback while driving |
| **Glide-coach** | Eco advice from OpenStreetMap traffic signals — needs network |
| **GPS trip path** | Stores the route points of every trip. Off = smaller database, no route maps |
| **Auto-record** | Starts a trip when the paired adapter connects to a moving vehicle |

<img src="guide/features-and-mode-6.jpg" width="340" alt="Experimental OEM PIDs, require OBD2, carbon dashboard, TankSync, baseline sync">

*Two switches here change data quality rather than the UI.*

- **Experimental OEM PIDs** — reads the exact tank level in litres via manufacturer-specific PIDs on compatible adapters. Better tank data where it works; harmless where it doesn't.
- **Require OBD2 for trip recording** — when **off**, trips record on GPS alone. Coaching is reduced (no instantaneous L/100 km, fewer engine signals) but nothing is blocked.
- **Baseline sync** — uploads per-vehicle consumption baselines so a second device can reuse them. Requires TankSync.

<img src="guide/features-and-mode-7.jpg" width="340" alt="Entry &amp; scanning: loyalty cards, receipt OCR, share receipt to import">

*Entry & scanning. Recognition is on-device; these switches only decide whether the shortcuts exist.*

<img src="guide/features-and-mode-8.jpg" width="340" alt="Developer &amp; experimental: GitHub PAT feedback, developer mode, startup trace">

*Developer & experimental — safe to leave off unless you are reporting bugs.*

---

## Data sources & location

*API keys, GPS, automatic profile switching*

<img src="guide/data-sources-location.jpg" width="340" alt="API key slots and the location block">

*A red cross on the fuel-price key is the usual reason a German search comes back empty.*

| Setting | Impact |
|---|---|
| **Fuel prices (Tankerkoenig)** | Required for Germany only. Free, per-user, stored in the hardware-backed vault |
| **EV charging (OpenChargeMap)** | Optional — replaces the shared built-in key with your own quota |
| **Automatic update** | Refreshes the GPS fix before each search. Off = faster searches, possibly from a stale position |
| **Automatic profile switching** | Switches profile when you cross a border, so the right provider and fuel are used automatically |

---

## Sync & account

<img src="guide/sync-and-account.jpg" width="340" alt="TankSync status, schema-outdated warning, switch to e-mail, consents, view my data">

*This screen also surfaces problems — here, a self-hosted TankSync schema that is out of date and therefore silently failing to sync some tables.*

Covered in full in [Privacy, Profiles & Sync → TankSync](User-en-Privacy-Profiles-Sync#tanksync-optional-cloud-sync). The essentials:

- **Sparkilo Community / your own database / a group's database** — three deployment shapes with three different data controllers.
- **Anonymous → e-mail** — *Switch to e-mail* keeps your existing data and account and adds a way to sign in from another device. An anonymous account exists only on the device that created it.
- **Schema outdated** — self-hosters must re-run the setup SQL after an app update, or newer tables fail to sync silently.

---

## Privacy & data

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Privacy controls: map-tile proxy and brand-logo loading">

*Two network-shaped privacy choices, each stated as what it actually leaks.*

- **Map tiles through the Sparkilo proxy** — *on*: the developer's EU server sees your map viewport and IP and fetches the tiles for you. *Off*: tiles come straight from tile.openstreetmap.org, which then sees your IP instead. Neither option is "no network"; pick who you would rather be seen by. The F-Droid build never uses the proxy.
- **Load brand logos from the internet** — *off* by default; generic bundled logos are used. On, logos come from logo.clearbit.com, which sees your IP.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Storage usage broken down by category with sizes">

*Storage, itemised. Cache is almost always the biggest slice and is the only one that is safe to drop.*

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Cache TTLs per category and the clear-cache action">

*Cache management, with the lifetime of each cached class stated: searches 5 min, station details 15 min, price queries 5 min, favourites data 30 min, city lookups 30 min, postal-code geocoding 24 h.*

<img src="guide/cache-clear-dialog.jpg" width="340" alt="Clear cache confirmation dialog">

*Clearing the cache deletes cached results and prices only — profiles, favourites and settings are untouched. The next few searches are slower; nothing is lost.*

---

## Backup & restore

<img src="guide/backup-restore.jpg" width="340" alt="Export backup and restore backup entries">

*A complete ZIP of vehicles, fill-ups, trips and charging logs.*

**Export backup** writes the ZIP to your Downloads folder. **Restore backup** offers *merge* or *replace* — merge keeps what is on the device and adds what is missing; replace wipes first. Use this before a phone change or a factory reset. TankSync is not a backup: it mirrors selected categories, not everything.

---

## Advanced & developer

<img src="guide/advanced-developer.jpg" width="340" alt="GitHub PAT token field and the developer tools entry">

*The GitHub token is optional — without it, failed-scan feedback is shared manually instead of filing an issue automatically.*

The **Developer tools** entry appears only when developer mode is on (Features & use mode → Developer & experimental).

<img src="guide/developer-tools-1.jpg" width="340" alt="Developer tools: error log, test notification, test alert pipeline, diagnostics, OCR tester, clear caches">

*The error log is the useful part for ordinary users: **Save error log** writes sanitised traces to Downloads to attach to a bug report.*

<img src="guide/developer-tools-2.jpg" width="340" alt="Copy diagnostics, export data-access trace, startup initialization trace waterfall">

*The startup trace is a waterfall of initialisation phases — how a slow launch gets diagnosed instead of guessed at.*

<img src="guide/developer-tools-3.jpg" width="340" alt="Test approach overlay and build info with version and channel">

***Test approach overlay** pushes a synthetic in-radius state for 30 s so you can verify the picture-in-picture price layout without driving anywhere.*

---

## About

<img src="guide/about-1.jpg" width="340" alt="About: app version and build number, author, licence, privacy policy, GitHub, bug report">

***Version and build number** — quote both in any bug report, and check them first when a fix "didn't work" (a store rollout may simply not have reached you yet).*

<img src="guide/about-2.jpg" width="340" alt="About: support links and data attributions">

*The app is free, open source and ad-free. Attribution for the price data and the map data is at the bottom, as the licences require.*

---

**See also:** [How Sparkilo Works](User-en-How-It-Works) · [Privacy, Profiles & Sync](User-en-Privacy-Profiles-Sync)
**Next:** [Privacy, Profiles & Sync →](User-en-Privacy-Profiles-Sync)
