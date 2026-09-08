# Datenschutz, Daten & Sync

Sparkilos Datenschutzversprechen sind überprüfbar, und auf dieser Seite überprüfst du sie.

---

## Datenschutz als Standard

Konkret:

- **Keine Google Play Services. Kein Firebase. Kein Google Analytics. Keine Werbe-IDs.**
- **Keine Tracking-SDKs Dritter** — die öffentliche `pubspec.yaml` hat null Analytics-Abhängigkeiten.
- **Kein Konto nötig.** Die App ist ohne eines voll funktionsfähig.
- **Local-first.** Alles bleibt auf deinem Telefon, bis du etwas einschaltest.
- **Einwilligung vor Verarbeitung**, plus eine Erklärung in Klartext *vor* jeder System-Abfrage.
- **Open Source, MIT.** Die eigenen Tests des Projekts schlagen fehl, wenn Datenschutzerklärung und Code auseinanderlaufen.

### Was das Telefon tatsächlich verlässt

| Daten | An wen | Wann | Vermeidbar? |
|---|---|---|---|
| Suchkoordinaten oder Regionscode | Der offizielle Preisanbieter deines Landes | Bei jeder Live-Suche | Nach Postleitzahl statt per GPS suchen |
| Kartenausschnitt + IP | Der EU-Kachel-Proxy des Entwicklers, der von OpenStreetMap holt | Kartennutzung | Proxy aus — dann sieht OpenStreetMap deine IP direkt |
| Deine IP | logo.clearbit.com | Nur mit aktivierten Internet-Logos | Aus lassen (Standard) |
| Bereinigte Absturzspuren | Sentry | Nur mit *Fehlermeldungen* an | Standardmäßig aus |
| Deine synchronisierten Zeilen | Deine gewählte TankSync-Datenbank | Nur mit TankSync an | Standardmäßig aus |

**Deine Identität ist nie Teil einer Preisabfrage**, und der Entwickler betreibt keinen Server, der deine Suchen speichert.

---

## Wer ist Verantwortlicher

Das hängt vollständig davon ab, wie du TankSync nutzt:

| Modus | Verantwortlicher |
|---|---|
| **Kein TankSync** *(Standard)* | **Nur du.** Nichts liegt auf einem Server des Entwicklers |
| **Eigenes Supabase-Projekt** | **Du** — der Entwickler sieht es nie |
| **Datenbank einer Gruppe** | **Der Gruppenbesitzer**, der das Projekt betreibt |
| **Sparkilo Community** | **Der Entwickler, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)); Supabase, Inc. ist Auftragsverarbeiter; gehostet in der EU (AWS eu-central-1, Frankfurt) |

Die App nennt den zutreffenden Fall **vor** dem Verbinden und noch einmal in der Zeile *Sync-Modus* unter **Synchronisierung & Konto**.

---

## Der Bildschirm Datenschutz & Daten

**Einstellungen → Datenschutz & Daten** ist der einzige Einstieg. Er öffnet mit einer Übersichtskarte, gefolgt von vier Themenkacheln:

| Zeile oder Kachel | Was sie dir sagt |
|---|---|
| *Ihre Daten bleiben auf diesem Gerät* / *Ihre Daten werden zusätzlich mit TankSync synchronisiert* | Wo deine Daten gerade physisch liegen |
| *Synchronisierung: aus* / *Synchronisierung: an · anonymes Konto* / *Synchronisierung: an · E-Mail-Konto* | Ob TankSync verbunden ist, und mit welcher Art Konto |
| *… auf diesem Gerät gespeichert* | Der Speicher, den die App gerade insgesamt belegt |
| **Ihre Entscheidungen** — *n von 5 aktiviert* | Die fünf Einwilligungen und die zwei Netzwerk-Schalter |
| **Daten auf diesem Gerät** — *Größe · n Kategorien* | Jede lokal gehaltene Kategorie mit Größe und Anzahl |
| **Synchronisierung & Konto** | TankSync-Status, Konto, Datenbank und die Sync-Aktionen |
| **Exportieren oder löschen** — *ZIP, JSON, CSV · Fehlerprotokoll (n)* | Die Exporte, das Fehlerprotokoll und die Gefahrenzone |

Das frühere *Datenschutz-Dashboard* gibt es nicht mehr: seine Zähler, Sync-Fakten, Exporte und der Löschknopf liegen jetzt unter diesen vier Themen. Alte Links und Startbildschirm-Widgets, die auf das Dashboard zeigten, öffnen stattdessen **Datenschutz & Daten**.

---

## Ihre Entscheidungen

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Datenschutz-Schalter: Kartenkachel-Proxy und Laden von Markenlogos">

