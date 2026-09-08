# Fehlersuche & FAQ

Grob danach sortiert, wie oft es tatsächlich vorkommt.

---

## Zuerst: prüfe deine Version

<img src="guide/about-1.jpg" width="340" alt="Über-Bildschirm mit Version und Build-Nummer">

*Einstellungen → Über. Nenne in jedem Bericht **beide** Angaben.*

Ein großer Teil der „geht immer noch nicht"-Meldungen ist ein Store-Rollout, der das Gerät noch nicht erreicht hat. Ist die Build-Nummer älter als das Release mit der Korrektur, gibt es nichts zu debuggen.

---

## „Keine Preise gefunden"

1. **Prüfe das Land im Profil.** Ein deutsches Profil ruft die deutsche Schnittstelle auf; in Frankreich findet es nichts. Einstellungen → Profile & Region → Region.
2. **Deutschland: ist der API-Schlüssel gesetzt?** Einstellungen → Datenquellen & Standort — ein rotes Kreuz bei *Kraftstoffpreise (Tankerkoenig)* ist die Antwort.
3. **Bist du offline?** Live-Preise brauchen einen Netzaufruf. Zwischengespeicherte Preise werden weiter gezeigt, als veraltet gekennzeichnet.
4. **Anbieterausfall.** Nationale Open-Data-Dienste fallen aus. In ein paar Minuten erneut versuchen.
5. **Veralteter Cache.** Zum Aktualisieren ziehen oder das Aktualisierungssymbol antippen.

---

## Deutschland: „API-Schlüssel fehlt" oder „Ungültiger Schlüssel"

- Kostenlosen Schlüssel bei [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) holen; es ist eine UUID.
- In **Einstellungen → Datenquellen & Standort → Kraftstoffpreise (Tankerkoenig)** einfügen.
- Immer noch Fehler? Der Schlüssel kann limitiert sein. Schlüssel gelten pro Nutzer — niemals veröffentlichen oder teilen.

---

## Ich finde den Such-Button nicht

Es gibt genau einen: den erhabenen grünen Button in der Mitte der unteren Leiste. Aus jedem Tab öffnet er den Kriterien-Dialog; im Dialog führt ein zweiter Tipp die Suche aus. Sieht er ausgegraut aus, bist du im **Routenmodus ohne Ziel**.

---

## Standort ist „unbekannt" oder GPS findet nichts

- Der System-Standort muss an sein, mit **Bei Nutzung** für die App.
- GPS funktioniert nicht in Gebäuden. Nach draußen gehen oder eine **Heimat-Postleitzahl** im Profil setzen und nach Gebiet suchen.
- „Nur ungefährer Standort" — genauen Standort in den Systemberechtigungen aktivieren.

---

## Routing ist langsam oder scheitert

- OSRM ist ein kostenloser öffentlicher Dienst und manchmal langsam.
- Ein Mehrländer-Korridor **streamt Teilergebnisse**; das Banner nennt die noch antwortenden Anbieter, und du kannst ein Ergebnis antippen, bevor der Rest da ist.
- Erneut versuchen — die Linie ist zwischengespeichert, der zweite Versuch ist meist sofort da.

---

## OBD2-Adapter verbindet nicht

**Beim Scan wird nichts gefunden**

- Zündung muss **an** sein (Zubehör oder Fahrstellung). Motor laufen lassen ist in Ordnung, Zündung aus nicht.
- Die Adapter-LED sollte stetig leuchten. Blinkt oder dunkel → neu einstecken.
- Telefon-Bluetooth an.
- Android 12+: **Bluetooth-Suche** und **Bluetooth-Verbindung** erlauben.
- Bis Android 11: Das System verlangt **Standort**, um Bluetooth-Geräte aufzulisten. Plattformregel, kein Tracking.

**Gefunden, aber die Verbindung scheitert**

- *„Reagiert nicht"* — billiger Klon. 30 s warten und erneut versuchen; den Motor kurz zu starten hilft oft.
- *„Protokoll-Init fehlgeschlagen"* — gefälschter ELM327-Chip. Anderes Modell probieren; vLinker FS ist die zuverlässige günstige Wahl.
- *„Berechtigung verweigert"* — in den Systemeinstellungen neu erteilen; manche Android-Builds vergessen Bluetooth-Rechte nach einem Neustart.

**Verbindet, bricht dann während der Fahrt ab**

Nutze **Verbindung zurücksetzen** in der Adapter-Karte des Fahrzeugs — sie wiederholt den Handshake, ohne die Kopplung zu vergessen. Passiert es weiter, schalte **Einstellungen → Fahren & Verbrauch → OBD2-Debug-Protokoll** ein, fahre einmal, exportiere das XML-Protokoll und hänge es an ein Issue. Danach wieder ausschalten.

