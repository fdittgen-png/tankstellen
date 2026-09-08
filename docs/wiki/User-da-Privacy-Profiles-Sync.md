# Privatliv, data og synkronisering

Sparkilos privatlivsløfter kan efterprøves, og det er på denne side, du efterprøver dem.

---

## Privatliv som standard

Konkret:

- **Ingen Google Play Services. Ingen Firebase. Ingen Google Analytics. Ingen reklame-id'er.**
- **Ingen tredjeparts-sporings-SDK'er** — den offentlige `pubspec.yaml` har nul analytics-afhængigheder.
- **Ingen konto påkrævet.** Appen er fuldt funktionsdygtig uden.
- **Local-first.** Alt bliver på telefonen, indtil du slår noget til.
- **Samtykke før behandling**, plus en forklaring i klart sprog *før* hver systemanmodning.
- **Open source, MIT.** Projektets egne test fejler, hvis privatlivspolitikken og koden driver fra hinanden.

### Hvad der faktisk forlader telefonen

| Data | Til hvem | Hvornår | Kan undgås? |
|---|---|---|---|
| Søgekoordinater eller en regionskode | Dit lands officielle prisleverandør | Ved hver live-søgning | Søg på postnummer i stedet for GPS |
| Kortudsnit + IP | Udviklerens EU-fliseproxy, som henter fra OpenStreetMap | Brug af kortet | Slå proxyen fra — så ser OpenStreetMap din IP direkte |
| Din IP | logo.clearbit.com | Kun hvis du slår internetlogoer til | Lad den være slået fra (standard) |
| Rensede nedbrudsspor | Sentry | Kun med *Fejlrapportering* slået til | Fra som standard |
| Dine synkroniserede rækker | Den TankSync-database du har valgt | Kun med TankSync slået til | Fra som standard |

**Din identitet indgår aldrig i en prisforespørgsel**, og udvikleren driver ingen server, der gemmer dine søgninger.

---

## Hvem er dataansvarlig

Det afhænger fuldstændig af, hvordan du bruger TankSync:

| Tilstand | Dataansvarlig |
|---|---|
| **Uden TankSync** *(standard)* | **Kun dig.** Intet ligger på nogen server, udvikleren driver |
| **Dit eget Supabase-projekt** | **Dig** — udvikleren ser det aldrig |
| **En gruppes database** | **Gruppens ejer**, som driver det projekt |
| **Sparkilo Community** | **Udvikleren, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)); Supabase, Inc. er databehandler; hostet i EU (AWS eu-central-1, Frankfurt) |

Appen oplyser det gældende tilfælde **før** du forbinder, og igen i rækken *Synkroniseringstilstand* under **Synkronisering & konto**.

---

## Skærmen Privatliv og data

**Indstillinger → Privatliv og data** er den ene indgang. Den åbner med et oversigtskort efterfulgt af fire emnefelter:

| Linje eller felt | Hvad den fortæller dig |
|---|---|
| *Dine data bliver på denne enhed* / *Dine data synkroniseres også til TankSync* | Hvor dine data fysisk ligger lige nu |
| *Sync: fra* / *Sync: til · anonym konto* / *Sync: til · e-mailkonto* | Om TankSync er forbundet, og med hvilken slags konto |
| *… gemt på denne enhed* | Den samlede lagerplads, appen bruger lige nu |
| **Dine valg** — *n af 5 slået til* | De fem samtykker og de to netværkskontakter |
| **Data på denne enhed** — *størrelse · n kategorier* | Hver kategori, der ligger lokalt, med størrelse og antal |
| **Synkronisering & konto** | TankSync-status, konto, database og synkroniseringshandlingerne |
| **Eksportér eller slet** — *ZIP, JSON, CSV · fejllog (n)* | Eksporterne, fejlloggen og farezonen |

Den tidligere *Privatlivsoversigt* findes ikke længere: dens tællere, synkroniseringsfakta, eksporter og sletteknap ligger nu under disse fire emner. Gamle links og hjemmeskærmswidgets, der pegede på oversigten, åbner i stedet **Privatliv og data**.

