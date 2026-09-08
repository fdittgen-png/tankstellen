# Comment fonctionne Sparkilo

Cette page est le modèle mental. Tout le reste du guide décrit des chemins de clic ; ici on explique *pourquoi* ces chemins ont cette forme. Dix minutes ici vous épargneront une heure à fouiller les réglages.

---

## Les trois niveaux d'économie

Une voiture coûte de l'argent de trois façons indépendantes, et faire baisser l'une ne fait rien pour les autres :

1. **Le prix au litre** — la pompe que vous choisissez. Fixé par la géographie et le marché ; le rôle de l'application est de vous montrer la moins chère que vous pouvez réellement atteindre.
2. **Les litres au kilomètre** — comment vous conduisez et ce que vous conduisez. Le rôle de l'application est de le mesurer honnêtement et de montrer quelle habitude coûte le plus.
3. **Ce que vous avez réellement payé** — la piste d'audit. Le rôle de l'application est de garder ses propres estimations ancrées au réel plutôt que de les laisser dériver.

Le niveau 1 fonctionne dès l'installation. Les niveaux 2 et 3 demandent vos données : au minimum vos pleins, idéalement aussi des trajets enregistrés. **L'application ne prétend jamais en savoir plus qu'on ne lui a dit** — d'où les badges de précision, les pourcentages de couverture et les mentions « provisoire » plutôt que de jolis chiffres ronds.

---

## Modes d'utilisation : mettre l'app à votre taille

Sparkilo peut être un chercheur de prix en deux écrans ou un véritable ordinateur de bord. Plutôt que d'imposer tous les interrupteurs à tout le monde, l'application regroupe les fonctions en **préréglages de mode d'utilisation**.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Gestion des fonctionnalités avec les préréglages Basique, Moyen, Complet et Personnalisé">

*Réglages → Fonctions et mode d'utilisation. Choisir un préréglage bascule d'un coup tout l'ensemble de fonctions correspondant ; toucher ensuite un interrupteur individuel vous fait passer en **Personnalisé**.*

| Préréglage | Vous obtenez | Barre du bas |
|---|---|---|
| **Basique** | Carburant et recharge les moins chers à proximité, favoris, alertes de prix, itinéraires | Favoris · Carte · **Recherche** |
| **Moyen** | Tout Basique + suivi manuel des pleins, consommation et coût réels | + Carburant |
| **Complet** | Tout Moyen + enregistrement OBD2 automatique des trajets, scores de conduite, cartes de fidélité | + Trajets |
| **Personnalisé** | Votre propre mélange — dès que vous touchez un interrupteur | selon le cas |

### Comment ça marche réellement

Un préréglage n'est pas un mode dans lequel l'application tourne — c'est un **ensemble nommé de drapeaux de fonctionnalités**. Chaque drapeau affiche ou masque une fonction de façon indépendante, et certains déclarent des prérequis : *Synchronisation des références* reste grisée tant que *TankSync* est éteint, *Annonces vocales* tant que *Retour vocal* est éteint, *Enregistrement automatique* tant qu'aucun adaptateur n'est appairé. La carte explique pourquoi un interrupteur est verrouillé au lieu d'ignorer votre appui en silence.

### Ce que ça change en pratique

- **Désactiver une fonction la retire de l'application, pas seulement de la vue** — son travail en arrière-plan s'arrête aussi. *Alertes de prix* éteintes arrête la vérification périodique ; *Trace GPS des trajets* éteinte arrête l'enregistrement des points de route.
- **Les préréglages écrasent votre mélange personnel.** Toucher *Moyen* remplace chaque interrupteur. Si vous avez réglé les choses à la main, restez en Personnalisé.
- **La barre du bas change de forme.** Si l'onglet Carburant ou Trajets a disparu, c'est que vous (ou un préréglage) avez éteint *Analyse de consommation* ou *Enregistrement OBD2 des trajets* — ce n'est pas un bug.

---

## Profils : un contexte, un jeu de valeurs par défaut

Un **profil** regroupe tout ce qui dépend de *où et comment vous roulez en ce moment* : pays, langue, carburant préféré, rayon de recherche par défaut, code postal du domicile, paramètres d'itinéraire, écran d'accueil, visibilité des notes de station, les réglages du radar et le véhicule par défaut.

<img src="guide/profile-edit-1.jpg" width="340" alt="Modifier le profil — nom, carburant dérivé du véhicule, rayon par défaut">

*Réglages → Profils et région → modifier. Le carburant préféré est **dérivé de votre véhicule par défaut** — retirez le véhicule si vous voulez choisir le carburant vous-même.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Section Région du profil — sélecteurs de pays et de langue">

*Le pays et la langue vivent dans le profil : c'est pourquoi changer de profil peut changer la source de données et la langue de l'interface d'un seul geste.*

### Comment ça marche réellement

