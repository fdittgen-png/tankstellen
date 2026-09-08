# Troubleshooting & FAQ

Ordered roughly by how often each one actually happens.

---

## Before anything else: check your version

<img src="guide/about-1.jpg" width="340" alt="About screen showing version and build number">

*Settings → About. Quote **both** the version and the build number in any report.*

A large share of "it's still broken" reports are a store rollout that has not reached the device yet. If the build number is older than the release that contains the fix, there is nothing to debug.

---

## "No prices found"

1. **Check the country in your profile.** A German profile calls the German API; in France it will find nothing. Settings → Profiles & region → Region.
2. **Germany: is the API key set?** Settings → Data sources & location — a red cross on *Fuel prices (Tankerkoenig)* is the answer.
3. **Are you offline?** Live prices need a network call. Cached prices are still shown, flagged stale.
4. **Provider outage.** National open-data services do go down. Retry in a few minutes.
5. **Stale cache.** Pull to refresh, or tap the refresh icon.

---

## Germany: "API key missing" or "Invalid API key"

- Get a free key at [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/); it is a UUID.
- Paste it into **Settings → Data sources & location → Fuel prices (Tankerkoenig)**.
- Still failing? The key may be rate-limited. Keys are per user — never publish or share one.

---

## I can't find the search button

There is exactly one: the raised green button in the middle of the bottom bar. From any tab it opens the criteria sheet; inside the sheet, a second tap runs the search. If it looks greyed out you are in **route mode without a destination**.

---

## Location is "unknown" or GPS never fixes

- System location must be on, with **While in use** granted to the app.
- GPS does not fix indoors. Step outside, or set a **home postal code** in your profile and search by area instead.
- "Coarse location only" — enable precise location in the system permission screen.

---

## Routing is slow or fails

- OSRM is a free public service and is sometimes slow.
- A multi-country corridor **streams partial results**; the banner names the providers still answering, and you can tap a result before the rest arrive.
- Retry — the polyline is cached, so the second attempt is usually instant.

---

## OBD2 adapter won't connect

**Nothing found during the scan**

- Ignition must be **on** (accessory or run). Engine running is fine; ignition off is not.
- The adapter LED should be on and steady. Blinking or dark → re-seat it.
- Phone Bluetooth on.
- Android 12+: grant **Bluetooth Scan** and **Bluetooth Connect**.
- Android 11 and below: the OS requires **Location** to enumerate Bluetooth devices. That is a platform rule, not tracking.

**Found, but the connection fails**

- *"Unresponsive"* — cheap clone. Wait 30 s and retry; briefly starting the engine often helps.
- *"Protocol init failed"* — counterfeit ELM327 chip. Try another model; vLinker FS is the reliable cheap option.
- *"Permission denied"* — re-grant in system settings; some Android builds forget Bluetooth permissions after a reboot.

**Connects, then drops mid-drive**

Use **Reset connection** in the vehicle's adapter card — it re-runs the handshake without forgetting the pairing. If it keeps happening, turn on **Settings → Driving & consumption → OBD2 debug logging**, drive once, then export the XML log and attach it to an issue. Turn the logging back off afterwards.

**The odometer reads 0 or is wrong**

Your car may not expose PID A6. The app retries with PID 31 and manufacturer Mode 22. Some pre-2008 European cars expose no odometer at all over OBD2 — type it with each fill-up instead.

---

## Auto-record didn't fire

It needs all of:

1. An adapter **paired to a vehicle**.
2. **Auto-record** on for that vehicle.
3. The **"Allow all the time"** location grant.
4. Bluetooth on, and the app not being killed by a battery optimiser.

Also check the **start-speed threshold** in the vehicle editor — a short crawl out of a car park may never reach it.

> **iOS:** the background wake needed for "connect when the adapter powers up" is not available yet ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). Start trips manually on iOS.

---

## My consumption figure looks wrong

Work through it in this order:

1. **Open the trip and read the OBD2 communication health card.** If coverage is well under 100 %, the gaps were filled with GPS estimates and the trip average is a blend, not a measurement.
2. **Check the tank report on the Trips tab.** If it says the estimates run *n* % over or under pump truth, the app already knows and has just corrected itself — expect the next trips to move.
3. **Check the tank capacity** on the vehicle. A wrong capacity produces plausible-but-wrong range for months.
4. **Check your odometer entries.** Consumption is litres ÷ kilometres, and the kilometres are entirely your typing.
5. **Check whether you ticked "Full tank".** Only full-to-full windows can calibrate anything.
6. **Check the accuracy badge** on the Fuel tab. *Low* means nothing has anchored the model yet — the figure is a model output, and it says so.

