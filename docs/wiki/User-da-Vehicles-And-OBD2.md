# Køretøjer og OBD2

Alt hvad appen ved om *din bil*. Det er denne side, der afgør, om forbrugstallene på alle de andre er til at stole på.

---

## Hvorfor appen overhovedet skal bruge et køretøj

Uden køretøj er Sparkilo en prisfinder. Med ét kan den omregne liter og kilometer til *din* pris pr. kilometer, anslå rækkevidde og — med en adapter — modellere det øjeblikkelige brændstofflow.

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Skærmen Køretøjer og OBD2 med felterne Mine køretøjer og OBD2-adapter">

*Indstillinger → Køretøjer & OBD2. Læg mærke til omfangsmærket på adapterfeltet: adaptere parres **pr. køretøj**, ikke pr. telefon.*

<img src="guide/my-vehicles.jpg" width="340" alt="Køretøjsliste med ét aktivt køretøj">

*Det grønne flueben markerer det aktive køretøj — det, nye tankninger og ture tilskrives.*

---

## Identitet og drivlinje

<img src="guide/vehicle-edit-1.jpg" width="340" alt="Køretøjseditor: navn, valgfrit stelnummer, læs stelnummer fra bilen, drivlinjevælger">

*Kald den, hvad du genkender. Stelnummeret er valgfrit.*

### Stelnummeret, og hvad det giver

At indtaste (eller læse) stelnummeret lader appen slå slagvolumen, cylinderantal, effekt og brændstoftype op — indgangene til forbrugsmodellen. **Læs stelnummer fra bilen** henter det på et sekund via OBD2.

Online-opslag af stelnummeret er et **selvstændigt samtykke** — appen spørger, før den sender noget, og delvis offline-afkodning virker også, hvis du siger nej. Et stelnummer er personoplysning; behandl det sådan.

### Drivlinje

**Forbrænding / Hybrid / Elektrisk** ændrer felterne nedenunder. Forbrænding beder om tankkapacitet, effekt og foretrukket brændstof; elektrisk beder om batteri og stik.

---

## Kapacitet, effekt og flex-fuel

<img src="guide/vehicle-edit-2.jpg" width="340" alt="Forbrændingsblok: tankkapacitet, motoreffekt, foretrukket brændstof, multibrændstof-kontakt, parret adapter">

*Tankkapaciteten er det tal på skærmen, der bærer mest.*

### Hvorfor tankkapaciteten betyder så meget

Den er nævneren i tankmåleren og i rækkeviddeberegningen, og den afgrænser, hvad appen anser for en plausibel tankning. En forkert kapacitet giver måneder med en troværdig, men forkert rækkevidde. Tag den fra instruktionsbogen, ikke fra hukommelsen — producenter angiver ofte en brugbar kapacitet et par liter under den nominelle.

### « Jeg kan tanke forskellige brændstoffer »

Slå til for en flex-fuel-bil (E85/E10, eller hvad du reelt veksler mellem). To ting ændrer sig:

- Tankformularen **spørger hver gang, hvilket brændstof du faktisk hældte på**, i stedet for at antage det foretrukne.
- Statistikskærmen får sammenligningen **pris pr. kilometer pr. brændstof**, den eneste ærlige måde at stille et billigt, tørstigt brændstof op mod et dyrt, nøjsomt.

Lad den være slået fra, hvis du altid tanker samme kvalitet — den tilføjer kun et felt.

---

## OBD2-adapteren

En OBD2-adapter er en lille Bluetooth-dongle i bilens diagnosestik (typisk under instrumentbrættet). **Den er helt valgfri.** Alt virker med GPS alene; adapteren gør skøn til målinger.

### Hvad den ændrer

| Uden adapter | Med adapter |
|---|---|
| Afstand og varighed fra GPS | Det samme, plus motordata |
| Forbrug **modelleret** fra din kalibrering | Forbrug **målt** (eller modelleret langt bedre) |
| Coaching ud fra fart og acceleration | Coaching ud fra omdrejninger, speeder, belastning, gear |
| Præcisionsloft: Mellem | Præcisionsloft: Høj (±3–7 %) |
| Manuel turstart | Automatisk optagelse mulig |

### Hvad appen læser

