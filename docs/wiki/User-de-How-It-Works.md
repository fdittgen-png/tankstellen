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

<img src="guide/features-and-mode-1.jpg" width="340" alt="Funktionsverwaltung mit den Voreinstellungen Basis, Mittel, Voll und Benutzerdefiniert">

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

<img src="guide/profile-edit-1.jpg" width="340" alt="Profil bearbeiten — Name, aus dem Fahrzeug abgeleiteter Kraftstoff, Standardradius">

*Einstellungen → Profile & Region → bearbeiten. Der bevorzugte Kraftstoff wird **aus deinem Standardfahrzeug abgeleitet** — entferne das Fahrzeug, wenn du den Kraftstoff selbst wählen willst.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Regions-Abschnitt des Profils — Land- und Sprachauswahl">

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

<img src="guide/search-results.jpg" width="340" alt="Ergebnis-Kopfzeile mit der französischen staatlichen Preisquelle">

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

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Daten auf diesem Gerät: jede lokal gespeicherte Datenkategorie mit Größe und Anzahl">

*Einstellungen → Datenschutz & Daten → Daten auf diesem Gerät zeigt jede Kategorie mit einem echten Zähler — nichts an deinen Daten bleibt dir verborgen.*

Nur vier Dinge verlassen jemals das Telefon, drei davon freiwillig:

| Verlässt das Telefon | Wann | Optional? |
|---|---|---|
| Suchkoordinaten oder ein Regionscode | Bei jeder Suche, an die Preisquelle des Landes | Für Live-Preise nötig |
| Kartenausschnitt + deine IP | Kartenkacheln über den EU-Proxy des Entwicklers | Ja — Proxy aus, dann direkt von OpenStreetMap |
| Absturzspuren | Nur mit eingeschalteter *Fehlerberichterstattung* | Ja — standardmäßig aus |
| Deine synchronisierten Zeilen | Nur mit eingeschaltetem *TankSync* | Ja — standardmäßig aus |

**Deine Identität ist nie Teil einer Preisabfrage.** Die vollständige Aufstellung: [Datenschutz, Daten & Sync](User-de-Privacy-Profiles-Sync).

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

<img src="guide/trips-tab.jpg" width="340" alt="Tank-Bericht mit Abdeckung und Kalibrierungs-Delta">

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
- **Wenn du ohne Aufzeichnung fährst, gehen die Zahlen nicht auf** — und die App sagt das, statt zu tricksen. Siehe den Abgleich in [Tankbuch & Verbrauch](User-de-Fuel-And-Consumption#wenn-die-zahlen-nicht-aufgehen).

---

## Wie die App dein Fahren lernt

Getrennt vom Pump-Gain trägt ein Fahrzeug eine **Fahrsituations-Baseline**: was dein Auto im Leerlauf, im Stop-and-go, in der Stadt, auf der Autobahn, beim Verzögern, am Berg oder beladen, aus dem Kalten, unter Dauerlast und im Segeln verbraucht.

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Baseline-Kalibrierung mit Stichproben je Situation und Warnung zu fehlenden Situationen">

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

<img src="guide/settings-root-1.jpg" width="340" alt="Einstellungs-Wurzel mit Themenkacheln und Suchfeld">

*Jeder Parameter hat genau ein Zuhause. Wer das Thema kennt, muss nie scrollen.*

Vollständige Karte aller Bildschirme: [Einstellungen-Referenz](User-de-Settings-Reference).

---

**Weiter:** [Tankstellen finden →](User-de-Finding-Stations)
