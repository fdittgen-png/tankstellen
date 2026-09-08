# Ruteplanlægning

Ikke « billigst i nærheden af mig » men **billigst på vejen** — forskellen er flere kroner værd på enhver længere tur.

---

## Start en rutesøgning

<img src="guide/search-criteria-route-1.jpg" width="340" alt="Kriterier i rutetilstand: start, stop, destination, brændstof, segment, omvej, mindste besparelse">

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

<img src="guide/search-criteria-route-2.jpg" width="340" alt="Nederste del af rutekriterierne: kun åbne, faciliteter, mærker, gem standardværdier">

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

**Du skal bruge en profil pr. land** med den rigtige foretrukne kvalitet, ellers har den anden strækning intet at prissætte og viser `--`. Se [Sådan fungerer Sparkilo → Profiler](User-da-How-It-Works#profiler-én-kontekst-ét-sæt-standardværdier).

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

<img src="guide/profile-edit-2.jpg" width="340" alt="Ruteplanlægningsparametre i profileditoren">

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

**Se også:** [Find tankstationer](User-da-Finding-Stations) · [Indstillingsoversigt](User-da-Settings-Reference#profiler--region)
**Videre:** [Favoritter og advarsler →](User-da-Favorites-And-Alerts)
