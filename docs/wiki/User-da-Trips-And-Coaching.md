# Ture og øko-coaching

Fanen 🛣️ **Ture** er en automatisk logbog plus en kørelærer. Den vises i tilstanden **Fuld**.

---

## Fanen Ture

<img src="guide/trips-tab.jpg" width="340" alt="Fanen Ture: månedssammenligning, tankrapport og turlisten med optageknappen">

*Månedens totaler, den seneste tankrapport, og derefter turlisten. Den flydende knap starter en optagelse.*

Månedssammenligningen kræver mindst tre ture pr. måned, før den sammenligner — med færre er gennemsnittet støj, ikke en tendens.

<img src="guide/trips-map.jpg" width="340" alt="Alle optagne ture på ét kort, farvet pr. tur">

*Kortikonet i bjælken tegner hver optaget tur på ét kort — et års kørsel på et blik, og en nem måde at få øje på de ruter, der er værd at optimere.*

---

## To måder at optage på

### Kun med telefonen

Ingen hardware. Appen registrerer rute, afstand, varighed og hastighed fra GPS, og **modellerer** forbruget ud fra køretøjets kalibrering og din kørsel. Markeret overalt med `~` og en udtrykkelig « GPS-skøn »-note.

Præcisionen starter dårligt og bliver bedre: hvert lukket tankvindue forankrer modellen til standeren igen, så efter en håndfuld fulde tanke lander en ren GPS-tur typisk inden for få procent. Indtil da er den mærket som foreløbig, ikke pyntet.

### Med en OBD2-adapter

