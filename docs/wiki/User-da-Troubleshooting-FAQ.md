# Fejlfinding og FAQ

Nogenlunde ordnet efter, hvor tit det faktisk sker.

---

## Først af alt: tjek din version

<img src="guide/about-1.jpg" width="340" alt="Om-skærmen med version og buildnummer">

*Indstillinger → Om. Angiv **begge** i enhver rapport.*

En stor del af « det virker stadig ikke » er en butiksudrulning, der endnu ikke har nået enheden. Er buildnummeret ældre end udgivelsen med rettelsen, er der intet at fejlsøge.

---

## « Ingen priser fundet »

1. **Tjek landet i din profil.** En tysk profil kalder den tyske API; i Danmark finder den intet. Indstillinger → Profiler & region → Region.
2. **Tyskland: er API-nøglen sat?** Indstillinger → Datakilder & placering — et rødt kryds ved *Brændstofpriser (Tankerkoenig)* er svaret.
3. **Er du offline?** Live-priser kræver et netværkskald. Cachede priser vises stadig, mærket som forældede.
4. **Nedbrud hos leverandøren.** Offentlige åben-data-tjenester går ned indimellem. Prøv igen om et par minutter.
5. **Forældet cache.** Træk for at opdatere, eller tryk på opdateringsikonet.

---

## Tyskland: « API-nøgle mangler » eller « Ugyldig nøgle »

- Hent en gratis nøgle på [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/); det er en UUID.
- Indsæt den i **Indstillinger → Datakilder & placering → Brændstofpriser (Tankerkoenig)**.
- Fejler den stadig? Nøglen kan være hastighedsbegrænset. Nøgler er personlige — offentliggør dem aldrig.

---

## Jeg kan ikke finde søgeknappen

Der findes præcis én: den hævede grønne knap midt i den nederste bjælke. Fra enhver fane åbner den kriteriearket; inde i arket kører et andet tryk søgningen. Ser den grå ud, er du i **rutetilstand uden destination**.

---

## Placeringen er « ukendt », eller GPS'en fanger ikke

- Systemets placering skal være slået til, med **Under brug** givet til appen.
- GPS fanger ikke indendørs. Gå udenfor, eller sæt et **hjemmepostnummer** i profilen og søg på område.
- « Kun omtrentlig placering » — slå præcis placering til i systemets tilladelser.

---

## Ruteberegningen er langsom eller fejler

- OSRM er en gratis offentlig tjeneste og indimellem langsom.
- En korridor gennem flere lande **strømmer delresultater**; banneret nævner de leverandører, der stadig svarer, og du kan trykke på et resultat, før resten når frem.
- Prøv igen — linjen er cachet, så andet forsøg er som regel øjeblikkeligt.

---

## OBD2-adapteren vil ikke forbinde

**Der findes intet under scanningen**

- Tændingen skal være **slået til** (tilbehør eller kørsel). Motoren i gang er fint, tændingen slukket er ikke.
- Adapterens LED skal lyse konstant. Blinkende eller slukket → sæt den i igen.
- Bluetooth slået til på telefonen.
- Android 12+: giv **Bluetooth-søgning** og **Bluetooth-forbindelse**.
- Til og med Android 11: systemet kræver **placering** for at opliste Bluetooth-enheder. Platformsregel, ikke sporing.

**Fundet, men forbindelsen fejler**

- *« Svarer ikke »* — billig klon. Vent 30 s og prøv igen; at starte motoren kortvarigt hjælper ofte.
- *« Protokolinitialisering mislykkedes »* — forfalsket ELM327-chip. Prøv en anden model; vLinker FS er det pålidelige billige valg.
- *« Tilladelse nægtet »* — giv den igen i systemindstillingerne; nogle Android-builds glemmer Bluetooth-tilladelser efter en genstart.

**Forbinder, men falder ud undervejs**

