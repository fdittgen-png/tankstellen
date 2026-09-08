# Tankbuch & Verbrauch

Ebene 2 und 3 der [drei Spar-Ebenen](User-de-How-It-Works#die-drei-spar-ebenen): wie viel du verbrauchst und was es wirklich gekostet hat. Der ⛽ **Kraftstoff**-Tab erscheint in den Nutzungsmodi **Mittel** und **Voll**.

---

## Der Kraftstoff-Tab auf einen Blick

<img src="guide/fuel-tab.jpg" width="340" alt="Kraftstoff-Tab: Tankfüllstand mit Reichweite, Verbrauchsstatistik mit Genauigkeits-Badge und Liste der Tankfüllungen">

*Drei Blöcke: was im Tank ist, was dein Fahren kostet, und was du tatsächlich getankt hast.*

### Tankfüllstand und Reichweite

Die Anzeige ist **an deiner letzten vollen Tankfüllung verankert** und wird dann um den Kraftstoff belastet, den deine aufgezeichneten Fahrten verbraucht haben. Der Datumsstempel unter dem Balken nennt die Verankerung.

Zwei Reichweiten werden bewusst gezeigt:

- **„≈ 548 km beim Verbrauch deiner letzten Tankfüllung"** — jüngstes Verhalten, nützlich für heute.
- **„Langfristiger Durchschnitt: ≈ 611 km"** — dein historischer Mittelwert, nützlich zum Planen.

Weichen sie stark ab, hat sich zuletzt etwas geändert: Dachbox, Winter, anderer Streckenmix oder ein Kraftstoffwechsel.

> Ist ein OBD2-Adapter verbunden und liefert dein Auto die Tankfüllstand-PID, wechselt die Anzeige auf den **Tanksensor** und sagt das. Dieser Wert ist eine Messung, keine Ableitung, und überlebt auch nicht aufgezeichnete Fahrten.

### Die Verbrauchsstatistik-Karte

Die drei Badges sind die Ehrlichkeitsschicht:

| Badge | Bedeutung |
|---|---|
| **Genauigkeit: Hoch · ±3-7 %** | Tankfüllungen und OBD2-Fahrten füttern das Modell |
| **Genauigkeit: Mittel** | Tankfüllungen verankern es, aber noch keine OBD2-Fahrt hat es gefüttert |
| **Genauigkeit: Niedrig** | Nur GPS, nichts verankert — trage ein paar volle Tankfüllungen ein |
| **η_v : 0,93 · 6 Stichproben** | Der gelernte volumetrische Wirkungsgrad des Speed-Density-Modells und seine Stichprobenzahl |

Darunter: Durchschnitt L/100 km, Durchschnittskosten pro km, Liter gesamt, Ausgaben gesamt, Anzahl Tankvorgänge. Ein Tipp öffnet die vollständige [Verbrauchsstatistik](#verbrauchsstatistik).

---

## Eine Tankfüllung erfassen

Auf **➕ Tankfüllung hinzufügen** tippen — oder viel schneller: **Tankfüllung erfassen** direkt auf der Detailseite einer Station, die Station, Sorte und Preis vorbelegt.

<img src="screenshots/consumption-pick-station.png" width="340" alt="Tankformular mit Marke, Sorte und Preis aus einer kürzlichen Suche vorbelegt">

*Von einer Station aus stimmen bereits drei Felder — du tippst Liter, Summe und Kilometerstand.*

| Feld | Warum es zählt |
|---|---|
| **Datum** | Ordnet die Tankfenster |
| **Fahrzeug** | Ordnet Betankung und Kalibrierung zu |
| **Kraftstoffsorte** | Bei einem Flex-Fuel-Auto hängt der ganze Vergleich an diesem Feld |
| **Liter** | Der Zähler der Zapfsäulen-Wahrheit |
| **Gesamtkosten** | Kosten pro km, Monatsausgaben |
| **Kilometerstand** | **Das wichtigste Feld im Formular** |
| **Voller Tank** | Schließt ein Kalibrierungsfenster — siehe unten |
| Station, Notizen | Optional |

### Warum der Kilometerstand das kritische Feld ist

Verbrauch ist Liter ÷ Kilometer. Die Liter kommen vom Kassenbon und sind exakt. Die Kilometer kommen aus *deinen beiden Tachoablesungen*. Ein 20-km-Tippfehler auf einem 600-km-Tank sind 3 % Fehler im Ergebnis — und weil dieses Ergebnis den Schätzer neu kalibriert, pflanzt sich der Fehler in jede künftige Fahrtschätzung fort. Das Formular verweigert einen Kilometerstand unter dem der vorherigen Betankung, denn Strecke läuft nicht rückwärts.

### Der Haken „Voller Tank"

Setze ihn, wann immer du randvoll getankt hast. Erst das macht aus zwei Tankfüllungen ein **geschlossenes Tankfenster** mit einem physikalisch wahren Verbrauchswert.

Teilbetankungen werden trotzdem erfasst, zählen für die Kosten und stehen in der Liste — sie können nur kein Fenster schließen. Die Statistik zeigt ein Banner, das *„Teilbetankungen warten auf einen vollen Tank — nicht im Durchschnitt"* zählt, damit du immer weißt, was in den Zahlen steckt.

### Scannen statt tippen

- **Zapfsäulenanzeige scannen** — Kamera auf das Display halten; die App liest Liter, Summe und Preis.
- **Kassenbon scannen** — dasselbe vom gedruckten Beleg.
- **Ein Belegfoto aus einer anderen App teilen** — direkt ins Tankformular.

Die Erkennung läuft **auf dem Gerät**; das Bild wird nie hochgeladen. Sieh die Werte vor dem Speichern immer kurz an — ein Scan ist ein Vorsprung, kein Orakel. Bei Fehllesungen legt *Scanfehler melden* ein Issue mit dem Ausschnitt an, damit die Erkennung besser wird.

> **F-Droid-Build:** Texterkennung auf dem Gerät steckt nur in den Play-/App-Store-Builds. Der GMS-freie F-Droid-Build hat kein Scannen — dort tippt man Tankfüllungen von Hand. Alles andere ist identisch.

---

## Der Tank-Bericht — der Moment der Wahrheit

Jedes Mal, wenn ein voller Tank schließt, veröffentlicht die App einen Bericht. Im Fahrten-Tab sieht er so aus:

<img src="guide/trips-tab.jpg" width="340" alt="Tank-Bericht: 6,4 L/100 km, Differenz zum vorherigen Tank, Abdeckungsbalken und Kalibrierungsurteil">

*Eine Karte, vier verschiedene Aussagen — und sie sind bewusst nicht dieselbe Zahl.*

| Zeile | Was es ist |
|---|---|
| **6,4 L/100 km** | Die **Zapfsäulen-Wahrheit** dieses Tanks: getankte Liter ÷ Tacho-Kilometer |
| **1,5 L/100 km weniger als beim vorherigen Tanken** | Trend gegen den letzten geschlossenen Tank |
| **559 km · 35,7 L · 32,12 €** | Das rohe Fenster |
| **Aufzeichnungen decken 81 % dieses Tanks ab** | Wie viel dieser Kilometer du wirklich aufgezeichnet hast |
| **Aufgezeichneter Anteil: 10,5 L/100 km** | Was allein die aufgezeichneten Kilometer im Mittel ergaben |
| **Aufgezeichnete Schätzungen liegen 39 % über der Zapfsäulen-Wahrheit** | Das Kalibrierungsurteil — der Schätzer las zu hoch und wurde jetzt korrigiert |

### Richtig lesen

Der aufgezeichnete Anteil und die Zapfsäulen-Wahrheit **dürfen abweichen**, aus zwei Gründen, die leicht verwechselt werden:

1. **Auswahl.** Du zeichnest die Fahrten auf, die du aufzeichnest. Sind deine 81 % überwiegend kurze Stadtfahrten und die fehlenden 19 % eine Autobahnetappe, liegt der aufgezeichnete Anteil zu Recht höher als der Tankdurchschnitt. Nichts ist kaputt.
2. **Kalibrierung.** Der Schätzer selbst kann verzerrt sein. Genau das misst die letzte Zeile — durch den Vergleich **pro Kilometer**, sodass die Abdeckung sich herauskürzt und nur noch bestimmt, wie viel Gewicht das Fenster trägt.

Nach einer Korrektur wie oben werden die Fahrtschätzungen auf der nächsten Fahrt spürbar sinken und sich dann einpendeln. Der ganze Mechanismus: [Wie Sparkilo funktioniert → Wie aus einem Liter eine Zahl wird](User-de-How-It-Works#wie-aus-einem-liter-eine-zahl-wird).

Die Karte kann auch zeigen, *was sich geändert hat* — Anteil hoher Drehzahlen, harte Ereignisse pro 100 km, Kaltstarts, Leerlaufanteil, jeweils gegen den vorherigen Tank — mit dem ausdrücklichen Vorbehalt, dass Aufzeichnungen spontan sind und nur einen Teil des Tanks abdecken.

---

## Verbrauchsstatistik

Auf die Statistikkarte tippen, oder **Kraftstoff → Verbrauchsstatistik**.

<img src="guide/consumption-stats-1.jpg" width="340" alt="Statistik-Kopf: Kraftstofffilter, Summen und Tabelle dieser Monat gegen letzten Monat">

*Die Filterchips oben schränken alles darunter auf eine Sorte ein — bei einem Flex-Fuel-Auto unverzichtbar, weil ein gemeinsamer Durchschnitt dort bedeutungslos ist.*

Die Monatstabelle zeigt Liter, Ausgaben, Durchschnittspreis pro Liter, Durchschnittsverbrauch, Kosten pro km und Anzahl Tankvorgänge, jeweils mit Differenz. Rote Pfeile sind kein Urteil — steigende *Ausgaben* nach steigendem *Literpreis* sind der Markt, nicht dein rechter Fuß. Die Zahl fürs Fahren ist **L/100 km**.

### Kosten pro Kilometer je Kraftstoff

<img src="guide/consumption-stats-2.jpg" width="340" alt="Kosten pro Kilometer je Kraftstoff: E85- und E5-Zeilen mit Kosten/km, L/100 km, gezahltem Preis und CO2">

*Die eigentliche Frage des Flex-Fuel-Fahrers, beantwortet: nicht welcher Kraftstoff pro Liter billiger ist, sondern welcher pro Kilometer.*

Jede Sorte bekommt eine Zeile, ausschließlich aus **geschlossenen Tankfenstern**: gemessene L/100 km, tatsächlich gezahlter Literpreis, Kosten pro 100 km, Ausgaben gesamt, gemessene Strecke, verbrauchte Liter, CO₂ pro 100 km und die Zahl voller Tanks dahinter. Eine Zeile aus einem einzigen Tank ist als **Vorläufig** gekennzeichnet.

<img src="guide/consumption-stats-3.jpg" width="340" alt="Urteilskarte zu den Fahrtkosten mit Sieger, Break-even-Preis und CO2-Hinweis">

*Die Urteilskarte nennt den Sieger, den Abstand pro 1000 km und — am nützlichsten — den **Break-even-Preis**.*

Die Break-even-Zeile („E5 wird unter 0,75 €/L besser als E85") wird aus **deinem eigenen gemessenen Verbrauch beider Sorten** berechnet, bewegt sich also mit deinem Fahren. Das ist eine Entscheidungsregel, die du an der Säule anwenden kannst; ein Pauschalverhältnis aus dem Internet ist es nicht.

CO₂-Werte sind Well-to-Wheel-Schätzungen (EU JEC WTW v5) auf deinen gemessenen Verbrauch angewandt — Bewusstsein, keine prüffähige Bilanz. Mischungen bleiben beim CO₂ außen vor, weil der Emissionsfaktor vom Mischverhältnis abhängt, das die Zeile nicht erfasst.

<img src="guide/consumption-stats-4.jpg" width="340" alt="Entwicklung über die Zeit: Liter pro Monat und Ausgaben pro Monat, nach Kraftstoff gestapelt">

*Die Trendcharts stapeln nach Sorte, ein Wechsel erscheint also als eine Farbe, die eine andere ablöst, statt als rätselhafter Sprung.*

<img src="guide/consumption-stats-5.jpg" width="340" alt="Preis pro Liter und L/100 km pro Monat">

*Preis pro Liter und L/100 km sind bewusst getrennte Charts — das eine ist der Markt, das andere bist du.*

**Export** schreibt alles als CSV in deinen öffentlichen Downloads-Ordner.

---

## Eco-Note je Tankfüllung

Jede Tankfüllung wird gegen den gleitenden Mittelwert deiner letzten drei gleichsortigen Betankungen bewertet:

| Differenz | Badge | So zu lesen |
|---|---|---|
| ≥ 3 % besser | 🟢 Verbessert | Deutlich weniger als deine eigene Baseline |
| innerhalb ±3 % | ⚪ Stabil | Normale Schwankung |
| ≥ 3 % schlechter | 🟠 Verschlechtert | Reifendruck, Dachbox, Kälte, Streckenmix prüfen |

Das Badge bleibt verborgen, bis vier Betankungen dieser Sorte vorliegen, damit die Baseline echt ist.

---

## Wenn die Zahlen nicht aufgehen

Früher oder später tankst du mehr Liter, als deine aufgezeichneten Fahrten erklären können — jemand anders ist gefahren, der Adapter war ab, die App war zu. Statt die Differenz still zu schlucken, zeigt die App ein **Lücken-Banner** und bietet einen kurzen Abgleich:

> *Wir haben eine Lücke von 4,2 L gefunden. Du hast 35,7 L getankt, deine aufgezeichneten Fahrten erklären aber nur 31,5 L.*

Sie stellt zwei Fragen:

1. **Sind alle Tankfüllungen dieses Tanks vollständig und korrekt?** — Nein heißt: eine fehlt oder ist vertippt, und die App legt eine **Korrektur-Tankfüllung** an, damit die Liter aufgehen.
2. **Sind alle deine Fahrten aufgezeichnet?** — Nein heißt: eine Fahrt fehlt, und die App legt eine **virtuelle Fahrt** für die fehlende Strecke an.

Beide Einträge sind danach bearbeitbar und löschbar, und beide sind als automatisch erzeugt gekennzeichnet, damit du sie nie mit echten Daten verwechselst. Du kannst auch **Später entscheiden** wählen — das Banner bleibt, bis du es klärst.

**Warum das zählt:** eine ungeklärte Lücke verzerrt das Kalibrierungsfenster still. Sie zu klären (oder den falschen Eintrag zu löschen) hält die Verankerung an der Zapfsäule vertrauenswürdig.

---

## Kundenkarten

**Einstellungen → Fahren & Verbrauch → Kundenkarten** speichert Rabatte pro Liter für die Ketten, die du nutzt. Der Rabatt fließt in die Preisvergleiche ein, sodass eine scheinbar 2 ct/L teurere Station für dich korrekt als die günstigere rangieren kann. Die Funktion wird unter Funktionen & Nutzungsmodus → Eingabe & Scannen aktiviert.

---

<details>
<summary>Gesamtansicht — Verbrauchsstatistik, ganze Seite</summary>

<img src="guide/full/consumption-stats.jpg" width="420" alt="Vollständige Verbrauchsstatistik aus fünf Aufnahmen zusammengesetzt">

</details>

---

**Siehe auch:** [Fahrzeuge & OBD2](User-de-Vehicles-And-OBD2) · [Fahrten & Eco-Coaching](User-de-Trips-And-Coaching)
**Weiter:** [Fahrten & Eco-Coaching →](User-de-Trips-And-Coaching)