Motordata i stedet for udledning: reelt flow (målt hvor bilen oplyser PID 5E), omdrejninger, belastning, speeder. Ingen indlæringsperiode for forbruget, og coachingen får adgang til signaler, GPS ikke kan se — gear, omdrejninger, motorbelastning. Opsætningen står i [Køretøjer og OBD2](User-da-Vehicles-And-OBD2#obd2-adapteren).

> **Optagelse kræver aldrig en adapter.** Slå *Kræv OBD2 til turoptagelse* fra (Funktioner & brugstilstand → Forbrug) for at optage med GPS alene; coachingen er reduceret, ikke fraværende.

---

## Mens du kører

### Live-tallet

Hovedtallet er dit gennemsnit **over de seneste sekunder** — brændt brændstof ÷ tilbagelagt afstand, den samme størrelse som en kørecomputer viser — mærket *« Seneste 5 s »*. I stilstand skifter det til L/t, fordi L/100 km er udefineret ved nul hastighed.

Skift vinduet under **Indstillinger → Kørsel & forbrug → Vindue for live-forbrug** (3 / 5 / 10 / 30 s). Et **længere vindue er roligere og lettere at læse under kørsel**; et kortere reagerer hurtigt nok til at lære dig, hvad din højre fod koster. Enheden følger **Enheder & visning → Forbrugsenhed** overalt: banner, billede-i-billede-felt, iOS Live Activity og turgennemsnit.

### Liggende er « bilvisningen »

Drej telefonen på tværs under en optagelse, og skærmen bliver et layout uden berøring, læsbart på et blik: til venstre det store øjeblikkelige forbrugstal med coaching-vinket nedenunder (*løft foden* / *forudse* / *acceleration blødt* på GPS, *skift op* / *skift ned* / *slip speederen* på OBD2) og en stor hastighed; til højre radarkortet for nærmeste station over et 2×2-gitter — **Afstand · Gns. · Tid · Forbrugt brændstof**.

Intet ruller, og intet er småt. Telefonen i holderen, og du rører den ikke igen.

### Billede-i-billede

Skrump appen til et flydende felt og hold din navigation ovenpå. Feltet tilpasser sig konteksten:

| Situation | Stort tal | Sekundær linje |
|---|---|---|
| OBD2 forbundet | live L/100 km (L/t i tomgang) | afstand · tid |
| Kun GPS, i bevægelse | afstand indtil nu | tid |
| Under opstart | forløbet tid | — |

### Indflyvningsoverlayet

Kører du ind i den indstillede radius omkring en station, skifter feltet til en stor visning af **brændstofprisen** — pris for din kvalitet, mærke, afstand, læsbart på et blik.

Hvilken station der låses fast, sættes i **Indstillinger → Kørsel & forbrug → Indflyvningsoverlay**: **nærmeste** (den første hvis radius du krydsede) eller **billigste i radius**. Når du kører ud, bliver prisvisningen stående i fem sekunders nåderum, så en tur forbi en stander ikke får feltet til at blinke.

**Prøv det uden at køre:** Indstillinger → Udviklerværktøjer → **Test indflyvningsoverlay** skubber en syntetisk tilstand i 30 sekunder.

---

## At læse en tur

<img src="guide/trip-detail-1.jpg" width="340" alt="Turresumé: dato, køretøj, adapter, afstand, varighed, forbrug, brændstof, pris og hastigheder">

*Resuméet oplyser sin egen oprindelse — køretøj, adapter, og et **GPS-spor**-mærke på afstanden, så du ved, hvor kilometrene kommer fra.*

<img src="guide/trip-detail-2.jpg" width="340" alt="Rutekort farvet efter effektivitet med signatur og kortet over de største brændstofslugere">

*Ruten er farvet efter effektivitet — grøn under 6 L/100 km, ravgul til 10, rød derover. Hvor brændstoffet blev af, geografisk.*

Den farvelægning er appens mest handlingsanvisende visning: den lægger de dyre dele af din daglige rute på et kort. En rød strækning der gentager sig hver dag, er et kryds, en bakke eller en vane, der er værd at ændre.

<img src="guide/trip-detail-3.jpg" width="340" alt="Vælgeren « hvordan gik turen », hvor brændstoffet blev af, fordelinger af speeder og omdrejninger">

*Tre blokke: din egen dom, brændstoffordelingen, og hvordan du faktisk belastede motoren.*

- **« Hvordan gik denne tur? »** — *Blød / Moderat / Aggressiv*. Dit svar bruges til at kalibrere kørestilstærskler mod virkelige ture, ikke til at give dig karakter.
- **Hvor dit brændstof blev af** — liter tilskrevet hårde accelerationer over for normal kørsel. Små absolutte tal på en kort tur; det er forholdet, der tæller.
- **Speederposition** og **motoromdrejninger** som fordelinger — den andel af turen der er tilbragt i frihjul, let, fast og fuld gas, og i hvert omdrejningsbånd. En høj andel over 3000 o/min på pendlerturen betyder, at du skifter op for sent, og det koster.

<img src="guide/trip-detail-4.jpg" width="340" alt="GPS-samplingsdiagnostik og det sammenfoldede kort om OBD2-kommunikationens sundhed">

*To diagnoser: hvor komplet GPS-sporet er, og hvordan adapteren opførte sig.*

<img src="guide/trip-obd2-health.jpg" width="340" alt="Udfoldet OBD2-kommunikationssundhed: målinger, dækning, adapter, protokol, varighed, årsag til sessionsafslutning">

*Udfoldet forklarer OBD2-kortet sig selv i klart sprog.*

**Læs dette kort, før du tvivler på et forbrugstal.** Det oplyser, hvor mange målinger der bar motordata, den resulterende **dækningsprocent**, adapteren og den forhandlede protokol, sessionens varighed, hvorfor den sluttede (`userStopped`, en afbrydelse, en procesdød), og den afgørende linje: *« Forbrugsværdierne kommer fra adapteren, ikke fra GPS-skøn. »* Ligger dækningen langt under 100 %, blev hullerne fyldt med GPS-skøn, og turens gennemsnit er en blanding.

<img src="guide/trip-detail-5.jpg" width="340" alt="Grafer: hastighed, brændstofflow og motoromdrejninger over turen">

*Hastighed, flow og omdrejninger på en fælles tidsakse — de tre kurver der forklarer ethvert forbrugstal.*

<img src="guide/trip-detail-6.jpg" width="340" alt="Grafer: omdrejninger, motorbelastning, speederposition og kølevæsketemperatur">

*Motorbelastning og speeder side om side viser forskellen mellem at lade motoren arbejde og blot at skrue den op i omdrejninger.*

<img src="guide/trip-detail-7.jpg" width="340" alt="Grafer: kølevæske, højde siden start, indsugningslufttemperatur og tændingsforstilling">

*Højden betyder mere, end de fleste tror: en stigning forklarer et forbrugsudsving, der ellers ville ligne dårlig kørsel.*

Handlingerne **del** og **slet** ligger i topbjælken. Deling eksporterer turen inklusive GPX-spor.

---

## Kørescore og coaching

Med en adapter scores hver tur op til 100 — sammensat af tomgang, hårde accelerationer, hårde opbremsninger, tid ved høje omdrejninger, fuld gas, for lave omdrejninger, rykvis kørsel, vedvarende høj fart, aggressiv pedalbrug og fed blanding. Opdelingen navngiver den adfærd, der kostede mest, så scoren er en diagnose frem for en karakter.

Kortet **største brændstofslugere** laver det om til sætninger, du kan handle på — og skriver *« Ingen nævneværdig ineffektivitet — bliv ved! »*, når der ikke er noget at rette, i stedet for at opfinde en klage.

Coaching kan også leveres undervejs:

- **Øko-coaching i realtid** — en let vibration plus et vink på skærmen, når du accelererer hårdt ved marchhastighed.
- **Talt kørecoaching** — samme råd læst højt, så øjnene bliver på vejen.
- **Glide-coach (beta)** — en diskret vibration, når du bør lette foden før et rødt lys, ud fra lyssignaler i OpenStreetMap. **Fra som standard: risiko for distraktion**, og den kræver netværk for at hente signalerne i dit område.

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching-kontakter, belønninger, loyalitetskort, præstationer og OBD2-fejlfindingslog">

*Indstillinger → Kørsel & forbrug. Præstationer og scorer kan skjules i hele appen, hvis gamification ikke er noget for dig.*

---

## CO₂-oversigten

<img src="screenshots/carbon-dashboard.png" width="340" alt="CO2-oversigt: pris og CO2 fordelt på turlængde og hastighedsbånd">

*Pris og CO₂ ud fra de samme målte liter, opdelt på to måder.*

- **Efter turlængde** — korte ture er som regel de dyreste pr. kilometer, fordi en kold motor drikker. At se det gjort op er dét, der får folk til at samle ærinder.
- **Efter hastighedsbånd** — hvor meget brændstof der går til at kravle i byen frem for at rulle på motorvejen.

Den bygges udelukkende på data på din telefon og slås til under Funktioner & brugstilstand → Forbrug.

---

## Eksport og diagnostik

- **Del** en enkelt tur (resumé + GPX).
- **Eksportér kørselsanalysesporet** — turens GPS-KPI'er, score og læringer som JSON, med et fritekstfelt til at beskrive, hvordan kørslen faktisk føltes. At dele det tilbage hjælper med at kalibrere kørestilstærskler mod virkelige ture. Udviklertilstands-funktion.
- **Eksportér mine data → ZIP-arkiv** under Privatliv og data → Eksportér eller slet indeholder hver tur og én GPX pr. tur.

---

<details>
<summary>Helskærmsopslag — turdetalje, hele siden</summary>

<img src="guide/full/trip-detail.jpg" width="420" alt="Fuld turdetaljeside sammensat af otte optagelser">

</details>

---

**Se også:** [Køretøjer og OBD2](User-da-Vehicles-And-OBD2) · [Tankbog og forbrug](User-da-Fuel-And-Consumption)
**Videre:** [Prishistorik og forudsigelser →](User-da-Price-History-And-Predictions)
