# Sparkilo — Launch Copy Kit

Ready-to-paste posts for launch day. Each block is self-contained. Don't fire them all at once — see **Posting tips** at the bottom for cadence.

---

## 1. Hacker News — Show HN

**Title** (copy this line):

```
Show HN: Sparkilo – open-source, ad-free fuel-price and EV-charging app (17 countries)
```

**Body**:

```
Hi HN,

I'm a solo developer and this is my first real launch, so I'd genuinely
appreciate honest feedback.

Sparkilo compares fuel prices and EV-charging across 17 countries (Austria,
Argentina, Australia, Chile, Denmark, France, Germany, Greece, Italy,
Luxembourg, Mexico, Portugal, Romania, Slovenia, South Korea, Spain, UK).
It routes you to the cheapest nearby station — or the cheapest one along a
route you're about to drive — for petrol, diesel, LPG, CNG, E85 or electric.

The thing that bugged me about existing apps, and the reason I built this:

- The prices are OFFICIAL. They come from government / open-data feeds, not
  crowdsourced guesses. (EV charging is via Open Charge Map.)
- No ads, no tracking, no account, no analytics SDK. Your GPS location and
  the API keys you enter never leave the device.
- It's free and MIT-licensed.

Other bits: on-device price alerts that only fire when you're actually near
the station, a fuel-station "radar" live scan, a consumption tracker with OCR
of the pump display and receipts, a fuel-cost calculator, a CO2 dashboard, a
trip logbook with eco-coaching (OBD2 ELM327 or GPS-only), a home-screen
widget and voice announcements.

Tech: Flutter (one codebase, Android + iOS), Riverpod + freezed, Hive for
local storage. Each country is a pluggable service that talks to that
country's official open-data API and normalises into a common model, with
fallback chains when a feed is flaky. 23 UI languages. There's a libre
F-Droid build with no proprietary bits, and an optional self-hosted Supabase
("TankSync") if you want cross-device sync you control — it's off by default
and the app ships you the SQL to paste into your own project.

Honest caveats: it's new, I'm one person, and coverage quality varies by
country because every government publishes data differently. If your country's
data looks wrong I'd love a bug report. iOS is in TestFlight right now; the
App Store listing is in progress.

Source: https://github.com/fdittgen-png/tankstellen
Google Play: https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
F-Droid (libre build): https://fdittgen-png.github.io/tankstellen/fdroid

Happy to answer anything about the data sources, the privacy model, or the
Flutter side.
```

---

## 2. Product Hunt

**Product name**:

```
Sparkilo
```

**Tagline** (≤60 chars):

```
Free, ad-free fuel & EV-charging prices, 17 countries
```

**Description** (≤260 chars):

```
Compare official, real-time fuel prices and EV-charging across 17 countries.
Routes you to the cheapest station nearby or along your route. No ads, no
tracking, no account — GPS and keys stay on-device. Free, open-source (MIT).
```

**Maker's first comment**:

```
Hey Product Hunt 👋

I'm the solo developer behind Sparkilo. I built it because the fuel apps I
was using were full of ads, wanted an account, and showed prices that other
users had typed in — sometimes days out of date.

Sparkilo is different in three ways I care about:

1. The prices are OFFICIAL — pulled straight from government / open-data feeds
   in each of the 17 countries (EV charging via Open Charge Map), not
   crowdsourced.
2. It's privacy-first by design — no ads, no tracking, no account. Your
   location and any API keys never leave your phone.
3. It's free and open-source (MIT). There's even a libre F-Droid build.

Beyond price comparison it does along-the-route search, on-device price alerts
that only fire when you're nearby, a fuel-station radar, a consumption tracker
with OCR of the pump/receipt, a CO2 dashboard, and a trip logbook with
eco-coaching (OBD2 or GPS-only). 23 UI languages.

It's on Google Play and F-Droid now; iOS is in TestFlight with the App Store
listing on the way.

I'm one person, so the roadmap and the next countries are wide open — I'd love
to hear what you'd want. Thanks for taking a look!
```

**Topics / tags**:

```
Android · Open Source · Privacy · Travel
```

---

## 3. Reddit

> Localise nothing further — the FR/DE/ES/PT blocks below are already written in-language. Post each to its own subreddit on a different day. Read each sub's self-promo rules first; some require a flair.

### r/france

**Title**:

```
J'ai créé une appli open-source et gratuite pour comparer les prix des carburants (prix officiels, sans pub ni traçage)
```

**Body**:

