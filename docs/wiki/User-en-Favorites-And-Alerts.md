# Favourites & Price Alerts

The ⭐ tab is your shortlist plus the robots that watch it for you.

---

## Favourites

<img src="guide/favorites.jpg" width="340" alt="Favourites tab with two saved stations, per-fuel prices and the alerts tab header">

*Two tabs at the top: **Favourites** and **Price alerts**. Each card carries all reported grades, not just your preferred one.*

Mark a station with the ★ on any result card or on its detail screen.

### What is actually stored

A favourite is not a bookmark — it is a **full local copy** of the station: identifier, address, amenities, accepted payments, opening hours and the last prices seen. That is why the tab still works with no network: you see the last-known prices, clearly marked by their freshness stamp.

### What this means in practice

- **Favourites work offline**; searches do not. Before a trip into poor coverage, open the tab once on Wi-Fi to refresh the cache.
- Prices refresh when you open the tab, not continuously.
- Favourites are one of the categories **TankSync** mirrors between your devices, if you turn it on.

### Sort and swipe

Sort by price (cheapest first, default), distance or alphabetically. **Swipe right** opens the station in your navigation app; **swipe left** removes it, with an undo snackbar.

### EV chargers

Charging points can be favourited too, and the card shows what an EV driver needs: per-connector **power in kW**, how many are **available right now**, and the **connector types**.

### Landscape and tablets

On landscape phones and any screen wider than 600 dp, favourites and alerts render **side by side** with a divider instead of behind a tab switcher. Both panes are visible at once, so there is no toggle in that layout.

---

## Price alerts

<img src="guide/price-alerts.jpg" width="340" alt="Price alerts screen: active/today/this week counters, station alerts and zone alerts sections">

*Three counters at the top — active rules, hits today, hits this week — then the two kinds of alert. The footer stamps the last background check.*

There are two kinds, and they answer different questions.

### Station alert — "tell me when *this* pump gets cheap"

Created from a station's detail page (the bell icon). Pick the fuel, set a threshold, save. Best for the station you already use: your commute stop, the supermarket forecourt near home.

### Zone alert — "tell me when *anywhere near here* gets cheap"

<img src="guide/price-alert-create.jpg" width="340" alt="Create a zone alert: label, fuel type, threshold, radius, check frequency, position or postal code">

*Settings → Prices & alerts → Price alerts → **Create a zone alert**.*

| Field | What it does |
|---|---|
| **Label** | Free text so a list of alerts stays readable ("Diesel near home") |
| **Fuel type** | One grade per alert — a station can have several alerts on it |
| **Threshold (€/L)** | Fires when any station in the zone drops **below** this |
| **Radius (km)** | The watched area around the centre point |
| **Check frequency** | How often the background task looks — see below |
| **Use my position / Pick on map / Postal code** | Three ways to set the centre; a postal code never touches GPS |

Best for "ping me whenever diesel drops below €1.60 anywhere within 5 km of home", when you don't care which forecourt wins.

---

## How the checking actually works

A background task, scheduled by the operating system, wakes up and:

1. Fetches live prices for the stations behind your alerts.
2. Compares each with its threshold.
3. Fires a **local notification** if any price is below. Tapping it opens that station.

The cadence is **every 30 minutes while charging, hourly otherwise**, and only when the phone has a network connection. Your per-alert *check frequency* is a ceiling within that: setting an alert to "once a day" makes the task skip it most of the time.

### What this means in practice

- **Alerts are best-effort, not real-time.** The OS decides when the task actually runs; aggressive battery savers delay or kill it. If timing matters, whitelist the app under Android's battery settings.
- **No GPS is used.** Alerts work on the stations' stored coordinates, so an alert around your home keeps working while you are 500 km away.
- **Battery cost is negligible** — a few KB per wake, inside an OS-managed slot, Doze-respecting. Well under 0.5 % a day.
- **A side effect worth knowing:** the same background check writes a price record into your local history. A station under an alert therefore builds its 30-day history in hours instead of weeks, which is what makes the *best time to fill* banner appear quickly. See [Price History](User-en-Price-History-And-Predictions#the-learning-phase).
- **If you switch notifications off at system level**, the in-app toggle cannot fire. Re-enable under Android Settings → Apps → Sparkilo → Notifications.

---

## Stats

The counters at the top of the alerts screen show how many rules are active and how often they have fired today and this week — a quick sanity check that the background task is really running. A row of zeros with several active alerts and a stale "last check" stamp is the classic symptom of a battery optimiser killing the task.

---

## Stopping alerts

Toggle an alert off to pause it without losing the rule, or swipe left to delete. Deleting the station from favourites does **not** delete its alerts.

---

**See also:** [Price History & Predictions](User-en-Price-History-And-Predictions) · [Settings Reference → Prices & alerts](User-en-Settings-Reference#prices--alerts)
**Next:** [EV Charging →](User-en-EV-Charging)