---

## Dine valg

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Privatlivskontakter: kortfliseproxy og hentning af mærkelogoer">

*De to netværkskontakter, hver beskrevet som det, den faktisk lækker. De fem samtykker sidder over dem på samme kort.*

Hver række er en kontakt — *« Du kan ændre dine privatlivsvalg til enhver tid. »*

| Række | Hvad den afgør |
|---|---|
| **Adgang til placering** | Find tankstationer i nærheden ud fra din placering. Fra: søg på postnummer |
| **Fejlrapportering** | Send anonyme nedbrudsrapporter for at forbedre appen. Fra som standard — intet uploades nogensinde uden |
| **Cloud-synkronisering** | Synkroniser favoritter og advarsler på tværs af enheder — samtykket bag TankSync |
| **VIN online-afkodning** | Afkod stelnummeret via NHTSA's gratis offentlige tjeneste. Fra: tast køretøjsdata selv |
| **Synkroniser turoptagelser** | Sikkerhedskopiér OBD2 + GPS-ture til TankSync. Nedtonet, indtil *Cloud-synkronisering* er slået til |
| **Hent kortfliser via Sparkilo-proxyen** | Til: kortudsnittet og din IP-adresse når udviklerens EU-server, som henter fliserne fra OpenStreetMap. Fra: fliserne hentes direkte fra tile.openstreetmap.org, som så ser din IP i stedet |
| **Hent mærkelogoer fra internettet** | Fra som standard: medfølgende pladsholdere vises. Til: logoer hentes fra logo.clearbit.com, som ser din IP-adresse |

De to netværkskontakter har en infoknap (*Læs mere*) med den fulde forklaring. Sidefoden noterer *Samtykke givet den … · politikversion …* — det revisionsspor, GDPR beder om — og linker til **Privatlivspolitik** på dit sprog. At trække et samtykke tilbage standser den behandling med det samme; tidligere behandling forbliver lovlig.

---

## Data på denne enhed

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Lagringsforbrug fordelt på kategorier med størrelser">

*Lagerplads, post for post: en bjælke pr. kategori, derefter én række pr. kategori med dens størrelse, dens antal og en prik i bjælkens farve. Tomme kategorier nedtones, ikke skjules.*

Rækkerne under **Lagringsforbrug på denne enhed**: **Favoritter** · **Stationsbedømmelser** · **Søgeprofiler** · **Prisalarmer** · **Prishistorik-stationer** · **Ignorerede stationer** · **Blokerede brugere** · **Gemte ruter** · **Cache** · **Indstillinger** (*API-nøgle, aktiv profil*) · **Total**.

Alt ligger i **krypterede Hive-databaser**; nøglen ligger i Android Keystore / iOS Keychain.

| Boks | Indhold |
|---|---|
| `settings` | Konfiguration, land, sprog, enheder |
| `profiles` | Dine søgeprofiler |
| `favorites` | Gemte stationer med alle deres data |
| `cache` | Cachede API-svar og ruter |
| `priceHistory` | De lokale 30-dages prisregistreringer |
| `price_snapshots` | Snapshots til offline-brug og widgetten |
| `alerts` | Dine advarselsregler |
| `service_reminders` | Servicepåmindelser |
| `obd2Baselines` | Forbrugsbasislinjer pr. køretøj |
| `obd2TripHistory` | Ture: rute, hastighed, sensorer |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Caches over adapterens kapaciteter |

API-nøgler, GitHub-tokenet og TankSync-sessionen ligger i det hardwarebaserede pengeskab, ikke i Hive.

### Cachedetaljer

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Cache-levetider pr. kategori og handlingen ryd cache">

*Feltet **Cachedetaljer** folder sig ud til levetiden for hver cachet klasse — søgninger 5 min, stationsdetaljer 15 min, prisforespørgsler 5 min, favoritdata 30 min, byopslag 30 min, postnummer-geokodning 24 t — og knappen **Ryd cache**.*

