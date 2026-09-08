# Trajets et éco-coaching

L'onglet 🛣️ **Trajets** est un carnet de bord automatique doublé d'un coach de conduite. Il apparaît en mode **Complet**.

---

## L'onglet Trajets

<img src="guide/trips-tab.jpg" width="340" alt="Onglet Trajets : comparaison mensuelle, rapport de plein et liste des trajets avec le bouton d'enregistrement">

*Totaux du mois, le dernier rapport de plein, puis la liste des trajets. Le bouton flottant démarre un enregistrement.*

La comparaison mensuelle exige au moins trois trajets par mois avant de comparer — en dessous, la moyenne est du bruit, pas une tendance.

<img src="guide/trips-map.jpg" width="340" alt="Tous les trajets enregistrés sur une carte, colorés par trajet">

*L'icône carte de la barre supérieure dessine tous vos trajets enregistrés sur une carte — une année de conduite d'un coup d'œil, et un moyen simple de repérer les routes qui méritent d'être optimisées.*

---

## Deux façons d'enregistrer

### Avec le téléphone seul

Aucun matériel. L'application relève route, distance, durée et vitesse par GPS, et **modélise** la consommation depuis le calibrage de votre véhicule et votre conduite. Signalée partout par un `~` et une mention explicite « estimation GPS ».

La précision démarre mauvaise et s'améliore : chaque fenêtre de plein fermée ré-ancre le modèle sur la pompe, si bien qu'après une poignée de pleins complets un trajet GPS tombe généralement à quelques pour cent près. D'ici là, c'est étiqueté préliminaire, pas maquillé.

### Avec un adaptateur OBD2

Des données moteur au lieu d'une déduction : débit réel (mesuré là où la voiture publie le PID 5E), régime, charge, accélérateur. Aucune période d'apprentissage pour la consommation, et le coaching accède à des signaux que le GPS ne voit pas — rapport, régime, charge moteur. La mise en place est dans [Véhicules et OBD2](User-fr-Vehicles-And-OBD2#ladaptateur-obd2).

> **Enregistrer n'exige jamais d'adaptateur.** Désactivez *Exiger OBD2 pour l'enregistrement des trajets* (Fonctions et mode d'utilisation → Conso) pour enregistrer au GPS seul ; le coaching est réduit, pas absent.

---

## Pendant que vous roulez

### Le chiffre en direct

Le chiffre principal est votre moyenne **sur les dernières secondes** — carburant brûlé ÷ distance parcourue, la même grandeur qu'un ordinateur de bord — libellée *« Dernières 5 s »*. À l'arrêt il passe en L/h, car les L/100 km n'ont pas de sens à vitesse nulle.

Changez la fenêtre sous **Réglages → Conduite et consommation → Fenêtre de consommation en direct** (3 / 5 / 10 / 30 s). Une **fenêtre longue est plus stable et plus lisible en conduisant** ; une courte réagit assez vite pour vous apprendre ce que coûte votre pied droit. L'unité suit **Unités et affichage → Unité de consommation** partout : bandeau, vignette en incrustation, Live Activity iOS et moyenne du trajet.

### Le paysage, c'est la vue « en voiture »

Tournez le téléphone à l'horizontale pendant un enregistrement et l'écran devient une disposition sans contact, lisible d'un coup d'œil : à gauche le grand chiffre de consommation instantanée avec l'indice de coaching en dessous (*lever le pied* / *anticiper* / *accélérer en douceur* en GPS, *monter un rapport* / *rétrograder* / *relâcher* en OBD2) et une grande vitesse ; à droite la fiche radar de la station la plus proche au-dessus d'une grille 2×2 — **Distance · Moy · Durée · Carburant utilisé**.

Rien ne défile et rien n'est petit. Le téléphone sur son support, vous n'y touchez plus.

### Incrustation (picture-in-picture)

Réduisez l'application en vignette flottante et gardez votre navigation au premier plan. La vignette s'adapte au contexte :

