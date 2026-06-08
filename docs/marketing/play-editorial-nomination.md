This is a content-writing task; no codebase exploration is needed. The brief is fully specified. I'll produce the Markdown directly.

# Google Play — Editorial Feature Nomination

**App name:** Sparkilo

**Package name:** `de.tankstellen.fuelprices`

**Primary category (recommended):** **Maps & Navigation**
> Rationale: Sparkilo's core loop is location-driven — route to the cheapest station nearby or *along your route*, live "Fuel Station Radar" scanning, an approach live-price overlay, and per-trip GPS routes. That is navigation-first behaviour, and the category is where curators look for polished mapping experiences. (Auto & Vehicles is the natural secondary tag — the consumption tracker, OBD2 trip logbook and CO2 dashboard fit it — but the day-to-day job-to-be-done is "navigate me to the best price," so Maps & Navigation is the stronger primary.)

**Single most compelling reason to feature it:**
> A genuinely **free, ad-free, no-account, open-source (MIT)** comparison app that uses **official government / open-data fuel prices** — not crowdsourced guesses — across **17 countries**, with **GPS and API keys that never leave the device**. It's the rare utility that's both delightful and principled: privacy-by-design, no monetisation dark patterns, and source you can audit on GitHub.

**What's new / innovative:**
- **Official price data, not crowdsourced.** Prices come from national government feeds and official open-data sources, so they're authoritative rather than user-submitted and stale.
- **Search *along your route*, not just nearby.** Plan a trip and Sparkilo finds the cheapest detour-light station on the way, with pins coloured cheapest→priciest.
- **Fuel Station Radar** live scan and an **approach live-price overlay** that surfaces the price as you near a station.
- **One app for combustion *and* EV** — petrol, diesel, LPG, CNG, E85, plus EV charging worldwide via Open Charge Map.
- **On-device price alerts** that fire only when you're actually near a qualifying station — useful, not spammy.
- **Eco-coaching trip logbook** via OBD2 (ELM327) *or* GPS-only, with each trip's route coloured by efficiency, plus OCR of the pump display and receipts into a consumption tracker (L/100km, cost/km, CO2 dashboard).

**Target audience:**
> Daily drivers, commuters, fleet and gig drivers, EV and hybrid owners, road-trippers, and privacy-conscious users across Europe, Latin America, Asia-Pacific and beyond who want to spend less on fuel without handing over their data.

**Key launch markets:**
> Germany, France, United Kingdom, Spain, Italy, Austria, Portugal, Greece, Denmark, Luxembourg, Romania, Slovenia, South Korea, Australia, Argentina, Chile, Mexico. (EV charging is worldwide.)

**Quality & design highlights:**
- Clean **Material 3** interface with a calm forest-green identity (#2E7D32) and a clear cheapest→priciest price-pin colour scale.
- Thoughtful utility surface: home-screen widget, voice announcements, favourites, full station detail (brand, opening hours, payment methods, amenities), filters (fuel type, radius, open-now, amenities, highway-only), and a built-in fuel-cost calculator.
- **Privacy-by-design architecture:** no ads, no tracking SDKs, no account required; location and API keys stay on-device. Optional, opt-in **TankSync** cross-device sync only if the user wants it.
- **Open-source and verifiable:** MIT-licensed, with a libre F-Droid build alongside Play.

**Accessibility & localisation:**
> **23 UI languages**, covering all 17 supported markets and more. Material 3 components inherit platform accessibility (scalable text, screen-reader labels, high-contrast-friendly colour roles); voice announcements add a hands-free, eyes-free mode for use while driving.

---

**Elevator pitch (reusable by curators):**
> Sparkilo is a free, ad-free, open-source app that routes you to the cheapest fuel — petrol, diesel, LPG, CNG, E85 or EV charging — using *official* government price data across 17 countries. It searches nearby or along your route, alerts you on-device when prices drop near you, and tracks your consumption and CO2 — all without ads, tracking, or an account, with your location never leaving your phone.

**Links:**
- Google Play: https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
- GitHub (source, MIT): https://github.com/fdittgen-png/tankstellen
- F-Droid (libre build): https://fdittgen-png.github.io/tankstellen/fdroid

---

# Apple App Store — Featuring / "Apps We Love" Pitch

> *iOS is coming soon to the App Store (currently in TestFlight / internal testing).*

**App name:** Sparkilo — Fuel & EV Price Compare

**The pitch:**
> Sparkilo finds you the cheapest place to fill up — petrol, diesel, LPG, CNG, E85, or an EV charger — using **official government price data** across **17 countries**, not crowdsourced guesses. Search nearby or **along your route**, watch pins shade from cheapest to priciest, and get an on-device alert the moment a good price appears near you. It then closes the loop with a consumption tracker, eco-coaching trip logbook, and a CO2 dashboard.

**Why it deserves a Story / feature:**
- **Principled by design.** Free, no ads, no tracking, no account — and **open-source (MIT)**. Your location and API keys never leave your iPhone.
- **Authoritative, not crowdsourced.** Real-time official price feeds make it trustworthy in a category full of stale, user-submitted data.
- **Beautifully focused utility.** A calm, modern interface, a home-screen widget, voice announcements for hands-free driving, an approach live-price overlay, and live Fuel Station Radar — saving money made genuinely pleasant to use.
- **Global from day one.** 17 countries, worldwide EV charging via Open Charge Map, and **23 languages** — a localisation story that travels.

**One-line hook:**
> The free, private, open-source way to never overpay for fuel — official prices, on your route, in 23 languages.

**Links:**
- iOS: coming soon to the App Store (TestFlight / internal testing now)
- Source (MIT): https://github.com/fdittgen-png/tankstellen