# Routenplanung

Nicht „am günstigsten in der Nähe", sondern **am günstigsten auf dem Weg** — der Unterschied ist auf jeder längeren Fahrt mehrere Euro wert.

---

## Eine Routensuche starten

<img src="guide/search-criteria-route-1.jpg" width="340" alt="Kriterien im Routenmodus: Start, Zwischenstopp, Ziel, Kraftstoff, Segment, Umweg, Mindestersparnis">

*Auf **Suche** tippen → auf **Entlang der Route suchen** wechseln. Der Such-Button bleibt gesperrt, bis Ziel und Kraftstoffsorte gesetzt sind.*

| Feld | Bedeutung |
|---|---|
| **Start** | Deine aktuelle Position oder ein getippter Ort / eine PLZ |
| **Zwischenstopp hinzufügen** | Zwischenziele — der Korridor folgt ihnen |
| **Ziel** | Ort, Postleitzahl oder Koordinaten |
| **Kraftstoff** | Die Sorte, die entlang des Korridors bepreist wird |
| **Routensegment** | Die günstigste Station alle *n* km zeigen (50–1000 km) |
| **Maximaler Umweg** | Wie weit abseits der direkten Linie eine Station liegen darf |
| **Mindestersparnis** | Blendet Stopps aus, die den Korridordurchschnitt nicht um mindestens diesen Betrag schlagen; *Aus* zeigt alles |

<img src="guide/search-criteria-route-2.jpg" width="340" alt="Untere Hälfte der Routenkriterien: Jetzt geöffnet, Ausstattung, Marken, Als Standard speichern">

*Dieselben Filter für Öffnung, Ausstattung und Marken wie bei einer Umkreissuche gelten auch für den Korridor.*

### Wie es tatsächlich funktioniert

1. Die App ruft den öffentlichen Routendienst **OSRM** auf und erhält die Straßenlinie deiner Route.
2. Entlang dieser Linie werden Kandidatenpunkte gesetzt, im Abstand deiner **Segmentlänge**.
3. Um jeden Punkt wird der Preisanbieter **des Landes abgefragt, in dem dieser Punkt liegt**, mit der Kraftstoffsorte aus dem Profil dieses Landes.
4. Innerhalb jedes Segments werden die Kandidaten nach deiner Strategie und dem **maximalen Umweg** sortiert.

### Was das in der Praxis heißt

- **Die Segmentlänge ist der eigentliche Regler.** 50 km auf 600 km ergibt zwölf Vorschlagslisten, 200 km ergibt drei. Wähle sie danach, wie oft du wirklich hältst.
- **Der maximale Umweg misst ab der direkten Route**, nicht ab dir. 5 km heißt „bis zu 5 km Mehrweg".
- **Lange Routen dauern länger.** Ein 600-km-Korridor tastet viele Punkte über womöglich mehrere Anbieter ab.
- Ist der Start „automatisch GPS" und das Signal fällt aus, greift die Suche auf die letzte bekannte Position zurück.

---

## Grenzüberschreitende Korridore

Überquert eine Route eine Grenze, wird **jedes Land des Korridors über seinen eigenen Anbieter abgefragt**, und die Kopfzeile nennt alle:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Weil die Sorten je Land unterschiedlich sind, zeigt ein grenzüberschreitendes Ergebnis zu Recht E85 auf dem französischen und Gasolina 95/E5 auf dem spanischen Abschnitt. Beide sind für ihre Seite korrekt bepreist, nie gemittelt.

**Du brauchst ein Profil pro Land** mit der richtigen bevorzugten Sorte, sonst hat der zweite Abschnitt nichts zu bepreisen und zeigt `--`. Siehe [Wie Sparkilo funktioniert → Profile](User-de-How-It-Works#profile-ein-kontext-ein-satz-voreinstellungen).

---

## Ergebnisse laufen nach und nach ein

Eine langsame nationale Schnittstelle soll den Rest des Korridors nicht aufhalten, deshalb kommen Ergebnisse **schrittweise**: die Stationen jedes Landes erscheinen, sobald der Anbieter antwortet, mit einem Banner, das die noch ausstehenden Quellen nennt. Du kannst ein günstiges Ergebnis antippen, sobald es da ist.

---

## Die vier Strategien

### 🏆 Beste Stopps *(Standard)*
Zeigt die 3–5 günstigsten realistisch erreichbaren Stationen als sortierte Chips oben. Umwege bleiben klein. Das wollen die meisten Fahrer tatsächlich.

### 🎯 Günstigste
Die eine günstigste Station der gesamten Route. Ideal, wenn du einmal tankst und die maximale Ersparnis pro Liter willst.

### ⚖️ Ausgewogen
Bewertet Kandidaten nach Preis *und* Nähe zur Linie. Eine Station 5 km abseits, aber 10 ct/L günstiger, gewinnt; eine 50 km abseits muss dramatisch günstiger sein.

### 📏 Gleichmäßig
Teilt die Route in gleiche Abschnitte und schlägt pro Abschnitt einen Stopp vor. Gut für lange Fahrten mit mehreren Tankstopps.

Die Standardstrategie, Segmentlänge, maximaler Umweg, Mindestersparnis und die Zahl der Kandidaten pro Abtastpunkt werden **pro Profil** gespeichert:

<img src="guide/profile-edit-2.jpg" width="340" alt="Routenplanungs-Parameter im Profil-Editor">

*Einstellungen → Profile & Region → bearbeiten → Routenplanung. Einmal hier setzen statt bei jeder Fahrt im Dialog nachjustieren.*

---

## Ergebnisse lesen

Jede Zeile hat zwei Zahlen, die eine Umkreissuche nicht hat:

- **Entfernung ab Start** — wo auf der Route die Station liegt, damit du sie mit dem Zeitpunkt abgleichen kannst, an dem dein Tank leer wird.
- **Umweg** — die Mehrkilometer gegenüber der direkten Linie.
- **Ersparnis gegenüber dem Durchschnitt** — gegen den Korridordurchschnitt, nicht gegen einen nationalen.

Mit **Alle Stationen** siehst du statt der Auswahl jede Station entlang der Route. Die Karte zeichnet die Linie mit allen Nadeln.

---

## Autobahnen meiden

**Einstellungen → Profile & Region → Anzeige & Stationen → Autobahnen meiden** lässt den Router Landstraßen bevorzugen. Das ändert die *Route selbst* und damit, welche Stationen überhaupt Kandidaten sind — Autobahnraststätten verschwinden aus dem Korridor, statt nur schlechter bewertet zu werden. Genau deshalb nützlich: Autobahnkraftstoff ist auf fast jeder Route der teuerste.

---

## Gespeicherte Routen

Auf dem Ergebnisbildschirm **Route speichern** antippen. Gespeicherte Routen stehen oben im Routenformular; ein Tipp führt denselben Korridor mit **frischen Preisen** erneut aus. Gespeichert wird die Geometrie, nicht die Preise.

---

**Siehe auch:** [Tankstellen finden](User-de-Finding-Stations) · [Einstellungen-Referenz](User-de-Settings-Reference#profile--region)
**Weiter:** [Favoriten & Alarme →](User-de-Favorites-And-Alerts)