Cachen gemmer API-svar til hurtigere indlæsning og offline-adgang. Rydder du den, slettes kun cachede resultater og priser — profiler, favoritter og indstillinger røres ikke; de næste par søgninger er langsommere, intet går tabt. Knappen viser *Cachen er tom* og er deaktiveret, når der intet er at rydde.

### Blokerede brugere

**Blokerede brugere** er den eneste række, der kan trykkes på: den åbner listen over konti, du har blokeret, hver med en knap **Fjern blokering**. Indhold delt af disse brugere skjules på denne enhed; blokering er lokal — den anmelder ikke kontoen.

---

## Tilladelser

| Tilladelse | Hvorfor | Kan afvises? |
|---|---|---|
| **Placering** *(under brug)* | Søgning i nærheden, rutestart, turoptagelse | Ja — brug et postnummer |
| **Placering** *(« Tillad altid »)* | **Kun** OBD2-automatoptagelse, så ruten fortsætter med skærmen slukket | Ja — start ture manuelt |
| **Bluetooth-søgning + -forbindelse** | Parring af adapteren | Ja — OBD2 er valgfrit |
| **Notifikationer** | Prisadvarsler | Ja — advarsler udløses ikke |
| **Kamera** | OCR på enheden af standere, kvitteringer og QR | Ja — tast i hånden |
| **Internet** | Pris- og kortkald | Påkrævet |

Til og med Android 11 kræver systemet **placering** for enhver Bluetooth-scanning — en platformsregel, ikke et valg om sporing. Enhver tilladelse kan siden tilbagekaldes i systemindstillingerne; den tilhørende funktion holder blot op.

---

## Synkronisering & konto

<img src="guide/sync-and-account.jpg" width="340" alt="Synkronisering & konto med TankSync-status, en advarsel om forældet skema og punktet Samtykker">

*Kan nås fra feltet under Privatliv og data og direkte fra indstillingernes rod. Skærmen viser også problemer — her et selvhostet skema, der er forældet og derfor stiltiende undlader at synkronisere nogle tabeller.*

Kræver tilvalg. *Deaktiveret* betyder, at intet gemmes på nogen server, noget sted. Oversigtskortet øverst oplyser fakta:

| Række | Værdi |
|---|---|
| **Status** | *Tilsluttet* eller *Deaktiveret* |
| **Synkroniseringstilstand** | *Sparkilo Community — udviklerens EU-server* · *Delt gruppe — en database, du har tilsluttet dig* · *Selvhostet — din egen Supabase* |
| **Konto** | *Anonym konto, knyttet til denne enhed* eller *E-mailkonto: …* |
| **Bruger-ID** | Din UUID med en kopieringsknap — angiv den i en supporthenvendelse |
| **Databasevært** | Værtsnavnet på den database, du synkroniserer til; nøglen vises aldrig |
| **Del lærte køretøjsprofiler** | Upload forbrugsbasislinjer pr. køretøj, så en anden enhed kan genbruge dem |

### Tre opsætningsformer

1. **Sparkilo Community** — den delte database, udvikleren driver (Supabase, EU/Frankfurt). Din konto er en tilfældig UUID; du kan knytte en e-mail til, så du kan nå den fra en anden enhed. Fællesskabets prisrapporter og offentligt delte bedømmelser kan læses af enhver indlogget bruger.
2. **Dit eget Supabase-projekt** — SQL-skemaet og Edge Functions ligger i arkivet. Du er dataansvarlig og beholder fuldt ejerskab.
3. **En gruppes database** — forbind til et projekt drevet af familie eller venner. Den person er dataansvarlig.

### Opsætning

**Synkronisering & konto → Opsæt cloud-synkronisering.** For Community: scan QR-koden fra wikien, eller indsæt URL og anon-nøgle; for eget eller gruppens projekt: indsæt projekt-URL og anon-nøgle. Begge ligger i det hardwarebaserede pengeskab, og endpoints over ren HTTP afvises blankt.

