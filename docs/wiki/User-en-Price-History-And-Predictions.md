# Price History & Predictions

The app builds a **private, local** picture of how prices move around you, and turns it into one honest recommendation.

---

## What is recorded, and where

Every time a station's price passes through the app — a search, a favourites refresh, or a background alert check — the app writes a record **on your phone**: station, fuel, price, timestamp. Nothing is uploaded, and no one else's data is downloaded.

- **De-duplicated to one record per station per hour.** Searching the same station five times in ten minutes adds one entry.
- **Retained 30 days.** Older records are deleted automatically.
- **Enabled by** *Features & use mode → Prices & alerts → Price history*. Switch it off and no records are written at all.

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Prices &amp; alerts settings: price history, TFLite prediction, community reports, payment QR">

*Settings → Prices & alerts. **Price history** is the prerequisite for the prediction below it — turn history off and the prediction has nothing to work with.*

---

## Viewing a station's history

Open a station's detail page and scroll to **Price history**:

- **Hourly chart** — the average price for each hour of the day over the last 30 days.
- **Day-of-week chart** — the average for each weekday.
- **Min / max / average / trend** summary.

The cheapest hour or day is highlighted green, the dearest red.

---

## "Best time to fill"

Once there is enough history the station grows a banner:

> 💡 **Prices typically drop Tuesday 18:00–20:00** — save ~3.2 c/L

### What it is — and is not

It is a **summary of what has already happened at this station in the last 30 days**, in *your* data. It is deliberately **not**:

- a forecast of tomorrow's price,
- aware of oil markets, tax changes or weather,
- built from other users' data.

That restraint is the point. A regional Monday-morning markup is a real, repeating, local pattern you can act on; a market prediction from a phone is not.

### The learning phase

The banner stays hidden until the app has at least **10 price records for that station in the last 30 days**. How long that takes depends entirely on how often the station's price passes through the app:

| Situation | Time to the banner |
|---|---|
| Station has a **price alert** on it | A few hours — the background check records every 30–60 min |
| Station is a **favourite** you open daily | About 10 days |
| Neither — you only search it occasionally | Weeks, possibly never |

**The practical trick:** put an alert on the station you actually use. The alert earns its keep twice — it pings you on a drop, and it fills the history that produces the recommendation.

### Why your favourite still has no banner

1. **Not enough records yet** (see above).
2. **The price barely moved.** If the 30-day spread is under 0.1 c/L there is nothing worth acting on, so nothing is shown.
3. **Only one fuel has samples.** The threshold is per fuel type, not per station.

---

## On-device price prediction

*Features & use mode → Prices & alerts → **Best time to fill up*** enables a small TensorFlow Lite model that runs **entirely on the device**. Its features and its predictions never leave the phone. It is what powers the *predictive* variant of the home-screen widget (**Settings → Units & display → Home-screen widget → Content variant**), which shows the best moment to fill rather than just the current price.

If you would rather have nothing inferred at all, switch it off: history and the pattern banner keep working without it.

---

## Community price reports

*Features & use mode → Prices & alerts → **Community price reports*** adds a flag action to the station detail so you can report a price the official source has wrong. Reports go to the shared TankSync database under your pseudonymous account and are visible to other signed-in users — so this is the one price feature that is **not** purely local. It requires TankSync and is off unless you turn it on.

---

## Exporting

**Settings → Privacy & data → Export or delete → Export my data → CSV** writes a CSV — its price-history table holds station, fuel, price, timestamp — to your public Downloads folder, ready for a spreadsheet.

---

**See also:** [Favourites & Alerts](User-en-Favorites-And-Alerts) · [Finding Stations → Freshness](User-en-Finding-Stations#freshness-and-why-it-matters-more-than-the-price)
**Next:** [Settings Reference →](User-en-Settings-Reference)
