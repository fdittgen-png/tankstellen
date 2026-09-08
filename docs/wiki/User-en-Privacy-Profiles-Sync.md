# Privacy, Data & Sync

Sparkilo's privacy claims are checkable, and this page is where you check them.

---

## Privacy by default

Concretely:

- **No Google Play Services. No Firebase. No Google Analytics. No advertising identifiers.**
- **No third-party tracking SDKs** — `pubspec.yaml` in the public source has zero analytics dependencies.
- **No account required.** The app is fully functional without one.
- **Local-first.** Everything lives on your phone unless you switch something on.
- **Consent before processing**, plus a plain-language explanation *before* each system permission prompt.
- **Open source, MIT.** The project's own tests fail if the privacy policy and the code drift apart.

### What actually leaves the phone

| Data | To whom | When | Avoidable? |
|---|---|---|---|
| Search coordinates or a region code | Your country's official price provider | Every live search | Search by postal code instead of GPS |
| Map viewport + IP | The developer's EU tile proxy, which fetches from OpenStreetMap | Map use | Turn the proxy off — OpenStreetMap then sees your IP directly |
| Your IP | logo.clearbit.com | Only if you enable internet brand logos | Leave it off (default) |
| Sanitised crash traces | Sentry | Only with *Error Reporting* on | Off by default |
| Your synced rows | Your chosen TankSync database | Only with TankSync on | Off by default |

**Your identity is never part of a price query**, and the developer runs no server that stores your searches.

---

## Who is the data controller

It depends entirely on how you use TankSync:

| Mode | Controller |
|---|---|
| **No TankSync** *(default)* | **Only you.** Nothing sits on any server the developer operates |
| **Your own Supabase project** | **You** — the developer never sees it |
| **A group's database** | **The group owner** who runs that project |
| **Sparkilo Community** | **The developer, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)); Supabase, Inc. is the processor; hosted in the EU (AWS eu-central-1, Frankfurt) |

The app states which case applies **before** you connect, and again as the *Sync mode* row of **Sync & account**.

---

## The Privacy & data screen

**Settings → Privacy & data** is the single entry point. It opens on a summary card followed by four topic tiles:

| Line or tile | What it tells you |
|---|---|
| *Your data stays on this device* / *Your data is also synced to TankSync* | Where your data physically lives right now |
| *Sync: off* / *Sync: on · anonymous account* / *Sync: on · email account* | Whether TankSync is connected, and with which kind of account |
| *… stored on this device* | The total storage the app currently uses |
| **Your choices** — *n of 5 enabled* | The five consents and the two network controls |
| **Data on this device** — *size · n categories* | Every category held locally, with size and count |
| **Sync & account** | TankSync status, account, database and the sync actions |
| **Export or delete** — *ZIP, JSON, CSV · error log (n)* | The exports, the error log and the danger zone |

The former *Privacy Dashboard* no longer exists: its counters, sync facts, exports and delete button now live under these four topics. Old links and home-screen widgets that pointed at the dashboard open **Privacy & data** instead.

---

## Your choices

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Privacy controls: map-tile proxy and brand-logo loading">

*The two network-shaped controls, each stated as what it actually leaks. The five consents sit above them on the same card.*

Every row is a switch — *"You can change your privacy choices at any time."*

| Row | What it decides |
|---|---|
| **Location Access** | Find nearby fuel stations using your location. Off: search by postal code |
| **Error Reporting** | Send anonymous crash reports to improve the app. Off by default — nothing is ever uploaded without it |
| **Cloud Sync** | Sync favorites and alerts across devices — the consent behind TankSync |
| **VIN online decode** | Decode the VIN via NHTSA's free public service. Off: type the vehicle data yourself |
| **Sync trip recordings** | Back up OBD2 + GPS trips to TankSync. Greyed out until *Cloud Sync* is on |
| **Route map tiles through the Sparkilo proxy** | On: the map viewport and your IP address reach the developer's EU server, which fetches the tiles from OpenStreetMap. Off: tiles load from tile.openstreetmap.org directly, which then sees your IP instead |
| **Load brand logos from the internet** | Off by default: bundled placeholders are shown. On: logos are fetched from logo.clearbit.com, which sees your IP address |

The two network controls carry an info button (*Learn more*) with the full explanation. The footer records *Consent given on … · policy version …* — the audit trail the GDPR asks for — and links to the **Privacy policy** in your language. Withdrawing a consent stops that processing immediately; earlier processing remains lawful.

---

## Data on this device

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Storage usage broken down by category with sizes">

*Storage, itemised: a bar by category, then one row per category with its size, its count and a dot in the bar's colour. Empty categories are greyed, not hidden.*

The rows under **Storage usage on this device**: **Favorites** · **Station ratings** · **Search profiles** · **Price Alerts** · **Price history stations** · **Ignored stations** · **Blocked users** · **Saved routes** · **Cache** · **Settings** (*API key, active profile*) · **Total**.

