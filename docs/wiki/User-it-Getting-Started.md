# Primi passi

Dieci minuti dall'installazione al primo euro risparmiato. Se dopo leggi una sola altra pagina, che sia [Come funziona Sparkilo](User-it-How-It-Works).

---

## 1. Installare

### Google Play (Android)

Installa dal **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — la versione pubblica di produzione.

> **Vieni dalla beta?** Play continua a servire build beta una volta iscritto al test aperto (la scheda mostra un'etichetta *(beta)*). Per passare alla produzione: apri la [scheda Play](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Abbandona il programma** → disinstalla → reinstalla.
>
> **Vuoi le novità prima?** Resta nella beta — ogni build arriva al canale beta prima della produzione.

### F-Droid (Android, senza Google)

Una build completamente **priva di GMS** viene distribuita da un repository F-Droid dedicato (mappe OpenStreetMap, nessun servizio Google). In F-Droid: **Impostazioni → Repository → +** e aggiungi:

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Poi cerca **Sparkilo**. Se la build Play è installata, disinstallala prima — chiave di firma diversa, quindi nessun aggiornamento sopra.

### Altri modi

- **APK** — dalle [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — beta TestFlight; chiedi un invito tramite [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) finché la scheda App Store non è pubblicata.

**Android minimo** 7.0 (API 24), target Android 15. **iOS minimo** 15.5, target iOS 18.

Nessun account, nessuna registrazione, nessuna e-mail. L'app è pienamente utilizzabile appena l'installazione finisce.

---

## 2. Primo avvio — il consenso

Prima di ogni altra schermata l'app mostra una **schermata di consenso GDPR**. Non è un banner sui cookie: elenca ogni finalità di trattamento, e l'app prosegue solo se accetti.

<img src="screenshots/privacy-consent.png" width="340" alt="Schermata di consenso al primo avvio con ogni finalità di trattamento">

*Ogni consenso mostrato qui torna più tardi in Impostazioni → Privacy e dati, con la data e la versione dell'informativa che hai visto.*

| Voce | Perché | Se rifiuti |
|---|---|---|
| **Posizione** *(durante l'uso)* | Ricerca nelle vicinanze, partenza itinerario, registrazione viaggi | Cerca per CAP o scegli un punto sulla mappa |
| **Notifiche** | Solo per gli avvisi di prezzo | Gli avvisi non scattano mai |
| **Diagnostica** | Tracce di crash verso Sentry — **disattivata di default** | Non viene inviato nulla; puoi comunque salvare tu il registro errori |

Prima di ogni richiesta *di sistema* (fotocamera, Bluetooth, notifiche) l'app mostra prima una propria spiegazione, così sai a cosa acconsenti prima che Android lo chieda.

Testo integrale: **[Informativa sulla privacy v3, 29 agosto 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/)**.

---

## 3. Paese, lingua e la tua zona

Entrambi sono rilevati dalla lingua di sistema, ed entrambi vivono **nel profilo** — vedi [Come funziona Sparkilo → Profili](User-it-How-It-Works#profili-un-contesto-un-insieme-di-valori-predefiniti).

<img src="guide/profile-edit-6.jpg" width="340" alt="Selettore di lingua e CAP di casa nell'editor di profilo">

*Impostazioni → Profili e regione → modifica profilo. Il CAP di casa consente ricerche in un'area fissa senza mai cedere il GPS.*

Cambiare paese **svuota i dati di stazione in cache**, perché i prezzi del fornitore precedente non valgono per il nuovo paese. La ricerca successiva impiegherà un attimo in più.

---

## 4. Scegliere una modalità d'uso

È l'impostazione più determinante, perché decide quanta app ottieni.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Preimpostazioni Base, Medio, Completo, Personalizzato">

*Impostazioni → Funzioni e modalità d'uso. Parti da **Base** se vuoi solo carburante più economico; sali quando vorrai sapere perché la tua auto beve.*

- **Base** — trovare carburante e ricarica, preferiti, avvisi, itinerari.
- **Medio** — aggiunge la scheda **Carburante**: registrare i rifornimenti, vedere consumo e costo reali. Nessun hardware.
- **Completo** — aggiunge la scheda **Viaggi**: registrazione automatica, punteggi di guida, carte fedeltà. Un adattatore OBD2 resta facoltativo anche qui — i viaggi si registrano col solo GPS.

Puoi cambiare in ogni momento, e ogni interruttore toccato poi ti porta in **Personalizzato**. L'elenco completo, e quanto ciascuno costa in batteria, dati o privacy: [Riferimento impostazioni → Funzioni e modalità d'uso](User-it-Settings-Reference#funzioni-e-modalità-duso).

---

## 5. Solo Germania: la chiave API gratuita

16 dei 17 paesi funzionano subito. Il servizio ufficiale **tedesco** rilascia una chiave per utente.

<img src="guide/data-sources-location.jpg" width="340" alt="Schermata fonti dati con i campi chiave Tankerkönig e OpenChargeMap">

*Impostazioni → Fonti dati e posizione. Una croce rossa qui è il motivo per cui una ricerca tedesca non restituisce nulla.*

1. Apri [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) e richiedi una chiave (modulo breve, gratuito).
2. Copiala — è un UUID come `00000000-0000-0000-0000-000000000002`.
3. Incollala nel campo **Prezzi carburante (Tankerkoenig)**.

La chiave sta nella cassaforte hardware (Android Keystore / Portachiavi iOS) ed è inviata solo al servizio tedesco. Il campo **Ricarica EV** sotto contiene già una chiave condivisa: i dati di ricarica funzionano senza configurazione.

---

## 6. La barra inferiore

<img src="guide/favorites.jpg" width="340" alt="Scheda Preferiti con la barra inferiore e il pulsante Cerca centrale">

*Il pulsante verde **Cerca** rialzato al centro è l'unico attivatore di ricerca dell'intera app.*

- ⭐ **Preferiti** — stazioni salvate e avvisi di prezzo
- 🗺️ **Mappa** — ogni stazione vicina come segnaposto colorato per prezzo
- 🔍 **Cerca** *(al centro)* — nelle vicinanze o lungo un itinerario
- ⛽ **Carburante** — serbatoio, consumi, rifornimenti *(da Medio in su)*
- 🛣️ **Viaggi** — registro e coaching *(Completo)*

Le impostazioni **non** sono una scheda: è l'ingranaggio in alto a destra delle schermate principali. Su tablet, o telefono in orizzontale, l'app si divide in due colonne per vedere elenco e mappa (o dettaglio) insieme.

---

## 7. La tua prima ricerca

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Foglio dei criteri per una ricerca nelle vicinanze">

*Tocca **Cerca** → il foglio dei criteri si apre precompilato dal profilo. Regola, poi tocca di nuovo **Cerca**.*

Ottieni un elenco dal più economico (o per distanza — a te la scelta), ogni scheda con prezzo, tendenza, distanza e freschezza. Un tocco apre il dettaglio. Il giro completo: [Trovare stazioni](User-it-Finding-Stations).

**Suggerimento:** tocca **Salva come valori predefiniti** in fondo al foglio una volta impostati i criteri abituali — ogni ricerca futura partirà da lì.

---

## 8. Due impostazioni da cambiare il primo giorno

<img src="guide/units-and-display-1.jpg" width="340" alt="Unità e visualizzazione con tema, unità di distanza e unità di consumo">

*Impostazioni → Unità e visualizzazione. L'**unità di consumo** è *Automatica* per impostazione predefinita (mpg nel Regno Unito, L/100 km altrove); scegli esplicitamente L/100 km, km/L o mpg se preferisci.*

La seconda è **Impostazioni → Guida e consumo → Finestra del consumo in tempo reale** (3 / 5 / 10 / 30 s). Governa il grande numero in tempo reale della schermata di registrazione: una finestra lunga è più stabile da leggere alla guida, una corta reagisce più in fretta al piede destro.

---

## 9. Scegli su cosa si apre l'app

**Impostazioni → Profili e regione → Schermata iniziale**: *Nelle vicinanze* (ricerca immediata con i tuoi ultimi criteri), *Stazione più vicina*, *Preferiti* o *Mappa*. Prendi quella che corrisponde al motivo per cui apri l'app.

---

## 10. Dove sta tutto

Le impostazioni sono un albero a due livelli con una ricerca per parola chiave in alto — digita « raggio », « OBD2 » o « tema » e la tessera giusta emerge.

<img src="guide/settings-root-1.jpg" width="340" alt="Radice delle impostazioni: tessere tematiche con campo di ricerca">

*Dodici temi, una casa per parametro. La mappa completa è il [Riferimento impostazioni](User-it-Settings-Reference).*

---

**Avanti:** [Come funziona Sparkilo →](User-it-How-It-Works)
