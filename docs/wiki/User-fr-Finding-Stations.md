# Trouver des stations

Niveau 1 des [trois niveaux d'économie](User-fr-How-It-Works#les-trois-niveaux-déconomie) : payer moins au litre.

---

## Un bouton, un modèle mental

La barre du bas n'a qu'un déclencheur de recherche — le bouton vert surélevé au centre. Il est contextuel plutôt que modal :

- **Depuis n'importe quel onglet** → ouvre la feuille de critères.
- **Depuis les résultats ou la carte** → rouvre la feuille avec vos derniers réglages.
- **Dans la feuille** → lance la recherche.

Son libellé indique ce qu'il va faire, et en mode itinéraire il reste désactivé tant qu'il n'y a pas de destination. Il n'y a délibérément pas de boutons séparés « chercher à proximité » et « chercher le long du trajet ».

---

## Régler les critères

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Critères : proximité ou trajet, adresse, puces carburant, rayon, ouvertes, équipements, marques">

*La feuille s'ouvre pré-remplie depuis votre profil actif — vous ne changez généralement qu'une chose.*

| Commande | Ce qu'elle fait | Impact opérationnel |
|---|---|---|
| **À proximité / Le long du trajet** | Change tout le mode de recherche | Le mode trajet exige une destination et interroge chaque pays du corridor |
| **Adresse, code postal ou ville** | Cherche à un endroit plutôt qu'à votre position GPS | Rien sur votre position ne quitte le téléphone ; le nom du lieu est géocodé via OpenStreetMap Nominatim et mis en cache 24 h |
| **Puces de carburant** | La sorte pour laquelle les prix s'affichent | La liste s'adapte à ce que le fournisseur de votre pays publie réellement |
| **Rayon** | Jusqu'où chercher | Un grand rayon dans un pays dense renvoie beaucoup de stations et ralentit la recherche |
| **Ouvertes uniquement** | Masque les stations fermées | Dépend du fournisseur qui publie les horaires — certains ne le font pas |
| **Équipements** | Boutique, lavage, air, WC… | Filtre uniquement sur les données déclarées ; une station au champ vide disparaît |
| **Marques** | Restreindre à certaines enseignes | Comptées sur l'ensemble courant de résultats, la liste change donc avec le rayon |
| **Enregistrer comme valeurs par défaut** | Écrit ces critères dans le profil | Toute recherche future part d'ici |

### Comment ça marche réellement

Une recherche à proximité envoie **vos coordonnées (ou un code de région) et un rayon** au fournisseur officiel de votre pays — jamais votre identité. Les pays qui publient un fichier quotidien (Espagne, Italie) sont filtrés sur l'appareil : ces recherches n'ont besoin d'aucun appel réseau une fois le fichier en cache.

---

## Lire une fiche de résultat

<img src="guide/search-results.jpg" width="340" alt="Liste de résultats avec prix, flèche de tendance, fraîcheur, équipements, distance et étoile">

*Tout ce qu'il faut pour décider, sans rien ouvrir.*

- **Prix** — pour le carburant cherché, dans la convention de votre pays (notez le dixième de centime en exposant).
- **Flèche de tendance** ▲▼▬ — où va le prix de cette station récemment, d'après *votre propre* historique local.
- **★** — appuyer pour mettre en favori ; pleine = déjà enregistrée.
- **Puces d'équipement** — boutique, lavage, air, DAB, tels que déclarés.
- **Distance** — à vol d'oiseau depuis votre position.
- **« Mis à jour 31/08 00:01 »** — l'horodatage de fraîcheur. **Lisez-le avant le prix.**
- **Ligne de tri** — Distance / Prix / A–Z / 24 h, plus une puce d'avertissement quand le prix le plus récent de la liste a plus d'une heure.

### La fraîcheur, plus importante que le prix

| Badge | Âge | Que faire |
|---|---|---|
| Vert | < 5 min | Faire confiance |
| Jaune | 5–30 min | Suffisant pour décider |
| Orange | heures | Plausible ; le fournisseur publie peut-être lentement |
| Contour rouge | > 1 jour | À traiter comme indicatif — actualisez avant de faire un détour |

La fraîcheur est une propriété du **fournisseur du pays**, pas de l'application. Un prix espagnol de 14 heures n'est pas un bug : ce pays publie une fois par jour. Voir [Comment fonctionne Sparkilo → Une source par pays](User-fr-How-It-Works#une-source-de-données-par-pays).

### Gestes de balayage

- **Balayer à droite** — ouvrir dans votre application de navigation (Google Maps, Waze, OsmAnd, Organic Maps).
- **Balayer à gauche** — masquer la station de tous les résultats futurs. On la ré-affiche depuis **Confidentialité et données → Données sur cet appareil → Stations ignorées**.

---

## Détail d'une station

<img src="guide/station-detail-1.jpg" width="340" alt="Détail station : tableau des prix par carburant, ajouter un plein, horaires, zone">

*Touchez une fiche. L'en-tête retombe de la marque au nom puis à la rue, si bien qu'un Intermarché sans champ marque affiche quand même « Intermarché ».*

Le bloc du haut est le **tableau complet des prix** — toutes les sortes que le fournisseur publie pour cette station, avec `--` là où il n'en publie aucune. C'est le moyen le plus rapide de voir si la station E85 bon marché tient aussi la route au diesel.

**Ajouter un plein** pré-remplit la station, le carburant et le prix dans le formulaire — le plus gros gain de temps de l'application si vous enregistrez vos pleins.

<img src="guide/station-detail-2.jpg" width="340" alt="Suite du détail : zone, équipements, moyens de paiement, votre note, historique des prix">

*Plus bas : services, moyens de paiement acceptés, votre note privée en étoiles, et l'historique local des prix sur 30 jours.*

Les actions de la barre supérieure sont, de gauche à droite : **créer une alerte de prix**, **scanner un QR de paiement**, **signaler un prix erroné**, et **mettre en favori**.

---

## La carte

<img src="guide/map-view.jpg" width="340" alt="Carte avec épingles colorées par prix, cercle de rayon et légende bon marché / cher">

*La couleur est relative à ce qui est à l'écran : vert = la moins chère visible, rouge = la plus chère. Le pied de page indique le nombre de stations, le rayon et l'âge des données.*

- **Les marqueurs de cluster** regroupent les épingles au dézoom ; un appui zoome.
- **Appui long** n'importe où pour poser votre propre marqueur et chercher depuis ce point.
- Le **bouton VE** en haut à droite bascule la carte sur les bornes — voir [Recharge électrique](User-fr-EV-Charging).
- **Partager** envoie la vue courante à quelqu'un.

Les tuiles viennent d'OpenStreetMap. Par défaut elles passent par le proxy UE du développeur pour qu'OpenStreetMap ne voie jamais votre IP ; vous pouvez désactiver le proxy dans Réglages → Confidentialité et données et charger en direct. La version F-Droid n'utilise jamais le proxy.

---

## Le radar de stations-service

Un balayage en direct autour de votre position, conçu pour **rouler**.

<img src="screenshots/radar-start.png" width="340" alt="La pastille « Démarrer le radar de stations-service » sur l'écran de résultats">

*Après toute recherche à proximité, une pastille flottante apparaît en bas à droite. Un appui démarre le radar.*

### Comment ça marche réellement

Le radar rafraîchit votre position GPS, récupère les **emplacements** de stations sur un large corridor de 60 km et fusionne une requête directe dans le rayon : il ne peut donc jamais montrer moins qu'une recherche normale. Les stations ne bougent pas, ces emplacements sont donc mis en cache jusqu'à une heure et réutilisés ; seul le **prix** d'une station dont vous approchez est récupéré juste à temps. C'est ce qui rend un radar en fonctionnement continu peu coûteux en données comme en batterie.

<img src="screenshots/radar-active.png" width="340" alt="Radar en marche : épingles de prix en direct et liste triée par distance avec barres de proximité">

*En marche : résultats triés par distance, chacun avec une barre qui se remplit à l'approche.*

### Pendant l'enregistrement d'un trajet

Le radar épingle une fiche **Station la plus proche** en haut de l'écran d'enregistrement — nom, prix pour votre carburant, distance, et une barre qui atteint 100 % à l'arrivée. Balayez à gauche/droite pour parcourir les candidates. En entrant dans le rayon d'approche configuré, la vignette en incrustation bascule sur un grand affichage de prix ; voir [Trajets et éco-coaching → L'overlay d'approche](User-fr-Trips-And-Coaching#loverlay-dapproche).

### Réglages qui changent son comportement

Tous sous **Réglages → Conduite et consommation** : le **rayon** auquel l'overlay s'agrandit, s'il montre la station **la plus proche** ou **la moins chère du rayon**, l'**intervalle minimal de rafraîchissement** (un plancher, pas une cadence fixe — il interroge plus vite à vitesse élevée mais jamais plus serré) et **l'épinglage automatique**, qui garde l'écran allumé et masque les barres système pour un support de tableau de bord, au prix de la batterie.

---

## Le calculateur de coût de carburant

Trois chiffres en entrée — distance, votre consommation, le prix — et en sortie les litres brûlés, le coût total et le coût au kilomètre. Il pré-remplit consommation et prix depuis vos propres données, si bien que vous ne tapez souvent que la distance.

Il répond honnêtement à une seule question : *la station 12 km plus loin est-elle vraiment moins chère une fois que j'y suis allé ?*

---

## Widget d'écran d'accueil

- Affiche votre favori le moins cher (ou la station la plus proche) et son prix.
- **Toucher le widget** → ouvre le détail de cette station, que l'application ait été tuée ou non.
- **Toucher l'icône d'actualisation** → recharge les prix en arrière-plan sans ouvrir l'application.
- Actualisation de fond toutes les 30 min en charge, toutes les heures sinon, dans le respect du mode Doze.

L'apparence et la variante de contenu (*prix actuel* ou *prédictif : meilleur moment pour faire le plein*) se règlent par profil dans **Réglages → Unités et affichage → Widget d'écran d'accueil**.

---

## Android Auto

Connecté à un écran Android Auto, l'application propose deux écrans compatibles conduite : **Recherche** (les stations de votre dernière recherche sur le téléphone) et **Radar** (les moins chères autour de votre route). Lancez d'abord la recherche sur le téléphone — le côté voiture est délibérément en lecture seule, car il n'existe pas de façon sûre de taper en conduisant. Android uniquement ; il n'y a pas de version CarPlay.

---

<details>
<summary>Vue d'ensemble — détail station, page entière</summary>

<img src="guide/full/station-detail.jpg" width="420" alt="Page complète du détail station assemblée à partir de deux captures">

</details>

---

**Voir aussi :** [Planification d'itinéraire](User-fr-Route-Planning) · [Favoris et alertes](User-fr-Favorites-And-Alerts) · [Historique des prix](User-fr-Price-History-And-Predictions)
**Suite :** [Planification d'itinéraire →](User-fr-Route-Planning)
