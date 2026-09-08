# Vehicles & OBD2

Everything the app knows about *your car*. This is the page that decides whether the consumption numbers on every other page are trustworthy.

---

## Why the app needs a vehicle at all

Without a vehicle, Sparkilo is a price finder. With one it can convert litres and kilometres into *your* cost per kilometre, estimate range, and — with an adapter — model instantaneous fuel flow.

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Vehicles &amp; OBD2 hub with My vehicles and OBD2 adapter tiles">

*Settings → Vehicles & OBD2. Note the scope badge on the adapter tile: adapters are paired **per vehicle**, not per phone.*

<img src="guide/my-vehicles.jpg" width="340" alt="My vehicles list with one active vehicle">

*The green check marks the active vehicle — the one new fill-ups and trips are attributed to.*

---

## Identity and drivetrain

<img src="guide/vehicle-edit-1.jpg" width="340" alt="Vehicle editor: name, optional VIN, read VIN from car, drivetrain selector">

*Name it whatever you'll recognise. The VIN is optional.*

### The VIN, and what it buys you

Entering (or reading) the VIN lets the app look up engine displacement, cylinder count, power and fuel type, which are the inputs of the consumption model. **Read VIN from car** pulls it over OBD2 in a second.

Online VIN decoding is a **separate consent** — the app asks before sending anything, and offline partial decoding still works if you decline. A VIN is personal data; treat it like one.

### Drivetrain

**Combustion / Hybrid / Electric** changes which fields exist below it. Combustion asks for tank capacity, power and preferred fuel; electric asks for battery capacity and connectors.

---

## Tank capacity, power, and flex-fuel

<img src="guide/vehicle-edit-2.jpg" width="340" alt="Combustion block: tank capacity, engine power, preferred fuel, multi-fuel switch, paired adapter">

*Tank capacity is the single most load-bearing number on this screen.*

### Why tank capacity matters so much

It is the denominator of the tank-level gauge and of the range estimate, and it bounds what the app considers a plausible fill. A wrong capacity produces a plausible-looking but wrong range for months. Take it from the handbook, not from memory — manufacturers often quote a usable capacity a couple of litres below the nominal one.

### "I can fill up with different fuels"

Turn this on for a flex-fuel car (E85/E10, or anything you genuinely alternate). Two things change:

- The fill-up form **asks which fuel you actually pumped** every time, instead of assuming the preferred one.
- The statistics screen gains the **cost per kilometre by fuel** comparison, which is the only honest way to compare a cheap-per-litre, thirsty fuel against an expensive, efficient one.

Leave it off if you always pump the same grade — it just adds a field.

---

## The OBD2 adapter

An OBD2 adapter is a small Bluetooth dongle in your car's diagnostic port (usually under the dashboard). **It is entirely optional.** Everything works on GPS alone; the adapter upgrades estimates to measurements.

### What it changes

| Without adapter | With adapter |
|---|---|
| Distance and time from GPS | Same, plus engine data |
| Consumption **modelled** from your calibration | Consumption **measured** (or modelled with a far better model) |
| Coaching from speed and acceleration | Coaching from RPM, throttle, load, gear |
| Accuracy ceiling: Medium | Accuracy ceiling: High (±3–7 %) |
| Manual trip start | Auto-record possible |

### What the app reads

Speed, RPM, engine load %, throttle position %, coolant and intake-air temperature, ignition timing advance, fuel level %, odometer (standard PID A6, falling back to PID 31 and manufacturer Mode 22), and instantaneous fuel flow — either directly from **PID 5E** where the car reports it, or derived from the mass-airflow sensor.

> **The important distinction:** if your car answers PID 5E, your consumption is *measured* and no calibration is applied to it. If it does not, the figure is *modelled* from airflow and engine parameters, and that model is what the pump-anchored gain corrects. The vehicle screen tells you which case you are in.

### Supported adapters

16 models are recognised by Bluetooth advertisement name, each with a compatibility tier:

- ✅ **Tested** — confirmed on real hardware by the maintainer.
- 👤 **User-verified** — at least one user reported it working.
- ⚠️ **Theoretical** — the profile and transport are right, but nobody has confirmed end-to-end yet.

| Adapter | Transport | Notes | Tier |
|---|---|---|---|
| vLinker FS | Classic BT | Dominant EU model; recommended | ✅ |
| vLinker BM-Android | Classic BT | Classic SPP sibling of BM+ | ✅ |
| SmartOBD (BLE) | BLE | Generic ELM327 v1.5 clone | 👤 |
| SmartOBD (Classic) | Classic BT | Same brand, Classic SPP | 👤 |
| vLinker FD / MC | BLE | Nordic UART FFF0 family | ⚠️ |
| OBDLink MX+ | BLE | Scantool premium | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | ELM327 v2.1 BLE clone | ⚠️ |
| vLinker BM+ | BLE | BLE-only sibling | ⚠️ |
| Konnwei KW902 | Classic BT | ELM327 v1.5 clone | ⚠️ |
| Vgate iCar Pro | BLE | BLE variant only | ⚠️ |
| Panlong WiFi | — | WiFi-only, listed so mis-pairings are labelled | ⚠️ |
| BAFX 34t5 | Classic BT | Legacy ELM327 v1.5 | ⚠️ |
| Generic ELM327 (BLE) | BLE | Catch-all for BLE FFF0 clones | ⚠️ |
| Generic ELM327 (Classic) | Classic BT | Catch-all for Classic SPP clones | ⚠️ |