```
Salut r/france,

Développeur solo, je viens de sortir Sparkilo. Ça compare les prix des
carburants à partir des données OFFICIELLES (prix.carburants / open data du
gouvernement en France), pas des prix saisis par les utilisateurs. Ça vous
guide vers la station la moins chère à proximité — ou la moins chère sur votre
trajet — pour SP95, gazole, GPL, E85, etc. Recharge électrique aussi (via Open
Charge Map).

Ce à quoi je tiens : pas de pub, pas de traçage, pas de compte. Votre position
GPS ne quitte jamais le téléphone. C'est gratuit et open-source (MIT).

Il y a aussi des alertes de prix locales, un suivi de consommation avec OCR du
ticket, un calculateur de coût et un carnet de trajets. 17 pays au total.

Play Store : https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
F-Droid : https://fdittgen-png.github.io/tankstellen/fdroid
Code source : https://github.com/fdittgen-png/tankstellen

C'est tout récent et je suis seul dessus, donc tout retour (ou bug sur les
données françaises) m'intéresse beaucoup. Merci !
```

### r/de  *(German)*

**Title**:

```
Ich habe eine kostenlose, quelloffene App für Spritpreise gebaut — offizielle Daten, keine Werbung, kein Tracking
```

**Body**:

```
Hallo r/de,

ich entwickle allein und habe gerade Sparkilo veröffentlicht. Die App
vergleicht Spritpreise auf Basis OFFIZIELLER Daten (in Deutschland über die
Markttransparenzstelle für Kraftstoffe), nicht über von Nutzern eingetragene
Preise. Sie lotst euch zur günstigsten Tankstelle in der Nähe — oder zur
günstigsten entlang eurer Route — für Benzin, Diesel, LPG, CNG, E85. Auch
E-Laden ist dabei (über Open Charge Map).

Was mir wichtig ist: keine Werbung, kein Tracking, kein Konto. Euer GPS-Standort
verlässt das Gerät nie. Kostenlos und Open Source (MIT).

Dazu gibt es lokale Preisalarme (lösen nur aus, wenn ihr in der Nähe seid),
einen Verbrauchstracker mit OCR des Kassenbons, einen Kostenrechner und ein
Fahrtenbuch. Insgesamt 17 Länder, 23 Sprachen.

Play Store: https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
F-Droid: https://fdittgen-png.github.io/tankstellen/fdroid
Quellcode: https://github.com/fdittgen-png/tankstellen

Ist noch ganz frisch und ich bin allein dran — über Feedback oder Bug-Reports
(gerade zu den deutschen Daten) freue ich mich sehr. Danke!
```

### r/italy  *(Italian)*

**Title**:

```
Ho creato un'app gratuita e open-source per confrontare i prezzi dei carburanti — dati ufficiali, niente pubblicità né tracciamento
```

**Body**:

```
Ciao r/italy,

sviluppatore solitario, ho appena pubblicato Sparkilo. Confronta i prezzi dei
carburanti usando i dati UFFICIALI (in Italia l'Osservaprezzi Carburanti del
MIMIT), non prezzi inseriti dagli utenti. Ti porta al distributore più
economico nelle vicinanze — o a quello più conveniente lungo il tuo percorso —
per benzina, diesel, GPL, metano, E85. C'è anche la ricarica elettrica (via
Open Charge Map).

Ciò che mi sta a cuore: niente pubblicità, niente tracciamento, niente account.
La tua posizione GPS non lascia mai il telefono. Gratuita e open-source (MIT).

Ci sono anche avvisi di prezzo locali, un registro dei consumi con OCR dello
scontrino, un calcolatore di costi e un diario di viaggio. In totale 17 paesi.

Play Store: https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
F-Droid: https://fdittgen-png.github.io/tankstellen/fdroid
Codice sorgente: https://github.com/fdittgen-png/tankstellen

È appena nata e ci lavoro da solo, quindi ogni feedback (o segnalazione di bug
sui dati italiani) è molto gradito. Grazie!
```

### r/es  *(Spanish)*

**Title**:

```
He creado una app gratuita y de código abierto para comparar precios de carburantes — datos oficiales, sin anuncios ni rastreo
```

**Body**:

```
Hola r/es,

soy desarrollador en solitario y acabo de publicar Sparkilo. Compara los
precios de los carburantes usando datos OFICIALES (en España, los del
Ministerio / Geoportal de Hidrocarburos), no precios introducidos por los
usuarios. Te lleva a la gasolinera más barata cercana — o a la más barata en tu
ruta — para gasolina, diésel, GLP, GNC, E85. También carga eléctrica (vía Open
Charge Map).

Lo que me importa: sin anuncios, sin rastreo, sin cuenta. Tu ubicación GPS
nunca sale del teléfono. Gratis y de código abierto (MIT).

También tiene alertas de precio locales, un registro de consumo con OCR del
ticket, una calculadora de costes y un diario de viajes. En total 17 países.

Play Store: https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
F-Droid: https://fdittgen-png.github.io/tankstellen/fdroid
Código fuente: https://github.com/fdittgen-png/tankstellen

Es muy reciente y lo llevo yo solo, así que cualquier comentario (o aviso de
fallo en los datos de España) lo agradezco mucho. ¡Gracias!
```

