# Planification d'itinéraire

Non pas « le moins cher près de moi » mais **le moins cher sur la route** — la différence vaut plusieurs euros sur tout long trajet.

---

## Lancer une recherche d'itinéraire

<img src="guide/search-criteria-route-1.jpg" width="340" alt="Critères en mode trajet : départ, étape, destination, carburant, segment, détour, économie minimale">

*Touchez **Recherche** → basculez sur **Rechercher le long du trajet**. Le bouton reste désactivé tant qu'une destination et un carburant ne sont pas définis.*

| Champ | Signification |
|---|---|
| **Départ** | Votre position actuelle, ou une ville / un code postal saisi |
| **Ajouter une étape** | Points intermédiaires — le corridor les suit |
| **Destination** | Ville, code postal ou coordonnées |
| **Carburant** | La sorte tarifée le long du corridor |
| **Segment de trajet** | Afficher la station la moins chère tous les *n* km (50–1000 km) |
| **Détour maximal** | À quelle distance de la ligne directe une station peut se trouver |
| **Économie minimale** | Masque les arrêts qui ne battent pas la moyenne du corridor d'au moins ce montant ; *Désactivé* montre tout |

<img src="guide/search-criteria-route-2.jpg" width="340" alt="Bas des critères de trajet : ouvertes, équipements, marques, enregistrer par défaut">

*Les mêmes filtres d'ouverture, d'équipements et de marques qu'une recherche à proximité s'appliquent au corridor.*

### Comment ça marche réellement

1. L'application appelle le service public d'itinéraires **OSRM** et obtient la polyligne routière de votre trajet.
2. Elle place des points candidats le long de cette ligne, espacés selon votre **segment de trajet**.
3. Autour de chaque point, elle interroge le fournisseur de prix **du pays où se trouve ce point**, avec la sorte issue du profil de ce pays.
4. Elle classe les candidates de chaque segment selon votre stratégie et la limite de **détour maximal**.

### Ce que ça change en pratique

- **La longueur de segment est la vraie commande.** 50 km sur 600 km donne douze listes ; 200 km en donne trois. Choisissez selon la fréquence réelle de vos arrêts.
- **Le détour maximal se mesure depuis l'itinéraire direct**, pas depuis vous. 5 km signifie « jusqu'à 5 km de route en plus ».
- **Les longues routes prennent plus de temps.** Un corridor de 600 km échantillonne beaucoup de points, éventuellement sur plusieurs fournisseurs.
- Si le départ est « GPS automatique » et que le signal tombe, la recherche retombe sur la dernière position connue.

---

## Corridors transfrontaliers

Quand une route franchit une frontière, **chaque pays du corridor est interrogé via son propre fournisseur**, et l'en-tête les cite tous :

> *España — Geoportal Gasolineras (MITECO) · France — Prix Carburants (data.economie.gouv.fr)*

Comme les sortes diffèrent selon le pays, un résultat transfrontalier montre légitimement du E85 sur le tronçon français et de la Gasolina 95/E5 sur l'espagnol. Chacun est correctement tarifé de son côté, jamais moyenné.

**Il vous faut un profil par pays** avec la bonne sorte préférée, sinon le second tronçon n'a rien à tarifer et affiche `--`. Voir [Comment fonctionne Sparkilo → Profils](User-fr-How-It-Works#profils--un-contexte-un-jeu-de-valeurs-par-défaut).

---

## Les résultats arrivent progressivement

Une API nationale lente ne doit pas bloquer le reste du corridor : les résultats arrivent **au fil de l'eau**, les stations de chaque pays apparaissant dès que son fournisseur répond, avec un bandeau nommant les sources encore attendues. Vous pouvez toucher un résultat bon marché dès qu'il arrive.

---

## Les quatre stratégies

### 🏆 Meilleurs arrêts *(par défaut)*
Fait remonter les 3 à 5 stations les moins chères réellement atteignables sous forme de puces classées en haut. Les détours restent courts. C'est ce que veulent la plupart des conducteurs.

### 🎯 La moins chère
La seule station au prix le plus bas de tout l'itinéraire. Idéal quand on fait un seul plein et qu'on veut l'économie maximale au litre.

### ⚖️ Équilibrée
Note chaque candidate sur le prix *et* la proximité de la ligne. Une station à 5 km mais 10 ct/L moins chère gagne ; une à 50 km doit être bien moins chère.

### 📏 Uniforme
Découpe la route en segments égaux et propose un arrêt par segment. Idéal pour les longs trajets transfrontaliers avec plusieurs pleins.

La stratégie par défaut, la longueur de segment, le détour maximal, l'économie minimale et le nombre de candidates par point d'échantillonnage sont stockés **par profil** :

<img src="guide/profile-edit-2.jpg" width="340" alt="Paramètres de planification d'itinéraire dans l'éditeur de profil">

*Réglages → Profils et région → modifier → Planification d'itinéraire. À régler une fois ici plutôt qu'à chaque trajet dans la feuille.*

---

## Lire les résultats

Chaque ligne ajoute deux chiffres qu'une recherche à proximité n'a pas :

- **Distance depuis le départ** — où la station se situe sur la route, pour la faire coïncider avec le moment où votre réservoir sera bas.
- **Détour** — les kilomètres en plus par rapport à la ligne directe.
- **Économie vs moyenne** — contre la moyenne du corridor, pas une moyenne nationale.

Passez à **Toutes les stations** pour voir chaque station le long de la route plutôt que la sélection. La carte trace la polyligne avec toutes les épingles.

---

## Éviter les autoroutes

**Réglages → Profils et région → Affichage et stations → Éviter les autoroutes** fait préférer les routes secondaires au calculateur. Cela change la *polyligne*, donc quelles stations sont candidates : les aires d'autoroute disparaissent du corridor au lieu d'être simplement déclassées. Utile précisément parce que le carburant d'autoroute est en général le plus cher de tout itinéraire.

---

## Itinéraires enregistrés

Touchez **Enregistrer l'itinéraire** sur l'écran de résultats. Les itinéraires enregistrés apparaissent en haut du formulaire ; un appui relance le même corridor avec des **prix frais**. C'est la géométrie qui est stockée, pas les prix.

---

**Voir aussi :** [Trouver des stations](User-fr-Finding-Stations) · [Référence des réglages](User-fr-Settings-Reference#profils-et-région)
**Suite :** [Favoris et alertes →](User-fr-Favorites-And-Alerts)
