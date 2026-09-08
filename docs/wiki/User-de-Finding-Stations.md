# Tankstellen finden

Ebene 1 der [drei Spar-Ebenen](User-de-How-It-Works#die-drei-spar-ebenen): weniger pro Liter zahlen.

---

## Ein Button, ein Denkmodell

Die untere Leiste hat genau einen Suchauslöser — den erhabenen grünen Button in der Mitte. Er ist kontextbewusst statt modal:

- **Aus jedem Tab** → öffnet den Kriterien-Dialog.
- **Aus Ergebnisliste oder Karte** → öffnet den Dialog mit deinen letzten Werten.
- **Im Dialog** → führt die Suche aus.

Die Beschriftung sagt, was passieren wird, und im Routenmodus bleibt der Button deaktiviert, bis es ein Ziel gibt. Getrennte Buttons für „in der Nähe" und „entlang der Route" gibt es bewusst nicht.

---

## Kriterien setzen

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Kriterien: Umkreis oder Route, Adresse, Kraftstoff-Chips, Radius, Jetzt geöffnet, Ausstattung, Marken">

*Der Dialog ist aus deinem aktiven Profil vorbelegt — meist änderst du genau eine Sache.*

| Bedienelement | Was es tut | Auswirkung im Betrieb |
|---|---|---|
| **In der Nähe / Entlang der Route** | Schaltet den ganzen Suchmodus um | Der Routenmodus braucht ein Ziel und fragt jedes Land im Korridor ab |
| **Adresse, PLZ oder Ort** | Sucht an einem Ort statt an deiner GPS-Position | Nichts über deinen Standort verlässt das Telefon; der Ortsname wird über OpenStreetMap Nominatim geokodiert und 24 h zwischengespeichert |
| **Kraftstoff-Chips** | Für welche Sorte die Preise gelten | Die Liste passt sich dem an, was der Anbieter deines Landes wirklich veröffentlicht |
| **Radius** | Wie weit gesucht wird | Ein großer Radius in einem dichten Land bringt viele Stationen und eine langsamere Suche |
| **Jetzt geöffnet** | Blendet geschlossene Stationen aus | Setzt voraus, dass der Anbieter Öffnungszeiten liefert — manche tun das nicht |
| **Ausstattung** | Shop, Waschanlage, Luft, WC … | Filtert nur auf gemeldeten Daten; eine Station mit leerem Feld verschwindet |
| **Marken** | Auf bestimmte Ketten beschränken | Wird aus der aktuellen Ergebnismenge gezählt, ändert sich also mit dem Radius |
| **Als Standard speichern** | Schreibt diese Kriterien ins Profil | Jede künftige Suche startet hier |

<!-- anchor: search.criteria.button -->
### Der Suchknopf

Der erhöhte Knopf in der Mitte der unteren Leiste ist der einzige
Suchauslöser. Aus jedem Tab öffnet er dieses Blatt; aus den Ergebnissen
oder der Karte öffnet er es mit dem zuletzt Benutzten; im Blatt selbst
startet er die Suche.

<!-- anchor: search.criteria.mode -->
### In der Nähe oder entlang einer Route

Zwei verschiedene Fragen. **In der Nähe** sucht um deine Position oder
eine Adresse. **Entlang der Route** braucht ein Ziel und misst die
Entfernung entlang des Korridors statt Luftlinie — eine Tankstelle 2 km
entfernt in einer Seitenstraße rangiert also hinter einer, die auf dem
Weg liegt.

<!-- anchor: search.criteria.fuel-type -->
### Kraftstoffsorte

Für welche Sorte die Preise gelten. Die Chips richten sich danach, was
der Anbieter deines Landes tatsächlich veröffentlicht — eine fehlende
Sorte fehlt in den Daten, nicht in der App.

<!-- anchor: search.criteria.radius -->
### Umkreis

Wie weit gesucht wird. Ein großer Umkreis in einem dichten Land liefert
sehr viele Tankstellen und eine langsamere Suche, und die zusätzlichen
liegen meist weiter weg, als die Ersparnis wert ist.

<!-- anchor: search.criteria.open-only -->
### Nur jetzt geöffnet

Blendet geschlossene Tankstellen aus. Das hängt davon ab, ob der Anbieter
Öffnungszeiten veröffentlicht, und manche tun es nicht — fehlen sie, wird
die Tankstelle behalten statt geraten.

<!-- anchor: search.criteria.amenities -->
### Ausstattung

Shop, Waschanlage, Luft, WC. Diese filtern über **gemeldete** Daten: eine
Tankstelle, die nichts über ihre Ausstattung veröffentlicht, verschwindet
aus einer gefilterten Liste, auch wenn sie alles hat.

<!-- anchor: search.criteria.highway -->
### Autobahntankstellen

Autobahntankstellen sind meist der teuerste Kraftstoff im Land — sie
auszuschließen ist der eine Filter, der am häufigsten ändert, was du
zahlst. Behalte sie, wenn du die Autobahn nicht verlassen kannst.

<!-- anchor: search.criteria.defaults -->
### Als meine Vorgaben speichern

Schreibt diese Kriterien in dein Profil, sodass jede spätere Suche hier
beginnt statt bei den Vorgaben der App. Diese Einstellung macht aus dem
Blatt eine Bestätigung mit einem Tipp statt eines Formulars.

### Wie es tatsächlich funktioniert

Eine Umkreissuche sendet **deine Koordinaten (oder einen Regionscode) und einen Radius** an den offiziellen Preisanbieter deines Landes — nie deine Identität. Länder mit täglicher Sammeldatei (Spanien, Italien) werden auf dem Gerät gefiltert; solche Suchen brauchen nach dem Zwischenspeichern gar keinen Netzaufruf mehr.

---

## Eine Ergebniskarte lesen

<img src="guide/search-results.jpg" width="340" alt="Ergebnisliste mit Preis, Trendpfeil, Aktualität, Ausstattung, Entfernung und Stern">

*Alles, was eine Entscheidung braucht, ohne etwas zu öffnen.*

- **Preis** — für die gesuchte Sorte, in der Konvention deines Landes (beachte die hochgestellte Zehntel-Cent-Stelle).
- **Trendpfeil** ▲▼▬ — wohin sich der Preis dieser Station zuletzt bewegt hat, aus *deinem eigenen* lokalen Verlauf.
- **★** — antippen zum Favorisieren; gefüllt heißt bereits gespeichert.
- **Ausstattungs-Chips** — Shop, Waschanlage, Luft, Geldautomat, soweit gemeldet.
- **Entfernung** — Luftlinie von deiner Position.
- **„Aktualisiert 31.08. 00:01"** — der Aktualitätsstempel. **Lies ihn vor dem Preis.**
- **Sortierzeile** — Entfernung / Preis / A–Z / 24 h, plus ein Warnchip, wenn der neueste Preis der Liste älter als eine Stunde ist.

### Aktualität — wichtiger als der Preis

| Badge | Alter | Was tun |
|---|---|---|
| Grün | < 5 Min. | Vertrauen |
| Gelb | 5–30 Min. | Für eine Entscheidung gut genug |
| Orange | Stunden | Plausibel; der Anbieter veröffentlicht evtl. langsam |
| Rot umrandet | > 1 Tag | Nur als Hinweis behandeln — vor einem Umweg aktualisieren |

Aktualität ist eine Eigenschaft des **Landesanbieters**, nicht der App. Ein spanischer Preis von vor 14 Stunden ist kein Fehler: dieses Land veröffentlicht einmal täglich. Siehe [Wie Sparkilo funktioniert → Eine Datenquelle pro Land](User-de-How-It-Works#eine-datenquelle-pro-land).

### Wischgesten

- **Nach rechts wischen** — in deiner Navi-App öffnen (Google Maps, Waze, OsmAnd, Organic Maps).
- **Nach links wischen** — Station aus allen künftigen Ergebnissen ausblenden. Rückgängig über **Datenschutz & Daten → Daten auf diesem Gerät → Ausgeblendete Stationen**.

---

## Stationsdetails

<img src="guide/station-detail-1.jpg" width="340" alt="Stationsdetails: Preistabelle je Sorte, Tankfüllung erfassen, Öffnungszeiten, Region">

*Karte antippen. Die Kopfzeile fällt von Marke über Name auf Straße zurück — ein Intermarché ohne Markenfeld heißt trotzdem „Intermarché".*

Der obere Block ist die **vollständige Preistabelle** — jede Sorte, die der Anbieter für diese Station meldet, mit `--` wo er nichts meldet. Der schnellste Weg zu sehen, ob die günstige E85-Station auch beim Diesel mithält.

**Tankfüllung erfassen** übernimmt Station, Sorte und Preis direkt ins Formular — der größte Zeitgewinn der App, wenn du deine Tankvorgänge erfasst.

<img src="guide/station-detail-2.jpg" width="340" alt="Stationsdetails weiter: Zone, Ausstattung, Zahlungsmittel, eigene Bewertung, Preisverlauf">

*Weiter unten: Dienste, akzeptierte Zahlungsmittel, deine eigene private Sternebewertung und der lokale 30-Tage-Preisverlauf.*

Die Aktionen in der Kopfleiste sind von links nach rechts: **Preisalarm setzen**, **Zahlungs-QR scannen**, **falschen Preis melden** und **favorisieren**.

---

## Die Karte

<img src="guide/map-view.jpg" width="340" alt="Karte mit preisfarbigen Nadeln, Radius-Kreis und Legende günstig bis teuer">

*Die Farbe ist relativ zum sichtbaren Ausschnitt: Grün ist die günstigste sichtbare Station, Rot die teuerste. Die Fußzeile nennt Anzahl, Radius und Alter der Daten.*

- **Cluster-Marker** fassen Nadeln beim Herauszoomen zusammen; antippen zoomt hinein.
- **Lang drücken** setzt eine eigene Markierung und sucht von dort.
- Der **E-Auto-Schalter** oben rechts wechselt zu Ladepunkten — siehe [E-Auto laden](User-de-EV-Charging).
- **Teilen** schickt den aktuellen Ausschnitt an jemanden.

Die Kacheln kommen von OpenStreetMap. Standardmäßig laufen sie über den EU-Proxy des Entwicklers, damit OpenStreetMap deine IP nie sieht; du kannst den Proxy unter Einstellungen → Datenschutz & Daten abschalten und direkt laden. Der F-Droid-Build nutzt den Proxy nie.

---

## Das Tankstellen-Radar

Ein Live-Scan um deine aktuelle Position, gebaut für die Nutzung **während der Fahrt**.

<img src="screenshots/radar-start.png" width="340" alt="Die Pille „Tankstellen-Radar starten" auf dem Ergebnisbildschirm">

*Nach jeder Umkreissuche erscheint unten rechts eine schwebende Pille. Ein Tipp startet das Radar.*

### Wie es tatsächlich funktioniert

Das Radar frischt deine GPS-Position auf, holt Stations**standorte** aus einem breiten 60-km-Korridor und mischt eine direkte Abfrage im Radius dazu — es kann also nie weniger zeigen als eine normale Suche. Tankstellen bewegen sich nicht, deshalb werden diese Standorte bis zu einer Stunde zwischengespeichert und wiederverwendet; nur der **Preis** einer Station, auf die du zufährst, wird genau dann geholt. Das macht ein dauerhaft laufendes Radar günstig in Daten und Akku.

<img src="screenshots/radar-active.png" width="340" alt="Radar in Betrieb: Live-Preisnadeln und nach Entfernung sortierte Liste mit Näherungsbalken">

*In Betrieb: nach Entfernung sortiert, mit einem Balken, der sich beim Näherkommen füllt.*

### Während einer Fahrtaufzeichnung

Das Radar heftet eine **Nächste Station**-Karte an den Kopf des Aufzeichnungsbildschirms — Name, Preis für deine Sorte, Entfernung und ein Balken, der bei Ankunft 100 % erreicht. Nach links/rechts wischen blättert durch die Kandidaten. Kommst du in den konfigurierten Annäherungsradius, wechselt die Bild-in-Bild-Kachel auf eine große Preisanzeige; siehe [Fahrten & Eco-Coaching → Annäherungs-Overlay](User-de-Trips-And-Coaching#das-annäherungs-overlay).

### Einstellungen, die das Verhalten ändern

Alle unter **Einstellungen → Fahren & Verbrauch**: der **Radius**, ab dem das Overlay groß wird, ob es die **nächste** oder die **günstigste im Radius** zeigt, das **Mindest-Aktualisierungsintervall** (eine Untergrenze, keine feste Rate — bei höherem Tempo wird öfter abgefragt, nie enger als dieser Wert) und **Automatisch anheften**, das den Bildschirm wach hält und die Systemleisten ausblendet — praktisch am Armaturenbrett, teurer im Akku.

---

## Der Kraftstoffkosten-Rechner

Drei Zahlen hinein — Strecke, dein Verbrauch, der Preis — und heraus kommen verbrauchte Liter, Gesamtkosten und Kosten pro Kilometer. Verbrauch und Preis werden aus deinen eigenen Daten vorbelegt, meist tippst du nur die Strecke.

Er beantwortet ehrlich genau eine Frage: *Ist die 12 km weiter entfernte Station wirklich günstiger, wenn ich hingefahren bin?*

---

## Startbildschirm-Widget

- Zeigt deinen günstigsten Favoriten (oder die nächste Station) mit aktuellem Preis.
- **Widget antippen** → öffnet die Detailseite, egal ob die App warm oder kalt war.
- **Aktualisierungs-Symbol antippen** → holt Preise im Hintergrund, ohne die App zu öffnen.
- Hintergrund-Aktualisierung alle 30 Minuten beim Laden, sonst stündlich, Doze-konform.

Aussehen und Inhaltsvariante (*aktueller Preis* vs. *prognostisch: beste Tankzeit*) werden pro Profil unter **Einstellungen → Einheiten & Darstellung → Startbildschirm-Widget** gesetzt.

---

## Android Auto

Am Android-Auto-Display bietet die App zwei fahrsichere Bildschirme: **Suche** (die Stationen deiner letzten Suche am Telefon) und **Radar** (die günstigsten entlang deiner Route). Die Suche zuerst am Telefon starten — die Autoseite ist bewusst nur lesend, weil es keine sichere Art gibt, während der Fahrt zu tippen. Nur Android; einen CarPlay-Build gibt es nicht.

---

<details>
<summary>Gesamtansicht — Stationsdetails, ganze Seite</summary>

<img src="guide/full/station-detail.jpg" width="420" alt="Vollständige Stationsdetailseite aus zwei Aufnahmen zusammengesetzt">

</details>

---

**Siehe auch:** [Routenplanung](User-de-Route-Planning) · [Favoriten & Alarme](User-de-Favorites-And-Alerts) · [Preisverlauf](User-de-Price-History-And-Predictions)
**Weiter:** [Routenplanung →](User-de-Route-Planning)
