# Preferiti e avvisi di prezzo

La scheda ⭐ è la tua rosa di stazioni, più i robot che la sorvegliano per te.

---

## Preferiti

<img src="guide/favorites.jpg" width="340" alt="Scheda Preferiti con due stazioni salvate, prezzi per carburante e la scheda avvisi">

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

<img src="guide/price-alerts.jpg" width="340" alt="Schermata avvisi: contatori attivi/oggi/questa settimana, avvisi di stazione e di zona">

*Tre contatori in alto — regole attive, scatti oggi e questa settimana — poi i due tipi di avviso. Il piè di pagina data l'ultimo controllo in background.*

Ce ne sono due tipi, che rispondono a domande diverse.

### Avviso di stazione — « avvisami quando *questa* pompa cala »

Creato dalla pagina di dettaglio di una stazione (icona campanella). Scegli il carburante, fissa una soglia, salva. Ideale per la stazione che già usi.

### Avviso di zona — « avvisami quando *qui intorno* cala »

<img src="guide/price-alert-create.jpg" width="340" alt="Crea un avviso di zona: etichetta, tipo di carburante, soglia, raggio, frequenza, posizione o CAP">

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
- **Un effetto collaterale utile:** lo stesso controllo scrive un rilevamento di prezzo nel tuo storico locale. Una stazione sotto avviso costruisce quindi il suo storico a 30 giorni in ore anziché settimane — ed è ciò che fa comparire in fretta il banner *momento migliore per il pieno*. Vedi [Storico prezzi](User-it-Price-History-And-Predictions#la-fase-di-apprendimento).
- **Se le notifiche sono spente a livello di sistema**, l'interruttore dell'app non può far scattare nulla.

---

## Statistiche

I contatori in alto mostrano quante regole sono attive e quante volte sono scattate oggi e questa settimana — un test rapido per capire se l'attività di fondo gira davvero. Una fila di zeri con più avvisi attivi e un timbro « ultimo controllo » vecchio è il sintomo classico di un risparmio energetico che uccide l'attività.

---

## Fermare gli avvisi

Disattivare un avviso lo mette in pausa senza perdere la regola; scorrere a sinistra lo elimina. Togliere la stazione dai preferiti **non** elimina i suoi avvisi.

---

**Vedi anche:** [Storico e previsioni prezzi](User-it-Price-History-And-Predictions) · [Riferimento impostazioni → Prezzi e avvisi](User-it-Settings-Reference#prezzi-e-avvisi)
**Avanti:** [Ricarica elettrica →](User-it-EV-Charging)
