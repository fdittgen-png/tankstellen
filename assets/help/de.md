# Sparkilo — Benutzerhandbuch (Deutsch)

> *Weniger pro Liter zahlen. Weniger Liter pro Kilometer verbrennen. Genau sehen, was es gekostet hat.*

Sparkilo ist eine kostenlose Open-Source-App, die die **laufenden Kosten deines Autos senkt**. Kein Konto, keine Werbung, keine Tracker, keine Google Play Services. Alles, was die App über dich weiß, bleibt auf deinem Telefon, bis du selbst etwas anderes einschaltest.

*Der Bildschirm, den du am häufigsten sehen wirst: Live-Preise in deiner Nähe, günstigste zuerst, mit der offiziellen Open-Data-Quelle im Kopf.*

---

## Die drei Spar-Ebenen

Die ganze App ist um eine Idee herum gebaut: **Ein Auto kostet auf drei voneinander unabhängigen Wegen Geld, und jeder braucht ein eigenes Werkzeug.**

| Ebene | Die Frage dahinter | Wo sie lebt |
|---|---|---|
| **1. Preis** | *Wo ist Kraftstoff gerade am günstigsten?* | Suche, Karte, Favoriten, Alarme, Routenplanung |
| **2. Verbrauch** | *Wie viele Liter verbrauche ich pro 100 km — und warum?* | Fahrten, Eco-Coaching, OBD2 |
| **3. Wahrheit** | *Was habe ich wirklich bezahlt, und ist die Schätzung der App ehrlich?* | Kraftstoff-Tab, Tankfüllungen, Verbrauchsstatistik |

Ebene 1 spart schon Geld und braucht nichts außer der App. Ebene 2 und 3 brauchen deine Tankfüllungen; Ebene 2 wird mit einem günstigen OBD2-Adapter deutlich schärfer. Wie tief du gehst, entscheidest du — siehe Wie Sparkilo funktioniert.

---

## Was in diesem Handbuch steht

**Hier anfangen**

| Seite | Was du lernst |
|---|---|
| Erste Schritte | Installation, Einwilligung beim ersten Start, Land und Sprache, Nutzungsmodus, erste Suche |
| Wie Sparkilo funktioniert | Die Konzepte hinter allem: Profile, Nutzungsmodi, eine Datenquelle pro Land, wo deine Daten liegen, wie aus einem Liter eine Zahl wird |

**Günstig tanken (Ebene 1)**

| Seite | Was du lernst |
|---|---|
| Tankstellen finden | Der zentrale Such-Button, Kriterien, Stationskarte lesen, Detailseite, Karte, Tankstellen-Radar |
| Routenplanung | Günstigste Stopps entlang der Route, grenzüberschreitende Korridore, die vier Strategien |
| Favoriten & Alarme | Gespeicherte Stationen, Stations- und Umkreisalarme, wie die Hintergrundprüfung wirklich arbeitet |
| E-Auto laden | Ladepunkte über OpenChargeMap, Stecker, Leistungsfilter |
| Preisverlauf & Prognosen | Der lokale 30-Tage-Verlauf, „beste Tankzeit" und was der Algorithmus bewusst *nicht* tut |

**Weniger verbrauchen und wissen, was es gekostet hat (Ebene 2 und 3)**

| Seite | Was du lernst |
|---|---|
| Fahrzeuge & OBD2 | Fahrzeugmodell, Tankgröße, Flex-Fuel, Adapter koppeln, Baseline-Kalibrierung, regelbasiert vs. Fuzzy |
| Tankbuch & Verbrauch | Tankfüllungen, Füllstand, Tank-Bericht, Genauigkeitsstufen, Kosten pro km je Kraftstoff |
| Fahrten & Eco-Coaching | Aufzeichnung per GPS oder OBD2, Fahrtdetails, Fahrnote, CO₂-Dashboard |

**Nachschlagen**

| Seite | Was du lernst |
|---|---|
| Einstellungen-Referenz | Jeder Bildschirm des zweistufigen Einstellungsbaums, mit den Auswirkungen jedes Schalters |
| Datenschutz, Daten & Sync | Einwilligungen, die Themen unter Datenschutz & Daten, TankSync, Sicherung, deine DSGVO-Rechte |
| Fehlersuche & FAQ | Nichts gefunden? Adapter verbindet nicht? Widget veraltet? |

---

## Die 17 unterstützten Länder

🇩🇪 Deutschland · 🇫🇷 Frankreich · 🇦🇹 Österreich · 🇪🇸 Spanien · 🇮🇹 Italien · 🇩🇰 Dänemark · 🇵🇹 Portugal · 🇱🇺 Luxemburg · 🇸🇮 Slowenien · 🇬🇧 Vereinigtes Königreich · 🇦🇷 Argentinien · 🇦🇺 Australien · 🇲🇽 Mexiko · 🇰🇷 Südkorea · 🇨🇱 Chile · 🇬🇷 Griechenland · 🇷🇴 Rumänien

