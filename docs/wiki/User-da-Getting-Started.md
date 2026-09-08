# Kom godt i gang

Ti minutter fra installation til den første sparede krone. Læser du kun én side mere bagefter, så lad det være [Sådan fungerer Sparkilo](User-da-How-It-Works).

---

## 1. Installér

### Google Play (Android)

Installér fra **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — den offentlige produktionsudgivelse.

> **Kommer du fra betaen?** Play bliver ved med at levere beta-builds, når du er tilmeldt den åbne test (listen viser et *(beta)*-mærke). Sådan skifter du til produktion: åbn [Play-siden](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Forlad programmet** → afinstallér → geninstallér.
>
> **Vil du have nyhederne først?** Bliv i betaen — hver build når beta-kanalen før produktion.

### F-Droid (Android, uden Google)

En fuldt **GMS-fri** build udgives via sit eget F-Droid-arkiv (OpenStreetMap-kort, ingen Google-tjenester). I F-Droid: **Indstillinger → Arkiver → +** og tilføj:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Søg derefter efter **Sparkilo**. Har du Play-versionen installeret, så afinstallér den først — anden signeringsnøgle, så den kan ikke opdatere ovenpå.

### Andre veje

- **APK** — fra [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — TestFlight-beta; bed om en invitation via [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues), indtil App Store-siden er live.

**Mindst Android** 7.0 (API 24), mål Android 15. **Mindst iOS** 15.5, mål iOS 18.

Ingen konto, ingen tilmelding, ingen e-mail. Appen kan bruges fuldt ud, så snart installationen er færdig.

---

## 2. Første start — samtykket

Før nogen anden skærm viser appen en **GDPR-samtykkeskærm**. Det er ikke et cookiebanner: den opremser hvert behandlingsformål, og appen fortsætter kun, hvis du accepterer.

<img src="screenshots/privacy-consent.png" width="340" alt="Samtykkeskærm ved første start med hvert behandlingsformål">

*Hvert samtykke, der vises her, optræder igen i Indstillinger → Privatliv og data, med datoen du gav det og den politikversion du så.*

| Punkt | Hvorfor | Hvis du afviser |
|---|---|---|
| **Placering** *(under brug)* | Søgning i nærheden, rutestart, turoptagelse | Søg på postnummer eller vælg et punkt på kortet |
| **Notifikationer** | Kun til prisadvarsler | Advarsler udløses aldrig |
| **Diagnostik** | Nedbrudsspor til Sentry — **fra som standard** | Intet sendes; du kan stadig selv gemme fejlloggen |

Før hver *system*-anmodning (kamera, Bluetooth, notifikationer) viser appen først sin egen korte forklaring, så du ved hvad du siger ja til, inden Android spørger.

Fuld tekst: **[Privatlivspolitik v3, 29. august 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. Land, sprog og dit område

Begge registreres fra dit systemsprog, og begge bor **i profilen** — se [Sådan fungerer Sparkilo → Profiler](User-da-How-It-Works#profiler-én-kontekst-ét-sæt-standardværdier).

<img src="guide/profile-edit-6.jpg" width="340" alt="Sprogvælger og hjemmepostnummer i profileditoren">

*Indstillinger → Profiler & region → redigér profil. Hjemmepostnummeret giver dig områdesøgninger uden nogensinde at udlevere GPS.*

At skifte land **rydder gemte stationsdata**, fordi priser fra den tidligere leverandør ikke gælder for det nye land. Den næste søgning tager derfor et øjeblik længere.

---

## 4. Vælg en brugstilstand

Det er den mest betydningsfulde enkeltindstilling, for den afgør hvor meget app du får.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Forudindstillingerne Basis, Mellem, Fuld, Tilpasset">

*Indstillinger → Funktioner & brugstilstand. Start på **Basis**, hvis du kun vil have billigere brændstof; gå op, når du vil vide hvorfor bilen drikker.*

- **Basis** — find billigt brændstof og opladning, favoritter, advarsler, ruter.
- **Mellem** — tilføjer fanen **Brændstof**: registrér tankninger, se reelt forbrug og reelle omkostninger. Ingen hardware nødvendig.
- **Fuld** — tilføjer fanen **Ture**: automatisk optagelse, kørescorer, loyalitetskort. En OBD2-adapter er valgfri selv her — ture optages med GPS alene.

Du kan skifte når som helst, og enhver enkeltkontakt du rører bagefter sætter dig i **Tilpasset**. Den fulde liste, og hvad hver enkelt koster i batteri, data eller privatliv: [Indstillingsoversigt → Funktioner & brugstilstand](User-da-Settings-Reference#funktioner--brugstilstand).

---

## 5. Kun Tyskland: den gratis API-nøgle

16 af de 17 lande virker med det samme. Den officielle **tyske** pristjeneste udsteder en nøgle pr. bruger.

<img src="guide/data-sources-location.jpg" width="340" alt="Datakildeskærm med nøglefelterne til Tankerkönig og OpenChargeMap">

*Indstillinger → Datakilder & placering. Et rødt kryds her er grunden til, at en tysk søgning intet giver.*

1. Åbn [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) og bed om en nøgle (kort formular, gratis).
2. Kopiér den — det er en UUID som `00000000-0000-0000-0000-000000000002`.
3. Indsæt den i feltet **Brændstofpriser (Tankerkoenig)**.

Nøglen ligger i det hardwarebaserede pengeskab (Android Keystore / iOS Keychain) og sendes kun til den tyske tjeneste. Feltet **EV-opladning** nedenunder rummer allerede en delt nøgle: ladedata virker uden opsætning.

---

## 6. Den nederste bjælke

<img src="guide/favorites.jpg" width="340" alt="Fanen Favoritter med den nederste bjælke og den centrale Søg-knap">

*Den hævede grønne **Søg**-knap i midten er den eneste søgeudløser i hele appen.*

- ⭐ **Favoritter** — gemte stationer og dine prisadvarsler
- 🗺️ **Kort** — hver station i nærheden som prisfarvet nål
- 🔍 **Søg** *(midten)* — i nærheden eller langs en rute
- ⛽ **Brændstof** — tank, forbrug, tankninger *(fra Mellem)*
- 🛣️ **Ture** — logbog og coaching *(Fuld)*

Indstillinger er **ikke** en fane: det er tandhjulet øverst til højre på hovedskærmene. På en tablet, eller en telefon holdt på tværs, deler appen sig i to spalter, så liste og kort (eller detalje) ses samtidig.

---

## 7. Din første søgning

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Kriterieark til en søgning i nærheden">

*Tryk på **Søg** → kriteriearket åbner forudfyldt fra din profil. Justér, og tryk **Søg** igen.*

Du får en liste sorteret fra billigst (eller efter afstand — dit valg), hvor hvert kort viser pris, tendens, afstand og hvor frisk tallet er. Et tryk åbner detaljen. Den fulde rundtur: [Find tankstationer](User-da-Finding-Stations).

**Tip:** tryk på **Gem som standardværdier** nederst i arket, når kriterierne passer — enhver fremtidig søgning starter dér.

---

## 8. To indstillinger værd at ændre på dag ét

<img src="guide/units-and-display-1.jpg" width="340" alt="Enheder og visning med tema, afstandsenhed og forbrugsenhed">

*Indstillinger → Enheder & visning. **Forbrugsenhed** står på *Automatisk* (mpg i Storbritannien, L/100 km ellers); vælg udtrykkeligt L/100 km, km/L eller mpg, hvis du foretrækker det.*

Den anden er **Indstillinger → Kørsel & forbrug → Vindue for live-forbrug** (3 / 5 / 10 / 30 s). Den styrer det store live-tal på optageskærmen: et længere vindue er roligere at læse under kørsel, et kortere reagerer hurtigere på din højre fod.

---

## 9. Vælg hvad appen åbner på

**Indstillinger → Profiler & region → Startskærm**: *I nærheden* (øjeblikkelig søgning med dine seneste kriterier), *Nærmeste station*, *Favoritter* eller *Kort*. Vælg den, der svarer til grunden til, at du åbner appen.

---

## 10. Hvor alting ligger

Indstillinger er et træ med to niveauer og en nøgleordssøgning øverst — skriv « radius », « OBD2 » eller « tema », og det rette felt dukker op.

<img src="guide/settings-root-1.jpg" width="340" alt="Indstillingsroden: emnefelter med søgefelt">

*Tolv emner, ét hjem pr. parameter. Det fulde kort er [Indstillingsoversigt](User-da-Settings-Reference).*

---

**Videre:** [Sådan fungerer Sparkilo →](User-da-How-It-Works)