Brug **Nulstil forbindelsen** i køretøjets adapterkort — den gentager håndtrykket uden at glemme parringen. Bliver det ved, så slå **Indstillinger → Kørsel & forbrug → OBD2-fejlfindingslog** til, kør én tur, eksportér XML-loggen og vedhæft den en sag. Slå derefter logningen fra igen.

**Kilometertælleren viser 0 eller er forkert**

Din bil oplyser måske ikke PID A6. Appen prøver igen med PID 31 og producentens tilstand 22. Nogle europæiske biler fra før 2008 oplyser slet ingen kilometerstand over OBD2 — tast den så ind ved hver tankning.

---

## Automatisk optagelse blev ikke udløst

Den kræver alt dette:

1. En adapter **parret til et køretøj**.
2. **Automatisk optagelse** slået til for det køretøj.
3. Placeringstilladelsen **« Tillad altid »**.
4. Bluetooth slået til, og ingen batterioptimering der dræber appen.

Tjek også **starthastighedstærsklen** i køretøjseditoren — en langsom udkørsel fra en p-kælder når den måske aldrig.

> **iOS:** den systemvækning, der kræves til « forbind når adapteren får strøm », findes endnu ikke ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). På iOS starter du ture manuelt.

---

## Mit forbrugstal ser forkert ud

Gå frem i denne rækkefølge:

1. **Åbn turen og læs kortet om OBD2-kommunikationens sundhed.** Ligger dækningen langt under 100 %, blev hullerne fyldt med GPS-skøn, og turgennemsnittet er en blanding, ikke en måling.
2. **Se tankrapporten på fanen Ture.** Står der, at skønnene ligger *n* % over eller under standersandheden, ved appen det allerede og har netop rettet sig selv — forvent bevægelse på de næste ture.
3. **Tjek tankkapaciteten** på køretøjet. En forkert kapacitet giver troværdige, men forkerte rækkevidder i månedsvis.
4. **Tjek dine kilometerstande.** Forbrug er liter ÷ kilometer, og kilometrene kommer udelukkende fra det, du taster.
5. **Tjek om du satte flueben i « Fuld tank ».** Kun fuld-til-fuld-vinduer kan kalibrere noget som helst.
6. **Se præcisionsmærket** på fanen Brændstof. *Lav* betyder, at intet endnu har forankret modellen — tallet er et modeloutput, og det siger det.