Le pays enregistré dans le profil actif décide **quel fournisseur national d'open data l'application appelle**. Le changer vide les données de stations en cache, car les prix de l'ancien fournisseur n'ont aucun sens pour le nouveau pays. Le carburant préféré décide quel prix fait la une de chaque fiche, sur quoi porte une alerte par défaut et pour quoi une recherche d'itinéraire optimise.

### Ce que ça change en pratique

- **Un profil par pays où vous roulez.** « Maison — France, E85, 10 km » et « Vacances — Espagne, E5, carte » sont deux profils, pas deux séances de réglages.
- **Les recherches transfrontalières utilisent le carburant du profil de chaque pays.** Sans profil pour le second pays, ce tronçon n'a aucune sorte à tarifer et ses stations affichent `--`.
- **Le changement automatique de profil** (Réglages → Sources de données et position) peut basculer le profil pour vous quand le GPS détecte une frontière.
- Les tuiles de réglages portent une **étiquette de portée** — *ce profil*, *tous les profils* ou *ce véhicule* — pour que vous sachiez toujours jusqu'où va une modification.

---

## Une source de données par pays

Sparkilo n'agrège pas. Chaque pays est interrogé via sa propre source officielle, et l'en-tête des résultats la nomme.

<img src="guide/search-results.jpg" width="340" alt="En-tête de résultats nommant la source de prix officielle française">

*La ligne sous la barre d'application n'est pas décorative — elle dit quelle autorité a publié ces prix, et pointe vers elle.*

### Comment ça marche réellement

| Pays | Source | Cadence |
|---|---|---|
| Allemagne | Tankerkönig (clé gratuite personnelle requise) | ~5 minutes |
| France | Prix-Carburants (gouv.fr) | en continu, par station |
| Espagne | Geoportal Gasolineras (MITECO) | fichier quotidien, filtré sur l'appareil |
| Italie | Fichier MIMIT | fichier quotidien, filtré sur l'appareil |
| …et 13 autres | le portail open data de chaque pays | variable |

### Ce que ça change en pratique

- **Les sortes de carburant diffèrent d'une frontière à l'autre.** L'Espagne vend du E5 et rarement du E10 ; la France met en avant le SP95-E10 ; l'Allemagne publie E5, E10 et Diesel. Le même carburant physique porte trois noms dans trois pays.
- **La fraîcheur diffère.** Un prix allemand peut avoir cinq minutes, un prix espagnol être la publication d'hier. Le badge de fraîcheur sur chaque fiche vous dit lequel vous regardez — faites-lui plus confiance qu'au chiffre.
- **La densité diffère.** Un jeu de données national léger renvoie moins de stations dans le même rayon. Ce sont les données du pays, pas une recherche ratée.
- **Un `--` à la place d'un prix signifie « ce fournisseur ne publie pas cette sorte pour cette station »** — pas « la station n'en vend pas ».

---

## Où vivent vos données

Sparkilo est **local-first**. Tout ce qu'elle sait est dans des bases chiffrées sur votre téléphone ; la clé est dans l'Android Keystore / le Trousseau iOS.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Données sur cet appareil : chaque catégorie de données conservée localement, avec taille et nombre">

*Réglages → Confidentialité et données → Données sur cet appareil montre chaque catégorie avec un compteur réel : rien de vos données ne vous est invisible.*

Seules quatre choses quittent le téléphone, et trois sont facultatives :

| Ce qui sort | Quand | Facultatif ? |
|---|---|---|
| Coordonnées de recherche ou code de région | À chaque recherche, vers la source de prix du pays | Nécessaire aux prix en direct |
| Zone de carte + votre adresse IP | Chargement des tuiles via le proxy UE du développeur | Oui — proxy désactivé, les tuiles viennent directement d'OpenStreetMap |
| Traces de plantage | Uniquement avec *Rapport d'erreurs* activé | Oui — désactivé par défaut |
| Vos lignes synchronisées | Uniquement avec *TankSync* activé | Oui — désactivé par défaut |

**Votre identité ne fait jamais partie d'une requête de prix.** Le décompte complet : [Confidentialité, données et sync](User-fr-Privacy-Profiles-Sync).

---

## Comment un litre devient un chiffre

C'est la partie que la plupart des applications de carburant ratent discrètement ; elle mérite d'être comprise.

### La pompe est la vérité

Le seul chiffre physiquement certain que l'application obtienne est **litres versés ÷ kilomètres parcourus entre deux pleins complets**. Tout le reste — estimations GPS, débit dérivé du débitmètre d'air, modélisation speed-density — est un modèle qui peut dériver.

L'application traite donc chaque **fenêtre de réservoir plein à plein** comme un événement de calibrage :

1. Vous enregistrez un plein et cochez **Plein complet**. Cela ferme la fenêtre précédente.
2. L'application calcule la *vérité de la pompe* : litres versés ÷ kilomètres au compteur × 100.
3. Elle la compare à ce que son propre estimateur a produit sur les kilomètres réellement enregistrés, chaque correction déjà appliquée étant retirée.
4. Le rapport entre les deux devient le **gain pompe** du véhicule, fondu avec les fenêtres précédentes et borné à une plage raisonnable.
5. Ce gain multiplie ensuite **toutes les branches estimées du débit de carburant** — speed-density et MAF — au trajet suivant.

