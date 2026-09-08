# Fahrten & Eco-Coaching

Der 🛣️ **Fahrten**-Tab ist ein automatisches Fahrtenbuch plus Fahrtrainer. Er erscheint im Nutzungsmodus **Voll**.

---

## Der Fahrten-Tab

<img src="guide/trips-tab.jpg" width="340" alt="Fahrten-Tab: Monatsvergleich, Tank-Bericht und Fahrtliste mit Aufzeichnungs-Button">

*Monatsvergleich, der jüngste Tank-Bericht, dann die Fahrtliste. Der schwebende Button startet eine Aufzeichnung.*

Der Monatsvergleich braucht mindestens drei Fahrten pro Monat, bevor er vergleicht — mit weniger ist der Mittelwert Rauschen statt Trend.

<img src="guide/trips-map.jpg" width="340" alt="Alle aufgezeichneten Fahrten auf einer Karte, je Fahrt eingefärbt">

*Das Kartensymbol in der Kopfleiste zeichnet jede aufgezeichnete Fahrt auf eine Karte — ein Jahr Fahren auf einen Blick, und ein einfacher Weg, die Strecken zu finden, deren Optimierung sich lohnt.*

---

## Zwei Wege aufzuzeichnen

### Nur mit dem Telefon

Keine Hardware. Die App erfasst Route, Strecke, Dauer und Geschwindigkeit aus GPS und **modelliert** den Verbrauch aus deiner Fahrzeugkalibrierung und deinem Fahren. Überall mit `~` und dem ausdrücklichen Hinweis „GPS-Schätzung" gekennzeichnet.

Die Genauigkeit beginnt schlecht und wird besser: jedes geschlossene Tankfenster verankert das Modell neu an der Zapfsäule, sodass eine reine GPS-Fahrt nach einer Handvoll voller Tanks typischerweise auf wenige Prozent genau liegt. Bis dahin ist sie als vorläufig gekennzeichnet und nicht schöngeredet.

### Mit einem OBD2-Adapter

