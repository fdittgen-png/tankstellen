# Route Planning

Not "cheapest near me" but **cheapest on the way** — the difference is worth several euros on any long drive.

---

## Starting a route search

<img src="guide/search-criteria-route-1.jpg" width="340" alt="Criteria sheet in route mode: start, add stop, destination, fuel, segment, detour, minimum saving">

*Tap **Search** → switch to **Search along route**. The Search button stays disabled until a destination and a fuel grade are set.*

| Field | Meaning |
|---|---|
| **Start** | Your current position, or a typed city / postal code |
| **Add a stop** | Intermediate waypoints — the corridor follows them |
| **Destination** | City, postal code or coordinates |
| **Fuel** | The grade to price along the corridor |
| **Route segment** | Show the cheapest station every *n* km (50–1000 km) |
| **Max detour** | How far off the direct line a station may sit |
| **Minimum saving** | Hide stops that don't beat the corridor average by at least this much; *Off* shows everything |

<img src="guide/search-criteria-route-2.jpg" width="340" alt="Lower half of the route criteria: open-now, amenities, brands, save as defaults">

*The same open-now / amenity / brand filters as a nearby search apply to the corridor.*

### How it actually works

1. The app calls the public **OSRM** open routing service to get the road polyline for your route.
2. It samples candidate points along that polyline, spaced by your **route segment** setting.
3. Around each sample point it queries the price provider **of whichever country that point is in**, using the fuel grade from that country's profile.
4. It ranks candidates within each segment by your chosen strategy and the **max detour** limit.

### What this means in practice

- **Segment length is the real control.** 50 km on a 600 km drive gives you twelve shortlists; 200 km gives you three. Pick it to match how often you actually stop.
- **Max detour is measured off the direct route**, not from you. 5 km means "up to 5 km of extra driving to reach it".
- **Long routes take longer.** A 500 km corridor samples many points across possibly several providers.
- If the start is *auto GPS* and you lose signal, the search falls back to the last known fix.

---

## Cross-border corridors

When a route crosses a border, **every country in the corridor is queried through its own provider**, and the result header credits all of them:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Because grades differ by country, a cross-border result legitimately shows E85 on the French leg and Gasolina 95/E5 on the Spanish leg. They are priced correctly for each side, never averaged.

**You need a profile per country** with the right preferred fuel, otherwise the second leg has no grade to price and its stations render `--`. See [How Sparkilo Works → Profiles](User-en-How-It-Works#profiles-one-context-one-set-of-defaults).

---

## Results stream in

One slow national API should not hold up the rest of the corridor, so results arrive **progressively**: each country's stations appear as that provider answers, with a banner naming the sources still pending. Tap a cheap result the moment it lands — you don't have to wait for the slowest country.

---

## The four strategies

### 🏆 Best stops *(default)*
Surfaces the 3–5 cheapest realistically-reachable stations as ranked chips at the top. Detours stay small. This is what most drivers actually want.

### 🎯 Cheapest
The single lowest-priced station on the whole route. Best when you refuel once and want the maximum per-litre saving.

### ⚖️ Balanced
Scores each candidate on price *and* proximity to the line. A station 5 km off but 10 c/L cheaper wins; one 50 km off has to be dramatically cheaper.

### 📏 Uniform
Splits the route into equal segments and proposes one stop per segment. Best for long cross-border drives with multiple refuels.

The default strategy, along with segment length, max detour, minimum saving and how many candidates are considered per sampling point, is stored **per profile**:

<img src="guide/profile-edit-2.jpg" width="340" alt="Route planning parameters inside the profile editor">

*Settings → Profiles & region → edit → Route planning. Set it once here instead of adjusting the sheet on every trip.*

---

## Reading the results

Each row adds two numbers a nearby search doesn't have:

- **Distance from start** — how far along the route the station sits, so you can match it to when your tank will actually be low.
- **Detour** — the extra kilometres versus the direct line.
- **Saving vs. average** — against the corridor average, not a national one.

Switch to **All stations** to see every station along the route rather than the shortlist. The map draws the polyline with all pins.

---

## Avoiding motorways

**Settings → Profiles & region → Display & stations → Avoid motorways** makes the router prefer secondary roads. This changes the *polyline*, so it changes which stations are candidates at all — motorway service stations disappear from the corridor rather than merely being deprioritised. Useful precisely because motorway fuel is usually the most expensive on any route.

---

## Saved itineraries

Tap **Save route** on the results screen. Saved itineraries appear at the top of the route form; tapping one re-runs the same corridor with **fresh prices**. The route geometry is stored, not the prices.

---

**See also:** [Finding Stations](User-en-Finding-Stations) · [Settings Reference](User-en-Settings-Reference#profiles--region)
**Next:** [Favourites & Alerts →](User-en-Favorites-And-Alerts)