Background: [How Sparkilo Works → How a litre becomes a number](User-en-How-It-Works#how-a-litre-becomes-a-number).

---

## "We found a gap of X litres"

You pumped more than your recorded trips account for. Answer the two questions in the reconciliation flow: a missing or mistyped fill-up gets a **correction entry**, an unrecorded drive gets a **virtual trip**. Both are editable afterwards. Leaving it unresolved biases the calibration, so it is worth two taps. See [Fuel Log & Consumption](User-en-Fuel-And-Consumption#when-the-numbers-dont-add-up).

---

## The picture-in-picture tile doesn't show a price

The approach overlay only fires while a **trip is recording** *and* you are inside the approach radius. To verify the layout without driving: **Settings → Developer tools → Test approach overlay** pushes a synthetic in-radius state for 30 seconds.

---

## Price-alert notifications don't arrive

- System notifications allowed for the app?
- Battery saver: Android's aggressive modes kill background work. Set the app to **not restricted**.
- The phone may have been offline at the scheduled slot; the check runs at the next network window.
- The price may simply not have crossed the threshold.
- The **Last check** stamp at the bottom of the alerts screen tells you whether the task is running at all. Old stamp + zero hits = the OS is killing it.

---

## The home-screen widget is stale

- Android limits widget refreshes to roughly once every 30 minutes; that is a system policy.
- Tap the **refresh icon on the widget itself** — it re-pulls prices without opening the app.
- Widget appearance and content variant are per profile, under **Settings → Units & display**.

---

## The map shows grey or blank tiles

- Usually a weak connection; swipe to refresh.
- If it persists, the tile servers may be rate-limiting — try again in a few minutes.
- Try toggling **Settings → Privacy & data → Map tiles through the Sparkilo proxy**; the two paths fail independently.

---

## Scanning a pump or receipt reads nothing

- The **F-Droid** build has no scanning at all — on-device text recognition ships only in the Play / App Store builds. Type the fill-up by hand there.
- Glare on a pump display is the most common cause. Shade it, get square to the display, fill the frame with the digits.
- If it reads the labels but not the numbers, use **Report scan error** so the crop can be used to improve the recogniser.

---

## The app takes a long time to start

Turn on **Startup initialization trace** (Features & use mode → Developer & experimental), restart, then open **Developer tools**. The waterfall names the slow phase; export it and attach it to an issue.

<img src="guide/developer-tools-2.jpg" width="340" alt="Startup initialization trace waterfall with per-phase timings">

*Each bar is one initialisation phase with its duration — a slow launch stops being a guess.*

---

## The app crashes on launch

- Clear the cache from your device's app settings.
- If it persists, file an issue with the Android version, phone model, the app version **and build number** from Settings → About, and the saved error log (the app offers to save it on the next launch; the file lands in Downloads).

---

## How do I back up my data?

**Settings → Backup & restore → Export backup** writes a ZIP to Downloads; restore offers merge or replace. For a machine-readable data export instead, use **Privacy & data → Export or delete → Export my data → ZIP archive**.

TankSync is **not** a backup — it mirrors selected categories, and trips only if you also enabled trip sync.

---

## How do I delete everything?

- **Device:** Privacy & data → Export or delete → **Delete all my data**. Irreversible.
- **Server (TankSync):** delete the server side **first** — Sync & account → Data transparency → **Delete account** removes every row you own in one transaction and names any table it could not erase.

Details: [Privacy, Data & Sync → Your rights](User-en-Privacy-Profiles-Sync#your-rights-under-the-gdpr).

---

## Can I use the app offline?

Partly. Favourites show their last-known prices, recently viewed map tiles are cached, and fill-ups and trips are entirely local. Discovering new stations needs a network call.

---

## Where did the Fuel or Trips tab go?

They belong to the **Medium** and **Full** use modes. If one vanished, a preset or an individual switch turned it off: Settings → Features & use mode → Consumption.

---

## More help

- **Bugs:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — use the Bug Report template and attach the saved error log.
- **Ideas:** the Feature Request template, or [Discussions](https://github.com/fdittgen-png/tankstellen/discussions) first.
- **Privacy questions:** the [privacy policy](https://fdittgen-png.github.io/tankstellen/privacy-policy/), or fdittgen@gmail.com.

---

**Back to:** [User Guide home](User-en-Home)