Everything sits in **encrypted Hive databases**; the key is in the Android Keystore / iOS Keychain.

| Box | Contents |
|---|---|
| `settings` | Configuration, country, language, units |
| `profiles` | Your search profiles |
| `favorites` | Saved stations with their full data |
| `cache` | Cached API responses and itineraries |
| `priceHistory` | The local 30-day price records |
| `price_snapshots` | Snapshots used offline and by the widget |
| `alerts` | Your alert rules |
| `service_reminders` | Service reminders |
| `obd2Baselines` | Per-vehicle consumption baselines |
| `obd2TripHistory` | Trips: route, speed, sensors |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Adapter capability caches |

API keys, the GitHub token and the TankSync session live in the hardware-backed vault, not in Hive.

### Cache details

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Cache TTLs per category and the clear-cache action">

*The **Cache details** tile expands to the lifetime of each cached class — searches 5 min, station details 15 min, price queries 5 min, favourites data 30 min, city lookups 30 min, postal-code geocoding 24 h — and the **Clear cache** button.*

The cache stores API responses for faster loading and offline access. Clearing it deletes cached results and prices only — profiles, favourites and settings are untouched; the next few searches are slower, nothing is lost. The button reads *Cache is empty* and is disabled when there is nothing to clear.

### Blocked users

**Blocked users** is the only tappable row: it opens the list of accounts you blocked, each with an **Unblock** button. Content shared by these users is hidden on this device; blocking is local — it does not report the account.

---

## Permissions

| Permission | Why | Refusable? |
|---|---|---|
| **Location** *(while in use)* | Nearby search, route start, trip recording | Yes — use a postal code |
| **Location** *("Allow all the time")* | **Only** OBD2 auto-record, so the route keeps recording with the screen off | Yes — start trips manually |
| **Bluetooth Scan + Connect** | Adapter pairing | Yes — OBD2 is optional |
| **Notifications** | Price alerts | Yes — alerts won't fire |
| **Camera** | On-device OCR of pump displays, receipts and QR codes | Yes — type manually |
| **Internet** | Price and map calls | Required |

On Android 11 and below the OS demands **Location** for any Bluetooth scan — that is a platform rule, not a tracking decision. Revoke any permission later in your device settings; the matching feature simply stops.

---

## Sync & account

<img src="guide/sync-and-account.jpg" width="340" alt="Sync &amp; account with the TankSync status, a schema-outdated warning and the Consents entry">

*Reachable from the Privacy & data tile and directly from the Settings root. The screen also surfaces problems — here a self-hosted schema that is out of date and therefore silently failing to sync some tables.*

Opt-in. *Disabled* means nothing is stored on any server, anywhere. The overview card at the top states the facts:

| Row | Value |
|---|---|
| **Status** | *Connected* or *Disabled* |
| **Sync mode** | *Sparkilo Community — the developer's EU server* · *Shared group — a database you joined* · *Self-hosted — your own Supabase* |
| **Account** | *Anonymous account, tied to this device* or *Email account: …* |
| **User ID** | Your UUID, with a copy button — quote it in a support request |
| **Database host** | The host name of the database you sync to; the key is never shown |
| **Share learned vehicle profiles** | Upload per-vehicle consumption baselines so a second device can reuse them |

### Three deployment shapes

1. **Sparkilo Community** — the shared database the developer runs (Supabase, EU/Frankfurt). Your account is a random UUID; you may link an e-mail so you can reach it from another device. Community price reports and publicly shared ratings are readable by every signed-in user.
2. **Your own Supabase project** — the SQL schema and Edge Functions are in the repository. You are the controller and keep full ownership.
3. **A group's database** — connect to a project run by family or friends. That person is the controller.

### Setting it up

**Sync & account → Set up cloud sync.** For Community, scan the QR from the wiki or paste the URL and anon key; for your own or a group's project, paste the project URL and anon key. Both are stored in the hardware-backed vault, and plain-HTTP endpoints are refused outright.

> **Self-hosters:** after an app update the screen may warn that your **schema is outdated**. Re-run the setup SQL it offers — otherwise the newer tables fail to sync **silently**, which is far worse than a visible error.

### Actions once connected

- **Switch to email** — keep data, add sign-in from other devices; the UUID stays the same. **Switch to anonymous** does the reverse.
- **Consents** — a cross-link to *Your choices*: the Cloud Sync and trip-sync consents live there, not here.
- **View my data** — the *Data transparency* screen lists the rows the server holds for you; its **Forget all synced trips** button scrubs only the trip rows.
- **Link device** — bring a second phone onto the same account.
- **Delete synced data** — pick *Trips*, *Vehicles*, *Fill-ups* or *Everything* to remove from the sync database; local copies stay.
- **Share database** — a QR code so family or friends can join your own or a group's database (not offered on Community).
- **Disconnect** — stop syncing; local data is kept.
- **Delete account** — remove all server data permanently, then the account identity itself, including any linked e-mail. Offered for your own and group databases; on Community use *Delete synced data → Everything* or the danger zone described below.

