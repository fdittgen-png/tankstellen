# Trovare stazioni

Livello 1 dei [tre livelli di risparmio](User-it-How-It-Works#i-tre-livelli-di-risparmio): pagare meno al litro.

---

## Un pulsante, un modello mentale

La barra inferiore ha un solo attivatore di ricerca — il pulsante verde rialzato al centro. È contestuale, non modale:

- **Da qualsiasi scheda** → apre il foglio dei criteri.
- **Dai risultati o dalla mappa** → riapre il foglio con i tuoi ultimi valori.
- **Dentro il foglio** → esegue la ricerca.

L'etichetta dice cosa farà, e in modalità itinerario resta disattivato finché non c'è una destinazione. Non esistono di proposito pulsanti separati per « cerca vicino » e « cerca lungo il percorso ».

---

## Impostare i criteri

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Criteri: vicinanze o itinerario, indirizzo, chip carburante, raggio, solo aperte, servizi, marche">

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

### Come funziona davvero

Una ricerca nelle vicinanze invia **le tue coordinate (o un codice di regione) e un raggio** al fornitore ufficiale del tuo paese — mai la tua identità. I paesi che pubblicano un file giornaliero (Spagna, Italia) sono filtrati sul dispositivo: quelle ricerche non richiedono alcuna chiamata di rete una volta messo in cache il file.

---

## Leggere una scheda di risultato

<img src="guide/search-results.jpg" width="340" alt="Elenco risultati con prezzo, freccia di tendenza, freschezza, servizi, distanza e stella">

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

La freschezza è una proprietà del **fornitore del paese**, non dell'app. Un prezzo spagnolo di 14 ore non è un bug: quel paese pubblica una volta al giorno. Vedi [Come funziona Sparkilo → Una fonte per paese](User-it-How-It-Works#una-fonte-dati-per-paese).

### Gesti di scorrimento

- **Scorri a destra** — apri nella tua app di navigazione (Google Maps, Waze, OsmAnd, Organic Maps).
- **Scorri a sinistra** — nascondi la stazione da tutti i risultati futuri. Si ripristina da **Privacy e dati → Dati su questo dispositivo → Stazioni ignorate**.

---

## Dettaglio di una stazione

<img src="guide/station-detail-1.jpg" width="340" alt="Dettaglio stazione: tabella prezzi per carburante, aggiungi rifornimento, orari, zona">

*Tocca una scheda. L'intestazione ripiega da marca a nome a via, così un Intermarché senza campo marca mostra comunque « Intermarché ».*

Il blocco superiore è la **tabella completa dei prezzi** — ogni qualità che il fornitore pubblica per quella stazione, con `--` dove non ne pubblica. È il modo più rapido di vedere se la stazione E85 conveniente regge anche sul diesel.

**Aggiungi rifornimento** precompila stazione, carburante e prezzo nel modulo — il maggior risparmio di tempo dell'app se registri i tuoi rifornimenti.

<img src="guide/station-detail-2.jpg" width="340" alt="Segue il dettaglio: zona, servizi, metodi di pagamento, la tua valutazione, storico prezzi">

*Più in basso: servizi, metodi di pagamento accettati, la tua valutazione privata a stelle, e lo storico locale dei prezzi a 30 giorni.*

Le azioni della barra superiore sono, da sinistra a destra: **creare un avviso di prezzo**, **scansionare un QR di pagamento**, **segnalare un prezzo errato** e **aggiungere ai preferiti**.

---

## La mappa

<img src="guide/map-view.jpg" width="340" alt="Mappa con segnaposto colorati per prezzo, cerchio del raggio e legenda economico/caro">

*Il colore è relativo a ciò che è a schermo: verde la più economica visibile, rosso la più cara. Il piè di pagina indica numero di stazioni, raggio ed età dei dati.*

- **I cluster** raggruppano i segnaposto allo zoom indietro; un tocco ingrandisce.
- **Pressione prolungata** ovunque per lasciare un marcatore e cercare da lì.
- Il **selettore EV** in alto a destra passa alle colonnine — vedi [Ricarica elettrica](User-it-EV-Charging).
- **Condividi** invia la vista corrente a qualcuno.

Le tessere vengono da OpenStreetMap. Per impostazione predefinita passano dal proxy UE dello sviluppatore così che OpenStreetMap non veda mai il tuo IP; puoi disattivare il proxy in Impostazioni → Privacy e dati e caricare direttamente. La build F-Droid non usa mai il proxy.

---

## Il radar stazioni di servizio

Una scansione in tempo reale attorno alla tua posizione, pensata per **guidare**.

<img src="screenshots/radar-start.png" width="340" alt="La pillola « Avvia il radar stazioni » nella schermata dei risultati">

*Dopo ogni ricerca nelle vicinanze appare una pillola flottante in basso a destra. Un tocco avvia il radar.*

### Come funziona davvero

Il radar aggiorna la posizione GPS, recupera le **posizioni** delle stazioni su un ampio corridoio di 60 km e fonde una richiesta diretta nel raggio: non può quindi mai mostrare meno di una ricerca normale. Le stazioni non si spostano, perciò quelle posizioni restano in cache fino a un'ora e vengono riusate; solo il **prezzo** di una stazione a cui ti stai avvicinando viene recuperato al momento giusto. È questo che rende un radar sempre acceso poco costoso in dati e batteria.

<img src="screenshots/radar-active.png" width="340" alt="Radar attivo: segnaposto di prezzo in tempo reale ed elenco ordinato per distanza con barre di prossimità">

*Attivo: risultati ordinati per distanza, ciascuno con una barra che si riempie all'avvicinarsi.*

### Durante la registrazione di un viaggio

Il radar fissa una scheda **Stazione più vicina** in cima alla schermata di registrazione — nome, prezzo per il tuo carburante, distanza, e una barra che arriva al 100 % all'arrivo. Scorri a destra/sinistra per sfogliare le candidate. Entrando nel raggio di avvicinamento configurato, la miniatura in sovrimpressione passa a una grande visualizzazione del prezzo; vedi [Viaggi ed eco-coaching → L'overlay di avvicinamento](User-it-Trips-And-Coaching#loverlay-di-avvicinamento).

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

<img src="guide/full/station-detail.jpg" width="420" alt="Pagina completa del dettaglio stazione assemblata da due catture">

</details>

---

**Vedi anche:** [Pianificazione itinerario](User-it-Route-Planning) · [Preferiti e avvisi](User-it-Favorites-And-Alerts) · [Storico prezzi](User-it-Price-History-And-Predictions)
**Avanti:** [Pianificazione itinerario →](User-it-Route-Planning)