Motordaten statt Ableitung: echter Kraftstofffluss (gemessen, wo das Auto PID 5E meldet), Drehzahl, Last, Gaspedal. Keine Lernphase beim Verbrauch, und das Coaching bekommt Signale, die GPS nicht sehen kann — Gang, Drehzahl, Motorlast. Einrichtung in [Fahrzeuge & OBD2](User-de-Vehicles-And-OBD2#der-obd2-adapter).

> **Aufzeichnen braucht nie einen Adapter.** Schalte *OBD2 für Fahrtaufzeichnung verlangen* aus (Funktionen & Nutzungsmodus → Verbrauch), um reine GPS-Fahrten aufzuzeichnen; das Coaching ist reduziert, nicht abwesend.

---

## Während der Fahrt

### Die Live-Zahl

Die Schlagzeile ist dein Durchschnitt **über die letzten Sekunden** — verbrauchter Kraftstoff ÷ zurückgelegte Strecke, dieselbe Größe wie im Bordcomputer — beschriftet mit *„Letzte 5 s"*. Im Stand wechselt sie auf L/h, weil L/100 km bei Tempo null undefiniert ist.

Das Fenster änderst du unter **Einstellungen → Fahren & Verbrauch → Live-Verbrauchsfenster** (3 / 5 / 10 / 30 s). Ein **längeres Fenster ist ruhiger und beim Fahren besser lesbar**; ein kürzeres reagiert schnell genug, um dir beizubringen, was dein rechter Fuß kostet. Die Einheit folgt **Einheiten & Darstellung → Verbrauchseinheit** überall: Banner, Bild-in-Bild-Kachel, iOS Live Activity und Fahrtdurchschnitt.

### Querformat = die Ansicht fürs Auto

Drehst du das Telefon während einer Aufzeichnung quer, wird der Bildschirm zu einem berührungsfreien, überblickbaren Layout: links die große Momentanverbrauchs-Zahl mit dem Coaching-Hinweis darunter (*Fuß vom Gas* / *vorausschauen* / *sanft beschleunigen* bei GPS, *hochschalten* / *runterschalten* / *Gas zurücknehmen* bei OBD2) und eine große Tempoanzeige; rechts die Nächste-Station-Karte über einem 2×2-Raster aus **Strecke · Ø · Dauer · Verbrauch**.

Nichts scrollt und nichts ist klein. Telefon in die Halterung, nie wieder anfassen.

### Bild-in-Bild

Schrumpfe die App in eine schwebende Kachel und behalte deine Navi-App oben. Die Kachel passt sich dem Kontext an:

| Situation | Große Zahl | Nebenzeile |
|---|---|---|
| OBD2 verbunden | Live L/100 km (L/h im Stand) | Strecke · Dauer |
| Nur GPS, in Fahrt | Bisherige Strecke | Dauer |
| Aufwärmen | Verstrichene Zeit | — |

### Das Annäherungs-Overlay

Kommst du in den konfigurierten Radius einer Station, wechselt die Kachel auf eine große **Kraftstoffpreis**-Anzeige — Preis für deine Sorte, Marke, Entfernung, auf einen Blick lesbar.

Auf welche Station sie sich fixiert, legst du unter **Einstellungen → Fahren & Verbrauch → Overlay bei Annäherung** fest: **nächste** (die erste Station, deren Radius du betreten hast) oder **günstigste im Radius**. Beim Verlassen bleibt die Preisanzeige fünf Sekunden als Karenzzeit stehen, damit ein Vorbeifahren nicht flackert.

**Ohne Fahrt testen:** Einstellungen → Entwicklerwerkzeuge → **Annäherungs-Overlay testen** setzt 30 Sekunden lang einen synthetischen Zustand.

---

## Eine Fahrt lesen

<img src="guide/trip-detail-1.jpg" width="340" alt="Fahrt-Zusammenfassung: Datum, Fahrzeug, Adapter, Strecke, Dauer, Verbrauch, Kraftstoff, Kosten und Geschwindigkeiten">

*Die Zusammenfassung nennt ihre eigene Herkunft — Fahrzeug, Adapter, und ein **GPS-Spur**-Badge an der Strecke, damit du weißt, woher die Kilometer kommen.*

<img src="guide/trip-detail-2.jpg" width="340" alt="Nach Effizienz eingefärbte Route mit Legende und die Karte der größten Verschwender">

*Die Route ist nach Effizienz gefärbt — grün unter 6 L/100 km, gelb bis 10, rot darüber. Wohin der Kraftstoff ging, geografisch.*

Diese Einfärbung ist die handlungsstärkste Ansicht der App: sie legt die teuren Teile deines Arbeitswegs auf eine Karte. Ein roter Abschnitt, der sich täglich wiederholt, ist eine Kreuzung, ein Hügel oder eine Gewohnheit, die sich zu ändern lohnt.

<img src="guide/trip-detail-3.jpg" width="340" alt="Wie war die Fahrt, wohin der Kraftstoff ging, Gaspedal- und Drehzahlverteilung">

*Drei Blöcke: dein eigenes Urteil, die Kraftstoffzuordnung und wie du den Motor wirklich genutzt hast.*

- **„Wie war diese Fahrt?"** — *Sanft / Moderat / Aggressiv*. Deine Antwort kalibriert die Fahrstil-Schwellen an echten Fahrten; sie benotet dich nicht.
- **Wohin dein Kraftstoff ging** — Liter, die harter Beschleunigung gegenüber normalem Fahren zugeordnet werden. Auf einer kurzen Fahrt kleine Absolutwerte; das Verhältnis ist der Punkt.
- **Gaspedalstellung** und **Drehzahl** als Verteilungen — der Anteil der Fahrt im Segeln, leicht, kräftig und Vollgas, und in jedem Drehzahlband. Ein hoher Anteil über 3000/min auf dem Arbeitsweg heißt: du schaltest zu spät hoch, und das ist teuer.

<img src="guide/trip-detail-4.jpg" width="340" alt="GPS-Abtastdiagnose und die eingeklappte Karte zur OBD2-Kommunikationsgesundheit">

*Zwei Diagnosen: wie vollständig die GPS-Spur ist und wie sich der Adapter verhalten hat.*

<img src="guide/trip-obd2-health.jpg" width="340" alt="Ausgeklappte OBD2-Kommunikationsgesundheit: Stichproben, Abdeckung, Adapter, Protokoll, Dauer, Sitzungsende">

*Ausgeklappt erklärt sich die OBD2-Karte im Klartext.*

**Lies diese Karte, bevor du an einer Verbrauchszahl zweifelst.** Sie nennt, wie viele Stichproben Motordaten trugen, die resultierende **Abdeckung in Prozent**, Adapter und ausgehandeltes Protokoll, die Sitzungsdauer, warum die Sitzung endete (`userStopped`, ein Abbruch, ein Prozesstod), und den entscheidenden Satz: *„Die Verbrauchswerte kommen vom Adapter, nicht aus GPS-Schätzungen."* Liegt die Abdeckung deutlich unter 100 %, wurden die Lücken mit GPS-Schätzungen gefüllt und der Fahrtdurchschnitt ist eine Mischung.

<img src="guide/trip-detail-5.jpg" width="340" alt="Diagramme: Geschwindigkeit, Kraftstofffluss und Drehzahl über die Fahrt">

*Geschwindigkeit, Kraftstofffluss und Drehzahl auf gemeinsamer Zeitachse — die drei Kurven, die jede Verbrauchszahl erklären.*

<img src="guide/trip-detail-6.jpg" width="340" alt="Diagramme: Drehzahl, Motorlast, Gaspedalstellung und Kühlmitteltemperatur">

*Motorlast und Gaspedal nebeneinander zeigen den Unterschied zwischen Arbeiten lassen und bloßem Hochdrehen.*

<img src="guide/trip-detail-7.jpg" width="340" alt="Diagramme: Kühlmitteltemperatur, Höhengewinn, Ansauglufttemperatur und Zündzeitpunkt">

*Die Höhe zählt mehr, als die meisten erwarten: eine Steigung erklärt einen Verbrauchsausschlag, der sonst wie schlechtes Fahren aussähe.*

Die Aktionen **Teilen** und **Löschen** stehen in der Kopfleiste. Teilen exportiert die Fahrt samt GPX-Spur.

---

## Fahrnote und Coaching

Mit Adapter wird jede Fahrt mit bis zu 100 Punkten bewertet — zusammengesetzt aus Leerlauf, harter Beschleunigung, hartem Bremsen, Zeit bei hoher Drehzahl, Vollgas, Untertourigkeit, Ruckeln, dauerhaft hohem Tempo, aggressiver Pedalarbeit und fettem Gemisch. Die Aufschlüsselung nennt, welches Verhalten am teuersten war — die Note ist also eine Diagnose, keine Zensur.

Die Karte **größte Verschwender** macht daraus Sätze, mit denen man etwas anfangen kann — und sagt *„Keine nennenswerte Ineffizienz — weiter so"*, wenn es nichts zu beanstanden gibt, statt eine Beschwerde zu erfinden.

Coaching gibt es auch während der Fahrt:

- **Echtzeit-Eco-Coaching** — leichte Vibration plus Bildschirmhinweis, wenn du bei Reisegeschwindigkeit stark beschleunigst.
- **Gesprochenes Fahrcoaching** — derselbe Rat vorgelesen, damit die Augen auf der Straße bleiben.
- **Glide-Coach (Beta)** — dezente Vibration, wenn du vor einer roten Ampel vom Gas gehen solltest, anhand von Ampelpositionen aus OpenStreetMap. **Standardmäßig aus: Ablenkungsrisiko**, und er braucht Netz, um die Ampeln deiner Gegend zu laden.

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching-Schalter, Belohnungen, Kundenkarten, Erfolge und OBD2-Debug-Protokoll">

*Einstellungen → Fahren & Verbrauch. Erfolge und Noten lassen sich app-weit ausblenden, wenn Gamification nichts für dich ist.*

---

## Das CO₂-Dashboard

<img src="screenshots/carbon-dashboard.png" width="340" alt="CO2-Dashboard: Kosten und CO2 nach Fahrtlänge und Geschwindigkeitsband">

*Kosten und CO₂ aus denselben gemessenen Litern, zweifach aufgeschlüsselt.*

- **Nach Fahrtlänge** — Kurzstrecken sind meist am teuersten pro Kilometer, weil ein kalter Motor säuft. Das quantifiziert zu sehen bringt Leute dazu, Erledigungen zu bündeln.
- **Nach Geschwindigkeitsband** — wie viel Kraftstoff auf Kriechen in der Stadt gegenüber Rollen auf der Autobahn entfällt.

Es entsteht vollständig aus Daten auf deinem Telefon und wird unter Funktionen & Nutzungsmodus → Verbrauch eingeschaltet.

---

## Exporte und Diagnosen

- **Teilen** einer einzelnen Fahrt (Zusammenfassung + GPX).
- **Fahranalyse-Trace exportieren** — GPS-Kennzahlen, Note und Lehren der Fahrt als JSON, mit Freitextfeld, wie sich die Fahrt wirklich anfühlte. Zurückgeteilt hilft das, die Fahrstil-Schwellen an echten Fahrten zu kalibrieren. Entwicklermodus-Funktion.
- **Meine Daten exportieren → ZIP-Archiv** unter Datenschutz & Daten → Exportieren oder löschen enthält jede Fahrt und je ein GPX.

---

<details>
<summary>Gesamtansicht — Fahrtdetails, ganze Seite</summary>

<img src="guide/full/trip-detail.jpg" width="420" alt="Vollständige Fahrtdetailseite aus acht Aufnahmen zusammengesetzt">

</details>

---

**Siehe auch:** [Fahrzeuge & OBD2](User-de-Vehicles-And-OBD2) · [Tankbuch & Verbrauch](User-de-Fuel-And-Consumption)
**Weiter:** [Preisverlauf & Prognosen →](User-de-Price-History-And-Predictions)
