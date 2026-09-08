# Fahrzeuge & OBD2

Alles, was die App über *dein Auto* weiß. Diese Seite entscheidet, ob die Verbrauchszahlen auf allen anderen Seiten vertrauenswürdig sind.

---

## Warum die App überhaupt ein Fahrzeug braucht

Ohne Fahrzeug ist Sparkilo ein Preisfinder. Mit einem kann es Liter und Kilometer in *deine* Kosten pro Kilometer umrechnen, Reichweite schätzen und — mit Adapter — den momentanen Kraftstofffluss modellieren.

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Übersicht Fahrzeuge &amp; OBD2 mit den Kacheln Meine Fahrzeuge und OBD2-Adapter">

*Einstellungen → Fahrzeuge & OBD2. Beachte das Gültigkeits-Label auf der Adapter-Kachel: Adapter werden **pro Fahrzeug** gekoppelt, nicht pro Telefon.*

<img src="guide/my-vehicles.jpg" width="340" alt="Fahrzeugliste mit einem aktiven Fahrzeug">

*Der grüne Haken markiert das aktive Fahrzeug — dem werden neue Tankfüllungen und Fahrten zugeordnet.*

---

## Identität und Antrieb

<img src="guide/vehicle-edit-1.jpg" width="340" alt="Fahrzeug-Editor: Name, optionale FIN, FIN aus dem Auto lesen, Antriebsauswahl">

*Nenne es, wie du es wiedererkennst. Die FIN ist optional.*

### Die FIN und was sie bringt

Die FIN (VIN) einzugeben oder auszulesen erlaubt der App, Hubraum, Zylinderzahl, Leistung und Kraftstoffart nachzuschlagen — die Eingaben des Verbrauchsmodells. **FIN aus dem Auto lesen** holt sie in einer Sekunde über OBD2.

Die Online-FIN-Auflösung ist eine **eigene Einwilligung** — die App fragt, bevor sie etwas sendet, und die teilweise Offline-Auflösung funktioniert auch bei Ablehnung. Eine FIN ist ein personenbezogenes Datum; behandle sie so.

### Antrieb

**Verbrenner / Hybrid / Elektrisch** ändert, welche Felder darunter existieren. Verbrenner fragt Tankinhalt, Leistung und bevorzugten Kraftstoff; elektrisch fragt Batteriekapazität und Stecker.

---

## Tankinhalt, Leistung und Flex-Fuel

<img src="guide/vehicle-edit-2.jpg" width="340" alt="Verbrenner-Block: Tankinhalt, Motorleistung, bevorzugter Kraftstoff, Mehrsorten-Schalter, gekoppelter Adapter">

*Der Tankinhalt ist die tragendste Zahl auf diesem Bildschirm.*

### Warum der Tankinhalt so wichtig ist

Er ist der Nenner der Füllstandsanzeige und der Reichweitenschätzung und begrenzt, was die App als plausible Betankung ansieht. Ein falscher Wert erzeugt monatelang eine plausibel aussehende, aber falsche Reichweite. Nimm ihn aus dem Handbuch, nicht aus dem Gedächtnis — Hersteller nennen oft eine nutzbare Menge, die ein paar Liter unter der nominellen liegt.

### „Ich kann verschiedene Kraftstoffe tanken"

Für ein Flex-Fuel-Auto einschalten (E85/E10 oder alles, was du wirklich abwechselst). Zwei Dinge ändern sich:

- Das Tankformular **fragt jedes Mal, welchen Kraftstoff du wirklich getankt hast**, statt den bevorzugten anzunehmen.
- Die Statistik bekommt den Vergleich **Kosten pro Kilometer je Kraftstoff** — der einzige ehrliche Weg, einen billigen, durstigen Kraftstoff gegen einen teuren, sparsamen zu stellen.

Lass es aus, wenn du immer dieselbe Sorte tankst — es fügt nur ein Feld hinzu.

---

## Der OBD2-Adapter

Ein OBD2-Adapter ist ein kleiner Bluetooth-Dongle in der Diagnosebuchse deines Autos (meist unter dem Armaturenbrett). **Er ist völlig optional.** Alles funktioniert auch nur mit GPS; der Adapter macht aus Schätzungen Messungen.

### Was sich damit ändert

| Ohne Adapter | Mit Adapter |
|---|---|
| Strecke und Zeit aus GPS | Dasselbe, plus Motordaten |
| Verbrauch aus der Kalibrierung **modelliert** | Verbrauch **gemessen** (oder mit weit besserem Modell) |
| Coaching aus Geschwindigkeit und Beschleunigung | Coaching aus Drehzahl, Gaspedal, Last, Gang |
| Genauigkeitsgrenze: Mittel | Genauigkeitsgrenze: Hoch (±3–7 %) |
| Fahrt manuell starten | Automatische Aufzeichnung möglich |

### Was die App ausliest

