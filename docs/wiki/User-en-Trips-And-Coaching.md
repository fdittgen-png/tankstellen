# Trips & Eco-Coaching

The 🛣️ **Trips** tab is an automatic logbook plus a driving coach. It appears on the **Full** use mode.

---

## The Trips tab

<img src="guide/trips-tab.jpg" width="340" alt="Trips tab: month comparison, tank report and the trip list with the start-recording button">

*Month-on-month totals, the latest tank report, then the trip list. The floating button starts a recording.*

The month comparison needs at least three trips per month before it will compare — with fewer, the average is noise rather than a trend.

<img src="guide/trips-map.jpg" width="340" alt="All recorded trips drawn on one map, colour-coded per trip">

*The map icon in the app bar draws every recorded trip on one map — a year of driving at a glance, and an easy way to spot the routes worth optimising.*

---

## Two ways to record

### With your phone alone

No hardware. The app logs the route, distance, duration and speed from GPS, and **models** consumption from your vehicle calibration and driving. Marked with a `~` and an explicit "GPS estimate" note wherever it appears.

Accuracy starts poor and improves: each closed fill-up window re-anchors the model to the pump, so after a handful of full tanks a GPS-only trip typically lands within a few percent. Until then it is labelled preliminary rather than dressed up.

### With an OBD2 adapter

