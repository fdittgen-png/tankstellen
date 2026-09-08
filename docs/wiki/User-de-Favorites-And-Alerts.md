# Favoriten & Preisalarme

Der ⭐-Tab ist deine Auswahlliste plus die Roboter, die sie für dich beobachten.

---

## Favoriten

<img src="guide/favorites.jpg" width="340" alt="Favoriten-Tab mit zwei gespeicherten Stationen, Preisen je Sorte und dem Alarm-Reiter">

*Zwei Reiter oben: **Favoriten** und **Preisalarme**. Jede Karte zeigt alle gemeldeten Sorten, nicht nur deine bevorzugte.*

Markiere eine Station mit dem ★ auf jeder Ergebniskarte oder auf ihrer Detailseite.

### Was wirklich gespeichert wird

Ein Favorit ist kein Lesezeichen, sondern eine **vollständige lokale Kopie** der Station: Kennung, Adresse, Ausstattung, Zahlungsmittel, Öffnungszeiten und die zuletzt gesehenen Preise. Deshalb funktioniert der Tab ohne Netz: du siehst die letzten bekannten Preise, klar mit ihrem Aktualitätsstempel gekennzeichnet.

### Was das in der Praxis heißt

- **Favoriten funktionieren offline**, Suchen nicht. Öffne den Tab vor einer Fahrt ins Funkloch einmal im WLAN.
- Preise werden beim Öffnen des Tabs aktualisiert, nicht laufend.
- Favoriten gehören zu den Kategorien, die **TankSync** zwischen deinen Geräten spiegelt, falls du es einschaltest.

### Sortieren und Wischen

Sortierung nach Preis (Standard), Entfernung oder Alphabet. **Nach rechts wischen** öffnet die Navi-App; **nach links wischen** entfernt den Favoriten mit Rückgängig-Hinweis.

### Ladepunkte

Auch Ladepunkte lassen sich favorisieren; die Karte zeigt, was E-Auto-Fahrer brauchen: **Leistung je Anschluss in kW**, wie viele **gerade frei** sind, und die **Steckertypen**.

### Querformat und Tablets

Auf quer gehaltenen Telefonen und ab 600 dp Breite werden Favoriten und Alarme **nebeneinander** dargestellt statt hinter einem Reiterwechsel. Beide Bereiche sind gleichzeitig sichtbar, deshalb gibt es dort keinen Umschalter.

---

## Preisalarme

<img src="guide/price-alerts.jpg" width="340" alt="Preisalarme: Zähler für aktiv/heute/diese Woche, Stationsalarme und Umkreisalarme">

*Oben drei Zähler — aktive Regeln, Treffer heute, Treffer diese Woche — darunter die beiden Alarmarten. Die Fußzeile stempelt die letzte Hintergrundprüfung.*

Es gibt zwei Arten, und sie beantworten verschiedene Fragen.

### Stationsalarm — „sag mir, wenn *diese* Säule günstig wird"

Wird auf der Detailseite einer Station erstellt (Glockensymbol). Sorte wählen, Schwelle setzen, speichern. Ideal für die Station, die du ohnehin nutzt.

### Umkreisalarm — „sag mir, wenn es *irgendwo hier* günstig wird"

<img src="guide/price-alert-create.jpg" width="340" alt="Umkreisalarm anlegen: Bezeichnung, Kraftstoff, Schwelle, Radius, Prüfhäufigkeit, Position oder PLZ">

*Einstellungen → Preise & Alarme → Preisalarme → **Umkreisalarm anlegen**.*

| Feld | Was es tut |
|---|---|
| **Bezeichnung** | Freier Text, damit eine Alarmliste lesbar bleibt („Diesel zuhause") |
| **Kraftstoffsorte** | Eine Sorte pro Alarm — eine Station kann mehrere Alarme haben |
| **Schwelle (€/L)** | Löst aus, wenn eine Station im Gebiet **darunter** fällt |
| **Radius (km)** | Das überwachte Gebiet um den Mittelpunkt |
| **Prüfhäufigkeit** | Wie oft die Hintergrundaufgabe nachsieht — siehe unten |
| **Meine Position / Auf Karte wählen / PLZ** | Drei Wege, den Mittelpunkt zu setzen; eine PLZ berührt GPS nie |

Ideal für „melde dich, wenn Diesel irgendwo im Umkreis von 5 km unter 1,60 € fällt", wenn dir die konkrete Station egal ist.

---

## Wie die Prüfung wirklich funktioniert

Eine vom Betriebssystem eingeplante Hintergrundaufgabe wacht auf und:

1. Holt Live-Preise für die Stationen hinter deinen Alarmen.
2. Vergleicht jeden mit seiner Schwelle.
3. Löst eine **lokale Benachrichtigung** aus, wenn ein Preis darunter liegt. Ein Tipp öffnet die Station.

Der Takt ist **alle 30 Minuten beim Laden, sonst stündlich**, und nur mit Netzverbindung. Deine Prüfhäufigkeit pro Alarm ist eine Obergrenze darin: „einmal täglich" lässt die Aufgabe den Alarm meistens überspringen.

### Was das in der Praxis heißt

- **Alarme sind Best-Effort, nicht Echtzeit.** Das Betriebssystem entscheidet, wann die Aufgabe wirklich läuft; aggressive Akkusparer verzögern oder töten sie. Wenn Timing zählt, nimm die App von der Akku-Optimierung aus.
- **Kein GPS im Spiel.** Alarme arbeiten mit den gespeicherten Koordinaten der Stationen, ein Heimatalarm läuft also auch 500 km entfernt weiter.
- **Der Akkuverbrauch ist vernachlässigbar** — ein paar KB pro Aufwachen, in einem OS-verwalteten Zeitfenster, Doze-konform. Deutlich unter 0,5 % pro Tag.
- **Ein wichtiger Nebeneffekt:** dieselbe Hintergrundprüfung schreibt einen Preis in deinen lokalen Verlauf. Eine Station mit Alarm baut ihren 30-Tage-Verlauf deshalb in Stunden statt Wochen auf — und genau das lässt den Banner *beste Tankzeit* schnell erscheinen. Siehe [Preisverlauf](User-de-Price-History-And-Predictions#die-lernphase).
- **Sind Benachrichtigungen auf Systemebene aus**, kann der App-Schalter nichts auslösen.

---

## Statistik

Die Zähler oben zeigen, wie viele Regeln aktiv sind und wie oft sie heute und diese Woche ausgelöst haben — ein schneller Test, ob die Hintergrundaufgabe wirklich läuft. Nur Nullen bei mehreren aktiven Alarmen und ein alter „Letzte Prüfung"-Stempel sind das klassische Zeichen für einen Akkusparer, der die Aufgabe killt.

---

## Alarme beenden

Einen Alarm ausschalten pausiert ihn, ohne die Regel zu verlieren; nach links wischen löscht ihn. Eine Station aus den Favoriten zu entfernen löscht ihre Alarme **nicht**.

---

**Siehe auch:** [Preisverlauf & Prognosen](User-de-Price-History-And-Predictions) · [Einstellungen-Referenz → Preise & Alarme](User-de-Settings-Reference#preise--alarme)
**Weiter:** [E-Auto laden →](User-de-EV-Charging)