*Die zwei Netzwerk-Schalter, jeder benannt nach dem, was er tatsächlich preisgibt. Die fünf Einwilligungen sitzen darüber auf derselben Karte.*

Jede Zeile ist ein Schalter — *„Sie können Ihre Datenschutzeinstellungen jederzeit ändern."*

| Zeile | Was sie entscheidet |
|---|---|
| **Standortzugriff** | Tankstellen in der Nähe über deinen Standort finden. Aus: nach Postleitzahl suchen |
| **Fehlermeldungen** | Anonyme Absturzberichte zur Verbesserung der App senden. Standardmäßig aus — ohne sie wird nie etwas hochgeladen |
| **Cloud-Synchronisierung** | Favoriten und Alarme geräteübergreifend synchronisieren — die Einwilligung hinter TankSync |
| **VIN online dekodieren** | Die FIN über den kostenlosen öffentlichen Dienst der NHTSA dekodieren. Aus: Fahrzeugdaten selbst eintippen |
| **Fahrtaufzeichnungen synchronisieren** | OBD2- und GPS-Fahrten in TankSync sichern. Ausgegraut, bis *Cloud-Synchronisierung* an ist |
| **Kartenkacheln über den Sparkilo-Proxy laden** | An: Kartenausschnitt und deine IP-Adresse erreichen den EU-Server des Entwicklers, der die Kacheln von OpenStreetMap holt. Aus: Kacheln laden direkt von tile.openstreetmap.org, das dann stattdessen deine IP sieht |
| **Markenlogos aus dem Internet laden** | Standardmäßig aus: mitgelieferte Platzhalter werden gezeigt. An: Logos kommen von logo.clearbit.com, das deine IP-Adresse sieht |

Die zwei Netzwerk-Schalter tragen einen Info-Knopf (*Mehr erfahren*) mit der vollständigen Erklärung. Die Fußzeile hält *Einwilligung erteilt am … · Datenschutzerklärung Version …* fest — die Nachweiskette, die die DSGVO verlangt — und verlinkt die **Datenschutzerklärung** in deiner Sprache. Eine Einwilligung zurückzuziehen stoppt diese Verarbeitung sofort; frühere Verarbeitung bleibt rechtmäßig.

---

## Daten auf diesem Gerät

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Speichernutzung nach Kategorie aufgeschlüsselt mit Größen">

*Speicher, aufgeschlüsselt: ein Balken nach Kategorie, dann eine Zeile je Kategorie mit Größe, Anzahl und einem Punkt in der Balkenfarbe. Leere Kategorien sind ausgegraut, nicht versteckt.*

Die Zeilen unter **Speichernutzung auf diesem Gerät**: **Favoriten** · **Stationsbewertungen** · **Suchprofile** · **Preisalarme** · **Preisverlauf-Stationen** · **Ausgeblendete Stationen** · **Blockierte Nutzer** · **Gespeicherte Routen** · **Cache** · **Einstellungen** (*API-Schlüssel, aktives Profil*) · **Gesamt**.

Alles liegt in **verschlüsselten Hive-Datenbanken**; der Schlüssel steckt im Android Keystore / iOS Keychain.

| Box | Inhalt |
|---|---|
| `settings` | Konfiguration, Land, Sprache, Einheiten |
| `profiles` | Deine Suchprofile |
| `favorites` | Gespeicherte Stationen mit allen Daten |
| `cache` | Zwischengespeicherte API-Antworten und Routen |
| `priceHistory` | Die lokalen 30-Tage-Preisdaten |
| `price_snapshots` | Snapshots für Offline-Nutzung und Widget |
| `alerts` | Deine Alarmregeln |
| `service_reminders` | Wartungserinnerungen |
| `obd2Baselines` | Verbrauchs-Baselines je Fahrzeug |
| `obd2TripHistory` | Fahrten: Route, Geschwindigkeit, Sensoren |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Adapter-Fähigkeits-Caches |

API-Schlüssel, das GitHub-Token und die TankSync-Sitzung liegen im hardwaregestützten Tresor, nicht in Hive.

### Cache-Details

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Cache-Lebensdauern je Kategorie und die Aktion Cache leeren">

*Die Kachel **Cache-Details** klappt auf die Lebensdauer jeder Cache-Klasse auf — Suchen 5 min, Stationsdetails 15 min, Preisabfragen 5 min, Favoritendaten 30 min, Ortssuchen 30 min, Postleitzahl-Geokodierung 24 h — und den Knopf **Cache leeren**.*

