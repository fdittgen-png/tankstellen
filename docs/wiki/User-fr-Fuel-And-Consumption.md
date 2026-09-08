# Carnet de pleins et consommation

Niveaux 2 et 3 des [trois niveaux d'économie](User-fr-How-It-Works#les-trois-niveaux-déconomie) : combien vous brûlez, et ce que cela a vraiment coûté. L'onglet ⛽ **Carburant** apparaît en modes **Moyen** et **Complet**.

---

## L'onglet Carburant d'un coup d'œil

<img src="guide/fuel-tab.jpg" width="340" alt="Onglet Carburant : niveau du réservoir avec autonomie, carte de statistiques avec badge de précision, et liste des pleins">

*Trois blocs : ce qu'il y a dans le réservoir, ce que votre conduite coûte, et ce que vous avez réellement mis.*

### Niveau du réservoir et autonomie

La jauge est **ancrée à votre dernier plein complet**, puis débitée du carburant consommé par vos trajets enregistrés. L'horodatage sous la barre indique à quel plein elle est ancrée.

Deux autonomies sont affichées volontairement :

- **« ≈ 548 km à la consommation de votre dernier plein »** — le comportement récent, utile aujourd'hui.
- **« Moyenne à long terme : ≈ 611 km »** — votre moyenne historique, utile pour planifier.

Si elles s'écartent beaucoup, quelque chose a changé récemment : un coffre de toit, l'hiver, un autre mélange de routes, ou un changement de carburant.

> Quand un adaptateur OBD2 est connecté et que votre voiture publie le PID de niveau de carburant, la jauge bascule sur le **capteur du réservoir** et le dit. Cette valeur est une mesure, pas une déduction, et elle survit aux trajets non enregistrés.

### La carte de statistiques

Les trois badges sont la couche d'honnêteté :

| Badge | Signification |
|---|---|
| **Précision : Élevée · ±3-7 %** | Pleins et trajets OBD2 alimentent tous deux le modèle |
| **Précision : Moyenne** | Les pleins l'ancrent, mais aucun trajet OBD2 n'a encore alimenté la boucle |
| **Précision : Faible** | GPS seul, rien d'ancré — ajoutez quelques pleins complets |
| **η_v : 0,93 · 6 échantillons** | Le rendement volumétrique appris du modèle speed-density et son nombre d'échantillons |

En dessous : moyenne L/100 km, coût moyen au km, litres au total, total dépensé, nombre de pleins. Un appui ouvre les [statistiques complètes](#statistiques-de-consommation).

---

## Enregistrer un plein

Touchez **➕ Ajouter un plein** — ou bien plus rapide : **Ajouter un plein** directement sur la page détail d'une station, ce qui pré-remplit station, carburant et prix.

<img src="screenshots/consumption-pick-station.png" width="340" alt="Formulaire de plein pré-rempli avec marque, carburant et prix d'une recherche récente">

*Depuis une station, trois champs sont déjà justes — vous tapez litres, total et compteur.*

| Champ | Pourquoi il compte |
|---|---|
| **Date** | Ordonne les fenêtres de réservoir |
| **Véhicule** | Attribue le plein et le calibrage |
| **Type de carburant** | Sur une flex-fuel, toute la comparaison tient à ce champ |
| **Litres** | Le numérateur de la vérité de la pompe |
| **Coût total** | Coût au km, dépenses mensuelles |
| **Compteur** | **Le champ le plus important du formulaire** |
| **Plein complet** | Ferme une fenêtre de calibrage — voir ci-dessous |
| Station, notes | Facultatifs |

### Pourquoi le compteur est le champ critique

La consommation, c'est litres ÷ kilomètres. Les litres viennent du ticket et sont exacts. Les kilomètres viennent de *vos deux relevés de compteur*. Une faute de 20 km sur un réservoir de 600 km fait 3 % d'erreur — et comme ce résultat recalibre l'estimateur, l'erreur se propage à toutes les estimations futures. Le formulaire refuse un compteur inférieur à celui du plein précédent, car la distance ne recule pas.

### La case « Plein complet »

Cochez-la chaque fois que vous faites le plein à ras bord. C'est ce qui transforme deux pleins en **fenêtre fermée** portant une consommation physiquement vraie.

Les pleins partiels sont quand même enregistrés, comptent pour le coût et figurent dans la liste — ils ne peuvent simplement pas fermer une fenêtre. L'écran de statistiques affiche un bandeau comptant les *« pleins partiels en attente d'un plein complet — hors moyenne »*, pour que vous sachiez toujours ce qui est dans les chiffres.

### Scanner au lieu de taper

- **Scanner l'écran de la pompe** — la caméra sur l'afficheur ; l'application lit litres, total et prix.
- **Scanner le ticket** — pareil depuis le reçu imprimé.
- **Partager une photo de ticket** depuis une autre application directement dans le formulaire.

La reconnaissance tourne **sur l'appareil** ; l'image n'est jamais envoyée. Jetez toujours un œil aux valeurs avant d'enregistrer — un scan est une longueur d'avance, pas un oracle. En cas d'erreur, *Signaler une erreur de scan* ouvre un ticket avec le recadrage pour améliorer la reconnaissance.

> **Version F-Droid :** la reconnaissance de texte sur appareil n'existe que dans les versions Play / App Store. La version F-Droid sans GMS n'a pas de scan — on y saisit les pleins à la main. Tout le reste est identique.

---

## Le rapport de plein — le moment de vérité

À chaque fermeture d'un plein complet, l'application publie un rapport. Dans l'onglet Trajets, il ressemble à ceci :

<img src="guide/trips-tab.jpg" width="340" alt="Rapport de plein : 6,4 L/100 km, écart avec le plein précédent, barre de couverture et verdict de calibrage">

*Une carte, quatre affirmations différentes — et ce ne sont volontairement pas le même chiffre.*

| Ligne | Ce que c'est |
|---|---|
| **6,4 L/100 km** | La **vérité de la pompe** de ce réservoir : litres versés ÷ kilomètres au compteur |
| **1,5 L/100 km de moins que le plein précédent** | Tendance par rapport au dernier réservoir fermé |
| **559 km · 35,7 L · 32,12 €** | La fenêtre brute |
| **Les enregistrements couvrent 81 % de ce plein** | Quelle part de ces kilomètres vous avez réellement enregistrée |
| **Part enregistrée : 10,5 L/100 km** | Ce que les kilomètres enregistrés ont donné à eux seuls |
| **Les estimations enregistrées sont 39 % au-dessus de la vérité de la pompe** | Le verdict de calibrage — l'estimateur surévaluait et vient d'être corrigé |

### Le lire correctement

La part enregistrée et la vérité de la pompe **ont le droit de différer**, pour deux raisons distinctes qu'on confond facilement :

1. **La sélection.** Vous enregistrez les trajets que vous enregistrez. Si vos 81 % sont surtout des trajets urbains courts et que les 19 % manquants sont une portion d'autoroute, la part enregistrée est légitimement plus haute que la moyenne du réservoir. Rien n'est cassé.
2. **Le calibrage.** L'estimateur lui-même peut être biaisé. C'est ce que mesure la dernière ligne, en comparant les deux **par kilomètre**, si bien que la couverture s'annule et ne fait que pondérer la fenêtre.

Après une correction comme celle-ci, attendez-vous à voir les estimations de trajet baisser nettement au prochain trajet, puis se stabiliser. Le mécanisme complet : [Comment fonctionne Sparkilo → Comment un litre devient un chiffre](User-fr-How-It-Works#comment-un-litre-devient-un-chiffre).

La carte peut aussi pointer *ce qui a changé* — part de haut régime, événements brusques aux 100 km, démarrages à froid, part de ralenti, chacun comparé au réservoir précédent — avec la réserve explicite que les enregistrements sont spontanés et ne couvrent qu'une partie du réservoir.

---

## Statistiques de consommation

Touchez la carte de statistiques, ou **Carburant → Statistiques de consommation**.

<img src="guide/consumption-stats-1.jpg" width="340" alt="En-tête des statistiques : puces de filtre par carburant, totaux et tableau ce mois-ci vs le mois dernier">

*Les puces du haut limitent tout ce qui suit à un carburant — indispensable sur une flex-fuel, où une moyenne combinée n'a aucun sens.*

Le tableau mensuel montre litres, dépenses, prix moyen au litre, consommation moyenne, coût au km et nombre de pleins, chacun avec son écart. Les flèches rouges ne sont pas un jugement — des *dépenses* en hausse après un *prix au litre* en hausse, c'est le marché, pas votre pied droit. Le chiffre à surveiller pour la conduite est **L/100 km**.

### Coût au kilomètre par carburant

<img src="guide/consumption-stats-2.jpg" width="340" alt="Coût au kilomètre par carburant : lignes E85 et E5 avec coût/km, L/100 km, prix payé et CO2">

*La vraie question du conducteur flex-fuel, tranchée : non pas quel carburant est moins cher au litre, mais lequel l'est au kilomètre.*

Chaque carburant a une ligne bâtie uniquement sur des **fenêtres de réservoir fermées** : L/100 km mesurés, prix réellement payé au litre, coût aux 100 km, total dépensé, distance mesurée, litres consommés, CO₂ aux 100 km, et le nombre de pleins complets derrière. Une ligne adossée à un seul réservoir est marquée **Provisoire**.

<img src="guide/consumption-stats-3.jpg" width="340" alt="Carte de verdict sur le coût d'utilisation avec le gagnant, le seuil de rentabilité et la note CO2">

*La carte de verdict annonce le gagnant, l'écart aux 1000 km et — le plus utile — le **seuil de rentabilité**.*

La ligne de seuil (« E5 devient plus avantageux que E85 en dessous de 0,75 €/L ») est calculée à partir de **votre propre consommation mesurée de chaque carburant** : elle bouge donc avec votre conduite. C'est une règle de décision utilisable à la pompe ; un ratio générique trouvé sur Internet ne l'est pas.

Les valeurs CO₂ sont des estimations du puits à la roue (EU JEC WTW v5) appliquées à votre consommation mesurée — de la sensibilisation, pas une comptabilité certifiée. Les mélanges sont exclus du CO₂ car le facteur d'émission dépend du mélange, que la ligne n'enregistre pas.

<img src="guide/consumption-stats-4.jpg" width="340" alt="Évolution dans le temps : litres par mois et dépenses par mois, empilés par carburant">

*Les graphiques de tendance empilent par carburant : un changement apparaît comme une couleur qui en remplace une autre, plutôt que comme un saut mystérieux.*

<img src="guide/consumption-stats-5.jpg" width="340" alt="Prix par litre et L/100 km par mois">

*Prix au litre et L/100 km sont volontairement deux graphiques distincts — l'un est le marché, l'autre c'est vous.*

**Exporter** écrit l'ensemble en CSV dans votre dossier Téléchargements public.

---

## Éco-note par plein

Chaque plein reçoit un badge comparé à la moyenne glissante de vos trois derniers pleins du même carburant :

| Écart | Badge | À lire comme |
|---|---|---|
| ≥ 3 % mieux | 🟢 En progrès | Nettement moins que votre propre référence |
| dans ±3 % | ⚪ Stable | Variation normale |
| ≥ 3 % moins bien | 🟠 En baisse | Vérifiez pression des pneus, coffre de toit, froid, mélange de routes |

Le badge reste masqué tant que vous n'avez pas quatre pleins de ce carburant, pour que la référence soit réelle.

---

## Quand les comptes ne tombent pas juste

Tôt ou tard vous mettrez plus de litres que vos trajets enregistrés ne peuvent expliquer — quelqu'un d'autre a conduit, l'adaptateur était débranché, l'application fermée. Plutôt que d'absorber la différence en silence, l'application affiche un **bandeau d'écart** et propose une courte réconciliation :

> *Nous avons trouvé un écart de 4,2 L. Vous avez versé 35,7 L, mais vos trajets enregistrés n'en expliquent que 31,5 L.*

Elle pose deux questions :

1. **Tous vos pleins de ce réservoir sont-ils complets et corrects ?** — Non signifie qu'un plein manque ou est mal saisi, et l'application ajoute un **plein de correction** pour que les litres tombent juste.
2. **Tous vos trajets sont-ils enregistrés ?** — Non signifie qu'un trajet manque, et l'application ajoute un **trajet virtuel** pour la distance manquante.

Les deux artefacts sont modifiables et supprimables ensuite, et tous deux sont marqués comme générés automatiquement pour qu'on ne les confonde jamais avec de vraies données. Vous pouvez aussi choisir **Décider plus tard** — le bandeau reste jusqu'à résolution.

**Pourquoi ça compte :** un écart non résolu biaise silencieusement la fenêtre de calibrage. Le résoudre (ou supprimer la mauvaise entrée) garde l'ancrage à la pompe digne de confiance.

---

## Cartes de fidélité

**Réglages → Conduite et consommation → Cartes de fidélité** stocke les remises au litre des enseignes que vous utilisez. La remise est ensuite appliquée dans les comparaisons de prix : une station en apparence 2 ct/L plus chère peut à juste titre se classer moins chère pour vous. La fonction s'active sous Fonctions et mode d'utilisation → Saisie et scan.

---

<details>
<summary>Vue d'ensemble — statistiques de consommation, page entière</summary>

<img src="guide/full/consumption-stats.jpg" width="420" alt="Statistiques de consommation complètes assemblées à partir de cinq captures">

</details>

---

**Voir aussi :** [Véhicules et OBD2](User-fr-Vehicles-And-OBD2) · [Trajets et éco-coaching](User-fr-Trips-And-Coaching)
**Suite :** [Trajets et éco-coaching →](User-fr-Trips-And-Coaching)
