# Storico e previsioni prezzi

L'app costruisce un quadro **privato e locale** di come si muovono i prezzi attorno a te, e ne ricava una raccomandazione onesta.

---

## Cosa viene registrato, e dove

Ogni volta che il prezzo di una stazione passa per l'app — una ricerca, un aggiornamento dei preferiti o un controllo avvisi in background — l'app scrive **sul tuo telefono** un rilevamento: stazione, carburante, prezzo, orario. Nulla viene caricato, e i dati di nessun altro vengono scaricati.

- **Deduplicato a un rilevamento per stazione all'ora.** Cinque ricerche in dieci minuti danno una voce.
- **Conservato 30 giorni.** I rilevamenti più vecchi sono eliminati automaticamente.
- **Abilitato da** *Funzioni e modalità d'uso → Prezzi e avvisi → Storico prezzi*. Spento, non viene scritto alcun rilevamento.

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Prezzi e avvisi: storico, previsione TFLite, segnalazioni della comunità, QR di pagamento">

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

**Vedi anche:** [Preferiti e avvisi](User-it-Favorites-And-Alerts) · [Trovare stazioni → La freschezza](User-it-Finding-Stations#la-freschezza-più-importante-del-prezzo)
**Avanti:** [Riferimento impostazioni →](User-it-Settings-Reference)