Engine data instead of inference: real fuel flow (measured where the car reports PID 5E), RPM, load, throttle. No learning period for consumption, and the coaching gets access to signals GPS cannot see — gear, revs, engine load. Setup is in [Vehicles & OBD2](User-en-Vehicles-And-OBD2#the-obd2-adapter).

> **Recording never requires an adapter.** Turn off *Require OBD2 for trip recording* (Features & use mode → Consumption) to record GPS-only trips; the coaching is reduced, not absent.

---

## While you drive

### The live figure

The headline number is your average **over the last few seconds** — fuel burned ÷ distance covered, the same quantity a dashboard trip computer shows — labelled *"Last 5 s"*. At a standstill it switches to L/h, because L/100 km is undefined at zero speed.

Change the window under **Settings → Driving & consumption → Live consumption window** (3 / 5 / 10 / 30 s). A **longer window is steadier and easier to read while driving**; a shorter one reacts fast enough to teach you what your right foot costs. The unit follows **Units & display → Consumption unit** everywhere: banner, PiP tile, iOS Live Activity and the trip average.

### Landscape = the in-car view

Turn the phone sideways during a recording and the screen becomes a zero-touch, glanceable layout: on the left the big instant consumption figure with the coaching cue underneath (*lift off* / *anticipate* / *smooth accel* on GPS, *shift up* / *shift down* / *ease pedal* on OBD2) and a large speed read-out; on the right the closest-station radar card above a 2×2 grid of **Distance · Avg · Elapsed · Fuel used**.

Nothing scrolls and nothing is small. Prop the phone in a dash mount and never touch it.

### Picture-in-picture

Shrink the app into a floating tile and keep your navigation app on top. The tile is context-adaptive:

| Situation | Big number | Secondary |
|---|---|---|
| OBD2 connected | live L/100 km (L/h at idle) | distance · elapsed |
| GPS-only, moving | distance so far | elapsed |
| Warming up | elapsed time | — |

### The approach overlay

Come within the configured radius of a station and the tile flips to a large **fuel price** display for it — price for your fuel, brand, distance, readable at a glance.

Which station it locks onto is set in **Settings → Driving & consumption → Station approach overlay**: **nearest** (the first station whose radius you entered) or **cheapest in radius**. On leaving the radius the price layout lingers for a five-second grace period, so brushing past a forecourt doesn't make the tile flicker.

**Test it without driving:** Settings → Developer tools → **Test approach overlay** pushes a synthetic in-radius state for 30 seconds.

---

## Reading a trip

<img src="guide/trip-detail-1.jpg" width="340" alt="Trip summary: date, vehicle, adapter, distance, duration, consumption, fuel used, cost and speeds">

*The summary states its own provenance — vehicle, adapter, and a **GPS track** badge on the distance so you know where the kilometres came from.*

<img src="guide/trip-detail-2.jpg" width="340" alt="Route map coloured by efficiency with the economical/moderate/excessive legend, and the top wasteful behaviours card">

*The route is coloured by efficiency — green under 6 L/100 km, amber to 10, red above. Where the fuel went, geographically.*

That colouring is the single most actionable view in the app: it puts the expensive parts of your commute on a map. A red stretch that repeats every day is a junction, a hill or a habit worth changing.

<img src="guide/trip-detail-3.jpg" width="340" alt="How the drive felt selector, where your fuel went, throttle and RPM distributions">

*Three blocks: your own verdict, the fuel attribution, and how you actually used the engine.*

- **"How did this drive go?"** — *Smooth / Moderate / Aggressive*. Your answer is used to calibrate the driving-style thresholds against real drives, not to score you.
- **Where your fuel went** — litres attributed to hard acceleration versus normal driving. Small absolute numbers on a short trip; the ratio is the point.
- **Throttle position** and **engine speed** distributions — the percentage of the trip spent coasting, light, firm and full throttle, and in each RPM band. A high share above 3000 rpm on a commute means you are short-shifting late, which is expensive.

<img src="guide/trip-detail-4.jpg" width="340" alt="GPS sampling diagnostic and the collapsed OBD2 communication health card">

*Two diagnostics: how complete the GPS track is, and how well the adapter behaved.*

<img src="guide/trip-obd2-health.jpg" width="340" alt="Expanded OBD2 communication health: samples, coverage, adapter, protocol, duration, session end reason">

*Expanded, the OBD2 card explains itself in plain language.*

**Read this card before doubting a consumption figure.** It states how many samples carried engine data, the resulting **coverage percentage**, the adapter and negotiated protocol, the session duration, why the session ended (`userStopped`, a disconnect, a process death), and the decisive line: *"Consumption values come from the adapter, not GPS estimates."* If coverage is well under 100 %, the gaps were filled with GPS estimates and the trip average is a blend.

<img src="guide/trip-detail-5.jpg" width="340" alt="Charts: speed, fuel flow and engine RPM over the trip">

*Speed, fuel flow and RPM on a shared time axis — the three curves that explain any consumption number.*

<img src="guide/trip-detail-6.jpg" width="340" alt="Charts: RPM, engine load, throttle position and coolant temperature">

*Engine load and throttle side by side show the difference between working the engine and merely revving it.*

<img src="guide/trip-detail-7.jpg" width="340" alt="Charts: coolant temperature, altitude gained since start, intake air temperature and ignition advance">

*Altitude matters more than most drivers expect: a climb explains a consumption spike that would otherwise look like bad driving.*

The **share** and **delete** actions sit in the app bar. Sharing exports the trip (including a GPX track) so you can keep it outside the app.

---

## Driving score and coaching

With an adapter, each trip is scored out of 100 — a composite of idling, hard acceleration, hard braking, high-RPM time, full throttle, lugging, jerkiness, sustained high speed, aggressive pedal work and mixture richness. The breakdown names which behaviour cost the most, so the score is a diagnosis rather than a grade.

The **top wasteful behaviours** card turns that into sentences you can act on — and says *"No notable inefficiency — keep it up"* when there is nothing to fix, rather than inventing a complaint.

Coaching can also be delivered while driving:

- **Real-time eco coaching** — a light vibration plus an on-screen cue when you accelerate hard at cruising speed.
- **Spoken driving coaching** — the same advice read aloud, so your eyes stay on the road.
- **Glide-coach (beta)** — a subtle haptic when you should lift off ahead of a red light, using traffic-signal positions from OpenStreetMap. **Off by default: it is a distraction risk**, and it needs network access to fetch signal positions for your area.

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching switches, rewards, loyalty cards, achievements toggle and OBD2 debug logging">

*Settings → Driving & consumption. Achievements and scores can be hidden app-wide if gamification isn't for you.*

---

## The carbon dashboard

<img src="screenshots/carbon-dashboard.png" width="340" alt="Carbon dashboard: cost and CO2 broken down by trip length and speed band">

*Cost and CO₂ from the same measured litres, broken down two ways.*

- **By trip length** — short hops are usually the most expensive per kilometre, because a cold engine drinks. Seeing that quantified is what makes people combine errands.
- **By speed band** — how much fuel goes on crawling in town versus cruising.

It is built entirely from data on your phone, and switched on under Features & use mode → Consumption.

---

## Exports and diagnostics

- **Share** a single trip (summary + GPX).
- **Export driving-analysis trace** — the trip's GPS KPIs, score and lessons as JSON, with a free-text field for how the drive actually felt. Sharing it back helps calibrate the driving-style thresholds against real drives. Developer-mode feature.
- **Export my data → ZIP archive** under Privacy & data → Export or delete includes every trip and one GPX per trip.

---

<details>
<summary>Whole-screen reference — trip detail, full page</summary>

<img src="guide/full/trip-detail.jpg" width="420" alt="Full trip detail screen stitched from eight captures">

</details>

---

**See also:** [Vehicles & OBD2](User-en-Vehicles-And-OBD2) · [Fuel Log & Consumption](User-en-Fuel-And-Consumption)
**Next:** [Price History & Predictions →](User-en-Price-History-And-Predictions)
