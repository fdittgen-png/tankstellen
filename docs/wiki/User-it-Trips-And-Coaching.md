# Viaggi ed eco-coaching

La scheda 🛣️ **Viaggi** è un registro automatico più un istruttore di guida. Compare nella modalità **Completo**.

---

## La scheda Viaggi

<img src="guide/trips-tab.jpg" width="340" alt="Scheda Viaggi: confronto mensile, rapporto del pieno ed elenco viaggi col pulsante di registrazione">

*Totali del mese, l'ultimo rapporto del pieno, poi l'elenco dei viaggi. Il pulsante flottante avvia una registrazione.*

Il confronto mensile richiede almeno tre viaggi al mese prima di confrontare — con meno, la media è rumore, non tendenza.

<img src="guide/trips-map.jpg" width="340" alt="Tutti i viaggi registrati su una mappa, colorati per viaggio">

*L'icona mappa nella barra disegna ogni viaggio registrato su una mappa — un anno di guida a colpo d'occhio, e un modo semplice per individuare i percorsi che vale la pena ottimizzare.*

---

## Due modi di registrare

### Col solo telefono

Nessun hardware. L'app rileva percorso, distanza, durata e velocità dal GPS, e **modella** il consumo dalla calibrazione del veicolo e dalla tua guida. Segnalato ovunque con `~` e una nota esplicita « stima GPS ».

La precisione parte male e migliora: ogni finestra di rifornimento chiusa riancora il modello alla pompa, così dopo una manciata di pieni un viaggio GPS cade di solito entro pochi punti percentuali. Fino ad allora è etichettato preliminare, non abbellito.

### Con un adattatore OBD2

Dati motore invece di deduzioni: portata reale (misurata dove l'auto pubblica il PID 5E), regime, carico, acceleratore. Nessun periodo di apprendimento per il consumo, e il coaching accede a segnali che il GPS non vede — marcia, giri, carico motore. La configurazione è in [Veicoli e OBD2](User-it-Vehicles-And-OBD2#ladattatore-obd2).

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

<img src="guide/trip-detail-1.jpg" width="340" alt="Riepilogo viaggio: data, veicolo, adattatore, distanza, durata, consumo, carburante, costo e velocità">

*Il riepilogo dichiara la propria provenienza — veicolo, adattatore, e un badge **Traccia GPS** sulla distanza per sapere da dove vengono i chilometri.*

<img src="guide/trip-detail-2.jpg" width="340" alt="Mappa del percorso colorata per efficienza con legenda e scheda dei principali comportamenti dispendiosi">

*Il percorso è colorato per efficienza — verde sotto 6 L/100 km, ambra fino a 10, rosso oltre. Dove è finito il carburante, geograficamente.*

Questa colorazione è la vista più azionabile dell'app: mette su mappa le porzioni costose del tuo tragitto quotidiano. Un tratto rosso che si ripete ogni giorno è un incrocio, una salita o un'abitudine che vale la pena cambiare.

<img src="guide/trip-detail-3.jpg" width="340" alt="Selettore « com'è andato il viaggio », dove è finito il carburante, distribuzioni di acceleratore e regime">

*Tre blocchi: il tuo verdetto, l'attribuzione del carburante, e come hai davvero sollecitato il motore.*

- **« Com'è andato questo viaggio? »** — *Fluido / Moderato / Aggressivo*. La tua risposta serve a calibrare le soglie di stile di guida su viaggi reali, non a darti un voto.
- **Dove è finito il carburante** — litri attribuiti alle accelerazioni forti rispetto alla guida normale. Numeri assoluti piccoli su un viaggio breve; conta il rapporto.
- **Posizione dell'acceleratore** e **regime motore** come distribuzioni — la quota di viaggio passata in veleggio, carico leggero, deciso e pieno gas, e in ciascuna fascia di giri. Una quota alta sopra i 3000 giri sul tragitto casa-lavoro significa che cambi marcia troppo tardi, e costa.

<img src="guide/trip-detail-4.jpg" width="340" alt="Diagnostica di campionamento GPS e scheda ripiegata sulla salute della comunicazione OBD2">

*Due diagnostiche: la completezza della traccia GPS e il comportamento dell'adattatore.*

<img src="guide/trip-obd2-health.jpg" width="340" alt="Salute della comunicazione OBD2 aperta: misure, copertura, adattatore, protocollo, durata, fine sessione">

*Aperta, la scheda OBD2 si spiega in chiaro.*

**Leggi questa scheda prima di dubitare di un numero di consumo.** Indica quante misure portavano dati motore, la **percentuale di copertura** risultante, adattatore e protocollo negoziato, la durata della sessione, perché è finita (`userStopped`, una disconnessione, una morte del processo), e la riga decisiva: *« I valori di consumo vengono dall'adattatore, non da stime GPS. »* Se la copertura è ben sotto il 100 %, i vuoti sono stati riempiti con stime GPS e la media del viaggio è un misto.

<img src="guide/trip-detail-5.jpg" width="340" alt="Grafici: velocità, portata di carburante e regime motore lungo il viaggio">

*Velocità, portata e regime su un asse temporale comune — le tre curve che spiegano qualsiasi numero di consumo.*

<img src="guide/trip-detail-6.jpg" width="340" alt="Grafici: regime, carico motore, posizione acceleratore e temperatura liquido">

*Carico motore e acceleratore affiancati mostrano la differenza fra far lavorare il motore e limitarsi a farlo girare.*

<img src="guide/trip-detail-7.jpg" width="340" alt="Grafici: liquido di raffreddamento, altitudine dalla partenza, temperatura aria aspirata e anticipo">

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

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Interruttori di coaching, ricompense, carte fedeltà, riconoscimenti e registrazione di debug OBD2">

*Impostazioni → Guida e consumo. Riconoscimenti e punteggi si possono nascondere in tutta l'app se la gamification non fa per te.*

---

## Il cruscotto carbonio

<img src="screenshots/carbon-dashboard.png" width="340" alt="Cruscotto carbonio: costo e CO2 per lunghezza di viaggio e fascia di velocità">

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

<img src="guide/full/trip-detail.jpg" width="420" alt="Pagina completa del dettaglio viaggio assemblata da otto catture">

</details>

---

**Vedi anche:** [Veicoli e OBD2](User-it-Vehicles-And-OBD2) · [Registro rifornimenti e consumi](User-it-Fuel-And-Consumption)
**Avanti:** [Storico e previsioni prezzi →](User-it-Price-History-And-Predictions)
