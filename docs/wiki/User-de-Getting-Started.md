# Erste Schritte

Zehn Minuten von der Installation bis zum ersten gesparten Euro. Wenn du danach nur eine weitere Seite liest, dann [Wie Sparkilo funktioniert](User-de-How-It-Works).

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

<img src="screenshots/privacy-consent.png" width="340" alt="Einwilligungsbildschirm beim ersten Start mit allen Verarbeitungszwecken">

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

Beides wird aus deiner Systemsprache erkannt, und beides steckt **im Profil** — siehe [Wie Sparkilo funktioniert → Profile](User-de-How-It-Works#profile-ein-kontext-ein-satz-voreinstellungen).

<img src="guide/profile-edit-6.jpg" width="340" alt="Sprachauswahl und Heimat-Postleitzahl im Profil-Editor">

*Einstellungen → Profile & Region → Profil bearbeiten. Die Heimat-Postleitzahl erlaubt Suchen in einem festen Gebiet, ohne je GPS herauszugeben.*

Das Land zu wechseln **löscht zwischengespeicherte Stationsdaten**, weil Preise des vorherigen Anbieters für das neue Land nicht gelten. Die nächste Suche dauert deshalb etwas länger.

---

## 4. Nutzungsmodus wählen

Das ist die folgenreichste einzelne Einstellung, denn sie bestimmt, wie viel App du bekommst.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Nutzungsmodi Basis, Mittel, Voll, Benutzerdefiniert">

*Einstellungen → Funktionen & Nutzungsmodus. Beginne mit **Basis**, wenn du nur günstiger tanken willst; steige auf, wenn du wissen willst, warum dein Auto säuft.*

- **Basis** — günstig tanken und laden, Favoriten, Alarme, Routen.
- **Mittel** — ergänzt den **Kraftstoff**-Tab: Tankfüllungen erfassen, echter Verbrauch und echte Kosten. Ohne Hardware.
- **Voll** — ergänzt den **Fahrten**-Tab: automatische Aufzeichnung, Fahrnoten, Kundenkarten. Ein OBD2-Adapter ist auch hier optional — Fahrten werden auch nur per GPS aufgezeichnet.

Du kannst jederzeit wechseln, und jeder Einzelschalter, den du danach umlegst, bringt dich auf **Benutzerdefiniert**. Die vollständige Liste der Schalter — und was jeder an Akku, Daten oder Privatsphäre kostet — steht in [Einstellungen-Referenz → Funktionen & Nutzungsmodus](User-de-Settings-Reference#funktionen--nutzungsmodus).

---

## 5. Nur Deutschland: der kostenlose API-Schlüssel

16 der 17 Länder funktionieren sofort. Der offizielle **deutsche** Preisdienst vergibt einen Schlüssel pro Nutzer.

<img src="guide/data-sources-location.jpg" width="340" alt="Datenquellen mit den Schlüsselfeldern für Tankerkönig und OpenChargeMap">

*Einstellungen → Datenquellen & Standort. Ein rotes Kreuz hier ist der Grund, warum eine deutsche Suche nichts liefert.*

1. [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) öffnen und einen Schlüssel anfordern (kurzes Formular, kostenlos).
2. Kopieren — es ist eine UUID wie `00000000-0000-0000-0000-000000000002`.
3. In das Feld **Kraftstoffpreise (Tankerkoenig)** einfügen.

Der Schlüssel liegt im hardwaregestützten Tresor (Android Keystore / iOS Keychain) und geht ausschließlich an den deutschen Preisdienst. Das Feld **E-Auto laden** darunter enthält bereits einen gemeinsamen Schlüssel — Ladedaten funktionieren ohne Einrichtung.

---

## 6. Die untere Leiste

<img src="guide/favorites.jpg" width="340" alt="Favoriten-Tab mit unterer Leiste und dem erhabenen Such-Button">

*Der erhabene grüne **Such**-Button in der Mitte ist der einzige Auslöser für eine Suche in der gesamten App.*

- ⭐ **Favoriten** — gespeicherte Stationen und deine Preisalarme
- 🗺️ **Karte** — jede Station in der Nähe als preisfarbige Nadel
- 🔍 **Suche** *(Mitte)* — in der Nähe oder entlang einer Route
- ⛽ **Kraftstoff** — Tank, Verbrauch, Tankfüllungen *(ab Mittel)*
- 🛣️ **Fahrten** — Fahrtenbuch und Coaching *(Voll)*

Einstellungen sind **kein** Tab: das Zahnrad oben rechts auf den Hauptbildschirmen. Auf einem Tablet oder einem quer gehaltenen Telefon teilt sich die App in zwei Spalten, sodass Liste und Karte (oder Detail) gleichzeitig sichtbar sind.

---

## 7. Deine erste Suche

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Kriterien-Dialog für eine Umkreissuche">

*Auf **Suche** tippen → der Kriterien-Dialog öffnet sich, vorbelegt aus deinem Profil. Anpassen, dann erneut **Suchen** tippen.*

Du bekommst eine Liste, günstigste zuerst (oder nach Entfernung — deine Wahl), jede Karte mit Preis, Trend, Entfernung und Aktualität. Ein Tipp öffnet die Detailseite. Die vollständige Tour steht in [Tankstellen finden](User-de-Finding-Stations).

**Tipp:** Tippe unten im Dialog einmal auf **Als Standard speichern**, wenn die Kriterien passen — jede künftige Suche startet dort.

---

## 8. Zwei Einstellungen für den ersten Tag

<img src="guide/units-and-display-1.jpg" width="340" alt="Einheiten und Darstellung mit Design, Entfernungseinheit und Verbrauchseinheit">

*Einstellungen → Einheiten & Darstellung. **Verbrauchseinheit** steht auf *Automatisch* (mpg in UK, sonst L/100 km); wähle L/100 km, km/L oder mpg ausdrücklich, wenn dir das lieber ist.*

Die zweite ist **Einstellungen → Fahren & Verbrauch → Live-Verbrauchsfenster** (3 / 5 / 10 / 30 s). Sie steuert die große Live-Zahl auf dem Aufzeichnungsbildschirm: ein längeres Fenster ist beim Fahren ruhiger zu lesen, ein kürzeres reagiert schneller auf den rechten Fuß.

---

## 9. Wähle, womit die App startet

**Einstellungen → Profile & Region → Startbildschirm**: *In der Nähe* (sofortige Suche mit deinen letzten Kriterien), *Nächste Station*, *Favoriten* oder *Karte*. Nimm das, weshalb du die App tatsächlich öffnest.

---

## 10. Wo alles liegt

Die Einstellungen sind ein zweistufiger Baum mit Stichwortsuche oben — tippe „Radius", „OBD2" oder „Design" und die passende Kachel taucht auf.

<img src="guide/settings-root-1.jpg" width="340" alt="Einstellungs-Wurzel: Themenkacheln mit Suchfeld">

*Zwölf Themen, ein Zuhause pro Parameter. Die vollständige Karte ist die [Einstellungen-Referenz](User-de-Settings-Reference).*

---

**Weiter:** [Wie Sparkilo funktioniert →](User-de-How-It-Works)
