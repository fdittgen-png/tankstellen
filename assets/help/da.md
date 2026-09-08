# Sparkilo — Brugervejledning (Dansk)

> *Betal mindre pr. liter. Brænd færre af dem pr. kilometer. Se præcis hvad det kostede.*

Sparkilo er en gratis open source-app, der **sænker driftsomkostningerne for din bil**. Ingen konto, ingen reklamer, ingen sporing, ingen Google Play Services. Alt appen ved om dig bliver på telefonen, indtil du selv slår noget andet til.

*Den skærm du kommer til at bruge mest: live-priser i nærheden, billigst først, med den officielle åbne datakilde navngivet øverst.*

---

## De tre spareniveauer

Hele appen er bygget om én idé: **en bil koster penge på tre uafhængige måder, og hver af dem kræver sit eget værktøj.**

| Niveau | Spørgsmålet det besvarer | Hvor det bor |
|---|---|---|
| **1. Prisen** | *Hvor er brændstof billigst lige nu?* | Søgning, Kort, Favoritter, Advarsler, Ruter |
| **2. Forbruget** | *Hvor mange liter pr. 100 km, og hvorfor?* | Ture, øko-coaching, OBD2 |
| **3. Sandheden** | *Hvad betalte jeg reelt, og er appens skøn ærligt?* | Fanen Brændstof, tankninger, forbrugsstatistik |

Niveau 1 sparer allerede penge og kræver intet ud over appen. Niveau 2 og 3 kræver dine tankninger; niveau 2 bliver markant skarpere med en billig OBD2-adapter. Hvor langt du går, bestemmer du selv — se Sådan fungerer Sparkilo.

---

## Hvad vejledningen indeholder

**Start her**

| Side | Hvad du lærer |
|---|---|
| Kom godt i gang | Installation, samtykke ved første start, land og sprog, brugstilstand, første søgning |
| Sådan fungerer Sparkilo | Begreberne bag det hele: profiler, brugstilstande, én kilde pr. land, hvor dine data bor, hvordan en liter bliver til et tal |

**Find billigt brændstof (niveau 1)**

| Side | Hvad du lærer |
|---|---|
| Find tankstationer | Den centrale Søg-knap, kriterierne, at læse et stationskort, detaljen, kortet, tankstationsradaren |
| Ruteplanlægning | De billigste stop på ruten, grænseoverskridende korridorer, de fire strategier |
| Favoritter og advarsler | Gemte stationer, stations- og zoneadvarsler, hvordan baggrundstjekket faktisk opfører sig |
| Elopladning | Ladepunkter via OpenChargeMap, stik, effektfiltre |
| Prishistorik og forudsigelser | Den lokale 30-dages historik, « bedste tidspunkt at tanke » og hvad algoritmen bevidst *ikke* gør |

**Brug mindre og vid hvad det kostede (niveau 2 og 3)**

| Side | Hvad du lærer |
|---|---|
| Køretøjer og OBD2 | Køretøjsmodellen, tankstørrelsen, flex-fuel, parring, basisliniekalibrering, regler vs fuzzy |
| Tankbog og forbrug | Tankninger, tankniveau, tankrapport, præcisionsniveauer, pris pr. km pr. brændstof |
| Ture og øko-coaching | Optagelse med GPS eller OBD2, turdetaljen, kørescore, CO₂-oversigt |

**Opslag**

| Side | Hvad du lærer |
|---|---|
| Indstillingsoversigt | Hver skærm i træet med to niveauer, med den driftsmæssige konsekvens af hver kontakt |
| Privatliv, data og synkronisering | Samtykker, emnerne under Privatliv og data, TankSync, sikkerhedskopi, dine GDPR-rettigheder |
| Fejlfinding og FAQ | Intet fundet? Adapteren vil ikke forbinde? Widget står stille? |

---

## De 17 understøttede lande

🇩🇪 Tyskland · 🇫🇷 Frankrig · 🇦🇹 Østrig · 🇪🇸 Spanien · 🇮🇹 Italien · 🇩🇰 Danmark · 🇵🇹 Portugal · 🇱🇺 Luxembourg · 🇸🇮 Slovenien · 🇬🇧 Storbritannien · 🇦🇷 Argentina · 🇦🇺 Australien · 🇲🇽 Mexico · 🇰🇷 Sydkorea · 🇨🇱 Chile · 🇬🇷 Grækenland · 🇷🇴 Rumænien