**Der Kilometerstand ist 0 oder falsch**

Dein Auto liefert womöglich kein PID A6. Die App versucht PID 31 und herstellerspezifischen Modus 22. Manche europäischen Autos vor 2008 liefern gar keinen Kilometerstand über OBD2 — dann mit jeder Tankfüllung eintippen.

---

## Die automatische Aufzeichnung hat nicht ausgelöst

Sie braucht alles davon:

1. Einen **an ein Fahrzeug gekoppelten** Adapter.
2. **Automatische Aufzeichnung** für dieses Fahrzeug an.
3. Die Standortfreigabe **„Immer zulassen"**.
4. Bluetooth an und keine Akku-Optimierung, die die App killt.

Prüfe auch die **Startgeschwindigkeit** im Fahrzeug-Editor — ein kurzes Kriechen aus dem Parkhaus erreicht sie vielleicht nie.

> **iOS:** Das systemseitige Aufwecken für „verbinden, sobald der Adapter Strom bekommt" gibt es noch nicht ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). Unter iOS Fahrten manuell starten.

---

## Mein Verbrauchswert sieht falsch aus

Arbeite es in dieser Reihenfolge ab:

1. **Öffne die Fahrt und lies die Karte zur OBD2-Kommunikationsgesundheit.** Liegt die Abdeckung deutlich unter 100 %, wurden Lücken mit GPS-Schätzungen gefüllt und der Fahrtdurchschnitt ist eine Mischung, keine Messung.
2. **Sieh dir den Tank-Bericht im Fahrten-Tab an.** Sagt er, die Schätzungen lägen *n* % über oder unter der Zapfsäulen-Wahrheit, weiß die App es bereits und hat sich gerade korrigiert — erwarte Bewegung bei den nächsten Fahrten.
3. **Prüfe den Tankinhalt** am Fahrzeug. Ein falscher Wert erzeugt monatelang plausible, aber falsche Reichweiten.
4. **Prüfe deine Kilometerstände.** Verbrauch ist Liter ÷ Kilometer, und die Kilometer sind vollständig deine Eingabe.
5. **Prüfe, ob du „Voller Tank" gesetzt hast.** Nur Voll-zu-voll-Fenster können etwas kalibrieren.
6. **Prüfe das Genauigkeits-Badge** im Kraftstoff-Tab. *Niedrig* heißt, dass noch nichts das Modell verankert hat — der Wert ist eine Modellausgabe, und das sagt er auch.

