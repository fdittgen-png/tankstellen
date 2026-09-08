# Registro rifornimenti e consumi

Livelli 2 e 3 dei [tre livelli di risparmio](User-it-How-It-Works#i-tre-livelli-di-risparmio): quanto bruci, e quanto è costato davvero. La scheda ⛽ **Carburante** compare nelle modalità **Medio** e **Completo**.

---

## La scheda Carburante a colpo d'occhio

<img src="guide/fuel-tab.jpg" width="340" alt="Scheda Carburante: livello serbatoio con autonomia, scheda statistiche con badge di precisione, elenco rifornimenti">

*Tre blocchi: cosa c'è nel serbatoio, quanto costa la tua guida, e cosa hai davvero messo.*

### Livello del serbatoio e autonomia

L'indicatore è **ancorato all'ultimo pieno**, poi decurtato del carburante consumato dai viaggi registrati. Il timbro sotto la barra indica a quale rifornimento è ancorato.

Vengono mostrate due autonomie di proposito:

- **« ≈ 548 km al consumo del tuo ultimo pieno »** — il comportamento recente, utile oggi.
- **« Media a lungo termine: ≈ 611 km »** — la tua media storica, utile per pianificare.

Se divergono molto, qualcosa è cambiato di recente: un box da tetto, l'inverno, un diverso mix di strade, o un cambio di carburante.

> Quando un adattatore OBD2 è collegato e l'auto pubblica il PID di livello carburante, l'indicatore passa al **sensore del serbatoio** e lo dichiara. Quel valore è una misura, non una deduzione, e sopravvive ai viaggi non registrati.

### La scheda delle statistiche

I tre badge sono lo strato di onestà:

| Badge | Significato |
|---|---|
| **Precisione: Alta · ±3-7 %** | Rifornimenti e viaggi OBD2 alimentano entrambi il modello |
| **Precisione: Media** | I rifornimenti lo ancorano, ma nessun viaggio OBD2 ha ancora alimentato il ciclo |
| **Precisione: Bassa** | Solo GPS, nulla ancorato — aggiungi un paio di pieni |
| **η_v : 0,93 · 6 campioni** | Il rendimento volumetrico appreso del modello speed-density e i suoi campioni |

Sotto: media L/100 km, costo medio al km, litri totali, spesa totale, numero di rifornimenti. Un tocco apre le [statistiche complete](#statistiche-consumi).

---

## Registrare un rifornimento

Tocca **➕ Aggiungi rifornimento** — oppure, molto più rapido: **Aggiungi rifornimento** direttamente sulla pagina di dettaglio di una stazione, che precompila stazione, carburante e prezzo.

<img src="screenshots/consumption-pick-station.png" width="340" alt="Modulo di rifornimento precompilato con marca, carburante e prezzo da una ricerca recente">

*Partendo da una stazione, tre campi sono già giusti — digiti litri, totale e contachilometri.*

| Campo | Perché conta |
|---|---|
| **Data** | Ordina le finestre di serbatoio |
| **Veicolo** | Attribuisce il rifornimento e la calibrazione |
| **Tipo di carburante** | Su una flex-fuel tutto il confronto dipende da questo campo |
| **Litri** | Il numeratore della verità della pompa |
| **Costo totale** | Costo al km, spesa mensile |
| **Contachilometri** | **Il campo più importante del modulo** |
| **Pieno** | Chiude una finestra di calibrazione — vedi sotto |
| Stazione, note | Facoltativi |

### Perché il contachilometri è il campo critico

Il consumo è litri ÷ chilometri. I litri vengono dallo scontrino e sono esatti. I chilometri vengono dalle *tue due letture del contachilometri*. Un errore di 20 km su un serbatoio di 600 km è un 3 % di errore — e poiché quel risultato ricalibra lo stimatore, l'errore si propaga a ogni stima futura. Il modulo rifiuta un contachilometri inferiore a quello del rifornimento precedente, perché la distanza non torna indietro.

### La casella « Pieno »

Spuntala ogni volta che riempi fino all'orlo. È ciò che trasforma due rifornimenti in una **finestra chiusa** con un consumo fisicamente vero.

I rifornimenti parziali vengono comunque registrati, contano per il costo e restano nell'elenco — semplicemente non possono chiudere una finestra. La schermata di statistiche mostra un banner che conta i *« rifornimenti parziali in attesa di un pieno — non nella media »*, così sai sempre cosa c'è nei numeri.

### Scansionare invece di digitare

- **Scansiona il display della pompa** — punta la fotocamera sul display; l'app legge litri, totale e prezzo.
- **Scansiona lo scontrino** — lo stesso dal foglietto stampato.
- **Condividi una foto di scontrino** da un'altra app direttamente nel modulo.

Il riconoscimento gira **sul dispositivo**; l'immagine non viene mai caricata. Dai sempre un'occhiata ai valori prima di salvare — una scansione è un vantaggio, non un oracolo. In caso di errore, *Segnala errore di scansione* apre una segnalazione col ritaglio per migliorare il riconoscimento.

> **Build F-Droid:** il riconoscimento di testo sul dispositivo esiste solo nelle build Play / App Store. La build F-Droid priva di GMS non ha la scansione — lì i rifornimenti si digitano a mano. Tutto il resto è identico.

---

## Il rapporto del pieno — il momento della verità

Ogni volta che un pieno si chiude, l'app pubblica un rapporto. Nella scheda Viaggi appare così:

<img src="guide/trips-tab.jpg" width="340" alt="Rapporto del pieno: 6,4 L/100 km, scarto rispetto al pieno precedente, barra di copertura e verdetto di calibrazione">

*Una scheda, quattro affermazioni diverse — e volutamente non sono lo stesso numero.*

| Riga | Cos'è |
|---|---|
| **6,4 L/100 km** | La **verità della pompa** di questo serbatoio: litri erogati ÷ chilometri contachilometri |
| **1,5 L/100 km in meno del pieno precedente** | Tendenza rispetto all'ultimo serbatoio chiuso |
| **559 km · 35,7 L · 32,12 €** | La finestra grezza |
| **Le registrazioni coprono l'81 % di questo pieno** | Quanta parte di quei chilometri hai davvero registrato |
| **Quota registrata: 10,5 L/100 km** | Cosa hanno dato da soli i chilometri registrati |
| **Le stime registrate sono del 39 % sopra la verità della pompa** | Il verdetto di calibrazione — lo stimatore leggeva alto ed è stato appena corretto |

### Leggerlo correttamente

La quota registrata e la verità della pompa **possono differire**, per due motivi distinti che è facile confondere:

1. **La selezione.** Registri i viaggi che registri. Se il tuo 81 % è per lo più urbano breve e il 19 % mancante è un tratto autostradale, la quota registrata è legittimamente più alta della media del serbatoio. Nulla è rotto.
2. **La calibrazione.** Lo stimatore stesso può essere distorto. È ciò che misura l'ultima riga, confrontando i due **per chilometro**, così la copertura si annulla e determina solo il peso della finestra.

Dopo una correzione come questa, aspettati che le stime di viaggio scendano nettamente al prossimo viaggio e poi si assestino. Il meccanismo completo: [Come funziona Sparkilo → Come un litro diventa un numero](User-it-How-It-Works#come-un-litro-diventa-un-numero).

La scheda può anche indicare *cosa è cambiato* — quota di alto regime, eventi bruschi ogni 100 km, avviamenti a freddo, quota di minimo, ciascuno rispetto al serbatoio precedente — con la riserva esplicita che le registrazioni sono spontanee e coprono solo parte del serbatoio.

---

## Statistiche consumi

Tocca la scheda delle statistiche, o **Carburante → Statistiche consumi**.

<img src="guide/consumption-stats-1.jpg" width="340" alt="Intestazione statistiche: chip di filtro carburante, totali e tabella questo mese vs mese scorso">

*I chip in alto restringono tutto ciò che segue a un carburante — indispensabile su una flex-fuel, dove una media combinata non significa nulla.*

La tabella mensile mostra litri, spesa, prezzo medio al litro, consumo medio, costo al km e numero di rifornimenti, ciascuno col suo scarto. Le frecce rosse non sono un giudizio — una *spesa* in aumento dopo un *prezzo al litro* in aumento è il mercato, non il tuo piede destro. Il numero da guardare per la guida è **L/100 km**.

### Costo al chilometro per carburante

<img src="guide/consumption-stats-2.jpg" width="340" alt="Costo al chilometro per carburante: righe E85 ed E5 con costo/km, L/100 km, prezzo pagato e CO2">

*La vera domanda di chi guida flex-fuel, risolta: non quale carburante costa meno al litro, ma quale costa meno al chilometro.*

Ogni carburante ha una riga costruita solo su **finestre di serbatoio chiuse**: L/100 km misurati, prezzo effettivamente pagato al litro, costo ogni 100 km, spesa totale, distanza misurata, litri consumati, CO₂ ogni 100 km, e quanti pieni ci sono dietro. Una riga basata su un solo serbatoio è marcata **Provvisoria**.

<img src="guide/consumption-stats-3.jpg" width="340" alt="Scheda di verdetto sul costo d'uso con il vincitore, il punto di pareggio e la nota CO2">

*La scheda di verdetto annuncia il vincitore, il divario ogni 1000 km e — la cosa più utile — il **prezzo di pareggio**.*

La riga di pareggio (« E5 diventa più conveniente di E85 sotto 0,75 €/L ») è calcolata dal **tuo consumo misurato di ciascun carburante**: si sposta quindi con la tua guida. È una regola decisionale utilizzabile alla pompa; un rapporto generico trovato in rete no.

I valori di CO₂ sono stime dal pozzo alla ruota (EU JEC WTW v5) applicate al tuo consumo misurato — consapevolezza, non contabilità certificata. Le miscele sono escluse dal CO₂ perché il fattore di emissione dipende dalla miscela, che la riga non registra.

<img src="guide/consumption-stats-4.jpg" width="340" alt="Evoluzione nel tempo: litri al mese e spesa al mese, impilati per carburante">

*I grafici di tendenza impilano per carburante: un cambio appare come un colore che ne sostituisce un altro, non come un salto misterioso.*

<img src="guide/consumption-stats-5.jpg" width="340" alt="Prezzo al litro e L/100 km al mese">

*Prezzo al litro e L/100 km sono di proposito due grafici distinti — uno è il mercato, l'altro sei tu.*

**Esporta** scrive tutto in CSV nella tua cartella Download pubblica.

---

## Eco-punteggio per rifornimento

Ogni rifornimento riceve un badge confrontato con la media mobile dei tuoi ultimi tre rifornimenti dello stesso carburante:

| Scarto | Badge | Come leggerlo |
|---|---|---|
| ≥ 3 % meglio | 🟢 In miglioramento | Nettamente meno del tuo riferimento |
| entro ±3 % | ⚪ Stabile | Variazione normale |
| ≥ 3 % peggio | 🟠 In peggioramento | Controlla pressione gomme, box da tetto, freddo, mix di strade |

Il badge resta nascosto finché non hai quattro rifornimenti di quel carburante, perché il riferimento sia reale.

---

## Quando i conti non tornano

Prima o poi metterai più litri di quanti i viaggi registrati possano spiegare — ha guidato qualcun altro, l'adattatore era staccato, l'app chiusa. Invece di assorbire la differenza in silenzio, l'app mostra un **banner di scarto** e propone una breve riconciliazione:

> *Abbiamo trovato uno scarto di 4,2 L. Hai erogato 35,7 L, ma i tuoi viaggi registrati ne spiegano solo 31,5 L.*

Fa due domande:

1. **Tutti i rifornimenti di questo serbatoio sono completi e corretti?** — No significa che ne manca uno o è mal digitato, e l'app aggiunge un **rifornimento di correzione** perché i litri tornino.
2. **Tutti i tuoi viaggi sono registrati?** — No significa che un viaggio manca, e l'app aggiunge un **viaggio virtuale** per la distanza mancante.

Entrambi gli artefatti sono poi modificabili ed eliminabili, ed entrambi sono marcati come generati automaticamente perché non li si confonda mai con dati reali. Puoi anche scegliere **Decidi più tardi** — il banner resta finché non risolvi.

**Perché conta:** uno scarto irrisolto distorce silenziosamente la finestra di calibrazione. Risolverlo (o eliminare la voce sbagliata) mantiene affidabile l'ancoraggio alla pompa.

---

## Carte fedeltà

**Impostazioni → Guida e consumo → Carte fedeltà** memorizza gli sconti al litro delle catene che usi. Lo sconto viene poi applicato nei confronti di prezzo, così una stazione apparentemente più cara di 2 cent/L può correttamente risultare la più economica per te. La funzione si attiva in Funzioni e modalità d'uso → Inserimento e scansione.

---

<details>
<summary>Vista d'insieme — statistiche consumi, pagina intera</summary>

<img src="guide/full/consumption-stats.jpg" width="420" alt="Statistiche consumi complete assemblate da cinque catture">

</details>

---

**Vedi anche:** [Veicoli e OBD2](User-it-Vehicles-And-OBD2) · [Viaggi ed eco-coaching](User-it-Trips-And-Coaching)
**Avanti:** [Viaggi ed eco-coaching →](User-it-Trips-And-Coaching)