Jedes Land wird über **seine eigene offizielle staatliche Open-Data-Quelle** bedient — niemals über einen einzelnen Aggregator. Deutschland braucht einen kostenlosen API-Schlüssel von [tankerkoenig.de](https://creativecommons.tankerkoenig.de/); alle anderen Länder funktionieren sofort. Warum das für das zählt, was du auf dem Bildschirm siehst, steht in Wie Sparkilo funktioniert.

Die Oberfläche ist in **23 Sprachen** übersetzt (bg, cs, da, de, el, en, es, et, fi, fr, hr, hu, it, lt, lv, nb, nl, pl, pt, ro, sk, sl, sv) und folgt deiner Systemsprache.

<a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
  <img alt="Jetzt bei Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/de_badge_web_generic.png" height="80"/>
</a>

---

**Weiter:** Erste Schritte →

> **Hinweis zu den Screenshots.** Alle Screenshots in diesem Handbuch stammen von einem Gerät, auf dem die App auf **Französisch** läuft, gegen die französische Live-Preisquelle. Die Oberfläche ist vollständig lokalisiert — deine Bildschirme haben dasselbe Layout mit den Wörtern deiner Sprache.

---

# Erste Schritte

Zehn Minuten von der Installation bis zum ersten gesparten Euro. Wenn du danach nur eine weitere Seite liest, dann Wie Sparkilo funktioniert.

---

## 1. Installieren

### Google Play (Android)

Installiere aus dem **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — die öffentliche Produktionsversion.

> **Aus der Beta?** Play liefert weiter Beta-Builds, sobald du am offenen Test teilnimmst (der Eintrag zeigt ein *(Beta)*-Kennzeichen). Zur Produktion wechseln: [Play-Eintrag](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Programm verlassen** → deinstallieren → neu installieren.
>
> **Neues zuerst?** Bleib in der Beta — jeder Build erreicht den Beta-Kanal vor der Produktion.

### F-Droid (Android, ohne Google)

Ein vollständig **GMS-freier** Build läuft über ein eigenes F-Droid-Repository (OpenStreetMap-Karten, keine Google-Dienste). In F-Droid **Einstellungen → Repositories → +** und hinzufügen:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Dann nach **Sparkilo** suchen. Ist der Play-Build installiert, zuerst deinstallieren — anderer Signaturschlüssel, also kein Update darüber.

### Andere Wege

- **APK** — von den [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — TestFlight-Beta; Einladung über [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) anfragen, bis der App-Store-Eintrag live ist.

**Mindestens Android** 7.0 (API 24), Ziel Android 15. **Mindestens iOS** 15.5, Ziel iOS 18.

Kein Konto, keine Anmeldung, keine E-Mail. Die App ist nutzbar, sobald die Installation fertig ist.

---

## 2. Erster Start — Einwilligung

Vor jedem anderen Bildschirm zeigt die App einen **DSGVO-Einwilligungsdialog**. Das ist kein Cookie-Banner: Er listet jeden Verarbeitungszweck, und die App startet erst, wenn du zustimmst.

*Jede hier gezeigte Einwilligung erscheint später erneut unter Einstellungen → Datenschutz & Daten, mit dem Datum und der Fassung der Richtlinie, die du gesehen hast.*

| Punkt | Wofür | Wenn du ablehnst |
|---|---|---|
| **Standort** *(bei Nutzung)* | Umkreissuche, Routenstart, Fahrtaufzeichnung | Nach Postleitzahl suchen oder Punkt auf der Karte wählen |
| **Benachrichtigungen** | Nur für Preisalarme | Alarme lösen nie aus |
| **Diagnose** | Absturzspuren an Sentry — **standardmäßig aus** | Es wird nichts gesendet; das Fehlerprotokoll kannst du trotzdem selbst speichern |

Vor jeder *System*-Abfrage (Kamera, Bluetooth, Benachrichtigungen) erklärt die App zuerst selbst kurz, worum es geht — du weißt also, wozu du zustimmst, bevor Android fragt.

Volltext: **[Datenschutzerklärung v3, 29. August 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/de/)**.

---

## 3. Land, Sprache und dein Heimatgebiet

Beides wird aus deiner Systemsprache erkannt, und beides steckt **im Profil** — siehe Wie Sparkilo funktioniert → Profile.

*Einstellungen → Profile & Region → Profil bearbeiten. Die Heimat-Postleitzahl erlaubt Suchen in einem festen Gebiet, ohne je GPS herauszugeben.*

Das Land zu wechseln **löscht zwischengespeicherte Stationsdaten**, weil Preise des vorherigen Anbieters für das neue Land nicht gelten. Die nächste Suche dauert deshalb etwas länger.

---

## 4. Nutzungsmodus wählen

Das ist die folgenreichste einzelne Einstellung, denn sie bestimmt, wie viel App du bekommst.

*Einstellungen → Funktionen & Nutzungsmodus. Beginne mit **Basis**, wenn du nur günstiger tanken willst; steige auf, wenn du wissen willst, warum dein Auto säuft.*

- **Basis** — günstig tanken und laden, Favoriten, Alarme, Routen.
- **Mittel** — ergänzt den **Kraftstoff**-Tab: Tankfüllungen erfassen, echter Verbrauch und echte Kosten. Ohne Hardware.
- **Voll** — ergänzt den **Fahrten**-Tab: automatische Aufzeichnung, Fahrnoten, Kundenkarten. Ein OBD2-Adapter ist auch hier optional — Fahrten werden auch nur per GPS aufgezeichnet.

Du kannst jederzeit wechseln, und jeder Einzelschalter, den du danach umlegst, bringt dich auf **Benutzerdefiniert**. Die vollständige Liste der Schalter — und was jeder an Akku, Daten oder Privatsphäre kostet — steht in Einstellungen-Referenz → Funktionen & Nutzungsmodus.

---

## 5. Nur Deutschland: der kostenlose API-Schlüssel

16 der 17 Länder funktionieren sofort. Der offizielle **deutsche** Preisdienst vergibt einen Schlüssel pro Nutzer.

*Einstellungen → Datenquellen & Standort. Ein rotes Kreuz hier ist der Grund, warum eine deutsche Suche nichts liefert.*

1. [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) öffnen und einen Schlüssel anfordern (kurzes Formular, kostenlos).
2. Kopieren — es ist eine UUID wie `00000000-0000-0000-0000-000000000002`.
3. In das Feld **Kraftstoffpreise (Tankerkoenig)** einfügen.

Der Schlüssel liegt im hardwaregestützten Tresor (Android Keystore / iOS Keychain) und geht ausschließlich an den deutschen Preisdienst. Das Feld **E-Auto laden** darunter enthält bereits einen gemeinsamen Schlüssel — Ladedaten funktionieren ohne Einrichtung.

---

## 6. Die untere Leiste

*Der erhabene grüne **Such**-Button in der Mitte ist der einzige Auslöser für eine Suche in der gesamten App.*

- ⭐ **Favoriten** — gespeicherte Stationen und deine Preisalarme
- 🗺️ **Karte** — jede Station in der Nähe als preisfarbige Nadel
- 🔍 **Suche** *(Mitte)* — in der Nähe oder entlang einer Route
- ⛽ **Kraftstoff** — Tank, Verbrauch, Tankfüllungen *(ab Mittel)*
- 🛣️ **Fahrten** — Fahrtenbuch und Coaching *(Voll)*

Einstellungen sind **kein** Tab: das Zahnrad oben rechts auf den Hauptbildschirmen. Auf einem Tablet oder einem quer gehaltenen Telefon teilt sich die App in zwei Spalten, sodass Liste und Karte (oder Detail) gleichzeitig sichtbar sind.

---

## 7. Deine erste Suche

*Auf **Suche** tippen → der Kriterien-Dialog öffnet sich, vorbelegt aus deinem Profil. Anpassen, dann erneut **Suchen** tippen.*

Du bekommst eine Liste, günstigste zuerst (oder nach Entfernung — deine Wahl), jede Karte mit Preis, Trend, Entfernung und Aktualität. Ein Tipp öffnet die Detailseite. Die vollständige Tour steht in Tankstellen finden.

**Tipp:** Tippe unten im Dialog einmal auf **Als Standard speichern**, wenn die Kriterien passen — jede künftige Suche startet dort.

---

## 8. Zwei Einstellungen für den ersten Tag

*Einstellungen → Einheiten & Darstellung. **Verbrauchseinheit** steht auf *Automatisch* (mpg in UK, sonst L/100 km); wähle L/100 km, km/L oder mpg ausdrücklich, wenn dir das lieber ist.*

Die zweite ist **Einstellungen → Fahren & Verbrauch → Live-Verbrauchsfenster** (3 / 5 / 10 / 30 s). Sie steuert die große Live-Zahl auf dem Aufzeichnungsbildschirm: ein längeres Fenster ist beim Fahren ruhiger zu lesen, ein kürzeres reagiert schneller auf den rechten Fuß.

---

## 9. Wähle, womit die App startet

**Einstellungen → Profile & Region → Startbildschirm**: *In der Nähe* (sofortige Suche mit deinen letzten Kriterien), *Nächste Station*, *Favoriten* oder *Karte*. Nimm das, weshalb du die App tatsächlich öffnest.

---

## 10. Wo alles liegt

Die Einstellungen sind ein zweistufiger Baum mit Stichwortsuche oben — tippe „Radius", „OBD2" oder „Design" und die passende Kachel taucht auf.

*Zwölf Themen, ein Zuhause pro Parameter. Die vollständige Karte ist die Einstellungen-Referenz.*

---

**Weiter:** Wie Sparkilo funktioniert →

---

# Wie Sparkilo funktioniert

Diese Seite ist das Denkmodell. Alles andere im Handbuch ist ein Klickpfad; hier steht, *warum* die Klickpfade so aussehen, wie sie aussehen. Zehn Minuten hier sparen dir eine Stunde Suchen in den Einstellungen.

---

## Die drei Spar-Ebenen

Ein Auto kostet auf drei unabhängigen Wegen Geld, und eine Ebene zu senken bringt den anderen nichts:

1. **Preis pro Liter** — die Zapfsäule, die du wählst. Von Geografie und Markt bestimmt; die Aufgabe der App ist, dir die günstigste zu zeigen, die du realistisch erreichst.
2. **Liter pro Kilometer** — wie du fährst und was du fährst. Die Aufgabe der App ist, das ehrlich zu messen und zu zeigen, welche Gewohnheit am teuersten ist.
3. **Was du tatsächlich bezahlt hast** — die Beweiskette. Die Aufgabe der App ist, die eigenen Schätzungen an der Realität zu verankern, statt sie driften zu lassen.

Ebene 1 funktioniert in der Sekunde nach der Installation. Ebene 2 und 3 brauchen Eingaben von dir: mindestens deine Tankfüllungen, idealerweise auch aufgezeichnete Fahrten. **Die App tut nie so, als wüsste sie mehr, als man ihr gesagt hat** — deshalb siehst du Genauigkeits-Badges, Abdeckungsangaben und „vorläufig"-Hinweise statt selbstbewusster runder Zahlen.

---

## Nutzungsmodi: die App auf deine Größe bringen

Sparkilo kann ein Preisfinder aus zwei Bildschirmen sein oder ein vollwertiger Bordcomputer. Statt jedem Nutzer jeden Schalter zu zeigen, gruppiert die App Funktionen in **Nutzungsmodus-Voreinstellungen**.

*Einstellungen → Funktionen & Nutzungsmodus. Eine Voreinstellung schaltet den gesamten passenden Satz an Funktionsschaltern auf einmal; sobald du danach einen einzelnen Schalter anfasst, bist du bei **Benutzerdefiniert**.*

| Voreinstellung | Du bekommst | Untere Leiste |
|---|---|---|
| **Basis** | Günstigsten Kraftstoff und Ladepunkte in der Nähe, Favoriten, Preisalarme, Routenplanung | Favoriten · Karte · **Suche** |
| **Mittel** | Alles aus Basis + manuelles Tankbuch, echter Verbrauch und Kosten | + Kraftstoff |
| **Voll** | Alles aus Mittel + automatische OBD2-Fahrtaufzeichnung, Fahrnoten, Kundenkarten | + Fahrten |
| **Benutzerdefiniert** | Deine eigene Mischung — sobald du irgendeinen Einzelschalter umlegst | je nachdem |

### Wie es tatsächlich funktioniert

Eine Voreinstellung ist kein Modus, in dem die App läuft — sie ist ein **benannter Satz von Funktions-Flags**. Jedes Flag blendet eine Funktion unabhängig ein oder aus, und manche Flags haben Voraussetzungen: *Baseline-Sync* bleibt gesperrt, bis *TankSync* an ist, *Sprachansagen*, bis *Sprachausgabe* an ist, *Automatische Aufzeichnung*, bis ein Adapter gekoppelt ist. Die Karte erklärt, warum ein Schalter gesperrt ist, statt deinen Tipp stillschweigend zu ignorieren.

### Was das in der Praxis heißt

- **Eine Funktion auszuschalten entfernt sie aus der App, nicht nur aus der Ansicht** — auch ihre Hintergrundarbeit endet. *Preisalarme* aus stoppt die periodische Hintergrundprüfung; *GPS-Fahrtspur* aus stoppt das Speichern von Routenpunkten.
- **Voreinstellungen zerstören deine eigene Mischung.** Ein Tipp auf *Mittel* überschreibt jeden Einzelschalter. Wer von Hand feinjustiert hat, bleibt auf Benutzerdefiniert.
- **Die untere Leiste ändert ihre Form.** Wenn der Kraftstoff- oder Fahrten-Tab verschwunden ist, hast du (oder eine Voreinstellung) *Verbrauchs-Tab* bzw. *OBD2-Fahrtaufzeichnung* ausgeschaltet — kein Fehler.

---

## Profile: ein Kontext, ein Satz Voreinstellungen

Ein **Profil** bündelt alles, was davon abhängt, *wo und wie du gerade fährst*: Land, Sprache, bevorzugter Kraftstoff, Standard-Suchradius, Heimat-Postleitzahl, Routenparameter, Startbildschirm, Sichtbarkeit von Stationsnotizen, die Radar-Einstellungen und das Standardfahrzeug.

*Einstellungen → Profile & Region → bearbeiten. Der bevorzugte Kraftstoff wird **aus deinem Standardfahrzeug abgeleitet** — entferne das Fahrzeug, wenn du den Kraftstoff selbst wählen willst.*

*Land und Sprache stecken im Profil. Deshalb kann ein Profilwechsel mit einem Tipp Datenquelle und Oberflächensprache umstellen.*

### Wie es tatsächlich funktioniert

Das im aktiven Profil gespeicherte Land entscheidet, **welchen nationalen Open-Data-Anbieter die App aufruft**. Es zu ändern löscht zwischengespeicherte Stationsdaten, denn Preise des alten Anbieters sind für das neue Land bedeutungslos. Der bevorzugte Kraftstoff entscheidet, welcher Preis auf jeder Karte die Schlagzeile ist, worauf ein Preisalarm standardmäßig läuft und wofür eine Routensuche optimiert.

### Was das in der Praxis heißt

- **Ein Profil pro Land, in dem du fährst.** „Zuhause — Deutschland, E10, 10 km" und „Urlaub — Spanien, E5, Kartenstart" sind zwei Profile, nicht zwei Einstellungssitzungen.
- **Grenzüberschreitende Routensuchen nutzen den Kraftstoff des jeweiligen Länderprofils.** Ohne Profil für das zweite Land hat dieser Abschnitt keine Kraftstoffsorte zum Bepreisen und zeigt `--`.
- **Automatischer Profilwechsel** (Einstellungen → Datenquellen & Standort) kann das Profil für dich umschalten, wenn GPS eine Grenzüberquerung meldet.
- Einstellungs-Kacheln tragen ein **Gültigkeits-Label** — *dieses Profil*, *alle Profile* oder *dieses Fahrzeug* — damit du immer weißt, wie weit eine Änderung reicht.

---

## Eine Datenquelle pro Land

Sparkilo aggregiert nicht. Jedes Land wird über seine eigene offizielle Quelle abgefragt, und die Ergebnisliste nennt sie.

*Die Zeile unter der App-Leiste ist keine Deko — sie sagt dir, welche Behörde diese Preise veröffentlicht hat, und verlinkt sie.*

### Wie es tatsächlich funktioniert

| Land | Quelle | Takt |
|---|---|---|
| Deutschland | Tankerkönig (eigener kostenloser Schlüssel nötig) | ~5 Minuten |
| Frankreich | Prix-Carburants (gouv.fr) | laufend, je Station |
| Spanien | Geoportal Gasolineras (MITECO) | tägliche Sammeldatei, lokal gefiltert |
| Italien | MIMIT-Sammeldatei | tägliche Sammeldatei, lokal gefiltert |
| …und 13 weitere | das jeweilige Open-Data-Portal | unterschiedlich |

### Was das in der Praxis heißt

- **Kraftstoffsorten unterscheiden sich über die Grenze hinweg.** Spanien verkauft E5 und selten E10; Frankreich führt SP95-E10 prominent; Deutschland veröffentlicht E5, E10 und Diesel. Derselbe physische Kraftstoff trägt in drei Ländern drei Namen.
- **Die Aktualität unterscheidet sich.** Ein deutscher Preis kann fünf Minuten alt sein, ein spanischer die gestrige Sammelveröffentlichung. Das Aktualitäts-Badge auf jeder Karte sagt dir, was du vor dir hast — vertraue ihm mehr als der Zahl.
- **Die Dichte unterscheidet sich.** Ein dünner nationaler Datensatz liefert im selben Radius weniger Stationen. Das sind die Daten des Landes, keine gescheiterte Suche.
- **Ein `--` statt eines Preises heißt „dieser Anbieter meldet diese Sorte für diese Station nicht"** — nicht „die Station verkauft sie nicht".

---

## Wo deine Daten liegen

Sparkilo ist **local-first**. Alles, was die App weiß, liegt in verschlüsselten Datenbanken auf deinem Telefon; der Schlüssel steckt im Android Keystore bzw. iOS Keychain.

*Einstellungen → Datenschutz & Daten → Daten auf diesem Gerät zeigt jede Kategorie mit einem echten Zähler — nichts an deinen Daten bleibt dir verborgen.*

Nur vier Dinge verlassen jemals das Telefon, drei davon freiwillig:

| Verlässt das Telefon | Wann | Optional? |
|---|---|---|
| Suchkoordinaten oder ein Regionscode | Bei jeder Suche, an die Preisquelle des Landes | Für Live-Preise nötig |
| Kartenausschnitt + deine IP | Kartenkacheln über den EU-Proxy des Entwicklers | Ja — Proxy aus, dann direkt von OpenStreetMap |
| Absturzspuren | Nur mit eingeschalteter *Fehlerberichterstattung* | Ja — standardmäßig aus |
| Deine synchronisierten Zeilen | Nur mit eingeschaltetem *TankSync* | Ja — standardmäßig aus |

**Deine Identität ist nie Teil einer Preisabfrage.** Die vollständige Aufstellung: Datenschutz, Daten & Sync.

---

## Wie aus einem Liter eine Zahl wird

Diesen Teil machen die meisten Tank-Apps still und leise falsch, deshalb lohnt es sich, ihn zu verstehen.

### Die Zapfsäule ist die Wahrheit

Die einzige physikalisch sichere Zahl, die die App je bekommt, ist **getankte Liter ÷ gefahrene Kilometer zwischen zwei vollen Tanks**. Alles andere — GPS-Schätzungen, aus dem Luftmassenmesser abgeleiteter Durchfluss, Speed-Density-Modellierung — ist ein Modell, das driften kann.

Deshalb behandelt die App jedes **Voll-zu-voll-Tankfenster** als Kalibrierungsereignis:

1. Du erfasst eine Tankfüllung und hakst **Voller Tank** an. Damit schließt das vorherige Fenster.
2. Die App berechnet die *Zapfsäulen-Wahrheit* des Fensters: getankte Liter ÷ Tacho-Kilometer × 100.
3. Sie vergleicht das mit dem, was ihr eigener Schätzer über die tatsächlich aufgezeichneten Kilometer geliefert hat — mit allen früher angewandten Korrekturen herausgerechnet.
4. Das Verhältnis der beiden wird zum **Pump-Gain** des Fahrzeugs, verschmolzen mit früheren Fenstern und auf einen sinnvollen Bereich begrenzt.
5. Dieser Gain multipliziert dann **jeden geschätzten Kraftstoffraten-Zweig** — Speed-Density und MAF — auf der nächsten Fahrt.

Kraftstoff, den dein Auto über OBD2 *selbst meldet* (PID 5E / 9D), ist gemessen und nicht modelliert — der Gain rührt ihn nie an.

*Der Tank-Bericht macht die Kalibrierung sichtbar: dieser Tank lief laut Zapfsäule auf 6,4 L/100 km, Aufzeichnungen deckten 81 % davon ab, und der Schätzer lag 39 % zu hoch, bis dieses Fenster ihn korrigiert hat.*

### Warum die Abdeckung nicht verzerrt

Die beiden Zahlen **pro Kilometer** zu vergleichen bedeutet, dass die nicht aufgezeichneten Kilometer schlicht kein Gewicht tragen. Ein Tank, von dem du nur ein Fünftel aufgezeichnet hast, liefert trotzdem ein unverzerrtes Verhältnis — es zählt nur weniger in der Verschmelzung. Deshalb zeigt die App die Abdeckung, statt sie zu verstecken: sie sagt dir, wie sehr du *diesem* Fenster trauen kannst, nicht ob die Kalibrierung gültig ist.

### Die Genauigkeitsleiter

| Badge | Was dahintersteckt | Typisches Band |
|---|---|---|
| **Niedrig** | Nur GPS — noch keine Tankfüllung hat etwas verankert | ±15 % und schlechter |
| **Mittel** | Tankfüllungen verankern das Modell, aber noch keine OBD2-Fahrt hat es gefüttert | ±7–15 % |
| **Hoch** | Tankfüllungen *und* OBD2-Fahrten | ±3–7 % |

### Was das in der Praxis heißt

- **Hake „Voller Tank" immer an, wenn du randvoll tankst.** Eine Teilbetankung wird trotzdem erfasst und zählt für die Kosten, kann aber kein Kalibrierungsfenster schließen. Teilbetankungen, die auf einen vollen Tank warten, erscheinen als Banner in der Statistik.
- **Die Tacho-Genauigkeit zählt mehr als die Liter-Genauigkeit.** Ein 2-%-Tippfehler beim Tacho vergiftet das Fenster; 0,2 L Rundung nicht.
- **Das erste Fenster wird für bare Münze genommen, spätere glätten.** Erwarte einen einmaligen Sprung, dann Ruhe.
- **Wenn du ohne Aufzeichnung fährst, gehen die Zahlen nicht auf** — und die App sagt das, statt zu tricksen. Siehe den Abgleich in Tankbuch & Verbrauch.

---

## Wie die App dein Fahren lernt

Getrennt vom Pump-Gain trägt ein Fahrzeug eine **Fahrsituations-Baseline**: was dein Auto im Leerlauf, im Stop-and-go, in der Stadt, auf der Autobahn, beim Verzögern, am Berg oder beladen, aus dem Kalten, unter Dauerlast und im Segeln verbraucht.

*Jede Situation füllt sich unabhängig. Die Warnung ist ehrlich: zwei Situationen haben noch null Stichproben, das Profil ist unvollständig.*

### Wie es tatsächlich funktioniert

Jede OBD2-Stichprobe wird einer Fahrsituation zugeordnet und ihrem Topf hinzugefügt. Es gibt zwei Zuordnungsmodi:

- **Regelbasiert** — jede Stichprobe gehört zu genau einer Situation. Klar, aber ein Auto bei 60 km/h springt von Stichprobe zu Stichprobe zwischen „Stadt" und „Autobahn".
- **Fuzzy** *(Standard)* — jede Stichprobe wird nach Passgenauigkeit auf alle Situationen verteilt. Genau dort glatt, wo regelbasiert springt.

### Was das in der Praxis heißt

- **Eine Baseline gehört zum Fahrzeug, nicht zum Telefon.** Autowechsel heißt neue Baseline; *Baseline-Sync* (braucht TankSync) trägt sie auf ein zweites Gerät.
- **Fehlende Situationen sind ehrliche Lücken, keine Fehler.** Wer nie einen Anhänger zieht, hat bei „Dauerlast / Anhänger" für immer 0 — und die App sagt weiter, das Profil sei unvollständig. Das ist in Ordnung.
- **Die Baseline zurückzusetzen wirft dich auf Kaltstart-Standards zurück**, bis neue Fahrten sie füllen — mach das nach einem mechanischen Eingriff, nicht weil eine Zahl seltsam aussah.

---

## Die eine Einstellungs-Regel, die man sich merken sollte

Die Einstellungen sind ein **zweistufiger Baum**: eine Wurzel aus Themenkacheln, ein Bildschirm pro Thema, und ein Suchfeld, das die Kacheln nach Stichwort filtert.

*Jeder Parameter hat genau ein Zuhause. Wer das Thema kennt, muss nie scrollen.*

Vollständige Karte aller Bildschirme: Einstellungen-Referenz.

---

**Weiter:** Tankstellen finden →

---

# Tankstellen finden

Ebene 1 der drei Spar-Ebenen: weniger pro Liter zahlen.

---

## Ein Button, ein Denkmodell

Die untere Leiste hat genau einen Suchauslöser — den erhabenen grünen Button in der Mitte. Er ist kontextbewusst statt modal:

- **Aus jedem Tab** → öffnet den Kriterien-Dialog.
- **Aus Ergebnisliste oder Karte** → öffnet den Dialog mit deinen letzten Werten.
- **Im Dialog** → führt die Suche aus.

Die Beschriftung sagt, was passieren wird, und im Routenmodus bleibt der Button deaktiviert, bis es ein Ziel gibt. Getrennte Buttons für „in der Nähe" und „entlang der Route" gibt es bewusst nicht.

---

## Kriterien setzen

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

### Der Suchknopf

Der erhöhte Knopf in der Mitte der unteren Leiste ist der einzige
Suchauslöser. Aus jedem Tab öffnet er dieses Blatt; aus den Ergebnissen
oder der Karte öffnet er es mit dem zuletzt Benutzten; im Blatt selbst
startet er die Suche.

### In der Nähe oder entlang einer Route

Zwei verschiedene Fragen. **In der Nähe** sucht um deine Position oder
eine Adresse. **Entlang der Route** braucht ein Ziel und misst die
Entfernung entlang des Korridors statt Luftlinie — eine Tankstelle 2 km
entfernt in einer Seitenstraße rangiert also hinter einer, die auf dem
Weg liegt.

### Kraftstoffsorte

Für welche Sorte die Preise gelten. Die Chips richten sich danach, was
der Anbieter deines Landes tatsächlich veröffentlicht — eine fehlende
Sorte fehlt in den Daten, nicht in der App.

### Umkreis

Wie weit gesucht wird. Ein großer Umkreis in einem dichten Land liefert
sehr viele Tankstellen und eine langsamere Suche, und die zusätzlichen
liegen meist weiter weg, als die Ersparnis wert ist.

### Nur jetzt geöffnet

Blendet geschlossene Tankstellen aus. Das hängt davon ab, ob der Anbieter
Öffnungszeiten veröffentlicht, und manche tun es nicht — fehlen sie, wird
die Tankstelle behalten statt geraten.

### Ausstattung

Shop, Waschanlage, Luft, WC. Diese filtern über **gemeldete** Daten: eine
Tankstelle, die nichts über ihre Ausstattung veröffentlicht, verschwindet
aus einer gefilterten Liste, auch wenn sie alles hat.

### Autobahntankstellen

Autobahntankstellen sind meist der teuerste Kraftstoff im Land — sie
auszuschließen ist der eine Filter, der am häufigsten ändert, was du
zahlst. Behalte sie, wenn du die Autobahn nicht verlassen kannst.

### Als meine Vorgaben speichern

Schreibt diese Kriterien in dein Profil, sodass jede spätere Suche hier
beginnt statt bei den Vorgaben der App. Diese Einstellung macht aus dem
Blatt eine Bestätigung mit einem Tipp statt eines Formulars.

### Wie es tatsächlich funktioniert

Eine Umkreissuche sendet **deine Koordinaten (oder einen Regionscode) und einen Radius** an den offiziellen Preisanbieter deines Landes — nie deine Identität. Länder mit täglicher Sammeldatei (Spanien, Italien) werden auf dem Gerät gefiltert; solche Suchen brauchen nach dem Zwischenspeichern gar keinen Netzaufruf mehr.

---

## Eine Ergebniskarte lesen

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

Aktualität ist eine Eigenschaft des **Landesanbieters**, nicht der App. Ein spanischer Preis von vor 14 Stunden ist kein Fehler: dieses Land veröffentlicht einmal täglich. Siehe Wie Sparkilo funktioniert → Eine Datenquelle pro Land.

### Wischgesten

- **Nach rechts wischen** — in deiner Navi-App öffnen (Google Maps, Waze, OsmAnd, Organic Maps).
- **Nach links wischen** — Station aus allen künftigen Ergebnissen ausblenden. Rückgängig über **Datenschutz & Daten → Daten auf diesem Gerät → Ausgeblendete Stationen**.

---

## Stationsdetails

*Karte antippen. Die Kopfzeile fällt von Marke über Name auf Straße zurück — ein Intermarché ohne Markenfeld heißt trotzdem „Intermarché".*

Der obere Block ist die **vollständige Preistabelle** — jede Sorte, die der Anbieter für diese Station meldet, mit `--` wo er nichts meldet. Der schnellste Weg zu sehen, ob die günstige E85-Station auch beim Diesel mithält.

**Tankfüllung erfassen** übernimmt Station, Sorte und Preis direkt ins Formular — der größte Zeitgewinn der App, wenn du deine Tankvorgänge erfasst.

*Weiter unten: Dienste, akzeptierte Zahlungsmittel, deine eigene private Sternebewertung und der lokale 30-Tage-Preisverlauf.*

Die Aktionen in der Kopfleiste sind von links nach rechts: **Preisalarm setzen**, **Zahlungs-QR scannen**, **falschen Preis melden** und **favorisieren**.

---

## Die Karte

*Die Farbe ist relativ zum sichtbaren Ausschnitt: Grün ist die günstigste sichtbare Station, Rot die teuerste. Die Fußzeile nennt Anzahl, Radius und Alter der Daten.*

- **Cluster-Marker** fassen Nadeln beim Herauszoomen zusammen; antippen zoomt hinein.
- **Lang drücken** setzt eine eigene Markierung und sucht von dort.
- Der **E-Auto-Schalter** oben rechts wechselt zu Ladepunkten — siehe E-Auto laden.
- **Teilen** schickt den aktuellen Ausschnitt an jemanden.

Die Kacheln kommen von OpenStreetMap. Standardmäßig laufen sie über den EU-Proxy des Entwicklers, damit OpenStreetMap deine IP nie sieht; du kannst den Proxy unter Einstellungen → Datenschutz & Daten abschalten und direkt laden. Der F-Droid-Build nutzt den Proxy nie.

---

## Das Tankstellen-Radar

Ein Live-Scan um deine aktuelle Position, gebaut für die Nutzung **während der Fahrt**.

*Nach jeder Umkreissuche erscheint unten rechts eine schwebende Pille. Ein Tipp startet das Radar.*

### Wie es tatsächlich funktioniert

Das Radar frischt deine GPS-Position auf, holt Stations**standorte** aus einem breiten 60-km-Korridor und mischt eine direkte Abfrage im Radius dazu — es kann also nie weniger zeigen als eine normale Suche. Tankstellen bewegen sich nicht, deshalb werden diese Standorte bis zu einer Stunde zwischengespeichert und wiederverwendet; nur der **Preis** einer Station, auf die du zufährst, wird genau dann geholt. Das macht ein dauerhaft laufendes Radar günstig in Daten und Akku.

*In Betrieb: nach Entfernung sortiert, mit einem Balken, der sich beim Näherkommen füllt.*

### Während einer Fahrtaufzeichnung

Das Radar heftet eine **Nächste Station**-Karte an den Kopf des Aufzeichnungsbildschirms — Name, Preis für deine Sorte, Entfernung und ein Balken, der bei Ankunft 100 % erreicht. Nach links/rechts wischen blättert durch die Kandidaten. Kommst du in den konfigurierten Annäherungsradius, wechselt die Bild-in-Bild-Kachel auf eine große Preisanzeige; siehe Fahrten & Eco-Coaching → Annäherungs-Overlay.

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

</details>

---

**Siehe auch:** Routenplanung · Favoriten & Alarme · Preisverlauf
**Weiter:** Routenplanung →

---

# Routenplanung

Nicht „am günstigsten in der Nähe", sondern **am günstigsten auf dem Weg** — der Unterschied ist auf jeder längeren Fahrt mehrere Euro wert.

---

## Eine Routensuche starten

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

**Du brauchst ein Profil pro Land** mit der richtigen bevorzugten Sorte, sonst hat der zweite Abschnitt nichts zu bepreisen und zeigt `--`. Siehe Wie Sparkilo funktioniert → Profile.

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

**Siehe auch:** Tankstellen finden · Einstellungen-Referenz
**Weiter:** Favoriten & Alarme →

---

# E-Auto laden

Sparkilo ist nicht nur für Verbrenner. Ladepunkte kommen von [OpenChargeMap](https://openchargemap.org), dem größten offenen Community-Verzeichnis weltweit.

---

## Einschalten

Zwei unabhängige Schalter, beide unter **Einstellungen → Funktionen & Nutzungsmodus → Suche & Karte**:

- **E-Auto laden** — die Funktion selbst (Suche, Detailseiten, Favoriten).
- **Ladepunkte anzeigen** — ob Ladepunkte in Ergebnissen und auf der Karte auftauchen.

*Du kannst Tankstellen, Ladepunkte oder beides zeigen. Wer rein elektrisch fährt, schaltet **Tankstellen anzeigen** meist aus.*

Lege dann unter **Einstellungen → Fahrzeuge & OBD2 → Meine Fahrzeuge → Hinzufügen** ein Fahrzeug mit dem Antrieb **Elektrisch** an. Ein E-Fahrzeug trägt Batteriekapazität (kWh), maximale AC- und DC-Ladeleistung (kW) und die unterstützten Stecker (Typ 2, CCS, CHAdeMO, Tesla, Schuko, Typ 1, Schutzkontakt). Suchen filtern dann auf Ladepunkte, die dein Auto wirklich nutzen kann.

---

## Wie die Daten funktionieren

*Einstellungen → Datenquellen & Standort. Das Feld **E-Auto laden (OpenChargeMap)** enthält bereits einen gemeinsamen Schlüssel, Laden funktioniert also ohne Einrichtung.*

Die App fragt die OpenChargeMap-POI-Schnittstelle live für den Bereich ab, den du ansiehst, und speichert das Ergebnis zwischen, damit es offline erhalten bleibt.

### Warum ein eigener Schlüssel sinnvoll sein kann

Der eingebaute Schlüssel wird von allen Sparkilo-Nutzern geteilt und ist deshalb als Pool limitiert. Ein eigener Schlüssel gibt dir dein eigenes Kontingent und lässt OpenChargeMap echte Nutzung sehen. Er ist kostenlos:

1. Bei [openchargemap.org](https://openchargemap.org) registrieren.
2. **My Profile → My Apps** öffnen.
3. **Register an Application**, kurz beschreiben — der API-Schlüssel (eine UUID) wird sofort ausgegeben.

In das E-Auto-Feld einfügen. Er liegt im selben hardwaregestützten Tresor wie der deutsche Preisschlüssel, verlässt das Gerät nie und geht nur an OpenChargeMap. Feld leeren = zurück zum gemeinsamen Schlüssel.

### Der Rückfall, der wie ein Fehler aussieht

Ist OpenChargeMap gar nicht erreichbar, zeichnet die App einen kleinen **eingebauten Demo-Datensatz** statt einer leeren Karte. Wenn du in jeder Stadt dieselbe Handvoll generischer Ladepunkte siehst, sagt dir dieser Rückfall, dass die Live-Abfrage gescheitert ist — prüfe Verbindung oder Schlüssel und traue diesen Nadeln nicht.

### Etwas zurückgeben

OpenChargeMap wird von der Community gepflegt. Ein fehlender oder falscher Ladepunkt wird auf [openchargemap.org](https://openchargemap.org) korrigiert, nicht in dieser App — und die Korrektur erreicht dann bei der nächsten Abfrage jede OCM-basierte App, auch diese.

---

## Suchen

*Der E-Auto-Schalter in der Kartenleiste wechselt die Nadeln von Kraftstoff auf Laden. Die Nadelfarbe folgt der Leistung: hellblau AC, dunkelblau DC.*

Im Kriterien-Dialog den Typ **E-Auto** wählen und eine Umkreissuche starten. Verfügbare Filter: Steckertypen, minimale kW und nur derzeit freie Punkte, wo der Betreiber Live-Status meldet.

---

## Die Detailseite eines Ladepunkts

- **Stecker** — Typ, Anzahl und maximale Leistung je Anschluss
- **Tarif** — pro kWh, sofern der Betreiber ihn veröffentlicht (viele tun das nicht)
- **Netzwerk** — Ionity, Fastned, Tesla …
- **Verfügbarkeit** — in Echtzeit, wo gemeldet
- **Ausstattung** — Essen, Toiletten, Einkaufen (zählt mehr, wenn man 30 Minuten steht)
- **Öffnungszeiten** — 24/7 oder betreiberabhängig
- **Bewertungen** — von OpenChargeMap-Beitragenden

---

## Favoriten und Erfassung

Ladepunkte lassen sich wie Tankstellen favorisieren; im Querformat und auf Tablets liegen Favoriten und Alarme nebeneinander. Die Favoritenkarte zeigt **kW je Anschluss**, **wie viele gerade frei sind** und die **Steckertypen**.

Preisalarme bringen beim Laden wenig, weil die meisten Betreiber pauschale kWh-Tarife haben. Ladevorgänge werden wie Tankfüllungen erfasst: **Kraftstoff-Tab → Hinzufügen**, mit kWh statt Litern — sie fließen in dieselbe Kosten-pro-Kilometer-Statistik wie Verbrenner-Tankfüllungen.

---

## Über Grenzen

Beim Laden gibt es bewusst **keinen Länderfilter**. Fährst du von Deutschland nach Frankreich, siehst du beide Infrastrukturen auf derselben Karte. Kraftstoffpreise sind nationale Datensätze; Laden ist ein einziger weltweiter Datensatz, deshalb gilt die Regel „ein Profil pro Land" hier nicht.

---

**Siehe auch:** Tankstellen finden · Tankbuch & Verbrauch
**Weiter:** Fahrzeuge & OBD2 →

---

# Favoriten & Preisalarme

Der ⭐-Tab ist deine Auswahlliste plus die Roboter, die sie für dich beobachten.

---

## Favoriten

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

*Oben drei Zähler — aktive Regeln, Treffer heute, Treffer diese Woche — darunter die beiden Alarmarten. Die Fußzeile stempelt die letzte Hintergrundprüfung.*

Es gibt zwei Arten, und sie beantworten verschiedene Fragen.

### Stationsalarm — „sag mir, wenn *diese* Säule günstig wird"

Wird auf der Detailseite einer Station erstellt (Glockensymbol). Sorte wählen, Schwelle setzen, speichern. Ideal für die Station, die du ohnehin nutzt.

### Umkreisalarm — „sag mir, wenn es *irgendwo hier* günstig wird"

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
- **Ein wichtiger Nebeneffekt:** dieselbe Hintergrundprüfung schreibt einen Preis in deinen lokalen Verlauf. Eine Station mit Alarm baut ihren 30-Tage-Verlauf deshalb in Stunden statt Wochen auf — und genau das lässt den Banner *beste Tankzeit* schnell erscheinen. Siehe Preisverlauf.
- **Sind Benachrichtigungen auf Systemebene aus**, kann der App-Schalter nichts auslösen.

---

## Statistik

Die Zähler oben zeigen, wie viele Regeln aktiv sind und wie oft sie heute und diese Woche ausgelöst haben — ein schneller Test, ob die Hintergrundaufgabe wirklich läuft. Nur Nullen bei mehreren aktiven Alarmen und ein alter „Letzte Prüfung"-Stempel sind das klassische Zeichen für einen Akkusparer, der die Aufgabe killt.

---

## Alarme beenden

Einen Alarm ausschalten pausiert ihn, ohne die Regel zu verlieren; nach links wischen löscht ihn. Eine Station aus den Favoriten zu entfernen löscht ihre Alarme **nicht**.

---

**Siehe auch:** Preisverlauf & Prognosen · Einstellungen-Referenz → Preise & Alarme
**Weiter:** E-Auto laden →

---

# Preisverlauf & Prognosen

Die App baut ein **privates, lokales** Bild davon, wie sich Preise um dich herum bewegen, und macht daraus eine ehrliche Empfehlung.

---

## Was erfasst wird, und wo

Immer wenn ein Stationspreis durch die App läuft — eine Suche, ein Aktualisieren der Favoriten oder eine Hintergrund-Alarmprüfung — schreibt die App **auf deinem Telefon** einen Datensatz: Station, Sorte, Preis, Zeitstempel. Nichts wird hochgeladen, und niemandes Daten werden heruntergeladen.

- **Entdoppelt auf einen Datensatz pro Station und Stunde.** Fünf Suchen in zehn Minuten ergeben einen Eintrag.
- **30 Tage Aufbewahrung.** Ältere Datensätze werden automatisch gelöscht.
- **Aktiviert durch** *Funktionen & Nutzungsmodus → Preise & Alarme → Preisverlauf*. Aus heißt: gar keine Datensätze.

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

**Siehe auch:** Favoriten & Alarme · Tankstellen finden → Aktualität
**Weiter:** Einstellungen-Referenz →

---

# Tankbuch & Verbrauch

Ebene 2 und 3 der drei Spar-Ebenen: wie viel du verbrauchst und was es wirklich gekostet hat. Der ⛽ **Kraftstoff**-Tab erscheint in den Nutzungsmodi **Mittel** und **Voll**.

---

## Der Kraftstoff-Tab auf einen Blick

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

Nach einer Korrektur wie oben werden die Fahrtschätzungen auf der nächsten Fahrt spürbar sinken und sich dann einpendeln. Der ganze Mechanismus: Wie Sparkilo funktioniert → Wie aus einem Liter eine Zahl wird.

Die Karte kann auch zeigen, *was sich geändert hat* — Anteil hoher Drehzahlen, harte Ereignisse pro 100 km, Kaltstarts, Leerlaufanteil, jeweils gegen den vorherigen Tank — mit dem ausdrücklichen Vorbehalt, dass Aufzeichnungen spontan sind und nur einen Teil des Tanks abdecken.

---

## Verbrauchsstatistik

Auf die Statistikkarte tippen, oder **Kraftstoff → Verbrauchsstatistik**.

*Die Filterchips oben schränken alles darunter auf eine Sorte ein — bei einem Flex-Fuel-Auto unverzichtbar, weil ein gemeinsamer Durchschnitt dort bedeutungslos ist.*

Die Monatstabelle zeigt Liter, Ausgaben, Durchschnittspreis pro Liter, Durchschnittsverbrauch, Kosten pro km und Anzahl Tankvorgänge, jeweils mit Differenz. Rote Pfeile sind kein Urteil — steigende *Ausgaben* nach steigendem *Literpreis* sind der Markt, nicht dein rechter Fuß. Die Zahl fürs Fahren ist **L/100 km**.

### Kosten pro Kilometer je Kraftstoff

*Die eigentliche Frage des Flex-Fuel-Fahrers, beantwortet: nicht welcher Kraftstoff pro Liter billiger ist, sondern welcher pro Kilometer.*

Jede Sorte bekommt eine Zeile, ausschließlich aus **geschlossenen Tankfenstern**: gemessene L/100 km, tatsächlich gezahlter Literpreis, Kosten pro 100 km, Ausgaben gesamt, gemessene Strecke, verbrauchte Liter, CO₂ pro 100 km und die Zahl voller Tanks dahinter. Eine Zeile aus einem einzigen Tank ist als **Vorläufig** gekennzeichnet.

*Die Urteilskarte nennt den Sieger, den Abstand pro 1000 km und — am nützlichsten — den **Break-even-Preis**.*

Die Break-even-Zeile („E5 wird unter 0,75 €/L besser als E85") wird aus **deinem eigenen gemessenen Verbrauch beider Sorten** berechnet, bewegt sich also mit deinem Fahren. Das ist eine Entscheidungsregel, die du an der Säule anwenden kannst; ein Pauschalverhältnis aus dem Internet ist es nicht.

CO₂-Werte sind Well-to-Wheel-Schätzungen (EU JEC WTW v5) auf deinen gemessenen Verbrauch angewandt — Bewusstsein, keine prüffähige Bilanz. Mischungen bleiben beim CO₂ außen vor, weil der Emissionsfaktor vom Mischverhältnis abhängt, das die Zeile nicht erfasst.

*Die Trendcharts stapeln nach Sorte, ein Wechsel erscheint also als eine Farbe, die eine andere ablöst, statt als rätselhafter Sprung.*

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

</details>

---

**Siehe auch:** Fahrzeuge & OBD2 · Fahrten & Eco-Coaching
**Weiter:** Fahrten & Eco-Coaching →

---

# Kraftstoff, Fahrten & Fahrverhalten *(verschoben)*

Diese Seite wurde in drei aufgeteilt, damit jedes Thema eigene Anker für eine spätere In-App-Hilfe hat:

- **Fahrzeuge & OBD2** — dein Auto, Tankinhalt, Flex-Fuel, Adapter koppeln, Baseline-Kalibrierung, automatische Aufzeichnung.
- **Tankbuch & Verbrauch** — Tankfüllungen, Füllstand, Tank-Bericht, Genauigkeit, Kosten pro Kilometer je Kraftstoff.
- **Fahrten & Eco-Coaching** — Aufzeichnung, Fahrtdetails, Fahrnote, CO₂-Dashboard.

Beginne mit **Wie Sparkilo funktioniert**, wenn du die Konzepte hinter allen dreien willst.

---

# Fahrzeuge & OBD2

Alles, was die App über *dein Auto* weiß. Diese Seite entscheidet, ob die Verbrauchszahlen auf allen anderen Seiten vertrauenswürdig sind.

---

## Warum die App überhaupt ein Fahrzeug braucht

Ohne Fahrzeug ist Sparkilo ein Preisfinder. Mit einem kann es Liter und Kilometer in *deine* Kosten pro Kilometer umrechnen, Reichweite schätzen und — mit Adapter — den momentanen Kraftstofffluss modellieren.

*Einstellungen → Fahrzeuge & OBD2. Beachte das Gültigkeits-Label auf der Adapter-Kachel: Adapter werden **pro Fahrzeug** gekoppelt, nicht pro Telefon.*

*Der grüne Haken markiert das aktive Fahrzeug — dem werden neue Tankfüllungen und Fahrten zugeordnet.*

---

## Identität und Antrieb

*Nenne es, wie du es wiedererkennst. Die FIN ist optional.*

### Die FIN und was sie bringt

Die FIN (VIN) einzugeben oder auszulesen erlaubt der App, Hubraum, Zylinderzahl, Leistung und Kraftstoffart nachzuschlagen — die Eingaben des Verbrauchsmodells. **FIN aus dem Auto lesen** holt sie in einer Sekunde über OBD2.

Die Online-FIN-Auflösung ist eine **eigene Einwilligung** — die App fragt, bevor sie etwas sendet, und die teilweise Offline-Auflösung funktioniert auch bei Ablehnung. Eine FIN ist ein personenbezogenes Datum; behandle sie so.

### Antrieb

**Verbrenner / Hybrid / Elektrisch** ändert, welche Felder darunter existieren. Verbrenner fragt Tankinhalt, Leistung und bevorzugten Kraftstoff; elektrisch fragt Batteriekapazität und Stecker.

---

## Tankinhalt, Leistung und Flex-Fuel

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

*210 von 270 Stichproben. Zwei Fahrsituationen sind noch leer, und die App sagt es, statt Vollständigkeit vorzutäuschen.*

Jede OBD2-Stichprobe wird einer Fahrsituation zugeordnet: **Leerlauf, Stop & go, Stadt, Autobahn, Verzögern, Steigung / beladen, Kaltstart, Dauerlast / Anhänger, Segeln**. Die Mittelwerte je Situation bilden die Baseline des Fahrzeugs — das Modell, das einen plausiblen L/100-km-Wert liefert, wenn der Adapter fehlt oder eine PID aufhört zu antworten.

*Situationen mit null Stichproben sind die, die auf Standardwerte zurückfallen. Hier zwei: Verzögern und Anhängerbetrieb.*

### Regelbasiert vs. Fuzzy

*Fuzzy ist der Standard und für fast alle die bessere Wahl.*

- **Regelbasiert** ordnet jede Stichprobe genau einer Situation zu. Vorhersagbar, springt aber von Stichprobe zu Stichprobe zwischen „Stadt" und „Autobahn", wenn du nahe der Grenze fährst — etwa bei 60 km/h.
- **Fuzzy** verteilt jede Stichprobe nach Passgenauigkeit auf alle Situationen. Genau dort glatt, wo regelbasiert springt, dafür schwerer Stichprobe für Stichprobe nachzuvollziehen.

### Die beiden Zurücksetzen-Buttons — und was sie wirklich tun

- **Volumetrischen Wirkungsgrad zurücksetzen** verwirft das gelernte η_v und stellt den Standard 0,85 wieder her. η_v ist ein Parameter des Speed-Density-Modells, das die Luftmasse schätzt, wenn kein MAF-Wert vorliegt. Setze ihn nur nach einem mechanischen Eingriff zurück; eine seltsame Zahl ist eher ein Abdeckungsproblem. Autos, die den Kraftstofffluss direkt melden (PID 5E), nutzen ihn gar nicht.
- **Aus Fahrzeugdatenbank zurücksetzen** holt Hubraum, Leistung und Standardwerte erneut aus dem eingebauten Katalog und verwirft deine manuellen Werte.
- **Fahrsituations-Baseline zurücksetzen** (in der Baseline-Karte) löscht jede gelernte Stichprobe und wirft dich auf Kaltstart-Standards zurück, bis neue Fahrten das Profil füllen.

Keiner davon rührt den **Pump-Gain** an, der aus Voll-zu-voll-Tankfenstern gelernt wird und außerhalb des OBD2-Modells lebt — siehe Wie Sparkilo funktioniert → Wie aus einem Liter eine Zahl wird.

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

</details>

---

**Siehe auch:** Fahrten & Eco-Coaching · Fehlersuche → OBD2
**Weiter:** Tankbuch & Verbrauch →

---

# Fahrten & Eco-Coaching

Der 🛣️ **Fahrten**-Tab ist ein automatisches Fahrtenbuch plus Fahrtrainer. Er erscheint im Nutzungsmodus **Voll**.

---

## Der Fahrten-Tab

*Monatsvergleich, der jüngste Tank-Bericht, dann die Fahrtliste. Der schwebende Button startet eine Aufzeichnung.*

Der Monatsvergleich braucht mindestens drei Fahrten pro Monat, bevor er vergleicht — mit weniger ist der Mittelwert Rauschen statt Trend.

*Das Kartensymbol in der Kopfleiste zeichnet jede aufgezeichnete Fahrt auf eine Karte — ein Jahr Fahren auf einen Blick, und ein einfacher Weg, die Strecken zu finden, deren Optimierung sich lohnt.*

---

## Zwei Wege aufzuzeichnen

### Nur mit dem Telefon

Keine Hardware. Die App erfasst Route, Strecke, Dauer und Geschwindigkeit aus GPS und **modelliert** den Verbrauch aus deiner Fahrzeugkalibrierung und deinem Fahren. Überall mit `~` und dem ausdrücklichen Hinweis „GPS-Schätzung" gekennzeichnet.

Die Genauigkeit beginnt schlecht und wird besser: jedes geschlossene Tankfenster verankert das Modell neu an der Zapfsäule, sodass eine reine GPS-Fahrt nach einer Handvoll voller Tanks typischerweise auf wenige Prozent genau liegt. Bis dahin ist sie als vorläufig gekennzeichnet und nicht schöngeredet.

### Mit einem OBD2-Adapter

Motordaten statt Ableitung: echter Kraftstofffluss (gemessen, wo das Auto PID 5E meldet), Drehzahl, Last, Gaspedal. Keine Lernphase beim Verbrauch, und das Coaching bekommt Signale, die GPS nicht sehen kann — Gang, Drehzahl, Motorlast. Einrichtung in Fahrzeuge & OBD2.

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

*Die Zusammenfassung nennt ihre eigene Herkunft — Fahrzeug, Adapter, und ein **GPS-Spur**-Badge an der Strecke, damit du weißt, woher die Kilometer kommen.*

*Die Route ist nach Effizienz gefärbt — grün unter 6 L/100 km, gelb bis 10, rot darüber. Wohin der Kraftstoff ging, geografisch.*

Diese Einfärbung ist die handlungsstärkste Ansicht der App: sie legt die teuren Teile deines Arbeitswegs auf eine Karte. Ein roter Abschnitt, der sich täglich wiederholt, ist eine Kreuzung, ein Hügel oder eine Gewohnheit, die sich zu ändern lohnt.

*Drei Blöcke: dein eigenes Urteil, die Kraftstoffzuordnung und wie du den Motor wirklich genutzt hast.*

- **„Wie war diese Fahrt?"** — *Sanft / Moderat / Aggressiv*. Deine Antwort kalibriert die Fahrstil-Schwellen an echten Fahrten; sie benotet dich nicht.
- **Wohin dein Kraftstoff ging** — Liter, die harter Beschleunigung gegenüber normalem Fahren zugeordnet werden. Auf einer kurzen Fahrt kleine Absolutwerte; das Verhältnis ist der Punkt.
- **Gaspedalstellung** und **Drehzahl** als Verteilungen — der Anteil der Fahrt im Segeln, leicht, kräftig und Vollgas, und in jedem Drehzahlband. Ein hoher Anteil über 3000/min auf dem Arbeitsweg heißt: du schaltest zu spät hoch, und das ist teuer.

*Zwei Diagnosen: wie vollständig die GPS-Spur ist und wie sich der Adapter verhalten hat.*

*Ausgeklappt erklärt sich die OBD2-Karte im Klartext.*

**Lies diese Karte, bevor du an einer Verbrauchszahl zweifelst.** Sie nennt, wie viele Stichproben Motordaten trugen, die resultierende **Abdeckung in Prozent**, Adapter und ausgehandeltes Protokoll, die Sitzungsdauer, warum die Sitzung endete (`userStopped`, ein Abbruch, ein Prozesstod), und den entscheidenden Satz: *„Die Verbrauchswerte kommen vom Adapter, nicht aus GPS-Schätzungen."* Liegt die Abdeckung deutlich unter 100 %, wurden die Lücken mit GPS-Schätzungen gefüllt und der Fahrtdurchschnitt ist eine Mischung.

*Geschwindigkeit, Kraftstofffluss und Drehzahl auf gemeinsamer Zeitachse — die drei Kurven, die jede Verbrauchszahl erklären.*

*Motorlast und Gaspedal nebeneinander zeigen den Unterschied zwischen Arbeiten lassen und bloßem Hochdrehen.*

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

*Einstellungen → Fahren & Verbrauch. Erfolge und Noten lassen sich app-weit ausblenden, wenn Gamification nichts für dich ist.*

---

## Das CO₂-Dashboard

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

</details>

---

**Siehe auch:** Fahrzeuge & OBD2 · Tankbuch & Verbrauch
**Weiter:** Preisverlauf & Prognosen →

---

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

Für einen wiederherstellbaren Stand statt eines Datenexports nimm **Einstellungen → Sicherung & Wiederherstellung** — siehe Einstellungen-Referenz.

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

**Siehe auch:** Einstellungen-Referenz · Wie Sparkilo funktioniert → Wo deine Daten liegen
**Weiter:** Fehlersuche & FAQ →

---

# Einstellungen-Referenz

Jeder Bildschirm des Einstellungsbaums und — nützlicher — **was jeder Schalter kostet**: an Akku, Daten, Genauigkeit oder Privatsphäre.

---

## Die Form des Ganzen

Die Einstellungen sind ein **zweistufiger Baum**: eine Wurzel aus Themenkacheln, ein Bildschirm pro Thema, und eine Stichwortsuche über alle.

*Tippe „Radius", „OBD2" oder „Design" in das Suchfeld, und die passende Kachel taucht auf — du musst dir nie merken, welches Thema einen Parameter besitzt.*

*Insgesamt zwölf Themen. Zu den Einstellungen: das Zahnrad oben rechts auf den Hauptbildschirmen.*

Drei Entwurfsregeln machen den Baum vorhersagbar:

1. **Ein Zuhause pro Parameter.** Nichts erscheint zweimal; Querverweise zeigen auf den einen Besitzer.
2. **Gültigkeits-Labels.** Eine Kachel mit *dieses Profil*, *alle Profile* oder *dieses Fahrzeug* sagt dir vorab, wie weit eine Änderung reicht.
3. **Ehrliche Leerzustände.** Ein Abschnitt, dessen Funktion aus ist, sagt das und verlinkt den Schalter, statt sich zu verstecken.

---

## Profile & Region

*Land, Sprache, Kraftstoff, Suchradius, Routenplanung · Gültigkeit: dieses Profil*

*Der bevorzugte Kraftstoff wird aus dem Standardfahrzeug abgeleitet. Um ihn direkt zu wählen, entferne das Fahrzeug aus dem Profil.*

| Einstellung | Auswirkung |
|---|---|
| **Profilname** | Kosmetisch, aber genau das zeigt der Profil-Chip |
| **Bevorzugter Kraftstoff** | Der Schlagzeilenpreis auf jeder Karte; Standard für Alarme; wofür die Routensuche optimiert |
| **Standardradius** | Größer = mehr Ergebnisse und langsamere Suchen |

*Standardwerte der Routenplanung. **Kandidaten pro Abtastpunkt** tauscht Gründlichkeit gegen Tempo auf langen Korridoren.*

*Drei getrennte Dinge, die man kennen sollte.*

- **Autobahnen meiden** ändert die berechnete Route selbst, Raststätten sind dann gar keine Kandidaten mehr — meist eine Ersparnis, denn Autobahnkraftstoff ist auf jedem Korridor der teuerste.
- **Stationsnotizen** — *Lokal* (nur dieses Gerät), *Privat* (in dein Konto synchronisiert) oder *Geteilt* (für andere Nutzer sichtbar). Das ist eine Datenschutz-, keine Speicherentscheidung.
- **Startbildschirm** — womit die App öffnet: In der Nähe, Nächste Station, Favoriten oder Karte.

*Radius und die Regel **nächste vs. günstigste im Radius** stehen im Profil, ein Pendler- und ein Urlaubsprofil können sich also unterschiedlich verhalten.*

*Das Land bestimmt den Datenanbieter. Es zu ändern löscht zwischengespeicherte Stationsdaten.*

*Eine **Heimat-Postleitzahl** ermöglicht Gebietssuchen ganz ohne GPS — der sauberste Weg, die App zu nutzen, wenn du deinen Standort nie teilen willst.*

---

## Fahrzeuge & OBD2

*Deine Autos, Tankgröße, Adapter-Kopplung · Gültigkeit: dieses Fahrzeug*

*Adapter werden pro Fahrzeug gekoppelt, deshalb führt die Adapter-Kachel in ein Fahrzeug statt auf einen globalen Kopplungsbildschirm.*

Die vollständige Behandlung — FIN, Tankinhalt, Flex-Fuel, Kalibrierungsmodi, Baseline, Schwellen der automatischen Aufzeichnung, Wartungserinnerungen — steht in Fahrzeuge & OBD2.

---

## Fahren & Verbrauch

*Coaching, Belohnungen, Radar, Fehlersuche · Gültigkeit: gemischt*

*Die oberen beiden Einträge sind die, die du wirklich justieren wirst.*

| Einstellung | Auswirkung |
|---|---|
| **Live-Verbrauchsfenster** (3/5/10/30 s) | Länger ist ruhiger und beim Fahren besser lesbar; kürzer reagiert schnell genug, um zu zeigen, was das Pedal kostet |
| **Overlay bei Annäherung** | Radius, Preismodus, Abfrage-Untergrenze und Bildschirm-Anheftung für das aktive Profil |
| **Echtzeit-Eco-Coaching** | Leichte Vibration + Bildschirmhinweis bei starker Beschleunigung im Reisetempo |
| **Gesprochenes Fahrcoaching** | Derselbe Rat vorgelesen — die Augen bleiben auf der Straße |
| **Glide-Coach Beta** | Haptik vor einer roten Ampel anhand von OpenStreetMap-Signalen. **Standardmäßig aus — Ablenkungsrisiko**, und es braucht Netz |

*Belohnungen und Fehlersuche.*

- **Kundenkarten** — Rabatte pro Liter, die in die Preisvergleiche einfließen, sodass eine nominell teurere Station für dich korrekt günstiger rangieren kann.
- **Erfolge und Noten anzeigen** — aus blendet jedes Abzeichen, jede Note und jede Trophäe app-weit aus. Gemessen wird weiter, nur nicht mehr angezeigt.
- **OBD2-Debug-Protokoll** — zeichnet jede Sitzung (Verbindung, Handshake, Datenverluste, Neuverbindungen) in ein exportierbares XML-Protokoll. **Standardmäßig aus**: es schreibt laufend und lohnt sich nur, solange du ein Adapterproblem jagst.

---

## Preise & Alarme

*Alarme, Sprachansagen, Verlauf, Community-Meldungen*

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

*Die **Verbrauchseinheit** wirkt überall gleichzeitig — Live-Banner, Bild-in-Bild-Kachel, Fahrtdurchschnitte, Statistik, Widget.*

- **Entfernungseinheit** folgt standardmäßig dem Land des aktiven Profils (km oder Meilen).
- **Verbrauchseinheit**: *Automatisch* (mpg in UK und USA, sonst L/100 km) oder ausdrücklich L/100 km, km/L oder mpg.

*Widget-Einstellungen tragen das Label **dieses Profil** und gelten ab der nächsten Aktualisierung für jedes installierte Widget dieses Profils.*

**Inhaltsvariante** — *nur aktueller Preis* oder *prognostisch: beste Tankzeit* (braucht die TFLite-Prognose).

---

## Funktionen & Nutzungsmodus

*Voreinstellungen und jeder Einzelschalter*

*Eine Voreinstellung **überschreibt** jeden Einzelschalter. Wer von Hand justiert hat, bleibt auf Benutzerdefiniert.*

Abhängigkeiten werden durchgesetzt, nicht versteckt: Ein Schalter mit ausgeschalteter Voraussetzung bleibt gesperrt und nennt die Voraussetzung.

*Suche & Karte — inklusive der Frage, ob Tankstellen und Ladepunkte überhaupt erscheinen.*

*Preise & Alarme. Der Preisverlauf ist die Elternfunktion der Prognose darunter.*

*Das Radar, seine Sprachansagen und der Hauptschalter **Sprachausgabe** — ist er aus, öffnet die App nie eine Sprachsynthese.*

*Die Auswahl **Aus / Kraftstoff / Kraftstoff + Fahrten** ist die kompakte Form des ganzen Verbrauchsstapels.*

| Schalter | Auswirkung |
|---|---|
| **Verbrauchsanalyse** | Der Auswertungs-Tab über Tankfüllungen und Fahrten |
| **Gamification** | Fahrnoten und verdiente Abzeichen |
| **Haptischer Eco-Coach** | Vibrationsrückmeldung in Echtzeit während der Fahrt |
| **Glide-Coach** | Eco-Hinweise aus OpenStreetMap-Ampeln — braucht Netz |
| **GPS-Fahrtspur** | Speichert die Routenpunkte jeder Fahrt. Aus = kleinere Datenbank, keine Routenkarten |
| **Automatische Aufzeichnung** | Startet eine Fahrt, wenn der gekoppelte Adapter sich mit einem fahrenden Auto verbindet |

*Zwei Schalter hier ändern die Datenqualität statt der Oberfläche.*

- **Experimentelle OEM-PIDs** — liest den exakten Tankstand in Litern über herstellerspezifische PIDs auf kompatiblen Adaptern. Bessere Tankdaten, wo es geht; harmlos, wo nicht.
- **OBD2 für Fahrtaufzeichnung verlangen** — **aus** heißt: Fahrten werden auch nur per GPS aufgezeichnet. Das Coaching ist reduziert (kein Momentanverbrauch, weniger Motorsignale), aber nichts ist blockiert.
- **Baseline-Sync** — lädt Fahrzeug-Baselines hoch, damit ein zweites Gerät sie wiederverwenden kann. Braucht TankSync.

*Eingabe & Scannen. Die Erkennung läuft auf dem Gerät; diese Schalter entscheiden nur, ob die Abkürzungen existieren.*

*Entwickler & experimentell — kann aus bleiben, außer du meldest Fehler.*

---

## Datenquellen & Standort

*API-Schlüssel, GPS, automatischer Profilwechsel*

*Ein rotes Kreuz beim Kraftstoffpreis-Schlüssel ist der übliche Grund, warum eine deutsche Suche leer bleibt.*

| Einstellung | Auswirkung |
|---|---|
| **Kraftstoffpreise (Tankerkoenig)** | Nur für Deutschland nötig. Kostenlos, pro Nutzer, im hardwaregestützten Tresor |
| **E-Auto laden (OpenChargeMap)** | Optional — ersetzt den gemeinsamen Schlüssel durch dein eigenes Kontingent |
| **Automatische Aktualisierung** | Frischt die GPS-Position vor jeder Suche auf. Aus = schnellere Suchen, evtl. von veralteter Position |
| **Automatischer Profilwechsel** | Wechselt das Profil beim Grenzübertritt, damit Anbieter und Sorte automatisch stimmen |

---

## Synchronisierung & Konto

*Dieser Bildschirm zeigt auch Probleme — hier ein selbst gehostetes TankSync-Schema, das veraltet ist und deshalb stillschweigend einige Tabellen nicht synchronisiert.*

Vollständig behandelt in Datenschutz, Daten & Sync → TankSync. Das Wesentliche:

- **Sparkilo Community / eigene Datenbank / Datenbank einer Gruppe** — drei Betriebsformen mit drei verschiedenen Verantwortlichen.
- **Anonym → E-Mail** — *Auf E-Mail wechseln* behält deine Daten und dein Konto und ergänzt eine Anmeldemöglichkeit von einem anderen Gerät. Ein anonymes Konto existiert nur auf dem Gerät, das es erzeugt hat.
- **Schema veraltet** — Selbsthoster müssen nach einem App-Update das Einrichtungs-SQL erneut ausführen, sonst scheitert die Synchronisierung neuer Tabellen still.

---

## Datenschutz & Daten

*Zwei netzbezogene Datenschutzentscheidungen, jeweils formuliert als das, was sie wirklich preisgeben.*

- **Kartenkacheln über den Sparkilo-Proxy** — *an*: der EU-Server des Entwicklers sieht deinen Kartenausschnitt und deine IP und holt die Kacheln für dich. *Aus*: die Kacheln kommen direkt von tile.openstreetmap.org, das dann deine IP sieht. Keine Option heißt „kein Netz"; du wählst, von wem du gesehen wirst. Der F-Droid-Build nutzt den Proxy nie.
- **Markenlogos aus dem Internet laden** — standardmäßig *aus*; es werden mitgelieferte generische Logos genutzt. An kommen sie von logo.clearbit.com, das deine IP sieht.

*Speicher, aufgeschlüsselt. Der Cache ist fast immer der größte Anteil und der einzige, den man gefahrlos wegwerfen kann.*

*Cache-Verwaltung, mit der Lebensdauer jeder Klasse: Suchen 5 Min., Stationsdetails 15 Min., Preisabfragen 5 Min., Favoritendaten 30 Min., Ortssuchen 30 Min., PLZ-Geokodierung 24 h.*

*Den Cache zu leeren löscht nur zwischengespeicherte Ergebnisse und Preise — Profile, Favoriten und Einstellungen bleiben. Die nächsten Suchen sind langsamer; verloren geht nichts.*

---

## Sicherung & Wiederherstellung

*Eine vollständige ZIP-Datei mit Fahrzeugen, Tankfüllungen, Fahrten und Ladeprotokollen.*

**Sicherung exportieren** schreibt die ZIP in deinen Downloads-Ordner. **Sicherung wiederherstellen** bietet *zusammenführen* oder *ersetzen* — Zusammenführen behält, was auf dem Gerät ist, und ergänzt Fehlendes; Ersetzen löscht zuerst. Nutze das vor einem Telefonwechsel oder einem Werksreset. TankSync ist keine Sicherung: es spiegelt ausgewählte Kategorien, nicht alles.

---

## Erweitert & Entwickler

*Das GitHub-Token ist optional — ohne es wird eine fehlgeschlagene Scan-Rückmeldung manuell geteilt, statt automatisch ein Issue anzulegen.*

Der Eintrag **Entwicklerwerkzeuge** erscheint nur bei eingeschaltetem Entwicklermodus (Funktionen & Nutzungsmodus → Entwickler & experimentell).

*Für normale Nutzer ist das Fehlerprotokoll der nützliche Teil: **Fehlerprotokoll speichern** schreibt bereinigte Spuren in die Downloads, zum Anhängen an einen Fehlerbericht.*

*Der Startup-Trace ist ein Wasserfall der Initialisierungsphasen — so diagnostiziert man einen langsamen Start, statt zu raten.*

***Annäherungs-Overlay testen** setzt 30 s lang einen synthetischen Zustand, damit du die Bild-in-Bild-Preisanzeige prüfen kannst, ohne irgendwohin zu fahren.*

---

## Über

***Version und Build-Nummer** — nenne beide in jedem Fehlerbericht und prüfe sie zuerst, wenn eine Korrektur „nicht funktioniert hat" (womöglich hat der Store-Rollout dich noch nicht erreicht).*

*Die App ist kostenlos, quelloffen und werbefrei. Die Quellenangaben für Preis- und Kartendaten stehen unten, wie es die Lizenzen verlangen.*

---

**Siehe auch:** Wie Sparkilo funktioniert · Datenschutz, Daten & Sync
**Weiter:** Datenschutz, Daten & Sync →

---

# Fehlersuche & FAQ

Grob danach sortiert, wie oft es tatsächlich vorkommt.

---

## Zuerst: prüfe deine Version

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

Hintergrund: Wie Sparkilo funktioniert → Wie aus einem Liter eine Zahl wird.

---

## „Wir haben eine Lücke von X Litern gefunden"

Du hast mehr getankt, als deine aufgezeichneten Fahrten erklären. Beantworte die beiden Fragen des Abgleichs: eine fehlende oder vertippte Tankfüllung bekommt einen **Korrektureintrag**, eine nicht aufgezeichnete Fahrt eine **virtuelle Fahrt**. Beides ist danach bearbeitbar. Ungeklärt verzerrt es die Kalibrierung, zwei Tipps lohnen sich also. Siehe Tankbuch & Verbrauch.

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

Details: Datenschutz, Daten & Sync → Deine Rechte.

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

**Zurück zu:** Benutzerhandbuch-Startseite
