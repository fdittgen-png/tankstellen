# Einstellungen-Referenz

Jeder Bildschirm des Einstellungsbaums und — nützlicher — **was jeder Schalter kostet**: an Akku, Daten, Genauigkeit oder Privatsphäre.

---

## Die Form des Ganzen

Die Einstellungen sind ein **zweistufiger Baum**: eine Wurzel aus Themenkacheln, ein Bildschirm pro Thema, und eine Stichwortsuche über alle.

<img src="guide/settings-root-1.jpg" width="340" alt="Einstellungs-Wurzel, obere Hälfte: Suchfeld und die ersten sechs Themenkacheln">

*Tippe „Radius", „OBD2" oder „Design" in das Suchfeld, und die passende Kachel taucht auf — du musst dir nie merken, welches Thema einen Parameter besitzt.*

<img src="guide/settings-root-2.jpg" width="340" alt="Einstellungs-Wurzel, untere Hälfte: Funktionen, Datenquellen, Sync, Datenschutz, Sicherung, Erweitert">

*Insgesamt zwölf Themen. Zu den Einstellungen: das Zahnrad oben rechts auf den Hauptbildschirmen.*

Drei Entwurfsregeln machen den Baum vorhersagbar:

1. **Ein Zuhause pro Parameter.** Nichts erscheint zweimal; Querverweise zeigen auf den einen Besitzer.
2. **Gültigkeits-Labels.** Eine Kachel mit *dieses Profil*, *alle Profile* oder *dieses Fahrzeug* sagt dir vorab, wie weit eine Änderung reicht.
3. **Ehrliche Leerzustände.** Ein Abschnitt, dessen Funktion aus ist, sagt das und verlinkt den Schalter, statt sich zu verstecken.

---

## Profile & Region

*Land, Sprache, Kraftstoff, Suchradius, Routenplanung · Gültigkeit: dieses Profil*

<img src="guide/profile-edit-1.jpg" width="340" alt="Profil-Editor: Name, bevorzugter Kraftstoff, Standardradius">

*Der bevorzugte Kraftstoff wird aus dem Standardfahrzeug abgeleitet. Um ihn direkt zu wählen, entferne das Fahrzeug aus dem Profil.*

| Einstellung | Auswirkung |
|---|---|
| **Profilname** | Kosmetisch, aber genau das zeigt der Profil-Chip |
| **Bevorzugter Kraftstoff** | Der Schlagzeilenpreis auf jeder Karte; Standard für Alarme; wofür die Routensuche optimiert |
| **Standardradius** | Größer = mehr Ergebnisse und langsamere Suchen |

<img src="guide/profile-edit-2.jpg" width="340" alt="Routenplanung: Segment, maximaler Umweg, Mindestersparnis, Auswahl je Segment, Kandidaten">

*Standardwerte der Routenplanung. **Kandidaten pro Abtastpunkt** tauscht Gründlichkeit gegen Tempo auf langen Korridoren.*

<img src="guide/profile-edit-3.jpg" width="340" alt="Anzeige &amp; Stationen, Sichtbarkeit der Stationsnotizen, Startbildschirm, Annäherungsradius">

*Drei getrennte Dinge, die man kennen sollte.*

- **Autobahnen meiden** ändert die berechnete Route selbst, Raststätten sind dann gar keine Kandidaten mehr — meist eine Ersparnis, denn Autobahnkraftstoff ist auf jedem Korridor der teuerste.
- **Stationsnotizen** — *Lokal* (nur dieses Gerät), *Privat* (in dein Konto synchronisiert) oder *Geteilt* (für andere Nutzer sichtbar). Das ist eine Datenschutz-, keine Speicherentscheidung.
- **Startbildschirm** — womit die App öffnet: In der Nähe, Nächste Station, Favoriten oder Karte.

<img src="guide/profile-edit-4.jpg" width="340" alt="Radius und Preismodus des Annäherungs-Overlays, Standardfahrzeug, Region">

*Radius und die Regel **nächste vs. günstigste im Radius** stehen im Profil, ein Pendler- und ein Urlaubsprofil können sich also unterschiedlich verhalten.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Region: Länder-Chips und Sprach-Chips">

*Das Land bestimmt den Datenanbieter. Es zu ändern löscht zwischengespeicherte Stationsdaten.*