> **Selvhostere:** efter en appopdatering kan skærmen advare om, at dit **skema er forældet**. Kør den tilbudte opsætnings-SQL igen — ellers fejler synkroniseringen af de nyere tabeller **stiltiende**, hvilket er langt værre end en synlig fejl.

### Handlinger, når du er forbundet

- **Skift til e-mail** — behold data, tilføj login fra andre enheder; UUID'en forbliver den samme. **Skift til anonym** gør det modsatte.
- **Samtykker** — et krydslink til *Dine valg*: samtykkerne til Cloud-synkronisering og tursynkronisering ligger dér, ikke her.
- **Se mine data** — skærmen *Datatransparens* viser de rækker, serveren har om dig; dens knap **Glem alle synkroniserede ture** rydder kun turrækkerne.
- **Tilknyt enhed** — få en anden telefon på samme konto.
- **Slet synkroniserede data** — vælg *Ture*, *Køretøjer*, *Tankninger* eller *Alt* for at fjerne dem fra synkroniseringsdatabasen; de lokale kopier bliver.
- **Del database** — en QR-kode, så familie eller venner kan tilslutte sig din egen eller en gruppes database (tilbydes ikke på Community).
- **Afbryd** — stop synkroniseringen; lokale data beholdes.
- **Slet konto** — fjern alle serverdata permanent og derefter selve kontoidentiteten, inklusive en tilknyttet e-mail. Tilbydes for din egen og gruppens database; på Community bruger du *Slet synkroniserede data → Alt* eller farezonen beskrevet nedenfor.

### Hvad der synkroniseres

Favoritter · prisadvarsler · ignorerede stationer · bedømmelser (med et privatlivsflag pr. bedømmelse: lokal / privat synkroniseret / offentligt delt) · ruter · køretøjer inklusive stelnummer og adapter-id · tankninger og ladelogger · forbrugsbasislinjer · fællesskabs- og indholdsrapporter du indsender.

**Ture er noget for sig.** Tursynkronisering er tilvalg *selv efter* Cloud-synkronisering er slået til — kontakten *Synkroniser turoptagelser* forbliver nedtonet indtil da. På serveren bliver turresuméer, indtil du sletter dem; de detaljerede GPS-prøver ryddes efter 90 dage.

Hver tabel er beskyttet af row-level security: en konto kan kun læse eller slette sine egne rækker. Delte bedømmelser og fællesskabets prisrapporter er de eneste rækker, andre indloggede brugere kan se.

### Konflikter

**Lokalt vinder altid.** Synkronisering tilføjer og opdaterer, men sletter aldrig stiltiende — kun din udtrykkelige sletning udløser en serversletning, som derefter forplanter sig til dine andre enheder.

---

## Eksportér eller slet

Én knap, ét formatark, én rød zone. **Eksportér mine data** åbner *Vælg et format*:

| Format | Hjælpetekst i arket | Hvad du får |
|---|---|---|
| **ZIP-arkiv** | *Alt, inklusive vedhæftninger — til en komplet sikkerhedskopi* | `sparkilo-my-data-<dato>.zip`: én maskinlæsbar JSON pr. kategori — favoritter, advarsler, profiler, ruter, prishistorik, køretøjer, tankninger, ture med GPS-prøver plus én GPX pr. tur, basislinjer, servicepåmindelser, ladelogger, præstationer og din samtykkeregistrering — plus hver servertabel, når TankSync er forbundet |
| **JSON** | *Maskinlæsbart — til en anden app* | `tankstellen-data.json`: kategorierne på enheden i én flad fil, også kopieret til udklipsholderen |
| **CSV** | *Regneark — én tabel pr. kategori* | `tankstellen-data.csv`: én `# table`-blok pr. kategori — favoritter, advarsler, prishistorik og resten — også kopieret til udklipsholderen |

Alle eksporter lander i din **offentlige Downloads**-mappe (*Gemt i mappen Downloads*), så enhver filhåndtering kan finde dem.