Hastighed, omdrejninger, motorbelastning %, speederposition %, kølevæske- og indsugningslufttemperatur, tændingsforstilling, brændstofniveau %, kilometertæller (standard-PID A6, med fald tilbage til PID 31 og producentens tilstand 22), og det øjeblikkelige brændstofflow — enten direkte fra **PID 5E**, hvor bilen oplyser det, eller udledt af luftmassemåleren.

> **Den vigtige skelnen:** svarer din bil på PID 5E, er dit forbrug *målt*, og ingen kalibrering anvendes på det. Gør den ikke, er tallet *modelleret* ud fra luftflow og motorparametre, og det er den model, pumpeforstærkningen retter. Køretøjsskærmen fortæller dig, hvilket tilfælde du er i.

### Understøttede adaptere

16 modeller genkendes på Bluetooth-navnet, hver med et kompatibilitetsniveau:

- ✅ **Testet** — bekræftet på rigtig hardware af vedligeholderen.
- 👤 **Brugerbekræftet** — mindst én bruger melder, at den virker.
- ⚠️ **Teoretisk** — profil og transport er rigtige, men ingen ende-til-ende-bekræftelse endnu.

| Adapter | Transport | Noter | Niveau |
|---|---|---|---|
| vLinker FS | Klassisk BT | Dominerende EU-model; anbefales | ✅ |
| vLinker BM-Android | Klassisk BT | Klassisk SPP-søskende til BM+ | ✅ |
| SmartOBD (BLE) | BLE | Generisk ELM327 v1.5-klon | 👤 |
| SmartOBD (Classic) | Klassisk BT | Samme mærke, SPP-variant | 👤 |
| vLinker FD / MC | BLE | Nordic UART FFF0-familien | ⚠️ |
| OBDLink MX+ | BLE | Scantools topmodel | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | ELM327 v2.1 BLE-klon | ⚠️ |
| vLinker BM+ | BLE | Kun-BLE-søskende | ⚠️ |
| Konnwei KW902 | Klassisk BT | ELM327 v1.5-klon | ⚠️ |
| Vgate iCar Pro | BLE | Kun BLE-varianten | ⚠️ |
| Panlong WiFi | — | Kun WiFi, medtaget så fejlparringer navngives | ⚠️ |
| BAFX 34t5 | Klassisk BT | Gammel ELM327 v1.5 | ⚠️ |
| Generic ELM327 (BLE) | BLE | Opsamlingsprofil til BLE FFF0-kloner | ⚠️ |
| Generic ELM327 (Classic) | Klassisk BT | Opsamlingsprofil til SPP-kloner | ⚠️ |

