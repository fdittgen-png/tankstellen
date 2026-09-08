# Recharge électrique

Sparkilo n'est pas réservée aux thermiques. Les bornes viennent d'[OpenChargeMap](https://openchargemap.org), le plus grand registre communautaire ouvert au monde.

---

## Activer

Deux interrupteurs indépendants, tous deux sous **Réglages → Fonctions et mode d'utilisation → Recherche et carte** :

- **Recharge VE** — la fonctionnalité elle-même (recherche, pages de détail, favoris).
- **Afficher les bornes de recharge** — si les bornes apparaissent dans les résultats et sur la carte.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Interrupteurs du groupe Recherche et carte dont Recharge VE et Afficher les bornes">

*Vous pouvez afficher les stations, les bornes, ou les deux. Un conducteur 100 % électrique désactive en général **Afficher les stations-service**.*

Créez ensuite un véhicule sous **Réglages → Véhicules et OBD2 → Mes véhicules → Ajouter**, en choisissant **Électrique** comme motorisation. Un véhicule électrique porte sa capacité de batterie (kWh), ses puissances de charge AC et DC maximales (kW) et ses connecteurs (Type 2, CCS, CHAdeMO, Tesla, Schuko, Type 1, prise domestique). Les recherches se limitent alors aux bornes que votre voiture peut réellement utiliser.

---

## Comment fonctionnent les données

<img src="guide/data-sources-location.jpg" width="340" alt="Champ de clé Recharge EV montrant la clé partagée par défaut">

*Réglages → Sources de données et position. Le champ **Recharge EV (OpenChargeMap)** contient déjà une clé partagée : la recharge fonctionne sans configuration.*

L'application interroge en direct l'API POI d'OpenChargeMap pour la zone que vous regardez, et met le résultat en cache pour qu'il survive hors ligne.

### Pourquoi prendre votre propre clé

La clé intégrée est partagée par tous les utilisateurs de Sparkilo et donc limitée en débit comme un pot commun. Une clé personnelle vous donne votre propre quota et permet à OpenChargeMap de voir un usage réel de ses données. C'est gratuit :

1. Créez un compte sur [openchargemap.org](https://openchargemap.org).
2. Ouvrez **My Profile → My Apps**.
3. **Register an Application**, décrivez brièvement, et la clé API (un UUID) est émise immédiatement.

Collez-la dans le champ Recharge EV. Elle est conservée dans le même coffre matériel que la clé de prix allemande, ne quitte jamais l'appareil et n'est envoyée qu'à OpenChargeMap. Videz le champ pour revenir à la clé partagée.

### Le repli qui ressemble à un bug

Si OpenChargeMap est totalement injoignable, l'application affiche un petit **jeu de données de démonstration intégré** plutôt qu'une carte vide. Si vous voyez la même poignée de bornes génériques dans toutes les villes, c'est ce repli qui vous dit que la requête en direct a échoué — vérifiez la connexion ou la clé, et ne vous fiez pas à ces épingles.

### Contribuer en retour

OpenChargeMap est maintenue par sa communauté. Une borne manquante ou fausse se corrige sur [openchargemap.org](https://openchargemap.org), pas dans cette application — et la correction atteint ensuite toutes les applications basées sur OCM, celle-ci comprise, à la requête suivante.

---

## Rechercher

<img src="screenshots/map-ev-charging.png" width="340" alt="Carte en mode VE avec les puces de filtre par connecteur">

*Le bouton VE de la barre de carte fait passer les épingles du carburant à la recharge. La couleur suit la puissance : bleu clair en AC, bleu foncé en DC.*

Dans la feuille de critères, choisissez le type **VE** et lancez une recherche par rayon. Filtres disponibles : types de connecteurs, kW minimum, et uniquement les bornes actuellement libres là où l'opérateur publie un statut en direct.

---

## La page détail d'une borne

- **Connecteurs** — type, quantité et puissance maximale de chacun
- **Tarif** — au kWh quand l'opérateur le publie (beaucoup ne le font pas)
- **Réseau** — Ionity, Fastned, Tesla…
- **Disponibilité** — en temps réel quand elle est déclarée
- **Équipements** — restauration, sanitaires, commerces (ça compte davantage quand on stationne 30 minutes)
- **Horaires** — 24/7 ou selon l'opérateur
- **Avis** — des contributeurs OpenChargeMap

---

## Favoris et enregistrement

Les bornes se mettent en favori comme les stations ; en paysage et sur tablette, favoris et alertes s'affichent côte à côte. La fiche favorite montre les **kW par connecteur**, **combien sont libres** et les **types de connecteurs**.

Les alertes de prix ont peu d'intérêt en recharge, la plupart des opérateurs appliquant un tarif forfaitaire au kWh. Les sessions de recharge s'enregistrent comme des pleins : **onglet Carburant → Ajouter**, avec des kWh au lieu de litres — elles alimentent les mêmes statistiques de coût au kilomètre que les pleins thermiques.

---

## Franchir les frontières

Il n'y a délibérément **aucun filtre par pays** sur la recharge. En allant d'Allemagne en France, vous voyez les deux infrastructures sur la même carte. Les prix des carburants sont des jeux de données nationaux ; la recharge est un unique jeu mondial, donc la règle « un profil par pays » ne s'applique pas ici.

---

**Voir aussi :** [Trouver des stations](User-fr-Finding-Stations) · [Carnet de pleins et consommation](User-fr-Fuel-And-Consumption)
**Suite :** [Véhicules et OBD2 →](User-fr-Vehicles-And-OBD2)