Hvert land betjenes af **sin egen officielle offentlige åbne datakilde** — aldrig af én samlet aggregator. Tyskland kræver en gratis API-nøgle fra [tankerkoenig.de](https://creativecommons.tankerkoenig.de/); alle andre virker med det samme. Hvorfor det betyder noget for det, du ser på skærmen: Sådan fungerer Sparkilo.

Brugerfladen er oversat til **23 sprog** (bg, cs, da, de, el, en, es, et, fi, fr, hr, hu, it, lt, lv, nb, nl, pl, pt, ro, sk, sl, sv) og følger dit systemsprog.

<a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
  <img alt="Hent den på Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/da_badge_web_generic.png" height="80"/>
</a>

---

**Videre:** Kom godt i gang →

> **Om skærmbillederne.** Alle skærmbilleder i denne vejledning kommer fra én enhed, hvor appen kører på **fransk**, mod den franske live-priskilde. Brugerfladen er fuldt lokaliseret — dine skærme har samme opbygning med dit eget sprogs ord.

---

# Kom godt i gang

Ti minutter fra installation til den første sparede krone. Læser du kun én side mere bagefter, så lad det være Sådan fungerer Sparkilo.

---

## 1. Installér

### Google Play (Android)

Installér fra **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — den offentlige produktionsudgivelse.

> **Kommer du fra betaen?** Play bliver ved med at levere beta-builds, når du er tilmeldt den åbne test (listen viser et *(beta)*-mærke). Sådan skifter du til produktion: åbn [Play-siden](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Forlad programmet** → afinstallér → geninstallér.
>
> **Vil du have nyhederne først?** Bliv i betaen — hver build når beta-kanalen før produktion.

### F-Droid (Android, uden Google)

En fuldt **GMS-fri** build udgives via sit eget F-Droid-arkiv (OpenStreetMap-kort, ingen Google-tjenester). I F-Droid: **Indstillinger → Arkiver → +** og tilføj:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Søg derefter efter **Sparkilo**. Har du Play-versionen installeret, så afinstallér den først — anden signeringsnøgle, så den kan ikke opdatere ovenpå.

### Andre veje

- **APK** — fra [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — TestFlight-beta; bed om en invitation via [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues), indtil App Store-siden er live.

**Mindst Android** 7.0 (API 24), mål Android 15. **Mindst iOS** 15.5, mål iOS 18.

Ingen konto, ingen tilmelding, ingen e-mail. Appen kan bruges fuldt ud, så snart installationen er færdig.

---

## 2. Første start — samtykket

Før nogen anden skærm viser appen en **GDPR-samtykkeskærm**. Det er ikke et cookiebanner: den opremser hvert behandlingsformål, og appen fortsætter kun, hvis du accepterer.

*Hvert samtykke, der vises her, optræder igen i Indstillinger → Privatliv og data, med datoen du gav det og den politikversion du så.*

| Punkt | Hvorfor | Hvis du afviser |
|---|---|---|
| **Placering** *(under brug)* | Søgning i nærheden, rutestart, turoptagelse | Søg på postnummer eller vælg et punkt på kortet |
| **Notifikationer** | Kun til prisadvarsler | Advarsler udløses aldrig |
| **Diagnostik** | Nedbrudsspor til Sentry — **fra som standard** | Intet sendes; du kan stadig selv gemme fejlloggen |

Før hver *system*-anmodning (kamera, Bluetooth, notifikationer) viser appen først sin egen korte forklaring, så du ved hvad du siger ja til, inden Android spørger.

Fuld tekst: **[Privatlivspolitik v3, 29. august 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. Land, sprog og dit område

Begge registreres fra dit systemsprog, og begge bor **i profilen** — se Sådan fungerer Sparkilo → Profiler.

*Indstillinger → Profiler & region → redigér profil. Hjemmepostnummeret giver dig områdesøgninger uden nogensinde at udlevere GPS.*

At skifte land **rydder gemte stationsdata**, fordi priser fra den tidligere leverandør ikke gælder for det nye land. Den næste søgning tager derfor et øjeblik længere.

---

## 4. Vælg en brugstilstand

Det er den mest betydningsfulde enkeltindstilling, for den afgør hvor meget app du får.

*Indstillinger → Funktioner & brugstilstand. Start på **Basis**, hvis du kun vil have billigere brændstof; gå op, når du vil vide hvorfor bilen drikker.*

- **Basis** — find billigt brændstof og opladning, favoritter, advarsler, ruter.
- **Mellem** — tilføjer fanen **Brændstof**: registrér tankninger, se reelt forbrug og reelle omkostninger. Ingen hardware nødvendig.
- **Fuld** — tilføjer fanen **Ture**: automatisk optagelse, kørescorer, loyalitetskort. En OBD2-adapter er valgfri selv her — ture optages med GPS alene.

Du kan skifte når som helst, og enhver enkeltkontakt du rører bagefter sætter dig i **Tilpasset**. Den fulde liste, og hvad hver enkelt koster i batteri, data eller privatliv: Indstillingsoversigt → Funktioner & brugstilstand.

---

## 5. Kun Tyskland: den gratis API-nøgle

16 af de 17 lande virker med det samme. Den officielle **tyske** pristjeneste udsteder en nøgle pr. bruger.

*Indstillinger → Datakilder & placering. Et rødt kryds her er grunden til, at en tysk søgning intet giver.*

1. Åbn [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) og bed om en nøgle (kort formular, gratis).
2. Kopiér den — det er en UUID som `00000000-0000-0000-0000-000000000002`.
3. Indsæt den i feltet **Brændstofpriser (Tankerkoenig)**.

Nøglen ligger i det hardwarebaserede pengeskab (Android Keystore / iOS Keychain) og sendes kun til den tyske tjeneste. Feltet **EV-opladning** nedenunder rummer allerede en delt nøgle: ladedata virker uden opsætning.

---

## 6. Den nederste bjælke

*Den hævede grønne **Søg**-knap i midten er den eneste søgeudløser i hele appen.*

- ⭐ **Favoritter** — gemte stationer og dine prisadvarsler
- 🗺️ **Kort** — hver station i nærheden som prisfarvet nål
- 🔍 **Søg** *(midten)* — i nærheden eller langs en rute
- ⛽ **Brændstof** — tank, forbrug, tankninger *(fra Mellem)*
- 🛣️ **Ture** — logbog og coaching *(Fuld)*

Indstillinger er **ikke** en fane: det er tandhjulet øverst til højre på hovedskærmene. På en tablet, eller en telefon holdt på tværs, deler appen sig i to spalter, så liste og kort (eller detalje) ses samtidig.

---

## 7. Din første søgning

*Tryk på **Søg** → kriteriearket åbner forudfyldt fra din profil. Justér, og tryk **Søg** igen.*

Du får en liste sorteret fra billigst (eller efter afstand — dit valg), hvor hvert kort viser pris, tendens, afstand og hvor frisk tallet er. Et tryk åbner detaljen. Den fulde rundtur: Find tankstationer.

**Tip:** tryk på **Gem som standardværdier** nederst i arket, når kriterierne passer — enhver fremtidig søgning starter dér.

---

## 8. To indstillinger værd at ændre på dag ét

*Indstillinger → Enheder & visning. **Forbrugsenhed** står på *Automatisk* (mpg i Storbritannien, L/100 km ellers); vælg udtrykkeligt L/100 km, km/L eller mpg, hvis du foretrækker det.*

Den anden er **Indstillinger → Kørsel & forbrug → Vindue for live-forbrug** (3 / 5 / 10 / 30 s). Den styrer det store live-tal på optageskærmen: et længere vindue er roligere at læse under kørsel, et kortere reagerer hurtigere på din højre fod.

---

## 9. Vælg hvad appen åbner på

**Indstillinger → Profiler & region → Startskærm**: *I nærheden* (øjeblikkelig søgning med dine seneste kriterier), *Nærmeste station*, *Favoritter* eller *Kort*. Vælg den, der svarer til grunden til, at du åbner appen.

---

## 10. Hvor alting ligger

Indstillinger er et træ med to niveauer og en nøgleordssøgning øverst — skriv « radius », « OBD2 » eller « tema », og det rette felt dukker op.

*Tolv emner, ét hjem pr. parameter. Det fulde kort er Indstillingsoversigt.*

---

**Videre:** Sådan fungerer Sparkilo →

---

# Sådan fungerer Sparkilo

Denne side er den mentale model. Alt andet i vejledningen er klikstier; her forklares *hvorfor* stierne ser sådan ud. Ti minutter her sparer dig en time med at rode i indstillingerne.

---

## De tre spareniveauer

En bil koster penge på tre uafhængige måder, og at sænke den ene gør intet for de andre:

1. **Prisen pr. liter** — den standerplads du vælger. Fastlagt af geografi og marked; appens opgave er at vise dig den billigste, du realistisk kan nå.
2. **Literne pr. kilometer** — hvordan du kører og hvad du kører. Appens opgave er at måle det ærligt og vise hvilken vane der koster mest.
3. **Hvad du faktisk betalte** — revisionssporet. Appens opgave er at holde sine egne skøn forankret i virkeligheden i stedet for at lade dem drive.

Niveau 1 virker i samme sekund du installerer. Niveau 2 og 3 kræver input fra dig: som minimum dine tankninger, helst også optagne ture. **Appen foregiver aldrig at vide mere, end den har fået at vide** — derfor ser du præcisionsmærker, dækningsprocenter og « foreløbig »-mærkater i stedet for selvsikre runde tal.

---

## Brugstilstande: appen i din størrelse

Sparkilo kan være en prisfinder på to skærme eller en fuldgyldig kørecomputer. I stedet for at give alle hver eneste kontakt, grupperer appen funktionerne i **brugstilstands-forudindstillinger**.

*Indstillinger → Funktioner & brugstilstand. At vælge en forudindstilling slår hele det tilsvarende sæt til på én gang; rører du bagefter en enkelt kontakt, havner du i **Tilpasset**.*

| Forudindstilling | Du får | Nederste bjælke |
|---|---|---|
| **Basis** | Billigste brændstof og opladning i nærheden, favoritter, prisadvarsler, ruter | Favoritter · Kort · **Søg** |
| **Mellem** | Alt i Basis + manuel tankbog, reelt forbrug og reelle omkostninger | + Brændstof |
| **Fuld** | Alt i Mellem + automatisk OBD2-turoptagelse, kørescorer, loyalitetskort | + Ture |
| **Tilpasset** | Din egen blanding — i samme øjeblik du rører en enkelt kontakt | afhænger |

### Sådan virker det i praksis

En forudindstilling er ikke en tilstand, appen kører i — den er et **navngivet sæt funktionsflag**. Hvert flag viser eller skjuler en funktion uafhængigt, og nogle erklærer forudsætninger: *Basisliniesynkronisering* er slået fra, indtil *TankSync* er tændt, *Taleannonceringer* indtil *Talefeedback* er tændt, *Automatisk optagelse* indtil en adapter er parret. Kortet forklarer hvorfor en kontakt er låst i stedet for stiltiende at ignorere dit tryk.

### Hvad det betyder i praksis

- **At slå en funktion fra fjerner den fra appen, ikke kun fra synet** — også dens baggrundsarbejde stopper. *Prisadvarsler* slået fra stopper det periodiske baggrundstjek; *GPS-turspor* slået fra stopper lagring af rutepunkter.
- **Forudindstillinger overskriver din egen blanding.** Et tryk på *Mellem* skriver hver kontakt om. Har du finjusteret i hånden, så bliv i Tilpasset.
- **Den nederste bjælke skifter form.** Er fanen Brændstof eller Ture forsvundet, har du (eller en forudindstilling) slået *Forbrugsanalyse* eller *OBD2-turoptagelse* fra — det er ikke en fejl.

---

## Profiler: én kontekst, ét sæt standardværdier

En **profil** samler alt, der afhænger af *hvor og hvordan du kører lige nu*: land, sprog, foretrukket brændstof, standardsøgeradius, hjemmepostnummer, ruteparametre, startskærm, synlighed af stationsnoter, radarindstillingerne og standardkøretøjet.

*Indstillinger → Profiler & region → rediger. Det foretrukne brændstof **udledes af dit standardkøretøj** — fjern køretøjet, hvis du selv vil vælge brændstof.*

*Land og sprog ligger i profilen: derfor kan et profilskift med ét tryk skifte både datakilde og brugerfladesprog.*

### Sådan virker det i praksis

Landet gemt i den aktive profil afgør, **hvilken national åben-data-leverandør appen kalder**. At ændre det rydder gemte stationsdata, fordi priser fra den gamle leverandør er meningsløse for det nye land. Det foretrukne brændstof afgør, hvilken pris der er overskriften på hvert kort, hvad en prisadvarsel som standard gælder, og hvad en rutesøgning optimerer for.

### Hvad det betyder i praksis

- **Én profil pr. land du kører i.** « Hjemme — Danmark, Blyfri 95, 10 km » og « Ferie — Frankrig, E85, kort » er to profiler, ikke to omgange indstillinger.
- **Grænseoverskridende rutesøgninger bruger brændstoffet fra hvert lands profil.** Uden en profil til land nummer to har den strækning ingen kvalitet at prissætte, og dens stationer viser `--`.
- **Automatisk profilskift** (Indstillinger → Datakilder & placering) kan skifte profil for dig, når GPS'en registrerer en grænse.
- Indstillingsfelter bærer et **omfangsmærke** — *denne profil*, *alle profiler* eller *dette køretøj* — så du altid ved, hvor langt en ændring rækker.

---

## Én datakilde pr. land

Sparkilo aggregerer ikke. Hvert land forespørges gennem sin egen officielle kilde, og resultatoverskriften navngiver den.

*Linjen under app-bjælken er ikke pynt — den fortæller, hvilken myndighed der har udgivet de priser, og linker til den.*

### Sådan virker det i praksis

| Land | Kilde | Kadence |
|---|---|---|
| Tyskland | Tankerkönig (kræver din egen gratis nøgle) | ~5 minutter |
| Frankrig | Prix-Carburants (gouv.fr) | løbende, pr. station |
| Spanien | Geoportal Gasolineras (MITECO) | daglig samlefil, filtreret på enheden |
| Italien | MIMIT-samlefil | daglig samlefil, filtreret på enheden |
| …og 13 mere | hvert lands eget åben-data-portal | varierer |

### Hvad det betyder i praksis

- **Brændstofkvaliteterne skifter over en grænse.** Spanien sælger E5 og sjældent E10; Frankrig fremhæver SP95-E10; Tyskland udgiver E5, E10 og diesel. Det samme fysiske brændstof bærer tre navne i tre lande.
- **Friskheden er forskellig.** En tysk pris kan være fem minutter gammel, en spansk være gårsdagens udgivelse. Friskhedsmærket på hvert kort fortæller dig hvilken du ser på — stol mere på det end på tallet.
- **Tætheden er forskellig.** Et tyndt nationalt datasæt giver færre stationer i samme radius. Det er landets data, ikke en mislykket søgning.
- **Et `--` i stedet for en pris betyder « denne leverandør oplyser ikke den kvalitet for denne station »** — ikke « stationen sælger den ikke ».

---

## Hvor dine data bor

Sparkilo er **local-first**. Alt appen ved ligger i krypterede databaser på din telefon; nøglen ligger i Android Keystore / iOS Keychain.

*Indstillinger → Privatliv og data → Data på denne enhed viser hver kategori med en reel tæller, så intet om dine data er usynligt for dig.*

Kun fire ting forlader nogensinde telefonen, og tre af dem er valgfrie:

| Hvad der forlader | Hvornår | Valgfrit? |
|---|---|---|
| Søgekoordinater eller en regionskode | Ved hver søgning, til landets priskilde | Nødvendigt for live-priser |
| Kortudsnit + din IP | Kortfliser hentet via udviklerens EU-proxy | Ja — proxy fra, så kommer fliserne direkte fra OpenStreetMap |
| Nedbrudsspor | Kun med *Fejlrapportering* slået til | Ja — fra som standard |
| Dine synkroniserede rækker | Kun med *TankSync* slået til | Ja — fra som standard |

**Din identitet indgår aldrig i en prisforespørgsel.** Det fulde regnskab: Privatliv, data og synkronisering.

---

## Hvordan en liter bliver til et tal

Det er den del, de fleste brændstofapps stille tager fejl af, så den er værd at forstå.

### Standeren er sandheden

Det eneste fysisk sikre tal, appen nogensinde får, er **påfyldte liter ÷ kørte kilometer mellem to fulde tanke**. Alt andet — GPS-skøn, flow udledt af luftmassemåleren, speed-density-modellering — er en model, der kan drive.

Derfor behandler appen hvert **fuld-til-fuld tankvindue** som en kalibreringshændelse:

1. Du registrerer en tankning og sætter flueben i **Fuld tank**. Det lukker det forrige vindue.
2. Appen beregner vinduets *standersandhed*: påfyldte liter ÷ kilometertællerens kilometer × 100.
3. Den sammenligner med det, dens egen estimator producerede over de kilometer, den faktisk optog, med enhver tidligere anvendt korrektion trukket fra.
4. Forholdet mellem de to bliver køretøjets **pumpeforstærkning**, blandet med tidligere vinduer og afgrænset til et fornuftigt interval.
5. Den forstærkning ganger derefter **hver estimeret brændstofrate-gren** — speed-density og MAF — på den næste tur.

Brændstof, som bilen *selv oplyser* over OBD2 (PID 5E / 9D), er målt, ikke modelleret — forstærkningen rører det aldrig.

*Tankrapporten gør kalibreringen synlig: denne tank kørte 6,4 L/100 km ved standeren, optagelserne dækkede 81 % af den, og estimatoren lå 39 % for højt, indtil dette vindue rettede den.*

### Hvorfor dækning ikke skævvrider

At sammenligne de to tal **pr. kilometer** betyder, at de kilometer, ingen optog, simpelthen ikke vejer. En tank, du kun optog en femtedel af, giver stadig et uskævt forhold — den tæller bare mindre i blandingen. Derfor viser appen en dækningsprocent i stedet for at skjule den: den fortæller hvor meget du kan stole på *dette* vindue, ikke om kalibreringen er gyldig.

### Præcisionsstigen

| Mærke | Hvad der ligger bag | Typisk bånd |
|---|---|---|
| **Lav** | Kun GPS — ingen tankning har endnu forankret noget | ±15 % og værre |
| **Mellem** | Tankninger har forankret modellen, men ingen OBD2-tur har fodret sløjfen | ±7–15 % |
| **Høj** | Tankninger *og* OBD2-optagne ture | ±3–7 % |

### Hvad det betyder i praksis

- **Sæt altid flueben i « Fuld tank », når du fylder helt op.** En delvis tankning registreres stadig og tæller for omkostningen, men kan ikke lukke et kalibreringsvindue. Delvise tankninger, der venter på en fuld tank, vises som banner i statistikken.
- **Kilometertællerens nøjagtighed betyder mere end literens.** En tastefejl på 2 % forgifter vinduet; 0,2 L afrunding gør ikke.
- **Det første vindue tages for pålydende, senere udjævner.** Forvent ét spring og derefter ro.
- **Kører du uden at optage, går regnestykket ikke op** — og appen siger det i stedet for at fuske. Se afstemningen i Tankbog og forbrug.

---

## Sådan lærer appen din kørsel

Uafhængigt af pumpeforstærkningen bærer et køretøj en **basislinje pr. kørselssituation**: hvad din bil bruger i tomgang, i stop & go, i byen, på motorvej, ved deceleration, på bakke eller lastet, fra kold, under vedvarende belastning og i frihjul.

*Hver situation fyldes uafhængigt. Advarslen er ærlig: to situationer har stadig nul prøver, så basislinjen er ufuldstændig.*

### Sådan virker det i praksis

Hver OBD2-prøve klassificeres i en kørselssituation og lægges i den kurv. Der findes to klassifikationstilstande:

- **Regelbaseret** — hver prøve hører til præcis én situation. Skarpt, men en bil ved 60 km/t hopper fra prøve til prøve mellem « by » og « motorvej ».
- **Fuzzy** *(standard)* — hver prøve fordeles på alle situationer efter, hvor godt den passer. Glat netop dér, hvor den regelbaserede springer.

### Hvad det betyder i praksis

- **En basislinje hører til køretøjet, ikke telefonen.** Skifter du bil, begynder en ny; *Basisliniesynkronisering* (kræver TankSync) fører den til en anden enhed.
- **Manglende situationer er ærlige huller, ikke fejl.** Trækker du aldrig anhænger, står « Vedvarende belastning / trailer » på 0 for altid, og appen bliver ved med at sige, at profilen er ufuldstændig. Det er i orden.
- **At nulstille basislinjen sender dig tilbage til koldstartsstandarder**, indtil nye ture fylder den — gør det efter et mekanisk indgreb, ikke fordi et tal så mærkeligt ud.

---

## Den ene indstillingsregel værd at huske

Indstillinger er et **træ med to niveauer**: en rod af emnefelter, én skærm pr. emne, og et søgefelt der filtrerer felterne på nøgleord.

*Hver parameter har præcis ét hjem. Husker du emnet, behøver du aldrig rulle.*

Fuldt kort over alle skærme: Indstillingsoversigt.

---

**Videre:** Find tankstationer →

---

# Find tankstationer

Niveau 1 af de tre spareniveauer: betal mindre pr. liter.

---

## Én knap, én mental model

Den nederste bjælke har én søgeudløser — den hævede grønne knap i midten. Den er kontekstafhængig frem for modal:

- **Fra enhver fane** → åbner kriteriearket.
- **Fra resultaterne eller kortet** → genåbner arket med dine seneste værdier.
- **Inde i arket** → udfører søgningen.

Etiketten fortæller hvad den vil gøre, og i rutetilstand er den slået fra, indtil der er en destination. Der findes bevidst ikke separate knapper til « søg i nærheden » og « søg langs ruten ».

---

## Sæt kriterierne

*Arket åbner forudfyldt fra din aktive profil — normalt ændrer du kun én ting.*

| Kontrol | Hvad den gør | Driftsmæssig konsekvens |
|---|---|---|
| **I nærheden / Langs ruten** | Skifter hele søgetilstanden | Rutetilstand kræver en destination og forespørger hvert land i korridoren |
| **Adresse, postnummer eller by** | Søger et sted i stedet for din GPS-position | Intet om din placering forlader telefonen; stednavnet geokodes via OpenStreetMap Nominatim og caches i 24 t |
| **Brændstofchips** | Den kvalitet priserne gælder | Listen tilpasser sig det, dit lands leverandør faktisk udgiver |
| **Radius** | Hvor langt der søges | En stor radius i et tæt land giver mange stationer og en langsommere søgning |
| **Kun åbne** | Skjuler lukkede stationer | Kræver at leverandøren udgiver åbningstider — nogle gør ikke |
| **Faciliteter** | Butik, vask, luft, toilet… | Filtrerer kun på oplyste data; en station med tomt felt forsvinder |
| **Mærker** | Begræns til bestemte kæder | Tælles på det aktuelle resultatsæt, så listen skifter med radius |
| **Gem som standardværdier** | Skriver disse kriterier ind i profilen | Enhver fremtidig søgning starter her |

### Søgeknappen

Den hævede knap midt i den nederste bjælke er den eneste søgeudløser. Fra
enhver fane åbner den dette ark; fra resultaterne eller kortet åbner den
det igen med det, du sidst brugte; inde i arket kører den søgningen.

### I nærheden eller langs en rute

To forskellige spørgsmål. **I nærheden** søger omkring din position eller
en adresse. **Langs ruten** kræver en destination og måler afstanden
langs korridoren i stedet for i fugleflugt: en tank 2 km væk ad en
sidevej rangerer altså efter en, der ligger på din vej.

### Brændstoftype

Hvilket brændstof priserne gælder. Chipsene retter sig efter, hvad dit
lands udbyder faktisk offentliggør — et brændstof, der mangler på listen,
mangler i data, ikke i appen.

### Radius

Hvor langt der skal søges. En stor radius i et tætbefolket land giver
rigtig mange tankstationer og en langsommere søgning, og de ekstra ligger
som regel længere væk, end besparelsen er værd.

### Kun åbne nu

Skjuler lukkede tankstationer. Det afhænger af, om udbyderen
offentliggør åbningstider, og nogle gør ikke — mangler de, beholdes
stationen i stedet for at blive gættet.

### Faciliteter

Butik, vask, luft, WC. Disse filtre virker på **indberettede** data: en
station, der intet offentliggør om sine faciliteter, forsvinder fra en
filtreret liste, selv om den har dem alle.

### Motorvejstankstationer

Motorvejstankstationer er som regel landets dyreste brændstof: at udelade
dem er det ene filter, der oftest ændrer, hvad du betaler. Behold dem, når
du ikke kan forlade motorvejen.

### Gem som mine standarder

Skriver disse kriterier ind i din profil, så hver senere søgning starter
her i stedet for ved appens egne standarder. Det er indstillingen, der
gør arket til en bekræftelse med ét tryk i stedet for en formular.

### Sådan virker det i praksis

En søgning i nærheden sender **dine koordinater (eller en regionskode) og en radius** til dit lands officielle leverandør — aldrig din identitet. Lande med en daglig samlefil (Spanien, Italien) filtreres på enheden; de søgninger kræver slet ingen netværkskald, når filen er cachet.

---

## At læse et resultatkort

*Alt hvad en beslutning kræver, uden at åbne noget.*

- **Pris** — for det søgte brændstof, i dit lands konvention (bemærk tiendedels-øren hævet).
- **Tendenspil** ▲▼▬ — hvor stationens pris har bevæget sig for nylig, ud fra *din egen* lokale historik.
- **★** — tryk for at gøre til favorit; udfyldt = allerede gemt.
- **Facilitetschips** — butik, vask, luft, hæveautomat, som oplyst.
- **Afstand** — i fugleflugt fra din position.
- **« Opdateret 31/08 00:01 »** — friskhedsstemplet. **Læs det før prisen.**
- **Sorteringsrække** — Afstand / Pris / A–Å / 24 t, plus et advarselschip når den nyeste pris i listen er over en time gammel.

### Friskhed — vigtigere end prisen

| Mærke | Alder | Hvad du gør |
|---|---|---|
| Grøn | < 5 min | Stol på den |
| Gul | 5–30 min | Fint til en beslutning |
| Orange | timer | Plausibelt; leverandøren udgiver måske langsomt |
| Rød ramme | > 1 dag | Betragt som vejledende — opdatér før du kører en omvej |

Friskhed er en egenskab ved **landets leverandør**, ikke ved appen. En spansk pris på 14 timer er ikke en fejl: det land udgiver én gang dagligt. Se Sådan fungerer Sparkilo → Én kilde pr. land.

### Strygebevægelser

- **Stryg til højre** — åbn i din navigationsapp (Google Maps, Waze, OsmAnd, Organic Maps).
- **Stryg til venstre** — skjul stationen fra alle fremtidige resultater. Den vises igen fra **Privatliv og data → Data på denne enhed → Ignorerede stationer**.

---

## Stationsdetaljer

*Tryk på et kort. Overskriften falder tilbage fra mærke til navn til vej, så et Intermarché med tomt mærkefelt stadig står som « Intermarché ».*

Den øverste blok er den **fulde pristabel** — hver kvalitet leverandøren oplyser for stationen, med `--` hvor den ikke oplyser nogen. Det er den hurtigste måde at se, om den billige E85-station også holder på diesel.

**Tilføj tankning** forudfylder station, brændstof og pris i formularen — appens største tidsbesparelse, hvis du registrerer dine tankninger.

*Længere nede: tjenester, accepterede betalingsmidler, din egen private stjernebedømmelse, og den lokale 30-dages prishistorik.*

Handlingerne i topbjælken er, fra venstre mod højre: **opret en prisadvarsel**, **scan en betalings-QR**, **rapportér en forkert pris** og **gør til favorit**.

---

## Kortet

*Farven er relativ til det, der er på skærmen: grøn er den billigste synlige, rød den dyreste. Bundlinjen angiver antal stationer, radius og datas alder.*

- **Klyngemarkører** samler nåle ved udzoom; et tryk zoomer ind.
- **Langt tryk** hvor som helst for at sætte din egen markør og søge derfra.
- **EV-knappen** øverst til højre skifter kortet til ladepunkter — se Elopladning.
- **Del** sender det aktuelle udsnit til en anden.

Fliserne kommer fra OpenStreetMap. Som standard går de gennem udviklerens EU-proxy, så OpenStreetMap aldrig ser din IP; du kan slå proxyen fra i Indstillinger → Privatliv og data og hente direkte. F-Droid-versionen bruger aldrig proxyen.

---

## Tankstationsradaren

En live-scanning omkring din position, bygget til brug **under kørsel**.

*Efter enhver søgning i nærheden dukker en flydende pille op nederst til højre. Ét tryk starter radaren.*

### Sådan virker det i praksis

Radaren opdaterer din GPS-position, henter stationernes **placeringer** i en bred 60 km-korridor og fletter en direkte forespørgsel i radius ind — den kan derfor aldrig vise mindre end en almindelig søgning. Stationer flytter sig ikke, så de placeringer caches i op til en time og genbruges; kun **prisen** på en station du nærmer dig, hentes lige når det gælder. Det er dét, der gør en kontinuerligt kørende radar billig i både data og batteri.

*I drift: resultater sorteret efter afstand, hver med en bjælke der fyldes, jo tættere du kommer.*

### Under en turoptagelse

Radaren fastgør et **Nærmeste station**-kort øverst på optageskærmen — navn, pris for dit brændstof, afstand, og en bjælke der når 100 % ved ankomst. Stryg til side for at bladre gennem kandidaterne. Kører du ind i den indstillede indflyvningsradius, skifter billede-i-billede-feltet til en stor prisvisning; se Ture og øko-coaching → Indflyvningsoverlayet.

### Indstillinger der ændrer opførslen

Alle under **Indstillinger → Kørsel & forbrug**: den **radius** hvor overlayet forstørres, om det viser **nærmeste** station eller den **billigste i radius**, det **mindste opdateringsinterval** (et gulv, ikke en fast kadence — der forespørges hurtigere ved høj fart, men aldrig tættere end det) og **automatisk fastgørelse**, der holder skærmen tændt og skjuler systembjælkerne til brug i en instrumentbrætholder, på bekostning af batteri.

---

## Brændstofprisberegneren

Tre tal ind — afstand, dit forbrug, prisen — og ud kommer forbrugte liter, samlet pris og pris pr. kilometer. Den forudfylder forbrug og pris fra dine egne data, så ofte skriver du kun afstanden.

Den besvarer ærligt ét spørgsmål: *er stationen 12 km længere væk reelt billigere, når jeg er kørt derhen?*

---

## Widget på startskærmen

- Viser din billigste favorit (eller nærmeste station) og dens pris.
- **Tryk på widgetten** → åbner den stations detalje, uanset om appen var varm eller lukket.
- **Tryk på opdateringsikonet** → henter priser i baggrunden uden at åbne appen.
- Baggrundsopdatering hvert 30. minut under opladning, ellers hver time, med respekt for Doze.

Udseende og indholdsvariant (*aktuel pris* eller *forudsigende: bedste tidspunkt at tanke*) sættes pr. profil under **Indstillinger → Enheder & visning → Widget på startskærmen**.

---

## Android Auto

Tilsluttet en Android Auto-skærm tilbyder appen to køresikre skærme: **Søg** (stationerne fra din seneste søgning på telefonen) og **Radar** (de billigste omkring din rute). Kør søgningen på telefonen først — bilsiden er bevidst skrivebeskyttet, fordi der ikke findes en sikker måde at skrive på under kørsel. Kun Android; der findes ingen CarPlay-version.

---

<details>
<summary>Helskærmsopslag — stationsdetalje, hele siden</summary>

</details>

---

**Se også:** Ruteplanlægning · Favoritter og advarsler · Prishistorik
**Videre:** Ruteplanlægning →

---

# Ruteplanlægning

Ikke « billigst i nærheden af mig » men **billigst på vejen** — forskellen er flere kroner værd på enhver længere tur.

---

## Start en rutesøgning

*Tryk på **Søg** → skift til **Søg langs ruten**. Knappen er slået fra, indtil der er destination og brændstofkvalitet.*

| Felt | Betydning |
|---|---|
| **Start** | Din nuværende position, eller en indtastet by / postnummer |
| **Tilføj et stop** | Mellemliggende punkter — korridoren følger dem |
| **Destination** | By, postnummer eller koordinater |
| **Brændstof** | Den kvalitet der prissættes langs korridoren |
| **Rutesegment** | Vis den billigste station for hver *n* km (50–1000 km) |
| **Maksimal omvej** | Hvor langt fra den direkte linje en station må ligge |
| **Mindste besparelse** | Skjuler stop, der ikke slår korridorens gennemsnit med mindst dette beløb; *Fra* viser alt |

*De samme filtre for åbningstid, faciliteter og mærker som ved en søgning i nærheden gælder for korridoren.*

### Sådan virker det i praksis

1. Appen kalder den offentlige rutetjeneste **OSRM** og får vejlinjen for din rute.
2. Den lægger kandidatpunkter langs linjen med afstand efter dit **rutesegment**.
3. Omkring hvert punkt forespørger den prisleverandøren **i det land, punktet ligger i**, med kvaliteten fra det lands profil.
4. Den rangerer kandidaterne i hvert segment efter din strategi og grænsen for **maksimal omvej**.

### Hvad det betyder i praksis

- **Segmentlængden er den egentlige knap.** 50 km på 600 km giver tolv lister; 200 km giver tre. Vælg efter hvor tit du reelt holder ind.
- **Maksimal omvej måles fra den direkte rute**, ikke fra dig. 5 km betyder « op til 5 km ekstra kørsel ».
- **Lange ruter tager længere tid.** En 600 km-korridor prøver mange punkter, muligvis hos flere leverandører.
- Er starten « automatisk GPS » og signalet forsvinder, falder søgningen tilbage på den sidst kendte position.

---

## Grænseoverskridende korridorer

Når en rute krydser en grænse, **forespørges hvert land i korridoren gennem sin egen leverandør**, og overskriften nævner dem alle:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Fordi kvaliteterne er forskellige fra land til land, viser et grænseoverskridende resultat med rette E85 på den franske strækning og Gasolina 95/E5 på den spanske. Hver er prissat korrekt for sin side, aldrig midlet.

**Du skal bruge en profil pr. land** med den rigtige foretrukne kvalitet, ellers har den anden strækning intet at prissætte og viser `--`. Se Sådan fungerer Sparkilo → Profiler.

---

## Resultaterne kommer løbende

En langsom national API skal ikke bremse resten af korridoren, så resultaterne kommer **gradvist**: hvert lands stationer dukker op, så snart den leverandør svarer, med et banner der nævner de kilder, der stadig mangler. Du kan trykke på et billigt resultat, så snart det lander.

---

## De fire strategier

### 🏆 Bedste stop *(standard)*
Løfter de 3–5 billigste, realistisk nåelige stationer op som rangerede chips øverst. Omvejene holdes korte. Det er, hvad de fleste bilister faktisk vil have.

### 🎯 Billigste
Den ene station med den laveste pris på hele ruten. Bedst når du tanker én gang og vil have den maksimale besparelse pr. liter.

### ⚖️ Balanceret
Scorer hver kandidat på pris *og* nærhed til linjen. En station 5 km væk men 10 øre/L billigere vinder; en 50 km væk skal være markant billigere.

### 📏 Ensartet
Deler ruten i lige store afsnit og foreslår ét stop pr. afsnit. Bedst til lange grænseoverskridende ture med flere tankninger.

Standardstrategi, segmentlængde, maksimal omvej, mindste besparelse og antallet af kandidater pr. prøvepunkt gemmes **pr. profil**:

*Indstillinger → Profiler & region → redigér → Ruteplanlægning. Sæt det én gang her i stedet for at justere arket ved hver tur.*

---

## At læse resultaterne

Hver række tilføjer to tal, som en søgning i nærheden ikke har:

- **Afstand fra start** — hvor på ruten stationen ligger, så du kan matche den med det tidspunkt, hvor tanken bliver lav.
- **Omvej** — de ekstra kilometer i forhold til den direkte linje.
- **Besparelse ift. gennemsnit** — mod korridorens gennemsnit, ikke et nationalt.

Skift til **Alle stationer** for at se hver station langs ruten frem for udvalget. Kortet tegner linjen med alle nåle.

---

## Undgå motorveje

**Indstillinger → Profiler & region → Visning og stationer → Undgå motorveje** får ruteberegneren til at foretrække sekundære veje. Det ændrer selve *linjen*, og dermed hvilke stationer der overhovedet er kandidater: motorvejsrastepladser forsvinder fra korridoren i stedet for blot at blive nedprioriteret. Nyttigt netop fordi motorvejsbrændstof normalt er det dyreste på enhver rute.

---

## Gemte ruter

Tryk på **Gem rute** på resultatskærmen. Gemte ruter vises øverst i ruteformularen; et tryk kører den samme korridor igen med **friske priser**. Det er geometrien der gemmes, ikke priserne.

---

**Se også:** Find tankstationer · Indstillingsoversigt
**Videre:** Favoritter og advarsler →

---

# Elopladning

Sparkilo er ikke kun til forbrændingsbiler. Ladepunkterne kommer fra [OpenChargeMap](https://openchargemap.org), verdens største åbne, fællesskabsdrevne register.

---

## Slå det til

To uafhængige kontakter, begge under **Indstillinger → Funktioner & brugstilstand → Søgning og kort**:

- **EV-opladning** — selve funktionen (søgning, detaljesider, favoritter).
- **Vis ladepunkter** — om ladepunkter optræder i resultater og på kortet.

*Du kan vise tankstationer, ladepunkter eller begge dele. Kører du kun elektrisk, slår du typisk **Vis tankstationer** fra.*

Opret derefter et køretøj under **Indstillinger → Køretøjer & OBD2 → Mine køretøjer → Tilføj**, og vælg **Elektrisk** som drivlinje. Et elkøretøj bærer batterikapacitet (kWh), maksimal AC- og DC-ladeeffekt (kW) og dets stik (Type 2, CCS, CHAdeMO, Tesla, Schuko, Type 1, husstandsstik). Søgninger begrænses så til de ladepunkter, din bil reelt kan bruge.

---

## Sådan virker dataene

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

**Se også:** Find tankstationer · Tankbog og forbrug
**Videre:** Køretøjer og OBD2 →

---

# Favoritter og prisadvarsler

Fanen ⭐ er din kortliste plus robotterne, der holder øje med den for dig.

---

## Favoritter

*To faner øverst: **Favoritter** og **Prisadvarsler**. Hvert kort bærer alle oplyste kvaliteter, ikke kun din.*

Markér en station med ★ på et resultatkort eller på dens detaljeskærm.

### Hvad der faktisk gemmes

En favorit er ikke et bogmærke, men en **fuld lokal kopi** af stationen: id, adresse, faciliteter, betalingsmidler, åbningstider og de sidst sete priser. Derfor virker fanen uden netværk: du ser de sidst kendte priser, tydeligt mærket med deres friskhedsstempel.

### Hvad det betyder i praksis

- **Favoritter virker offline**; søgninger gør ikke. Før en tur uden dækning: åbn fanen én gang på Wi-Fi.
- Priserne opdateres når du åbner fanen, ikke løbende.
- Favoritter er blandt de kategorier, **TankSync** spejler mellem dine enheder, hvis du slår det til.

### Sortering og strygning

Sortér efter pris (billigst først, standard), afstand eller alfabetisk. **Stryg til højre** åbner navigationen; **stryg til venstre** fjerner favoritten med fortryd-mulighed.

### Ladepunkter

Ladepunkter kan også gøres til favoritter, og kortet viser, hvad en elbilist har brug for: **effekt pr. stik i kW**, hvor mange der er **ledige lige nu**, og **stiktyperne**.

### Liggende og tablets

På telefoner på tværs og på enhver skærm over 600 dp vises favoritter og advarsler **side om side** med en skillelinje i stedet for bag en faneskifter. Da begge ruder er synlige, er der ingen skifter i det layout.

---

## Prisadvarsler

*Tre tællere øverst — aktive regler, udløsninger i dag og denne uge — derefter de to advarselstyper. Bundlinjen stempler det seneste baggrundstjek.*

Der findes to typer, og de besvarer forskellige spørgsmål.

### Stationsadvarsel — « sig til når *denne* stander falder »

Oprettes fra en stations detaljeside (klokkeikonet). Vælg brændstof, sæt en grænse, gem. Bedst til den station, du i forvejen bruger.

### Zoneadvarsel — « sig til når *et sted her omkring* falder »

*Indstillinger → Priser & advarsler → Prisadvarsler → **Opret en zoneadvarsel**.*

| Felt | Hvad det gør |
|---|---|
| **Etiket** | Fri tekst, så en liste af advarsler forbliver læsbar (« Diesel hjemme ») |
| **Brændstoftype** | Én kvalitet pr. advarsel — en station kan have flere |
| **Grænse (kr./L)** | Udløses når en station i zonen falder **under** |
| **Radius (km)** | Det overvågede område omkring midtpunktet |
| **Tjekfrekvens** | Hvor tit baggrundsopgaven kigger — se nedenfor |
| **Min position / Vælg på kortet / Postnummer** | Tre måder at sætte midtpunktet; et postnummer rører aldrig GPS |

Bedst til « sig til når diesel falder under 12 kr. inden for 5 km fra hjemmet », når den konkrete station er ligegyldig.

---

## Sådan virker tjekket faktisk

En baggrundsopgave planlagt af systemet vågner og:

1. Henter live-priser for stationerne bag dine advarsler.
2. Sammenligner hver med sin grænse.
3. Udløser en **lokal notifikation**, hvis en pris er under. Et tryk åbner stationen.

Kadencen er **hvert 30. minut under opladning, ellers hver time**, og kun med netværksforbindelse. Din tjekfrekvens pr. advarsel er et loft indenfor det: « én gang om dagen » får opgaven til at springe advarslen over det meste af tiden.

### Hvad det betyder i praksis

- **Advarsler er bedste indsats, ikke realtid.** Systemet bestemmer hvornår opgaven kører; aggressive batterisparere forsinker eller dræber den. Er timing vigtigt, så fritag appen fra batterioptimering.
- **Der bruges ingen GPS.** Advarsler arbejder på stationernes gemte koordinater, så en advarsel omkring hjemmet virker videre, selv om du er 500 km væk.
- **Batteriforbruget er ubetydeligt** — nogle få KB pr. opvågning, i et systemstyret vindue, Doze-venligt. Klart under 0,5 % om dagen.
- **En nyttig sidegevinst:** samme tjek skriver en prisregistrering i din lokale historik. En station under advarsel opbygger derfor sin 30-dages historik på timer i stedet for uger — og det er dét, der får banneret *bedste tidspunkt at tanke* frem hurtigt. Se Prishistorik.
- **Er notifikationer slået fra på systemniveau**, kan appens kontakt intet udløse.

---

## Statistik

Tællerne øverst viser hvor mange regler der er aktive, og hvor tit de er udløst i dag og denne uge — en hurtig kontrol af, om baggrundsopgaven virkelig kører. En række nuller med flere aktive advarsler og et gammelt « seneste tjek »-stempel er det klassiske tegn på en batterisparer, der dræber opgaven.

---

## Stop advarsler

At slå en advarsel fra sætter den på pause uden at miste reglen; stryg til venstre sletter den. At fjerne stationen fra favoritter sletter **ikke** dens advarsler.

---

**Se også:** Prishistorik og forudsigelser · Indstillingsoversigt → Priser & advarsler
**Videre:** Elopladning →

---

# Prishistorik og forudsigelser

Appen bygger et **privat, lokalt** billede af, hvordan priserne bevæger sig omkring dig, og gør det til én ærlig anbefaling.

---

## Hvad der registreres, og hvor

Hver gang en stations pris passerer gennem appen — en søgning, en opdatering af favoritter eller et baggrundstjek af advarsler — skriver appen en registrering **på din telefon**: station, brændstof, pris, tidsstempel. Intet uploades, og ingen andres data hentes.

- **Dubletfjernet til én registrering pr. station pr. time.** Fem søgninger på ti minutter giver én post.
- **Gemmes i 30 dage.** Ældre registreringer slettes automatisk.
- **Slås til af** *Funktioner & brugstilstand → Priser & advarsler → Prishistorik*. Er den fra, skrives ingen registreringer overhovedet.

*Indstillinger → Priser & advarsler. **Prishistorik** er forudsætningen for forudsigelsen nedenunder — uden historik har den intet at arbejde med.*

---

## Se en stations historik

Åbn en stations detaljeside og rul ned til **Prishistorik**:

- **Timegraf** — gennemsnitspris for hver time på døgnet over de seneste 30 dage.
- **Ugedagsgraf** — gennemsnit for hver ugedag.
- **Min / maks / gennemsnit / tendens** som opsummering.

Den billigste time eller dag fremhæves med grønt, den dyreste med rødt.

---

## « Bedste tidspunkt at tanke »

Så snart der er historik nok, får stationen et banner:

> 💡 **Priserne falder typisk tirsdag 18:00–20:00** — spar ~3,2 øre/L

### Hvad det er — og ikke er

Det er en **opsummering af, hvad der allerede er sket på den station de seneste 30 dage**, i *dine* data. Det er bevidst **ikke**:

- en forudsigelse af morgendagens pris,
- bevidst om oliemarked, afgiftsændringer eller vejr,
- bygget på andre brugeres data.

Den tilbageholdenhed er pointen. Et regionalt mandagsmorgen-tillæg er et virkeligt, gentagende, lokalt mønster, man kan handle på; en markedsprognose fra en telefon er ikke.

### Læringsfasen

Banneret forbliver skjult, indtil appen har mindst **10 prisregistreringer for den station de seneste 30 dage**. Hvor lang tid det tager, afhænger udelukkende af, hvor tit stationens pris passerer gennem appen:

| Situation | Tid til banneret |
|---|---|
| Stationen har en **prisadvarsel** | Få timer — baggrundstjekket registrerer hvert 30.–60. minut |
| Stationen er en **favorit**, du åbner dagligt | Omkring 10 dage |
| Ingen af delene — kun lejlighedsvise søgninger | Uger, muligvis aldrig |

**Det praktiske trick:** sæt en advarsel på den station, du reelt bruger. Advarslen tjener sig ind to gange — den siger til ved et fald og fylder den historik, der producerer anbefalingen.

### Hvorfor din favorit stadig ikke har et banner

1. **Ikke nok registreringer endnu** (se ovenfor).
2. **Prisen har knap nok bevæget sig.** Er spændet over 30 dage under 0,1 øre/L, er der intet værd at handle på, så der vises intet.
3. **Kun ét brændstof har prøver.** Tærsklen gælder pr. brændstoftype, ikke pr. station.

---

## Prisforudsigelse på enheden

*Funktioner & brugstilstand → Priser & advarsler → **Bedste tidspunkt at tanke*** aktiverer en lille TensorFlow Lite-model, der kører **udelukkende på enheden**. Dens træk og forudsigelser forlader aldrig telefonen. Det er den, der driver den *forudsigende* variant af startskærms-widgetten (**Indstillinger → Enheder & visning → Widget på startskærmen → Indholdsvariant**), som viser det bedste tidspunkt at tanke frem for blot den aktuelle pris.

Vil du hellere have, at intet udledes, så slå den fra: historik og mønsterbanner virker videre uden.

---

## Prisrapporter fra fællesskabet

*Funktioner & brugstilstand → Priser & advarsler → **Fællesskabets prisrapporter*** tilføjer en rapportér-handling til stationsdetaljen, så du kan melde en pris, den officielle kilde har forkert. Rapporter går til den delte TankSync-database under din pseudonyme konto og er synlige for andre indloggede brugere — det er altså den eneste prisfunktion, der **ikke** er rent lokal. Den kræver TankSync og er slået fra, indtil du tænder den.

---

## Eksport

**Indstillinger → Privatliv og data → Eksportér eller slet → Eksportér mine data → CSV** skriver en CSV — dens prishistorik-tabel indeholder station, brændstof, pris, tidsstempel — til din offentlige Downloads-mappe.

---

**Se også:** Favoritter og advarsler · Find tankstationer → Friskhed
**Videre:** Indstillingsoversigt →

---

# Tankbog og forbrug

Niveau 2 og 3 af de tre spareniveauer: hvor meget du brænder, og hvad det reelt kostede. Fanen ⛽ **Brændstof** vises i tilstandene **Mellem** og **Fuld**.

---

## Fanen Brændstof på et blik

*Tre blokke: hvad der er i tanken, hvad din kørsel koster, og hvad du faktisk har tanket.*

### Tankniveau og rækkevidde

Måleren er **forankret i din seneste fulde tankning** og derefter trukket ned med det brændstof, dine optagne ture har brugt. Datostemplet under bjælken fortæller, hvilken tankning den er forankret i.

Der vises bevidst to rækkevidder:

- **« ≈ 548 km ved forbruget fra din seneste tank »** — den seneste adfærd, nyttig i dag.
- **« Langsigtet gennemsnit: ≈ 611 km »** — dit historiske gennemsnit, nyttigt til planlægning.

Afviger de meget, har noget ændret sig for nylig: en tagboks, vinteren, en anden vejblanding, eller et brændstofskift.

> Når en OBD2-adapter er tilsluttet, og bilen oplyser brændstofniveau-PID'en, skifter måleren til **tanksensoren** og siger det. Den værdi er en måling, ikke en udledning, og den overlever ikke-optagne ture.

### Statistikkortet

De tre mærker er ærlighedslaget:

| Mærke | Betydning |
|---|---|
| **Præcision: Høj · ±3-7 %** | Både tankninger og OBD2-ture fodrer modellen |
| **Præcision: Mellem** | Tankninger forankrer den, men ingen OBD2-tur har fodret sløjfen endnu |
| **Præcision: Lav** | Kun GPS, intet forankret — tilføj et par fulde tankninger |
| **η_v : 0,93 · 6 prøver** | Speed-density-modellens lærte volumetriske virkningsgrad og antal prøver |

Nedenunder: gennemsnitlig L/100 km, gennemsnitlig pris pr. km, liter i alt, samlet forbrug, antal tankninger. Et tryk åbner den fulde [forbrugsstatistik](#forbrugsstatistik).

---

## Registrér en tankning

Tryk på **➕ Tilføj tankning** — eller meget hurtigere: **Tilføj tankning** direkte på en stations detaljeside, som forudfylder station, brændstof og pris.

*Kommer du fra en station, er tre felter allerede rigtige — du skriver liter, total og kilometerstand.*

| Felt | Hvorfor det betyder noget |
|---|---|
| **Dato** | Ordner tankvinduerne |
| **Køretøj** | Tilskriver tankningen og kalibreringen |
| **Brændstoftype** | På en flex-fuel hænger hele sammenligningen på dette felt |
| **Liter** | Tælleren i standersandheden |
| **Samlet pris** | Pris pr. km, månedligt forbrug |
| **Kilometerstand** | **Det vigtigste felt i formularen** |
| **Fuld tank** | Lukker et kalibreringsvindue — se nedenfor |
| Station, noter | Valgfrit |

### Hvorfor kilometerstanden er det kritiske felt

Forbrug er liter ÷ kilometer. Literne kommer fra kvitteringen og er eksakte. Kilometerne kommer fra *dine to aflæsninger af kilometertælleren*. En tastefejl på 20 km på en tank på 600 km er 3 % fejl — og fordi det resultat rekalibrerer estimatoren, forplanter fejlen sig til alle fremtidige skøn. Formularen afviser en kilometerstand under den forrige tanknings, for afstand går ikke baglæns.

### Fluebenet « Fuld tank »

Sæt det, hver gang du fylder helt op. Det er dét, der gør to tankninger til et **lukket vindue** med et fysisk sandt forbrug.

Delvise tankninger registreres stadig, tæller for omkostningen og står på listen — de kan bare ikke lukke et vindue. Statistikskærmen viser et banner, der tæller *« delvise tankninger der afventer en fuld tank — ikke med i gennemsnittet »*, så du altid ved, hvad der er i tallene.

### Scan i stedet for at taste

- **Scan standerens display** — ret kameraet mod displayet; appen læser liter, total og pris.
- **Scan kvitteringen** — det samme fra den trykte bon.
- **Del et foto af en kvittering** fra en anden app direkte ind i formularen.

Genkendelsen kører **på enheden**; billedet uploades aldrig. Kast altid et blik på værdierne før du gemmer — en scanning er et forspring, ikke et orakel. Læser den forkert, opretter *Rapportér scanningsfejl* en sag med udsnittet, så genkendelsen bliver bedre.

> **F-Droid-build:** tekstgenkendelse på enheden findes kun i Play- / App Store-builds. Den GMS-frie F-Droid-build har ingen scanning — dér taster man tankninger i hånden. Alt andet er identisk.

---

## Tankrapporten — sandhedens øjeblik

Hver gang en fuld tank lukker, udgiver appen en rapport. På fanen Ture ser den sådan ud:

*Ét kort, fire forskellige udsagn — og de er bevidst ikke det samme tal.*

| Linje | Hvad det er |
|---|---|
| **6,4 L/100 km** | Denne tanks **standersandhed**: påfyldte liter ÷ kilometertællerens kilometer |
| **1,5 L/100 km mindre end forrige tankning** | Tendens mod den sidst lukkede tank |
| **559 km · 35,7 L · 32,12 €** | Det rå vindue |
| **Optagelserne dækker 81 % af denne tank** | Hvor stor en del af de kilometer du faktisk optog |
| **Optaget andel: 10,5 L/100 km** | Hvad de optagne kilometer alene gav i gennemsnit |
| **De optagne skøn ligger 39 % over standersandheden** | Kalibreringsdommen — estimatoren lå for højt og er netop rettet |

### At læse den rigtigt

Den optagne andel og standersandheden **må gerne afvige**, af to forskellige grunde, der er lette at forveksle:

1. **Udvælgelsen.** Du optager de ture, du optager. Er dine 81 % mest korte byture, og de manglende 19 % en motorvejsstrækning, ligger den optagne andel med rette højere end tankens gennemsnit. Intet er i stykker.
2. **Kalibreringen.** Selve estimatoren kan være skæv. Det er dét, sidste linje måler, ved at sammenligne de to **pr. kilometer**, så dækningen går ud og kun afgør vinduets vægt.

Efter en rettelse som denne skal du forvente, at turskønnene falder mærkbart på næste tur og derefter falder til ro. Hele mekanismen: Sådan fungerer Sparkilo → Hvordan en liter bliver til et tal.

Kortet kan også pege på *hvad der ændrede sig* — andel af høje omdrejninger, hårde hændelser pr. 100 km, koldstarter, tomgangsandel, hver især mod forrige tank — med det udtrykkelige forbehold, at optagelser er spontane og kun dækker en del af tanken.

---

## Forbrugsstatistik

Tryk på statistikkortet, eller **Brændstof → Forbrugsstatistik**.

*Chipsene øverst begrænser alt nedenunder til ét brændstof — uundværligt på en flex-fuel, hvor et samlet gennemsnit er meningsløst.*

Månedstabellen viser liter, forbrug i kroner, gennemsnitspris pr. liter, gennemsnitsforbrug, pris pr. km og antal tankninger, hver med sin forskel. Røde pile er ikke en dom — stigende *udgift* efter stigende *pris pr. liter* er markedet, ikke din højre fod. Tallet at holde øje med for kørslen er **L/100 km**.

### Pris pr. kilometer pr. brændstof

*Flex-fuel-bilistens egentlige spørgsmål, besvaret: ikke hvilket brændstof der er billigst pr. liter, men hvilket der er billigst pr. kilometer.*

Hvert brændstof får en række bygget udelukkende på **lukkede tankvinduer**: målt L/100 km, faktisk betalt pris pr. liter, pris pr. 100 km, samlet forbrug, målt afstand, forbrugte liter, CO₂ pr. 100 km, og hvor mange fulde tanke der ligger bag. En række baseret på én enkelt tank er mærket **Foreløbig**.

*Domkortet angiver vinderen, forskellen pr. 1000 km og — mest nyttigt — **balanceprisen**.*

Balancelinjen (« E5 bliver bedre end E85 under 0,75 €/L ») beregnes ud fra **dit eget målte forbrug af hvert brændstof**, så den flytter sig, når din kørsel gør. Det er en beslutningsregel, du kan bruge ved standeren; et generisk forhold fra nettet er ikke.

CO₂-tallene er well-to-wheel-skøn (EU JEC WTW v5) anvendt på dit målte forbrug — bevidsthed, ikke revisionsegnet regnskab. Blandinger holdes uden for CO₂, fordi emissionsfaktoren afhænger af blandingen, som rækken ikke registrerer.

*Tendensgraferne stabler efter brændstof, så et skift viser sig som én farve der afløser en anden, frem for som et mystisk spring.*

*Pris pr. liter og L/100 km er bevidst to adskilte grafer — den ene er markedet, den anden er dig.*

**Eksportér** skriver det hele som CSV i din offentlige Downloads-mappe.

---

## Øko-score pr. tankning

Hver tankning får et mærke sammenlignet med et rullende gennemsnit af dine seneste tre tankninger med samme brændstof:

| Forskel | Mærke | Sådan læses det |
|---|---|---|
| ≥ 3 % bedre | 🟢 Forbedres | Mærkbart mindre end din egen basislinje |
| inden for ±3 % | ⚪ Stabil | Normal variation |
| ≥ 3 % dårligere | 🟠 Forværres | Tjek dæktryk, tagboks, kulde, vejblanding |

Mærket forbliver skjult, indtil du har fire tankninger med det brændstof, så basislinjen er reel.

---

## Når regnestykket ikke går op

Før eller siden tanker du flere liter, end dine optagne ture kan gøre rede for — en anden kørte, adapteren var taget ud, appen var lukket. I stedet for stiltiende at sluge forskellen viser appen et **afvigelsesbanner** og tilbyder en kort afstemning:

> *Vi fandt en afvigelse på 4,2 L. Du tankede 35,7 L, men dine optagne ture gør kun rede for 31,5 L.*

Den stiller to spørgsmål:

1. **Er alle tankninger på denne tank fuldstændige og korrekte?** — Nej betyder, at en mangler eller er tastet forkert, og appen tilføjer en **korrektionstankning**, så literne går op.
2. **Er alle dine ture optaget?** — Nej betyder, at en tur mangler, og appen tilføjer en **virtuel tur** for den manglende afstand.

Begge poster kan bagefter redigeres og slettes, og begge er mærket som automatisk genereret, så du aldrig forveksler dem med rigtige data. Du kan også vælge **Beslut senere** — banneret bliver, indtil du løser det.

**Hvorfor det betyder noget:** en uløst afvigelse skævvrider stille kalibreringsvinduet. At løse den (eller slette den forkerte post) holder forankringen til standeren troværdig.

---

## Loyalitetskort

**Indstillinger → Kørsel & forbrug → Loyalitetskort** gemmer rabatter pr. liter for de kæder, du bruger. Rabatten anvendes derefter i prissammenligningerne, så en station der ser 2 øre/L dyrere ud, med rette kan rangere som den billigste for dig. Funktionen slås til under Funktioner & brugstilstand → Indtastning og scanning.

---

<details>
<summary>Helskærmsopslag — forbrugsstatistik, hele siden</summary>

</details>

---

**Se også:** Køretøjer og OBD2 · Ture og øko-coaching
**Videre:** Ture og øko-coaching →

---

# Brændstof, ture og kørsel *(flyttet)*

Denne side er delt i tre, så hvert emne har sine egne ankre med henblik på en fremtidig hjælp i appen:

- **Køretøjer og OBD2** — din bil, tankkapacitet, flex-fuel, adapterparring, basisliniekalibrering, automatisk optagelse.
- **Tankbog og forbrug** — tankninger, tankniveau, tankrapport, præcision, pris pr. kilometer pr. brændstof.
- **Ture og øko-coaching** — optagelse, turdetaljen, kørescore, CO₂-oversigt.

Start med **Sådan fungerer Sparkilo**, hvis du vil have begreberne bag alle tre.

---

# Køretøjer og OBD2

Alt hvad appen ved om *din bil*. Det er denne side, der afgør, om forbrugstallene på alle de andre er til at stole på.

---

## Hvorfor appen overhovedet skal bruge et køretøj

Uden køretøj er Sparkilo en prisfinder. Med ét kan den omregne liter og kilometer til *din* pris pr. kilometer, anslå rækkevidde og — med en adapter — modellere det øjeblikkelige brændstofflow.

*Indstillinger → Køretøjer & OBD2. Læg mærke til omfangsmærket på adapterfeltet: adaptere parres **pr. køretøj**, ikke pr. telefon.*

*Det grønne flueben markerer det aktive køretøj — det, nye tankninger og ture tilskrives.*

---

## Identitet og drivlinje

*Kald den, hvad du genkender. Stelnummeret er valgfrit.*

### Stelnummeret, og hvad det giver

At indtaste (eller læse) stelnummeret lader appen slå slagvolumen, cylinderantal, effekt og brændstoftype op — indgangene til forbrugsmodellen. **Læs stelnummer fra bilen** henter det på et sekund via OBD2.

Online-opslag af stelnummeret er et **selvstændigt samtykke** — appen spørger, før den sender noget, og delvis offline-afkodning virker også, hvis du siger nej. Et stelnummer er personoplysning; behandl det sådan.

### Drivlinje

**Forbrænding / Hybrid / Elektrisk** ændrer felterne nedenunder. Forbrænding beder om tankkapacitet, effekt og foretrukket brændstof; elektrisk beder om batteri og stik.

---

## Kapacitet, effekt og flex-fuel

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

*210 prøver ud af 270. To kørselssituationer er stadig tomme, og appen siger det i stedet for at foregive fuldstændighed.*

Hver OBD2-prøve arkiveres i en kørselssituation: **tomgang, stop & go, by, motorvej, deceleration, stigning / lastet, koldstart, vedvarende belastning / trailer, frihjul**. Gennemsnittene pr. situation danner køretøjets basislinje — den model, der giver et plausibelt L/100 km, når adapteren mangler, eller en PID holder op med at svare.

*Situationer med nul prøver er dem, der falder tilbage på standardværdier. Her to: deceleration og trailerkørsel.*

### Regelbaseret eller fuzzy

*Fuzzy er standard og det bedste valg for næsten alle.*

- **Regelbaseret** tildeler hver prøve til præcis én situation. Forudsigeligt, men den skifter fra prøve til prøve mellem « by » og « motorvej », når du kører nær grænsen — omkring 60 km/t for eksempel.
- **Fuzzy** fordeler hver prøve på alle situationer efter, hvor godt den passer. Glat netop dér, hvor den regelbaserede springer, til gengæld sværere at følge prøve for prøve.

### De to nulstillingsknapper — og hvad de reelt gør

- **Nulstil volumetrisk virkningsgrad** kasserer den lærte η_v og genopretter standardværdien 0,85. η_v er en parameter i speed-density-modellen, der anslår luftflow, når der ikke er en luftmassemåling. Nulstil den kun efter et mekanisk indgreb; et mærkeligt tal skyldes oftere et dækningsproblem. Biler, der oplyser flowet direkte (PID 5E), bruger den slet ikke.
- **Nulstil fra køretøjsdatabasen** henter slagvolumen, effekt og standardværdier fra det indbyggede katalog igen og kasserer dine manuelle værdier.
- **Nulstil basislinjen pr. situation** (i basislinjekortet) sletter hver lært prøve og sender dig tilbage til koldstartsstandarder, indtil nye ture fylder profilen.

Ingen af dem rører **pumpeforstærkningen**, som læres af fuld-til-fuld-tankvinduer og lever uden for OBD2-modellen — se Sådan fungerer Sparkilo → Hvordan en liter bliver til et tal.

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

</details>

---

**Se også:** Ture og øko-coaching · Fejlfinding → OBD2
**Videre:** Tankbog og forbrug →

---

# Ture og øko-coaching

Fanen 🛣️ **Ture** er en automatisk logbog plus en kørelærer. Den vises i tilstanden **Fuld**.

---

## Fanen Ture

*Månedens totaler, den seneste tankrapport, og derefter turlisten. Den flydende knap starter en optagelse.*

Månedssammenligningen kræver mindst tre ture pr. måned, før den sammenligner — med færre er gennemsnittet støj, ikke en tendens.

*Kortikonet i bjælken tegner hver optaget tur på ét kort — et års kørsel på et blik, og en nem måde at få øje på de ruter, der er værd at optimere.*

---

## To måder at optage på

### Kun med telefonen

Ingen hardware. Appen registrerer rute, afstand, varighed og hastighed fra GPS, og **modellerer** forbruget ud fra køretøjets kalibrering og din kørsel. Markeret overalt med `~` og en udtrykkelig « GPS-skøn »-note.

Præcisionen starter dårligt og bliver bedre: hvert lukket tankvindue forankrer modellen til standeren igen, så efter en håndfuld fulde tanke lander en ren GPS-tur typisk inden for få procent. Indtil da er den mærket som foreløbig, ikke pyntet.

### Med en OBD2-adapter

Motordata i stedet for udledning: reelt flow (målt hvor bilen oplyser PID 5E), omdrejninger, belastning, speeder. Ingen indlæringsperiode for forbruget, og coachingen får adgang til signaler, GPS ikke kan se — gear, omdrejninger, motorbelastning. Opsætningen står i Køretøjer og OBD2.

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

*Resuméet oplyser sin egen oprindelse — køretøj, adapter, og et **GPS-spor**-mærke på afstanden, så du ved, hvor kilometrene kommer fra.*

*Ruten er farvet efter effektivitet — grøn under 6 L/100 km, ravgul til 10, rød derover. Hvor brændstoffet blev af, geografisk.*

Den farvelægning er appens mest handlingsanvisende visning: den lægger de dyre dele af din daglige rute på et kort. En rød strækning der gentager sig hver dag, er et kryds, en bakke eller en vane, der er værd at ændre.

*Tre blokke: din egen dom, brændstoffordelingen, og hvordan du faktisk belastede motoren.*

- **« Hvordan gik denne tur? »** — *Blød / Moderat / Aggressiv*. Dit svar bruges til at kalibrere kørestilstærskler mod virkelige ture, ikke til at give dig karakter.
- **Hvor dit brændstof blev af** — liter tilskrevet hårde accelerationer over for normal kørsel. Små absolutte tal på en kort tur; det er forholdet, der tæller.
- **Speederposition** og **motoromdrejninger** som fordelinger — den andel af turen der er tilbragt i frihjul, let, fast og fuld gas, og i hvert omdrejningsbånd. En høj andel over 3000 o/min på pendlerturen betyder, at du skifter op for sent, og det koster.

*To diagnoser: hvor komplet GPS-sporet er, og hvordan adapteren opførte sig.*

*Udfoldet forklarer OBD2-kortet sig selv i klart sprog.*

**Læs dette kort, før du tvivler på et forbrugstal.** Det oplyser, hvor mange målinger der bar motordata, den resulterende **dækningsprocent**, adapteren og den forhandlede protokol, sessionens varighed, hvorfor den sluttede (`userStopped`, en afbrydelse, en procesdød), og den afgørende linje: *« Forbrugsværdierne kommer fra adapteren, ikke fra GPS-skøn. »* Ligger dækningen langt under 100 %, blev hullerne fyldt med GPS-skøn, og turens gennemsnit er en blanding.

*Hastighed, flow og omdrejninger på en fælles tidsakse — de tre kurver der forklarer ethvert forbrugstal.*

*Motorbelastning og speeder side om side viser forskellen mellem at lade motoren arbejde og blot at skrue den op i omdrejninger.*

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

*Indstillinger → Kørsel & forbrug. Præstationer og scorer kan skjules i hele appen, hvis gamification ikke er noget for dig.*

---

## CO₂-oversigten

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

</details>

---

**Se også:** Køretøjer og OBD2 · Tankbog og forbrug
**Videre:** Prishistorik og forudsigelser →

---

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

Vil du have et gendannelsesbart øjebliksbillede frem for en dataeksport, så brug **Indstillinger → Sikkerhedskopi & gendannelse** — se Indstillingsoversigt.

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

**Se også:** Indstillingsoversigt · Sådan fungerer Sparkilo → Hvor dine data bor
**Videre:** Fejlfinding og FAQ →

---

# Indstillingsoversigt

Hver skærm i indstillingstræet og — mere brugbart — **hvad hver kontakt koster dig** i batteri, data, præcision eller privatliv.

---

## Formen på det hele

Indstillinger er et **træ med to niveauer**: en rod af emnefelter, én skærm pr. emne, og en nøgleordssøgning på tværs af dem alle.

*Skriv « radius », « OBD2 » eller « tema » i søgefeltet, og det rette felt dukker op — du behøver aldrig huske, hvilket emne der ejer en parameter.*

*Tolv emner i alt. Sådan når du dem: tandhjulet øverst til højre på hovedskærmene.*

Tre designregler gør træet forudsigeligt:

1. **Ét hjem pr. parameter.** Intet optræder to steder; krydshenvisninger peger på den ene ejer.
2. **Omfangsmærker.** Et felt mærket *denne profil*, *alle profiler* eller *dette køretøj* fortæller på forhånd, hvor langt en ændring rækker.
3. **Ærlige tomme tilstande.** Et afsnit, hvis funktion er slået fra, siger det og linker til kontakten i stedet for at skjule sig.

---

## Profiler & region

*Land, sprog, brændstof, søgeradius, ruter · omfang: denne profil*

*Det foretrukne brændstof udledes af standardkøretøjet. Vil du vælge brændstof direkte, så fjern køretøjet fra profilen.*

| Indstilling | Konsekvens |
|---|---|
| **Profilnavn** | Kosmetisk, men det er dét, profilchippen viser |
| **Foretrukket brændstof** | Prisen i overskriften på hvert kort; standard for advarsler; hvad rutesøgningen optimerer for |
| **Standardradius** | Større = flere resultater og langsommere søgninger |

*Rutens standardværdier. **Kandidater pr. prøvepunkt** bytter grundighed for hastighed på lange korridorer.*

*Tre adskilte ting værd at kende.*

- **Undgå motorveje** ændrer selve den beregnede rute, så motorvejsrastepladser holder op med at være kandidater — normalt en besparelse, da motorvejsbrændstof er det dyreste på enhver korridor.
- **Stationsnoter** — *Lokal* (kun denne enhed), *Privat* (synkroniseret til din konto) eller *Delt* (synlig for andre brugere). Det er et privatlivsvalg, ikke et lagringsvalg.
- **Startskærm** — hvad appen åbner på: I nærheden, Nærmeste station, Favoritter eller Kort.

*Overlayets radius og reglen **nærmeste vs billigste i radius** ligger i profilen, så en pendlerprofil og en ferieprofil kan opføre sig forskelligt.*

*Landet afgør dataleverandøren. At ændre det rydder gemte stationsdata.*

*Et **hjemmepostnummer** giver dig områdesøgninger helt uden GPS — den reneste måde at bruge appen på, hvis du aldrig vil dele din placering.*

---

## Køretøjer & OBD2

*Dine biler, tankkapacitet, adapterparring · omfang: dette køretøj*

*Adaptere parres pr. køretøj, så adapterfeltet sender dig ind i et køretøj i stedet for til en global parringsskærm.*

Den fulde gennemgang — stelnummer, kapacitet, flex-fuel, kalibreringstilstande, basislinje, tærskler for automatisk optagelse, servicepåmindelser — står i Køretøjer og OBD2.

---

## Kørsel & forbrug

*Coaching, belønninger, radaren, fejlfinding · omfang: blandet*

*De to øverste punkter er dem, du reelt kommer til at justere.*

| Indstilling | Konsekvens |
|---|---|
| **Vindue for live-forbrug** (3/5/10/30 s) | Længere = roligere og lettere at læse under kørsel; kortere = reagerer hurtigt nok til at lære dig, hvad pedalen koster |
| **Indflyvningsoverlay** | Radius, pristilstand, forespørgselsgulv og skærmfastgørelse for den aktive profil |
| **Øko-coaching i realtid** | Let vibration + vink på skærmen ved hård acceleration i marchhastighed |
| **Talt kørecoaching** | Samme råd læst højt — øjnene bliver på vejen |
| **Glide-coach beta** | Haptisk vink før rødt lys ud fra OpenStreetMap-signaler. **Fra som standard — risiko for distraktion**, og den kræver netværk |

*Belønninger og fejlfinding.*

- **Loyalitetskort** — rabatter pr. liter anvendt i prissammenligningerne, så en nominelt dyrere station med rette kan rangere som billigere for dig.
- **Vis præstationer og scorer** — slået fra skjules alle mærker, scorer og trofæer i hele appen. Intet holder op med at blive målt; det holder op med at blive vist.
- **OBD2-fejlfindingslog** — optager hver session (forbindelse, håndtryk, datatab, genforbindelser) i en eksporterbar XML-log. **Fra som standard**: den skriver løbende og er kun værd at slå til, mens man jager et adapterproblem.

---

## Priser & advarsler

*Advarsler, taleannonceringer, historik, fællesskabsrapporter*

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

***Forbrugsenheden** slår igennem overalt på én gang — live-banner, billede-i-billede-felt, turgennemsnit, statistik, widget.*

- **Afstandsenhed** følger som standard den aktive profils land (km eller miles).
- **Forbrugsenhed**: *Automatisk* (mpg i Storbritannien og USA, L/100 km ellers), eller udtrykkeligt L/100 km, km/L eller mpg.

*Widget-valg bærer mærket **denne profil** og gælder for hver installeret widget, der viser den profil, fra næste opdatering.*

**Indholdsvariant** — *kun aktuel pris*, eller *forudsigende: bedste tidspunkt at tanke* (kræver TFLite-forudsigelsen).

---

## Funktioner & brugstilstand

*Forudindstillinger og hver enkelt kontakt*

*At vælge en forudindstilling **overskriver** hver enkelt kontakt. Har du en håndjusteret blanding, så bliv i Tilpasset.*

Afhængigheder håndhæves, ikke skjules: en kontakt hvis forudsætning er slået fra, forbliver deaktiveret og navngiver forudsætningen.

*Søgning og kort — herunder om tankstationer og ladepunkter overhovedet vises.*

*Priser og advarsler. Prishistorik er forældrefunktionen til forudsigelsen nedenunder.*

*Radaren, dens taleannonceringer og hovedkontakten **Talefeedback** — er den slået fra, åbner appen aldrig en talemotor.*

*Vælgeren **Fra / Brændstof / Brændstof + Ture** er den kompakte form af hele forbrugsstakken.*

| Kontakt | Konsekvens |
|---|---|
| **Forbrugsanalyse** | Analysefanen over tankninger og ture |
| **Gamification** | Kørescorer og optjente mærker |
| **Haptisk øko-coach** | Vibrationsfeedback i realtid under kørsel |
| **Glide-coach** | Øko-råd ud fra OpenStreetMap-lyssignaler — kræver netværk |
| **GPS-turspor** | Gemmer rutepunkterne for hver tur. Fra = mindre database, ingen rutekort |
| **Automatisk optagelse** | Starter en tur, når den parrede adapter forbinder til et køretøj i bevægelse |

*To kontakter her ændrer datakvaliteten frem for brugerfladen.*

- **Eksperimentelle OEM-PID'er** — læser det præcise tankniveau i liter via producentspecifikke PID'er på kompatible adaptere. Bedre tankdata hvor det virker; harmløst hvor det ikke gør.
- **Kræv OBD2 til turoptagelse** — når den er **fra**, optages ture med GPS alene. Coachingen er reduceret (ingen øjeblikkelig L/100 km, færre motorsignaler), men intet er blokeret.
- **Basisliniesynkronisering** — uploader forbrugsbasislinjer pr. køretøj, så en anden enhed kan genbruge dem. Kræver TankSync.

*Indtastning og scanning. Genkendelsen sker på enheden; disse kontakter afgør kun, om genvejene findes.*

*Udvikler og eksperimentelt — kan roligt blive slået fra, medmindre du rapporterer fejl.*

---

## Datakilder & placering

*API-nøgler, GPS, automatisk profilskift*

*Et rødt kryds ved brændstofprisnøglen er den sædvanlige grund til, at en tysk søgning kommer tom tilbage.*

| Indstilling | Konsekvens |
|---|---|
| **Brændstofpriser (Tankerkoenig)** | Kun nødvendig for Tyskland. Gratis, pr. bruger, i det hardwarebaserede pengeskab |
| **EV-opladning (OpenChargeMap)** | Valgfri — erstatter den delte indbyggede nøgle med din egen kvote |
| **Automatisk opdatering** | Opdaterer GPS-positionen før hver søgning. Fra = hurtigere søgninger, muligvis fra en forældet position |
| **Automatisk profilskift** | Skifter profil, når du krydser en grænse, så den rette leverandør og kvalitet bruges automatisk |

---

## Synkronisering & konto

*Denne skærm bringer også problemer frem — her et selvhostet TankSync-skema, der er forældet og derfor stiltiende undlader at synkronisere nogle tabeller.*

Behandlet fuldt ud i Privatliv, data og synkronisering → TankSync. Det væsentlige:

- **Sparkilo Community / din egen database / en gruppes database** — tre opsætningsformer med tre forskellige dataansvarlige.
- **Anonym → e-mail** — *Skift til e-mail* bevarer dine data og din konto og tilføjer en måde at logge ind fra en anden enhed. En anonym konto findes kun på den enhed, der oprettede den.
- **Forældet skema** — selvhostere skal køre opsætnings-SQL'en igen efter en appopdatering, ellers fejler nyere tabeller stiltiende.

---

## Privatliv og data

*To netværksrelaterede privatlivsvalg, hver formuleret som dét, de faktisk afslører.*

- **Hent kortfliser via Sparkilo-proxyen** — *til*: udviklerens EU-server ser dit kortudsnit og din IP og henter fliserne for dig. *Fra*: fliserne kommer direkte fra tile.openstreetmap.org, som så ser din IP. Ingen af mulighederne betyder « intet netværk »; du vælger, hvem du helst vil ses af. F-Droid-versionen bruger aldrig proxyen.
- **Hent mærkelogoer fra internettet** — *fra* som standard; indbyggede generiske logoer bruges. Slået til kommer logoerne fra logo.clearbit.com, som ser din IP.

*Lagerplads, specificeret. Cachen er næsten altid den største andel og den eneste, det er sikkert at smide væk.*

*Cache-styring, med levetiden for hver klasse angivet: søgninger 5 min, stationsdetaljer 15 min, prisforespørgsler 5 min, favoritdata 30 min, byopslag 30 min, postnummer-geokodning 24 t.*

*At rydde cachen sletter kun gemte resultater og priser — profiler, favoritter og indstillinger røres ikke. De næste par søgninger er langsommere; intet går tabt.*

---

## Sikkerhedskopi & gendannelse

*En komplet ZIP med køretøjer, tankninger, ture og ladelogger.*

**Eksportér sikkerhedskopi** skriver ZIP-filen til dine Downloads. **Gendan sikkerhedskopi** tilbyder *flet* eller *erstat* — flet beholder det, der er på enheden, og tilføjer det manglende; erstat rydder først. Brug det før et telefonskift eller en fabriksnulstilling. TankSync er ikke en sikkerhedskopi: det spejler udvalgte kategorier, ikke alt.

---

## Avanceret og udvikler

*GitHub-tokenet er valgfrit — uden det deles feedback om en mislykket scanning manuelt i stedet for automatisk at oprette en sag.*

Punktet **Udviklerværktøjer** vises kun, når udviklertilstand er slået til (Funktioner & brugstilstand → Udvikler og eksperimentelt).

*For almindelige brugere er fejlloggen den nyttige del: **Gem fejllog** skriver rensede spor til Downloads, som du kan vedhæfte en fejlrapport.*

*Opstartssporet er et vandfald af initialiseringsfaser — sådan diagnosticeres en langsom opstart i stedet for at blive gættet.*

***Test indflyvningsoverlay** skubber en syntetisk tilstand i 30 s, så du kan efterprøve billede-i-billede-prisvisningen uden at køre nogen steder.*

---

## Om

***Version og buildnummer** — angiv begge i enhver fejlrapport, og tjek dem først, når en rettelse « ikke virkede » (en butiksudrulning har måske slet ikke nået dig).*

*Appen er gratis, open source og reklamefri. Kildeangivelserne for prisdata og kortdata står nederst, som licenserne kræver.*

---

**Se også:** Sådan fungerer Sparkilo · Privatliv, data og synkronisering
**Videre:** Privatliv, data og synkronisering →

---

# Fejlfinding og FAQ

Nogenlunde ordnet efter, hvor tit det faktisk sker.

---

## Først af alt: tjek din version

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

Baggrund: Sådan fungerer Sparkilo → Hvordan en liter bliver til et tal.

---

## « Vi fandt en afvigelse på X liter »

Du tankede mere, end dine optagne ture kan gøre rede for. Besvar de to spørgsmål i afstemningen: en manglende eller fejltastet tankning får en **korrektionspost**, en ikke-optaget tur får en **virtuel tur**. Begge kan redigeres bagefter. At lade den stå uløst skævvrider kalibreringen, så to tryk er det værd. Se Tankbog og forbrug.

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

Detaljer: Privatliv, data og synkronisering → Dine rettigheder.

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

**Tilbage til:** vejledningens forside
