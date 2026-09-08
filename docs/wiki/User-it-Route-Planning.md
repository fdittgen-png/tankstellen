# Pianificazione itinerario

Non « il più economico vicino a me » ma **il più economico sulla strada** — la differenza vale diversi euro su ogni viaggio lungo.

---

## Avviare una ricerca su itinerario

<img src="guide/search-criteria-route-1.jpg" width="340" alt="Criteri in modalità itinerario: partenza, tappa, destinazione, carburante, segmento, deviazione, risparmio minimo">

*Tocca **Cerca** → passa a **Cerca lungo l'itinerario**. Il pulsante resta disattivato finché non ci sono destinazione e carburante.*

| Campo | Significato |
|---|---|
| **Partenza** | La tua posizione attuale, o una città / un CAP digitati |
| **Aggiungi una tappa** | Punti intermedi — il corridoio li segue |
| **Destinazione** | Città, CAP o coordinate |
| **Carburante** | La qualità quotata lungo il corridoio |
| **Segmento di percorso** | Mostra la stazione più economica ogni *n* km (50–1000 km) |
| **Deviazione massima** | Quanto lontano dalla linea diretta può stare una stazione |
| **Risparmio minimo** | Nasconde le soste che non battono la media del corridoio di almeno questo importo; *Disattivato* mostra tutto |

<img src="guide/search-criteria-route-2.jpg" width="340" alt="Parte bassa dei criteri di itinerario: solo aperte, servizi, marche, salva predefiniti">

*Gli stessi filtri di apertura, servizi e marche di una ricerca nelle vicinanze valgono per il corridoio.*

### Come funziona davvero

1. L'app chiama il servizio pubblico di instradamento **OSRM** e ottiene la polilinea stradale del percorso.
2. Colloca punti candidati lungo quella linea, distanziati secondo il **segmento di percorso**.
3. Attorno a ciascun punto interroga il fornitore di prezzi **del paese in cui si trova quel punto**, con la qualità presa dal profilo di quel paese.
4. Ordina le candidate di ogni segmento secondo la strategia scelta e il limite di **deviazione massima**.

### Cosa cambia in pratica

- **La lunghezza del segmento è il vero comando.** 50 km su 600 km dà dodici liste; 200 km ne dà tre. Scegli in base a quanto spesso ti fermi davvero.
- **La deviazione massima si misura dall'itinerario diretto**, non da te. 5 km significa « fino a 5 km di strada in più ».
- **I percorsi lunghi richiedono più tempo.** Un corridoio di 600 km campiona molti punti, forse su più fornitori.
- Se la partenza è « GPS automatico » e il segnale cade, la ricerca ripiega sull'ultima posizione nota.

---

## Corridoi transfrontalieri

Quando un percorso attraversa un confine, **ogni paese del corridoio è interrogato tramite il proprio fornitore**, e l'intestazione li cita tutti:

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Poiché le qualità differiscono per paese, un risultato transfrontaliero mostra legittimamente E85 sul tratto francese e Gasolina 95/E5 su quello spagnolo. Ciascuno è quotato correttamente per il suo lato, mai mediato.

**Serve un profilo per paese** con la qualità preferita giusta, altrimenti il secondo tratto non ha nulla da quotare e mostra `--`. Vedi [Come funziona Sparkilo → Profili](User-it-How-It-Works#profili-un-contesto-un-insieme-di-valori-predefiniti).

---

## I risultati arrivano progressivamente

Un'API nazionale lenta non deve bloccare il resto del corridoio: i risultati arrivano **man mano**, con le stazioni di ciascun paese che compaiono appena quel fornitore risponde e un banner che nomina le fonti ancora attese. Puoi toccare un risultato conveniente appena arriva.

---

## Le quattro strategie

### 🏆 Soste migliori *(predefinita)*
Porta in cima le 3–5 stazioni più economiche realisticamente raggiungibili come chip ordinati. Le deviazioni restano brevi. È ciò che vuole la maggior parte dei guidatori.

### 🎯 La più economica
L'unica stazione col prezzo più basso dell'intero percorso. Ideale quando fai un solo pieno e vuoi il massimo risparmio al litro.

### ⚖️ Bilanciata
Valuta ogni candidata su prezzo *e* vicinanza alla linea. Una stazione a 5 km ma 10 cent/L più economica vince; una a 50 km deve essere molto più economica.

### 📏 Uniforme
Divide il percorso in segmenti uguali e propone una sosta per segmento. Ideale per lunghi viaggi transfrontalieri con più rifornimenti.

Strategia predefinita, lunghezza di segmento, deviazione massima, risparmio minimo e numero di candidate per punto di campionamento sono memorizzati **per profilo**:

<img src="guide/profile-edit-2.jpg" width="340" alt="Parametri di pianificazione itinerario nell'editor di profilo">

*Impostazioni → Profili e regione → modifica → Pianificazione itinerario. Da impostare una volta qui invece di ritoccare il foglio a ogni viaggio.*

---

## Leggere i risultati

Ogni riga aggiunge due numeri che una ricerca nelle vicinanze non ha:

- **Distanza dalla partenza** — dove si trova la stazione sul percorso, per farla coincidere col momento in cui il serbatoio sarà basso.
- **Deviazione** — i chilometri in più rispetto alla linea diretta.
- **Risparmio rispetto alla media** — sulla media del corridoio, non su una nazionale.

Passa a **Tutte le stazioni** per vedere ogni stazione lungo il percorso invece della selezione. La mappa traccia la polilinea con tutti i segnaposto.

---

## Evitare le autostrade

**Impostazioni → Profili e regione → Visualizzazione e stazioni → Evita le autostrade** fa preferire le strade secondarie. Questo cambia la *polilinea*, quindi quali stazioni sono candidate: le aree di servizio autostradali scompaiono dal corridoio invece di essere solo declassate. Utile proprio perché il carburante autostradale è di norma il più caro di qualsiasi itinerario.

---

## Itinerari salvati

Tocca **Salva itinerario** nella schermata dei risultati. Gli itinerari salvati appaiono in cima al modulo; un tocco riesegue lo stesso corridoio con **prezzi freschi**. Viene salvata la geometria, non i prezzi.

---

**Vedi anche:** [Trovare stazioni](User-it-Finding-Stations) · [Riferimento impostazioni](User-it-Settings-Reference#profili-e-regione)
**Avanti:** [Preferiti e avvisi →](User-it-Favorites-And-Alerts)
