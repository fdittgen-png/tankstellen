# Riferimento impostazioni

Ogni schermata dell'albero delle impostazioni e — più utile — **quanto ti costa ogni interruttore** in batteria, dati, precisione o privacy.

---

## La forma dell'insieme

Le impostazioni sono un **albero a due livelli**: una radice di tessere tematiche, una schermata per tema, e una ricerca per parola chiave su tutte.

<img src="guide/settings-root-1.jpg" width="340" alt="Radice delle impostazioni, metà superiore: campo di ricerca e le prime sei tessere">

*Digita « raggio », « OBD2 » o « tema » nel campo di ricerca e la tessera giusta emerge — non serve ricordare quale tema possiede un parametro.*

<img src="guide/settings-root-2.jpg" width="340" alt="Radice delle impostazioni, metà inferiore: funzioni, fonti dati, sincronizzazione, privacy, backup, avanzate">

*Dodici temi in tutto. Per arrivarci: l'ingranaggio in alto a destra delle schermate principali.*

Tre regole di progetto rendono l'albero prevedibile:

1. **Una casa per parametro.** Nulla compare due volte; i rimandi puntano all'unico proprietario.
2. **Etichette di ambito.** Una tessera marcata *questo profilo*, *tutti i profili* o *questo veicolo* dice in anticipo quanto lontano arriva una modifica.
3. **Stati vuoti onesti.** Una sezione con la funzione spenta lo dice e rimanda all'interruttore, invece di nascondersi.

---

## Profili e regione

*Paese, lingua, carburante, raggio di ricerca, itinerari · ambito: questo profilo*

<img src="guide/profile-edit-1.jpg" width="340" alt="Editor di profilo: nome, carburante preferito, raggio predefinito">

*Il carburante preferito è derivato dal veicolo predefinito. Per sceglierlo direttamente, togli il veicolo dal profilo.*

| Impostazione | Impatto |
|---|---|
| **Nome del profilo** | Estetico, ma è ciò che mostra il chip di profilo |
| **Carburante preferito** | Il prezzo in evidenza su ogni scheda; il predefinito degli avvisi; ciò per cui ottimizza la ricerca su itinerario |
| **Raggio predefinito** | Più grande = più risultati e ricerche più lente |

<img src="guide/profile-edit-2.jpg" width="340" alt="Pianificazione itinerario: segmento, deviazione massima, risparmio minimo, scelta per segmento, candidate">

*Valori predefiniti dell'itinerario. **Candidate per punto di campionamento** scambia accuratezza con velocità sui corridoi lunghi.*

<img src="guide/profile-edit-3.jpg" width="340" alt="Visualizzazione e stazioni, visibilità delle note, schermata iniziale, raggio dell'overlay">

*Tre cose distinte da conoscere.*

- **Evita le autostrade** cambia l'itinerario calcolato stesso: le aree di servizio smettono di essere candidate — in genere un risparmio, dato che il carburante autostradale è il più caro di ogni corridoio.
- **Note delle stazioni** — *Locale* (solo questo dispositivo), *Privato* (sincronizzato sul tuo account) o *Condiviso* (visibile ad altri utenti). È una scelta di privacy, non di archiviazione.
- **Schermata iniziale** — su cosa si apre l'app: Nelle vicinanze, Stazione più vicina, Preferiti o Mappa.

<img src="guide/profile-edit-4.jpg" width="340" alt="Raggio e modalità prezzo dell'overlay, veicolo predefinito, regione">

*Il raggio dell'overlay e la regola **più vicina vs più economica nel raggio** stanno nel profilo: un profilo « pendolare » e uno « vacanza » possono comportarsi diversamente.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Regione: chip di paese e di lingua">

*Il paese decide il fornitore di dati. Cambiarlo svuota i dati di stazione in cache.*

<img src="guide/profile-edit-6.jpg" width="340" alt="Chip di lingua e campo del CAP di casa">

*Un **CAP di casa** consente ricerche per area senza alcun GPS — il modo più pulito di usare l'app se non vuoi mai condividere la posizione.*

---

## Veicoli e OBD2

*Le tue auto, capacità del serbatoio, accoppiamento · ambito: questo veicolo*

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Schermata Veicoli e OBD2">

*Gli adattatori si accoppiano per veicolo: la tessera adattatore ti porta quindi dentro un veicolo invece che su una schermata globale.*