Baggrund: [Sådan fungerer Sparkilo → Hvordan en liter bliver til et tal](User-da-How-It-Works#hvordan-en-liter-bliver-til-et-tal).

---

## « Vi fandt en afvigelse på X liter »

Du tankede mere, end dine optagne ture kan gøre rede for. Besvar de to spørgsmål i afstemningen: en manglende eller fejltastet tankning får en **korrektionspost**, en ikke-optaget tur får en **virtuel tur**. Begge kan redigeres bagefter. At lade den stå uløst skævvrider kalibreringen, så to tryk er det værd. Se [Tankbog og forbrug](User-da-Fuel-And-Consumption#når-regnestykket-ikke-går-op).

---

## Billede-i-billede-feltet viser ingen pris

Indflyvningsoverlayet udløses kun, mens **en tur optages** *og* du er inden for indflyvningsradius. For at efterprøve visningen uden at køre: **Indstillinger → Udviklerværktøjer → Test indflyvningsoverlay** skubber en syntetisk tilstand i 30 sekunder.

---

## Prisadvarslernes notifikationer kommer ikke

- Er systemnotifikationer tilladt for appen?
- Batterisparer: Androids aggressive tilstande dræber baggrundsarbejde. Sæt appen til **ikke begrænset**.
- Telefonen kan have været offline i det planlagte tidsrum; tjekket kører igen i næste netværksvindue.
- Prisen har måske simpelthen ikke krydset grænsen.
- Stemplet **Seneste tjek** nederst på advarselsskærmen fortæller, om opgaven overhovedet kører. Gammelt stempel + nul udløsninger = systemet dræber den.

---

## Widgetten på startskærmen står stille

- Android begrænser widget-opdateringer til ca. én hvert 30. minut; det er systempolitik.
- Tryk på **opdateringsikonet på selve widgetten** — det henter priser uden at åbne appen.
- Udseende og indholdsvariant sættes pr. profil under **Indstillinger → Enheder & visning**.

---

## Kortet viser grå eller tomme fliser

- Som regel en svag forbindelse; stryg for at opdatere.
- Bliver det ved, kan fliseserverne være ved at begrænse trafikken — prøv igen om et par minutter.
- Prøv at skifte **Indstillinger → Privatliv og data → Hent kortfliser via Sparkilo-proxyen**; de to veje fejler uafhængigt af hinanden.

---

## Scanning af stander eller kvittering læser intet

- **F-Droid**-builden har slet ingen scanning — tekstgenkendelse på enheden findes kun i Play- / App Store-builds. Tast tankningen i hånden dér.
- Refleks i standerens display er den hyppigste årsag. Skyg for den, stil dig lige foran, og fyld billedet med cifrene.
- Læser den etiketterne, men ikke tallene, så brug **Rapportér scanningsfejl**, så udsnittet kan bruges til at forbedre genkendelsen.

---

## Appen er længe om at starte

Slå **Opstartsspor** til (Funktioner & brugstilstand → Udvikler og eksperimentelt), genstart, og åbn derefter **Udviklerværktøjer**. Vandfaldet navngiver den langsomme fase; eksportér det og vedhæft det en sag.

<img src="guide/developer-tools-2.jpg" width="340" alt="Opstartsspor som vandfald med tider pr. fase">

*Hver bjælke er én initialiseringsfase med sin varighed — en langsom opstart holder op med at være et gæt.*

---

## Appen går ned ved start

- Ryd cachen fra enhedens appindstillinger.
- Bliver det ved, så opret en sag med Android-versionen, telefonmodellen, versionen **og buildnummeret** fra Indstillinger → Om, og den gemte fejllog (appen tilbyder den ved næste start; filen ligger i Downloads).

---

## Hvordan tager jeg backup af mine data?

**Indstillinger → Sikkerhedskopi & gendannelse → Eksportér sikkerhedskopi** skriver en ZIP til Downloads; gendannelse tilbyder flet eller erstat. Vil du have en maskinlæsbar dataeksport i stedet, så brug **Privatliv og data → Eksportér eller slet → Eksportér mine data → ZIP-arkiv**.

TankSync er **ikke** en sikkerhedskopi — det spejler udvalgte kategorier, og ture kun hvis du også slog tursynkronisering til.

---

## Hvordan sletter jeg alt?

- **Enhed:** Privatliv og data → Eksportér eller slet → **Slet alle mine data**. Uigenkaldeligt.
- **Server (TankSync):** slet serversiden **først** — Synkronisering & konto → Datatransparens → **Slet konto** fjerner hver række du ejer i én transaktion og navngiver enhver tabel, der ikke kunne slettes.

Detaljer: [Privatliv, data og synkronisering → Dine rettigheder](User-da-Privacy-Profiles-Sync#dine-rettigheder-efter-gdpr).

---

## Kan jeg bruge appen offline?

Delvis. Favoritter viser deres sidst kendte priser, nyligt viste kortfliser er cachet, og tankninger og ture er helt lokale. At opdage nye stationer kræver et netværkskald.

---

## Hvor blev fanen Brændstof eller Ture af?

De hører til tilstandene **Mellem** og **Fuld**. Er én forsvundet, har en forudindstilling eller en enkelt kontakt slået den fra: Indstillinger → Funktioner & brugstilstand → Forbrug.

---

## Mere hjælp

- **Fejl:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — brug Bug Report-skabelonen og vedhæft den gemte fejllog.
- **Idéer:** Feature Request-skabelonen, eller først [Discussions](https://github.com/fdittgen-png/tankstellen/discussions).
- **Spørgsmål om privatliv:** [privatlivspolitikken](https://fdittgen-png.github.io/tankstellen/privacy-policy/), eller fdittgen@gmail.com.

---

**Tilbage til:** [vejledningens forside](User-da-Home)
