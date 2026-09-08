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

<img src="guide/features-and-mode-1.jpg" width="340" alt="Gestione funzioni con le preimpostazioni Base, Medio, Completo e Personalizzato">

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

<img src="guide/profile-edit-1.jpg" width="340" alt="Modifica profilo — nome, carburante derivato dal veicolo, raggio predefinito">

*Impostazioni → Profili e regione → modifica. Il carburante preferito è **derivato dal veicolo predefinito** — rimuovi il veicolo se vuoi sceglierlo tu.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Sezione Regione del profilo — selettori di paese e lingua">

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

<img src="guide/search-results.jpg" width="340" alt="Intestazione dei risultati che nomina la fonte prezzi ufficiale francese">

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

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Dati su questo dispositivo: ogni categoria di dati conservata localmente, con dimensione e conteggio">

*Impostazioni → Privacy e dati → Dati su questo dispositivo mostra ogni categoria con un contatore reale: nulla dei tuoi dati ti è invisibile.*

Solo quattro cose lasciano il telefono, e tre sono facoltative:

| Cosa esce | Quando | Facoltativo? |
|---|---|---|
| Coordinate di ricerca o codice di regione | A ogni ricerca, verso la fonte prezzi del paese | Necessario per i prezzi in tempo reale |
| Area di mappa + il tuo IP | Caricamento tessere tramite il proxy UE dello sviluppatore | Sì — proxy spento, le tessere arrivano direttamente da OpenStreetMap |
| Tracce di crash | Solo con *Segnalazione errori* attiva | Sì — disattivata di default |
| Le tue righe sincronizzate | Solo con *TankSync* attivo | Sì — disattivato di default |

**La tua identità non fa mai parte di una richiesta di prezzo.** Il conteggio completo: [Privacy, dati e sincronizzazione](User-it-Privacy-Profiles-Sync).

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

<img src="guide/trips-tab.jpg" width="340" alt="Rapporto del pieno con copertura e scarto di calibrazione">

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
- **Se guidi senza registrare, i conti non torneranno** — e l'app lo dice invece di arrangiarsi. Vedi la riconciliazione in [Registro rifornimenti e consumi](User-it-Fuel-And-Consumption#quando-i-conti-non-tornano).

---

## Come l'app impara la tua guida

Separatamente dal guadagno pompa, un veicolo porta una **linea di riferimento per situazione di guida**: quanto consuma al minimo, in stop & go, in città, in autostrada, in decelerazione, in salita o a carico, da freddo, sotto carico prolungato e in veleggio.

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibrazione di riferimento con campioni per situazione e avviso sulle situazioni mancanti">

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

<img src="guide/settings-root-1.jpg" width="340" alt="Radice delle impostazioni con tessere tematiche e campo di ricerca">

*Ogni parametro ha esattamente una casa. Se ricordi il tema, non devi mai scorrere.*

Mappa completa di tutte le schermate: [Riferimento impostazioni](User-it-Settings-Reference).

---

**Avanti:** [Trovare stazioni →](User-it-Finding-Stations)
