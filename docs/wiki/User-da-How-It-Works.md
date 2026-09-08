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

<img src="guide/features-and-mode-1.jpg" width="340" alt="Funktionsstyring med forudindstillingerne Basis, Mellem, Fuld og Tilpasset">

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

<img src="guide/profile-edit-1.jpg" width="340" alt="Rediger profil — navn, brændstof afledt af køretøjet, standardradius">

*Indstillinger → Profiler & region → rediger. Det foretrukne brændstof **udledes af dit standardkøretøj** — fjern køretøjet, hvis du selv vil vælge brændstof.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Profilens regionsafsnit — land- og sprogvælgere">

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

<img src="guide/search-results.jpg" width="340" alt="Resultatoverskrift der navngiver den franske officielle priskilde">

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

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Data på denne enhed: hver lokalt gemt datakategori med størrelse og antal">

*Indstillinger → Privatliv og data → Data på denne enhed viser hver kategori med en reel tæller, så intet om dine data er usynligt for dig.*

Kun fire ting forlader nogensinde telefonen, og tre af dem er valgfrie:

| Hvad der forlader | Hvornår | Valgfrit? |
|---|---|---|
| Søgekoordinater eller en regionskode | Ved hver søgning, til landets priskilde | Nødvendigt for live-priser |
| Kortudsnit + din IP | Kortfliser hentet via udviklerens EU-proxy | Ja — proxy fra, så kommer fliserne direkte fra OpenStreetMap |
| Nedbrudsspor | Kun med *Fejlrapportering* slået til | Ja — fra som standard |
| Dine synkroniserede rækker | Kun med *TankSync* slået til | Ja — fra som standard |

**Din identitet indgår aldrig i en prisforespørgsel.** Det fulde regnskab: [Privatliv, data og synkronisering](User-da-Privacy-Profiles-Sync).

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

<img src="guide/trips-tab.jpg" width="340" alt="Tankrapport med dækning og kalibreringsafvigelse">

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
- **Kører du uden at optage, går regnestykket ikke op** — og appen siger det i stedet for at fuske. Se afstemningen i [Tankbog og forbrug](User-da-Fuel-And-Consumption#når-regnestykket-ikke-går-op).

---

## Sådan lærer appen din kørsel

Uafhængigt af pumpeforstærkningen bærer et køretøj en **basislinje pr. kørselssituation**: hvad din bil bruger i tomgang, i stop & go, i byen, på motorvej, ved deceleration, på bakke eller lastet, fra kold, under vedvarende belastning og i frihjul.

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Basisliniekalibrering med antal prøver pr. situation og advarsel om manglende situationer">

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

<img src="guide/settings-root-1.jpg" width="340" alt="Indstillingsroden med emnefelter og søgefeltet">

*Hver parameter har præcis ét hjem. Husker du emnet, behøver du aldrig rulle.*

Fuldt kort over alle skærme: [Indstillingsoversigt](User-da-Settings-Reference).

---

**Videre:** [Find tankstationer →](User-da-Finding-Stations)