<img src="guide/profile-edit-6.jpg" width="340" alt="Sprach-Chips und das Feld für die Heimat-Postleitzahl">

*Eine **Heimat-Postleitzahl** ermöglicht Gebietssuchen ganz ohne GPS — der sauberste Weg, die App zu nutzen, wenn du deinen Standort nie teilen willst.*

---

## Fahrzeuge & OBD2

*Deine Autos, Tankgröße, Adapter-Kopplung · Gültigkeit: dieses Fahrzeug*

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Übersicht Fahrzeuge &amp; OBD2">

*Adapter werden pro Fahrzeug gekoppelt, deshalb führt die Adapter-Kachel in ein Fahrzeug statt auf einen globalen Kopplungsbildschirm.*

Die vollständige Behandlung — FIN, Tankinhalt, Flex-Fuel, Kalibrierungsmodi, Baseline, Schwellen der automatischen Aufzeichnung, Wartungserinnerungen — steht in [Fahrzeuge & OBD2](User-de-Vehicles-And-OBD2).

---

## Fahren & Verbrauch

*Coaching, Belohnungen, Radar, Fehlersuche · Gültigkeit: gemischt*

<img src="guide/driving-and-consumption-1.jpg" width="340" alt="Live-Verbrauchsfenster, Annäherungs-Overlay, meine Fahrzeuge, Coaching-Schalter">

*Die oberen beiden Einträge sind die, die du wirklich justieren wirst.*

| Einstellung | Auswirkung |
|---|---|
| **Live-Verbrauchsfenster** (3/5/10/30 s) | Länger ist ruhiger und beim Fahren besser lesbar; kürzer reagiert schnell genug, um zu zeigen, was das Pedal kostet |
| **Overlay bei Annäherung** | Radius, Preismodus, Abfrage-Untergrenze und Bildschirm-Anheftung für das aktive Profil |
| **Echtzeit-Eco-Coaching** | Leichte Vibration + Bildschirmhinweis bei starker Beschleunigung im Reisetempo |
| **Gesprochenes Fahrcoaching** | Derselbe Rat vorgelesen — die Augen bleiben auf der Straße |
| **Glide-Coach Beta** | Haptik vor einer roten Ampel anhand von OpenStreetMap-Signalen. **Standardmäßig aus — Ablenkungsrisiko**, und es braucht Netz |

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching, Kundenkarten, Erfolge, OBD2-Debug-Protokoll">

*Belohnungen und Fehlersuche.*

- **Kundenkarten** — Rabatte pro Liter, die in die Preisvergleiche einfließen, sodass eine nominell teurere Station für dich korrekt günstiger rangieren kann.
- **Erfolge und Noten anzeigen** — aus blendet jedes Abzeichen, jede Note und jede Trophäe app-weit aus. Gemessen wird weiter, nur nicht mehr angezeigt.
- **OBD2-Debug-Protokoll** — zeichnet jede Sitzung (Verbindung, Handshake, Datenverluste, Neuverbindungen) in ein exportierbares XML-Protokoll. **Standardmäßig aus**: es schreibt laufend und lohnt sich nur, solange du ein Adapterproblem jagst.

---

## Preise & Alarme

*Alarme, Sprachansagen, Verlauf, Community-Meldungen*

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Preise &amp; Alarme: Alarmeintrag, Hinweis zu Sprachansagen, Preisfunktionen">

*Der ausgegraute Sprachansagen-Block ist ein ehrlicher Leerzustand: er nennt beide nötigen Schalter und wo sie stehen.*

| Einstellung | Auswirkung |
|---|---|
| **Preisalarme** | Öffnet die Alarmliste; die Funktion selbst ist ein Schalter unter Funktionen & Nutzungsmodus |
| **Preisverlauf** | Lokale 30-Tage-Erfassung. Aus = keine Diagramme, keine „beste Tankzeit" |
| **TFLite-Preisprognose** | Modell auf dem Gerät; Merkmale und Vorhersagen verlassen das Telefon nie |
| **Community-Preismeldungen** | Braucht TankSync; deine Meldungen sind für andere angemeldete Nutzer sichtbar |
| **Zahlungs-QR scannen** | Ergänzt den QR-Leser auf den Stationsdetails |

---

## Einheiten & Darstellung