Geschwindigkeit, Drehzahl, Motorlast in %, Gaspedalstellung in %, Kühlmittel- und Ansauglufttemperatur, Zündzeitpunkt, Tankfüllstand in %, Kilometerstand (Standard-PID A6, ersatzweise PID 31 und herstellerspezifischer Modus 22) und den momentanen Kraftstofffluss — entweder direkt über **PID 5E**, wo das Auto ihn meldet, oder abgeleitet aus dem Luftmassenmesser.

> **Der entscheidende Unterschied:** Antwortet dein Auto auf PID 5E, ist dein Verbrauch *gemessen* und es wird keine Kalibrierung darauf angewandt. Antwortet es nicht, ist der Wert aus Luftmasse und Motorparametern *modelliert* — und genau dieses Modell korrigiert der Pump-Gain. Der Fahrzeug-Bildschirm sagt dir, welcher Fall vorliegt.

### Unterstützte Adapter

16 Modelle werden am Bluetooth-Namen erkannt, jedes mit einer Kompatibilitätsstufe:

- ✅ **Getestet** — vom Betreuer auf echter Hardware bestätigt.
- 👤 **Von Nutzern bestätigt** — mindestens ein Nutzer meldet, dass es geht.
- ⚠️ **Theoretisch** — Profil und Transport stimmen, aber noch keine durchgängige Bestätigung.

| Adapter | Transport | Hinweise | Stufe |
|---|---|---|---|
| vLinker FS | Classic BT | Dominantes EU-Modell; empfohlen | ✅ |
| vLinker BM-Android | Classic BT | Classic-SPP-Geschwister von BM+ | ✅ |
| SmartOBD (BLE) | BLE | Generischer ELM327-v1.5-Klon | 👤 |
| SmartOBD (Classic) | Classic BT | Gleiche Marke, Classic SPP | 👤 |
| vLinker FD / MC | BLE | Nordic-UART-FFF0-Familie | ⚠️ |
| OBDLink MX+ | BLE | Scantool-Premium | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | ELM327-v2.1-BLE-Klon | ⚠️ |
| vLinker BM+ | BLE | Reines BLE-Geschwister | ⚠️ |
| Konnwei KW902 | Classic BT | ELM327-v1.5-Klon | ⚠️ |
| Vgate iCar Pro | BLE | Nur BLE-Variante | ⚠️ |
| Panlong WiFi | — | Nur WLAN, gelistet damit Fehlkopplungen benannt werden | ⚠️ |
| BAFX 34t5 | Classic BT | Alter ELM327 v1.5 | ⚠️ |
| Generic ELM327 (BLE) | BLE | Auffangprofil für BLE-FFF0-Klone | ⚠️ |
| Generic ELM327 (Classic) | Classic BT | Auffangprofil für Classic-SPP-Klone | ⚠️ |

