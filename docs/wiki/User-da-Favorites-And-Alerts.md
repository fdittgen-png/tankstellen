# Favoritter og prisadvarsler

Fanen ⭐ er din kortliste plus robotterne, der holder øje med den for dig.

---

## Favoritter

<img src="guide/favorites.jpg" width="340" alt="Fanen Favoritter med to gemte stationer, priser pr. brændstof og advarselsfanen">

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

<img src="guide/price-alerts.jpg" width="340" alt="Advarselsskærm: tællere aktive/i dag/denne uge, stations- og zoneadvarsler">

*Tre tællere øverst — aktive regler, udløsninger i dag og denne uge — derefter de to advarselstyper. Bundlinjen stempler det seneste baggrundstjek.*

Der findes to typer, og de besvarer forskellige spørgsmål.

### Stationsadvarsel — « sig til når *denne* stander falder »

Oprettes fra en stations detaljeside (klokkeikonet). Vælg brændstof, sæt en grænse, gem. Bedst til den station, du i forvejen bruger.

### Zoneadvarsel — « sig til når *et sted her omkring* falder »

<img src="guide/price-alert-create.jpg" width="340" alt="Opret en zoneadvarsel: etiket, brændstoftype, grænse, radius, tjekfrekvens, position eller postnummer">

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
- **En nyttig sidegevinst:** samme tjek skriver en prisregistrering i din lokale historik. En station under advarsel opbygger derfor sin 30-dages historik på timer i stedet for uger — og det er dét, der får banneret *bedste tidspunkt at tanke* frem hurtigt. Se [Prishistorik](User-da-Price-History-And-Predictions#læringsfasen).
- **Er notifikationer slået fra på systemniveau**, kan appens kontakt intet udløse.

---

## Statistik

Tællerne øverst viser hvor mange regler der er aktive, og hvor tit de er udløst i dag og denne uge — en hurtig kontrol af, om baggrundsopgaven virkelig kører. En række nuller med flere aktive advarsler og et gammelt « seneste tjek »-stempel er det klassiske tegn på en batterisparer, der dræber opgaven.

---

## Stop advarsler

At slå en advarsel fra sætter den på pause uden at miste reglen; stryg til venstre sletter den. At fjerne stationen fra favoritter sletter **ikke** dens advarsler.

---

**Se også:** [Prishistorik og forudsigelser](User-da-Price-History-And-Predictions) · [Indstillingsoversigt → Priser & advarsler](User-da-Settings-Reference#priser--advarsler)
**Videre:** [Elopladning →](User-da-EV-Charging)