Il trattamento completo — VIN, capacità, flex-fuel, modalità di calibrazione, riferimento, soglie di registrazione automatica, promemoria — è in [Veicoli e OBD2](User-it-Vehicles-And-OBD2).

---

## Guida e consumo

*Coaching, ricompense, radar, risoluzione problemi · ambito: misto*

<img src="guide/driving-and-consumption-1.jpg" width="340" alt="Finestra del consumo in tempo reale, overlay di avvicinamento, i miei veicoli, interruttori di coaching">

*Le prime due voci sono quelle che regolerai davvero.*

| Impostazione | Impatto |
|---|---|
| **Finestra del consumo in tempo reale** (3/5/10/30 s) | Più lunga = più stabile e leggibile alla guida; più corta = abbastanza reattiva da insegnare quanto costa il pedale |
| **Overlay all'avvicinamento** | Raggio, modalità prezzo, limite di interrogazione e fissaggio schermo per il profilo attivo |
| **Coaching eco in tempo reale** | Vibrazione leggera + consiglio a schermo in accelerazione forte a velocità di crociera |
| **Coaching vocale di guida** | Lo stesso consiglio letto ad alta voce — gli occhi restano sulla strada |
| **Glide-coach beta** | Feedback aptico prima di un rosso dai semafori OpenStreetMap. **Spento di default — rischio di distrazione**, e serve rete |

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching, carte fedeltà, riconoscimenti, registrazione di debug OBD2">

*Ricompense e risoluzione problemi.*

- **Carte fedeltà** — sconti al litro applicati nei confronti di prezzo, così una stazione nominalmente più cara può risultare correttamente più economica per te.
- **Mostra riconoscimenti e punteggi** — spento, badge, punteggi e trofei spariscono da tutta l'app. Nulla smette di essere misurato; smette solo di essere mostrato.
- **Registrazione di debug OBD2** — registra ogni sessione (connessione, handshake, perdite di dati, riconnessioni) in un log XML esportabile. **Spenta di default**: scrive di continuo e conviene solo mentre si insegue un problema di adattatore.

---

## Prezzi e avvisi

*Avvisi, annunci vocali, storico, segnalazioni della comunità*

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Prezzi e avvisi: voce avvisi, nota sugli annunci vocali, funzioni di prezzo">

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

<img src="guide/units-and-display-1.jpg" width="340" alt="Tema, unità di distanza e unità di consumo">

*L'**unità di consumo** si propaga ovunque in un colpo solo — banner in tempo reale, miniatura, medie dei viaggi, statistiche, widget.*

- **Unità di distanza** segue di default il paese del profilo attivo (km o miglia).
- **Unità di consumo**: *Automatica* (mpg nel Regno Unito e negli USA, L/100 km altrove), oppure esplicitamente L/100 km, km/L o mpg.

<img src="guide/units-and-display-2.jpg" width="340" alt="Widget schermata Home: schema colori e variante di contenuto">

*Le scelte del widget portano l'etichetta **questo profilo** e valgono per ogni widget installato che mostra quel profilo, dal prossimo aggiornamento.*

**Variante di contenuto** — *solo prezzo attuale*, o *predittivo: momento migliore per il pieno* (richiede la previsione TFLite).

---

## Funzioni e modalità d'uso

*Preimpostazioni e ogni singolo interruttore*

<img src="guide/features-and-mode-1.jpg" width="340" alt="Preimpostazioni Base, Medio, Completo e lo stato Personalizzato">

*Scegliere una preimpostazione **sovrascrive** ogni singolo interruttore. Se hai regolato a mano, resta su Personalizzato.*

Le dipendenze sono applicate, non nascoste: un interruttore col prerequisito spento resta disattivato e nomina quel prerequisito.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Gruppo Ricerca e mappa: itinerari, ricarica EV, mostra stazioni, mostra colonnine, calcolatore">

*Ricerca e mappa — incluso se stazioni e colonnine compaiano affatto.*

<img src="guide/features-and-mode-3.jpg" width="340" alt="Gruppo Prezzi e avvisi: avvisi, storico, previsione TFLite, QR di pagamento, segnalazioni">

*Prezzi e avvisi. Lo storico è la funzione genitore della previsione che segue.*

<img src="guide/features-and-mode-4.jpg" width="340" alt="Gruppo Radar stazioni con annunci vocali e l'interruttore principale di sintesi vocale">

*Il radar, i suoi annunci vocali e l'interruttore principale **Feedback vocale** — spento, l'app non apre mai un motore di sintesi.*

