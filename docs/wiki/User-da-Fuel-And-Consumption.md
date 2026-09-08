# Tankbog og forbrug

Niveau 2 og 3 af de [tre spareniveauer](User-da-How-It-Works#de-tre-spareniveauer): hvor meget du brænder, og hvad det reelt kostede. Fanen ⛽ **Brændstof** vises i tilstandene **Mellem** og **Fuld**.

---

## Fanen Brændstof på et blik

<img src="guide/fuel-tab.jpg" width="340" alt="Fanen Brændstof: tankniveau med rækkevidde, statistikkort med præcisionsmærke og listen over tankninger">

*Tre blokke: hvad der er i tanken, hvad din kørsel koster, og hvad du faktisk har tanket.*

### Tankniveau og rækkevidde

Måleren er **forankret i din seneste fulde tankning** og derefter trukket ned med det brændstof, dine optagne ture har brugt. Datostemplet under bjælken fortæller, hvilken tankning den er forankret i.

Der vises bevidst to rækkevidder:

- **« ≈ 548 km ved forbruget fra din seneste tank »** — den seneste adfærd, nyttig i dag.
- **« Langsigtet gennemsnit: ≈ 611 km »** — dit historiske gennemsnit, nyttigt til planlægning.

Afviger de meget, har noget ændret sig for nylig: en tagboks, vinteren, en anden vejblanding, eller et brændstofskift.

> Når en OBD2-adapter er tilsluttet, og bilen oplyser brændstofniveau-PID'en, skifter måleren til **tanksensoren** og siger det. Den værdi er en måling, ikke en udledning, og den overlever ikke-optagne ture.

### Statistikkortet

De tre mærker er ærlighedslaget:

| Mærke | Betydning |
|---|---|
| **Præcision: Høj · ±3-7 %** | Både tankninger og OBD2-ture fodrer modellen |
| **Præcision: Mellem** | Tankninger forankrer den, men ingen OBD2-tur har fodret sløjfen endnu |
| **Præcision: Lav** | Kun GPS, intet forankret — tilføj et par fulde tankninger |
| **η_v : 0,93 · 6 prøver** | Speed-density-modellens lærte volumetriske virkningsgrad og antal prøver |

Nedenunder: gennemsnitlig L/100 km, gennemsnitlig pris pr. km, liter i alt, samlet forbrug, antal tankninger. Et tryk åbner den fulde [forbrugsstatistik](#forbrugsstatistik).

---

## Registrér en tankning

Tryk på **➕ Tilføj tankning** — eller meget hurtigere: **Tilføj tankning** direkte på en stations detaljeside, som forudfylder station, brændstof og pris.

<img src="screenshots/consumption-pick-station.png" width="340" alt="Tankformular forudfyldt med mærke, brændstof og pris fra en nylig søgning">

*Kommer du fra en station, er tre felter allerede rigtige — du skriver liter, total og kilometerstand.*

| Felt | Hvorfor det betyder noget |
|---|---|
| **Dato** | Ordner tankvinduerne |
| **Køretøj** | Tilskriver tankningen og kalibreringen |
| **Brændstoftype** | På en flex-fuel hænger hele sammenligningen på dette felt |
| **Liter** | Tælleren i standersandheden |
| **Samlet pris** | Pris pr. km, månedligt forbrug |
| **Kilometerstand** | **Det vigtigste felt i formularen** |
| **Fuld tank** | Lukker et kalibreringsvindue — se nedenfor |
| Station, noter | Valgfrit |

### Hvorfor kilometerstanden er det kritiske felt

Forbrug er liter ÷ kilometer. Literne kommer fra kvitteringen og er eksakte. Kilometerne kommer fra *dine to aflæsninger af kilometertælleren*. En tastefejl på 20 km på en tank på 600 km er 3 % fejl — og fordi det resultat rekalibrerer estimatoren, forplanter fejlen sig til alle fremtidige skøn. Formularen afviser en kilometerstand under den forrige tanknings, for afstand går ikke baglæns.

### Fluebenet « Fuld tank »

Sæt det, hver gang du fylder helt op. Det er dét, der gør to tankninger til et **lukket vindue** med et fysisk sandt forbrug.

Delvise tankninger registreres stadig, tæller for omkostningen og står på listen — de kan bare ikke lukke et vindue. Statistikskærmen viser et banner, der tæller *« delvise tankninger der afventer en fuld tank — ikke med i gennemsnittet »*, så du altid ved, hvad der er i tallene.

### Scan i stedet for at taste

- **Scan standerens display** — ret kameraet mod displayet; appen læser liter, total og pris.
- **Scan kvitteringen** — det samme fra den trykte bon.
- **Del et foto af en kvittering** fra en anden app direkte ind i formularen.

Genkendelsen kører **på enheden**; billedet uploades aldrig. Kast altid et blik på værdierne før du gemmer — en scanning er et forspring, ikke et orakel. Læser den forkert, opretter *Rapportér scanningsfejl* en sag med udsnittet, så genkendelsen bliver bedre.

> **F-Droid-build:** tekstgenkendelse på enheden findes kun i Play- / App Store-builds. Den GMS-frie F-Droid-build har ingen scanning — dér taster man tankninger i hånden. Alt andet er identisk.

---

## Tankrapporten — sandhedens øjeblik

Hver gang en fuld tank lukker, udgiver appen en rapport. På fanen Ture ser den sådan ud:

<img src="guide/trips-tab.jpg" width="340" alt="Tankrapport: 6,4 L/100 km, forskel til forrige tank, dækningsbjælke og kalibreringsdom">

*Ét kort, fire forskellige udsagn — og de er bevidst ikke det samme tal.*

| Linje | Hvad det er |
|---|---|
| **6,4 L/100 km** | Denne tanks **standersandhed**: påfyldte liter ÷ kilometertællerens kilometer |
| **1,5 L/100 km mindre end forrige tankning** | Tendens mod den sidst lukkede tank |
| **559 km · 35,7 L · 32,12 €** | Det rå vindue |
| **Optagelserne dækker 81 % af denne tank** | Hvor stor en del af de kilometer du faktisk optog |
| **Optaget andel: 10,5 L/100 km** | Hvad de optagne kilometer alene gav i gennemsnit |
| **De optagne skøn ligger 39 % over standersandheden** | Kalibreringsdommen — estimatoren lå for højt og er netop rettet |

### At læse den rigtigt

Den optagne andel og standersandheden **må gerne afvige**, af to forskellige grunde, der er lette at forveksle:

1. **Udvælgelsen.** Du optager de ture, du optager. Er dine 81 % mest korte byture, og de manglende 19 % en motorvejsstrækning, ligger den optagne andel med rette højere end tankens gennemsnit. Intet er i stykker.
2. **Kalibreringen.** Selve estimatoren kan være skæv. Det er dét, sidste linje måler, ved at sammenligne de to **pr. kilometer**, så dækningen går ud og kun afgør vinduets vægt.

Efter en rettelse som denne skal du forvente, at turskønnene falder mærkbart på næste tur og derefter falder til ro. Hele mekanismen: [Sådan fungerer Sparkilo → Hvordan en liter bliver til et tal](User-da-How-It-Works#hvordan-en-liter-bliver-til-et-tal).

Kortet kan også pege på *hvad der ændrede sig* — andel af høje omdrejninger, hårde hændelser pr. 100 km, koldstarter, tomgangsandel, hver især mod forrige tank — med det udtrykkelige forbehold, at optagelser er spontane og kun dækker en del af tanken.

---

## Forbrugsstatistik

Tryk på statistikkortet, eller **Brændstof → Forbrugsstatistik**.

<img src="guide/consumption-stats-1.jpg" width="340" alt="Statistikoverskrift: brændstoffilterchips, totaler og tabellen denne måned vs sidste måned">

*Chipsene øverst begrænser alt nedenunder til ét brændstof — uundværligt på en flex-fuel, hvor et samlet gennemsnit er meningsløst.*

Månedstabellen viser liter, forbrug i kroner, gennemsnitspris pr. liter, gennemsnitsforbrug, pris pr. km og antal tankninger, hver med sin forskel. Røde pile er ikke en dom — stigende *udgift* efter stigende *pris pr. liter* er markedet, ikke din højre fod. Tallet at holde øje med for kørslen er **L/100 km**.

### Pris pr. kilometer pr. brændstof

<img src="guide/consumption-stats-2.jpg" width="340" alt="Pris pr. kilometer pr. brændstof: E85- og E5-rækker med pris/km, L/100 km, betalt pris og CO2">

*Flex-fuel-bilistens egentlige spørgsmål, besvaret: ikke hvilket brændstof der er billigst pr. liter, men hvilket der er billigst pr. kilometer.*

Hvert brændstof får en række bygget udelukkende på **lukkede tankvinduer**: målt L/100 km, faktisk betalt pris pr. liter, pris pr. 100 km, samlet forbrug, målt afstand, forbrugte liter, CO₂ pr. 100 km, og hvor mange fulde tanke der ligger bag. En række baseret på én enkelt tank er mærket **Foreløbig**.

<img src="guide/consumption-stats-3.jpg" width="340" alt="Domkort om driftsomkostninger med vinderen, balancepunktet og CO2-noten">

*Domkortet angiver vinderen, forskellen pr. 1000 km og — mest nyttigt — **balanceprisen**.*

Balancelinjen (« E5 bliver bedre end E85 under 0,75 €/L ») beregnes ud fra **dit eget målte forbrug af hvert brændstof**, så den flytter sig, når din kørsel gør. Det er en beslutningsregel, du kan bruge ved standeren; et generisk forhold fra nettet er ikke.

CO₂-tallene er well-to-wheel-skøn (EU JEC WTW v5) anvendt på dit målte forbrug — bevidsthed, ikke revisionsegnet regnskab. Blandinger holdes uden for CO₂, fordi emissionsfaktoren afhænger af blandingen, som rækken ikke registrerer.

<img src="guide/consumption-stats-4.jpg" width="340" alt="Udvikling over tid: liter pr. måned og forbrug pr. måned, stablet efter brændstof">

*Tendensgraferne stabler efter brændstof, så et skift viser sig som én farve der afløser en anden, frem for som et mystisk spring.*

<img src="guide/consumption-stats-5.jpg" width="340" alt="Pris pr. liter og L/100 km pr. måned">

*Pris pr. liter og L/100 km er bevidst to adskilte grafer — den ene er markedet, den anden er dig.*

**Eksportér** skriver det hele som CSV i din offentlige Downloads-mappe.

---

## Øko-score pr. tankning

Hver tankning får et mærke sammenlignet med et rullende gennemsnit af dine seneste tre tankninger med samme brændstof:

| Forskel | Mærke | Sådan læses det |
|---|---|---|
| ≥ 3 % bedre | 🟢 Forbedres | Mærkbart mindre end din egen basislinje |
| inden for ±3 % | ⚪ Stabil | Normal variation |
| ≥ 3 % dårligere | 🟠 Forværres | Tjek dæktryk, tagboks, kulde, vejblanding |

Mærket forbliver skjult, indtil du har fire tankninger med det brændstof, så basislinjen er reel.

---

## Når regnestykket ikke går op

Før eller siden tanker du flere liter, end dine optagne ture kan gøre rede for — en anden kørte, adapteren var taget ud, appen var lukket. I stedet for stiltiende at sluge forskellen viser appen et **afvigelsesbanner** og tilbyder en kort afstemning:

> *Vi fandt en afvigelse på 4,2 L. Du tankede 35,7 L, men dine optagne ture gør kun rede for 31,5 L.*

Den stiller to spørgsmål:

1. **Er alle tankninger på denne tank fuldstændige og korrekte?** — Nej betyder, at en mangler eller er tastet forkert, og appen tilføjer en **korrektionstankning**, så literne går op.
2. **Er alle dine ture optaget?** — Nej betyder, at en tur mangler, og appen tilføjer en **virtuel tur** for den manglende afstand.

Begge poster kan bagefter redigeres og slettes, og begge er mærket som automatisk genereret, så du aldrig forveksler dem med rigtige data. Du kan også vælge **Beslut senere** — banneret bliver, indtil du løser det.

**Hvorfor det betyder noget:** en uløst afvigelse skævvrider stille kalibreringsvinduet. At løse den (eller slette den forkerte post) holder forankringen til standeren troværdig.

---

## Loyalitetskort

**Indstillinger → Kørsel & forbrug → Loyalitetskort** gemmer rabatter pr. liter for de kæder, du bruger. Rabatten anvendes derefter i prissammenligningerne, så en station der ser 2 øre/L dyrere ud, med rette kan rangere som den billigste for dig. Funktionen slås til under Funktioner & brugstilstand → Indtastning og scanning.

---

<details>
<summary>Helskærmsopslag — forbrugsstatistik, hele siden</summary>

<img src="guide/full/consumption-stats.jpg" width="420" alt="Fuld forbrugsstatistik sammensat af fem optagelser">

</details>

---

**Se også:** [Køretøjer og OBD2](User-da-Vehicles-And-OBD2) · [Ture og øko-coaching](User-da-Trips-And-Coaching)
**Videre:** [Ture og øko-coaching →](User-da-Trips-And-Coaching)
