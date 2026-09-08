# E-Auto laden

Sparkilo ist nicht nur für Verbrenner. Ladepunkte kommen von [OpenChargeMap](https://openchargemap.org), dem größten offenen Community-Verzeichnis weltweit.

---

## Einschalten

Zwei unabhängige Schalter, beide unter **Einstellungen → Funktionen & Nutzungsmodus → Suche & Karte**:

- **E-Auto laden** — die Funktion selbst (Suche, Detailseiten, Favoriten).
- **Ladepunkte anzeigen** — ob Ladepunkte in Ergebnissen und auf der Karte auftauchen.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Schalter der Gruppe Suche & Karte inklusive E-Auto laden und Ladepunkte anzeigen">

*Du kannst Tankstellen, Ladepunkte oder beides zeigen. Wer rein elektrisch fährt, schaltet **Tankstellen anzeigen** meist aus.*

Lege dann unter **Einstellungen → Fahrzeuge & OBD2 → Meine Fahrzeuge → Hinzufügen** ein Fahrzeug mit dem Antrieb **Elektrisch** an. Ein E-Fahrzeug trägt Batteriekapazität (kWh), maximale AC- und DC-Ladeleistung (kW) und die unterstützten Stecker (Typ 2, CCS, CHAdeMO, Tesla, Schuko, Typ 1, Schutzkontakt). Suchen filtern dann auf Ladepunkte, die dein Auto wirklich nutzen kann.

---

## Wie die Daten funktionieren

<img src="guide/data-sources-location.jpg" width="340" alt="Schlüsselfeld für E-Auto-Laden mit dem Standardschlüssel der App">

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

<img src="screenshots/map-ev-charging.png" width="340" alt="Karte im E-Auto-Modus mit Stecker-Filterchips">

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

**Siehe auch:** [Tankstellen finden](User-de-Finding-Stations) · [Tankbuch & Verbrauch](User-de-Fuel-And-Consumption)
**Weiter:** [Fahrzeuge & OBD2 →](User-de-Vehicles-And-OBD2)