<img src="guide/features-and-mode-5.jpg" width="340" alt="Gruppo Consumo: selettore di modalità più analisi, gamification, coach aptico, glide-coach, traccia GPS, registrazione automatica">

*Il selettore **Spento / Carburante / Carburante + Viaggi** è la forma compatta di tutta la pila consumo.*

| Interruttore | Impatto |
|---|---|
| **Statistiche consumi** | La scheda di analisi di rifornimenti e viaggi |
| **Gamification** | Punteggi di guida e badge conquistati |
| **Eco-coach aptico** | Feedback vibratorio in tempo reale alla guida |
| **Glide-coach** | Consigli eco dai semafori OpenStreetMap — richiede rete |
| **Traccia GPS dei viaggi** | Conserva i punti di percorso di ogni viaggio. Spento = database più piccolo, niente mappe dei viaggi |
| **Registrazione automatica** | Avvia un viaggio quando l'adattatore accoppiato si collega a un veicolo in movimento |

<img src="guide/features-and-mode-6.jpg" width="340" alt="PID OEM sperimentali, richiedi OBD2, cruscotto carbonio, TankSync, sincronizzazione riferimenti">

*Due interruttori qui cambiano la qualità dei dati anziché l'interfaccia.*

- **PID OEM sperimentali** — legge il livello esatto del serbatoio in litri tramite PID del costruttore su adattatori compatibili. Dati migliori dove funziona; innocuo dove no.
- **Richiedi OBD2 per la registrazione dei viaggi** — **spento**, i viaggi si registrano col solo GPS. Il coaching è ridotto (niente L/100 km istantanei, meno segnali motore) ma nulla è bloccato.
- **Sincronizzazione dei riferimenti** — carica i riferimenti di consumo per veicolo perché un secondo dispositivo li riusi. Richiede TankSync.

<img src="guide/features-and-mode-7.jpg" width="340" alt="Inserimento e scansione: carte fedeltà, OCR scontrino, condividi scontrino per importarlo">

*Inserimento e scansione. Il riconoscimento è sul dispositivo; questi interruttori decidono solo se le scorciatoie esistono.*

<img src="guide/features-and-mode-8.jpg" width="340" alt="Sviluppatore e sperimentale: feedback via PAT GitHub, modalità sviluppatore, traccia di avvio">

*Sviluppatore e sperimentale — da lasciare spento se non segnali bug.*

---

## Fonti dati e posizione

*Chiavi API, GPS, cambio automatico di profilo*

<img src="guide/data-sources-location.jpg" width="340" alt="Campi chiave API e blocco posizione">

*Una croce rossa sulla chiave prezzi è il motivo abituale di una ricerca tedesca vuota.*

| Impostazione | Impatto |
|---|---|
| **Prezzi carburante (Tankerkoenig)** | Necessaria solo per la Germania. Gratuita, per utente, nella cassaforte hardware |
| **Ricarica EV (OpenChargeMap)** | Facoltativa — sostituisce la chiave condivisa con la tua quota |
| **Aggiornamento automatico** | Aggiorna la posizione GPS prima di ogni ricerca. Spento = ricerche più rapide, posizione forse vecchia |
| **Cambio automatico di profilo** | Commuta il profilo al passaggio di un confine, così fornitore e carburante sono corretti automaticamente |

---

## Sincronizzazione e account

<img src="guide/sync-and-account.jpg" width="340" alt="Stato TankSync, avviso di schema obsoleto, passa all'e-mail, consensi, vedi i miei dati">

*Questa schermata fa emergere anche i problemi — qui uno schema TankSync auto-ospitato obsoleto che quindi non sincronizza alcune tabelle, in silenzio.*

