# Sparkilo — Guida utente (Italiano)

> *Pagare meno al litro. Bruciarne meno al chilometro. Vedere esattamente quanto è costato.*

Sparkilo è un'app libera e gratuita che **riduce il costo d'uso della tua auto**. Nessun account, nessuna pubblicità, nessun tracciamento, nessun Google Play Services. Tutto ciò che l'app sa di te resta sul telefono finché non attivi qualcos'altro.

*La schermata che userai di più: prezzi in tempo reale vicino a te, i più economici per primi, con la fonte ufficiale in open data indicata in alto.*

---

## I tre livelli di risparmio

Tutta l'app è costruita su un'idea: **un'auto costa denaro in tre modi indipendenti, e ciascuno richiede uno strumento diverso.**

| Livello | La domanda a cui risponde | Dove vive |
|---|---|---|
| **1. Il prezzo** | *Dove il carburante costa meno adesso?* | Ricerca, Mappa, Preferiti, Avvisi, Itinerari |
| **2. Il consumo** | *Quanti litri ogni 100 km, e perché?* | Viaggi, eco-coaching, OBD2 |
| **3. La verità** | *Quanto ho pagato davvero, e la stima dell'app è onesta?* | Scheda Carburante, rifornimenti, statistiche consumi |

Il livello 1 fa già risparmiare e non richiede nulla oltre all'app. I livelli 2 e 3 richiedono i tuoi rifornimenti; il livello 2 diventa molto più preciso con un adattatore OBD2 economico. Quanto scendere lo decidi tu — vedi Come funziona Sparkilo.

---

## Cosa contiene questa guida

**Iniziare da qui**

| Pagina | Cosa imparerai |
|---|---|
| Primi passi | Installazione, consenso al primo avvio, paese e lingua, modalità d'uso, prima ricerca |
| Come funziona Sparkilo | I concetti dietro tutto: profili, modalità d'uso, una fonte per paese, dove vivono i tuoi dati, come un litro diventa un numero |

**Trovare carburante economico (livello 1)**

| Pagina | Cosa imparerai |
|---|---|
| Trovare stazioni | Il pulsante Cerca centrale, i criteri, leggere una scheda, il dettaglio, la mappa, il radar stazioni |
| Pianificazione itinerario | Le soste più economiche lungo il percorso, i corridoi transfrontalieri, le quattro strategie |
| Preferiti e avvisi | Stazioni salvate, avvisi di stazione e di zona, come si comporta davvero il controllo in background |
| Ricarica elettrica | Colonnine via OpenChargeMap, connettori, filtri di potenza |
| Storico e previsioni prezzi | Lo storico locale a 30 giorni, il « momento migliore per fare rifornimento » e ciò che l'algoritmo deliberatamente *non* fa |

**Consumare meno e sapere quanto è costato (livelli 2 e 3)**

| Pagina | Cosa imparerai |
|---|---|
| Veicoli e OBD2 | Il modello di veicolo, la capacità del serbatoio, il flex-fuel, l'accoppiamento, la calibrazione di riferimento, regole vs fuzzy |
| Registro rifornimenti e consumi | Rifornimenti, livello serbatoio, rapporto del pieno, livelli di precisione, costo al km per carburante |
| Viaggi ed eco-coaching | Registrazione GPS o OBD2, dettaglio di un viaggio, punteggio di guida, cruscotto carbonio |

**Riferimento**

| Pagina | Cosa imparerai |
|---|---|
| Riferimento impostazioni | Ogni schermata dell'albero a due livelli, con l'impatto operativo di ogni interruttore |
| Privacy, dati e sincronizzazione | Consensi, gli argomenti di Privacy e dati, TankSync, backup, i tuoi diritti GDPR |
| Risoluzione problemi e FAQ | Nessun risultato? L'adattatore non si collega? Widget fermo? |

---

## I 17 paesi supportati

🇩🇪 Germania · 🇫🇷 Francia · 🇦🇹 Austria · 🇪🇸 Spagna · 🇮🇹 Italia · 🇩🇰 Danimarca · 🇵🇹 Portogallo · 🇱🇺 Lussemburgo · 🇸🇮 Slovenia · 🇬🇧 Regno Unito · 🇦🇷 Argentina · 🇦🇺 Australia · 🇲🇽 Messico · 🇰🇷 Corea del Sud · 🇨🇱 Cile · 🇬🇷 Grecia · 🇷🇴 Romania

