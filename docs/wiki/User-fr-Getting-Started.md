# Premiers pas

Dix minutes entre l'installation et le premier euro économisé. Si vous ne lisez qu'une autre page ensuite, que ce soit [Comment fonctionne Sparkilo](User-fr-How-It-Works).

---

## 1. Installer

### Google Play (Android)

Installez depuis le **[Google Play Store](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices)** — la version publique de production.

> **Vous venez de la bêta ?** Play continue de servir des versions bêta une fois inscrit au test ouvert (la fiche affiche une mention *(bêta)*). Pour passer en production : ouvrez la [fiche Play](https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices) → **Quitter le programme** → désinstaller → réinstaller.
>
> **Les nouveautés d'abord ?** Restez en bêta — chaque version atteint le canal bêta avant la production.

### F-Droid (Android, sans Google)

Une version entièrement **sans GMS** est distribuée par son propre dépôt F-Droid (cartes OpenStreetMap, aucun service Google). Dans F-Droid : **Paramètres → Dépôts → +** et ajoutez :

```
https://fdittgen-png.github.io/tankstellen/fdroid/repo
```

Puis cherchez **Sparkilo**. Si la version Play est installée, désinstallez-la d'abord — clé de signature différente, donc pas de mise à jour par-dessus.

### Autres moyens

- **APK** — depuis les [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases).
- **iPhone** — bêta TestFlight ; demandez une invitation via [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues) tant que la fiche App Store n'est pas publiée.

**Android minimum** 7.0 (API 24), cible Android 15. **iOS minimum** 15.5, cible iOS 18.

Pas de compte, pas d'inscription, pas d'e-mail. L'application est pleinement utilisable dès la fin de l'installation.

---

## 2. Premier lancement — le consentement

Avant tout autre écran, l'application affiche un **écran de consentement RGPD**. Ce n'est pas une bannière cookies : il liste chaque finalité de traitement, et l'application ne continue que si vous acceptez.

<img src="screenshots/privacy-consent.png" width="340" alt="Écran de consentement au premier lancement listant chaque finalité">

*Chaque consentement montré ici est repris plus tard dans Réglages → Confidentialité et données, avec la date et la version de la politique que vous avez vue.*