**Fejllog** viser, hvor mange rensede spor appen har (*Ingen poster* … *n poster*). **Gem** skriver dem til Downloads til en fejlrapport — ingen e-mails, koordinater, nøgler eller tokens i dem, og intet uploades nogensinde automatisk; **Ryd** tømmer loggen.

**Farezone** — *Sletter permanent alt, hvad appen gemmer på denne enhed. Er sync slået til, slettes dine data på TankSync-serveren også.* **Slet alle mine data** beder om bekræftelse og opremser, hvad der ryger: alle favoritter og stationsdata, alle søgeprofiler, alle prisadvarsler, al prishistorik, alle cachedata, din API-nøgle, alle appindstillinger. Med TankSync forbundet slettes dine serverrækker først; kunne en tabel ikke slettes, **siger appen hvilken** i stedet for at påstå succes. Appen vender derefter tilbage til førstegangsopsætningen. Uigenkaldeligt.

Vil du have et gendannelsesbart øjebliksbillede frem for en dataeksport, så brug **Indstillinger → Sikkerhedskopi & gendannelse** — se [Indstillingsoversigt](User-da-Settings-Reference#sikkerhedskopi--gendannelse).

---

## Dine rettigheder efter GDPR

Hver rettighed i artikel 15–22 har en knap. Ingen supporthenvendelse nødvendig.

- **Indsigt** — *Data på denne enhed* viser hver kategori på enheden; *Se mine data* viser hver række i din TankSync-database.
- **Dataportabilitet** — *Eksportér mine data* som ZIP-arkiv.
- **Berigtigelse** — redigér enhver post på stedet; ændringen synkroniseres, hvis TankSync er slået til.
- **Sletning**
  - *Enhed:* **Eksportér eller slet → Slet alle mine data**.
  - *Server:* **Synkronisering & konto → Slet konto** sletter hver række, du ejer, **i én transaktion** — favoritter, advarsler, ignorerede stationer, pris- og indholdsrapporter, køretøjer, tankninger, ruter, basislinjer, bedømmelser, ture, turdelinger du har givet og modtaget, synkroniseringsindstillinger, sletteregistreringer og din brugerrække — og derefter selve kontoidentiteten, inklusive en tilknyttet e-mail. Kunne en tabel ikke slettes, **siger appen hvilken** i stedet for at påstå succes.
  - *Enkeltposter:* alt kan slettes hver for sig; **Slet synkroniserede data** fjerner ture, køretøjer eller tankninger fra serveren, og **Glem alle synkroniserede ture** rydder kun turrækkerne.
- **Tilbagekald samtykke** — Privatliv og data → Dine valg; behandlingen standser med det samme.
- **Begrænsning / indsigelse** — slå TankSync, tursynkronisering, fliseproxyen eller diagnostik fra; tilbagekald tilladelser i systemindstillingerne.
- **Klage** — til en tilsynsmyndighed, navnlig i dit bopælsland, arbejdsland eller landet for den påståede overtrædelse. Udvikleren vil gerne have chancen for at rette op først: [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

Kan du ikke længere åbne appen, så bed om sletning pr. e-mail fra den adresse, der er knyttet til kontoen. **En anonym konto, der aldrig blev knyttet til en e-mail, kan ikke identificeres af nogen — heller ikke udvikleren — uden den enhed, der oprettede den.** Det er prisen for ikke at bede dig registrere dig.

Fuld tekst: **[Privatlivspolitik v3, 29. august 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**, tilgængelig på alle 23 appsprog. Appen noterer, hvilken version du samtykkede til, og viser politikken igen, hver gang den ændres.

---

**Se også:** [Indstillingsoversigt](User-da-Settings-Reference) · [Sådan fungerer Sparkilo → Hvor dine data bor](User-da-How-It-Works#hvor-dine-data-bor)
**Videre:** [Fejlfinding og FAQ →](User-da-Troubleshooting-FAQ)