| Situation | Grand chiffre | Ligne secondaire |
|---|---|---|
| OBD2 connecté | L/100 km en direct (L/h à l'arrêt) | distance · durée |
| GPS seul, en route | distance parcourue | durée |
| Mise en route | temps écoulé | — |

### L'overlay d'approche

En entrant dans le rayon configuré autour d'une station, la vignette bascule sur un grand affichage du **prix du carburant** — prix pour votre sorte, marque, distance, lisibles d'un coup d'œil.

La station retenue se règle dans **Réglages → Conduite et consommation → Overlay à l'approche d'une station** : **la plus proche** (la première dont vous avez franchi le rayon) ou **la moins chère du rayon**. En sortant, l'affichage du prix reste cinq secondes en délai de grâce, pour qu'un passage à proximité ne fasse pas clignoter la vignette.

**Tester sans rouler :** Réglages → Outils de développement → **Tester l'overlay d'approche** pousse un état synthétique pendant 30 secondes.

---

## Lire un trajet

<img src="guide/trip-detail-1.jpg" width="340" alt="Résumé du trajet : date, véhicule, adaptateur, distance, durée, consommation, carburant, coût et vitesses">

*Le résumé annonce sa propre provenance — véhicule, adaptateur, et un badge **Trace GPS** sur la distance pour savoir d'où viennent les kilomètres.*

<img src="guide/trip-detail-2.jpg" width="340" alt="Carte de la route colorée par efficacité avec sa légende et la carte des principaux comportements gaspilleurs">

*La route est colorée par efficacité — vert sous 6 L/100 km, orange jusqu'à 10, rouge au-delà. Où est passé le carburant, géographiquement.*

Cette coloration est la vue la plus actionnable de l'application : elle place sur une carte les portions coûteuses de votre trajet quotidien. Une portion rouge qui revient tous les jours, c'est un carrefour, une côte ou une habitude qu'il vaut la peine de changer.

<img src="guide/trip-detail-3.jpg" width="340" alt="Sélecteur « comment s'est passé ce trajet », où est passé votre carburant, distributions d'accélérateur et de régime">

*Trois blocs : votre propre verdict, l'attribution du carburant, et comment vous avez réellement sollicité le moteur.*

- **« Comment s'est passé ce trajet ? »** — *Souple / Modéré / Agressif*. Votre réponse sert à calibrer les seuils de style de conduite sur de vrais trajets, pas à vous noter.
- **Où est passé votre carburant** — litres attribués aux accélérations fortes contre la conduite normale. Chiffres absolus petits sur un trajet court ; c'est le rapport qui compte.
- **Position d'accélérateur** et **régime moteur** en distributions — la part du trajet passée en roue libre, en charge légère, ferme et pleins gaz, et dans chaque plage de régime. Une part élevée au-dessus de 3000 tr/min sur un trajet domicile-travail signifie que vous montez les rapports trop tard, et ça coûte cher.

<img src="guide/trip-detail-4.jpg" width="340" alt="Diagnostic d'échantillonnage GPS et carte repliée de santé de la communication OBD2">

*Deux diagnostics : la complétude de la trace GPS et le comportement de l'adaptateur.*

<img src="guide/trip-obd2-health.jpg" width="340" alt="Santé de la communication OBD2 dépliée : mesures, couverture, adaptateur, protocole, durée, fin de session">

*Dépliée, la carte OBD2 s'explique en clair.*

**Lisez cette carte avant de douter d'un chiffre de consommation.** Elle indique combien de mesures portaient des données moteur, la **couverture en pourcentage** qui en résulte, l'adaptateur et le protocole négocié, la durée de la session, pourquoi elle s'est terminée (`userStopped`, une déconnexion, une mort du processus), et la ligne décisive : *« Les valeurs de consommation viennent de l'adaptateur, pas d'estimations GPS. »* Si la couverture est nettement sous 100 %, les trous ont été comblés par des estimations GPS et la moyenne du trajet est un mélange.

<img src="guide/trip-detail-5.jpg" width="340" alt="Graphiques : vitesse, débit de carburant et régime moteur sur le trajet">

*Vitesse, débit et régime sur un axe de temps commun — les trois courbes qui expliquent n'importe quel chiffre de consommation.*

<img src="guide/trip-detail-6.jpg" width="340" alt="Graphiques : régime, charge moteur, position d'accélérateur et température de liquide">

*Charge moteur et accélérateur côte à côte montrent la différence entre faire travailler le moteur et simplement le faire monter en régime.*

<img src="guide/trip-detail-7.jpg" width="340" alt="Graphiques : liquide de refroidissement, altitude depuis le départ, température d'air d'admission et avance à l'allumage">

*L'altitude compte plus qu'on ne croit : une montée explique un pic de consommation qui, autrement, ressemblerait à de la mauvaise conduite.*

Les actions **partager** et **supprimer** sont dans la barre supérieure. Le partage exporte le trajet avec sa trace GPX.

---

## Score de conduite et coaching

Avec un adaptateur, chaque trajet est noté sur 100 — un composite du ralenti, des accélérations fortes, des freinages appuyés, du temps à haut régime, des pleins gaz, du sous-régime, des à-coups, de la vitesse élevée soutenue, de l'agressivité à la pédale et de la richesse du mélange. Le détail nomme le comportement le plus coûteux : la note est donc un diagnostic, pas une sanction.

La carte **principaux comportements gaspilleurs** en tire des phrases exploitables — et affiche *« Aucune inefficacité notable — continuez ainsi ! »* quand il n'y a rien à corriger, au lieu d'inventer un reproche.

Le coaching peut aussi se faire en roulant :

- **Coaching éco en temps réel** — vibration légère et conseil à l'écran quand vous accélérez fort en vitesse de croisière.
- **Coaching vocal de conduite** — le même conseil lu à voix haute, pour garder les yeux sur la route.
- **Glide-coach (bêta)** — vibration discrète quand il faudrait lever le pied avant un feu rouge, à partir des feux de circulation d'OpenStreetMap. **Désactivé par défaut : risque de distraction**, et il lui faut du réseau pour charger les feux de votre secteur.

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Interrupteurs de coaching, récompenses, cartes de fidélité, succès et journalisation OBD2">

*Réglages → Conduite et consommation. Les succès et les scores peuvent être masqués dans toute l'application si la gamification n'est pas pour vous.*

---

## Le tableau de bord carbone

<img src="screenshots/carbon-dashboard.png" width="340" alt="Tableau de bord carbone : coût et CO2 par longueur de trajet et par plage de vitesse">

*Coût et CO₂ issus des mêmes litres mesurés, décomposés de deux façons.*

- **Par longueur de trajet** — les courts trajets sont d'ordinaire les plus chers au kilomètre, parce qu'un moteur froid boit. Le voir chiffré est ce qui pousse les gens à grouper leurs courses.
- **Par plage de vitesse** — la part de carburant consommée à ramper en ville contre celle passée à rouler sur autoroute.

Il est bâti entièrement sur des données de votre téléphone, et s'active sous Fonctions et mode d'utilisation → Conso.

---

## Exports et diagnostics

- **Partager** un trajet (résumé + GPX).
- **Exporter la trace d'analyse de conduite** — les KPI GPS, le score et les leçons du trajet en JSON, avec un champ libre pour décrire comment la conduite s'est vraiment passée. Le repartager aide à calibrer les seuils de style sur de vrais trajets. Fonction du mode développeur.
- **Exporter mes données → Archive ZIP** sous Confidentialité et données → Exporter ou supprimer inclut chaque trajet et un GPX par trajet.

---

<details>
<summary>Vue d'ensemble — détail d'un trajet, page entière</summary>

<img src="guide/full/trip-detail.jpg" width="420" alt="Page complète du détail de trajet assemblée à partir de huit captures">

</details>

---

**Voir aussi :** [Véhicules et OBD2](User-fr-Vehicles-And-OBD2) · [Carnet de pleins et consommation](User-fr-Fuel-And-Consumption)
**Suite :** [Historique et prévisions de prix →](User-fr-Price-History-And-Predictions)