### What syncs

Favourites · price alerts · ignored stations · ratings (with a per-rating privacy flag: local / private-synced / publicly shared) · itineraries · vehicles including VIN and adapter identifier · fill-ups and charging logs · consumption baselines · community and content reports you submit.

**Trips are separate.** Trip sync is opt-in *even after* Cloud Sync is on — the *Sync trip recordings* switch stays greyed until then. On the server, trip summaries stay until you delete them; the detailed GPS samples are pruned after 90 days.

Every table is protected by row-level security: an account can only read or delete its own rows. Shared ratings and community price reports are the only rows other signed-in users can see.

### Conflicts

**Local always wins.** Sync adds and updates but never silently deletes — only your explicit delete triggers a server delete, which then propagates to your other devices.

---

## Export or delete

One button, one format sheet, one red zone. **Export my data** opens *Choose a format*:

| Format | Hint in the sheet | What you get |
|---|---|---|
| **ZIP archive** | *Everything, attachments included — for a complete backup* | `sparkilo-my-data-<date>.zip`: one machine-readable JSON per category — favourites, alerts, profiles, routes, price history, vehicles, fill-ups, trips with GPS samples plus a GPX per trip, baselines, service reminders, charging logs, achievements and your consent record — plus every server table when TankSync is connected |
| **JSON** | *Machine-readable — for another app* | `tankstellen-data.json`: the on-device categories in one flat file, also copied to the clipboard |
| **CSV** | *Spreadsheet — one table per category* | `tankstellen-data.csv`: one `# table` block per category — favourites, alerts, price history and the rest — also copied to the clipboard |

All exports land in your **public Downloads** folder (*Saved to your Downloads folder*), so any file manager can pick them up.

**Error log** shows how many sanitised traces the app holds (*No entries* … *n entries*). **Save** writes them to Downloads for a bug report — no e-mails, coordinates, keys or tokens inside, and nothing is ever uploaded automatically; **Clear** empties the log.

**Danger zone** — *Permanently deletes everything the app stores on this device. With sync on, your data on the TankSync server is erased too.* **Delete all my data** asks for confirmation and lists what goes: favourites and station data, search profiles, price alerts, price history, cached data, your API key, all app settings. With TankSync connected it erases your server rows first; if a table could not be erased, the app **tells you which one** instead of claiming success. The app then returns to first-launch setup. Irreversible.

For a restorable snapshot rather than a data export, use **Settings → Backup & restore** — see [Settings Reference](User-en-Settings-Reference#backup--restore).

---

## Your rights under the GDPR

Every right in Articles 15–22 has a button. No support request needed.

- **Access** — *Data on this device* lists every category on the device; *View my data* lists every row in your TankSync database.
- **Portability** — *Export my data* as a ZIP archive.
- **Rectification** — edit any entry in place; the change syncs if TankSync is on.
- **Erasure**
  - *Device:* **Export or delete → Delete all my data**.
  - *Server:* **Sync & account → Delete account** erases every row you own **in one transaction** — favourites, alerts, ignored stations, price and content reports, vehicles, fill-ups, itineraries, baselines, ratings, trips, trip shares given and received, sync settings, deletion records and your user row — then the account identity itself, including any linked e-mail. If a table could not be erased, the app **tells you which one** instead of claiming success.
  - *Individual items:* everything is individually deletable; **Delete synced data** removes trips, vehicles or fill-ups from the server, and **Forget all synced trips** scrubs only the trip rows.
- **Withdraw consent** — Privacy & data → Your choices; processing stops immediately.
- **Restriction / objection** — switch off TankSync, trip sync, the tile proxy or diagnostics; revoke permissions in your device settings.
- **Complain** — to a supervisory authority, in particular in your country of residence, workplace or of the alleged infringement. The developer would appreciate a chance to fix it first: [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

If you can no longer open the app, request deletion by e-mail from the address linked to your account. **An anonymous account never linked to an e-mail cannot be identified by anyone — including the developer — without the device that created it.** That is the price of not asking you to register.

Full text: **[Privacy policy v3, 29 August 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**, available in all 23 app languages ([Deutsch](https://fdittgen-png.github.io/tankstellen/privacy-policy/de/), [Français](https://fdittgen-png.github.io/tankstellen/privacy-policy/fr/), …). The app records which version you consented to and shows the policy again whenever it changes.

---

**See also:** [Settings Reference](User-en-Settings-Reference) · [How Sparkilo Works → Where your data lives](User-en-How-It-Works#where-your-data-lives)
**Next:** [Troubleshooting & FAQ →](User-en-Troubleshooting-FAQ)