*Design, Entfernungseinheit, Verbrauchseinheit, Startbildschirm-Widget · Gültigkeit: gemischt*

<img src="guide/units-and-display-1.jpg" width="340" alt="Design, Entfernungseinheit und Verbrauchseinheit">

*Die **Verbrauchseinheit** wirkt überall gleichzeitig — Live-Banner, Bild-in-Bild-Kachel, Fahrtdurchschnitte, Statistik, Widget.*

- **Entfernungseinheit** folgt standardmäßig dem Land des aktiven Profils (km oder Meilen).
- **Verbrauchseinheit**: *Automatisch* (mpg in UK und USA, sonst L/100 km) oder ausdrücklich L/100 km, km/L oder mpg.

<img src="guide/units-and-display-2.jpg" width="340" alt="Startbildschirm-Widget: Farbschema und Inhaltsvariante">

*Widget-Einstellungen tragen das Label **dieses Profil** und gelten ab der nächsten Aktualisierung für jedes installierte Widget dieses Profils.*

**Inhaltsvariante** — *nur aktueller Preis* oder *prognostisch: beste Tankzeit* (braucht die TFLite-Prognose).

---

## Funktionen & Nutzungsmodus

*Voreinstellungen und jeder Einzelschalter*

<img src="guide/features-and-mode-1.jpg" width="340" alt="Nutzungsmodi Basis, Mittel, Voll und der Zustand Benutzerdefiniert">

*Eine Voreinstellung **überschreibt** jeden Einzelschalter. Wer von Hand justiert hat, bleibt auf Benutzerdefiniert.*

Abhängigkeiten werden durchgesetzt, nicht versteckt: Ein Schalter mit ausgeschalteter Voraussetzung bleibt gesperrt und nennt die Voraussetzung.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Gruppe Suche &amp; Karte: Routenplanung, E-Auto laden, Tankstellen anzeigen, Ladepunkte anzeigen, Kostenrechner">

*Suche & Karte — inklusive der Frage, ob Tankstellen und Ladepunkte überhaupt erscheinen.*

<img src="guide/features-and-mode-3.jpg" width="340" alt="Gruppe Preise &amp; Alarme: Alarme, Verlauf, TFLite-Prognose, Zahlungs-QR, Community-Meldungen">

*Preise & Alarme. Der Preisverlauf ist die Elternfunktion der Prognose darunter.*

<img src="guide/features-and-mode-4.jpg" width="340" alt="Gruppe Tankstellen-Radar mit Sprachansagen und dem Hauptschalter für Sprachausgabe">

*Das Radar, seine Sprachansagen und der Hauptschalter **Sprachausgabe** — ist er aus, öffnet die App nie eine Sprachsynthese.*

<img src="guide/features-and-mode-5.jpg" width="340" alt="Gruppe Verbrauch: Modusauswahl plus Analyse, Gamification, haptischer Coach, Glide-Coach, GPS-Spur, automatische Aufzeichnung">

*Die Auswahl **Aus / Kraftstoff / Kraftstoff + Fahrten** ist die kompakte Form des ganzen Verbrauchsstapels.*

| Schalter | Auswirkung |
|---|---|
| **Verbrauchsanalyse** | Der Auswertungs-Tab über Tankfüllungen und Fahrten |
| **Gamification** | Fahrnoten und verdiente Abzeichen |
| **Haptischer Eco-Coach** | Vibrationsrückmeldung in Echtzeit während der Fahrt |
| **Glide-Coach** | Eco-Hinweise aus OpenStreetMap-Ampeln — braucht Netz |
| **GPS-Fahrtspur** | Speichert die Routenpunkte jeder Fahrt. Aus = kleinere Datenbank, keine Routenkarten |
| **Automatische Aufzeichnung** | Startet eine Fahrt, wenn der gekoppelte Adapter sich mit einem fahrenden Auto verbindet |

<img src="guide/features-and-mode-6.jpg" width="340" alt="Experimentelle OEM-PIDs, OBD2 verlangen, CO2-Dashboard, TankSync, Baseline-Sync">

*Zwei Schalter hier ändern die Datenqualität statt der Oberfläche.*