Der Cache speichert API-Antworten für schnellere Ladezeiten und Offline-Zugriff. Ihn zu leeren löscht nur zwischengespeicherte Ergebnisse und Preise — Profile, Favoriten und Einstellungen bleiben unberührt; die nächsten Suchen sind langsamer, nichts geht verloren. Der Knopf zeigt *Cache ist leer* und ist deaktiviert, wenn es nichts zu leeren gibt.

### Blockierte Nutzer

**Blockierte Nutzer** ist die einzige antippbare Zeile: sie öffnet die Liste der Konten, die du blockiert hast, jedes mit einem Knopf **Freigeben**. Von diesen Nutzern geteilte Inhalte werden auf diesem Gerät ausgeblendet; Blockieren ist lokal — es meldet das Konto nicht.

---

## Berechtigungen

| Berechtigung | Wofür | Ablehnbar? |
|---|---|---|
| **Standort** *(bei Nutzung)* | Umkreissuche, Routenstart, Fahrtaufzeichnung | Ja — Postleitzahl nutzen |
| **Standort** *(„Immer zulassen")* | **Nur** OBD2-Autoaufzeichnung, damit die Route bei ausgeschaltetem Bildschirm weiterläuft | Ja — Fahrten manuell starten |
| **Bluetooth-Suche + -Verbindung** | Adapter koppeln | Ja — OBD2 ist optional |
| **Benachrichtigungen** | Preisalarme | Ja — Alarme lösen nicht aus |
| **Kamera** | OCR von Zapfsäulen, Belegen und QR-Codes auf dem Gerät | Ja — von Hand tippen |
| **Internet** | Preis- und Kartenaufrufe | Erforderlich |

Bis Android 11 verlangt das System **Standort** für jede Bluetooth-Suche — eine Plattformregel, keine Tracking-Entscheidung. Jede Berechtigung lässt sich später in den Systemeinstellungen entziehen; die zugehörige Funktion stellt dann einfach ihre Arbeit ein.

---

## Synchronisierung & Konto

<img src="guide/sync-and-account.jpg" width="340" alt="Synchronisierung &amp; Konto mit dem TankSync-Status, einer Warnung vor veraltetem Schema und dem Eintrag Einwilligungen">

*Erreichbar über die Kachel in Datenschutz & Daten und direkt aus der Einstellungen-Wurzel. Der Bildschirm zeigt auch Probleme — hier ein selbst gehostetes Schema, das veraltet ist und deshalb einige Tabellen stillschweigend nicht synchronisiert.*

Freiwillig. *Deaktiviert* heißt: nichts liegt auf irgendeinem Server. Die Übersichtskarte oben nennt die Fakten:

| Zeile | Wert |
|---|---|
| **Status** | *Verbunden* oder *Deaktiviert* |
| **Sync-Modus** | *Sparkilo Community — EU-Server des Entwicklers* · *Geteilte Gruppe — eine Datenbank, der Sie beigetreten sind* · *Selbst gehostet — Ihr eigenes Supabase* |
| **Konto** | *Anonymes Konto, an dieses Gerät gebunden* oder *E-Mail-Konto: …* |
| **Benutzer-ID** | Deine UUID mit Kopierknopf — nenne sie in einer Supportanfrage |
| **Datenbank-Host** | Der Hostname der Datenbank, mit der du synchronisierst; der Schlüssel wird nie gezeigt |
| **Gelernte Fahrzeugprofile teilen** | Pro-Fahrzeug-Verbrauchsbaselines hochladen, damit ein zweites Gerät sie wiederverwenden kann |

### Drei Betriebsformen

1. **Sparkilo Community** — die gemeinsame Datenbank des Entwicklers (Supabase, EU/Frankfurt). Dein Konto ist eine zufällige UUID; du kannst eine E-Mail verknüpfen, um es von einem anderen Gerät zu erreichen. Community-Preismeldungen und öffentlich geteilte Bewertungen sind für alle angemeldeten Nutzer lesbar.
2. **Eigenes Supabase-Projekt** — SQL-Schema und Edge Functions liegen im Repository. Du bist Verantwortlicher und behältst das volle Eigentum.
3. **Datenbank einer Gruppe** — verbinde dich mit einem Projekt von Familie oder Freunden. Diese Person ist Verantwortliche.

### Einrichten

**Synchronisierung & Konto → Cloud-Sync einrichten.** Für Community den QR aus dem Wiki scannen oder URL und Anon-Key einfügen; für eigenes oder Gruppenprojekt Projekt-URL und Anon-Key einfügen. Beides liegt im hardwaregestützten Tresor, und reine HTTP-Endpunkte werden rundweg abgelehnt.

> **Selbsthoster:** Nach einem App-Update kann der Bildschirm warnen, dein **Schema sei veraltet**. Führe das angebotene Einrichtungs-SQL erneut aus — sonst scheitert die Synchronisierung der neueren Tabellen **stillschweigend**, was weit schlimmer ist als ein sichtbarer Fehler.

### Aktionen im verbundenen Zustand

- **Zu E-Mail wechseln** — Daten behalten, Anmeldung von anderen Geräten hinzufügen; die UUID bleibt gleich. **Zu anonym wechseln** macht das Gegenteil.
- **Einwilligungen** — ein Querverweis auf *Ihre Entscheidungen*: die Einwilligungen für Cloud-Synchronisierung und Fahrten-Sync liegen dort, nicht hier.
- **Meine Daten anzeigen** — der Bildschirm *Datentransparenz* listet die Zeilen, die der Server für dich hält; sein Knopf **Alle synchronisierten Fahrten vergessen** entfernt nur die Fahrtzeilen.
- **Gerät verknüpfen** — ein zweites Telefon auf dasselbe Konto holen.
- **Synchronisierte Daten löschen** — *Fahrten*, *Fahrzeuge*, *Tankvorgänge* oder *Alles* aus der Sync-Datenbank entfernen; lokale Kopien bleiben.
- **Datenbank teilen** — ein QR-Code, damit Familie oder Freunde deiner eigenen oder einer Gruppendatenbank beitreten können (auf Community nicht angeboten).
- **Trennen** — Synchronisierung beenden; lokale Daten bleiben erhalten.
- **Konto löschen** — alle Serverdaten dauerhaft entfernen, dann die Kontoidentität selbst samt verknüpfter E-Mail. Angeboten für eigene und Gruppendatenbanken; auf Community nimm *Synchronisierte Daten löschen → Alles* oder die unten beschriebene Gefahrenzone.

### Was synchronisiert wird

Favoriten · Preisalarme · ignorierte Stationen · Bewertungen (mit Datenschutz-Kennzeichen je Bewertung: lokal / privat synchronisiert / öffentlich geteilt) · Routen · Fahrzeuge inklusive FIN und Adapterkennung · Tankfüllungen und Ladeprotokolle · Verbrauchs-Baselines · von dir eingereichte Community- und Inhaltsmeldungen.

**Fahrten sind getrennt.** Die Fahrten-Synchronisierung ist auch *nach* dem Einschalten der Cloud-Synchronisierung freiwillig — der Schalter *Fahrtaufzeichnungen synchronisieren* bleibt bis dahin ausgegraut. Auf dem Server bleiben Fahrtzusammenfassungen bis zur Löschung; die detaillierten GPS-Stichproben werden nach 90 Tagen entfernt.

Jede Tabelle ist durch Row-Level-Security geschützt: ein Konto kann nur eigene Zeilen lesen oder löschen. Geteilte Bewertungen und Community-Preismeldungen sind die einzigen Zeilen, die andere angemeldete Nutzer sehen.

### Konflikte

**Lokal gewinnt immer.** Sync ergänzt und aktualisiert, löscht aber nie still — nur dein ausdrückliches Löschen löst ein Serverlöschen aus, das sich dann auf deine anderen Geräte fortpflanzt.

---

## Exportieren oder löschen

Ein Knopf, ein Format-Blatt, eine rote Zone. **Meine Daten exportieren** öffnet *Format wählen*:

| Format | Hinweis im Blatt | Was du bekommst |
|---|---|---|
| **ZIP-Archiv** | *Alles, inklusive Anhänge — für eine vollständige Sicherung* | `sparkilo-my-data-<datum>.zip`: ein maschinenlesbares JSON je Kategorie — Favoriten, Alarme, Profile, Routen, Preisverlauf, Fahrzeuge, Tankfüllungen, Fahrten mit GPS-Stichproben plus ein GPX je Fahrt, Baselines, Wartungserinnerungen, Ladeprotokolle, Erfolge und dein Einwilligungsnachweis — plus jede Servertabelle, wenn TankSync verbunden ist |
| **JSON** | *Maschinenlesbar — für eine andere Software* | `tankstellen-data.json`: die Kategorien auf dem Gerät in einer flachen Datei, zusätzlich in die Zwischenablage kopiert |
| **CSV** | *Tabellenkalkulation — eine Tabelle pro Kategorie* | `tankstellen-data.csv`: ein `# table`-Block je Kategorie — Favoriten, Alarme, Preisverlauf und der Rest — zusätzlich in die Zwischenablage kopiert |

Alle Exporte landen im **öffentlichen Downloads**-Ordner (*Im Downloads-Ordner gespeichert*), damit jeder Dateimanager sie findet.

**Fehlerprotokoll** zeigt, wie viele bereinigte Spuren die App hält (*Keine Einträge* … *n Einträge*). **Speichern** schreibt sie in die Downloads für einen Fehlerbericht — keine E-Mails, Koordinaten, Schlüssel oder Token darin, und es wird nie automatisch etwas hochgeladen; **Leeren** leert das Protokoll.

**Gefahrenzone** — *Löscht dauerhaft alles, was die App auf diesem Gerät speichert. Bei aktiver Synchronisierung werden auch Ihre Daten auf dem TankSync-Server gelöscht.* **Alle meine Daten löschen** fragt nach Bestätigung und listet, was geht: Favoriten und Stationsdaten, Suchprofile, Preisalarme, Preisverlauf, zwischengespeicherte Daten, dein API-Schlüssel, alle App-Einstellungen. Bei verbundenem TankSync löscht es zuerst deine Serverzeilen; ließ sich eine Tabelle nicht löschen, **nennt die App welche**, statt Erfolg zu behaupten. Danach kehrt die App zur Ersteinrichtung zurück. Unwiderruflich.

Für einen wiederherstellbaren Stand statt eines Datenexports nimm **Einstellungen → Sicherung & Wiederherstellung** — siehe [Einstellungen-Referenz](User-de-Settings-Reference#sicherung--wiederherstellung).

---

## Deine Rechte nach der DSGVO

Jedes Recht aus Art. 15–22 hat einen Knopf. Keine Supportanfrage nötig.

- **Auskunft** — *Daten auf diesem Gerät* listet jede Kategorie auf dem Gerät; *Meine Daten anzeigen* listet jede Zeile in deiner TankSync-Datenbank.
- **Datenübertragbarkeit** — *Meine Daten exportieren* als ZIP-Archiv.
- **Berichtigung** — jeden Eintrag direkt bearbeiten; die Änderung synchronisiert, wenn TankSync an ist.
- **Löschung**
  - *Gerät:* **Exportieren oder löschen → Alle meine Daten löschen**.
  - *Server:* **Synchronisierung & Konto → Konto löschen** löscht jede dir gehörende Zeile **in einer Transaktion** — Favoriten, Alarme, ignorierte Stationen, Preis- und Inhaltsmeldungen, Fahrzeuge, Tankfüllungen, Routen, Baselines, Bewertungen, Fahrten, gegebene und erhaltene Fahrtfreigaben, Sync-Einstellungen, Löschnachweise und deine Nutzerzeile — dann die Kontoidentität selbst samt verknüpfter E-Mail. Ließ sich eine Tabelle nicht löschen, **nennt die App welche**, statt Erfolg zu behaupten.
  - *Einzelne Elemente:* alles ist einzeln löschbar; **Synchronisierte Daten löschen** entfernt Fahrten, Fahrzeuge oder Tankvorgänge vom Server, und **Alle synchronisierten Fahrten vergessen** entfernt nur die Fahrtzeilen.
- **Widerruf der Einwilligung** — Datenschutz & Daten → Ihre Entscheidungen; die Verarbeitung endet sofort.
- **Einschränkung / Widerspruch** — TankSync, Fahrten-Sync, Kachel-Proxy oder Diagnose ausschalten; Berechtigungen in den Systemeinstellungen entziehen.
- **Beschwerde** — bei einer Aufsichtsbehörde, insbesondere in deinem Wohnsitz-, Arbeits- oder Verstoßland. Der Entwickler würde sich über die Chance freuen, es vorher zu klären: [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

Kannst du die App nicht mehr öffnen, fordere die Löschung per E-Mail von der mit dem Konto verknüpften Adresse an. **Ein anonymes Konto ohne verknüpfte E-Mail kann von niemandem identifiziert werden — auch nicht vom Entwickler — ohne das Gerät, das es erzeugt hat.** Das ist der Preis dafür, dass du dich nicht registrieren musst.

Volltext: **[Datenschutzerklärung v3, 29. August 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/de/)**, in allen 23 App-Sprachen verfügbar. Die App merkt sich, welcher Fassung du zugestimmt hast, und zeigt die Richtlinie erneut, wenn sie sich ändert.

---

**Siehe auch:** [Einstellungen-Referenz](User-de-Settings-Reference) · [Wie Sparkilo funktioniert → Wo deine Daten liegen](User-de-How-It-Works#wo-deine-daten-liegen)
**Weiter:** [Fehlersuche & FAQ →](User-de-Troubleshooting-FAQ)
