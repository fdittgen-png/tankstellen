# Risoluzione problemi e FAQ

Ordinato all'incirca per frequenza reale.

---

## Prima di tutto: controlla la versione

<img src="guide/about-1.jpg" width="340" alt="Schermata Informazioni con versione e numero di build">

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

Contesto: [Come funziona Sparkilo → Come un litro diventa un numero](User-it-How-It-Works#come-un-litro-diventa-un-numero).

---

## « Abbiamo trovato uno scarto di X litri »

Hai erogato più di quanto i viaggi registrati spieghino. Rispondi alle due domande della riconciliazione: un rifornimento mancante o mal digitato riceve una **voce di correzione**, un viaggio non registrato riceve un **viaggio virtuale**. Entrambi restano modificabili. Lasciarlo irrisolto distorce la calibrazione, quindi due tocchi valgono la pena. Vedi [Registro rifornimenti e consumi](User-it-Fuel-And-Consumption#quando-i-conti-non-tornano).

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

<img src="guide/developer-tools-2.jpg" width="340" alt="Traccia di inizializzazione all'avvio a cascata con i tempi per fase">

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

Dettagli: [Privacy, dati e sincronizzazione → I tuoi diritti](User-it-Privacy-Profiles-Sync#i-tuoi-diritti-secondo-il-gdpr).

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

**Torna a:** [la home della guida](User-it-Home)