- **Experimentelle OEM-PIDs** — liest den exakten Tankstand in Litern über herstellerspezifische PIDs auf kompatiblen Adaptern. Bessere Tankdaten, wo es geht; harmlos, wo nicht.
- **OBD2 für Fahrtaufzeichnung verlangen** — **aus** heißt: Fahrten werden auch nur per GPS aufgezeichnet. Das Coaching ist reduziert (kein Momentanverbrauch, weniger Motorsignale), aber nichts ist blockiert.
- **Baseline-Sync** — lädt Fahrzeug-Baselines hoch, damit ein zweites Gerät sie wiederverwenden kann. Braucht TankSync.

<img src="guide/features-and-mode-7.jpg" width="340" alt="Eingabe &amp; Scannen: Kundenkarten, Beleg-OCR, Beleg zum Import teilen">

*Eingabe & Scannen. Die Erkennung läuft auf dem Gerät; diese Schalter entscheiden nur, ob die Abkürzungen existieren.*

<img src="guide/features-and-mode-8.jpg" width="340" alt="Entwickler &amp; experimentell: GitHub-PAT-Rückmeldung, Entwicklermodus, Startup-Trace">

*Entwickler & experimentell — kann aus bleiben, außer du meldest Fehler.*

---

## Datenquellen & Standort

*API-Schlüssel, GPS, automatischer Profilwechsel*

<img src="guide/data-sources-location.jpg" width="340" alt="Schlüsselfelder und der Standort-Block">

*Ein rotes Kreuz beim Kraftstoffpreis-Schlüssel ist der übliche Grund, warum eine deutsche Suche leer bleibt.*

| Einstellung | Auswirkung |
|---|---|
| **Kraftstoffpreise (Tankerkoenig)** | Nur für Deutschland nötig. Kostenlos, pro Nutzer, im hardwaregestützten Tresor |
| **E-Auto laden (OpenChargeMap)** | Optional — ersetzt den gemeinsamen Schlüssel durch dein eigenes Kontingent |
| **Automatische Aktualisierung** | Frischt die GPS-Position vor jeder Suche auf. Aus = schnellere Suchen, evtl. von veralteter Position |
| **Automatischer Profilwechsel** | Wechselt das Profil beim Grenzübertritt, damit Anbieter und Sorte automatisch stimmen |

---

## Synchronisierung & Konto

<img src="guide/sync-and-account.jpg" width="340" alt="TankSync-Status, Warnung zu veraltetem Schema, auf E-Mail wechseln, Einwilligungen, meine Daten ansehen">

*Dieser Bildschirm zeigt auch Probleme — hier ein selbst gehostetes TankSync-Schema, das veraltet ist und deshalb stillschweigend einige Tabellen nicht synchronisiert.*