### r/portugal  *(Portuguese)*

**Title**:

```
Criei uma app gratuita e de código aberto para comparar preços de combustíveis — dados oficiais, sem anúncios nem rastreamento
```

**Body**:

```
Olá r/portugal,

sou um programador a solo e acabei de lançar a Sparkilo. Compara os preços dos
combustíveis com base em dados OFICIAIS (em Portugal, os da DGEG / Preços
Combustíveis), não em preços introduzidos pelos utilizadores. Leva-te ao posto
mais barato nas proximidades — ou ao mais barato ao longo do teu trajeto — para
gasolina, gasóleo, GPL, GNC, E85. Também tem carregamento elétrico (via Open
Charge Map).

O que me importa: sem anúncios, sem rastreamento, sem conta. A tua localização
GPS nunca sai do telemóvel. Gratuita e de código aberto (MIT).

Tem ainda alertas de preço locais, um registo de consumos com OCR do talão, uma
calculadora de custos e um diário de viagens. No total, 17 países.

Play Store: https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
F-Droid: https://fdittgen-png.github.io/tankstellen/fdroid
Código-fonte: https://github.com/fdittgen-png/tankstellen

É muito recente e sou só eu a trabalhar nela, por isso qualquer comentário (ou
relato de erro nos dados de Portugal) é muito bem-vindo. Obrigado!
```

### r/androidapps

**Title**:

```
[App] Sparkilo — free, ad-free fuel-price & EV-charging comparison using official data (17 countries, open-source)
```

**Body**:

```
Solo dev here. Sparkilo compares fuel prices across 17 countries (AT, AR, AU,
CL, DK, FR, DE, GR, IT, LU, MX, PT, RO, SI, KR, ES, UK) using OFFICIAL
government / open-data feeds — not crowdsourced prices. EV charging is via Open
Charge Map. It routes you to the cheapest station nearby or along your route for
petrol, diesel, LPG, CNG, E85 or electric.

No ads, no tracking, no account, and your GPS + API keys never leave the device.
Free and MIT-licensed.

Other features: on-device price alerts (only fire when you're nearby), a
fuel-station radar, consumption tracker with OCR of the pump/receipt, fuel-cost
calculator, CO2 dashboard, home-screen widget, trip logbook with eco-coaching
(OBD2 or GPS-only). 23 UI languages.

Play Store: https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices
F-Droid: https://fdittgen-png.github.io/tankstellen/fdroid
Source: https://github.com/fdittgen-png/tankstellen

It's brand new and I'm one person — feedback and bug reports very welcome,
especially on data quality in your country. iOS is in TestFlight, App Store
listing coming soon.
```

### r/fossdroid

**Title**:

```
Sparkilo — fuel-price & EV-charging comparison (17 countries), MIT-licensed, libre F-Droid build, no tracking
```

**Body**:

```
I built Sparkilo, a fuel-price + EV-charging comparison app, and it now has a
self-hosted libre F-Droid repo (no proprietary dependencies in that build):

https://fdittgen-png.github.io/tankstellen/fdroid

It uses OFFICIAL open-data fuel feeds across 17 countries (EV charging via Open
Charge Map), routes you to the cheapest station nearby or along a route, and is
genuinely privacy-first: no ads, no tracking, no account, and your GPS + any API
keys never leave the device. MIT-licensed.

Optional cross-device sync ("TankSync") is off by default and uses a Supabase
project YOU self-host — the app generates the SQL to paste into your own
instance, so even sync stays under your control.

Source: https://github.com/fdittgen-png/tankstellen

Solo dev, just launched — happy to take feedback on the libre build, the data
sources, or anything that should change to make it a cleaner FOSS citizen.
```

### r/degoogle

**Title**:

```
Sparkilo — a fuel-price app with no Google dependency: official data, no tracking, no account, libre F-Droid build
```

**Body**:

```
Most fuel-price apps are ad-and-tracker monsters that want an account. I built
Sparkilo as the opposite:

- No ads, no tracking, no analytics SDK, no account.
- Your GPS location and any API keys NEVER leave the device.
- Available as a libre F-Droid build (no proprietary bits):
  https://fdittgen-png.github.io/tankstellen/fdroid
- Open-source, MIT-licensed: https://github.com/fdittgen-png/tankstellen

It compares OFFICIAL government / open-data fuel prices across 17 countries (EV
charging via Open Charge Map) and routes you to the cheapest station nearby or
along your route. Optional sync is self-hosted on a Supabase project you control
(off by default), so there's nothing of yours sitting on my servers — I don't
run any.

Solo dev, just launched. If you spot anything that phones home that shouldn't,
tell me — that's exactly the kind of report I want.
```