| Élément | Pourquoi | Si vous refusez |
|---|---|---|
| **Position** *(pendant l'utilisation)* | Recherche à proximité, départ d'itinéraire, enregistrement de trajet | Chercher par code postal ou choisir un point sur la carte |
| **Notifications** | Uniquement pour les alertes de prix | Les alertes ne se déclenchent jamais |
| **Diagnostics** | Traces de plantage vers Sentry — **désactivé par défaut** | Rien n'est envoyé ; vous pouvez toujours enregistrer le journal d'erreurs vous-même |

Avant chaque demande *système* (caméra, Bluetooth, notifications), l'application affiche d'abord sa propre explication, pour que vous sachiez à quoi vous consentez avant qu'Android ne le demande.

Texte intégral : **[Politique de confidentialité v3, 29 août 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/fr/)**.

---

## 3. Pays, langue et votre zone

Les deux sont détectés depuis la langue système, et les deux vivent **dans le profil** — voir [Comment fonctionne Sparkilo → Profils](User-fr-How-It-Works#profils--un-contexte-un-jeu-de-valeurs-par-défaut).

<img src="guide/profile-edit-6.jpg" width="340" alt="Sélecteur de langue et code postal du domicile dans l'éditeur de profil">

*Réglages → Profils et région → modifier le profil. Le code postal du domicile permet de chercher dans une zone fixe sans jamais céder le GPS.*

Changer de pays **vide les données de stations en cache**, car les prix du fournisseur précédent ne s'appliquent pas au nouveau pays. La recherche suivante prendra donc un instant de plus.

---

## 4. Choisir un mode d'utilisation

C'est le réglage le plus lourd de conséquences, car il décide de la quantité d'application que vous obtenez.

<img src="guide/features-and-mode-1.jpg" width="340" alt="Préréglages Basique, Moyen, Complet, Personnalisé">

*Réglages → Fonctions et mode d'utilisation. Commencez en **Basique** si vous voulez seulement du carburant moins cher ; montez quand vous voudrez savoir pourquoi votre voiture boit.*

- **Basique** — trouver carburant et recharge, favoris, alertes, itinéraires.
- **Moyen** — ajoute l'onglet **Carburant** : enregistrer vos pleins, voir consommation et coût réels. Aucun matériel nécessaire.
- **Complet** — ajoute l'onglet **Trajets** : enregistrement automatique, scores de conduite, cartes de fidélité. Un adaptateur OBD2 reste facultatif même ici — les trajets s'enregistrent au GPS seul.

Vous pouvez changer à tout moment, et tout interrupteur individuel touché ensuite vous met en **Personnalisé**. La liste complète, et ce que chacun coûte en batterie, données ou vie privée : [Référence des réglages → Fonctions et mode d'utilisation](User-fr-Settings-Reference#fonctions-et-mode-dutilisation).

---

## 5. Allemagne uniquement : la clé API gratuite

16 des 17 pays fonctionnent immédiatement. Le service officiel **allemand** délivre une clé par utilisateur.

<img src="guide/data-sources-location.jpg" width="340" alt="Écran des sources de données avec les champs de clé Tankerkönig et OpenChargeMap">

*Réglages → Sources de données et position. Une croix rouge ici est la raison pour laquelle une recherche allemande ne renvoie rien.*

1. Ouvrez [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) et demandez une clé (formulaire court, gratuit).
2. Copiez-la — c'est un UUID comme `00000000-0000-0000-0000-000000000002`.
3. Collez-la dans le champ **Prix carburants (Tankerkoenig)**.

La clé est conservée dans le coffre matériel (Android Keystore / Trousseau iOS) et n'est envoyée qu'au service allemand. Le champ **Recharge EV** en dessous contient déjà une clé partagée : les données de recharge fonctionnent sans configuration.

---

## 6. La barre du bas

<img src="guide/favorites.jpg" width="340" alt="Onglet Favoris avec la barre du bas et le bouton Recherche central">

*Le bouton vert **Recherche** surélevé au centre est le seul déclencheur de recherche de toute l'application.*

- ⭐ **Favoris** — stations enregistrées et alertes de prix
- 🗺️ **Carte** — chaque station proche en épingle colorée par prix
- 🔍 **Recherche** *(au centre)* — à proximité ou le long d'un trajet
- ⛽ **Carburant** — réservoir, consommation, pleins *(à partir de Moyen)*
- 🛣️ **Trajets** — carnet de bord et coaching *(Complet)*

Les réglages **ne sont pas** un onglet : c'est l'engrenage en haut à droite des écrans principaux. Sur tablette, ou téléphone tenu à l'horizontale, l'application se divise en deux colonnes pour voir liste et carte (ou détail) en même temps.

---

## 7. Votre première recherche

<img src="guide/search-criteria-nearby.jpg" width="340" alt="Feuille des critères pour une recherche à proximité">

*Touchez **Recherche** → la feuille de critères s'ouvre pré-remplie depuis votre profil. Ajustez, puis touchez **Rechercher** à nouveau.*

Vous obtenez une liste triée du moins cher au plus cher (ou par distance — à vous de voir), chaque fiche montrant prix, tendance, distance et fraîcheur. Un appui ouvre le détail complet. La visite guidée : [Trouver des stations](User-fr-Finding-Stations).

**Astuce :** touchez **Enregistrer comme valeurs par défaut** en bas de la feuille une fois vos critères habituels réglés — toute recherche future partira de là.

---

## 8. Deux réglages à changer dès le premier jour

<img src="guide/units-and-display-1.jpg" width="340" alt="Unités et affichage avec thème, unité de distance et unité de consommation">

*Réglages → Unités et affichage. L'**unité de consommation** est *Automatique* par défaut (mpg au Royaume-Uni, L/100 km ailleurs) ; choisissez explicitement L/100 km, km/L ou mpg si vous préférez.*

Le second est **Réglages → Conduite et consommation → Fenêtre de consommation en direct** (3 / 5 / 10 / 30 s). Il pilote le grand chiffre en direct de l'écran d'enregistrement : une fenêtre longue est plus stable à lire en conduisant, une courte réagit plus vite à votre pied droit.

---

## 9. Choisissez sur quoi l'application s'ouvre

**Réglages → Profils et région → Écran d'accueil** : *À proximité* (recherche immédiate avec vos derniers critères), *Station la plus proche*, *Favoris* ou *Carte*. Prenez celui qui correspond à la raison pour laquelle vous ouvrez l'application.

---

## 10. Où tout se trouve

Les réglages sont un arbre à deux niveaux avec une recherche par mot-clé en haut — tapez « rayon », « OBD2 » ou « thème » et la tuile correspondante remonte.

<img src="guide/settings-root-1.jpg" width="340" alt="Racine des réglages : tuiles thématiques avec champ de recherche">

*Douze thèmes, un domicile par paramètre. La carte complète est la [Référence des réglages](User-fr-Settings-Reference).*

---

**Suite :** [Comment fonctionne Sparkilo →](User-fr-How-It-Works)