Vollständig behandelt in [Datenschutz, Daten & Sync → TankSync](User-de-Privacy-Profiles-Sync#tanksync-optionale-cloud-synchronisierung). Das Wesentliche:

- **Sparkilo Community / eigene Datenbank / Datenbank einer Gruppe** — drei Betriebsformen mit drei verschiedenen Verantwortlichen.
- **Anonym → E-Mail** — *Auf E-Mail wechseln* behält deine Daten und dein Konto und ergänzt eine Anmeldemöglichkeit von einem anderen Gerät. Ein anonymes Konto existiert nur auf dem Gerät, das es erzeugt hat.
- **Schema veraltet** — Selbsthoster müssen nach einem App-Update das Einrichtungs-SQL erneut ausführen, sonst scheitert die Synchronisierung neuer Tabellen still.

---

## Datenschutz & Daten

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Datenschutzkontrollen: Kartenkachel-Proxy und Laden von Markenlogos">

*Zwei netzbezogene Datenschutzentscheidungen, jeweils formuliert als das, was sie wirklich preisgeben.*

- **Kartenkacheln über den Sparkilo-Proxy** — *an*: der EU-Server des Entwicklers sieht deinen Kartenausschnitt und deine IP und holt die Kacheln für dich. *Aus*: die Kacheln kommen direkt von tile.openstreetmap.org, das dann deine IP sieht. Keine Option heißt „kein Netz"; du wählst, von wem du gesehen wirst. Der F-Droid-Build nutzt den Proxy nie.
- **Markenlogos aus dem Internet laden** — standardmäßig *aus*; es werden mitgelieferte generische Logos genutzt. An kommen sie von logo.clearbit.com, das deine IP sieht.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Speichernutzung nach Kategorie mit Größen">

*Speicher, aufgeschlüsselt. Der Cache ist fast immer der größte Anteil und der einzige, den man gefahrlos wegwerfen kann.*

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Cache-Lebensdauern je Kategorie und die Aktion Cache leeren">

*Cache-Verwaltung, mit der Lebensdauer jeder Klasse: Suchen 5 Min., Stationsdetails 15 Min., Preisabfragen 5 Min., Favoritendaten 30 Min., Ortssuchen 30 Min., PLZ-Geokodierung 24 h.*

<img src="guide/cache-clear-dialog.jpg" width="340" alt="Bestätigungsdialog zum Leeren des Caches">

*Den Cache zu leeren löscht nur zwischengespeicherte Ergebnisse und Preise — Profile, Favoriten und Einstellungen bleiben. Die nächsten Suchen sind langsamer; verloren geht nichts.*

---

## Sicherung & Wiederherstellung

<img src="guide/backup-restore.jpg" width="340" alt="Einträge Sicherung exportieren und Sicherung wiederherstellen">

*Eine vollständige ZIP-Datei mit Fahrzeugen, Tankfüllungen, Fahrten und Ladeprotokollen.*

**Sicherung exportieren** schreibt die ZIP in deinen Downloads-Ordner. **Sicherung wiederherstellen** bietet *zusammenführen* oder *ersetzen* — Zusammenführen behält, was auf dem Gerät ist, und ergänzt Fehlendes; Ersetzen löscht zuerst. Nutze das vor einem Telefonwechsel oder einem Werksreset. TankSync ist keine Sicherung: es spiegelt ausgewählte Kategorien, nicht alles.

---

## Erweitert & Entwickler

<img src="guide/advanced-developer.jpg" width="340" alt="GitHub-PAT-Feld und der Eintrag Entwicklerwerkzeuge">

*Das GitHub-Token ist optional — ohne es wird eine fehlgeschlagene Scan-Rückmeldung manuell geteilt, statt automatisch ein Issue anzulegen.*

Der Eintrag **Entwicklerwerkzeuge** erscheint nur bei eingeschaltetem Entwicklermodus (Funktionen & Nutzungsmodus → Entwickler & experimentell).

<img src="guide/developer-tools-1.jpg" width="340" alt="Entwicklerwerkzeuge: Fehlerprotokoll, Testbenachrichtigung, Test-Alarmpipeline, Diagnosen, OCR-Tester, Caches leeren">

*Für normale Nutzer ist das Fehlerprotokoll der nützliche Teil: **Fehlerprotokoll speichern** schreibt bereinigte Spuren in die Downloads, zum Anhängen an einen Fehlerbericht.*

<img src="guide/developer-tools-2.jpg" width="340" alt="Diagnosen kopieren, Datenzugriffs-Trace exportieren, Startup-Trace als Wasserfall">

*Der Startup-Trace ist ein Wasserfall der Initialisierungsphasen — so diagnostiziert man einen langsamen Start, statt zu raten.*

<img src="guide/developer-tools-3.jpg" width="340" alt="Annäherungs-Overlay testen und Build-Infos mit Version und Kanal">

***Annäherungs-Overlay testen** setzt 30 s lang einen synthetischen Zustand, damit du die Bild-in-Bild-Preisanzeige prüfen kannst, ohne irgendwohin zu fahren.*

---

## Über

<img src="guide/about-1.jpg" width="340" alt="Über: App-Version und Build-Nummer, Autor, Lizenz, Datenschutzerklärung, GitHub, Fehlerbericht">

***Version und Build-Nummer** — nenne beide in jedem Fehlerbericht und prüfe sie zuerst, wenn eine Korrektur „nicht funktioniert hat" (womöglich hat der Store-Rollout dich noch nicht erreicht).*

<img src="guide/about-2.jpg" width="340" alt="Über: Unterstützungs-Links und Datenquellenangaben">

*Die App ist kostenlos, quelloffen und werbefrei. Die Quellenangaben für Preis- und Kartendaten stehen unten, wie es die Lizenzen verlangen.*

---

**Siehe auch:** [Wie Sparkilo funktioniert](User-de-How-It-Works) · [Datenschutz, Daten & Sync](User-de-Privacy-Profiles-Sync)
**Weiter:** [Datenschutz, Daten & Sync →](User-de-Privacy-Profiles-Sync)