### r/opensource

**Title**:

```
Sparkilo — MIT-licensed Flutter app comparing official fuel prices across 17 countries (no ads/tracking/account)
```

**Body**:

```
Sharing a project I just launched: Sparkilo, an MIT-licensed fuel-price and
EV-charging comparison app.

What it does: pulls OFFICIAL government / open-data fuel feeds across 17
countries (EV charging via Open Charge Map) and routes you to the cheapest
station nearby or along a route. Privacy-first — no ads, no tracking, no account,
GPS + keys stay on-device.

How it's built: Flutter, one codebase for Android + iOS, Riverpod + freezed,
Hive local storage. Each country is a pluggable service that normalises its
national feed into a shared model, with fallback chains for flaky feeds. 23 UI
languages. Optional sync is self-hosted Supabase, off by default.

Source: https://github.com/fdittgen-png/tankstellen
F-Droid (libre): https://fdittgen-png.github.io/tankstellen/fdroid

I'm a solo maintainer and this is an early launch. Contributions, issues, and
especially new-country data adapters are very welcome — the per-country service
pattern is designed to make adding a country a fairly contained PR.
```

---

## 4. Lobsters / r/flutterdev

**Title**:

```
Sparkilo — a cross-platform fuel-price app in Flutter: 23 locales, OBD2, on-device OCR (Apple Vision / ML Kit)
```

**Body**:

```
Sharing the dev side of Sparkilo, an open-source (MIT) fuel-price + EV-charging
app I just launched on Android and F-Droid (iOS in TestFlight).

Stack and the bits that were interesting to build:

- Flutter, single codebase for Android + iOS. Riverpod (with codegen) + freezed
  models, Hive for local persistence.
- 17 countries, each a pluggable service that talks to a national open-data fuel
  API and normalises into one shared station model, with fallback chains so a
  flaky feed degrades gracefully instead of blanking the map.
- 23 UI languages via ARB. New strings fan out to every locale through a build
  step + a coverage gate, so en-only additions can't slip through.
- On-device OCR for the pump display and fuel receipts — Apple Vision on iOS,
  ML Kit on Android — behind a platform-plugin seam so the shared code never
  branches on Platform.is*.
- Trip logbook + eco-coaching from either an OBD2 ELM327 adapter (BLE) or
  GPS-only, with the per-trip route coloured by efficiency.
- Privacy by construction: no analytics, no account, GPS + API keys never leave
  the device. Optional cross-device sync is a self-hosted Supabase the user
  controls.

Source: https://github.com/fdittgen-png/tankstellen

Solo project, early days — happy to talk about the per-country service pattern,
the BLE/OBD2 layer, the OCR plumbing, or the ARB fan-out if anyone's curious.
```

---

## 5. Posting tips

- **One subreddit per day**, max. Cross-posting the same link to many subs on the same day is the fastest way to get auto-flagged as spam and shadow-removed.
- **Read each sub's rules first.** Some (e.g. r/androidapps) require a `[App]`/self-promo flair or have a dedicated self-promo thread/day; r/france and others restrict promo. A removed post for a rules violation burns the launch.
- **Don't paste identical text across subs.** The blocks above are deliberately different per community (the localized ones, the FOSS/degoogle angles). Reddit's filters and humans both notice copy-paste.
- **Be a person, not an ad** on Reddit and HN: lead with "I built this / here's why," stay in the comments, answer every reply for the first few hours, and take criticism gracefully — engagement in the first hour drives ranking on both HN and Reddit.
- **Best timing:** HN Show HN lands best weekday mornings US Eastern (Tue–Thu, ~8–10am ET). Product Hunt launches at 12:01am PT and runs a 24h cycle — pick a Tue–Thu and be online all day. Reddit posts do well weekday mid-morning in the sub's own timezone (post the localized ones at local morning, not US time).
- **Stagger the launch over ~2 weeks**, not one day: e.g. HN + Product Hunt on day 1, then one Reddit sub per day after, localized subs on weekday mornings in their region. Spreading it out also keeps you sane in the comments.
- **Disclose you're the maker** every time (PH requires it; HN and Reddit expect it). It builds trust and it's the norm for solo-dev launches.
- **Have screenshots / a short screen-recording ready** for Product Hunt and r/androidapps — those communities expect visuals, and a 15-30s clip of "search → cheapest pin → route" converts far better than text.