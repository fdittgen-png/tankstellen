# Prishistorik og forudsigelser

Appen bygger et **privat, lokalt** billede af, hvordan priserne bevæger sig omkring dig, og gør det til én ærlig anbefaling.

---

## Hvad der registreres, og hvor

Hver gang en stations pris passerer gennem appen — en søgning, en opdatering af favoritter eller et baggrundstjek af advarsler — skriver appen en registrering **på din telefon**: station, brændstof, pris, tidsstempel. Intet uploades, og ingen andres data hentes.

- **Dubletfjernet til én registrering pr. station pr. time.** Fem søgninger på ti minutter giver én post.
- **Gemmes i 30 dage.** Ældre registreringer slettes automatisk.
- **Slås til af** *Funktioner & brugstilstand → Priser & advarsler → Prishistorik*. Er den fra, skrives ingen registreringer overhovedet.

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Priser &amp; advarsler: historik, TFLite-forudsigelse, fællesskabsrapporter, betalings-QR">

*Indstillinger → Priser & advarsler. **Prishistorik** er forudsætningen for forudsigelsen nedenunder — uden historik har den intet at arbejde med.*

---

## Se en stations historik

Åbn en stations detaljeside og rul ned til **Prishistorik**:

- **Timegraf** — gennemsnitspris for hver time på døgnet over de seneste 30 dage.
- **Ugedagsgraf** — gennemsnit for hver ugedag.
- **Min / maks / gennemsnit / tendens** som opsummering.

Den billigste time eller dag fremhæves med grønt, den dyreste med rødt.

---

## « Bedste tidspunkt at tanke »

Så snart der er historik nok, får stationen et banner:

> 💡 **Priserne falder typisk tirsdag 18:00–20:00** — spar ~3,2 øre/L

### Hvad det er — og ikke er

Det er en **opsummering af, hvad der allerede er sket på den station de seneste 30 dage**, i *dine* data. Det er bevidst **ikke**:

- en forudsigelse af morgendagens pris,
- bevidst om oliemarked, afgiftsændringer eller vejr,
- bygget på andre brugeres data.

Den tilbageholdenhed er pointen. Et regionalt mandagsmorgen-tillæg er et virkeligt, gentagende, lokalt mønster, man kan handle på; en markedsprognose fra en telefon er ikke.

### Læringsfasen

Banneret forbliver skjult, indtil appen har mindst **10 prisregistreringer for den station de seneste 30 dage**. Hvor lang tid det tager, afhænger udelukkende af, hvor tit stationens pris passerer gennem appen:

| Situation | Tid til banneret |
|---|---|
| Stationen har en **prisadvarsel** | Få timer — baggrundstjekket registrerer hvert 30.–60. minut |
| Stationen er en **favorit**, du åbner dagligt | Omkring 10 dage |
| Ingen af delene — kun lejlighedsvise søgninger | Uger, muligvis aldrig |

**Det praktiske trick:** sæt en advarsel på den station, du reelt bruger. Advarslen tjener sig ind to gange — den siger til ved et fald og fylder den historik, der producerer anbefalingen.

### Hvorfor din favorit stadig ikke har et banner

1. **Ikke nok registreringer endnu** (se ovenfor).
2. **Prisen har knap nok bevæget sig.** Er spændet over 30 dage under 0,1 øre/L, er der intet værd at handle på, så der vises intet.
3. **Kun ét brændstof har prøver.** Tærsklen gælder pr. brændstoftype, ikke pr. station.

---

## Prisforudsigelse på enheden

*Funktioner & brugstilstand → Priser & advarsler → **Bedste tidspunkt at tanke*** aktiverer en lille TensorFlow Lite-model, der kører **udelukkende på enheden**. Dens træk og forudsigelser forlader aldrig telefonen. Det er den, der driver den *forudsigende* variant af startskærms-widgetten (**Indstillinger → Enheder & visning → Widget på startskærmen → Indholdsvariant**), som viser det bedste tidspunkt at tanke frem for blot den aktuelle pris.

Vil du hellere have, at intet udledes, så slå den fra: historik og mønsterbanner virker videre uden.

---

## Prisrapporter fra fællesskabet

*Funktioner & brugstilstand → Priser & advarsler → **Fællesskabets prisrapporter*** tilføjer en rapportér-handling til stationsdetaljen, så du kan melde en pris, den officielle kilde har forkert. Rapporter går til den delte TankSync-database under din pseudonyme konto og er synlige for andre indloggede brugere — det er altså den eneste prisfunktion, der **ikke** er rent lokal. Den kræver TankSync og er slået fra, indtil du tænder den.

---

## Eksport

**Indstillinger → Privatliv og data → Eksportér eller slet → Eksportér mine data → CSV** skriver en CSV — dens prishistorik-tabel indeholder station, brændstof, pris, tidsstempel — til din offentlige Downloads-mappe.

---

**Se også:** [Favoritter og advarsler](User-da-Favorites-And-Alerts) · [Find tankstationer → Friskhed](User-da-Finding-Stations#friskhed--vigtigere-end-prisen)
**Videre:** [Indstillingsoversigt →](User-da-Settings-Reference)
