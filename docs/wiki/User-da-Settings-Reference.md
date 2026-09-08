# Indstillingsoversigt

Hver skærm i indstillingstræet og — mere brugbart — **hvad hver kontakt koster dig** i batteri, data, præcision eller privatliv.

---

## Formen på det hele

Indstillinger er et **træ med to niveauer**: en rod af emnefelter, én skærm pr. emne, og en nøgleordssøgning på tværs af dem alle.

<img src="guide/settings-root-1.jpg" width="340" alt="Indstillingsroden, øverste halvdel: søgefelt og de første seks emnefelter">

*Skriv « radius », « OBD2 » eller « tema » i søgefeltet, og det rette felt dukker op — du behøver aldrig huske, hvilket emne der ejer en parameter.*

<img src="guide/settings-root-2.jpg" width="340" alt="Indstillingsroden, nederste halvdel: funktioner, datakilder, synkronisering, privatliv, sikkerhedskopi, avanceret">

*Tolv emner i alt. Sådan når du dem: tandhjulet øverst til højre på hovedskærmene.*

Tre designregler gør træet forudsigeligt:

1. **Ét hjem pr. parameter.** Intet optræder to steder; krydshenvisninger peger på den ene ejer.
2. **Omfangsmærker.** Et felt mærket *denne profil*, *alle profiler* eller *dette køretøj* fortæller på forhånd, hvor langt en ændring rækker.
3. **Ærlige tomme tilstande.** Et afsnit, hvis funktion er slået fra, siger det og linker til kontakten i stedet for at skjule sig.

---

## Profiler & region

*Land, sprog, brændstof, søgeradius, ruter · omfang: denne profil*

<img src="guide/profile-edit-1.jpg" width="340" alt="Profileditor: navn, foretrukket brændstof, standardradius">

*Det foretrukne brændstof udledes af standardkøretøjet. Vil du vælge brændstof direkte, så fjern køretøjet fra profilen.*

| Indstilling | Konsekvens |
|---|---|
| **Profilnavn** | Kosmetisk, men det er dét, profilchippen viser |
| **Foretrukket brændstof** | Prisen i overskriften på hvert kort; standard for advarsler; hvad rutesøgningen optimerer for |
| **Standardradius** | Større = flere resultater og langsommere søgninger |

<img src="guide/profile-edit-2.jpg" width="340" alt="Ruteplanlægning: segment, maksimal omvej, mindste besparelse, valg pr. segment, kandidater">

*Rutens standardværdier. **Kandidater pr. prøvepunkt** bytter grundighed for hastighed på lange korridorer.*

<img src="guide/profile-edit-3.jpg" width="340" alt="Visning og stationer, noternes synlighed, startskærm, overlayets radius">

*Tre adskilte ting værd at kende.*

- **Undgå motorveje** ændrer selve den beregnede rute, så motorvejsrastepladser holder op med at være kandidater — normalt en besparelse, da motorvejsbrændstof er det dyreste på enhver korridor.
- **Stationsnoter** — *Lokal* (kun denne enhed), *Privat* (synkroniseret til din konto) eller *Delt* (synlig for andre brugere). Det er et privatlivsvalg, ikke et lagringsvalg.
- **Startskærm** — hvad appen åbner på: I nærheden, Nærmeste station, Favoritter eller Kort.

<img src="guide/profile-edit-4.jpg" width="340" alt="Indflyvningsoverlayets radius og pristilstand, standardkøretøj, region">

*Overlayets radius og reglen **nærmeste vs billigste i radius** ligger i profilen, så en pendlerprofil og en ferieprofil kan opføre sig forskelligt.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Region: land- og sprogchips">

*Landet afgør dataleverandøren. At ændre det rydder gemte stationsdata.*

<img src="guide/profile-edit-6.jpg" width="340" alt="Sprogchips og feltet til hjemmepostnummer">

*Et **hjemmepostnummer** giver dig områdesøgninger helt uden GPS — den reneste måde at bruge appen på, hvis du aldrig vil dele din placering.*

---

## Køretøjer & OBD2

*Dine biler, tankkapacitet, adapterparring · omfang: dette køretøj*

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Skærmen Køretøjer og OBD2">

*Adaptere parres pr. køretøj, så adapterfeltet sender dig ind i et køretøj i stedet for til en global parringsskærm.*

Den fulde gennemgang — stelnummer, kapacitet, flex-fuel, kalibreringstilstande, basislinje, tærskler for automatisk optagelse, servicepåmindelser — står i [Køretøjer og OBD2](User-da-Vehicles-And-OBD2).

---

## Kørsel & forbrug

*Coaching, belønninger, radaren, fejlfinding · omfang: blandet*