Trattato per esteso in [Privacy, dati e sincronizzazione → TankSync](User-it-Privacy-Profiles-Sync#tanksync-sincronizzazione-cloud-facoltativa). L'essenziale:

- **Sparkilo Community / il tuo database / il database di un gruppo** — tre forme di distribuzione con tre titolari del trattamento diversi.
- **Anonimo → e-mail** — *Passa all'e-mail* conserva dati e account e aggiunge un modo di accedere da un altro dispositivo. Un account anonimo esiste solo sul dispositivo che l'ha creato.
- **Schema obsoleto** — dopo un aggiornamento, chi si auto-ospita deve rieseguire il SQL di installazione, altrimenti le nuove tabelle falliscono in silenzio.

---

## Privacy e dati

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Controlli privacy: proxy delle tessere e caricamento dei loghi">

*Due scelte di privacy legate alla rete, ciascuna formulata per ciò che davvero rivela.*

- **Carica le tessere tramite il proxy Sparkilo** — *attivo*: il server UE dello sviluppatore vede l'area di mappa e il tuo IP e recupera le tessere per te. *Spento*: le tessere arrivano da tile.openstreetmap.org, che allora vede il tuo IP. Nessuna opzione significa « niente rete »; scegli da chi essere visto. La build F-Droid non usa mai il proxy.
- **Carica i loghi delle marche da Internet** — *spento* di default; si usano loghi generici integrati. Attivo, arrivano da logo.clearbit.com, che vede il tuo IP.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Utilizzo dello spazio per categoria con le dimensioni">

*Lo spazio, voce per voce. La cache è quasi sempre la fetta maggiore e l'unica che si può buttare senza rischi.*

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Durate della cache per categoria e azione Svuota la cache">

*Gestione della cache, con la durata di ciascuna classe: ricerche 5 min, dettagli stazione 15 min, richieste di prezzo 5 min, dati preferiti 30 min, ricerche di città 30 min, geocodifica CAP 24 h.*

<img src="guide/cache-clear-dialog.jpg" width="340" alt="Finestra di conferma dello svuotamento della cache">

*Svuotare la cache elimina solo risultati e prezzi memorizzati — profili, preferiti e impostazioni restano. Le prossime ricerche saranno più lente; nulla va perduto.*

---

## Backup e ripristino

<img src="guide/backup-restore.jpg" width="340" alt="Voci Esporta backup e Ripristina backup">

*Uno ZIP completo con veicoli, rifornimenti, viaggi e registri di ricarica.*

**Esporta backup** scrive lo ZIP nei tuoi Download. **Ripristina backup** offre *unisci* o *sostituisci* — unire conserva ciò che c'è sul dispositivo e aggiunge il mancante; sostituire cancella prima. Da usare prima di un cambio telefono o di un ripristino di fabbrica. TankSync non è un backup: replica categorie scelte, non tutto.

---

## Avanzate e sviluppatore

<img src="guide/advanced-developer.jpg" width="340" alt="Campo del token PAT GitHub e voce Strumenti di sviluppo">

*Il token GitHub è facoltativo — senza, un riscontro di scansione fallita si condivide a mano invece di aprire automaticamente una segnalazione.*

La voce **Strumenti di sviluppo** compare solo con la modalità sviluppatore attiva (Funzioni e modalità d'uso → Sviluppatore e sperimentale).

<img src="guide/developer-tools-1.jpg" width="340" alt="Strumenti di sviluppo: registro errori, notifica di prova, pipeline di avviso di prova, diagnostica, tester OCR, svuota cache">

*Per un utente normale il registro errori è la parte utile: **Salva il registro errori** scrive tracce depurate nei Download, da allegare a una segnalazione.*

<img src="guide/developer-tools-2.jpg" width="340" alt="Copia diagnostica, esporta traccia di accesso ai dati, traccia di inizializzazione all'avvio">

*La traccia di avvio è una cascata delle fasi di inizializzazione — così un avvio lento si diagnostica invece di indovinarlo.*

<img src="guide/developer-tools-3.jpg" width="340" alt="Prova l'overlay di avvicinamento e info di build con versione e canale">

***Prova l'overlay di avvicinamento** forza uno stato sintetico per 30 s per verificare la visualizzazione del prezzo in sovrimpressione senza andare a guidare.*

---

## Informazioni

<img src="guide/about-1.jpg" width="340" alt="Informazioni: versione e numero di build, autore, licenza, informativa privacy, GitHub, segnala un bug">

***Versione e numero di build** — citali entrambi in ogni segnalazione, e controllali per primi quando una correzione « non ha funzionato » (la distribuzione dello store potrebbe non averti ancora raggiunto).*

<img src="guide/about-2.jpg" width="340" alt="Informazioni: link di sostegno e attribuzioni dei dati">

*L'app è gratuita, open source e senza pubblicità. Le attribuzioni dei dati di prezzo e di mappa sono in fondo, come richiedono le licenze.*

---

**Vedi anche:** [Come funziona Sparkilo](User-it-How-It-Works) · [Privacy, dati e sincronizzazione](User-it-Privacy-Profiles-Sync)
**Avanti:** [Privacy, dati e sincronizzazione →](User-it-Privacy-Profiles-Sync)