Unlisted adapters fall through to the generic ELM327 profile and usually work. If yours does — or doesn't — [open an issue](https://github.com/fdittgen-png/tankstellen/issues) so the tier can be corrected.

### Pairing

1. Turn the ignition to **on** (engine running is fine, off is not).
2. Plug the adapter in; its LED should be solid.
3. Open the vehicle and tap the adapter section, or start a trip.
4. Grant **Bluetooth Scan** and **Bluetooth Connect** (Android 12+). On Android 11 and below the OS demands **Location** for Bluetooth scanning instead — an OS rule, not a tracking decision.
5. Wait roughly 8 seconds for the scan and tap your adapter. The app runs the ELM327 handshake and confirms.

Once paired, the adapter belongs to that vehicle. **Reset connection** re-runs the handshake without forgetting the device — the first thing to try after a mid-drive dropout. **Forget adapter** clears the pairing entirely.

---

## Baseline calibration — teaching the app your car

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Baseline calibration: paired adapter, 210/270 sample progress, missing-situation warning and per-situation bars">

*210 of 270 samples collected. Two driving situations are still empty, and the app says so rather than pretending the profile is complete.*

Each OBD2 sample is filed into a driving situation: **idle, stop & go, urban, highway, decelerating, climbing / loaded, cold start, sustained load / towing, coasting**. The per-situation averages become the vehicle's baseline — the model that produces a plausible L/100 km when the adapter is absent or a PID stops answering.

<img src="guide/vehicle-edit-4.jpg" width="340" alt="Per-situation sample bars and the reset baseline action, plus the calibration mode selector">

*Situations with zero samples are the ones that will fall back to defaults. Two of them here — decelerating and towing.*

### Rule-based vs fuzzy

<img src="guide/vehicle-edit-5.jpg" width="340" alt="Calibration mode selector with Rule-based and Fuzzy, plus reset actions and service reminders">

*Fuzzy is the default and the better choice for almost everyone.*

- **Rule-based** assigns each sample to exactly one situation. Predictable, but it flips between "urban" and "highway" from sample to sample when you cruise near the boundary — around 60 km/h, for example.
- **Fuzzy** spreads each sample across all situations by how well each one fits. Smoother precisely where rule-based is jumpy, at the cost of being harder to reason about sample by sample.

### The two reset buttons — and what they really do

- **Reset volumetric efficiency** discards the learned η_v and restores the 0.85 default. η_v is a parameter of the speed-density model that estimates airflow when there is no MAF reading. Reset it only after a mechanical change; a wrong-looking number is more likely a coverage problem than a bad η_v. Cars that report fuel rate directly (PID 5E) never use it at all.
- **Reset from vehicle database** re-pulls displacement, power and defaults from the built-in catalogue, discarding your manual overrides.
- **Reset driving-situation baseline** (in the baseline card) wipes every learned sample and drops you back to cold-start defaults until new trips refill the profile.

None of these touch the **pump gain**, which is learned from full-to-full fill-up windows and lives outside the OBD2 model — see [How Sparkilo Works → How a litre becomes a number](User-en-How-It-Works#how-a-litre-becomes-a-number).

---

## Service reminders

At the bottom of the vehicle editor: presets for **oil change (15 000 km)**, **tyres (20 000 km)** and **inspection (30 000 km)**, plus custom reminders. They count against the odometer readings you enter with your fill-ups, so they only advance if you log the odometer — which is also what the calibration needs. One habit, two payoffs.

---

## Auto-record

With an adapter paired, recording can be fully hands-off:

- **Auto-pair** — the first manual pairing creates the adapter ↔ vehicle association.
- **Auto-connect** — when the OS sees the paired adapter advertising, the app reconnects in the background.
- **Auto-start** — once connected and moving above the start-speed threshold, the trip begins.
- **Auto-save** — the adapter loses power with the ignition, and after the configured delay the trip is finalised and saved.

Auto-record needs the **"Allow all the time"** location grant, because Android only lets a background service stream GPS with that permission. That grant is used by auto-record and nothing else; searching and map centring use the ordinary foreground grant.

> **Platform note.** Auto-record is verified on **Android**. On iOS the OS-level background wake needed for "connect when the adapter powers up" is not available yet ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)); iOS users start trips manually.

Thresholds (start speed, save delay after disconnect) live in the vehicle editor, so a car you use for short hops can have a different trigger than a commuter.

---

<details>
<summary>Whole-screen reference — the vehicle editor, full page</summary>

<img src="guide/full/vehicle-edit.jpg" width="420" alt="Full vehicle editor stitched from five captures">

</details>

---

**See also:** [Trips & Eco-Coaching](User-en-Trips-And-Coaching) · [Troubleshooting → OBD2](User-en-Troubleshooting-FAQ#obd2-adapter-wont-connect)
**Next:** [Fuel Log & Consumption →](User-en-Fuel-And-Consumption)
