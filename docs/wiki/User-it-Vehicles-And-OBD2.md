# Veicoli e OBD2

Tutto ciò che l'app sa della *tua auto*. È questa pagina a decidere se i numeri di consumo di tutte le altre siano affidabili.

---

## Perché all'app serve un veicolo

Senza veicolo, Sparkilo è un cercaprezzi. Con uno può convertire litri e chilometri nel *tuo* costo al chilometro, stimare l'autonomia e — con un adattatore — modellare la portata istantanea di carburante.

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Schermata Veicoli e OBD2 con le tessere I miei veicoli e Adattatore OBD2">

*Impostazioni → Veicoli e OBD2. Nota l'etichetta di ambito sulla tessera adattatore: gli adattatori si accoppiano **per veicolo**, non per telefono.*

<img src="guide/my-vehicles.jpg" width="340" alt="Elenco veicoli con un veicolo attivo">

*Il segno di spunta verde indica il veicolo attivo — quello a cui vengono attribuiti nuovi rifornimenti e viaggi.*

---

## Identità e motorizzazione

<img src="guide/vehicle-edit-1.jpg" width="340" alt="Editor veicolo: nome, VIN facoltativo, leggi il VIN dall'auto, selettore di motorizzazione">

*Chiamalo come lo riconoscerai. Il VIN è facoltativo.*

### Il VIN, e cosa porta

Inserire (o leggere) il VIN permette all'app di risalire a cilindrata, numero di cilindri, potenza e tipo di carburante, che sono gli ingressi del modello di consumo. **Leggi il VIN dall'auto** lo recupera in un secondo via OBD2.

La decodifica online del VIN è un **consenso separato** — l'app chiede prima di inviare qualcosa, e la decodifica offline parziale funziona anche se rifiuti. Un VIN è un dato personale; trattalo come tale.

### Motorizzazione

**Termico / Ibrido / Elettrico** cambia i campi sottostanti. Il termico chiede capacità del serbatoio, potenza e carburante preferito; l'elettrico chiede batteria e connettori.

---

## Capacità, potenza e flex-fuel

<img src="guide/vehicle-edit-2.jpg" width="340" alt="Blocco termico: capacità serbatoio, potenza motore, carburante preferito, interruttore multi-carburante, adattatore accoppiato">

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

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibrazione di riferimento: adattatore accoppiato, avanzamento 210/270, avviso di situazioni mancanti e barre per situazione">

*210 campioni su 270. Due situazioni di guida sono ancora vuote, e l'app lo dice invece di fingere completezza.*

Ogni campione OBD2 è archiviato in una situazione di guida: **minimo, stop & go, urbano, autostrada, decelerazione, salita / carico, avviamento a freddo, carico prolungato / traino, veleggio**. Le medie per situazione formano il riferimento del veicolo — il modello che produce un L/100 km plausibile quando l'adattatore manca o un PID smette di rispondere.

<img src="guide/vehicle-edit-4.jpg" width="340" alt="Barre di campioni per situazione, azzeramento del riferimento e selettore di modalità di calibrazione">

*Le situazioni con zero campioni sono quelle che ripiegheranno su valori predefiniti. Qui due: decelerazione e traino.*

### Basata su regole o fuzzy

<img src="guide/vehicle-edit-5.jpg" width="340" alt="Modalità di calibrazione basata su regole o fuzzy, azioni di azzeramento e promemoria di manutenzione">

*La modalità fuzzy è quella predefinita e la scelta migliore per quasi tutti.*

- **Basata su regole** assegna ogni campione a esattamente una situazione. Prevedibile, ma oscilla da un campione all'altro fra « urbano » e « autostrada » quando viaggi vicino al confine — intorno ai 60 km/h per esempio.
- **Fuzzy** distribuisce ogni campione su tutte le situazioni in base al grado di appartenenza. Liscia proprio dove la modalità a regole salta, al prezzo di essere più difficile da seguire campione per campione.

### I pulsanti di azzeramento — e cosa fanno davvero

- **Azzera il rendimento volumetrico** scarta il η_v appreso e ripristina il valore predefinito 0,85. η_v è un parametro del modello speed-density che stima la portata d'aria in assenza di debimetro. Azzeralo solo dopo un intervento meccanico; un numero strano è più spesso un problema di copertura. Le auto che pubblicano la portata direttamente (PID 5E) non lo usano affatto.
- **Ripristina dal database veicoli** ricarica cilindrata, potenza e valori predefiniti dal catalogo integrato, scartando le tue immissioni manuali.
- **Azzera il riferimento per situazione** (nella scheda di riferimento) cancella ogni campione appreso e ti riporta ai valori a freddo finché nuovi viaggi non riempiono il profilo.

Nessuno di questi tocca il **guadagno pompa**, appreso dalle finestre da pieno a pieno e residente fuori dal modello OBD2 — vedi [Come funziona Sparkilo → Come un litro diventa un numero](User-it-How-It-Works#come-un-litro-diventa-un-numero).

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

<img src="guide/full/vehicle-edit.jpg" width="420" alt="Editor di veicolo completo assemblato da cinque catture">

</details>

---

**Vedi anche:** [Viaggi ed eco-coaching](User-it-Trips-And-Coaching) · [Risoluzione problemi → OBD2](User-it-Troubleshooting-FAQ#ladattatore-obd2-non-si-collega)
**Avanti:** [Registro rifornimenti e consumi →](User-it-Fuel-And-Consumption)