Hintergrund: [Wie Sparkilo funktioniert → Wie aus einem Liter eine Zahl wird](User-de-How-It-Works#wie-aus-einem-liter-eine-zahl-wird).

---

## „Wir haben eine Lücke von X Litern gefunden"

Du hast mehr getankt, als deine aufgezeichneten Fahrten erklären. Beantworte die beiden Fragen des Abgleichs: eine fehlende oder vertippte Tankfüllung bekommt einen **Korrektureintrag**, eine nicht aufgezeichnete Fahrt eine **virtuelle Fahrt**. Beides ist danach bearbeitbar. Ungeklärt verzerrt es die Kalibrierung, zwei Tipps lohnen sich also. Siehe [Tankbuch & Verbrauch](User-de-Fuel-And-Consumption#wenn-die-zahlen-nicht-aufgehen).

---

## Die Bild-in-Bild-Kachel zeigt keinen Preis

Das Annäherungs-Overlay löst nur aus, während eine **Fahrt aufgezeichnet wird** *und* du im Annäherungsradius bist. Zum Prüfen ohne Fahrt: **Einstellungen → Entwicklerwerkzeuge → Annäherungs-Overlay testen** setzt 30 Sekunden lang einen synthetischen Zustand.

---

## Preisalarm-Benachrichtigungen kommen nicht an

- Sind Systembenachrichtigungen für die App erlaubt?
- Akkusparer: Androids aggressive Modi töten Hintergrundarbeit. Stelle die App auf **nicht eingeschränkt**.
- Das Telefon war zum geplanten Zeitpunkt vielleicht offline; die Prüfung läuft im nächsten Netzfenster.
- Vielleicht hat der Preis die Schwelle schlicht nicht unterschritten.
- Der Stempel **Letzte Prüfung** unten auf dem Alarmbildschirm sagt dir, ob die Aufgabe überhaupt läuft. Alter Stempel + null Treffer = das System killt sie.

---

## Das Startbildschirm-Widget ist veraltet

- Android begrenzt Widget-Aktualisierungen auf etwa alle 30 Minuten; das ist Systempolitik.
- Tippe das **Aktualisierungssymbol auf dem Widget** — es holt Preise, ohne die App zu öffnen.
- Aussehen und Inhaltsvariante sind pro Profil unter **Einstellungen → Einheiten & Darstellung**.

---

## Die Karte zeigt graue oder leere Kacheln

- Meist eine schwache Verbindung; zum Aktualisieren wischen.
- Hält es an, limitieren die Kachelserver vielleicht — in ein paar Minuten erneut versuchen.
- Probiere **Einstellungen → Datenschutz & Daten → Kartenkacheln über den Sparkilo-Proxy** umzuschalten; die beiden Wege scheitern unabhängig voneinander.

---

## Das Scannen von Zapfsäule oder Beleg liest nichts

- Der **F-Droid**-Build hat gar kein Scannen — Texterkennung auf dem Gerät steckt nur in den Play-/App-Store-Builds. Dort die Tankfüllung von Hand tippen.
- Blendung auf dem Zapfsäulendisplay ist die häufigste Ursache. Abschatten, gerade davorstellen, die Ziffern formatfüllend aufnehmen.
- Liest es die Beschriftungen, aber nicht die Zahlen, nutze **Scanfehler melden**, damit der Ausschnitt zur Verbesserung dient.

---

## Die App startet sehr langsam

Schalte **Startup-Trace** ein (Funktionen & Nutzungsmodus → Entwickler & experimentell), starte neu und öffne die **Entwicklerwerkzeuge**. Der Wasserfall nennt die langsame Phase; exportiere ihn und hänge ihn an ein Issue.

<img src="guide/developer-tools-2.jpg" width="340" alt="Startup-Trace als Wasserfall mit Zeiten je Phase">

*Jeder Balken ist eine Initialisierungsphase mit ihrer Dauer — ein langsamer Start ist keine Vermutung mehr.*

---

## Die App stürzt beim Start ab

- Cache über die App-Einstellungen des Geräts leeren.
- Hält es an, ein Issue anlegen mit Android-Version, Telefonmodell, App-Version **und Build-Nummer** aus Einstellungen → Über und dem gespeicherten Fehlerprotokoll (die App bietet es beim nächsten Start an; die Datei landet in den Downloads).

---

## Wie sichere ich meine Daten?

**Einstellungen → Sicherung & Wiederherstellung → Sicherung exportieren** schreibt eine ZIP in die Downloads; die Wiederherstellung bietet Zusammenführen oder Ersetzen. Für einen maschinenlesbaren Datenexport stattdessen **Datenschutz & Daten → Exportieren oder löschen → Meine Daten exportieren → ZIP-Archiv**.

TankSync ist **keine** Sicherung — es spiegelt ausgewählte Kategorien, und Fahrten nur, wenn du auch die Fahrten-Synchronisierung eingeschaltet hast.

---

## Wie lösche ich alles?

- **Gerät:** Datenschutz & Daten → Exportieren oder löschen → **Alle meine Daten löschen**. Unwiderruflich.
- **Server (TankSync):** die Serverseite **zuerst** löschen — Synchronisierung & Konto → Datentransparenz → **Konto löschen** entfernt jede dir gehörende Zeile in einer Transaktion und nennt jede Tabelle, die nicht gelöscht werden konnte.

Details: [Datenschutz, Daten & Sync → Deine Rechte](User-de-Privacy-Profiles-Sync#deine-rechte-nach-der-dsgvo).

---

## Kann ich die App offline nutzen?

Teilweise. Favoriten zeigen ihre letzten bekannten Preise, kürzlich betrachtete Kartenkacheln sind zwischengespeichert, und Tankfüllungen und Fahrten sind vollständig lokal. Neue Stationen zu entdecken braucht einen Netzaufruf.

---

## Wo ist der Kraftstoff- oder Fahrten-Tab hin?

Sie gehören zu den Nutzungsmodi **Mittel** und **Voll**. Ist einer verschwunden, hat eine Voreinstellung oder ein Einzelschalter ihn ausgeschaltet: Einstellungen → Funktionen & Nutzungsmodus → Verbrauch.

---

## Mehr Hilfe

- **Fehler:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — die Bug-Report-Vorlage nutzen und das gespeicherte Fehlerprotokoll anhängen.
- **Ideen:** die Feature-Request-Vorlage oder zuerst [Discussions](https://github.com/fdittgen-png/tankstellen/discussions).
- **Datenschutzfragen:** die [Datenschutzerklärung](https://fdittgen-png.github.io/tankstellen/privacy-policy/de/) oder fdittgen@gmail.com.

---

**Zurück zu:** [Benutzerhandbuch-Startseite](User-de-Home)