<img src="guide/driving-and-consumption-1.jpg" width="340" alt="Vindue for live-forbrug, indflyvningsoverlay, mine køretøjer, coaching-kontakter">

*De to øverste punkter er dem, du reelt kommer til at justere.*

| Indstilling | Konsekvens |
|---|---|
| **Vindue for live-forbrug** (3/5/10/30 s) | Længere = roligere og lettere at læse under kørsel; kortere = reagerer hurtigt nok til at lære dig, hvad pedalen koster |
| **Indflyvningsoverlay** | Radius, pristilstand, forespørgselsgulv og skærmfastgørelse for den aktive profil |
| **Øko-coaching i realtid** | Let vibration + vink på skærmen ved hård acceleration i marchhastighed |
| **Talt kørecoaching** | Samme råd læst højt — øjnene bliver på vejen |
| **Glide-coach beta** | Haptisk vink før rødt lys ud fra OpenStreetMap-signaler. **Fra som standard — risiko for distraktion**, og den kræver netværk |

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching, loyalitetskort, præstationer, OBD2-fejlfindingslog">

*Belønninger og fejlfinding.*

- **Loyalitetskort** — rabatter pr. liter anvendt i prissammenligningerne, så en nominelt dyrere station med rette kan rangere som billigere for dig.
- **Vis præstationer og scorer** — slået fra skjules alle mærker, scorer og trofæer i hele appen. Intet holder op med at blive målt; det holder op med at blive vist.
- **OBD2-fejlfindingslog** — optager hver session (forbindelse, håndtryk, datatab, genforbindelser) i en eksporterbar XML-log. **Fra som standard**: den skriver løbende og er kun værd at slå til, mens man jager et adapterproblem.

---

## Priser & advarsler

*Advarsler, taleannonceringer, historik, fællesskabsrapporter*

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Priser &amp; advarsler: advarselspunkt, note om taleannonceringer, prisfunktioner">

*Den grå blok med taleannonceringer er en ærlig tom tilstand: den navngiver begge nødvendige kontakter og hvor de findes.*

| Indstilling | Konsekvens |
|---|---|
| **Prisadvarsler** | Åbner advarselslisten; selve funktionen er en kontakt under Funktioner & brugstilstand |
| **Prishistorik** | Lokal 30-dages registrering. Fra = ingen grafer, intet « bedste tidspunkt » |
| **TFLite-prisforudsigelse** | Model på enheden; træk og forudsigelser forlader aldrig telefonen |
| **Fællesskabets prisrapporter** | Kræver TankSync; dine rapporter er synlige for andre indloggede brugere |
| **Scan betalings-QR** | Tilføjer QR-læseren til stationsdetaljerne |

---

## Enheder & visning

*Tema, afstandsenhed, forbrugsenhed, widget · omfang: blandet*

<img src="guide/units-and-display-1.jpg" width="340" alt="Tema, afstandsenhed og forbrugsenhed">

***Forbrugsenheden** slår igennem overalt på én gang — live-banner, billede-i-billede-felt, turgennemsnit, statistik, widget.*

- **Afstandsenhed** følger som standard den aktive profils land (km eller miles).
- **Forbrugsenhed**: *Automatisk* (mpg i Storbritannien og USA, L/100 km ellers), eller udtrykkeligt L/100 km, km/L eller mpg.

<img src="guide/units-and-display-2.jpg" width="340" alt="Widget på startskærmen: farveskema og indholdsvariant">

*Widget-valg bærer mærket **denne profil** og gælder for hver installeret widget, der viser den profil, fra næste opdatering.*

**Indholdsvariant** — *kun aktuel pris*, eller *forudsigende: bedste tidspunkt at tanke* (kræver TFLite-forudsigelsen).

---

## Funktioner & brugstilstand

*Forudindstillinger og hver enkelt kontakt*

<img src="guide/features-and-mode-1.jpg" width="340" alt="Forudindstillingerne Basis, Mellem, Fuld og tilstanden Tilpasset">

*At vælge en forudindstilling **overskriver** hver enkelt kontakt. Har du en håndjusteret blanding, så bliv i Tilpasset.*

Afhængigheder håndhæves, ikke skjules: en kontakt hvis forudsætning er slået fra, forbliver deaktiveret og navngiver forudsætningen.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Gruppen Søgning og kort: ruter, EV-opladning, vis tankstationer, vis ladepunkter, beregner">

*Søgning og kort — herunder om tankstationer og ladepunkter overhovedet vises.*

<img src="guide/features-and-mode-3.jpg" width="340" alt="Gruppen Priser og advarsler: advarsler, historik, TFLite-forudsigelse, betalings-QR, rapporter">

