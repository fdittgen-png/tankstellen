# Elopladning

Sparkilo er ikke kun til forbrændingsbiler. Ladepunkterne kommer fra [OpenChargeMap](https://openchargemap.org), verdens største åbne, fællesskabsdrevne register.

---

## Slå det til

To uafhængige kontakter, begge under **Indstillinger → Funktioner & brugstilstand → Søgning og kort**:

- **EV-opladning** — selve funktionen (søgning, detaljesider, favoritter).
- **Vis ladepunkter** — om ladepunkter optræder i resultater og på kortet.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Kontakter i gruppen Søgning og kort inklusive EV-opladning og Vis ladepunkter">

*Du kan vise tankstationer, ladepunkter eller begge dele. Kører du kun elektrisk, slår du typisk **Vis tankstationer** fra.*

Opret derefter et køretøj under **Indstillinger → Køretøjer & OBD2 → Mine køretøjer → Tilføj**, og vælg **Elektrisk** som drivlinje. Et elkøretøj bærer batterikapacitet (kWh), maksimal AC- og DC-ladeeffekt (kW) og dets stik (Type 2, CCS, CHAdeMO, Tesla, Schuko, Type 1, husstandsstik). Søgninger begrænses så til de ladepunkter, din bil reelt kan bruge.

---

## Sådan virker dataene

<img src="guide/data-sources-location.jpg" width="340" alt="Nøglefelt til EV-opladning med appens delte standardnøgle">

*Indstillinger → Datakilder & placering. Feltet **EV-opladning (OpenChargeMap)** rummer allerede en delt nøgle: opladning virker uden opsætning.*

Appen forespørger OpenChargeMaps POI-API live for det område, du kigger på, og cacher resultatet, så det overlever offline.

### Hvorfor du måske vil have din egen nøgle

Den indbyggede nøgle deles af alle Sparkilo-brugere og er derfor hastighedsbegrænset som en fælles pulje. En personlig nøgle giver dig din egen kvote og lader OpenChargeMap se reel brug af sine data. Den er gratis:

1. Opret en konto på [openchargemap.org](https://openchargemap.org).
2. Åbn **My Profile → My Apps**.
3. **Register an Application**, beskriv den kort, og API-nøglen (en UUID) udstedes straks.

Indsæt den i EV-feltet. Den ligger i samme hardwarebaserede pengeskab som den tyske prisnøgle, forlader aldrig enheden og sendes kun til OpenChargeMap. Ryd feltet for at vende tilbage til den delte nøgle.

### Nødløsningen der ligner en fejl

Kan OpenChargeMap slet ikke nås, tegner appen et lille **indbygget demodatasæt** i stedet for et tomt kort. Ser du den samme håndfuld generiske ladepunkter i hver by, er det nødløsningen, der fortæller dig, at live-hentningen slog fejl — tjek forbindelse eller nøgle, og stol ikke på de nåle.

### Giv tilbage

OpenChargeMap vedligeholdes af sit fællesskab. Et manglende eller forkert ladepunkt rettes på [openchargemap.org](https://openchargemap.org), ikke i denne app — og rettelsen når derefter enhver OCM-baseret app, inklusive denne, ved næste hentning.

---

## Søg

<img src="screenshots/map-ev-charging.png" width="340" alt="Kort i EV-tilstand med filterchips pr. stik">

*EV-knappen i kortets bjælke skifter nålene fra brændstof til opladning. Nålefarven følger effekten: lyseblå AC, mørkeblå DC.*

Vælg typen **EV** i kriteriearket og kør en radiussøgning. Tilgængelige filtre: stiktyper, minimum kW, og kun aktuelt ledige punkter dér, hvor operatøren melder live-status.

---

## Et ladepunkts detaljeside

- **Stik** — type, antal og maksimal effekt for hvert
- **Takst** — pr. kWh når operatøren offentliggør den (mange gør ikke)
- **Netværk** — Ionity, Fastned, Tesla, …
- **Tilgængelighed** — i realtid når den meldes
- **Faciliteter** — mad, toiletter, indkøb (betyder mere, når man holder i 30 minutter)
- **Åbningstider** — 24/7 eller operatørbestemt
- **Anmeldelser** — fra OpenChargeMap-bidragydere

---

## Favoritter og registrering

Ladepunkter kan gøres til favoritter præcis som tankstationer; på tværs og på tablet vises favoritter og advarsler side om side. Favoritkortet viser **kW pr. stik**, **hvor mange der er ledige lige nu** og **stiktyperne**.

Prisadvarsler nytter kun lidt ved opladning, da de fleste operatører bruger faste kWh-takster. Ladesessioner registreres som tankninger: **fanen Brændstof → Tilføj**, med kWh i stedet for liter — de fodrer den samme statistik over pris pr. kilometer som forbrændingstankninger.

---

## Over grænser

Ved opladning findes der bevidst **intet landefilter**. Kører du fra Tyskland til Frankrig, ser du begge landes infrastruktur på samme kort. Brændstofpriser er nationale datasæt; opladning er ét verdensomspændende datasæt, så reglen « én profil pr. land » gælder ikke her.

---

**Se også:** [Find tankstationer](User-da-Finding-Stations) · [Tankbog og forbrug](User-da-Fuel-And-Consumption)
**Videre:** [Køretøjer og OBD2 →](User-da-Vehicles-And-OBD2)
