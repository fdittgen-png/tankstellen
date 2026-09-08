# Ricarica elettrica

Sparkilo non è solo per i motori termici. Le colonnine vengono da [OpenChargeMap](https://openchargemap.org), il più grande registro comunitario aperto al mondo.

---

## Attivare

Due interruttori indipendenti, entrambi in **Impostazioni → Funzioni e modalità d'uso → Ricerca e mappa**:

- **Ricarica EV** — la funzione stessa (ricerca, pagine di dettaglio, preferiti).
- **Mostra le colonnine di ricarica** — se le colonnine compaiono nei risultati e sulla mappa.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Interruttori del gruppo Ricerca e mappa inclusi Ricarica EV e Mostra colonnine">

*Puoi mostrare stazioni, colonnine, o entrambe. Chi guida solo elettrico di solito disattiva **Mostra le stazioni di servizio**.*

Poi crea un veicolo in **Impostazioni → Veicoli e OBD2 → I miei veicoli → Aggiungi**, scegliendo **Elettrico** come motorizzazione. Un veicolo elettrico porta capacità della batteria (kWh), potenze massime di ricarica AC e DC (kW) e i connettori supportati (Tipo 2, CCS, CHAdeMO, Tesla, Schuko, Tipo 1, presa domestica). Le ricerche si limitano allora alle colonnine che la tua auto può davvero usare.

---

## Come funzionano i dati

<img src="guide/data-sources-location.jpg" width="340" alt="Campo chiave Ricarica EV con la chiave condivisa predefinita">

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

<img src="screenshots/map-ev-charging.png" width="340" alt="Mappa in modalità EV con i chip di filtro per connettore">

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

**Vedi anche:** [Trovare stazioni](User-it-Finding-Stations) · [Registro rifornimenti e consumi](User-it-Fuel-And-Consumption)
**Avanti:** [Veicoli e OBD2 →](User-it-Vehicles-And-OBD2)