Le carburant que votre voiture *déclare elle-même* en OBD2 (PID 5E / 9D) est mesuré, pas modélisé : le gain n'y touche jamais.

<img src="guide/trips-tab.jpg" width="340" alt="Rapport de plein montrant la couverture et l'écart de calibrage">

*Le rapport de plein rend le calibrage visible : ce réservoir a tourné à 6,4 L/100 km à la pompe, les enregistrements en couvraient 81 %, et l'estimateur surévaluait de 39 % avant que cette fenêtre ne le corrige.*

### Pourquoi la couverture ne fausse rien

Comparer les deux chiffres **par kilomètre** fait que les kilomètres non enregistrés ne pèsent tout simplement rien. Un réservoir dont vous n'avez enregistré qu'un cinquième donne quand même un rapport non biaisé — il compte simplement moins dans le mélange. C'est pourquoi l'application affiche un pourcentage de couverture au lieu de le cacher : il dit combien faire confiance à *cette* fenêtre, pas si le calibrage est valide.

### L'échelle de précision

| Badge | Ce qu'il y a derrière | Plage typique |
|---|---|---|
| **Faible** | GPS seul — aucun plein n'a encore rien ancré | ±15 % et pire |
| **Moyenne** | Les pleins ont ancré le modèle, mais aucun trajet OBD2 n'a alimenté la boucle | ±7–15 % |
| **Élevée** | Pleins *et* trajets enregistrés en OBD2 | ±3–7 % |

### Ce que ça change en pratique

- **Cochez toujours « Plein complet » quand vous faites le plein à ras bord.** Un plein partiel est quand même enregistré et compte pour le coût, mais il ne peut pas fermer une fenêtre de calibrage. Les pleins partiels en attente apparaissent en bandeau dans les statistiques.
- **La précision du compteur compte plus que celle des litres.** Une faute de frappe de 2 % au compteur empoisonne la fenêtre ; 0,2 L d'arrondi non.
- **La première fenêtre est prise au pied de la lettre, les suivantes lissent.** Attendez-vous à un saut, puis à une stabilisation.
- **Si vous roulez sans enregistrer, les comptes ne tomberont pas juste** — et l'application le dit au lieu de bricoler. Voir la réconciliation dans [Carnet de pleins et consommation](User-fr-Fuel-And-Consumption#quand-les-comptes-ne-tombent-pas-juste).

---

## Comment l'application apprend votre conduite

Indépendamment du gain pompe, un véhicule porte une **baseline par situation de conduite** : ce que votre voiture consomme au ralenti, en stop & go, en ville, sur autoroute, en décélération, en côte ou chargée, à froid, en charge soutenue et en roue libre.

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibrage de la baseline avec le nombre d'échantillons par situation et l'avertissement sur les situations manquantes">

*Chaque situation se remplit indépendamment. L'avertissement est honnête : deux situations n'ont encore aucun échantillon, la référence est donc incomplète.*

### Comment ça marche réellement

Chaque échantillon OBD2 est classé dans une situation de conduite et ajouté à ce panier. Deux modes de classement existent :

- **Basé sur les règles** — chaque échantillon appartient à exactement une situation. Net, mais une voiture qui roule à 60 km/h bascule d'un échantillon à l'autre entre « urbain » et « autoroute ».
- **Flou** *(par défaut)* — chaque échantillon est réparti sur toutes les situations selon son degré d'appartenance. Lisse précisément là où le mode règles saute.

### Ce que ça change en pratique

- **Une baseline appartient au véhicule, pas au téléphone.** Changer de voiture veut dire en recommencer une ; *Synchronisation des références* (nécessite TankSync) la porte sur un second appareil.
- **Les situations manquantes sont des trous honnêtes, pas des erreurs.** Si vous ne tractez jamais, « Charge soutenue / remorquage » restera à 0 pour toujours, et l'application continuera de dire que le profil est incomplet. C'est normal.
- **Réinitialiser la baseline vous ramène aux valeurs de départ à froid** jusqu'à ce que de nouveaux trajets la remplissent — à faire après une intervention mécanique, pas parce qu'un chiffre semblait bizarre.

---

## La seule règle de réglages à retenir

Les réglages sont un **arbre à deux niveaux** : une racine de tuiles thématiques, un écran par thème, et un champ de recherche qui filtre les tuiles par mot-clé.

<img src="guide/settings-root-1.jpg" width="340" alt="Racine des réglages avec les tuiles thématiques et le champ de recherche">

*Chaque paramètre a exactement un domicile. Si vous vous souvenez du thème, vous n'avez jamais à faire défiler.*

Carte complète de tous les écrans : [Référence des réglages](User-fr-Settings-Reference).

---

**Suite :** [Trouver des stations →](User-fr-Finding-Stations)