*Priser og advarsler. Prishistorik er forældrefunktionen til forudsigelsen nedenunder.*

<img src="guide/features-and-mode-4.jpg" width="340" alt="Gruppen Tankstationsradar med taleannonceringer og hovedkontakten for talesyntese">

*Radaren, dens taleannonceringer og hovedkontakten **Talefeedback** — er den slået fra, åbner appen aldrig en talemotor.*

<img src="guide/features-and-mode-5.jpg" width="340" alt="Gruppen Forbrug: tilstandsvælger plus analyse, gamification, haptisk coach, glide-coach, GPS-spor, automatisk optagelse">

*Vælgeren **Fra / Brændstof / Brændstof + Ture** er den kompakte form af hele forbrugsstakken.*

| Kontakt | Konsekvens |
|---|---|
| **Forbrugsanalyse** | Analysefanen over tankninger og ture |
| **Gamification** | Kørescorer og optjente mærker |
| **Haptisk øko-coach** | Vibrationsfeedback i realtid under kørsel |
| **Glide-coach** | Øko-råd ud fra OpenStreetMap-lyssignaler — kræver netværk |
| **GPS-turspor** | Gemmer rutepunkterne for hver tur. Fra = mindre database, ingen rutekort |
| **Automatisk optagelse** | Starter en tur, når den parrede adapter forbinder til et køretøj i bevægelse |

<img src="guide/features-and-mode-6.jpg" width="340" alt="Eksperimentelle OEM-PID'er, kræv OBD2, CO2-oversigt, TankSync, basisliniesynkronisering">

*To kontakter her ændrer datakvaliteten frem for brugerfladen.*

- **Eksperimentelle OEM-PID'er** — læser det præcise tankniveau i liter via producentspecifikke PID'er på kompatible adaptere. Bedre tankdata hvor det virker; harmløst hvor det ikke gør.
- **Kræv OBD2 til turoptagelse** — når den er **fra**, optages ture med GPS alene. Coachingen er reduceret (ingen øjeblikkelig L/100 km, færre motorsignaler), men intet er blokeret.
- **Basisliniesynkronisering** — uploader forbrugsbasislinjer pr. køretøj, så en anden enhed kan genbruge dem. Kræver TankSync.

<img src="guide/features-and-mode-7.jpg" width="340" alt="Indtastning og scanning: loyalitetskort, kvitterings-OCR, del kvittering for at importere">

*Indtastning og scanning. Genkendelsen sker på enheden; disse kontakter afgør kun, om genvejene findes.*

<img src="guide/features-and-mode-8.jpg" width="340" alt="Udvikler og eksperimentelt: feedback via GitHub-PAT, udviklertilstand, opstartsspor">

*Udvikler og eksperimentelt — kan roligt blive slået fra, medmindre du rapporterer fejl.*

---

## Datakilder & placering

*API-nøgler, GPS, automatisk profilskift*

<img src="guide/data-sources-location.jpg" width="340" alt="API-nøglefelter og placeringsblokken">

*Et rødt kryds ved brændstofprisnøglen er den sædvanlige grund til, at en tysk søgning kommer tom tilbage.*

| Indstilling | Konsekvens |
|---|---|
| **Brændstofpriser (Tankerkoenig)** | Kun nødvendig for Tyskland. Gratis, pr. bruger, i det hardwarebaserede pengeskab |
| **EV-opladning (OpenChargeMap)** | Valgfri — erstatter den delte indbyggede nøgle med din egen kvote |
| **Automatisk opdatering** | Opdaterer GPS-positionen før hver søgning. Fra = hurtigere søgninger, muligvis fra en forældet position |
| **Automatisk profilskift** | Skifter profil, når du krydser en grænse, så den rette leverandør og kvalitet bruges automatisk |

---

## Synkronisering & konto

<img src="guide/sync-and-account.jpg" width="340" alt="TankSync-status, advarsel om forældet skema, skift til e-mail, samtykker, se mine data">

*Denne skærm bringer også problemer frem — her et selvhostet TankSync-skema, der er forældet og derfor stiltiende undlader at synkronisere nogle tabeller.*

