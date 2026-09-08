# Preisverlauf & Prognosen

Die App baut ein **privates, lokales** Bild davon, wie sich Preise um dich herum bewegen, und macht daraus eine ehrliche Empfehlung.

---

## Was erfasst wird, und wo

Immer wenn ein Stationspreis durch die App läuft — eine Suche, ein Aktualisieren der Favoriten oder eine Hintergrund-Alarmprüfung — schreibt die App **auf deinem Telefon** einen Datensatz: Station, Sorte, Preis, Zeitstempel. Nichts wird hochgeladen, und niemandes Daten werden heruntergeladen.

- **Entdoppelt auf einen Datensatz pro Station und Stunde.** Fünf Suchen in zehn Minuten ergeben einen Eintrag.
- **30 Tage Aufbewahrung.** Ältere Datensätze werden automatisch gelöscht.
- **Aktiviert durch** *Funktionen & Nutzungsmodus → Preise & Alarme → Preisverlauf*. Aus heißt: gar keine Datensätze.

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Preise &amp; Alarme: Preisverlauf, TFLite-Prognose, Community-Meldungen, Zahlungs-QR">

*Einstellungen → Preise & Alarme. Der **Preisverlauf** ist die Voraussetzung für die Prognose darunter — ohne Verlauf hat sie nichts zu tun.*

---

## Den Verlauf einer Station ansehen

Öffne die Detailseite einer Station und scrolle zu **Preisverlauf**:

- **Stundendiagramm** — Durchschnittspreis je Tagesstunde über die letzten 30 Tage.
- **Wochentagsdiagramm** — Durchschnitt je Wochentag.
- **Min / Max / Ø / Trend** als Zusammenfassung.

Die günstigste Stunde bzw. der günstigste Tag ist grün hervorgehoben, die teuerste rot.

---

## „Beste Tankzeit"

Sobald genug Verlauf da ist, bekommt die Station ein Banner:

> 💡 **Preise fallen typischerweise dienstags 18:00–20:00** — spare ca. 3,2 ct/L

### Was es ist — und was nicht

Es ist eine **Zusammenfassung dessen, was an dieser Station in den letzten 30 Tagen tatsächlich passiert ist**, in *deinen* Daten. Es ist bewusst **nicht**:

- eine Prognose des morgigen Preises,
- auf Ölmarkt, Steueränderungen oder Wetter bezogen,
- aus den Daten anderer Nutzer gebaut.

Diese Zurückhaltung ist der Punkt. Ein regionaler Montagmorgen-Aufschlag ist ein echtes, wiederkehrendes lokales Muster, auf das man reagieren kann; eine Marktprognose vom Telefon ist es nicht.

### Die Lernphase

Das Banner bleibt verborgen, bis mindestens **10 Preisdatensätze dieser Station in den letzten 30 Tagen** vorliegen. Wie lange das dauert, hängt allein davon ab, wie oft der Preis der Station durch die App läuft:

| Situation | Zeit bis zum Banner |
|---|---|
| Station hat einen **Preisalarm** | Wenige Stunden — die Hintergrundprüfung erfasst alle 30–60 Min. |
| Station ist ein **Favorit**, den du täglich öffnest | Etwa 10 Tage |
| Keines von beidem — nur gelegentliche Suchen | Wochen, womöglich nie |

**Der praktische Trick:** setze einen Alarm auf die Station, die du wirklich nutzt. Der Alarm verdient doppelt — er meldet den Preisrutsch und füllt den Verlauf, der die Empfehlung erzeugt.

### Warum dein Favorit noch kein Banner hat

1. **Noch nicht genug Datensätze** (siehe oben).
2. **Der Preis hat sich kaum bewegt.** Liegt die 30-Tage-Spanne unter 0,1 ct/L, gibt es nichts, worauf man reagieren sollte, also wird nichts gezeigt.
3. **Nur eine Sorte hat Stichproben.** Die Schwelle gilt pro Kraftstoffsorte, nicht pro Station.

---

## Preisprognose auf dem Gerät

*Funktionen & Nutzungsmodus → Preise & Alarme → **Beste Tankzeit*** aktiviert ein kleines TensorFlow-Lite-Modell, das **vollständig auf dem Gerät** läuft. Seine Merkmale und Vorhersagen verlassen das Telefon nie. Es speist die *prognostische* Variante des Startbildschirm-Widgets (**Einstellungen → Einheiten & Darstellung → Startbildschirm-Widget → Inhaltsvariante**), die den besten Tankzeitpunkt statt nur den aktuellen Preis zeigt.

Wenn du gar nichts abgeleitet haben willst, schalte es aus: Verlauf und Musterbanner funktionieren auch ohne.

---

## Community-Preismeldungen

*Funktionen & Nutzungsmodus → Preise & Alarme → **Community-Preismeldungen*** ergänzt die Stationsdetails um eine Meldeaktion für Preise, die die offizielle Quelle falsch hat. Meldungen gehen unter deinem pseudonymen Konto in die gemeinsame TankSync-Datenbank und sind für andere angemeldete Nutzer sichtbar — das ist also die einzige Preisfunktion, die **nicht** rein lokal ist. Sie braucht TankSync und ist aus, bis du sie einschaltest.

---

## Exportieren

**Einstellungen → Datenschutz & Daten → Exportieren oder löschen → Meine Daten exportieren → CSV** schreibt eine CSV — ihre Preisverlaufstabelle enthält Station, Sorte, Preis, Zeitstempel — in deinen öffentlichen Downloads-Ordner.

---

**Siehe auch:** [Favoriten & Alarme](User-de-Favorites-And-Alerts) · [Tankstellen finden → Aktualität](User-de-Finding-Stations#aktualität--wichtiger-als-der-preis)
**Weiter:** [Einstellungen-Referenz →](User-de-Settings-Reference)