Nicht gelistete Adapter fallen auf das generische ELM327-Profil zurück und funktionieren meist. Wenn deiner geht — oder nicht — [öffne ein Issue](https://github.com/fdittgen-png/tankstellen/issues), damit die Stufe korrigiert wird.

### Koppeln

1. Zündung **an** (Motor laufen lassen ist in Ordnung, aus ist es nicht).
2. Adapter einstecken; seine LED sollte stetig leuchten.
3. Fahrzeug öffnen und den Adapter-Abschnitt antippen, oder eine Fahrt starten.
4. **Bluetooth-Suche** und **Bluetooth-Verbindung** erlauben (Android 12+). Bis Android 11 verlangt das System stattdessen **Standort** für Bluetooth-Suchen — eine Systemregel, keine Tracking-Entscheidung.
5. Rund 8 Sekunden auf den Scan warten und den Adapter antippen. Die App führt den ELM327-Handshake aus und bestätigt.

Nach dem Koppeln gehört der Adapter zu diesem Fahrzeug. **Verbindung zurücksetzen** wiederholt den Handshake, ohne das Gerät zu vergessen — das Erste, was man nach einem Abbruch während der Fahrt versucht. **Adapter vergessen** löscht die Kopplung ganz.

---

## Baseline-Kalibrierung — der App dein Auto beibringen

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Baseline-Kalibrierung: gekoppelter Adapter, Fortschritt 210/270, Warnung zu fehlenden Situationen und Balken je Situation">

*210 von 270 Stichproben. Zwei Fahrsituationen sind noch leer, und die App sagt es, statt Vollständigkeit vorzutäuschen.*

Jede OBD2-Stichprobe wird einer Fahrsituation zugeordnet: **Leerlauf, Stop & go, Stadt, Autobahn, Verzögern, Steigung / beladen, Kaltstart, Dauerlast / Anhänger, Segeln**. Die Mittelwerte je Situation bilden die Baseline des Fahrzeugs — das Modell, das einen plausiblen L/100-km-Wert liefert, wenn der Adapter fehlt oder eine PID aufhört zu antworten.

<img src="guide/vehicle-edit-4.jpg" width="340" alt="Balken je Situation, Baseline zurücksetzen und die Auswahl des Kalibrierungsmodus">

*Situationen mit null Stichproben sind die, die auf Standardwerte zurückfallen. Hier zwei: Verzögern und Anhängerbetrieb.*

### Regelbasiert vs. Fuzzy

<img src="guide/vehicle-edit-5.jpg" width="340" alt="Kalibrierungsmodus regelbasiert oder Fuzzy, Zurücksetzen-Aktionen und Wartungserinnerungen">

*Fuzzy ist der Standard und für fast alle die bessere Wahl.*

- **Regelbasiert** ordnet jede Stichprobe genau einer Situation zu. Vorhersagbar, springt aber von Stichprobe zu Stichprobe zwischen „Stadt" und „Autobahn", wenn du nahe der Grenze fährst — etwa bei 60 km/h.
- **Fuzzy** verteilt jede Stichprobe nach Passgenauigkeit auf alle Situationen. Genau dort glatt, wo regelbasiert springt, dafür schwerer Stichprobe für Stichprobe nachzuvollziehen.

### Die beiden Zurücksetzen-Buttons — und was sie wirklich tun

- **Volumetrischen Wirkungsgrad zurücksetzen** verwirft das gelernte η_v und stellt den Standard 0,85 wieder her. η_v ist ein Parameter des Speed-Density-Modells, das die Luftmasse schätzt, wenn kein MAF-Wert vorliegt. Setze ihn nur nach einem mechanischen Eingriff zurück; eine seltsame Zahl ist eher ein Abdeckungsproblem. Autos, die den Kraftstofffluss direkt melden (PID 5E), nutzen ihn gar nicht.
- **Aus Fahrzeugdatenbank zurücksetzen** holt Hubraum, Leistung und Standardwerte erneut aus dem eingebauten Katalog und verwirft deine manuellen Werte.
- **Fahrsituations-Baseline zurücksetzen** (in der Baseline-Karte) löscht jede gelernte Stichprobe und wirft dich auf Kaltstart-Standards zurück, bis neue Fahrten das Profil füllen.

Keiner davon rührt den **Pump-Gain** an, der aus Voll-zu-voll-Tankfenstern gelernt wird und außerhalb des OBD2-Modells lebt — siehe [Wie Sparkilo funktioniert → Wie aus einem Liter eine Zahl wird](User-de-How-It-Works#wie-aus-einem-liter-eine-zahl-wird).

---

## Wartungserinnerungen

Ganz unten im Fahrzeug-Editor: Vorlagen für **Ölwechsel (15 000 km)**, **Reifen (20 000 km)** und **Hauptuntersuchung (30 000 km)** plus eigene Erinnerungen. Sie zählen gegen die Kilometerstände, die du mit deinen Tankfüllungen einträgst — sie laufen also nur, wenn du den Tacho erfasst, was die Kalibrierung ohnehin braucht. Eine Gewohnheit, zwei Vorteile.

---

## Automatische Aufzeichnung

Mit gekoppeltem Adapter läuft die Aufzeichnung vollständig freihändig:

- **Automatische Kopplung** — die erste manuelle Kopplung erzeugt die Zuordnung Adapter ↔ Fahrzeug.
- **Automatische Verbindung** — sobald das System den gekoppelten Adapter senden sieht, verbindet die App im Hintergrund.
- **Automatischer Start** — verbunden und über der Startgeschwindigkeit beginnt die Fahrt.
- **Automatisches Speichern** — mit der Zündung verliert der Adapter Strom, und nach der eingestellten Verzögerung wird die Fahrt abgeschlossen und gespeichert.

Die automatische Aufzeichnung braucht die Standortfreigabe **„Immer zulassen"**, weil Android nur damit einen Hintergrunddienst GPS streamen lässt. Diese Freigabe nutzt ausschließlich die Aufzeichnung; Suche und Kartenzentrierung verwenden die normale Vordergrund-Freigabe.

> **Plattform-Hinweis.** Die automatische Aufzeichnung ist auf **Android** verifiziert. Unter iOS fehlt das systemseitige Aufwecken für „verbinden, sobald der Adapter Strom bekommt" noch ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)); dort startet man Fahrten manuell.

Die Schwellen (Startgeschwindigkeit, Speicherverzögerung nach Trennung) stehen im Fahrzeug-Editor, ein Kurzstreckenauto kann also anders auslösen als ein Pendlerfahrzeug.

---

<details>
<summary>Gesamtansicht — Fahrzeug-Editor, ganze Seite</summary>

<img src="guide/full/vehicle-edit.jpg" width="420" alt="Vollständiger Fahrzeug-Editor aus fünf Aufnahmen zusammengesetzt">

</details>

---

**Siehe auch:** [Fahrten & Eco-Coaching](User-de-Trips-And-Coaching) · [Fehlersuche → OBD2](User-de-Troubleshooting-FAQ#obd2-adapter-verbindet-nicht)
**Weiter:** [Tankbuch & Verbrauch →](User-de-Fuel-And-Consumption)