Ogni paese è servito dalla **propria fonte pubblica ufficiale in open data** — mai da un aggregatore unico. La Germania richiede una chiave API gratuita da [tankerkoenig.de](https://creativecommons.tankerkoenig.de/); tutti gli altri funzionano subito. Perché questo conta per ciò che vedi a schermo: Come funziona Sparkilo.

L'interfaccia è tradotta in **23 lingue** (bg, cs, da, de, el, en, es, et, fi, fr, hr, hu, it, lt, lv, nb, nl, pl, pt, ro, sk, sl, sv) e segue la lingua di sistema.

<a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
  <img alt="Disponibile su Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/it_badge_web_generic.png" height="80"/>
</a>

---

**Avanti:** Primi passi →

> **Sulle schermate.** Tutte le schermate di questa guida provengono da un dispositivo con l'app in **francese**, sulla fonte prezzi francese in tempo reale. L'interfaccia è completamente localizzata — le tue schermate hanno lo stesso layout con le parole della tua lingua.

---

# Primi passi

Dieci minuti dall'installazione al primo euro risparmiato. Se dopo leggi una sola altra pagina, che sia Come funziona Sparkilo.

---

## 1. Installare

### Google Play (Android)

Installa dal **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — la versione pubblica di produzione.

> **Vieni dalla beta?** Play continua a servire build beta una volta iscritto al test aperto (la scheda mostra un'etichetta *(beta)*). Per passare alla produzione: apri la [scheda Play](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Abbandona il programma** → disinstalla → reinstalla.
>
> **Vuoi le novità prima?** Resta nella beta — ogni build arriva al canale beta prima della produzione.

### F-Droid (Android, senza Google)

Una build completamente **priva di GMS** viene distribuita da un repository F-Droid dedicato (mappe OpenStreetMap, nessun servizio Google). In F-Droid: **Impostazioni → Repository → +** e aggiungi:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Poi cerca **Sparkilo**. Se la build Play è installata, disinstallala prima — chiave di firma diversa, quindi nessun aggiornamento sopra.

### Altri modi

- **APK** — dalle [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — beta TestFlight; chiedi un invito tramite [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) finché la scheda App Store non è pubblicata.

**Android minimo** 7.0 (API 24), target Android 15. **iOS minimo** 15.5, target iOS 18.

Nessun account, nessuna registrazione, nessuna e-mail. L'app è pienamente utilizzabile appena l'installazione finisce.

---

## 2. Primo avvio — il consenso

Prima di ogni altra schermata l'app mostra una **schermata di consenso GDPR**. Non è un banner sui cookie: elenca ogni finalità di trattamento, e l'app prosegue solo se accetti.

*Ogni consenso mostrato qui torna più tardi in Impostazioni → Privacy e dati, con la data e la versione dell'informativa che hai visto.*

| Voce | Perché | Se rifiuti |
|---|---|---|
| **Posizione** *(durante l'uso)* | Ricerca nelle vicinanze, partenza itinerario, registrazione viaggi | Cerca per CAP o scegli un punto sulla mappa |
| **Notifiche** | Solo per gli avvisi di prezzo | Gli avvisi non scattano mai |
| **Diagnostica** | Tracce di crash verso Sentry — **disattivata di default** | Non viene inviato nulla; puoi comunque salvare tu il registro errori |

Prima di ogni richiesta *di sistema* (fotocamera, Bluetooth, notifiche) l'app mostra prima una propria spiegazione, così sai a cosa acconsenti prima che Android lo chieda.

Testo integrale: **[Informativa sulla privacy v3, 29 agosto 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. Paese, lingua e la tua zona

Entrambi sono rilevati dalla lingua di sistema, ed entrambi vivono **nel profilo** — vedi Come funziona Sparkilo → Profili.

*Impostazioni → Profili e regione → modifica profilo. Il CAP di casa consente ricerche in un'area fissa senza mai cedere il GPS.*

Cambiare paese **svuota i dati di stazione in cache**, perché i prezzi del fornitore precedente non valgono per il nuovo paese. La ricerca successiva impiegherà un attimo in più.

---

## 4. Scegliere una modalità d'uso

È l'impostazione più determinante, perché decide quanta app ottieni.

*Impostazioni → Funzioni e modalità d'uso. Parti da **Base** se vuoi solo carburante più economico; sali quando vorrai sapere perché la tua auto beve.*

- **Base** — trovare carburante e ricarica, preferiti, avvisi, itinerari.
- **Medio** — aggiunge la scheda **Carburante**: registrare i rifornimenti, vedere consumo e costo reali. Nessun hardware.
- **Completo** — aggiunge la scheda **Viaggi**: registrazione automatica, punteggi di guida, carte fedeltà. Un adattatore OBD2 resta facoltativo anche qui — i viaggi si registrano col solo GPS.

Puoi cambiare in ogni momento, e ogni interruttore toccato poi ti porta in **Personalizzato**. L'elenco completo, e quanto ciascuno costa in batteria, dati o privacy: Riferimento impostazioni → Funzioni e modalità d'uso.

---

## 5. Solo Germania: la chiave API gratuita

16 dei 17 paesi funzionano subito. Il servizio ufficiale **tedesco** rilascia una chiave per utente.

*Impostazioni → Fonti dati e posizione. Una croce rossa qui è il motivo per cui una ricerca tedesca non restituisce nulla.*

1. Apri [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) e richiedi una chiave (modulo breve, gratuito).
2. Copiala — è un UUID come `00000000-0000-0000-0000-000000000002`.
3. Incollala nel campo **Prezzi carburante (Tankerkoenig)**.

La chiave sta nella cassaforte hardware (Android Keystore / Portachiavi iOS) ed è inviata solo al servizio tedesco. Il campo **Ricarica EV** sotto contiene già una chiave condivisa: i dati di ricarica funzionano senza configurazione.

---

## 6. La barra inferiore

*Il pulsante verde **Cerca** rialzato al centro è l'unico attivatore di ricerca dell'intera app.*

- ⭐ **Preferiti** — stazioni salvate e avvisi di prezzo
- 🗺️ **Mappa** — ogni stazione vicina come segnaposto colorato per prezzo
- 🔍 **Cerca** *(al centro)* — nelle vicinanze o lungo un itinerario
- ⛽ **Carburante** — serbatoio, consumi, rifornimenti *(da Medio in su)*
- 🛣️ **Viaggi** — registro e coaching *(Completo)*

Le impostazioni **non** sono una scheda: è l'ingranaggio in alto a destra delle schermate principali. Su tablet, o telefono in orizzontale, l'app si divide in due colonne per vedere elenco e mappa (o dettaglio) insieme.

---

## 7. La tua prima ricerca

*Tocca **Cerca** → il foglio dei criteri si apre precompilato dal profilo. Regola, poi tocca di nuovo **Cerca**.*

Ottieni un elenco dal più economico (o per distanza — a te la scelta), ogni scheda con prezzo, tendenza, distanza e freschezza. Un tocco apre il dettaglio. Il giro completo: Trovare stazioni.

**Suggerimento:** tocca **Salva come valori predefiniti** in fondo al foglio una volta impostati i criteri abituali — ogni ricerca futura partirà da lì.

---

## 8. Due impostazioni da cambiare il primo giorno

*Impostazioni → Unità e visualizzazione. L'**unità di consumo** è *Automatica* per impostazione predefinita (mpg nel Regno Unito, L/100 km altrove); scegli esplicitamente L/100 km, km/L o mpg se preferisci.*

La seconda è **Impostazioni → Guida e consumo → Finestra del consumo in tempo reale** (3 / 5 / 10 / 30 s). Governa il grande numero in tempo reale della schermata di registrazione: una finestra lunga è più stabile da leggere alla guida, una corta reagisce più in fretta al piede destro.

---

## 9. Scegli su cosa si apre l'app

**Impostazioni → Profili e regione → Schermata iniziale**: *Nelle vicinanze* (ricerca immediata con i tuoi ultimi criteri), *Stazione più vicina*, *Preferiti* o *Mappa*. Prendi quella che corrisponde al motivo per cui apri l'app.

---

## 10. Dove sta tutto

Le impostazioni sono un albero a due livelli con una ricerca per parola chiave in alto — digita « raggio », « OBD2 » o « tema » e la tessera giusta emerge.

*Dodici temi, una casa per parametro. La mappa completa è il Riferimento impostazioni.*

---

**Avanti:** Come funziona Sparkilo →

---

# Come funziona Sparkilo

Questa pagina è il modello mentale. Tutto il resto della guida descrive percorsi di clic; qui si spiega *perché* quei percorsi hanno questa forma. Dieci minuti qui ti risparmiano un'ora a frugare nelle impostazioni.

---

## I tre livelli di risparmio

Un'auto costa denaro in tre modi indipendenti, e abbassarne uno non fa nulla per gli altri:

1. **Il prezzo al litro** — la pompa che scegli. Determinato da geografia e mercato; il compito dell'app è mostrarti la più economica che puoi realisticamente raggiungere.
2. **I litri al chilometro** — come guidi e cosa guidi. Il compito dell'app è misurarlo onestamente e mostrare quale abitudine costa di più.
3. **Quanto hai davvero pagato** — la traccia di controllo. Il compito dell'app è mantenere le proprie stime ancorate alla realtà invece di lasciarle derivare.

Il livello 1 funziona dall'installazione. I livelli 2 e 3 richiedono dati da te: come minimo i rifornimenti, idealmente anche viaggi registrati. **L'app non finge mai di sapere più di quanto le sia stato detto** — per questo vedi badge di precisione, percentuali di copertura ed etichette « provvisorio » anziché numeri tondi e sicuri.

---

## Modalità d'uso: l'app della tua taglia

Sparkilo può essere un cercaprezzi da due schermate o un vero computer di bordo. Invece di imporre ogni interruttore a tutti, l'app raggruppa le funzioni in **preimpostazioni di modalità d'uso**.

*Impostazioni → Funzioni e modalità d'uso. Scegliere una preimpostazione commuta in blocco tutto l'insieme corrispondente; toccare poi un singolo interruttore ti porta in **Personalizzato**.*

| Preimpostazione | Ottieni | Barra inferiore |
|---|---|---|
| **Base** | Carburante e ricarica più economici nelle vicinanze, preferiti, avvisi, itinerari | Preferiti · Mappa · **Cerca** |
| **Medio** | Tutto Base + registro manuale dei rifornimenti, consumo e costo reali | + Carburante |
| **Completo** | Tutto Medio + registrazione OBD2 automatica dei viaggi, punteggi di guida, carte fedeltà | + Viaggi |
| **Personalizzato** | La tua miscela — appena tocchi un singolo interruttore | dipende |

### Come funziona davvero

Una preimpostazione non è una modalità in cui l'app gira — è un **insieme di flag di funzionalità con un nome**. Ogni flag mostra o nasconde una funzione in modo indipendente, e alcuni dichiarano prerequisiti: *Sincronizzazione dei riferimenti* resta disattivata finché *TankSync* è spento, *Annunci vocali* finché *Feedback vocale* è spento, *Registrazione automatica* finché non è accoppiato un adattatore. La scheda spiega perché un interruttore è bloccato invece di ignorare il tocco in silenzio.

### Cosa cambia in pratica

- **Disattivare una funzione la rimuove dall'app, non solo dalla vista** — si ferma anche il suo lavoro in background. *Avvisi di prezzo* spenti fermano il controllo periodico; *Traccia GPS dei viaggi* spenta ferma la registrazione dei punti di percorso.
- **Le preimpostazioni sovrascrivono la tua miscela.** Toccare *Medio* riscrive ogni interruttore. Se hai regolato a mano, resta su Personalizzato.
- **La barra inferiore cambia forma.** Se la scheda Carburante o Viaggi è sparita, tu (o una preimpostazione) hai spento *Statistiche consumi* o *Registrazione OBD2 dei viaggi* — non è un bug.

---

## Profili: un contesto, un insieme di valori predefiniti

Un **profilo** raggruppa tutto ciò che dipende da *dove e come stai guidando ora*: paese, lingua, carburante preferito, raggio di ricerca predefinito, CAP di casa, parametri di itinerario, schermata iniziale, visibilità delle note, le impostazioni del radar e il veicolo predefinito.

*Impostazioni → Profili e regione → modifica. Il carburante preferito è **derivato dal veicolo predefinito** — rimuovi il veicolo se vuoi sceglierlo tu.*

*Paese e lingua stanno nel profilo: per questo cambiare profilo può cambiare in un tocco la fonte dati e la lingua dell'interfaccia.*

### Come funziona davvero

Il paese salvato nel profilo attivo decide **quale fornitore nazionale di open data l'app chiama**. Cambiarlo svuota i dati di stazione in cache, perché i prezzi del vecchio fornitore non hanno senso per il nuovo paese. Il carburante preferito decide quale prezzo è il titolo su ogni scheda, su cosa punta un avviso per impostazione predefinita e per cosa ottimizza una ricerca su itinerario.

### Cosa cambia in pratica

- **Un profilo per ogni paese in cui guidi.** « Casa — Italia, Benzina, 10 km » e « Vacanza — Spagna, E5, mappa » sono due profili, non due sessioni di impostazioni.
- **Le ricerche transfrontaliere usano il carburante del profilo di ciascun paese.** Senza un profilo per il secondo paese, quel tratto non ha una qualità da quotare e le sue stazioni mostrano `--`.
- **Il cambio automatico di profilo** (Impostazioni → Fonti dati e posizione) può commutare il profilo quando il GPS rileva un confine.
- Le tessere delle impostazioni portano un'**etichetta di ambito** — *questo profilo*, *tutti i profili* o *questo veicolo* — così sai sempre quanto lontano arriva una modifica.

---

## Una fonte dati per paese

Sparkilo non aggrega. Ogni paese è interrogato tramite la sua fonte ufficiale, e l'intestazione dei risultati la nomina.

*La riga sotto la barra non è decorazione — dice quale autorità ha pubblicato questi prezzi, e vi rimanda.*

### Come funziona davvero

| Paese | Fonte | Cadenza |
|---|---|---|
| Germania | Tankerkönig (chiave gratuita personale) | ~5 minuti |
| Francia | Prix-Carburants (gouv.fr) | continua, per stazione |
| Spagna | Geoportal Gasolineras (MITECO) | file giornaliero, filtrato sul dispositivo |
| Italia | File MIMIT | file giornaliero, filtrato sul dispositivo |
| …e altri 13 | il portale open data di ciascun paese | variabile |

### Cosa cambia in pratica

- **Le qualità di carburante cambiano oltre confine.** La Spagna vende E5 e raramente E10; la Francia mette in evidenza SP95-E10; la Germania pubblica E5, E10 e Diesel. Lo stesso carburante fisico porta tre nomi in tre paesi.
- **La freschezza cambia.** Un prezzo tedesco può avere cinque minuti, uno spagnolo essere la pubblicazione di ieri. Il badge di freschezza su ogni scheda dice quale stai guardando — fidati di quello più che del numero.
- **La densità cambia.** Un dataset nazionale povero restituisce meno stazioni nello stesso raggio. Sono i dati del paese, non una ricerca fallita.
- **Un `--` al posto del prezzo significa « questo fornitore non pubblica quella qualità per questa stazione »** — non « la stazione non la vende ».

---

## Dove vivono i tuoi dati

Sparkilo è **local-first**. Tutto ciò che sa è in database cifrati sul tuo telefono; la chiave sta nell'Android Keystore / Portachiavi iOS.

*Impostazioni → Privacy e dati → Dati su questo dispositivo mostra ogni categoria con un contatore reale: nulla dei tuoi dati ti è invisibile.*

Solo quattro cose lasciano il telefono, e tre sono facoltative:

| Cosa esce | Quando | Facoltativo? |
|---|---|---|
| Coordinate di ricerca o codice di regione | A ogni ricerca, verso la fonte prezzi del paese | Necessario per i prezzi in tempo reale |
| Area di mappa + il tuo IP | Caricamento tessere tramite il proxy UE dello sviluppatore | Sì — proxy spento, le tessere arrivano direttamente da OpenStreetMap |
| Tracce di crash | Solo con *Segnalazione errori* attiva | Sì — disattivata di default |
| Le tue righe sincronizzate | Solo con *TankSync* attivo | Sì — disattivato di default |

**La tua identità non fa mai parte di una richiesta di prezzo.** Il conteggio completo: Privacy, dati e sincronizzazione.

---

## Come un litro diventa un numero

È la parte che la maggior parte delle app di carburante sbaglia in silenzio, quindi vale la pena capirla.

### La pompa è la verità

L'unico numero fisicamente certo che l'app ottenga è **litri erogati ÷ chilometri percorsi tra due pieni**. Tutto il resto — stime GPS, portata derivata dal debimetro, modello speed-density — è un modello che può derivare.

Perciò l'app tratta ogni **finestra da pieno a pieno** come un evento di calibrazione:

1. Registri un rifornimento e spunti **Pieno**. Questo chiude la finestra precedente.
2. L'app calcola la *verità della pompa*: litri erogati ÷ chilometri contachilometri × 100.
3. La confronta con ciò che il suo stimatore ha prodotto sui chilometri effettivamente registrati, sottraendo ogni correzione già applicata.
4. Il rapporto fra i due diventa il **guadagno pompa** del veicolo, fuso con le finestre precedenti e limitato a un intervallo ragionevole.
5. Questo guadagno moltiplica poi **ogni ramo stimato della portata di carburante** — speed-density e MAF — al viaggio successivo.

Il carburante che l'auto *dichiara da sé* via OBD2 (PID 5E / 9D) è misurato, non modellato: il guadagno non lo tocca mai.

*Il rapporto del pieno rende visibile la calibrazione: questo serbatoio è andato a 6,4 L/100 km alla pompa, le registrazioni ne coprivano l'81 %, e lo stimatore era del 39 % troppo alto prima che questa finestra lo correggesse.*

### Perché la copertura non falsa nulla

Confrontare i due numeri **per chilometro** fa sì che i chilometri non registrati semplicemente non pesino. Un serbatoio di cui hai registrato un quinto dà comunque un rapporto non distorto — conta solo meno nella fusione. Per questo l'app mostra la percentuale di copertura invece di nasconderla: dice quanto fidarsi di *quella* finestra, non se la calibrazione sia valida.

### La scala di precisione

| Badge | Cosa c'è dietro | Fascia tipica |
|---|---|---|
| **Bassa** | Solo GPS — nessun rifornimento ha ancora ancorato nulla | ±15 % o peggio |
| **Media** | I rifornimenti hanno ancorato il modello, ma nessun viaggio OBD2 ha alimentato il ciclo | ±7–15 % |
| **Alta** | Rifornimenti *e* viaggi registrati in OBD2 | ±3–7 % |

### Cosa cambia in pratica

- **Spunta sempre « Pieno » quando riempi fino all'orlo.** Un rifornimento parziale viene comunque registrato e conta per il costo, ma non può chiudere una finestra di calibrazione. I parziali in attesa compaiono come banner nelle statistiche.
- **La precisione del contachilometri conta più di quella dei litri.** Un errore di battitura del 2 % avvelena la finestra; 0,2 L di arrotondamento no.
- **La prima finestra è presa alla lettera, le successive smussano.** Aspettati un salto, poi la stabilità.
- **Se guidi senza registrare, i conti non torneranno** — e l'app lo dice invece di arrangiarsi. Vedi la riconciliazione in Registro rifornimenti e consumi.

---

## Come l'app impara la tua guida

Separatamente dal guadagno pompa, un veicolo porta una **linea di riferimento per situazione di guida**: quanto consuma al minimo, in stop & go, in città, in autostrada, in decelerazione, in salita o a carico, da freddo, sotto carico prolungato e in veleggio.

*Ogni situazione si riempie in modo indipendente. L'avviso è onesto: due situazioni non hanno ancora campioni, quindi il riferimento è incompleto.*

### Come funziona davvero

Ogni campione OBD2 viene classificato in una situazione di guida e aggiunto a quel paniere. Esistono due modalità di classificazione:

- **Basata su regole** — ogni campione appartiene a esattamente una situazione. Netta, ma un'auto a 60 km/h oscilla da un campione all'altro fra « urbano » e « autostrada ».
- **Fuzzy** *(predefinita)* — ogni campione è distribuito su tutte le situazioni in base a quanto vi si adatta. Liscia esattamente dove la modalità a regole salta.

### Cosa cambia in pratica

- **Un riferimento appartiene al veicolo, non al telefono.** Cambiare auto significa ricominciare; *Sincronizzazione dei riferimenti* (richiede TankSync) lo porta su un secondo dispositivo.
- **Le situazioni mancanti sono lacune oneste, non errori.** Se non traini mai, « Carico prolungato / traino » resterà a 0 per sempre e l'app continuerà a dire che il profilo è incompleto. Va bene così.
- **Azzerare il riferimento ti riporta ai valori di partenza a freddo** finché nuovi viaggi non lo riempiono — fallo dopo un intervento meccanico, non perché un numero sembrava strano.

---

## L'unica regola sulle impostazioni da ricordare

Le impostazioni sono un **albero a due livelli**: una radice di tessere tematiche, una schermata per tema, e un campo di ricerca che filtra le tessere per parola chiave.

*Ogni parametro ha esattamente una casa. Se ricordi il tema, non devi mai scorrere.*

Mappa completa di tutte le schermate: Riferimento impostazioni.

---

**Avanti:** Trovare stazioni →

---

# Trovare stazioni

Livello 1 dei tre livelli di risparmio: pagare meno al litro.

---

## Un pulsante, un modello mentale

La barra inferiore ha un solo attivatore di ricerca — il pulsante verde rialzato al centro. È contestuale, non modale:

- **Da qualsiasi scheda** → apre il foglio dei criteri.
- **Dai risultati o dalla mappa** → riapre il foglio con i tuoi ultimi valori.
- **Dentro il foglio** → esegue la ricerca.

L'etichetta dice cosa farà, e in modalità itinerario resta disattivato finché non c'è una destinazione. Non esistono di proposito pulsanti separati per « cerca vicino » e « cerca lungo il percorso ».

---

## Impostare i criteri

*Il foglio si apre precompilato dal profilo attivo — di solito cambi una sola cosa.*

| Comando | Cosa fa | Impatto operativo |
|---|---|---|
| **Nelle vicinanze / Lungo l'itinerario** | Cambia l'intera modalità di ricerca | La modalità itinerario richiede una destinazione e interroga ogni paese del corridoio |
| **Indirizzo, CAP o città** | Cerca in un luogo anziché alla tua posizione GPS | Nulla sulla tua posizione lascia il telefono; il nome del luogo è geocodificato con OpenStreetMap Nominatim e messo in cache 24 h |
| **Chip di carburante** | La qualità per cui vedi i prezzi | L'elenco si adatta a ciò che il fornitore del tuo paese pubblica davvero |
| **Raggio** | Quanto lontano cercare | Un raggio ampio in un paese denso restituisce molte stazioni e rallenta la ricerca |
| **Solo aperte** | Nasconde le stazioni chiuse | Dipende dal fornitore che pubblica gli orari — alcuni non lo fanno |
| **Servizi** | Negozio, autolavaggio, aria, WC… | Filtra solo su dati dichiarati; una stazione con campo vuoto sparisce |
| **Marche** | Limita a certe catene | Contate sull'insieme corrente di risultati, quindi l'elenco cambia col raggio |
| **Salva come valori predefiniti** | Scrive questi criteri nel profilo | Ogni ricerca futura parte da qui |

### Il pulsante di ricerca

Il pulsante in rilievo al centro della barra inferiore è l'unico
attivatore della ricerca. Da qualsiasi scheda apre questo foglio; dai
risultati o dalla mappa lo riapre con ciò che hai usato per ultimo; nel
foglio stesso avvia la ricerca.

### Nelle vicinanze o lungo un percorso

Due domande diverse. **Nelle vicinanze** cerca attorno alla tua posizione
o a un indirizzo. **Lungo il percorso** richiede una destinazione e
misura la distanza lungo il corridoio anziché in linea d'aria: un
distributore a 2 km in una via laterale finisce dietro a uno che è sulla
tua strada.

### Tipo di carburante

Per quale carburante sono i prezzi. I chip si adattano a ciò che il
fornitore del tuo paese pubblica davvero — un carburante assente
dall'elenco manca nei dati, non nell'app.

### Raggio

Fin dove cercare. Un raggio ampio in un paese denso restituisce moltissimi
distributori e una ricerca più lenta, e quelli in più sono di solito più
lontani di quanto valga il risparmio.

### Solo aperti adesso

Nasconde i distributori chiusi. Dipende dal fornitore che pubblica o meno
gli orari, e alcuni non lo fanno — quando mancano, il distributore viene
mantenuto anziché indovinato.

### Servizi

Negozio, autolavaggio, aria, WC. Questi filtri agiscono su dati
**dichiarati**: un distributore che non pubblica nulla sui propri servizi
sparisce da un elenco filtrato anche se li ha tutti.

### Distributori autostradali

I distributori autostradali sono di norma il carburante più caro del
paese: escluderli è il filtro che più spesso cambia quanto paghi.
Tienili quando non puoi lasciare l'autostrada.

### Salvare come miei valori predefiniti

Scrive questi criteri nel tuo profilo, così ogni ricerca successiva parte
da qui e non dai valori dell'app. È l'impostazione che rende il foglio
una conferma in un tocco anziché un modulo.

### Come funziona davvero

Una ricerca nelle vicinanze invia **le tue coordinate (o un codice di regione) e un raggio** al fornitore ufficiale del tuo paese — mai la tua identità. I paesi che pubblicano un file giornaliero (Spagna, Italia) sono filtrati sul dispositivo: quelle ricerche non richiedono alcuna chiamata di rete una volta messo in cache il file.

---

## Leggere una scheda di risultato

*Tutto ciò che serve per decidere, senza aprire nulla.*

- **Prezzo** — per il carburante cercato, nella convenzione del tuo paese (nota il decimo di centesimo in apice).
- **Freccia di tendenza** ▲▼▬ — dove sta andando il prezzo di questa stazione, dal *tuo* storico locale.
- **★** — tocca per aggiungere ai preferiti; piena = già salvata.
- **Chip dei servizi** — negozio, autolavaggio, aria, bancomat, come dichiarati.
- **Distanza** — in linea d'aria dalla tua posizione.
- **« Aggiornato 31/08 00:01 »** — il timbro di freschezza. **Leggilo prima del prezzo.**
- **Riga di ordinamento** — Distanza / Prezzo / A–Z / 24 h, più un chip di avviso quando il prezzo più recente dell'elenco supera l'ora.

### La freschezza, più importante del prezzo

| Badge | Età | Cosa fare |
|---|---|---|
| Verde | < 5 min | Fidati |
| Giallo | 5–30 min | Va bene per decidere |
| Arancione | ore | Plausibile; il fornitore potrebbe pubblicare lentamente |
| Bordo rosso | > 1 giorno | Trattalo come indicativo — aggiorna prima di deviare |

La freschezza è una proprietà del **fornitore del paese**, non dell'app. Un prezzo spagnolo di 14 ore non è un bug: quel paese pubblica una volta al giorno. Vedi Come funziona Sparkilo → Una fonte per paese.

### Gesti di scorrimento

- **Scorri a destra** — apri nella tua app di navigazione (Google Maps, Waze, OsmAnd, Organic Maps).
- **Scorri a sinistra** — nascondi la stazione da tutti i risultati futuri. Si ripristina da **Privacy e dati → Dati su questo dispositivo → Stazioni ignorate**.

---

## Dettaglio di una stazione

*Tocca una scheda. L'intestazione ripiega da marca a nome a via, così un Intermarché senza campo marca mostra comunque « Intermarché ».*

Il blocco superiore è la **tabella completa dei prezzi** — ogni qualità che il fornitore pubblica per quella stazione, con `--` dove non ne pubblica. È il modo più rapido di vedere se la stazione E85 conveniente regge anche sul diesel.

**Aggiungi rifornimento** precompila stazione, carburante e prezzo nel modulo — il maggior risparmio di tempo dell'app se registri i tuoi rifornimenti.

*Più in basso: servizi, metodi di pagamento accettati, la tua valutazione privata a stelle, e lo storico locale dei prezzi a 30 giorni.*

Le azioni della barra superiore sono, da sinistra a destra: **creare un avviso di prezzo**, **scansionare un QR di pagamento**, **segnalare un prezzo errato** e **aggiungere ai preferiti**.

---

## La mappa

*Il colore è relativo a ciò che è a schermo: verde la più economica visibile, rosso la più cara. Il piè di pagina indica numero di stazioni, raggio ed età dei dati.*

- **I cluster** raggruppano i segnaposto allo zoom indietro; un tocco ingrandisce.
- **Pressione prolungata** ovunque per lasciare un marcatore e cercare da lì.
- Il **selettore EV** in alto a destra passa alle colonnine — vedi Ricarica elettrica.
- **Condividi** invia la vista corrente a qualcuno.

Le tessere vengono da OpenStreetMap. Per impostazione predefinita passano dal proxy UE dello sviluppatore così che OpenStreetMap non veda mai il tuo IP; puoi disattivare il proxy in Impostazioni → Privacy e dati e caricare direttamente. La build F-Droid non usa mai il proxy.

---

## Il radar stazioni di servizio

Una scansione in tempo reale attorno alla tua posizione, pensata per **guidare**.

*Dopo ogni ricerca nelle vicinanze appare una pillola flottante in basso a destra. Un tocco avvia il radar.*

### Come funziona davvero

Il radar aggiorna la posizione GPS, recupera le **posizioni** delle stazioni su un ampio corridoio di 60 km e fonde una richiesta diretta nel raggio: non può quindi mai mostrare meno di una ricerca normale. Le stazioni non si spostano, perciò quelle posizioni restano in cache fino a un'ora e vengono riusate; solo il **prezzo** di una stazione a cui ti stai avvicinando viene recuperato al momento giusto. È questo che rende un radar sempre acceso poco costoso in dati e batteria.

*Attivo: risultati ordinati per distanza, ciascuno con una barra che si riempie all'avvicinarsi.*

### Durante la registrazione di un viaggio

Il radar fissa una scheda **Stazione più vicina** in cima alla schermata di registrazione — nome, prezzo per il tuo carburante, distanza, e una barra che arriva al 100 % all'arrivo. Scorri a destra/sinistra per sfogliare le candidate. Entrando nel raggio di avvicinamento configurato, la miniatura in sovrimpressione passa a una grande visualizzazione del prezzo; vedi Viaggi ed eco-coaching → L'overlay di avvicinamento.

### Impostazioni che ne cambiano il comportamento

Tutte in **Impostazioni → Guida e consumo**: il **raggio** a cui l'overlay si ingrandisce, se mostra la stazione **più vicina** o la **più economica del raggio**, l'**intervallo minimo di aggiornamento** (un limite inferiore, non una cadenza fissa — interroga più spesso ad alta velocità ma mai più stretto di così) e il **fissaggio automatico**, che tiene lo schermo acceso e nasconde le barre di sistema per un supporto da cruscotto, a costo di batteria.

---

## Il calcolatore del costo del carburante

Tre numeri in entrata — distanza, il tuo consumo, il prezzo — e in uscita litri bruciati, costo totale e costo al chilometro. Precompila consumo e prezzo dai tuoi dati, così spesso digiti solo la distanza.

Risponde onestamente a una sola domanda: *la stazione 12 km più lontana è davvero più economica una volta arrivato?*

---

## Widget nella schermata Home

- Mostra il tuo preferito più economico (o la stazione più vicina) e il suo prezzo.
- **Tocca il widget** → apre il dettaglio di quella stazione, che l'app fosse viva o chiusa.
- **Tocca l'icona di aggiornamento** → ricarica i prezzi in background senza aprire l'app.
- Aggiornamento di fondo ogni 30 min in carica, ogni ora altrimenti, rispettando la modalità Doze.

Aspetto e variante di contenuto (*prezzo attuale* o *predittivo: momento migliore per il pieno*) si impostano per profilo in **Impostazioni → Unità e visualizzazione → Widget schermata Home**.

---

## Android Auto

Collegata a un'unità Android Auto, l'app offre due schermate sicure alla guida: **Cerca** (le stazioni dell'ultima ricerca fatta sul telefono) e **Radar** (le più economiche lungo il percorso). Avvia prima la ricerca sul telefono — il lato auto è di proposito in sola lettura, perché non esiste modo sicuro di digitare mentre si guida. Solo Android; non c'è una versione CarPlay.

---

<details>
<summary>Vista d'insieme — dettaglio stazione, pagina intera</summary>

</details>

---

**Vedi anche:** Pianificazione itinerario · Preferiti e avvisi · Storico prezzi
**Avanti:** Pianificazione itinerario →

---

# Pianificazione itinerario

Non « il più economico vicino a me » ma **il più economico sulla strada** — la differenza vale diversi euro su ogni viaggio lungo.

---

## Avviare una ricerca su itinerario

*Tocca **Cerca** → passa a **Cerca lungo l'itinerario**. Il pulsante resta disattivato finché non ci sono destinazione e carburante.*

| Campo | Significato |
|---|---|
| **Partenza** | La tua posizione attuale, o una città / un CAP digitati |
| **Aggiungi una tappa** | Punti intermedi — il corridoio li segue |
| **Destinazione** | Città, CAP o coordinate |
| **Carburante** | La qualità quotata lungo il corridoio |
| **Segmento di percorso** | Mostra la stazione più economica ogni *n* km (50–1000 km) |
| **Deviazione massima** | Quanto lontano dalla linea diretta può stare una stazione |
| **Risparmio minimo** | Nasconde le soste che non battono la media del corridoio di almeno questo importo; *Disattivato* mostra tutto |

*Gli stessi filtri di apertura, servizi e marche di una ricerca nelle vicinanze valgono per il corridoio.*

### Come funziona davvero

1. L'app chiama il servizio pubblico di instradamento **OSRM** e ottiene la polilinea stradale del percorso.
2. Colloca punti candidati lungo quella linea, distanziati secondo il **segmento di percorso**.
3. Attorno a ciascun punto interroga il fornitore di prezzi **del paese in cui si trova quel punto**, con la qualità presa dal profilo di quel paese.
4. Ordina le candidate di ogni segmento secondo la strategia scelta e il limite di **deviazione massima**.

### Cosa cambia in pratica

- **La lunghezza del segmento è il vero comando.** 50 km su 600 km dà dodici liste; 200 km ne dà tre. Scegli in base a quanto spesso ti fermi davvero.
- **La deviazione massima si misura dall'itinerario diretto**, non da te. 5 km significa « fino a 5 km di strada in più ».
- **I percorsi lunghi richiedono più tempo.** Un corridoio di 600 km campiona molti punti, forse su più fornitori.
- Se la partenza è « GPS automatico » e il segnale cade, la ricerca ripiega sull'ultima posizione nota.

---

## Corridoi transfrontalieri

Quando un percorso attraversa un confine, **ogni paese del corridoio è interrogato tramite il proprio fornitore**, e l'intestazione li cita tutti:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Poiché le qualità differiscono per paese, un risultato transfrontaliero mostra legittimamente E85 sul tratto francese e Gasolina 95/E5 su quello spagnolo. Ciascuno è quotato correttamente per il suo lato, mai mediato.

**Serve un profilo per paese** con la qualità preferita giusta, altrimenti il secondo tratto non ha nulla da quotare e mostra `--`. Vedi Come funziona Sparkilo → Profili.

---

## I risultati arrivano progressivamente

Un'API nazionale lenta non deve bloccare il resto del corridoio: i risultati arrivano **man mano**, con le stazioni di ciascun paese che compaiono appena quel fornitore risponde e un banner che nomina le fonti ancora attese. Puoi toccare un risultato conveniente appena arriva.

---

## Le quattro strategie

### 🏆 Soste migliori *(predefinita)*
Porta in cima le 3–5 stazioni più economiche realisticamente raggiungibili come chip ordinati. Le deviazioni restano brevi. È ciò che vuole la maggior parte dei guidatori.

### 🎯 La più economica
L'unica stazione col prezzo più basso dell'intero percorso. Ideale quando fai un solo pieno e vuoi il massimo risparmio al litro.

### ⚖️ Bilanciata
Valuta ogni candidata su prezzo *e* vicinanza alla linea. Una stazione a 5 km ma 10 cent/L più economica vince; una a 50 km deve essere molto più economica.

### 📏 Uniforme
Divide il percorso in segmenti uguali e propone una sosta per segmento. Ideale per lunghi viaggi transfrontalieri con più rifornimenti.

Strategia predefinita, lunghezza di segmento, deviazione massima, risparmio minimo e numero di candidate per punto di campionamento sono memorizzati **per profilo**:

*Impostazioni → Profili e regione → modifica → Pianificazione itinerario. Da impostare una volta qui invece di ritoccare il foglio a ogni viaggio.*

---

## Leggere i risultati

Ogni riga aggiunge due numeri che una ricerca nelle vicinanze non ha:

- **Distanza dalla partenza** — dove si trova la stazione sul percorso, per farla coincidere col momento in cui il serbatoio sarà basso.
- **Deviazione** — i chilometri in più rispetto alla linea diretta.
- **Risparmio rispetto alla media** — sulla media del corridoio, non su una nazionale.

Passa a **Tutte le stazioni** per vedere ogni stazione lungo il percorso invece della selezione. La mappa traccia la polilinea con tutti i segnaposto.

---

## Evitare le autostrade

**Impostazioni → Profili e regione → Visualizzazione e stazioni → Evita le autostrade** fa preferire le strade secondarie. Questo cambia la *polilinea*, quindi quali stazioni sono candidate: le aree di servizio autostradali scompaiono dal corridoio invece di essere solo declassate. Utile proprio perché il carburante autostradale è di norma il più caro di qualsiasi itinerario.

---

## Itinerari salvati

Tocca **Salva itinerario** nella schermata dei risultati. Gli itinerari salvati appaiono in cima al modulo; un tocco riesegue lo stesso corridoio con **prezzi freschi**. Viene salvata la geometria, non i prezzi.

---

**Vedi anche:** Trovare stazioni · Riferimento impostazioni
**Avanti:** Preferiti e avvisi →

---

# Ricarica elettrica

Sparkilo non è solo per i motori termici. Le colonnine vengono da [OpenChargeMap](https://openchargemap.org), il più grande registro comunitario aperto al mondo.

---

## Attivare

Due interruttori indipendenti, entrambi in **Impostazioni → Funzioni e modalità d'uso → Ricerca e mappa**:

- **Ricarica EV** — la funzione stessa (ricerca, pagine di dettaglio, preferiti).
- **Mostra le colonnine di ricarica** — se le colonnine compaiono nei risultati e sulla mappa.

*Puoi mostrare stazioni, colonnine, o entrambe. Chi guida solo elettrico di solito disattiva **Mostra le stazioni di servizio**.*

Poi crea un veicolo in **Impostazioni → Veicoli e OBD2 → I miei veicoli → Aggiungi**, scegliendo **Elettrico** come motorizzazione. Un veicolo elettrico porta capacità della batteria (kWh), potenze massime di ricarica AC e DC (kW) e i connettori supportati (Tipo 2, CCS, CHAdeMO, Tesla, Schuko, Tipo 1, presa domestica). Le ricerche si limitano allora alle colonnine che la tua auto può davvero usare.

---

## Come funzionano i dati

*Impostazioni → Fonti dati e posizione. Il campo **Ricarica EV (OpenChargeMap)** contiene già una chiave condivisa: la ricarica funziona senza configurazione.*

L'app interroga in tempo reale l'API POI di OpenChargeMap per l'area che stai guardando, e mette il risultato in cache perché sopravviva offline.

### Perché prendere una chiave propria

La chiave integrata è condivisa da tutti gli utenti di Sparkilo ed è quindi limitata come un fondo comune. Una chiave personale ti dà la tua quota e permette a OpenChargeMap di vedere un uso reale dei suoi dati. È gratuita:

1. Registrati su [openchargemap.org](https://openchargemap.org).
2. Apri **My Profile → My Apps**.
3. **Register an Application**, descrivi brevemente, e la chiave API (un UUID) viene emessa subito.

Incollala nel campo Ricarica EV. Sta nella stessa cassaforte hardware della chiave prezzi tedesca, non lascia mai il dispositivo ed è inviata solo a OpenChargeMap. Svuota il campo per tornare alla chiave condivisa.

### Il ripiego che sembra un bug

Se OpenChargeMap è del tutto irraggiungibile, l'app disegna un piccolo **set di dati dimostrativo integrato** invece di una mappa vuota. Se vedi la stessa manciata di colonnine generiche in ogni città, è quel ripiego che ti dice che la richiesta è fallita — controlla connessione o chiave, e non fidarti di quei segnaposto.

### Contribuire

OpenChargeMap è mantenuta dalla comunità. Una colonnina mancante o sbagliata si corregge su [openchargemap.org](https://openchargemap.org), non in questa app — e la correzione raggiunge poi ogni app basata su OCM, questa compresa, alla richiesta successiva.

---

## Cercare

*Il selettore EV nella barra della mappa fa passare i segnaposto dal carburante alla ricarica. Il colore segue la potenza: azzurro in AC, blu scuro in DC.*

Nel foglio dei criteri scegli il tipo **EV** e avvia una ricerca per raggio. Filtri disponibili: tipi di connettore, kW minimi, e solo le colonnine attualmente libere dove l'operatore pubblica lo stato in tempo reale.

---

## La pagina di dettaglio di una colonnina

- **Connettori** — tipo, quantità e potenza massima di ciascuno
- **Tariffa** — al kWh quando l'operatore la pubblica (molti non lo fanno)
- **Rete** — Ionity, Fastned, Tesla…
- **Disponibilità** — in tempo reale quando dichiarata
- **Servizi** — ristorazione, servizi igienici, negozi (contano di più se resti fermo 30 minuti)
- **Orari** — 24/7 o secondo l'operatore
- **Recensioni** — dai contributori OpenChargeMap

---

## Preferiti e registrazione

Le colonnine si mettono tra i preferiti come le stazioni; in orizzontale e su tablet preferiti e avvisi appaiono affiancati. La scheda preferita mostra i **kW per connettore**, **quanti sono liberi** e i **tipi di connettore**.

Gli avvisi di prezzo servono a poco per la ricarica, dato che la maggior parte degli operatori applica tariffe forfettarie al kWh. Le sessioni di ricarica si registrano come rifornimenti: **scheda Carburante → Aggiungi**, con kWh al posto dei litri — alimentano le stesse statistiche di costo al chilometro dei rifornimenti termici.

---

## Attraversare i confini

Sulla ricarica non esiste di proposito **alcun filtro per paese**. Andando dalla Germania alla Francia vedi entrambe le infrastrutture sulla stessa mappa. I prezzi dei carburanti sono dataset nazionali; la ricarica è un unico dataset mondiale, quindi la regola « un profilo per paese » qui non si applica.

---

**Vedi anche:** Trovare stazioni · Registro rifornimenti e consumi
**Avanti:** Veicoli e OBD2 →

---

# Preferiti e avvisi di prezzo

La scheda ⭐ è la tua rosa di stazioni, più i robot che la sorvegliano per te.

---

## Preferiti

*Due schede in alto: **Preferiti** e **Avvisi di prezzo**. Ogni scheda riporta tutte le qualità dichiarate, non solo la tua.*

Segna una stazione con la ★ su una scheda di risultato o sul suo dettaglio.

### Cosa viene davvero salvato

Un preferito non è un segnalibro, è una **copia locale completa** della stazione: identificativo, indirizzo, servizi, metodi di pagamento, orari e gli ultimi prezzi visti. Per questo la scheda funziona senza rete: vedi gli ultimi prezzi noti, chiaramente marcati dal loro timbro di freschezza.

### Cosa cambia in pratica

- **I preferiti funzionano offline**, le ricerche no. Prima di un viaggio in zona senza copertura, apri la scheda una volta in Wi-Fi.
- I prezzi si aggiornano all'apertura della scheda, non di continuo.
- I preferiti sono tra le categorie che **TankSync** replica tra i tuoi dispositivi, se lo attivi.

### Ordinamento e gesti

Ordina per prezzo (più economico prima, predefinito), distanza o alfabeticamente. **Scorri a destra** apre la navigazione; **scorri a sinistra** rimuove il preferito, con annullamento.

### Colonnine di ricarica

Anche le colonnine si possono mettere tra i preferiti, e la scheda mostra ciò che serve a chi guida elettrico: **potenza per connettore in kW**, quanti sono **liberi adesso**, e i **tipi di connettore**.

### Orizzontale e tablet

Su telefoni in orizzontale e su qualsiasi schermo oltre 600 dp, preferiti e avvisi appaiono **affiancati** con un separatore invece che dietro un selettore di schede. Essendo entrambi visibili, in quel layout non c'è alcun selettore.

---

## Avvisi di prezzo

*Tre contatori in alto — regole attive, scatti oggi e questa settimana — poi i due tipi di avviso. Il piè di pagina data l'ultimo controllo in background.*

Ce ne sono due tipi, che rispondono a domande diverse.

### Avviso di stazione — « avvisami quando *questa* pompa cala »

Creato dalla pagina di dettaglio di una stazione (icona campanella). Scegli il carburante, fissa una soglia, salva. Ideale per la stazione che già usi.

### Avviso di zona — « avvisami quando *qui intorno* cala »

*Impostazioni → Prezzi e avvisi → Avvisi di prezzo → **Crea un avviso di zona**.*

| Campo | Cosa fa |
|---|---|
| **Etichetta** | Testo libero perché un elenco di avvisi resti leggibile (« Diesel casa ») |
| **Tipo di carburante** | Una qualità per avviso — una stazione può avere più avvisi |
| **Soglia (€/L)** | Scatta quando una stazione della zona scende **sotto** |
| **Raggio (km)** | L'area sorvegliata attorno al punto centrale |
| **Frequenza di controllo** | Ogni quanto l'attività di fondo guarda — vedi sotto |
| **La mia posizione / Scegli sulla mappa / CAP** | Tre modi di fissare il centro; un CAP non tocca mai il GPS |

Ideale per « avvisami quando il diesel scende sotto 1,60 € entro 5 km da casa », quando la stazione precisa non conta.

---

## Come funziona davvero il controllo

Un'attività di fondo pianificata dal sistema si sveglia e:

1. Recupera i prezzi in tempo reale delle stazioni coinvolte.
2. Confronta ciascuno con la sua soglia.
3. Fa scattare una **notifica locale** se un prezzo è sotto. Il tocco apre la stazione.

La cadenza è **ogni 30 minuti in carica, ogni ora altrimenti**, e solo con connessione. La tua frequenza per avviso è un tetto al suo interno: « una volta al giorno » fa saltare l'avviso quasi sempre.

### Cosa cambia in pratica

- **Gli avvisi sono al meglio possibile, non in tempo reale.** È il sistema a decidere quando l'attività gira; i risparmi energetici aggressivi la ritardano o la uccidono. Se l'orario conta, escludi l'app dall'ottimizzazione batteria.
- **Non viene usato alcun GPS.** Gli avvisi lavorano sulle coordinate memorizzate delle stazioni: un avviso attorno a casa continua a funzionare anche a 500 km di distanza.
- **Il costo in batteria è trascurabile** — pochi KB per risveglio, in una finestra gestita dal sistema, compatibile con Doze. Ben sotto lo 0,5 % al giorno.
- **Un effetto collaterale utile:** lo stesso controllo scrive un rilevamento di prezzo nel tuo storico locale. Una stazione sotto avviso costruisce quindi il suo storico a 30 giorni in ore anziché settimane — ed è ciò che fa comparire in fretta il banner *momento migliore per il pieno*. Vedi Storico prezzi.
- **Se le notifiche sono spente a livello di sistema**, l'interruttore dell'app non può far scattare nulla.

---

## Statistiche

I contatori in alto mostrano quante regole sono attive e quante volte sono scattate oggi e questa settimana — un test rapido per capire se l'attività di fondo gira davvero. Una fila di zeri con più avvisi attivi e un timbro « ultimo controllo » vecchio è il sintomo classico di un risparmio energetico che uccide l'attività.

---

## Fermare gli avvisi

Disattivare un avviso lo mette in pausa senza perdere la regola; scorrere a sinistra lo elimina. Togliere la stazione dai preferiti **non** elimina i suoi avvisi.

---

**Vedi anche:** Storico e previsioni prezzi · Riferimento impostazioni → Prezzi e avvisi
**Avanti:** Ricarica elettrica →

---

# Storico e previsioni prezzi

L'app costruisce un quadro **privato e locale** di come si muovono i prezzi attorno a te, e ne ricava una raccomandazione onesta.

---

## Cosa viene registrato, e dove

Ogni volta che il prezzo di una stazione passa per l'app — una ricerca, un aggiornamento dei preferiti o un controllo avvisi in background — l'app scrive **sul tuo telefono** un rilevamento: stazione, carburante, prezzo, orario. Nulla viene caricato, e i dati di nessun altro vengono scaricati.

- **Deduplicato a un rilevamento per stazione all'ora.** Cinque ricerche in dieci minuti danno una voce.
- **Conservato 30 giorni.** I rilevamenti più vecchi sono eliminati automaticamente.
- **Abilitato da** *Funzioni e modalità d'uso → Prezzi e avvisi → Storico prezzi*. Spento, non viene scritto alcun rilevamento.

*Impostazioni → Prezzi e avvisi. Lo **storico prezzi** è il prerequisito della previsione sottostante — senza storico non ha nulla su cui lavorare.*

---

## Consultare lo storico di una stazione

Apri la pagina di dettaglio di una stazione e scorri fino a **Storico prezzi**:

- **Grafico orario** — prezzo medio per ogni ora del giorno negli ultimi 30 giorni.
- **Grafico per giorno della settimana** — media per giorno.
- **Min / max / media / tendenza** in sintesi.

L'ora o il giorno più economico è evidenziato in verde, il più caro in rosso.

---

## « Momento migliore per fare rifornimento »

Appena c'è abbastanza storico, la stazione mostra un banner:

> 💡 **I prezzi di solito calano il martedì 18:00–20:00** — risparmi ~3,2 cent/L

### Cos'è — e cosa non è

È un **riassunto di ciò che è già accaduto in quella stazione negli ultimi 30 giorni**, nei *tuoi* dati. Volutamente **non** è:

- una previsione del prezzo di domani,
- consapevole del mercato petrolifero, della fiscalità o del meteo,
- costruito con i dati di altri utenti.

Questa sobrietà è il punto. Un rincaro regionale del lunedì mattina è uno schema locale reale e ripetibile su cui si può agire; una previsione di mercato fatta da un telefono no.

### La fase di apprendimento

Il banner resta nascosto finché non ci sono almeno **10 rilevamenti per quella stazione negli ultimi 30 giorni**. La durata dipende solo da quanto spesso il prezzo passa per l'app:

| Situazione | Tempo fino al banner |
|---|---|
| La stazione ha un **avviso di prezzo** | Poche ore — il controllo di fondo rileva ogni 30–60 min |
| La stazione è un **preferito** aperto ogni giorno | Una decina di giorni |
| Né l'uno né l'altro — ricerche occasionali | Settimane, forse mai |

**Il trucco pratico:** metti un avviso sulla stazione che usi davvero. L'avviso rende doppiamente — ti segnala il calo e riempie lo storico che produce la raccomandazione.

### Perché il tuo preferito non ha ancora il banner

1. **Non abbastanza rilevamenti** (vedi sopra).
2. **Il prezzo si è mosso appena.** Se l'escursione su 30 giorni è sotto 0,1 cent/L non c'è nulla su cui agire, quindi non viene mostrato nulla.
3. **Solo un carburante ha campioni.** La soglia vale per tipo di carburante, non per stazione.

---

## Previsione di prezzo sul dispositivo

*Funzioni e modalità d'uso → Prezzi e avvisi → **Momento migliore per il pieno*** attiva un piccolo modello TensorFlow Lite che gira **interamente sul dispositivo**. Le sue caratteristiche e le sue previsioni non lasciano mai il telefono. È ciò che alimenta la variante *predittiva* del widget nella schermata Home (**Impostazioni → Unità e visualizzazione → Widget schermata Home → Variante di contenuto**), che mostra il momento migliore per fare il pieno invece del solo prezzo attuale.

Se preferisci che non venga inferito nulla, disattivalo: storico e banner di schema continuano a funzionare.

---

## Segnalazioni di prezzo della comunità

*Funzioni e modalità d'uso → Prezzi e avvisi → **Segnalazioni di prezzo della comunità*** aggiunge un'azione di segnalazione al dettaglio della stazione, per correggere un prezzo che la fonte ufficiale ha sbagliato. Le segnalazioni finiscono nel database TankSync condiviso sotto il tuo account pseudonimo e sono visibili agli altri utenti connessi — è quindi l'unica funzione di prezzo **non** puramente locale. Richiede TankSync ed è spenta finché non la attivi.

---

## Esportare

**Impostazioni → Privacy e dati → Esporta o elimina → Esporta i miei dati → CSV** scrive un CSV — la sua tabella dello storico prezzi contiene stazione, carburante, prezzo, orario — nella tua cartella Download pubblica.

---

**Vedi anche:** Preferiti e avvisi · Trovare stazioni → La freschezza
**Avanti:** Riferimento impostazioni →

---

# Registro rifornimenti e consumi

Livelli 2 e 3 dei tre livelli di risparmio: quanto bruci, e quanto è costato davvero. La scheda ⛽ **Carburante** compare nelle modalità **Medio** e **Completo**.

---

## La scheda Carburante a colpo d'occhio

*Tre blocchi: cosa c'è nel serbatoio, quanto costa la tua guida, e cosa hai davvero messo.*

### Livello del serbatoio e autonomia

L'indicatore è **ancorato all'ultimo pieno**, poi decurtato del carburante consumato dai viaggi registrati. Il timbro sotto la barra indica a quale rifornimento è ancorato.

Vengono mostrate due autonomie di proposito:

- **« ≈ 548 km al consumo del tuo ultimo pieno »** — il comportamento recente, utile oggi.
- **« Media a lungo termine: ≈ 611 km »** — la tua media storica, utile per pianificare.

Se divergono molto, qualcosa è cambiato di recente: un box da tetto, l'inverno, un diverso mix di strade, o un cambio di carburante.

> Quando un adattatore OBD2 è collegato e l'auto pubblica il PID di livello carburante, l'indicatore passa al **sensore del serbatoio** e lo dichiara. Quel valore è una misura, non una deduzione, e sopravvive ai viaggi non registrati.

### La scheda delle statistiche

I tre badge sono lo strato di onestà:

| Badge | Significato |
|---|---|
| **Precisione: Alta · ±3-7 %** | Rifornimenti e viaggi OBD2 alimentano entrambi il modello |
| **Precisione: Media** | I rifornimenti lo ancorano, ma nessun viaggio OBD2 ha ancora alimentato il ciclo |
| **Precisione: Bassa** | Solo GPS, nulla ancorato — aggiungi un paio di pieni |
| **η_v : 0,93 · 6 campioni** | Il rendimento volumetrico appreso del modello speed-density e i suoi campioni |

Sotto: media L/100 km, costo medio al km, litri totali, spesa totale, numero di rifornimenti. Un tocco apre le [statistiche complete](#statistiche-consumi).

---

## Registrare un rifornimento

Tocca **➕ Aggiungi rifornimento** — oppure, molto più rapido: **Aggiungi rifornimento** direttamente sulla pagina di dettaglio di una stazione, che precompila stazione, carburante e prezzo.

*Partendo da una stazione, tre campi sono già giusti — digiti litri, totale e contachilometri.*

| Campo | Perché conta |
|---|---|
| **Data** | Ordina le finestre di serbatoio |
| **Veicolo** | Attribuisce il rifornimento e la calibrazione |
| **Tipo di carburante** | Su una flex-fuel tutto il confronto dipende da questo campo |
| **Litri** | Il numeratore della verità della pompa |
| **Costo totale** | Costo al km, spesa mensile |
| **Contachilometri** | **Il campo più importante del modulo** |
| **Pieno** | Chiude una finestra di calibrazione — vedi sotto |
| Stazione, note | Facoltativi |

### Perché il contachilometri è il campo critico

Il consumo è litri ÷ chilometri. I litri vengono dallo scontrino e sono esatti. I chilometri vengono dalle *tue due letture del contachilometri*. Un errore di 20 km su un serbatoio di 600 km è un 3 % di errore — e poiché quel risultato ricalibra lo stimatore, l'errore si propaga a ogni stima futura. Il modulo rifiuta un contachilometri inferiore a quello del rifornimento precedente, perché la distanza non torna indietro.

### La casella « Pieno »

Spuntala ogni volta che riempi fino all'orlo. È ciò che trasforma due rifornimenti in una **finestra chiusa** con un consumo fisicamente vero.

I rifornimenti parziali vengono comunque registrati, contano per il costo e restano nell'elenco — semplicemente non possono chiudere una finestra. La schermata di statistiche mostra un banner che conta i *« rifornimenti parziali in attesa di un pieno — non nella media »*, così sai sempre cosa c'è nei numeri.

### Scansionare invece di digitare

- **Scansiona il display della pompa** — punta la fotocamera sul display; l'app legge litri, totale e prezzo.
- **Scansiona lo scontrino** — lo stesso dal foglietto stampato.
- **Condividi una foto di scontrino** da un'altra app direttamente nel modulo.

Il riconoscimento gira **sul dispositivo**; l'immagine non viene mai caricata. Dai sempre un'occhiata ai valori prima di salvare — una scansione è un vantaggio, non un oracolo. In caso di errore, *Segnala errore di scansione* apre una segnalazione col ritaglio per migliorare il riconoscimento.

> **Build F-Droid:** il riconoscimento di testo sul dispositivo esiste solo nelle build Play / App Store. La build F-Droid priva di GMS non ha la scansione — lì i rifornimenti si digitano a mano. Tutto il resto è identico.

---

## Il rapporto del pieno — il momento della verità

Ogni volta che un pieno si chiude, l'app pubblica un rapporto. Nella scheda Viaggi appare così:

*Una scheda, quattro affermazioni diverse — e volutamente non sono lo stesso numero.*

| Riga | Cos'è |
|---|---|
| **6,4 L/100 km** | La **verità della pompa** di questo serbatoio: litri erogati ÷ chilometri contachilometri |
| **1,5 L/100 km in meno del pieno precedente** | Tendenza rispetto all'ultimo serbatoio chiuso |
| **559 km · 35,7 L · 32,12 €** | La finestra grezza |
| **Le registrazioni coprono l'81 % di questo pieno** | Quanta parte di quei chilometri hai davvero registrato |
| **Quota registrata: 10,5 L/100 km** | Cosa hanno dato da soli i chilometri registrati |
| **Le stime registrate sono del 39 % sopra la verità della pompa** | Il verdetto di calibrazione — lo stimatore leggeva alto ed è stato appena corretto |

### Leggerlo correttamente

La quota registrata e la verità della pompa **possono differire**, per due motivi distinti che è facile confondere:

1. **La selezione.** Registri i viaggi che registri. Se il tuo 81 % è per lo più urbano breve e il 19 % mancante è un tratto autostradale, la quota registrata è legittimamente più alta della media del serbatoio. Nulla è rotto.
2. **La calibrazione.** Lo stimatore stesso può essere distorto. È ciò che misura l'ultima riga, confrontando i due **per chilometro**, così la copertura si annulla e determina solo il peso della finestra.

Dopo una correzione come questa, aspettati che le stime di viaggio scendano nettamente al prossimo viaggio e poi si assestino. Il meccanismo completo: Come funziona Sparkilo → Come un litro diventa un numero.

La scheda può anche indicare *cosa è cambiato* — quota di alto regime, eventi bruschi ogni 100 km, avviamenti a freddo, quota di minimo, ciascuno rispetto al serbatoio precedente — con la riserva esplicita che le registrazioni sono spontanee e coprono solo parte del serbatoio.

---

## Statistiche consumi

Tocca la scheda delle statistiche, o **Carburante → Statistiche consumi**.

*I chip in alto restringono tutto ciò che segue a un carburante — indispensabile su una flex-fuel, dove una media combinata non significa nulla.*

La tabella mensile mostra litri, spesa, prezzo medio al litro, consumo medio, costo al km e numero di rifornimenti, ciascuno col suo scarto. Le frecce rosse non sono un giudizio — una *spesa* in aumento dopo un *prezzo al litro* in aumento è il mercato, non il tuo piede destro. Il numero da guardare per la guida è **L/100 km**.

### Costo al chilometro per carburante

*La vera domanda di chi guida flex-fuel, risolta: non quale carburante costa meno al litro, ma quale costa meno al chilometro.*

Ogni carburante ha una riga costruita solo su **finestre di serbatoio chiuse**: L/100 km misurati, prezzo effettivamente pagato al litro, costo ogni 100 km, spesa totale, distanza misurata, litri consumati, CO₂ ogni 100 km, e quanti pieni ci sono dietro. Una riga basata su un solo serbatoio è marcata **Provvisoria**.

*La scheda di verdetto annuncia il vincitore, il divario ogni 1000 km e — la cosa più utile — il **prezzo di pareggio**.*

La riga di pareggio (« E5 diventa più conveniente di E85 sotto 0,75 €/L ») è calcolata dal **tuo consumo misurato di ciascun carburante**: si sposta quindi con la tua guida. È una regola decisionale utilizzabile alla pompa; un rapporto generico trovato in rete no.

I valori di CO₂ sono stime dal pozzo alla ruota (EU JEC WTW v5) applicate al tuo consumo misurato — consapevolezza, non contabilità certificata. Le miscele sono escluse dal CO₂ perché il fattore di emissione dipende dalla miscela, che la riga non registra.

*I grafici di tendenza impilano per carburante: un cambio appare come un colore che ne sostituisce un altro, non come un salto misterioso.*

*Prezzo al litro e L/100 km sono di proposito due grafici distinti — uno è il mercato, l'altro sei tu.*

**Esporta** scrive tutto in CSV nella tua cartella Download pubblica.

---

## Eco-punteggio per rifornimento

Ogni rifornimento riceve un badge confrontato con la media mobile dei tuoi ultimi tre rifornimenti dello stesso carburante:

| Scarto | Badge | Come leggerlo |
|---|---|---|
| ≥ 3 % meglio | 🟢 In miglioramento | Nettamente meno del tuo riferimento |
| entro ±3 % | ⚪ Stabile | Variazione normale |
| ≥ 3 % peggio | 🟠 In peggioramento | Controlla pressione gomme, box da tetto, freddo, mix di strade |

Il badge resta nascosto finché non hai quattro rifornimenti di quel carburante, perché il riferimento sia reale.

---

## Quando i conti non tornano

Prima o poi metterai più litri di quanti i viaggi registrati possano spiegare — ha guidato qualcun altro, l'adattatore era staccato, l'app chiusa. Invece di assorbire la differenza in silenzio, l'app mostra un **banner di scarto** e propone una breve riconciliazione:

> *Abbiamo trovato uno scarto di 4,2 L. Hai erogato 35,7 L, ma i tuoi viaggi registrati ne spiegano solo 31,5 L.*

Fa due domande:

1. **Tutti i rifornimenti di questo serbatoio sono completi e corretti?** — No significa che ne manca uno o è mal digitato, e l'app aggiunge un **rifornimento di correzione** perché i litri tornino.
2. **Tutti i tuoi viaggi sono registrati?** — No significa che un viaggio manca, e l'app aggiunge un **viaggio virtuale** per la distanza mancante.

Entrambi gli artefatti sono poi modificabili ed eliminabili, ed entrambi sono marcati come generati automaticamente perché non li si confonda mai con dati reali. Puoi anche scegliere **Decidi più tardi** — il banner resta finché non risolvi.

**Perché conta:** uno scarto irrisolto distorce silenziosamente la finestra di calibrazione. Risolverlo (o eliminare la voce sbagliata) mantiene affidabile l'ancoraggio alla pompa.

---

## Carte fedeltà

**Impostazioni → Guida e consumo → Carte fedeltà** memorizza gli sconti al litro delle catene che usi. Lo sconto viene poi applicato nei confronti di prezzo, così una stazione apparentemente più cara di 2 cent/L può correttamente risultare la più economica per te. La funzione si attiva in Funzioni e modalità d'uso → Inserimento e scansione.

---

<details>
<summary>Vista d'insieme — statistiche consumi, pagina intera</summary>

</details>

---

**Vedi anche:** Veicoli e OBD2 · Viaggi ed eco-coaching
**Avanti:** Viaggi ed eco-coaching →

---

# Carburante, viaggi e guida *(spostata)*

Questa pagina è stata divisa in tre, perché ogni argomento abbia le proprie ancore in vista di un aiuto integrato nell'app:

- **Veicoli e OBD2** — la tua auto, capacità del serbatoio, flex-fuel, accoppiamento, calibrazione di riferimento, registrazione automatica.
- **Registro rifornimenti e consumi** — rifornimenti, livello serbatoio, rapporto del pieno, precisione, costo al chilometro per carburante.
- **Viaggi ed eco-coaching** — registrazione, dettaglio di un viaggio, punteggio di guida, cruscotto carbonio.

Inizia da **Come funziona Sparkilo** se vuoi i concetti dietro tutti e tre.

---

# Veicoli e OBD2

Tutto ciò che l'app sa della *tua auto*. È questa pagina a decidere se i numeri di consumo di tutte le altre siano affidabili.

---

## Perché all'app serve un veicolo

Senza veicolo, Sparkilo è un cercaprezzi. Con uno può convertire litri e chilometri nel *tuo* costo al chilometro, stimare l'autonomia e — con un adattatore — modellare la portata istantanea di carburante.

*Impostazioni → Veicoli e OBD2. Nota l'etichetta di ambito sulla tessera adattatore: gli adattatori si accoppiano **per veicolo**, non per telefono.*

*Il segno di spunta verde indica il veicolo attivo — quello a cui vengono attribuiti nuovi rifornimenti e viaggi.*

---

## Identità e motorizzazione

*Chiamalo come lo riconoscerai. Il VIN è facoltativo.*

### Il VIN, e cosa porta

Inserire (o leggere) il VIN permette all'app di risalire a cilindrata, numero di cilindri, potenza e tipo di carburante, che sono gli ingressi del modello di consumo. **Leggi il VIN dall'auto** lo recupera in un secondo via OBD2.

La decodifica online del VIN è un **consenso separato** — l'app chiede prima di inviare qualcosa, e la decodifica offline parziale funziona anche se rifiuti. Un VIN è un dato personale; trattalo come tale.

### Motorizzazione

**Termico / Ibrido / Elettrico** cambia i campi sottostanti. Il termico chiede capacità del serbatoio, potenza e carburante preferito; l'elettrico chiede batteria e connettori.

---

## Capacità, potenza e flex-fuel

*La capacità del serbatoio è il numero più portante di questa schermata.*

### Perché la capacità del serbatoio conta tanto

È il denominatore dell'indicatore di livello e della stima di autonomia, e limita ciò che l'app considera un rifornimento plausibile. Una capacità sbagliata produce per mesi un'autonomia credibile ma errata. Prendila dal libretto, non a memoria — i costruttori indicano spesso una capacità utile inferiore di un paio di litri a quella nominale.

### « Posso fare il pieno con carburanti diversi »

Da attivare per un'auto flex-fuel (E85/E10, o qualsiasi cosa alterni davvero). Cambiano due cose:

- Il modulo di rifornimento **chiede ogni volta quale carburante hai davvero messo**, invece di assumere quello preferito.
- La schermata di statistiche guadagna il confronto **costo al chilometro per carburante**, l'unico modo onesto di opporre un carburante economico ma assetato a uno caro ma sobrio.

Lascialo spento se metti sempre la stessa qualità — aggiunge solo un campo.

---

## L'adattatore OBD2

Un adattatore OBD2 è una piccola chiavetta Bluetooth nella presa diagnostica dell'auto (di solito sotto il cruscotto). **È del tutto facoltativo.** Tutto funziona col solo GPS; l'adattatore trasforma stime in misure.

### Cosa cambia

| Senza adattatore | Con adattatore |
|---|---|
| Distanza e durata da GPS | Idem, più i dati motore |
| Consumo **modellato** dalla tua calibrazione | Consumo **misurato** (o modellato molto meglio) |
| Coaching da velocità e accelerazione | Coaching da regime, acceleratore, carico, marcia |
| Tetto di precisione: Media | Tetto di precisione: Alta (±3–7 %) |
| Avvio manuale del viaggio | Registrazione automatica possibile |

### Cosa legge l'app

Velocità, regime, carico motore %, posizione acceleratore %, temperature del liquido di raffreddamento e dell'aria aspirata, anticipo di accensione, livello carburante %, contachilometri (PID standard A6, con ripiego su PID 31 e modo 22 del costruttore), e la portata istantanea di carburante — direttamente dal **PID 5E** dove l'auto lo pubblica, oppure derivata dal debimetro d'aria.

> **La distinzione importante:** se la tua auto risponde al PID 5E, il consumo è *misurato* e nessuna calibrazione vi si applica. Se non risponde, il valore è *modellato* da portata d'aria e parametri motore, ed è quel modello che il guadagno pompa corregge. La schermata del veicolo ti dice in quale caso sei.

### Adattatori supportati

16 modelli sono riconosciuti dal nome Bluetooth, ciascuno con un livello di compatibilità:

- ✅ **Testato** — confermato su hardware reale dal manutentore.
- 👤 **Verificato da un utente** — almeno un utente riferisce che funziona.
- ⚠️ **Teorico** — profilo e trasporto corretti, ma nessuna verifica end-to-end.

| Adattatore | Trasporto | Note | Livello |
|---|---|---|---|
| vLinker FS | BT classico | Modello dominante in Europa; consigliato | ✅ |
| vLinker BM-Android | BT classico | Gemello SPP classico del BM+ | ✅ |
| SmartOBD (BLE) | BLE | Clone ELM327 v1.5 generico | 👤 |
| SmartOBD (Classic) | BT classico | Stessa marca, variante SPP | 👤 |
| vLinker FD / MC | BLE | Famiglia Nordic UART FFF0 | ⚠️ |
| OBDLink MX+ | BLE | Fascia alta Scantool | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | Clone ELM327 v2.1 BLE | ⚠️ |
| vLinker BM+ | BLE | Gemello solo BLE | ⚠️ |
| Konnwei KW902 | BT classico | Clone ELM327 v1.5 | ⚠️ |
| Vgate iCar Pro | BLE | Solo variante BLE | ⚠️ |
| Panlong WiFi | — | Solo WiFi, elencato per etichettare gli accoppiamenti errati | ⚠️ |
| BAFX 34t5 | BT classico | Vecchio ELM327 v1.5 | ⚠️ |
| Generic ELM327 (BLE) | BLE | Profilo generico per cloni BLE FFF0 | ⚠️ |
| Generic ELM327 (Classic) | BT classico | Profilo generico per cloni SPP | ⚠️ |

Gli adattatori non elencati ripiegano sul profilo ELM327 generico e di solito funzionano. Se il tuo funziona — o no — [apri una segnalazione](https://github.com/fdittgen-png/tankstellen/issues) per correggere il livello.

### Accoppiare

1. Quadro **acceso** (motore in moto va bene, quadro spento no).
2. Inserisci l'adattatore; il LED deve essere fisso.
3. Apri il veicolo e tocca la sezione adattatore, oppure avvia un viaggio.
4. Concedi **Ricerca Bluetooth** e **Connessione Bluetooth** (Android 12+). Fino ad Android 11 il sistema chiede invece la **posizione** per scansionare in Bluetooth — regola di sistema, non una scelta di tracciamento.
5. Attendi circa 8 secondi la scansione e tocca il tuo adattatore. L'app esegue l'handshake ELM327 e conferma.

Una volta accoppiato, l'adattatore appartiene a quel veicolo. **Reimposta la connessione** ripete l'handshake senza dimenticare il dispositivo — la prima cosa da provare dopo un'interruzione in marcia. **Dimentica l'adattatore** cancella del tutto l'accoppiamento.

---

## Calibrazione di riferimento — insegnare la tua auto all'app

*210 campioni su 270. Due situazioni di guida sono ancora vuote, e l'app lo dice invece di fingere completezza.*

Ogni campione OBD2 è archiviato in una situazione di guida: **minimo, stop & go, urbano, autostrada, decelerazione, salita / carico, avviamento a freddo, carico prolungato / traino, veleggio**. Le medie per situazione formano il riferimento del veicolo — il modello che produce un L/100 km plausibile quando l'adattatore manca o un PID smette di rispondere.

*Le situazioni con zero campioni sono quelle che ripiegheranno su valori predefiniti. Qui due: decelerazione e traino.*

### Basata su regole o fuzzy

*La modalità fuzzy è quella predefinita e la scelta migliore per quasi tutti.*

- **Basata su regole** assegna ogni campione a esattamente una situazione. Prevedibile, ma oscilla da un campione all'altro fra « urbano » e « autostrada » quando viaggi vicino al confine — intorno ai 60 km/h per esempio.
- **Fuzzy** distribuisce ogni campione su tutte le situazioni in base al grado di appartenenza. Liscia proprio dove la modalità a regole salta, al prezzo di essere più difficile da seguire campione per campione.

### I pulsanti di azzeramento — e cosa fanno davvero

- **Azzera il rendimento volumetrico** scarta il η_v appreso e ripristina il valore predefinito 0,85. η_v è un parametro del modello speed-density che stima la portata d'aria in assenza di debimetro. Azzeralo solo dopo un intervento meccanico; un numero strano è più spesso un problema di copertura. Le auto che pubblicano la portata direttamente (PID 5E) non lo usano affatto.
- **Ripristina dal database veicoli** ricarica cilindrata, potenza e valori predefiniti dal catalogo integrato, scartando le tue immissioni manuali.
- **Azzera il riferimento per situazione** (nella scheda di riferimento) cancella ogni campione appreso e ti riporta ai valori a freddo finché nuovi viaggi non riempiono il profilo.

Nessuno di questi tocca il **guadagno pompa**, appreso dalle finestre da pieno a pieno e residente fuori dal modello OBD2 — vedi Come funziona Sparkilo → Come un litro diventa un numero.

---

## Promemoria di manutenzione

In fondo all'editor di veicolo: preimpostazioni per **cambio olio (15 000 km)**, **pneumatici (20 000 km)** e **revisione (30 000 km)**, più promemoria personalizzati. Contano sui chilometraggi che inserisci con i rifornimenti: avanzano quindi solo se annoti il contachilometri — che è comunque ciò di cui la calibrazione ha bisogno. Un'abitudine, due benefici.

---

## Registrazione automatica

Con un adattatore accoppiato, la registrazione può fare a meno di te:

- **Accoppiamento automatico** — il primo accoppiamento manuale crea l'associazione adattatore ↔ veicolo.
- **Connessione automatica** — appena il sistema vede l'adattatore accoppiato trasmettere, l'app si ricollega in background.
- **Avvio automatico** — connesso e sopra la soglia di velocità, il viaggio inizia.
- **Salvataggio automatico** — l'adattatore perde alimentazione col quadro, e dopo il ritardo configurato il viaggio è finalizzato e salvato.

La registrazione automatica richiede l'autorizzazione di posizione **« Consenti sempre »**, perché Android permette a un servizio in background di trasmettere GPS solo con essa. Quell'autorizzazione serve solo a questo; ricerca e centratura mappa usano quella ordinaria in primo piano.

> **Nota di piattaforma.** La registrazione automatica è verificata su **Android**. Su iOS il risveglio di sistema necessario a « collegarsi appena l'adattatore si accende » non esiste ancora ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)); su iOS i viaggi si avviano a mano.

Le soglie (velocità di partenza, ritardo di salvataggio dopo la disconnessione) stanno nell'editor di veicolo: un'auto da tragitti brevi può quindi scattare diversamente da una da pendolarismo.

---

<details>
<summary>Vista d'insieme — editor di veicolo, pagina intera</summary>

</details>

---

**Vedi anche:** Viaggi ed eco-coaching · Risoluzione problemi → OBD2
**Avanti:** Registro rifornimenti e consumi →

---

# Viaggi ed eco-coaching

La scheda 🛣️ **Viaggi** è un registro automatico più un istruttore di guida. Compare nella modalità **Completo**.

---

## La scheda Viaggi

*Totali del mese, l'ultimo rapporto del pieno, poi l'elenco dei viaggi. Il pulsante flottante avvia una registrazione.*

Il confronto mensile richiede almeno tre viaggi al mese prima di confrontare — con meno, la media è rumore, non tendenza.

*L'icona mappa nella barra disegna ogni viaggio registrato su una mappa — un anno di guida a colpo d'occhio, e un modo semplice per individuare i percorsi che vale la pena ottimizzare.*

---

## Due modi di registrare

### Col solo telefono

Nessun hardware. L'app rileva percorso, distanza, durata e velocità dal GPS, e **modella** il consumo dalla calibrazione del veicolo e dalla tua guida. Segnalato ovunque con `~` e una nota esplicita « stima GPS ».

La precisione parte male e migliora: ogni finestra di rifornimento chiusa riancora il modello alla pompa, così dopo una manciata di pieni un viaggio GPS cade di solito entro pochi punti percentuali. Fino ad allora è etichettato preliminare, non abbellito.

### Con un adattatore OBD2

Dati motore invece di deduzioni: portata reale (misurata dove l'auto pubblica il PID 5E), regime, carico, acceleratore. Nessun periodo di apprendimento per il consumo, e il coaching accede a segnali che il GPS non vede — marcia, giri, carico motore. La configurazione è in Veicoli e OBD2.

> **Registrare non richiede mai un adattatore.** Disattiva *Richiedi OBD2 per la registrazione dei viaggi* (Funzioni e modalità d'uso → Consumo) per registrare col solo GPS; il coaching è ridotto, non assente.

---

## Mentre guidi

### Il numero in tempo reale

Il numero principale è la tua media **sugli ultimi secondi** — carburante bruciato ÷ distanza percorsa, la stessa grandezza di un computer di bordo — etichettata *« Ultimi 5 s »*. Da fermo passa a L/h, perché i L/100 km non hanno senso a velocità zero.

Cambia la finestra in **Impostazioni → Guida e consumo → Finestra del consumo in tempo reale** (3 / 5 / 10 / 30 s). Una **finestra lunga è più stabile e leggibile alla guida**; una corta reagisce abbastanza in fretta da insegnarti quanto costa il piede destro. L'unità segue **Unità e visualizzazione → Unità di consumo** ovunque: banner, miniatura in sovrimpressione, Live Activity iOS e media del viaggio.

### L'orizzontale è la vista « in auto »

Ruota il telefono in orizzontale durante una registrazione e la schermata diventa un layout a zero tocchi, leggibile a colpo d'occhio: a sinistra il grande numero di consumo istantaneo con l'indicazione di coaching sotto (*alza il piede* / *anticipa* / *accelera dolce* col GPS, *sali di marcia* / *scala* / *allevia* con OBD2) e una grande velocità; a destra la scheda radar della stazione più vicina sopra una griglia 2×2 — **Distanza · Media · Durata · Carburante usato**.

Nulla scorre e nulla è piccolo. Telefono nel supporto, e non lo tocchi più.

### Immagine nell'immagine

Riduci l'app a una miniatura flottante e tieni sopra la navigazione. La miniatura si adatta al contesto:

| Situazione | Numero grande | Riga secondaria |
|---|---|---|
| OBD2 collegato | L/100 km in tempo reale (L/h da fermo) | distanza · durata |
| Solo GPS, in marcia | distanza percorsa | durata |
| Avvio | tempo trascorso | — |

### L'overlay di avvicinamento

Entrando nel raggio configurato attorno a una stazione, la miniatura passa a una grande visualizzazione del **prezzo del carburante** — prezzo per la tua qualità, marca, distanza, leggibili a colpo d'occhio.

Quale stazione viene agganciata si imposta in **Impostazioni → Guida e consumo → Overlay all'avvicinamento di una stazione**: **la più vicina** (la prima di cui hai varcato il raggio) o **la più economica del raggio**. All'uscita, la visualizzazione del prezzo resta cinque secondi di grazia, così un semplice passaggio non fa lampeggiare la miniatura.

**Provalo senza guidare:** Impostazioni → Strumenti di sviluppo → **Prova l'overlay di avvicinamento** forza uno stato sintetico per 30 secondi.

---

## Leggere un viaggio

*Il riepilogo dichiara la propria provenienza — veicolo, adattatore, e un badge **Traccia GPS** sulla distanza per sapere da dove vengono i chilometri.*

*Il percorso è colorato per efficienza — verde sotto 6 L/100 km, ambra fino a 10, rosso oltre. Dove è finito il carburante, geograficamente.*

Questa colorazione è la vista più azionabile dell'app: mette su mappa le porzioni costose del tuo tragitto quotidiano. Un tratto rosso che si ripete ogni giorno è un incrocio, una salita o un'abitudine che vale la pena cambiare.

*Tre blocchi: il tuo verdetto, l'attribuzione del carburante, e come hai davvero sollecitato il motore.*

- **« Com'è andato questo viaggio? »** — *Fluido / Moderato / Aggressivo*. La tua risposta serve a calibrare le soglie di stile di guida su viaggi reali, non a darti un voto.
- **Dove è finito il carburante** — litri attribuiti alle accelerazioni forti rispetto alla guida normale. Numeri assoluti piccoli su un viaggio breve; conta il rapporto.
- **Posizione dell'acceleratore** e **regime motore** come distribuzioni — la quota di viaggio passata in veleggio, carico leggero, deciso e pieno gas, e in ciascuna fascia di giri. Una quota alta sopra i 3000 giri sul tragitto casa-lavoro significa che cambi marcia troppo tardi, e costa.

*Due diagnostiche: la completezza della traccia GPS e il comportamento dell'adattatore.*

*Aperta, la scheda OBD2 si spiega in chiaro.*

**Leggi questa scheda prima di dubitare di un numero di consumo.** Indica quante misure portavano dati motore, la **percentuale di copertura** risultante, adattatore e protocollo negoziato, la durata della sessione, perché è finita (`userStopped`, una disconnessione, una morte del processo), e la riga decisiva: *« I valori di consumo vengono dall'adattatore, non da stime GPS. »* Se la copertura è ben sotto il 100 %, i vuoti sono stati riempiti con stime GPS e la media del viaggio è un misto.

*Velocità, portata e regime su un asse temporale comune — le tre curve che spiegano qualsiasi numero di consumo.*

*Carico motore e acceleratore affiancati mostrano la differenza fra far lavorare il motore e limitarsi a farlo girare.*

*L'altitudine conta più di quanto si creda: una salita spiega un picco di consumo che altrimenti sembrerebbe cattiva guida.*

Le azioni **condividi** ed **elimina** sono nella barra superiore. La condivisione esporta il viaggio con la traccia GPX.

---

## Punteggio di guida e coaching

Con un adattatore, ogni viaggio è valutato su 100 — un composito di minimo, accelerazioni forti, frenate decise, tempo ad alto regime, pieno gas, sottoregime, scatti, alta velocità prolungata, aggressività sul pedale e ricchezza della miscela. Il dettaglio nomina il comportamento più costoso: il punteggio è una diagnosi, non una punizione.

La scheda **principali comportamenti dispendiosi** ne ricava frasi utilizzabili — e mostra *« Nessuna inefficienza rilevante — continua così! »* quando non c'è nulla da correggere, invece di inventare un rimprovero.

Il coaching può avvenire anche in marcia:

- **Coaching eco in tempo reale** — vibrazione leggera e consiglio a schermo quando acceleri forte a velocità di crociera.
- **Coaching vocale di guida** — lo stesso consiglio letto ad alta voce, per tenere gli occhi sulla strada.
- **Glide-coach (beta)** — vibrazione discreta quando conviene alzare il piede prima di un rosso, in base ai semafori di OpenStreetMap. **Disattivato di default: rischio di distrazione**, e serve rete per caricare i semafori della tua zona.

*Impostazioni → Guida e consumo. Riconoscimenti e punteggi si possono nascondere in tutta l'app se la gamification non fa per te.*

---

## Il cruscotto carbonio

*Costo e CO₂ dagli stessi litri misurati, scomposti in due modi.*

- **Per lunghezza di viaggio** — i tragitti brevi sono di solito i più cari al chilometro, perché un motore freddo beve. Vederlo quantificato è ciò che spinge ad accorpare le commissioni.
- **Per fascia di velocità** — quanta parte del carburante se ne va a passo d'uomo in città rispetto al viaggiare in autostrada.

È costruito interamente su dati del tuo telefono, e si attiva in Funzioni e modalità d'uso → Consumo.

---

## Esportazioni e diagnostica

- **Condividi** un singolo viaggio (riepilogo + GPX).
- **Esporta la traccia di analisi di guida** — KPI GPS, punteggio e lezioni del viaggio in JSON, con un campo libero per descrivere com'è andata davvero. Ricondividerla aiuta a calibrare le soglie di stile su viaggi reali. Funzione della modalità sviluppatore.
- **Esporta i miei dati → Archivio ZIP** in Privacy e dati → Esporta o elimina include ogni viaggio e un GPX per viaggio.

---

<details>
<summary>Vista d'insieme — dettaglio di un viaggio, pagina intera</summary>

</details>

---

**Vedi anche:** Veicoli e OBD2 · Registro rifornimenti e consumi
**Avanti:** Storico e previsioni prezzi →

---

# Privacy, dati e sincronizzazione

Le promesse di privacy di Sparkilo sono verificabili, e questa è la pagina in cui le verifichi.

---

## La privacy per impostazione predefinita

Concretamente:

- **Nessun Google Play Services. Nessun Firebase. Nessun Google Analytics. Nessun identificatore pubblicitario.**
- **Nessun SDK di tracciamento di terzi** — il `pubspec.yaml` pubblico non ha dipendenze di analitica.
- **Nessun account richiesto.** L'app è pienamente funzionale senza.
- **Local-first.** Tutto resta sul telefono finché non attivi qualcosa.
- **Consenso prima del trattamento**, più una spiegazione in linguaggio chiaro *prima* di ogni richiesta di sistema.
- **Open source, MIT.** I test del progetto falliscono se l'informativa e il codice divergono.

### Cosa lascia davvero il telefono

| Dato | A chi | Quando | Evitabile? |
|---|---|---|---|
| Coordinate di ricerca o codice di regione | Il fornitore ufficiale del tuo paese | A ogni ricerca in tempo reale | Cercare per CAP anziché col GPS |
| Area di mappa + IP | Il proxy UE delle tessere dello sviluppatore, che recupera da OpenStreetMap | Uso della mappa | Disattivare il proxy — allora OpenStreetMap vede il tuo IP direttamente |
| Il tuo IP | logo.clearbit.com | Solo se attivi i loghi online | Lasciarlo spento (predefinito) |
| Tracce di crash depurate | Sentry | Solo con *Segnalazione errori* attiva | Spenta di default |
| Le tue righe sincronizzate | Il database TankSync che hai scelto | Solo con TankSync attivo | Spento di default |

**La tua identità non fa mai parte di una richiesta di prezzo**, e lo sviluppatore non gestisce alcun server che memorizzi le tue ricerche.

---

## Chi è il titolare del trattamento

Dipende interamente da come usi TankSync:

| Modalità | Titolare |
|---|---|
| **Senza TankSync** *(predefinito)* | **Solo tu.** Nulla risiede su un server gestito dallo sviluppatore |
| **Il tuo progetto Supabase** | **Tu** — lo sviluppatore non lo vede mai |
| **Il database di un gruppo** | **Il proprietario del gruppo** che gestisce quel progetto |
| **Sparkilo Community** | **Lo sviluppatore, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)); Supabase, Inc. è responsabile del trattamento; ospitato nell'UE (AWS eu-central-1, Francoforte) |

L'app indica il caso applicabile **prima** della connessione, e di nuovo nella riga *Modalità sincronizzazione* di **Sincronizzazione e account**.

---

## La schermata Privacy e dati

**Impostazioni → Privacy e dati** è l'unico punto di ingresso. Si apre su una scheda di riepilogo seguita da quattro riquadri tematici:

| Riga o riquadro | Cosa ti dice |
|---|---|
| *I tuoi dati restano su questo dispositivo* / *I tuoi dati sono sincronizzati anche su TankSync* | Dove vivono fisicamente i tuoi dati in questo momento |
| *Sincronizzazione: disattivata* / *Sincronizzazione: attiva · account anonimo* / *Sincronizzazione: attiva · account email* | Se TankSync è collegato, e con quale tipo di account |
| *… archiviati su questo dispositivo* | Lo spazio totale che l'app occupa attualmente |
| **Le tue scelte** — *n su 5 attive* | I cinque consensi e i due controlli di rete |
| **Dati su questo dispositivo** — *dimensione · n categorie* | Ogni categoria conservata localmente, con dimensione e conteggio |
| **Sincronizzazione e account** | Stato di TankSync, account, database e le azioni di sincronizzazione |
| **Esporta o elimina** — *ZIP, JSON, CSV · registro errori (n)* | Le esportazioni, il registro errori e la zona pericolosa |

Il vecchio *Cruscotto privacy* non esiste più: i suoi contatori, i fatti di sincronizzazione, le esportazioni e il pulsante di eliminazione vivono ora sotto questi quattro argomenti. I vecchi collegamenti e i widget della schermata iniziale che puntavano al cruscotto aprono invece **Privacy e dati**.

---

## Le tue scelte

*I due controlli di rete, ciascuno descritto per ciò che fa davvero trapelare. I cinque consensi stanno sopra di essi, nella stessa scheda.*

Ogni riga è un interruttore — *« Puoi modificare le tue scelte sulla privacy in qualsiasi momento. »*

| Riga | Cosa decide |
|---|---|
| **Accesso alla posizione** | Trova le stazioni di carburante vicine usando la tua posizione. Spento: ricerca per CAP |
| **Segnalazione errori** | Invia rapporti di arresto anomalo anonimi per migliorare l'app. Spenta di default — nulla viene mai inviato senza di essa |
| **Sincronizzazione cloud** | Sincronizza preferiti e avvisi su dispositivi — il consenso alla base di TankSync |
| **Decodifica VIN online** | Decodifica il VIN tramite il servizio pubblico gratuito di NHTSA. Spenta: inserisci a mano i dati del veicolo |
| **Sincronizza registrazioni percorsi** | Backup percorsi OBD2 + GPS su TankSync. In grigio finché *Sincronizzazione cloud* non è attiva |
| **Carica le tessere della mappa tramite il proxy Sparkilo** | Acceso: l'area di mappa e il tuo indirizzo IP raggiungono il server UE dello sviluppatore, che recupera le tessere da OpenStreetMap. Spento: le tessere si caricano direttamente da tile.openstreetmap.org, che allora vede il tuo IP |
| **Carica i loghi dei marchi da internet** | Spento di default: si mostrano i segnaposto inclusi nell'app. Acceso: i loghi sono recuperati da logo.clearbit.com, che vede il tuo indirizzo IP |

I due controlli di rete hanno un pulsante informativo (*Scopri di più*) con la spiegazione completa. Il piè di pagina registra *Consenso dato il … · versione … dell'informativa* — la traccia di controllo richiesta dal GDPR — e rimanda all'**Informativa sulla privacy** nella tua lingua. Ritirare un consenso ferma immediatamente quel trattamento; i trattamenti precedenti restano leciti.

---

## Dati su questo dispositivo

*Lo spazio, voce per voce: una barra per categoria, poi una riga per categoria con dimensione, conteggio e un punto del colore della barra. Le categorie vuote sono in grigio, non nascoste.*

Le righe sotto **Utilizzo dello spazio su questo dispositivo**: **Preferiti** · **Valutazioni stazioni** · **Profili di ricerca** · **Avvisi prezzo** · **Stazioni cronologia prezzi** · **Stazioni ignorate** · **Utenti bloccati** · **Percorsi salvati** · **Cache** · **Impostazioni** (*Chiave API, profilo attivo*) · **Totale**.

Tutto risiede in **database Hive cifrati**; la chiave sta nell'Android Keystore / Portachiavi iOS.

| Contenitore | Contenuto |
|---|---|
| `settings` | Configurazione, paese, lingua, unità |
| `profiles` | I tuoi profili di ricerca |
| `favorites` | Stazioni salvate con tutti i loro dati |
| `cache` | Risposte API e itinerari in cache |
| `priceHistory` | I rilevamenti di prezzo locali a 30 giorni |
| `price_snapshots` | Istantanee per l'uso offline e il widget |
| `alerts` | Le tue regole di avviso |
| `service_reminders` | Promemoria di manutenzione |
| `obd2Baselines` | Riferimenti di consumo per veicolo |
| `obd2TripHistory` | Viaggi: percorso, velocità, sensori |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Cache delle capacità dell'adattatore |

Chiavi API, token GitHub e sessione TankSync vivono nella cassaforte hardware, non in Hive.

### Dettagli cache

*Il riquadro **Dettagli cache** si espande sulla durata di ogni classe in cache — ricerche 5 min, dettagli stazione 15 min, richieste di prezzo 5 min, dati dei preferiti 30 min, ricerche di città 30 min, geocodifica dei CAP 24 h — e sul pulsante **Svuota cache**.*

La cache conserva le risposte API per un caricamento più rapido e l'accesso offline. Svuotarla elimina solo risultati e prezzi in cache — profili, preferiti e impostazioni restano intatti; le ricerche successive sono più lente, nulla va perduto. Il pulsante mostra *La cache è vuota* ed è disattivato quando non c'è nulla da svuotare.

### Utenti bloccati

**Utenti bloccati** è l'unica riga toccabile: apre l'elenco degli account che hai bloccato, ciascuno con un pulsante **Sblocca**. I contenuti condivisi da questi utenti sono nascosti su questo dispositivo; il blocco è locale — non segnala l'account.

---

## Autorizzazioni

| Autorizzazione | Perché | Rifiutabile? |
|---|---|---|
| **Posizione** *(durante l'uso)* | Ricerca vicina, partenza itinerario, registrazione | Sì — usare un CAP |
| **Posizione** *(« Consenti sempre »)* | **Solo** la registrazione automatica OBD2, perché il percorso continui a schermo spento | Sì — avviare i viaggi a mano |
| **Ricerca + connessione Bluetooth** | Accoppiamento dell'adattatore | Sì — l'OBD2 è facoltativo |
| **Notifiche** | Avvisi di prezzo | Sì — gli avvisi non scatteranno |
| **Fotocamera** | OCR sul dispositivo di pompe, scontrini e QR | Sì — digitare a mano |
| **Internet** | Chiamate di prezzo e mappa | Necessaria |

Fino ad Android 11 il sistema richiede la **posizione** per qualsiasi scansione Bluetooth — regola di piattaforma, non una scelta di tracciamento. Ogni autorizzazione si revoca poi nelle impostazioni di sistema; la funzione corrispondente semplicemente si ferma.

---

## Sincronizzazione e account

*Raggiungibile dal riquadro Privacy e dati e direttamente dalla radice delle Impostazioni. La schermata fa emergere anche i problemi — qui uno schema auto-ospitato obsoleto, che quindi non riesce a sincronizzare alcune tabelle, in silenzio.*

Su attivazione. *Disabilitato* significa che nulla è memorizzato su alcun server, da nessuna parte. La scheda di riepilogo in alto espone i fatti:

| Riga | Valore |
|---|---|
| **Stato** | *Connesso* oppure *Disabilitato* |
| **Modalità sincronizzazione** | *Sparkilo Community — il server UE dello sviluppatore* · *Gruppo condiviso — un database a cui ti sei unito* · *Self-hosted — il tuo Supabase* |
| **Account** | *Account anonimo, legato a questo dispositivo* oppure *Account email: …* |
| **ID utente** | Il tuo UUID, con un pulsante di copia — citalo in una richiesta di assistenza |
| **Host del database** | Il nome host del database con cui sincronizzi; la chiave non viene mai mostrata |
| **Condividi profili veicolo appresi** | Carica i riferimenti di consumo per veicolo perché un secondo dispositivo possa riutilizzarli |

### Tre forme di distribuzione

1. **Sparkilo Community** — il database condiviso gestito dallo sviluppatore (Supabase, UE/Francoforte). Il tuo account è un UUID casuale; puoi collegare un'e-mail per raggiungerlo da un altro dispositivo. Le segnalazioni della comunità e le valutazioni condivise pubblicamente sono leggibili da ogni utente connesso.
2. **Il tuo progetto Supabase** — schema SQL ed Edge Function sono nel repository. Sei tu il titolare e mantieni la piena proprietà.
3. **Il database di un gruppo** — collegati al progetto di familiari o amici. Quella persona è il titolare.

### Configurazione

**Sincronizzazione e account → Configura sincronizzazione cloud.** Per Community, scansiona il QR del wiki o incolla URL e chiave anon; per un progetto proprio o di gruppo, incolla URL del progetto e chiave anon. Entrambi stanno nella cassaforte hardware, e gli endpoint in HTTP semplice sono rifiutati.

> **Auto-ospitanti:** dopo un aggiornamento la schermata può avvisare che lo **schema è obsoleto**. Riesegui il SQL di installazione proposto — altrimenti la sincronizzazione delle nuove tabelle fallisce **in silenzio**, che è ben peggio di un errore visibile.

### Azioni una volta collegato

- **Passa a e-mail** — conserva i dati, aggiunge l'accesso da altri dispositivi; l'UUID resta lo stesso. **Passa ad anonimo** fa il contrario.
- **Consensi** — un rimando a *Le tue scelte*: i consensi Sincronizzazione cloud e sincronizzazione dei viaggi vivono lì, non qui.
- **Visualizza i miei dati** — la schermata *Trasparenza dei dati* elenca le righe che il server conserva per te; il suo pulsante **Elimina tutti i percorsi sincronizzati** ripulisce solo le righe dei viaggi.
- **Collega dispositivo** — porta un secondo telefono sullo stesso account.
- **Elimina dati sincronizzati** — scegli *Viaggi*, *Veicoli*, *Rifornimenti* o *Tutto* da rimuovere dal database di sincronizzazione; le copie locali restano.
- **Condividi database** — un codice QR perché familiari o amici possano unirsi al tuo database o a quello di un gruppo (non offerto su Community).
- **Disconnetti** — smette di sincronizzare; i dati locali sono conservati.
- **Elimina account** — rimuove definitivamente tutti i dati sul server, poi l'identità stessa dell'account, e-mail collegata compresa. Offerto per il tuo database e per quelli di gruppo; su Community usa *Elimina dati sincronizzati → Tutto* oppure la zona pericolosa descritta sotto.

### Cosa si sincronizza

Preferiti · avvisi di prezzo · stazioni ignorate · valutazioni (con indicatore di privacy per valutazione: locale / privata sincronizzata / condivisa pubblicamente) · itinerari · veicoli compresi VIN e identificativo dell'adattatore · rifornimenti e registri di ricarica · riferimenti di consumo · segnalazioni di comunità e di contenuto che invii.

**I viaggi sono a parte.** La loro sincronizzazione resta facoltativa *anche dopo* aver attivato la Sincronizzazione cloud — l'interruttore *Sincronizza registrazioni percorsi* resta in grigio fino ad allora. Sul server i riepiloghi restano fino alla cancellazione; i campioni GPS dettagliati sono eliminati dopo 90 giorni.

Ogni tabella è protetta da sicurezza a livello di riga: un account può leggere o eliminare solo le proprie righe. Le valutazioni condivise e le segnalazioni della comunità sono le uniche righe visibili agli altri utenti connessi.

### Conflitti

**Il locale vince sempre.** La sincronizzazione aggiunge e aggiorna, ma non elimina mai in silenzio — solo la tua eliminazione esplicita provoca una cancellazione sul server, che si propaga poi agli altri tuoi dispositivi.

---

## Esporta o elimina

Un pulsante, un foglio dei formati, una zona rossa. **Esporta i miei dati** apre *Scegli un formato*:

| Formato | Suggerimento nel foglio | Cosa ottieni |
|---|---|---|
| **Archivio ZIP** | *Tutto, allegati inclusi — per un backup completo* | `sparkilo-my-data-<date>.zip`: un JSON leggibile da macchina per categoria — preferiti, avvisi, profili, percorsi, storico prezzi, veicoli, rifornimenti, viaggi con campioni GPS e un GPX per viaggio, riferimenti, promemoria di manutenzione, registri di ricarica, traguardi e la tua traccia di consenso — più ogni tabella server se TankSync è collegato |
| **JSON** | *Leggibile dalle macchine — per un'altra app* | `tankstellen-data.json`: le categorie sul dispositivo in un unico file piatto, copiato anche negli appunti |
| **CSV** | *Foglio di calcolo — una tabella per categoria* | `tankstellen-data.csv`: un blocco `# table` per categoria — preferiti, avvisi, storico prezzi e il resto — copiato anche negli appunti |

Tutte le esportazioni finiscono nella cartella **Download pubblica** (*Salvato nella cartella Download*), perché qualsiasi gestore di file le trovi.

**Registro errori** mostra quante tracce depurate l'app conserva (*Nessuna voce* … *n voci*). **Salva** le scrive nei Download per una segnalazione — senza e-mail, coordinate, chiavi o token all'interno, e nulla viene mai inviato automaticamente; **Cancella** svuota il registro.

**Zona pericolosa** — *Elimina definitivamente tutto ciò che l'app archivia su questo dispositivo. Con la sincronizzazione attiva, vengono cancellati anche i tuoi dati sul server TankSync.* **Elimina tutti i miei dati** chiede conferma ed elenca cosa sparisce: preferiti e dati delle stazioni, profili di ricerca, avvisi di prezzo, storico prezzi, dati in cache, la tua chiave API, tutte le impostazioni dell'app. Con TankSync collegato cancella prima le tue righe sul server; se una tabella non è stata cancellata, l'app **ti dice quale** invece di proclamare il successo. L'app torna poi alla configurazione di primo avvio. Irreversibile.

Per un'istantanea ripristinabile invece di un'esportazione di dati, usa **Impostazioni → Backup e ripristino** — vedi Riferimento impostazioni.

---

## I tuoi diritti secondo il GDPR

Ogni diritto degli articoli 15–22 ha un pulsante. Nessuna richiesta di assistenza necessaria.

- **Accesso** — *Dati su questo dispositivo* elenca ogni categoria sul dispositivo; *Visualizza i miei dati* elenca ogni riga del tuo database TankSync.
- **Portabilità** — *Esporta i miei dati* come archivio ZIP.
- **Rettifica** — modifica qualsiasi voce sul posto; la modifica si sincronizza se TankSync è attivo.
- **Cancellazione**
  - *Dispositivo:* **Esporta o elimina → Elimina tutti i miei dati**.
  - *Server:* **Sincronizzazione e account → Elimina account** cancella ogni riga di tua proprietà **in una transazione** — preferiti, avvisi, stazioni ignorate, segnalazioni di prezzo e contenuto, veicoli, rifornimenti, itinerari, riferimenti, valutazioni, viaggi, condivisioni di viaggio date e ricevute, impostazioni di sincronizzazione, tracce di cancellazione e la tua riga utente — poi l'identità dell'account stessa, e-mail collegata compresa. Se una tabella non è stata cancellata, l'app **ti dice quale** invece di proclamare il successo.
  - *Singoli elementi:* tutto è eliminabile singolarmente; **Elimina dati sincronizzati** rimuove viaggi, veicoli o rifornimenti dal server, e **Elimina tutti i percorsi sincronizzati** ripulisce solo le righe dei viaggi.
- **Revoca del consenso** — Privacy e dati → Le tue scelte; il trattamento cessa subito.
- **Limitazione / opposizione** — disattiva TankSync, la sincronizzazione dei viaggi, il proxy delle tessere o la diagnostica; revoca le autorizzazioni nelle impostazioni di sistema.
- **Reclamo** — a un'autorità di controllo, in particolare quella della tua residenza, del luogo di lavoro o della presunta violazione. Lo sviluppatore gradirebbe poter rimediare prima: [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

Se non riesci più ad aprire l'app, chiedi la cancellazione via e-mail dall'indirizzo collegato all'account. **Un account anonimo mai collegato a un'e-mail non può essere identificato da nessuno — sviluppatore incluso — senza il dispositivo che l'ha creato.** È il prezzo di non chiederti di registrarti.

Testo integrale: **[Informativa sulla privacy v3, 29 agosto 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**, disponibile in tutte le 23 lingue dell'app. L'app ricorda a quale versione hai acconsentito e la ripropone a ogni modifica.

---

**Vedi anche:** Riferimento impostazioni · Come funziona Sparkilo → Dove vivono i tuoi dati
**Avanti:** Risoluzione problemi e FAQ →

---

# Riferimento impostazioni

Ogni schermata dell'albero delle impostazioni e — più utile — **quanto ti costa ogni interruttore** in batteria, dati, precisione o privacy.

---

## La forma dell'insieme

Le impostazioni sono un **albero a due livelli**: una radice di tessere tematiche, una schermata per tema, e una ricerca per parola chiave su tutte.

*Digita « raggio », « OBD2 » o « tema » nel campo di ricerca e la tessera giusta emerge — non serve ricordare quale tema possiede un parametro.*

*Dodici temi in tutto. Per arrivarci: l'ingranaggio in alto a destra delle schermate principali.*

Tre regole di progetto rendono l'albero prevedibile:

1. **Una casa per parametro.** Nulla compare due volte; i rimandi puntano all'unico proprietario.
2. **Etichette di ambito.** Una tessera marcata *questo profilo*, *tutti i profili* o *questo veicolo* dice in anticipo quanto lontano arriva una modifica.
3. **Stati vuoti onesti.** Una sezione con la funzione spenta lo dice e rimanda all'interruttore, invece di nascondersi.

---

## Profili e regione

*Paese, lingua, carburante, raggio di ricerca, itinerari · ambito: questo profilo*

*Il carburante preferito è derivato dal veicolo predefinito. Per sceglierlo direttamente, togli il veicolo dal profilo.*

| Impostazione | Impatto |
|---|---|
| **Nome del profilo** | Estetico, ma è ciò che mostra il chip di profilo |
| **Carburante preferito** | Il prezzo in evidenza su ogni scheda; il predefinito degli avvisi; ciò per cui ottimizza la ricerca su itinerario |
| **Raggio predefinito** | Più grande = più risultati e ricerche più lente |

*Valori predefiniti dell'itinerario. **Candidate per punto di campionamento** scambia accuratezza con velocità sui corridoi lunghi.*

*Tre cose distinte da conoscere.*

- **Evita le autostrade** cambia l'itinerario calcolato stesso: le aree di servizio smettono di essere candidate — in genere un risparmio, dato che il carburante autostradale è il più caro di ogni corridoio.
- **Note delle stazioni** — *Locale* (solo questo dispositivo), *Privato* (sincronizzato sul tuo account) o *Condiviso* (visibile ad altri utenti). È una scelta di privacy, non di archiviazione.
- **Schermata iniziale** — su cosa si apre l'app: Nelle vicinanze, Stazione più vicina, Preferiti o Mappa.

*Il raggio dell'overlay e la regola **più vicina vs più economica nel raggio** stanno nel profilo: un profilo « pendolare » e uno « vacanza » possono comportarsi diversamente.*

*Il paese decide il fornitore di dati. Cambiarlo svuota i dati di stazione in cache.*

*Un **CAP di casa** consente ricerche per area senza alcun GPS — il modo più pulito di usare l'app se non vuoi mai condividere la posizione.*

---

## Veicoli e OBD2

*Le tue auto, capacità del serbatoio, accoppiamento · ambito: questo veicolo*

*Gli adattatori si accoppiano per veicolo: la tessera adattatore ti porta quindi dentro un veicolo invece che su una schermata globale.*

Il trattamento completo — VIN, capacità, flex-fuel, modalità di calibrazione, riferimento, soglie di registrazione automatica, promemoria — è in Veicoli e OBD2.

---

## Guida e consumo

*Coaching, ricompense, radar, risoluzione problemi · ambito: misto*

*Le prime due voci sono quelle che regolerai davvero.*

| Impostazione | Impatto |
|---|---|
| **Finestra del consumo in tempo reale** (3/5/10/30 s) | Più lunga = più stabile e leggibile alla guida; più corta = abbastanza reattiva da insegnare quanto costa il pedale |
| **Overlay all'avvicinamento** | Raggio, modalità prezzo, limite di interrogazione e fissaggio schermo per il profilo attivo |
| **Coaching eco in tempo reale** | Vibrazione leggera + consiglio a schermo in accelerazione forte a velocità di crociera |
| **Coaching vocale di guida** | Lo stesso consiglio letto ad alta voce — gli occhi restano sulla strada |
| **Glide-coach beta** | Feedback aptico prima di un rosso dai semafori OpenStreetMap. **Spento di default — rischio di distrazione**, e serve rete |

*Ricompense e risoluzione problemi.*

- **Carte fedeltà** — sconti al litro applicati nei confronti di prezzo, così una stazione nominalmente più cara può risultare correttamente più economica per te.
- **Mostra riconoscimenti e punteggi** — spento, badge, punteggi e trofei spariscono da tutta l'app. Nulla smette di essere misurato; smette solo di essere mostrato.
- **Registrazione di debug OBD2** — registra ogni sessione (connessione, handshake, perdite di dati, riconnessioni) in un log XML esportabile. **Spenta di default**: scrive di continuo e conviene solo mentre si insegue un problema di adattatore.

---

## Prezzi e avvisi

*Avvisi, annunci vocali, storico, segnalazioni della comunità*

*Il blocco grigio degli annunci vocali è uno stato vuoto onesto: nomina entrambi gli interruttori necessari e dove si trovano.*

| Impostazione | Impatto |
|---|---|
| **Avvisi di prezzo** | Apre l'elenco; la funzionalità è un interruttore in Funzioni e modalità d'uso |
| **Storico prezzi** | Registrazione locale a 30 giorni. Spento = niente grafici, niente « momento migliore » |
| **Previsione di prezzo TFLite** | Modello sul dispositivo; caratteristiche e previsioni non lasciano mai il telefono |
| **Segnalazioni di prezzo della comunità** | Richiede TankSync; le tue segnalazioni sono visibili agli altri utenti connessi |
| **Scansiona il QR di pagamento** | Aggiunge il lettore QR al dettaglio delle stazioni |

---

## Unità e visualizzazione

*Tema, unità di distanza, unità di consumo, widget · ambito: misto*

*L'**unità di consumo** si propaga ovunque in un colpo solo — banner in tempo reale, miniatura, medie dei viaggi, statistiche, widget.*

- **Unità di distanza** segue di default il paese del profilo attivo (km o miglia).
- **Unità di consumo**: *Automatica* (mpg nel Regno Unito e negli USA, L/100 km altrove), oppure esplicitamente L/100 km, km/L o mpg.

*Le scelte del widget portano l'etichetta **questo profilo** e valgono per ogni widget installato che mostra quel profilo, dal prossimo aggiornamento.*

**Variante di contenuto** — *solo prezzo attuale*, o *predittivo: momento migliore per il pieno* (richiede la previsione TFLite).

---

## Funzioni e modalità d'uso

*Preimpostazioni e ogni singolo interruttore*

*Scegliere una preimpostazione **sovrascrive** ogni singolo interruttore. Se hai regolato a mano, resta su Personalizzato.*

Le dipendenze sono applicate, non nascoste: un interruttore col prerequisito spento resta disattivato e nomina quel prerequisito.

*Ricerca e mappa — incluso se stazioni e colonnine compaiano affatto.*

*Prezzi e avvisi. Lo storico è la funzione genitore della previsione che segue.*

*Il radar, i suoi annunci vocali e l'interruttore principale **Feedback vocale** — spento, l'app non apre mai un motore di sintesi.*

*Il selettore **Spento / Carburante / Carburante + Viaggi** è la forma compatta di tutta la pila consumo.*

| Interruttore | Impatto |
|---|---|
| **Statistiche consumi** | La scheda di analisi di rifornimenti e viaggi |
| **Gamification** | Punteggi di guida e badge conquistati |
| **Eco-coach aptico** | Feedback vibratorio in tempo reale alla guida |
| **Glide-coach** | Consigli eco dai semafori OpenStreetMap — richiede rete |
| **Traccia GPS dei viaggi** | Conserva i punti di percorso di ogni viaggio. Spento = database più piccolo, niente mappe dei viaggi |
| **Registrazione automatica** | Avvia un viaggio quando l'adattatore accoppiato si collega a un veicolo in movimento |

*Due interruttori qui cambiano la qualità dei dati anziché l'interfaccia.*

- **PID OEM sperimentali** — legge il livello esatto del serbatoio in litri tramite PID del costruttore su adattatori compatibili. Dati migliori dove funziona; innocuo dove no.
- **Richiedi OBD2 per la registrazione dei viaggi** — **spento**, i viaggi si registrano col solo GPS. Il coaching è ridotto (niente L/100 km istantanei, meno segnali motore) ma nulla è bloccato.
- **Sincronizzazione dei riferimenti** — carica i riferimenti di consumo per veicolo perché un secondo dispositivo li riusi. Richiede TankSync.

*Inserimento e scansione. Il riconoscimento è sul dispositivo; questi interruttori decidono solo se le scorciatoie esistono.*

*Sviluppatore e sperimentale — da lasciare spento se non segnali bug.*

---

## Fonti dati e posizione

*Chiavi API, GPS, cambio automatico di profilo*

*Una croce rossa sulla chiave prezzi è il motivo abituale di una ricerca tedesca vuota.*

| Impostazione | Impatto |
|---|---|
| **Prezzi carburante (Tankerkoenig)** | Necessaria solo per la Germania. Gratuita, per utente, nella cassaforte hardware |
| **Ricarica EV (OpenChargeMap)** | Facoltativa — sostituisce la chiave condivisa con la tua quota |
| **Aggiornamento automatico** | Aggiorna la posizione GPS prima di ogni ricerca. Spento = ricerche più rapide, posizione forse vecchia |
| **Cambio automatico di profilo** | Commuta il profilo al passaggio di un confine, così fornitore e carburante sono corretti automaticamente |

---

## Sincronizzazione e account

*Questa schermata fa emergere anche i problemi — qui uno schema TankSync auto-ospitato obsoleto che quindi non sincronizza alcune tabelle, in silenzio.*

Trattato per esteso in Privacy, dati e sincronizzazione → TankSync. L'essenziale:

- **Sparkilo Community / il tuo database / il database di un gruppo** — tre forme di distribuzione con tre titolari del trattamento diversi.
- **Anonimo → e-mail** — *Passa all'e-mail* conserva dati e account e aggiunge un modo di accedere da un altro dispositivo. Un account anonimo esiste solo sul dispositivo che l'ha creato.
- **Schema obsoleto** — dopo un aggiornamento, chi si auto-ospita deve rieseguire il SQL di installazione, altrimenti le nuove tabelle falliscono in silenzio.

---

## Privacy e dati

*Due scelte di privacy legate alla rete, ciascuna formulata per ciò che davvero rivela.*

- **Carica le tessere tramite il proxy Sparkilo** — *attivo*: il server UE dello sviluppatore vede l'area di mappa e il tuo IP e recupera le tessere per te. *Spento*: le tessere arrivano da tile.openstreetmap.org, che allora vede il tuo IP. Nessuna opzione significa « niente rete »; scegli da chi essere visto. La build F-Droid non usa mai il proxy.
- **Carica i loghi delle marche da Internet** — *spento* di default; si usano loghi generici integrati. Attivo, arrivano da logo.clearbit.com, che vede il tuo IP.

*Lo spazio, voce per voce. La cache è quasi sempre la fetta maggiore e l'unica che si può buttare senza rischi.*

*Gestione della cache, con la durata di ciascuna classe: ricerche 5 min, dettagli stazione 15 min, richieste di prezzo 5 min, dati preferiti 30 min, ricerche di città 30 min, geocodifica CAP 24 h.*

*Svuotare la cache elimina solo risultati e prezzi memorizzati — profili, preferiti e impostazioni restano. Le prossime ricerche saranno più lente; nulla va perduto.*

---

## Backup e ripristino

*Uno ZIP completo con veicoli, rifornimenti, viaggi e registri di ricarica.*

**Esporta backup** scrive lo ZIP nei tuoi Download. **Ripristina backup** offre *unisci* o *sostituisci* — unire conserva ciò che c'è sul dispositivo e aggiunge il mancante; sostituire cancella prima. Da usare prima di un cambio telefono o di un ripristino di fabbrica. TankSync non è un backup: replica categorie scelte, non tutto.

---

## Avanzate e sviluppatore

*Il token GitHub è facoltativo — senza, un riscontro di scansione fallita si condivide a mano invece di aprire automaticamente una segnalazione.*

La voce **Strumenti di sviluppo** compare solo con la modalità sviluppatore attiva (Funzioni e modalità d'uso → Sviluppatore e sperimentale).

*Per un utente normale il registro errori è la parte utile: **Salva il registro errori** scrive tracce depurate nei Download, da allegare a una segnalazione.*

*La traccia di avvio è una cascata delle fasi di inizializzazione — così un avvio lento si diagnostica invece di indovinarlo.*

***Prova l'overlay di avvicinamento** forza uno stato sintetico per 30 s per verificare la visualizzazione del prezzo in sovrimpressione senza andare a guidare.*

---

## Informazioni

***Versione e numero di build** — citali entrambi in ogni segnalazione, e controllali per primi quando una correzione « non ha funzionato » (la distribuzione dello store potrebbe non averti ancora raggiunto).*

*L'app è gratuita, open source e senza pubblicità. Le attribuzioni dei dati di prezzo e di mappa sono in fondo, come richiedono le licenze.*

---

**Vedi anche:** Come funziona Sparkilo · Privacy, dati e sincronizzazione
**Avanti:** Privacy, dati e sincronizzazione →

---

# Risoluzione problemi e FAQ

Ordinato all'incirca per frequenza reale.

---

## Prima di tutto: controlla la versione

*Impostazioni → Informazioni. Cita **entrambi** in ogni segnalazione.*

Buona parte dei « non funziona ancora » è una distribuzione dello store che non ha ancora raggiunto il dispositivo. Se il numero di build è precedente alla versione con la correzione, non c'è nulla da diagnosticare.

---

## « Nessun prezzo trovato »

1. **Controlla il paese nel profilo.** Un profilo tedesco chiama l'API tedesca; in Italia non troverà nulla. Impostazioni → Profili e regione → Regione.
2. **Germania: la chiave API è impostata?** Impostazioni → Fonti dati e posizione — una croce rossa su *Prezzi carburante (Tankerkoenig)* è la risposta.
3. **Sei offline?** I prezzi in tempo reale richiedono una chiamata di rete. I prezzi in cache restano visibili, marcati obsoleti.
4. **Guasto del fornitore.** I servizi pubblici di open data cadono a volte. Riprova fra qualche minuto.
5. **Cache obsoleta.** Tira per aggiornare, o tocca l'icona di aggiornamento.

---

## Germania: « Chiave API mancante » o « Chiave non valida »

- Ottieni una chiave gratuita su [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/); è un UUID.
- Incollala in **Impostazioni → Fonti dati e posizione → Prezzi carburante (Tankerkoenig)**.
- Ancora errore? La chiave può essere limitata. Le chiavi sono personali — non pubblicarle mai.

---

## Non trovo il pulsante di ricerca

Ce n'è uno solo: il pulsante verde rialzato al centro della barra inferiore. Da qualsiasi scheda apre il foglio dei criteri; nel foglio, un secondo tocco esegue la ricerca. Se appare disattivato, sei in **modalità itinerario senza destinazione**.

---

## La posizione è « sconosciuta » o il GPS non aggancia

- La localizzazione di sistema deve essere attiva, con **Durante l'uso** concesso all'app.
- Il GPS non aggancia al chiuso. Esci, o imposta un **CAP di casa** nel profilo e cerca per area.
- « Solo posizione approssimativa » — attiva la posizione precisa nelle autorizzazioni di sistema.

---

## Il calcolo dell'itinerario è lento o fallisce

- OSRM è un servizio pubblico gratuito e a volte lento.
- Un corridoio multi-paese **trasmette risultati parziali**; il banner nomina i fornitori ancora attesi, e puoi toccare un risultato prima che arrivino gli altri.
- Riprova — la polilinea è in cache, il secondo tentativo è di solito immediato.

---

## L'adattatore OBD2 non si collega

**Non trova nulla in scansione**

- Il quadro deve essere **acceso** (accessori o marcia). Motore in moto va bene, quadro spento no.
- Il LED dell'adattatore deve essere acceso fisso. Lampeggiante o spento → reinserisci.
- Bluetooth attivo sul telefono.
- Android 12+: concedi **Ricerca Bluetooth** e **Connessione Bluetooth**.
- Fino ad Android 11: il sistema richiede la **posizione** per elencare i dispositivi Bluetooth. Regola di piattaforma, non tracciamento.

**Trovato, ma la connessione fallisce**

- *« Non risponde »* — clone economico. Attendi 30 s e riprova; avviare brevemente il motore spesso aiuta.
- *« Inizializzazione del protocollo fallita »* — chip ELM327 contraffatto. Prova un altro modello; il vLinker FS è l'opzione economica affidabile.
- *« Autorizzazione negata »* — riconcedi nelle impostazioni di sistema; alcune build Android dimenticano i permessi Bluetooth dopo un riavvio.

**Si collega, poi cade in marcia**

Usa **Reimposta la connessione** nella scheda adattatore del veicolo — ripete l'handshake senza dimenticare l'accoppiamento. Se persiste, attiva **Impostazioni → Guida e consumo → Registrazione di debug OBD2**, fai un viaggio, esporta il log XML e allegalo a una segnalazione. Poi disattiva la registrazione.

**Il contachilometri segna 0 o è sbagliato**

La tua auto potrebbe non pubblicare il PID A6. L'app riprova con il PID 31 e il modo 22 del costruttore. Alcune europee prima del 2008 non pubblicano affatto il contachilometri via OBD2 — allora digitalo a ogni rifornimento.

---

## La registrazione automatica non è partita

Le serve tutto questo:

1. Un adattatore **accoppiato a un veicolo**.
2. **Registrazione automatica** attiva per quel veicolo.
3. L'autorizzazione di posizione **« Consenti sempre »**.
4. Bluetooth attivo e nessuna ottimizzazione batteria che uccida l'app.

Controlla anche la **soglia di velocità di partenza** nell'editor di veicolo — un'uscita a passo d'uomo da un parcheggio potrebbe non raggiungerla mai.

> **iOS:** il risveglio di sistema per « collegarsi appena l'adattatore si accende » non esiste ancora ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). Su iOS avvia i viaggi a mano.

---

## Il mio consumo sembra sbagliato

Procedi in quest'ordine:

1. **Apri il viaggio e leggi la scheda di salute della comunicazione OBD2.** Se la copertura è ben sotto il 100 %, i vuoti sono stati riempiti con stime GPS e la media è un misto, non una misura.
2. **Guarda il rapporto del pieno nella scheda Viaggi.** Se dice che le stime sono del *n* % sopra o sotto la verità della pompa, l'app lo sa già e si è appena corretta — aspettati movimento nei prossimi viaggi.
3. **Controlla la capacità del serbatoio** sul veicolo. Una capacità sbagliata produce per mesi autonomie credibili ma errate.
4. **Controlla i tuoi chilometraggi.** Il consumo è litri ÷ chilometri, e i chilometri vengono interamente da ciò che digiti.
5. **Controlla di aver spuntato « Pieno ».** Solo le finestre da pieno a pieno possono calibrare qualcosa.
6. **Guarda il badge di precisione** nella scheda Carburante. *Bassa* significa che nulla ha ancora ancorato il modello — il valore è un'uscita di modello, e lo dichiara.

Contesto: Come funziona Sparkilo → Come un litro diventa un numero.

---

## « Abbiamo trovato uno scarto di X litri »

Hai erogato più di quanto i viaggi registrati spieghino. Rispondi alle due domande della riconciliazione: un rifornimento mancante o mal digitato riceve una **voce di correzione**, un viaggio non registrato riceve un **viaggio virtuale**. Entrambi restano modificabili. Lasciarlo irrisolto distorce la calibrazione, quindi due tocchi valgono la pena. Vedi Registro rifornimenti e consumi.

---

## La miniatura in sovrimpressione non mostra un prezzo

L'overlay di avvicinamento scatta solo mentre **si registra un viaggio** *e* si è dentro il raggio. Per verificarne la resa senza guidare: **Impostazioni → Strumenti di sviluppo → Prova l'overlay di avvicinamento** forza uno stato sintetico per 30 secondi.

---

## Le notifiche degli avvisi non arrivano

- Le notifiche di sistema sono consentite all'app?
- Risparmio energetico: le modalità aggressive di Android uccidono il lavoro di fondo. Imposta l'app su **non limitata**.
- Il telefono poteva essere offline nella finestra prevista; il controllo riprende alla prossima finestra di rete.
- Il prezzo potrebbe semplicemente non aver superato la soglia.
- Il timbro **Ultimo controllo** in fondo alla schermata degli avvisi dice se l'attività gira. Timbro vecchio + zero scatti = il sistema la sta uccidendo.

---

## Il widget nella schermata Home è fermo

- Android limita gli aggiornamenti dei widget a circa uno ogni 30 minuti; è una regola di sistema.
- Tocca l'**icona di aggiornamento sul widget** — ricarica i prezzi senza aprire l'app.
- Aspetto e variante di contenuto si impostano per profilo in **Impostazioni → Unità e visualizzazione**.

---

## La mappa mostra tessere grigie o vuote

- Di solito una connessione debole; scorri per aggiornare.
- Se persiste, i server delle tessere potrebbero limitare il traffico — riprova fra qualche minuto.
- Prova a commutare **Impostazioni → Privacy e dati → Carica le tessere tramite il proxy Sparkilo**; i due percorsi falliscono in modo indipendente.

---

## La scansione di pompa o scontrino non legge nulla

- La build **F-Droid** non ha alcuna scansione — il riconoscimento del testo sul dispositivo esiste solo nelle build Play / App Store. Digita il rifornimento a mano.
- Il riflesso sul display della pompa è la causa più comune. Fai ombra, mettiti frontale, riempi l'inquadratura con le cifre.
- Se legge le etichette ma non i numeri, usa **Segnala errore di scansione** perché il ritaglio serva a migliorare il riconoscimento.

---

## L'app impiega molto ad avviarsi

Attiva **Traccia di inizializzazione all'avvio** (Funzioni e modalità d'uso → Sviluppatore e sperimentale), riavvia, poi apri gli **Strumenti di sviluppo**. La cascata nomina la fase lenta; esportala e allegala a una segnalazione.

*Ogni barra è una fase di inizializzazione con la sua durata — un avvio lento smette di essere una supposizione.*

---

## L'app va in crash all'avvio

- Svuota la cache dalle impostazioni applicazioni del dispositivo.
- Se persiste, apri una segnalazione con versione di Android, modello del telefono, versione **e numero di build** da Impostazioni → Informazioni, e il registro errori salvato (l'app lo propone al prossimo avvio; il file va nei Download).

---

## Come faccio il backup dei dati?

**Impostazioni → Backup e ripristino → Esporta backup** scrive uno ZIP nei Download; il ripristino offre unisci o sostituisci. Per un'esportazione leggibile da macchina, usa invece **Privacy e dati → Esporta o elimina → Esporta i miei dati → Archivio ZIP**.

TankSync **non** è un backup — replica categorie scelte, e i viaggi solo se hai attivato anche la loro sincronizzazione.

---

## Come elimino tutto?

- **Dispositivo:** Privacy e dati → Esporta o elimina → **Elimina tutti i miei dati**. Irreversibile.
- **Server (TankSync):** elimina prima il lato server — Sincronizzazione e account → Trasparenza dei dati → **Elimina account** rimuove ogni riga di tua proprietà in una transazione e nomina ogni tabella che non è stato possibile cancellare.

Dettagli: Privacy, dati e sincronizzazione → I tuoi diritti.

---

## Posso usare l'app offline?

In parte. I preferiti mostrano gli ultimi prezzi noti, le tessere consultate di recente sono in cache, e rifornimenti e viaggi sono interamente locali. Scoprire nuove stazioni richiede una chiamata di rete.

---

## Dov'è finita la scheda Carburante o Viaggi?

Appartengono alle modalità **Medio** e **Completo**. Se una è sparita, una preimpostazione o un interruttore l'ha spenta: Impostazioni → Funzioni e modalità d'uso → Consumo.

---

## Altro aiuto

- **Bug:** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — usa il modello Bug Report e allega il registro errori salvato.
- **Idee:** il modello Feature Request, o prima le [Discussions](https://github.com/fdittgen-png/tankstellen/discussions).
- **Domande sulla privacy:** l'[informativa](https://fdittgen-png.github.io/tankstellen/privacy-policy/), o fdittgen@gmail.com.

---

**Torna a:** la home della guida
