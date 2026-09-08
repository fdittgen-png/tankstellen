# Favoris et alertes de prix

L'onglet ⭐ est votre sélection, plus les robots qui la surveillent pour vous.

---

## Favoris

<img src="guide/favorites.jpg" width="340" alt="Onglet Favoris avec deux stations enregistrées, prix par carburant et l'onglet des alertes">

*Deux onglets en haut : **Favoris** et **Alertes de prix**. Chaque fiche porte toutes les sortes déclarées, pas seulement la vôtre.*

Marquez une station avec l'★ sur n'importe quelle fiche de résultat ou sur son écran de détail.

### Ce qui est réellement stocké

Un favori n'est pas un signet, c'est une **copie locale complète** de la station : identifiant, adresse, équipements, moyens de paiement, horaires et les derniers prix vus. C'est pourquoi l'onglet fonctionne sans réseau : vous voyez les derniers prix connus, clairement marqués par leur horodatage de fraîcheur.

### Ce que ça change en pratique

- **Les favoris fonctionnent hors ligne** ; les recherches non. Avant un trajet en zone blanche, ouvrez l'onglet une fois en Wi-Fi.
- Les prix se rafraîchissent à l'ouverture de l'onglet, pas en continu.
- Les favoris font partie des catégories que **TankSync** réplique entre vos appareils, si vous l'activez.

### Tri et gestes

Tri par prix (le moins cher d'abord, par défaut), par distance ou alphabétique. **Balayer à droite** ouvre la navigation ; **balayer à gauche** retire le favori, avec une annulation possible.

### Bornes de recharge

Les bornes se mettent aussi en favori, et la fiche montre ce qu'il faut à un conducteur électrique : **puissance par connecteur en kW**, combien sont **libres à l'instant**, et les **types de connecteurs**.

### Paysage et tablettes

Sur téléphone en paysage et sur tout écran de plus de 600 dp, favoris et alertes s'affichent **côte à côte** avec un séparateur au lieu d'un sélecteur d'onglets. Les deux panneaux étant visibles, il n'y a pas de bascule dans cette disposition.

---

## Alertes de prix

<img src="guide/price-alerts.jpg" width="340" alt="Écran des alertes : compteurs actives/aujourd'hui/cette semaine, alertes de station et de zone">

*Trois compteurs en haut — règles actives, déclenchements aujourd'hui et cette semaine — puis les deux types d'alerte. Le pied de page horodate la dernière vérification en arrière-plan.*

Il y en a deux sortes, qui répondent à des questions différentes.

### Alerte de station — « préviens-moi quand *cette* pompe baisse »

Créée depuis la page détail d'une station (icône cloche). Choisissez le carburant, fixez un seuil, enregistrez. Idéal pour la station que vous utilisez déjà.

### Alerte de zone — « préviens-moi quand *quelque part par ici* baisse »

<img src="guide/price-alert-create.jpg" width="340" alt="Créer une alerte de zone : libellé, type de carburant, seuil, rayon, fréquence, position ou code postal">

*Réglages → Prix et alertes → Alertes de prix → **Créer une alerte de zone**.*

| Champ | Ce qu'il fait |
|---|---|
| **Libellé** | Texte libre pour qu'une liste d'alertes reste lisible (« Diesel maison ») |
| **Type de carburant** | Une sorte par alerte — une station peut porter plusieurs alertes |
| **Seuil (€/L)** | Se déclenche quand une station de la zone passe **en dessous** |
| **Rayon (km)** | La zone surveillée autour du point central |
| **Fréquence de vérification** | À quelle fréquence la tâche de fond regarde — voir plus bas |
| **Ma position / Choisir sur la carte / Code postal** | Trois façons de fixer le centre ; un code postal ne touche jamais au GPS |

Idéal pour « préviens-moi quand le diesel passe sous 1,60 € dans un rayon de 5 km autour de chez moi », quand la station précise vous est indifférente.

---

## Comment la vérification fonctionne vraiment

Une tâche de fond planifiée par le système se réveille et :

1. Récupère les prix en direct des stations concernées.
2. Compare chacun à son seuil.
3. Déclenche une **notification locale** si un prix est en dessous. L'appui ouvre la station.

La cadence est de **30 minutes en charge, une heure sinon**, et uniquement avec une connexion. Votre fréquence par alerte est un plafond à l'intérieur : « une fois par jour » fait sauter l'alerte la plupart du temps.

### Ce que ça change en pratique

- **Les alertes sont au mieux, pas en temps réel.** C'est le système qui décide quand la tâche tourne ; les économiseurs agressifs la retardent ou la tuent. Si l'horaire compte, sortez l'application de l'optimisation de batterie.
- **Aucun GPS n'est utilisé.** Les alertes travaillent sur les coordonnées stockées des stations : une alerte autour de chez vous continue de fonctionner à 500 km de là.
- **Le coût en batterie est négligeable** — quelques Ko par réveil, dans un créneau géré par le système, compatible Doze. Bien moins de 0,5 % par jour.
- **Un effet de bord utile :** la même vérification écrit un relevé de prix dans votre historique local. Une station sous alerte construit donc son historique de 30 jours en heures plutôt qu'en semaines — c'est ce qui fait apparaître vite le bandeau *meilleur moment pour faire le plein*. Voir [Historique des prix](User-fr-Price-History-And-Predictions#la-phase-dapprentissage).
- **Si les notifications sont coupées au niveau système**, l'interrupteur de l'application ne peut rien déclencher.

---

## Statistiques

Les compteurs du haut montrent combien de règles sont actives et combien de fois elles se sont déclenchées aujourd'hui et cette semaine — un test rapide pour savoir si la tâche de fond tourne vraiment. Une rangée de zéros avec plusieurs alertes actives et un horodatage « dernière vérification » ancien est le symptôme classique d'un économiseur de batterie qui tue la tâche.

---

## Arrêter les alertes

Désactiver une alerte la met en pause sans perdre la règle ; balayer à gauche la supprime. Retirer la station des favoris ne supprime **pas** ses alertes.

---

**Voir aussi :** [Historique et prévisions de prix](User-fr-Price-History-And-Predictions) · [Référence des réglages → Prix et alertes](User-fr-Settings-Reference#prix-et-alertes)
**Suite :** [Recharge électrique →](User-fr-EV-Charging)
