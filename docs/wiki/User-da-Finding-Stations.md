# Find tankstationer

Niveau 1 af de [tre spareniveauer](User-da-How-It-Works#de-tre-spareniveauer): betal mindre pr. liter.

---

## Én knap, én mental model

Den nederste bjælke har én søgeudløser — den hævede grønne knap i midten. Den er kontekstafhængig frem for modal:

- **Fra enhver fane** → åbner kriteriearket.
- **Fra resultaterne eller kortet** → genåbner arket med dine seneste værdier.
- **Inde i arket** → udfører søgningen.

Etiketten fortæller hvad den vil gøre, og i rutetilstand er den slået fra, indtil der er en destination. Der findes bevidst ikke separate knapper til « søg i nærheden » og « søg langs ruten ».

---

## Sæt kriterierne

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Kriterier: nærhed eller rute, adresse, brændstofchips, radius, kun åbne, faciliteter, mærker">

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

### Sådan virker det i praksis

En søgning i nærheden sender **dine koordinater (eller en regionskode) og en radius** til dit lands officielle leverandør — aldrig din identitet. Lande med en daglig samlefil (Spanien, Italien) filtreres på enheden; de søgninger kræver slet ingen netværkskald, når filen er cachet.

---

## At læse et resultatkort

<img src="guide/search-results.jpg" width="340" alt="Resultatliste med pris, tendenspil, friskhed, faciliteter, afstand og stjerne">

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

Friskhed er en egenskab ved **landets leverandør**, ikke ved appen. En spansk pris på 14 timer er ikke en fejl: det land udgiver én gang dagligt. Se [Sådan fungerer Sparkilo → Én kilde pr. land](User-da-How-It-Works#én-datakilde-pr-land).

### Strygebevægelser

- **Stryg til højre** — åbn i din navigationsapp (Google Maps, Waze, OsmAnd, Organic Maps).
- **Stryg til venstre** — skjul stationen fra alle fremtidige resultater. Den vises igen fra **Privatliv og data → Data på denne enhed → Ignorerede stationer**.

---

## Stationsdetaljer

<img src="guide/station-detail-1.jpg" width="340" alt="Stationsdetalje: pristabel pr. brændstof, tilføj tankning, åbningstider, zone">

*Tryk på et kort. Overskriften falder tilbage fra mærke til navn til vej, så et Intermarché med tomt mærkefelt stadig står som « Intermarché ».*

Den øverste blok er den **fulde pristabel** — hver kvalitet leverandøren oplyser for stationen, med `--` hvor den ikke oplyser nogen. Det er den hurtigste måde at se, om den billige E85-station også holder på diesel.

**Tilføj tankning** forudfylder station, brændstof og pris i formularen — appens største tidsbesparelse, hvis du registrerer dine tankninger.

<img src="guide/station-detail-2.jpg" width="340" alt="Fortsat detalje: zone, faciliteter, betalingsmidler, din bedømmelse, prishistorik">

*Længere nede: tjenester, accepterede betalingsmidler, din egen private stjernebedømmelse, og den lokale 30-dages prishistorik.*

Handlingerne i topbjælken er, fra venstre mod højre: **opret en prisadvarsel**, **scan en betalings-QR**, **rapportér en forkert pris** og **gør til favorit**.

---

## Kortet

<img src="guide/map-view.jpg" width="340" alt="Kort med prisfarvede nåle, radiuscirkel og billig/dyr-signatur">

*Farven er relativ til det, der er på skærmen: grøn er den billigste synlige, rød den dyreste. Bundlinjen angiver antal stationer, radius og datas alder.*

- **Klyngemarkører** samler nåle ved udzoom; et tryk zoomer ind.
- **Langt tryk** hvor som helst for at sætte din egen markør og søge derfra.
- **EV-knappen** øverst til højre skifter kortet til ladepunkter — se [Elopladning](User-da-EV-Charging).
- **Del** sender det aktuelle udsnit til en anden.

Fliserne kommer fra OpenStreetMap. Som standard går de gennem udviklerens EU-proxy, så OpenStreetMap aldrig ser din IP; du kan slå proxyen fra i Indstillinger → Privatliv og data og hente direkte. F-Droid-versionen bruger aldrig proxyen.

---

## Tankstationsradaren

En live-scanning omkring din position, bygget til brug **under kørsel**.

<img src="screenshots/radar-start.png" width="340" alt="Pillen « Start tankstationsradar » på resultatskærmen">

*Efter enhver søgning i nærheden dukker en flydende pille op nederst til højre. Ét tryk starter radaren.*

### Sådan virker det i praksis

Radaren opdaterer din GPS-position, henter stationernes **placeringer** i en bred 60 km-korridor og fletter en direkte forespørgsel i radius ind — den kan derfor aldrig vise mindre end en almindelig søgning. Stationer flytter sig ikke, så de placeringer caches i op til en time og genbruges; kun **prisen** på en station du nærmer dig, hentes lige når det gælder. Det er dét, der gør en kontinuerligt kørende radar billig i både data og batteri.

<img src="screenshots/radar-active.png" width="340" alt="Radar i drift: live-prisnåle og afstandssorteret liste med nærhedsbjælker">

*I drift: resultater sorteret efter afstand, hver med en bjælke der fyldes, jo tættere du kommer.*

### Under en turoptagelse

Radaren fastgør et **Nærmeste station**-kort øverst på optageskærmen — navn, pris for dit brændstof, afstand, og en bjælke der når 100 % ved ankomst. Stryg til side for at bladre gennem kandidaterne. Kører du ind i den indstillede indflyvningsradius, skifter billede-i-billede-feltet til en stor prisvisning; se [Ture og øko-coaching → Indflyvningsoverlayet](User-da-Trips-And-Coaching#indflyvningsoverlayet).

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

<img src="guide/full/station-detail.jpg" width="420" alt="Fuld stationsdetaljeside sammensat af to optagelser">

</details>

---

**Se også:** [Ruteplanlægning](User-da-Route-Planning) · [Favoritter og advarsler](User-da-Favorites-And-Alerts) · [Prishistorik](User-da-Price-History-And-Predictions)
**Videre:** [Ruteplanlægning →](User-da-Route-Planning)