Behandlet fuldt ud i [Privatliv, data og synkronisering → TankSync](User-da-Privacy-Profiles-Sync#tanksync-valgfri-cloud-synkronisering). Det væsentlige:

- **Sparkilo Community / din egen database / en gruppes database** — tre opsætningsformer med tre forskellige dataansvarlige.
- **Anonym → e-mail** — *Skift til e-mail* bevarer dine data og din konto og tilføjer en måde at logge ind fra en anden enhed. En anonym konto findes kun på den enhed, der oprettede den.
- **Forældet skema** — selvhostere skal køre opsætnings-SQL'en igen efter en appopdatering, ellers fejler nyere tabeller stiltiende.

---

## Privatliv og data

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Privatlivskontroller: kortflise-proxy og indlæsning af mærkelogoer">

*To netværksrelaterede privatlivsvalg, hver formuleret som dét, de faktisk afslører.*

- **Hent kortfliser via Sparkilo-proxyen** — *til*: udviklerens EU-server ser dit kortudsnit og din IP og henter fliserne for dig. *Fra*: fliserne kommer direkte fra tile.openstreetmap.org, som så ser din IP. Ingen af mulighederne betyder « intet netværk »; du vælger, hvem du helst vil ses af. F-Droid-versionen bruger aldrig proxyen.
- **Hent mærkelogoer fra internettet** — *fra* som standard; indbyggede generiske logoer bruges. Slået til kommer logoerne fra logo.clearbit.com, som ser din IP.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Lagerforbrug opdelt på kategori med størrelser">

*Lagerplads, specificeret. Cachen er næsten altid den største andel og den eneste, det er sikkert at smide væk.*

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Cache-levetider pr. kategori og handlingen Ryd cache">

*Cache-styring, med levetiden for hver klasse angivet: søgninger 5 min, stationsdetaljer 15 min, prisforespørgsler 5 min, favoritdata 30 min, byopslag 30 min, postnummer-geokodning 24 t.*

<img src="guide/cache-clear-dialog.jpg" width="340" alt="Bekræftelsesdialog for rydning af cache">

*At rydde cachen sletter kun gemte resultater og priser — profiler, favoritter og indstillinger røres ikke. De næste par søgninger er langsommere; intet går tabt.*

---

## Sikkerhedskopi & gendannelse

<img src="guide/backup-restore.jpg" width="340" alt="Punkterne Eksportér sikkerhedskopi og Gendan sikkerhedskopi">

*En komplet ZIP med køretøjer, tankninger, ture og ladelogger.*

**Eksportér sikkerhedskopi** skriver ZIP-filen til dine Downloads. **Gendan sikkerhedskopi** tilbyder *flet* eller *erstat* — flet beholder det, der er på enheden, og tilføjer det manglende; erstat rydder først. Brug det før et telefonskift eller en fabriksnulstilling. TankSync er ikke en sikkerhedskopi: det spejler udvalgte kategorier, ikke alt.

---

## Avanceret og udvikler

<img src="guide/advanced-developer.jpg" width="340" alt="Felt til GitHub-PAT-token og punktet Udviklerværktøjer">

*GitHub-tokenet er valgfrit — uden det deles feedback om en mislykket scanning manuelt i stedet for automatisk at oprette en sag.*

Punktet **Udviklerværktøjer** vises kun, når udviklertilstand er slået til (Funktioner & brugstilstand → Udvikler og eksperimentelt).

<img src="guide/developer-tools-1.jpg" width="340" alt="Udviklerværktøjer: fejllog, testnotifikation, test-advarselspipeline, diagnostik, OCR-tester, ryd caches">

*For almindelige brugere er fejlloggen den nyttige del: **Gem fejllog** skriver rensede spor til Downloads, som du kan vedhæfte en fejlrapport.*

<img src="guide/developer-tools-2.jpg" width="340" alt="Kopiér diagnostik, eksportér dataadgangsspor, opstartsspor som vandfald">

*Opstartssporet er et vandfald af initialiseringsfaser — sådan diagnosticeres en langsom opstart i stedet for at blive gættet.*

<img src="guide/developer-tools-3.jpg" width="340" alt="Test indflyvningsoverlay og buildinfo med version og kanal">

***Test indflyvningsoverlay** skubber en syntetisk tilstand i 30 s, så du kan efterprøve billede-i-billede-prisvisningen uden at køre nogen steder.*

---

## Om

<img src="guide/about-1.jpg" width="340" alt="Om: appversion og buildnummer, forfatter, licens, privatlivspolitik, GitHub, fejlrapport">

***Version og buildnummer** — angiv begge i enhver fejlrapport, og tjek dem først, når en rettelse « ikke virkede » (en butiksudrulning har måske slet ikke nået dig).*

<img src="guide/about-2.jpg" width="340" alt="Om: støttelinks og datakildeangivelser">

*Appen er gratis, open source og reklamefri. Kildeangivelserne for prisdata og kortdata står nederst, som licenserne kræver.*

---

**Se også:** [Sådan fungerer Sparkilo](User-da-How-It-Works) · [Privatliv, data og synkronisering](User-da-Privacy-Profiles-Sync)
**Videre:** [Privatliv, data og synkronisering →](User-da-Privacy-Profiles-Sync)
