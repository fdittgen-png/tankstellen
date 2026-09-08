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

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Controlli privacy: proxy delle tessere di mappa e caricamento dei loghi dei marchi">

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

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Utilizzo dello spazio suddiviso per categoria con le dimensioni">

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

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Durata della cache per categoria e l'azione di svuotamento della cache">

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

<img src="guide/sync-and-account.jpg" width="340" alt="Sincronizzazione e account con lo stato TankSync, un avviso di schema obsoleto e la voce Consensi">

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

Per un'istantanea ripristinabile invece di un'esportazione di dati, usa **Impostazioni → Backup e ripristino** — vedi [Riferimento impostazioni](User-it-Settings-Reference#backup-e-ripristino).

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

**Vedi anche:** [Riferimento impostazioni](User-it-Settings-Reference) · [Come funziona Sparkilo → Dove vivono i tuoi dati](User-it-How-It-Works#dove-vivono-i-tuoi-dati)
**Avanti:** [Risoluzione problemi e FAQ →](User-it-Troubleshooting-FAQ)