Adaptere, der ikke er på listen, falder tilbage på den generiske ELM327-profil og virker som regel. Virker din — eller gør den ikke — så [opret en sag](https://github.com/fdittgen-png/tankstellen/issues), så niveauet kan rettes.

### Parring

1. Tændingen **slået til** (motoren i gang er fint, tændingen slukket er ikke).
2. Sæt adapteren i; dens LED skal lyse konstant.
3. Åbn køretøjet og tryk på adapterafsnittet, eller start en tur.
4. Giv **Bluetooth-søgning** og **Bluetooth-forbindelse** (Android 12+). Til og med Android 11 kræver systemet i stedet **placering** for at scanne Bluetooth — en systemregel, ikke et valg om sporing.
5. Vent ca. 8 sekunder på scanningen og tryk på din adapter. Appen kører ELM327-håndtrykket og bekræfter.

Efter parring hører adapteren til det køretøj. **Nulstil forbindelsen** gentager håndtrykket uden at glemme enheden — det første at prøve efter et afbrud undervejs. **Glem adapteren** rydder parringen helt.

---

## Basisliniekalibrering — at lære appen din bil

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Basisliniekalibrering: parret adapter, fremdrift 210/270, advarsel om manglende situationer og bjælker pr. situation">

*210 prøver ud af 270. To kørselssituationer er stadig tomme, og appen siger det i stedet for at foregive fuldstændighed.*

Hver OBD2-prøve arkiveres i en kørselssituation: **tomgang, stop & go, by, motorvej, deceleration, stigning / lastet, koldstart, vedvarende belastning / trailer, frihjul**. Gennemsnittene pr. situation danner køretøjets basislinje — den model, der giver et plausibelt L/100 km, når adapteren mangler, eller en PID holder op med at svare.

<img src="guide/vehicle-edit-4.jpg" width="340" alt="Prøvebjælker pr. situation, nulstil basislinjen og vælgeren for kalibreringstilstand">

*Situationer med nul prøver er dem, der falder tilbage på standardværdier. Her to: deceleration og trailerkørsel.*

### Regelbaseret eller fuzzy

<img src="guide/vehicle-edit-5.jpg" width="340" alt="Kalibreringstilstand regelbaseret eller fuzzy, nulstillingshandlinger og servicepåmindelser">

*Fuzzy er standard og det bedste valg for næsten alle.*

- **Regelbaseret** tildeler hver prøve til præcis én situation. Forudsigeligt, men den skifter fra prøve til prøve mellem « by » og « motorvej », når du kører nær grænsen — omkring 60 km/t for eksempel.
- **Fuzzy** fordeler hver prøve på alle situationer efter, hvor godt den passer. Glat netop dér, hvor den regelbaserede springer, til gengæld sværere at følge prøve for prøve.

### De to nulstillingsknapper — og hvad de reelt gør

- **Nulstil volumetrisk virkningsgrad** kasserer den lærte η_v og genopretter standardværdien 0,85. η_v er en parameter i speed-density-modellen, der anslår luftflow, når der ikke er en luftmassemåling. Nulstil den kun efter et mekanisk indgreb; et mærkeligt tal skyldes oftere et dækningsproblem. Biler, der oplyser flowet direkte (PID 5E), bruger den slet ikke.
- **Nulstil fra køretøjsdatabasen** henter slagvolumen, effekt og standardværdier fra det indbyggede katalog igen og kasserer dine manuelle værdier.
- **Nulstil basislinjen pr. situation** (i basislinjekortet) sletter hver lært prøve og sender dig tilbage til koldstartsstandarder, indtil nye ture fylder profilen.

Ingen af dem rører **pumpeforstærkningen**, som læres af fuld-til-fuld-tankvinduer og lever uden for OBD2-modellen — se [Sådan fungerer Sparkilo → Hvordan en liter bliver til et tal](User-da-How-It-Works#hvordan-en-liter-bliver-til-et-tal).

---

## Servicepåmindelser

Nederst i køretøjseditoren: forudindstillinger for **olieskift (15 000 km)**, **dæk (20 000 km)** og **syn (30 000 km)**, plus egne påmindelser. De tæller mod de kilometerstande, du indtaster med dine tankninger, så de rykker kun frem, hvis du noterer kilometertælleren — hvilket kalibreringen alligevel har brug for. Én vane, to gevinster.

---

## Automatisk optagelse

Med en parret adapter kan optagelsen klare sig helt uden dig:

- **Automatisk parring** — den første manuelle parring skaber sammenkoblingen adapter ↔ køretøj.
- **Automatisk forbindelse** — så snart systemet ser den parrede adapter sende, forbinder appen igen i baggrunden.
- **Automatisk start** — forbundet og over hastighedstærsklen begynder turen.
- **Automatisk gemning** — adapteren mister strøm med tændingen, og efter den indstillede forsinkelse afsluttes og gemmes turen.

Automatisk optagelse kræver placeringstilladelsen **« Tillad altid »**, fordi Android kun lader en baggrundstjeneste sende GPS med den. Den tilladelse bruges udelukkende hertil; søgning og kortcentrering bruger den almindelige forgrundstilladelse.

> **Platformbemærkning.** Automatisk optagelse er verificeret på **Android**. På iOS findes den systemvækning, der kræves til « forbind når adapteren får strøm », endnu ikke ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)); på iOS starter man ture manuelt.

Tærsklerne (starthastighed, gemmeforsinkelse efter afbrydelse) ligger i køretøjseditoren, så en bil til korte ærinder kan udløse anderledes end en pendlerbil.

---

<details>
<summary>Helskærmsopslag — køretøjseditoren, hele siden</summary>

<img src="guide/full/vehicle-edit.jpg" width="420" alt="Fuld køretøjseditor sammensat af fem optagelser">

</details>

---

**Se også:** [Ture og øko-coaching](User-da-Trips-And-Coaching) · [Fejlfinding → OBD2](User-da-Troubleshooting-FAQ#obd2-adapteren-vil-ikke-forbinde)
**Videre:** [Tankbog og forbrug →](User-da-Fuel-And-Consumption)
