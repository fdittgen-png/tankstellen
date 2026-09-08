# Sparkilo — Guide de l'utilisateur (Français)

> *Payer moins au litre. En brûler moins au kilomètre. Voir exactement ce que ça a coûté.*

Sparkilo est une application libre et gratuite qui **réduit le coût d'usage de votre voiture**. Pas de compte, pas de publicité, pas de traceurs, pas de Google Play Services. Tout ce que l'application sait de vous reste sur votre téléphone tant que vous n'activez rien d'autre.

*L'écran que vous verrez le plus : les prix en direct près de vous, les moins chers d'abord, avec la source officielle en open data nommée en haut.*

---

## Les trois niveaux d'économie

Toute l'application est bâtie sur une idée : **une voiture coûte de l'argent de trois façons indépendantes, et chacune demande un outil différent.**

| Niveau | La question posée | Où ça vit |
|---|---|---|
| **1. Le prix** | *Où le carburant est-il le moins cher en ce moment ?* | Recherche, Carte, Favoris, Alertes, Itinéraires |
| **2. La consommation** | *Combien de litres aux 100 km, et pourquoi ?* | Trajets, éco-coaching, OBD2 |
| **3. La vérité** | *Qu'ai-je réellement payé, et l'estimation de l'app est-elle honnête ?* | Onglet Carburant, pleins, statistiques de consommation |

Le niveau 1 fait déjà économiser et ne demande rien de plus que l'application. Les niveaux 2 et 3 demandent vos pleins ; le niveau 2 devient nettement plus précis avec un adaptateur OBD2 bon marché. C'est vous qui décidez jusqu'où aller — voir Comment fonctionne Sparkilo.

---

## Ce que contient ce guide

**Commencer ici**

| Page | Ce que vous y apprenez |
|---|---|
| Premiers pas | Installation, consentement au premier lancement, pays et langue, mode d'utilisation, première recherche |
| Comment fonctionne Sparkilo | Les concepts derrière tout : profils, modes d'utilisation, une source par pays, où vivent vos données, comment un litre devient un chiffre |

**Trouver du carburant pas cher (niveau 1)**

| Page | Ce que vous y apprenez |
|---|---|
| Trouver des stations | Le bouton Recherche central, les critères, lire une fiche station, le détail, la carte, le radar de stations-service |
| Planification d'itinéraire | Les arrêts les moins chers sur la route, les corridors transfrontaliers, les quatre stratégies |
| Favoris et alertes | Stations enregistrées, alertes de station et de zone, comment la vérification en arrière-plan se comporte vraiment |
| Recharge électrique | Bornes via OpenChargeMap, connecteurs, filtres de puissance |
| Historique et prévisions de prix | L'historique local sur 30 jours, « meilleur moment pour faire le plein » et ce que l'algorithme ne fait délibérément *pas* |

**Consommer moins et savoir ce que ça coûte (niveaux 2 et 3)**

| Page | Ce que vous y apprenez |
|---|---|
| Véhicules et OBD2 | Le modèle de véhicule, la capacité du réservoir, le flex-fuel, l'appairage, le calibrage de la baseline, règles vs flou |
| Carnet de pleins et consommation | Pleins, niveau du réservoir, rapport de plein, niveaux de précision, coût au km par carburant |
| Trajets et éco-coaching | Enregistrement GPS ou OBD2, détail d'un trajet, score de conduite, tableau de bord carbone |

**Référence**

| Page | Ce que vous y apprenez |
|---|---|
| Référence des réglages | Chaque écran de l'arborescence à deux niveaux, avec l'impact opérationnel de chaque interrupteur |
| Confidentialité, données et sync | Consentements, les rubriques Confidentialité et données, TankSync, sauvegarde, vos droits RGPD |
| Dépannage et FAQ | Rien trouvé ? L'adaptateur ne se connecte pas ? Widget figé ? |

---

## Les 17 pays pris en charge

🇩🇪 Allemagne · 🇫🇷 France · 🇦🇹 Autriche · 🇪🇸 Espagne · 🇮🇹 Italie · 🇩🇰 Danemark · 🇵🇹 Portugal · 🇱🇺 Luxembourg · 🇸🇮 Slovénie · 🇬🇧 Royaume-Uni · 🇦🇷 Argentine · 🇦🇺 Australie · 🇲🇽 Mexique · 🇰🇷 Corée du Sud · 🇨🇱 Chili · 🇬🇷 Grèce · 🇷🇴 Roumanie

Chaque pays est servi par **sa propre source publique officielle en open data** — jamais par un agrégateur unique. L'Allemagne exige une clé API gratuite de [tankerkoenig.de](https://creativecommons.tankerkoenig.de/) ; tous les autres pays fonctionnent immédiatement. Pourquoi cela compte pour ce que vous voyez à l'écran : Comment fonctionne Sparkilo.

L'interface est traduite en **23 langues** (bg, cs, da, de, el, en, es, et, fi, fr, hr, hu, it, lt, lv, nb, nl, pl, pt, ro, sk, sl, sv) et suit la langue de votre système.

<a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
  <img alt="Disponible sur Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/fr_badge_web_generic.png" height="80"/>
</a>

---

**Suite :** Premiers pas →

> **À propos des captures d'écran.** Toutes les captures de ce guide viennent d'un appareil faisant tourner l'application en **français**, sur la source de prix française en direct. L'interface est entièrement localisée — vos écrans ont la même disposition avec les mots de votre langue.

---

# Premiers pas

Dix minutes entre l'installation et le premier euro économisé. Si vous ne lisez qu'une autre page ensuite, que ce soit Comment fonctionne Sparkilo.

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

Les deux sont détectés depuis la langue système, et les deux vivent **dans le profil** — voir Comment fonctionne Sparkilo → Profils.

*Réglages → Profils et région → modifier le profil. Le code postal du domicile permet de chercher dans une zone fixe sans jamais céder le GPS.*

Changer de pays **vide les données de stations en cache**, car les prix du fournisseur précédent ne s'appliquent pas au nouveau pays. La recherche suivante prendra donc un instant de plus.

---

## 4. Choisir un mode d'utilisation

C'est le réglage le plus lourd de conséquences, car il décide de la quantité d'application que vous obtenez.

*Réglages → Fonctions et mode d'utilisation. Commencez en **Basique** si vous voulez seulement du carburant moins cher ; montez quand vous voudrez savoir pourquoi votre voiture boit.*

- **Basique** — trouver carburant et recharge, favoris, alertes, itinéraires.
- **Moyen** — ajoute l'onglet **Carburant** : enregistrer vos pleins, voir consommation et coût réels. Aucun matériel nécessaire.
- **Complet** — ajoute l'onglet **Trajets** : enregistrement automatique, scores de conduite, cartes de fidélité. Un adaptateur OBD2 reste facultatif même ici — les trajets s'enregistrent au GPS seul.

Vous pouvez changer à tout moment, et tout interrupteur individuel touché ensuite vous met en **Personnalisé**. La liste complète, et ce que chacun coûte en batterie, données ou vie privée : Référence des réglages → Fonctions et mode d'utilisation.

---

## 5. Allemagne uniquement : la clé API gratuite

16 des 17 pays fonctionnent immédiatement. Le service officiel **allemand** délivre une clé par utilisateur.

*Réglages → Sources de données et position. Une croix rouge ici est la raison pour laquelle une recherche allemande ne renvoie rien.*

1. Ouvrez [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) et demandez une clé (formulaire court, gratuit).
2. Copiez-la — c'est un UUID comme `00000000-0000-0000-0000-000000000002`.
3. Collez-la dans le champ **Prix carburants (Tankerkoenig)**.

La clé est conservée dans le coffre matériel (Android Keystore / Trousseau iOS) et n'est envoyée qu'au service allemand. Le champ **Recharge EV** en dessous contient déjà une clé partagée : les données de recharge fonctionnent sans configuration.

---

## 6. La barre du bas

*Le bouton vert **Recherche** surélevé au centre est le seul déclencheur de recherche de toute l'application.*

- ⭐ **Favoris** — stations enregistrées et alertes de prix
- 🗺️ **Carte** — chaque station proche en épingle colorée par prix
- 🔍 **Recherche** *(au centre)* — à proximité ou le long d'un trajet
- ⛽ **Carburant** — réservoir, consommation, pleins *(à partir de Moyen)*
- 🛣️ **Trajets** — carnet de bord et coaching *(Complet)*

Les réglages **ne sont pas** un onglet : c'est l'engrenage en haut à droite des écrans principaux. Sur tablette, ou téléphone tenu à l'horizontale, l'application se divise en deux colonnes pour voir liste et carte (ou détail) en même temps.

---

## 7. Votre première recherche

*Touchez **Recherche** → la feuille de critères s'ouvre pré-remplie depuis votre profil. Ajustez, puis touchez **Rechercher** à nouveau.*

Vous obtenez une liste triée du moins cher au plus cher (ou par distance — à vous de voir), chaque fiche montrant prix, tendance, distance et fraîcheur. Un appui ouvre le détail complet. La visite guidée : Trouver des stations.

**Astuce :** touchez **Enregistrer comme valeurs par défaut** en bas de la feuille une fois vos critères habituels réglés — toute recherche future partira de là.

---

## 8. Deux réglages à changer dès le premier jour

*Réglages → Unités et affichage. L'**unité de consommation** est *Automatique* par défaut (mpg au Royaume-Uni, L/100 km ailleurs) ; choisissez explicitement L/100 km, km/L ou mpg si vous préférez.*

Le second est **Réglages → Conduite et consommation → Fenêtre de consommation en direct** (3 / 5 / 10 / 30 s). Il pilote le grand chiffre en direct de l'écran d'enregistrement : une fenêtre longue est plus stable à lire en conduisant, une courte réagit plus vite à votre pied droit.

---

## 9. Choisissez sur quoi l'application s'ouvre

**Réglages → Profils et région → Écran d'accueil** : *À proximité* (recherche immédiate avec vos derniers critères), *Station la plus proche*, *Favoris* ou *Carte*. Prenez celui qui correspond à la raison pour laquelle vous ouvrez l'application.

---

## 10. Où tout se trouve

Les réglages sont un arbre à deux niveaux avec une recherche par mot-clé en haut — tapez « rayon », « OBD2 » ou « thème » et la tuile correspondante remonte.

*Douze thèmes, un domicile par paramètre. La carte complète est la Référence des réglages.*

---

**Suite :** Comment fonctionne Sparkilo →

---

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

*Réglages → Profils et région → modifier. Le carburant préféré est **dérivé de votre véhicule par défaut** — retirez le véhicule si vous voulez choisir le carburant vous-même.*

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

*Réglages → Confidentialité et données → Données sur cet appareil montre chaque catégorie avec un compteur réel : rien de vos données ne vous est invisible.*

Seules quatre choses quittent le téléphone, et trois sont facultatives :

| Ce qui sort | Quand | Facultatif ? |
|---|---|---|
| Coordonnées de recherche ou code de région | À chaque recherche, vers la source de prix du pays | Nécessaire aux prix en direct |
| Zone de carte + votre adresse IP | Chargement des tuiles via le proxy UE du développeur | Oui — proxy désactivé, les tuiles viennent directement d'OpenStreetMap |
| Traces de plantage | Uniquement avec *Rapport d'erreurs* activé | Oui — désactivé par défaut |
| Vos lignes synchronisées | Uniquement avec *TankSync* activé | Oui — désactivé par défaut |

**Votre identité ne fait jamais partie d'une requête de prix.** Le décompte complet : Confidentialité, données et sync.

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
- **Si vous roulez sans enregistrer, les comptes ne tomberont pas juste** — et l'application le dit au lieu de bricoler. Voir la réconciliation dans Carnet de pleins et consommation.

---

## Comment l'application apprend votre conduite

Indépendamment du gain pompe, un véhicule porte une **baseline par situation de conduite** : ce que votre voiture consomme au ralenti, en stop & go, en ville, sur autoroute, en décélération, en côte ou chargée, à froid, en charge soutenue et en roue libre.

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

*Chaque paramètre a exactement un domicile. Si vous vous souvenez du thème, vous n'avez jamais à faire défiler.*

Carte complète de tous les écrans : Référence des réglages.

---

**Suite :** Trouver des stations →

---

# Trouver des stations

Niveau 1 des trois niveaux d'économie : payer moins au litre.

---

## Un bouton, un modèle mental

La barre du bas n'a qu'un déclencheur de recherche — le bouton vert surélevé au centre. Il est contextuel plutôt que modal :

- **Depuis n'importe quel onglet** → ouvre la feuille de critères.
- **Depuis les résultats ou la carte** → rouvre la feuille avec vos derniers réglages.
- **Dans la feuille** → lance la recherche.

Son libellé indique ce qu'il va faire, et en mode itinéraire il reste désactivé tant qu'il n'y a pas de destination. Il n'y a délibérément pas de boutons séparés « chercher à proximité » et « chercher le long du trajet ».

---

## Régler les critères

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

### Le bouton de recherche

Le bouton en relief au milieu de la barre du bas est le seul déclencheur
de recherche. Depuis n'importe quel onglet il ouvre cette feuille ;
depuis les résultats ou la carte il la rouvre avec ce que vous avez
utilisé en dernier ; dans la feuille, il lance la recherche.

### À proximité ou le long d'un trajet

Deux questions différentes. **À proximité** cherche autour de votre
position ou d'une adresse. **Le long du trajet** demande une destination
et mesure la distance le long du corridor et non à vol d'oiseau : une
station à 2 km dans une rue latérale passe donc derrière une station sur
votre route.

### Type de carburant

Pour quel carburant sont les prix. Les puces s'adaptent à ce que publie
réellement le fournisseur de votre pays — un carburant absent de la liste
manque dans les données, pas dans l'application.

### Rayon

Jusqu'où chercher. Un grand rayon dans un pays dense renvoie beaucoup de
stations et une recherche plus lente, et les stations en plus sont
généralement plus loin que ce que vaut l'économie.

### Ouvertes maintenant seulement

Masque les stations fermées. Cela dépend du fournisseur qui publie ou non
les horaires, et certains ne le font pas — quand ils manquent, la station
est conservée plutôt que devinée.

### Services

Boutique, lavage, air, WC. Ces filtres portent sur des données
**déclarées** : une station qui ne publie rien sur ses services disparaît
d'une liste filtrée même si elle les a tous.

### Stations d'autoroute

Les stations d'autoroute sont en général le carburant le plus cher du
pays : les exclure est le filtre qui change le plus souvent ce que vous
payez. Gardez-les quand vous ne pouvez pas quitter l'autoroute.

### Enregistrer comme mes valeurs par défaut

Écrit ces critères dans votre profil : chaque recherche suivante part
d'ici plutôt que des valeurs de l'application. C'est le réglage qui fait
de la feuille une confirmation en une touche plutôt qu'un formulaire.

### Comment ça marche réellement

Une recherche à proximité envoie **vos coordonnées (ou un code de région) et un rayon** au fournisseur officiel de votre pays — jamais votre identité. Les pays qui publient un fichier quotidien (Espagne, Italie) sont filtrés sur l'appareil : ces recherches n'ont besoin d'aucun appel réseau une fois le fichier en cache.

---

## Lire une fiche de résultat

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

La fraîcheur est une propriété du **fournisseur du pays**, pas de l'application. Un prix espagnol de 14 heures n'est pas un bug : ce pays publie une fois par jour. Voir Comment fonctionne Sparkilo → Une source par pays.

### Gestes de balayage

- **Balayer à droite** — ouvrir dans votre application de navigation (Google Maps, Waze, OsmAnd, Organic Maps).
- **Balayer à gauche** — masquer la station de tous les résultats futurs. On la ré-affiche depuis **Confidentialité et données → Données sur cet appareil → Stations ignorées**.

---

## Détail d'une station

*Touchez une fiche. L'en-tête retombe de la marque au nom puis à la rue, si bien qu'un Intermarché sans champ marque affiche quand même « Intermarché ».*

Le bloc du haut est le **tableau complet des prix** — toutes les sortes que le fournisseur publie pour cette station, avec `--` là où il n'en publie aucune. C'est le moyen le plus rapide de voir si la station E85 bon marché tient aussi la route au diesel.

**Ajouter un plein** pré-remplit la station, le carburant et le prix dans le formulaire — le plus gros gain de temps de l'application si vous enregistrez vos pleins.

*Plus bas : services, moyens de paiement acceptés, votre note privée en étoiles, et l'historique local des prix sur 30 jours.*

Les actions de la barre supérieure sont, de gauche à droite : **créer une alerte de prix**, **scanner un QR de paiement**, **signaler un prix erroné**, et **mettre en favori**.

---

## La carte

*La couleur est relative à ce qui est à l'écran : vert = la moins chère visible, rouge = la plus chère. Le pied de page indique le nombre de stations, le rayon et l'âge des données.*

- **Les marqueurs de cluster** regroupent les épingles au dézoom ; un appui zoome.
- **Appui long** n'importe où pour poser votre propre marqueur et chercher depuis ce point.
- Le **bouton VE** en haut à droite bascule la carte sur les bornes — voir Recharge électrique.
- **Partager** envoie la vue courante à quelqu'un.

Les tuiles viennent d'OpenStreetMap. Par défaut elles passent par le proxy UE du développeur pour qu'OpenStreetMap ne voie jamais votre IP ; vous pouvez désactiver le proxy dans Réglages → Confidentialité et données et charger en direct. La version F-Droid n'utilise jamais le proxy.

---

## Le radar de stations-service

Un balayage en direct autour de votre position, conçu pour **rouler**.

*Après toute recherche à proximité, une pastille flottante apparaît en bas à droite. Un appui démarre le radar.*

### Comment ça marche réellement

Le radar rafraîchit votre position GPS, récupère les **emplacements** de stations sur un large corridor de 60 km et fusionne une requête directe dans le rayon : il ne peut donc jamais montrer moins qu'une recherche normale. Les stations ne bougent pas, ces emplacements sont donc mis en cache jusqu'à une heure et réutilisés ; seul le **prix** d'une station dont vous approchez est récupéré juste à temps. C'est ce qui rend un radar en fonctionnement continu peu coûteux en données comme en batterie.

*En marche : résultats triés par distance, chacun avec une barre qui se remplit à l'approche.*

### Pendant l'enregistrement d'un trajet

Le radar épingle une fiche **Station la plus proche** en haut de l'écran d'enregistrement — nom, prix pour votre carburant, distance, et une barre qui atteint 100 % à l'arrivée. Balayez à gauche/droite pour parcourir les candidates. En entrant dans le rayon d'approche configuré, la vignette en incrustation bascule sur un grand affichage de prix ; voir Trajets et éco-coaching → L'overlay d'approche.

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

</details>

---

**Voir aussi :** Planification d'itinéraire · Favoris et alertes · Historique des prix
**Suite :** Planification d'itinéraire →

---

# Planification d'itinéraire

Non pas « le moins cher près de moi » mais **le moins cher sur la route** — la différence vaut plusieurs euros sur tout long trajet.

---

## Lancer une recherche d'itinéraire

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

**Il vous faut un profil par pays** avec la bonne sorte préférée, sinon le second tronçon n'a rien à tarifer et affiche `--`. Voir Comment fonctionne Sparkilo → Profils.

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

**Voir aussi :** Trouver des stations · Référence des réglages
**Suite :** Favoris et alertes →

---

# Recharge électrique

Sparkilo n'est pas réservée aux thermiques. Les bornes viennent d'[OpenChargeMap](https://openchargemap.org), le plus grand registre communautaire ouvert au monde.

---

## Activer

Deux interrupteurs indépendants, tous deux sous **Réglages → Fonctions et mode d'utilisation → Recherche et carte** :

- **Recharge VE** — la fonctionnalité elle-même (recherche, pages de détail, favoris).
- **Afficher les bornes de recharge** — si les bornes apparaissent dans les résultats et sur la carte.

*Vous pouvez afficher les stations, les bornes, ou les deux. Un conducteur 100 % électrique désactive en général **Afficher les stations-service**.*

Créez ensuite un véhicule sous **Réglages → Véhicules et OBD2 → Mes véhicules → Ajouter**, en choisissant **Électrique** comme motorisation. Un véhicule électrique porte sa capacité de batterie (kWh), ses puissances de charge AC et DC maximales (kW) et ses connecteurs (Type 2, CCS, CHAdeMO, Tesla, Schuko, Type 1, prise domestique). Les recherches se limitent alors aux bornes que votre voiture peut réellement utiliser.

---

## Comment fonctionnent les données

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

**Voir aussi :** Trouver des stations · Carnet de pleins et consommation
**Suite :** Véhicules et OBD2 →

---

# Favoris et alertes de prix

L'onglet ⭐ est votre sélection, plus les robots qui la surveillent pour vous.

---

## Favoris

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

*Trois compteurs en haut — règles actives, déclenchements aujourd'hui et cette semaine — puis les deux types d'alerte. Le pied de page horodate la dernière vérification en arrière-plan.*

Il y en a deux sortes, qui répondent à des questions différentes.

### Alerte de station — « préviens-moi quand *cette* pompe baisse »

Créée depuis la page détail d'une station (icône cloche). Choisissez le carburant, fixez un seuil, enregistrez. Idéal pour la station que vous utilisez déjà.

### Alerte de zone — « préviens-moi quand *quelque part par ici* baisse »

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
- **Un effet de bord utile :** la même vérification écrit un relevé de prix dans votre historique local. Une station sous alerte construit donc son historique de 30 jours en heures plutôt qu'en semaines — c'est ce qui fait apparaître vite le bandeau *meilleur moment pour faire le plein*. Voir Historique des prix.
- **Si les notifications sont coupées au niveau système**, l'interrupteur de l'application ne peut rien déclencher.

---

## Statistiques

Les compteurs du haut montrent combien de règles sont actives et combien de fois elles se sont déclenchées aujourd'hui et cette semaine — un test rapide pour savoir si la tâche de fond tourne vraiment. Une rangée de zéros avec plusieurs alertes actives et un horodatage « dernière vérification » ancien est le symptôme classique d'un économiseur de batterie qui tue la tâche.

---

## Arrêter les alertes

Désactiver une alerte la met en pause sans perdre la règle ; balayer à gauche la supprime. Retirer la station des favoris ne supprime **pas** ses alertes.

---

**Voir aussi :** Historique et prévisions de prix · Référence des réglages → Prix et alertes
**Suite :** Recharge électrique →

---

# Historique et prévisions de prix

L'application construit une image **privée et locale** de la façon dont les prix bougent autour de vous, et en tire une recommandation honnête.

---

## Ce qui est enregistré, et où

Chaque fois qu'un prix de station passe par l'application — une recherche, un rafraîchissement des favoris ou une vérification d'alerte en arrière-plan — l'application écrit **sur votre téléphone** un relevé : station, carburant, prix, horodatage. Rien n'est envoyé, et les données de personne d'autre ne sont téléchargées.

- **Dédoublonné à un relevé par station et par heure.** Cinq recherches en dix minutes donnent une entrée.
- **Conservé 30 jours.** Les relevés plus anciens sont supprimés automatiquement.
- **Activé par** *Fonctions et mode d'utilisation → Prix et alertes → Historique des prix*. Désactivé, aucun relevé n'est écrit.

*Réglages → Prix et alertes. L'**historique des prix** est le prérequis de la prédiction en dessous — sans historique, elle n'a rien pour travailler.*

---

## Consulter l'historique d'une station

Ouvrez la page détail d'une station et descendez jusqu'à **Historique des prix** :

- **Graphique horaire** — prix moyen pour chaque heure de la journée sur les 30 derniers jours.
- **Graphique par jour de semaine** — moyenne par jour.
- **Min / max / moyenne / tendance** en synthèse.

L'heure ou le jour le moins cher est en vert, le plus cher en rouge.

---

## « Meilleur moment pour faire le plein »

Dès qu'il y a assez d'historique, la station affiche un bandeau :

> 💡 **Les prix baissent généralement le mardi 18:00–20:00** — économisez ~3,2 ct/L

### Ce que c'est — et ce que ce n'est pas

C'est un **résumé de ce qui s'est déjà passé dans cette station sur les 30 derniers jours**, dans *vos* données. Ce n'est délibérément **pas** :

- une prévision du prix de demain,
- une lecture du marché pétrolier, de la fiscalité ou de la météo,
- construit à partir des données d'autres utilisateurs.

Cette retenue est le point. Une majoration régionale du lundi matin est un motif local réel et répétable sur lequel on peut agir ; une prévision de marché faite par un téléphone, non.

### La phase d'apprentissage

Le bandeau reste masqué tant qu'il n'y a pas au moins **10 relevés de prix pour cette station sur 30 jours**. La durée dépend entièrement de la fréquence à laquelle le prix passe par l'application :

| Situation | Délai avant le bandeau |
|---|---|
| La station a une **alerte de prix** | Quelques heures — la vérification de fond relève toutes les 30–60 min |
| La station est un **favori** ouvert quotidiennement | Une dizaine de jours |
| Ni l'un ni l'autre — recherches occasionnelles | Des semaines, voire jamais |

**L'astuce pratique :** posez une alerte sur la station que vous utilisez vraiment. L'alerte est doublement rentable — elle vous prévient d'une baisse et remplit l'historique qui produit la recommandation.

### Pourquoi votre favori n'a-t-il pas de bandeau

1. **Pas encore assez de relevés** (voir ci-dessus).
2. **Le prix n'a presque pas bougé.** Si l'amplitude sur 30 jours est inférieure à 0,1 ct/L, il n'y a rien qui vaille une action, donc rien n'est affiché.
3. **Un seul carburant a des échantillons.** Le seuil s'applique par type de carburant, pas par station.

---

## Prédiction de prix sur l'appareil

*Fonctions et mode d'utilisation → Prix et alertes → **Prédiction de prix TFLite*** active un petit modèle TensorFlow Lite qui tourne **entièrement sur l'appareil**. Ses caractéristiques et ses prédictions ne quittent jamais le téléphone. C'est lui qui alimente la variante *prédictive* du widget d'écran d'accueil (**Réglages → Unités et affichage → Widget d'écran d'accueil → Variante de contenu**), qui affiche le meilleur moment pour faire le plein plutôt que le seul prix actuel.

Si vous préférez qu'on n'infère rien du tout, désactivez-le : l'historique et le bandeau de motif continuent de fonctionner.

---

## Signalements de prix communautaires

*Fonctions et mode d'utilisation → Prix et alertes → **Signalements de prix communautaires*** ajoute une action de signalement sur le détail d'une station, pour corriger un prix que la source officielle a faux. Les signalements partent dans la base TankSync partagée sous votre compte pseudonyme et sont visibles des autres utilisateurs connectés — c'est donc la seule fonction de prix qui **n'est pas** purement locale. Elle nécessite TankSync et reste désactivée tant que vous ne l'activez pas.

---

## Exporter

**Réglages → Confidentialité et données → Exporter ou supprimer → Exporter mes données → CSV** écrit un CSV — sa table d'historique des prix contient station, carburant, prix, horodatage — dans votre dossier Téléchargements public.

---

**Voir aussi :** Favoris et alertes · Trouver des stations → La fraîcheur
**Suite :** Référence des réglages →

---

# Carnet de pleins et consommation

Niveaux 2 et 3 des trois niveaux d'économie : combien vous brûlez, et ce que cela a vraiment coûté. L'onglet ⛽ **Carburant** apparaît en modes **Moyen** et **Complet**.

---

## L'onglet Carburant d'un coup d'œil

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

Après une correction comme celle-ci, attendez-vous à voir les estimations de trajet baisser nettement au prochain trajet, puis se stabiliser. Le mécanisme complet : Comment fonctionne Sparkilo → Comment un litre devient un chiffre.

La carte peut aussi pointer *ce qui a changé* — part de haut régime, événements brusques aux 100 km, démarrages à froid, part de ralenti, chacun comparé au réservoir précédent — avec la réserve explicite que les enregistrements sont spontanés et ne couvrent qu'une partie du réservoir.

---

## Statistiques de consommation

Touchez la carte de statistiques, ou **Carburant → Statistiques de consommation**.

*Les puces du haut limitent tout ce qui suit à un carburant — indispensable sur une flex-fuel, où une moyenne combinée n'a aucun sens.*

Le tableau mensuel montre litres, dépenses, prix moyen au litre, consommation moyenne, coût au km et nombre de pleins, chacun avec son écart. Les flèches rouges ne sont pas un jugement — des *dépenses* en hausse après un *prix au litre* en hausse, c'est le marché, pas votre pied droit. Le chiffre à surveiller pour la conduite est **L/100 km**.

### Coût au kilomètre par carburant

*La vraie question du conducteur flex-fuel, tranchée : non pas quel carburant est moins cher au litre, mais lequel l'est au kilomètre.*

Chaque carburant a une ligne bâtie uniquement sur des **fenêtres de réservoir fermées** : L/100 km mesurés, prix réellement payé au litre, coût aux 100 km, total dépensé, distance mesurée, litres consommés, CO₂ aux 100 km, et le nombre de pleins complets derrière. Une ligne adossée à un seul réservoir est marquée **Provisoire**.

*La carte de verdict annonce le gagnant, l'écart aux 1000 km et — le plus utile — le **seuil de rentabilité**.*

La ligne de seuil (« E5 devient plus avantageux que E85 en dessous de 0,75 €/L ») est calculée à partir de **votre propre consommation mesurée de chaque carburant** : elle bouge donc avec votre conduite. C'est une règle de décision utilisable à la pompe ; un ratio générique trouvé sur Internet ne l'est pas.

Les valeurs CO₂ sont des estimations du puits à la roue (EU JEC WTW v5) appliquées à votre consommation mesurée — de la sensibilisation, pas une comptabilité certifiée. Les mélanges sont exclus du CO₂ car le facteur d'émission dépend du mélange, que la ligne n'enregistre pas.

*Les graphiques de tendance empilent par carburant : un changement apparaît comme une couleur qui en remplace une autre, plutôt que comme un saut mystérieux.*

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

</details>

---

**Voir aussi :** Véhicules et OBD2 · Trajets et éco-coaching
**Suite :** Trajets et éco-coaching →

---

# Carburant, trajets et conduite *(déplacé)*

Cette page a été scindée en trois, pour que chaque sujet ait ses propres ancres en vue d'une aide intégrée :

- **Véhicules et OBD2** — votre voiture, capacité du réservoir, flex-fuel, appairage, calibrage de la baseline, enregistrement automatique.
- **Carnet de pleins et consommation** — pleins, niveau du réservoir, rapport de plein, précision, coût au kilomètre par carburant.
- **Trajets et éco-coaching** — enregistrement, détail d'un trajet, score de conduite, tableau de bord carbone.

Commencez par **Comment fonctionne Sparkilo** si vous voulez les concepts derrière les trois.

---

# Véhicules et OBD2

Tout ce que l'application sait de *votre voiture*. C'est cette page qui décide si les chiffres de consommation de toutes les autres sont dignes de confiance.

---

## Pourquoi l'application a besoin d'un véhicule

Sans véhicule, Sparkilo est un chercheur de prix. Avec, elle peut convertir litres et kilomètres en *votre* coût au kilomètre, estimer l'autonomie et — avec un adaptateur — modéliser le débit de carburant instantané.

*Réglages → Véhicules et OBD2. Notez l'étiquette de portée sur la tuile adaptateur : les adaptateurs s'appairent **par véhicule**, pas par téléphone.*

*La coche verte marque le véhicule actif — celui auquel les nouveaux pleins et trajets sont attribués.*

---

## Identité et motorisation

*Nommez-le comme vous le reconnaîtrez. Le VIN est facultatif.*

### Le VIN, et ce qu'il apporte

Saisir (ou lire) le VIN permet à l'application de retrouver cylindrée, nombre de cylindres, puissance et type de carburant, qui sont les entrées du modèle de consommation. **Lire le VIN depuis la voiture** le récupère en une seconde via OBD2.

Le décodage en ligne du VIN fait l'objet d'un **consentement distinct** — l'application demande avant d'envoyer quoi que ce soit, et le décodage hors ligne partiel fonctionne même si vous refusez. Un VIN est une donnée personnelle ; traitez-le comme tel.

### Motorisation

**Thermique / Hybride / Électrique** change les champs qui suivent. Thermique demande la capacité du réservoir, la puissance et le carburant préféré ; électrique demande la batterie et les connecteurs.

---

## Capacité, puissance et flex-fuel

*La capacité du réservoir est le chiffre le plus porteur de cet écran.*

### Pourquoi la capacité du réservoir compte tant

C'est le dénominateur de la jauge et de l'estimation d'autonomie, et elle borne ce que l'application considère comme un plein plausible. Une capacité fausse produit pendant des mois une autonomie crédible mais erronée. Prenez-la dans le manuel, pas de mémoire — les constructeurs annoncent souvent une capacité utile inférieure de deux litres à la nominale.

### « Je peux faire le plein avec différents carburants »

À activer pour une voiture flex-fuel (E85/E10, ou tout ce que vous alternez vraiment). Deux choses changent :

- Le formulaire de plein **demande à chaque fois quel carburant vous avez réellement mis**, au lieu de supposer le préféré.
- L'écran de statistiques gagne la comparaison **coût au kilomètre par carburant**, la seule façon honnête d'opposer un carburant bon marché mais gourmand à un carburant cher mais sobre.

Laissez-le désactivé si vous mettez toujours la même sorte — ça n'ajoute qu'un champ.

---

## L'adaptateur OBD2

Un adaptateur OBD2 est un petit boîtier Bluetooth branché sur la prise diagnostic de votre voiture (souvent sous le tableau de bord). **Il est totalement facultatif.** Tout fonctionne au GPS seul ; l'adaptateur transforme des estimations en mesures.

### Ce qu'il change

| Sans adaptateur | Avec adaptateur |
|---|---|
| Distance et durée par GPS | Idem, plus les données moteur |
| Consommation **modélisée** depuis votre calibrage | Consommation **mesurée** (ou modélisée bien plus finement) |
| Coaching depuis vitesse et accélération | Coaching depuis régime, accélérateur, charge, rapport |
| Plafond de précision : Moyenne | Plafond de précision : Élevée (±3–7 %) |
| Démarrage manuel du trajet | Enregistrement automatique possible |

### Ce que l'application lit

Vitesse, régime, charge moteur %, position d'accélérateur %, températures de liquide de refroidissement et d'air d'admission, avance à l'allumage, niveau de carburant %, compteur kilométrique (PID standard A6, avec repli sur le PID 31 et le mode 22 constructeur), et le débit de carburant instantané — soit directement par le **PID 5E** là où la voiture le publie, soit dérivé du débitmètre d'air massique.

> **La distinction importante :** si votre voiture répond au PID 5E, votre consommation est *mesurée* et aucun calibrage ne lui est appliqué. Sinon, le chiffre est *modélisé* à partir du débit d'air et des paramètres moteur, et c'est ce modèle que le gain pompe corrige. L'écran du véhicule vous dit dans quel cas vous êtes.

### Adaptateurs pris en charge

16 modèles sont reconnus par leur nom Bluetooth, chacun avec un niveau de compatibilité :

- ✅ **Testé** — confirmé sur matériel réel par le mainteneur.
- 👤 **Vérifié par un utilisateur** — au moins un utilisateur rapporte que ça marche.
- ⚠️ **Théorique** — profil et transport corrects, mais pas encore de vérification de bout en bout.

| Adaptateur | Transport | Notes | Niveau |
|---|---|---|---|
| vLinker FS | BT classique | Modèle dominant en Europe ; recommandé | ✅ |
| vLinker BM-Android | BT classique | Jumeau SPP classique du BM+ | ✅ |
| SmartOBD (BLE) | BLE | Clone ELM327 v1.5 générique | 👤 |
| SmartOBD (Classic) | BT classique | Même marque, variante SPP | 👤 |
| vLinker FD / MC | BLE | Famille Nordic UART FFF0 | ⚠️ |
| OBDLink MX+ | BLE | Haut de gamme Scantool | ⚠️ |
| Carista OBD2 | BLE | Nordic UART FFF0 | ⚠️ |
| Veepeak BLE+ | BLE | Nordic UART FFF0 | ⚠️ |
| ieGeek Scanner | BLE | Clone ELM327 v2.1 BLE | ⚠️ |
| vLinker BM+ | BLE | Jumeau BLE uniquement | ⚠️ |
| Konnwei KW902 | BT classique | Clone ELM327 v1.5 | ⚠️ |
| Vgate iCar Pro | BLE | Variante BLE seulement | ⚠️ |
| Panlong WiFi | — | WiFi seulement, listé pour nommer les mauvais appairages | ⚠️ |
| BAFX 34t5 | BT classique | Ancien ELM327 v1.5 | ⚠️ |
| Generic ELM327 (BLE) | BLE | Profil fourre-tout pour clones BLE FFF0 | ⚠️ |
| Generic ELM327 (Classic) | BT classique | Profil fourre-tout pour clones SPP | ⚠️ |

Les adaptateurs absents retombent sur le profil ELM327 générique et fonctionnent le plus souvent. Si le vôtre marche — ou non — [ouvrez un ticket](https://github.com/fdittgen-png/tankstellen/issues) pour corriger le niveau.

### Appairer

1. Contact **mis** (moteur tournant convient, contact coupé non).
2. Branchez l'adaptateur ; sa LED doit être fixe.
3. Ouvrez le véhicule et touchez la section adaptateur, ou démarrez un trajet.
4. Accordez **Recherche Bluetooth** et **Connexion Bluetooth** (Android 12+). Jusqu'à Android 11, le système exige à la place la **position** pour scanner en Bluetooth — une règle du système, pas un choix de traçage.
5. Attendez environ 8 secondes le balayage et touchez votre adaptateur. L'application lance la poignée de main ELM327 et confirme.

Une fois appairé, l'adaptateur appartient à ce véhicule. **Réinitialiser la connexion** relance la poignée de main sans oublier l'appareil — la première chose à essayer après une coupure en route. **Oublier l'adaptateur** efface entièrement l'appairage.

---

## Calibrage de la baseline — apprendre votre voiture à l'application

*210 échantillons sur 270. Deux situations de conduite sont encore vides, et l'application le dit plutôt que de feindre la complétude.*

Chaque échantillon OBD2 est rangé dans une situation de conduite : **ralenti, stop & go, urbain, autoroute, décélération, côte / chargé, démarrage à froid, charge soutenue / remorquage, roue libre**. Les moyennes par situation forment la baseline du véhicule — le modèle qui produit un L/100 km plausible quand l'adaptateur est absent ou qu'un PID cesse de répondre.

*Les situations à zéro échantillon sont celles qui retomberont sur des valeurs par défaut. Ici deux : décélération et remorquage.*

### Basé sur les règles ou flou

*Le mode flou est le défaut, et le meilleur choix pour presque tout le monde.*

- **Basé sur les règles** attribue chaque échantillon à exactement une situation. Prévisible, mais il bascule d'un échantillon à l'autre entre « urbain » et « autoroute » quand vous roulez près de la frontière — vers 60 km/h par exemple.
- **Flou** répartit chaque échantillon sur toutes les situations selon son degré d'appartenance. Lisse précisément là où le mode règles saute, au prix d'être plus difficile à suivre échantillon par échantillon.

### Les boutons de réinitialisation — et ce qu'ils font vraiment

- **Réinitialiser le rendement volumétrique** jette le η_v appris et rétablit la valeur par défaut 0,85. η_v est un paramètre du modèle speed-density qui estime le débit d'air en l'absence de débitmètre. Ne le réinitialisez qu'après une intervention mécanique ; un chiffre qui semble bizarre relève plus souvent d'un problème de couverture. Les voitures qui publient le débit directement (PID 5E) ne l'utilisent pas du tout.
- **Réinitialiser depuis la base de véhicules** recharge cylindrée, puissance et valeurs par défaut du catalogue intégré, en écartant vos saisies manuelles.
- **Réinitialiser la baseline par situation** (dans la carte de baseline) efface chaque échantillon appris et vous ramène aux valeurs de départ à froid jusqu'à ce que de nouveaux trajets remplissent le profil.

Aucun de ces boutons ne touche au **gain pompe**, appris à partir des fenêtres de plein à plein et vivant en dehors du modèle OBD2 — voir Comment fonctionne Sparkilo → Comment un litre devient un chiffre.

---

## Rappels d'entretien

En bas de l'éditeur de véhicule : des préréglages pour **vidange (15 000 km)**, **pneus (20 000 km)** et **contrôle technique (30 000 km)**, plus des rappels personnalisés. Ils comptent sur les relevés kilométriques que vous saisissez avec vos pleins : ils n'avancent donc que si vous notez le compteur — ce dont le calibrage a de toute façon besoin. Une habitude, deux bénéfices.

---

## Enregistrement automatique

Avec un adaptateur appairé, l'enregistrement peut se passer entièrement de vous :

- **Appairage automatique** — le premier appairage manuel crée l'association adaptateur ↔ véhicule.
- **Connexion automatique** — dès que le système voit l'adaptateur appairé émettre, l'application se reconnecte en arrière-plan.
- **Démarrage automatique** — connecté et au-dessus du seuil de vitesse, le trajet commence.
- **Enregistrement automatique à l'arrêt** — l'adaptateur perd son alimentation avec le contact, et après le délai configuré le trajet est finalisé et sauvegardé.

L'enregistrement automatique exige l'autorisation de position **« Toujours autoriser »**, car Android ne laisse un service d'arrière-plan diffuser du GPS qu'avec elle. Cette autorisation ne sert qu'à cela ; la recherche et le centrage de carte utilisent l'autorisation de premier plan ordinaire.

> **Note de plateforme.** L'enregistrement automatique est vérifié sur **Android**. Sur iOS, le réveil système nécessaire au « se connecter dès que l'adaptateur s'allume » n'existe pas encore ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)) ; les utilisateurs iOS démarrent les trajets à la main.

Les seuils (vitesse de départ, délai de sauvegarde après déconnexion) vivent dans l'éditeur de véhicule : une voiture d'appoint peut donc se déclencher autrement qu'une voiture de trajet quotidien.

---

<details>
<summary>Vue d'ensemble — éditeur de véhicule, page entière</summary>

</details>

---

**Voir aussi :** Trajets et éco-coaching · Dépannage → OBD2
**Suite :** Carnet de pleins et consommation →

---

# Trajets et éco-coaching

L'onglet 🛣️ **Trajets** est un carnet de bord automatique doublé d'un coach de conduite. Il apparaît en mode **Complet**.

---

## L'onglet Trajets

*Totaux du mois, le dernier rapport de plein, puis la liste des trajets. Le bouton flottant démarre un enregistrement.*

La comparaison mensuelle exige au moins trois trajets par mois avant de comparer — en dessous, la moyenne est du bruit, pas une tendance.

*L'icône carte de la barre supérieure dessine tous vos trajets enregistrés sur une carte — une année de conduite d'un coup d'œil, et un moyen simple de repérer les routes qui méritent d'être optimisées.*

---

## Deux façons d'enregistrer

### Avec le téléphone seul

Aucun matériel. L'application relève route, distance, durée et vitesse par GPS, et **modélise** la consommation depuis le calibrage de votre véhicule et votre conduite. Signalée partout par un `~` et une mention explicite « estimation GPS ».

La précision démarre mauvaise et s'améliore : chaque fenêtre de plein fermée ré-ancre le modèle sur la pompe, si bien qu'après une poignée de pleins complets un trajet GPS tombe généralement à quelques pour cent près. D'ici là, c'est étiqueté préliminaire, pas maquillé.

### Avec un adaptateur OBD2

Des données moteur au lieu d'une déduction : débit réel (mesuré là où la voiture publie le PID 5E), régime, charge, accélérateur. Aucune période d'apprentissage pour la consommation, et le coaching accède à des signaux que le GPS ne voit pas — rapport, régime, charge moteur. La mise en place est dans Véhicules et OBD2.

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

*Le résumé annonce sa propre provenance — véhicule, adaptateur, et un badge **Trace GPS** sur la distance pour savoir d'où viennent les kilomètres.*

*La route est colorée par efficacité — vert sous 6 L/100 km, orange jusqu'à 10, rouge au-delà. Où est passé le carburant, géographiquement.*

Cette coloration est la vue la plus actionnable de l'application : elle place sur une carte les portions coûteuses de votre trajet quotidien. Une portion rouge qui revient tous les jours, c'est un carrefour, une côte ou une habitude qu'il vaut la peine de changer.

*Trois blocs : votre propre verdict, l'attribution du carburant, et comment vous avez réellement sollicité le moteur.*

- **« Comment s'est passé ce trajet ? »** — *Souple / Modéré / Agressif*. Votre réponse sert à calibrer les seuils de style de conduite sur de vrais trajets, pas à vous noter.
- **Où est passé votre carburant** — litres attribués aux accélérations fortes contre la conduite normale. Chiffres absolus petits sur un trajet court ; c'est le rapport qui compte.
- **Position d'accélérateur** et **régime moteur** en distributions — la part du trajet passée en roue libre, en charge légère, ferme et pleins gaz, et dans chaque plage de régime. Une part élevée au-dessus de 3000 tr/min sur un trajet domicile-travail signifie que vous montez les rapports trop tard, et ça coûte cher.

*Deux diagnostics : la complétude de la trace GPS et le comportement de l'adaptateur.*

*Dépliée, la carte OBD2 s'explique en clair.*

**Lisez cette carte avant de douter d'un chiffre de consommation.** Elle indique combien de mesures portaient des données moteur, la **couverture en pourcentage** qui en résulte, l'adaptateur et le protocole négocié, la durée de la session, pourquoi elle s'est terminée (`userStopped`, une déconnexion, une mort du processus), et la ligne décisive : *« Les valeurs de consommation viennent de l'adaptateur, pas d'estimations GPS. »* Si la couverture est nettement sous 100 %, les trous ont été comblés par des estimations GPS et la moyenne du trajet est un mélange.

*Vitesse, débit et régime sur un axe de temps commun — les trois courbes qui expliquent n'importe quel chiffre de consommation.*

*Charge moteur et accélérateur côte à côte montrent la différence entre faire travailler le moteur et simplement le faire monter en régime.*

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

*Réglages → Conduite et consommation. Les succès et les scores peuvent être masqués dans toute l'application si la gamification n'est pas pour vous.*

---

## Le tableau de bord carbone

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

</details>

---

**Voir aussi :** Véhicules et OBD2 · Carnet de pleins et consommation
**Suite :** Historique et prévisions de prix →

---

# Confidentialité, données et synchronisation

Les promesses de confidentialité de Sparkilo sont vérifiables, et c'est sur cette page qu'on les vérifie.

---

## La confidentialité par défaut

Concrètement :

- **Pas de Google Play Services. Pas de Firebase. Pas de Google Analytics. Pas d'identifiants publicitaires.**
- **Aucun SDK de traçage tiers** — le `pubspec.yaml` public ne contient aucune dépendance d'analytique.
- **Aucun compte requis.** L'application est pleinement fonctionnelle sans.
- **Local-first.** Tout reste sur votre téléphone tant que vous n'activez rien.
- **Consentement avant traitement**, plus une explication en langage clair *avant* chaque demande système.
- **Open source, MIT.** Les propres tests du projet échouent si la politique de confidentialité et le code divergent.

### Ce qui quitte réellement le téléphone

| Donnée | Vers qui | Quand | Évitable ? |
|---|---|---|---|
| Coordonnées de recherche ou code de région | Le fournisseur officiel de votre pays | À chaque recherche en direct | Chercher par code postal plutôt qu'au GPS |
| Zone de carte + IP | Le proxy de tuiles UE du développeur, qui récupère chez OpenStreetMap | Usage de la carte | Désactiver le proxy — OpenStreetMap voit alors votre IP directement |
| Votre IP | logo.clearbit.com | Uniquement si vous activez les logos en ligne | Laisser désactivé (défaut) |
| Traces de plantage expurgées | Sentry | Uniquement avec *Rapports d'erreurs* activé | Désactivé par défaut |
| Vos lignes synchronisées | La base TankSync que vous avez choisie | Uniquement avec TankSync activé | Désactivé par défaut |

**Votre identité ne fait jamais partie d'une requête de prix**, et le développeur n'exploite aucun serveur qui stocke vos recherches.

---

## Qui est responsable de traitement

Cela dépend entièrement de votre usage de TankSync :

| Mode | Responsable |
|---|---|
| **Sans TankSync** *(défaut)* | **Vous seul.** Rien ne réside sur un serveur exploité par le développeur |
| **Votre projet Supabase** | **Vous** — le développeur ne le voit jamais |
| **La base d'un groupe** | **Le propriétaire du groupe** qui exploite ce projet |
| **Sparkilo Community** | **Le développeur, Florian DITTGEN** ([fdittgen@gmail.com](mailto:fdittgen@gmail.com)) ; Supabase, Inc. est sous-traitant ; hébergement dans l'UE (AWS eu-central-1, Francfort) |

L'application indique le cas qui s'applique **avant** la connexion, puis à nouveau sur la ligne *Mode de synchronisation* de **Synchronisation et compte**.

---

## L'écran Confidentialité et données

**Réglages → Confidentialité et données** est le point d'entrée unique. Il s'ouvre sur une carte de synthèse suivie de quatre tuiles thématiques :

| Ligne ou tuile | Ce qu'elle vous dit |
|---|---|
| *Vos données restent sur cet appareil* / *Vos données sont aussi synchronisées sur TankSync* | Où vos données vivent physiquement en ce moment |
| *Synchronisation : désactivée* / *Synchronisation : activée · compte anonyme* / *Synchronisation : activée · compte e-mail* | Si TankSync est connecté, et avec quel type de compte |
| *… stockés sur cet appareil* | Le stockage total que l'application utilise actuellement |
| **Vos choix** — *n sur 5 activés* | Les cinq consentements et les deux contrôles réseau |
| **Données sur cet appareil** — *taille · n catégories* | Chaque catégorie conservée localement, avec taille et compteur |
| **Synchronisation et compte** | État de TankSync, compte, base de données et actions de synchronisation |
| **Exporter ou supprimer** — *ZIP, JSON, CSV · journal d'erreurs (n)* | Les exports, le journal d'erreurs et la zone dangereuse |

L'ancien *Tableau de bord Confidentialité* n'existe plus : ses compteurs, ses informations de synchronisation, ses exports et son bouton de suppression vivent désormais sous ces quatre thèmes. Les anciens liens et widgets d'écran d'accueil qui pointaient vers le tableau de bord ouvrent **Confidentialité et données** à la place.

---

## Vos choix

*Les deux contrôles liés au réseau, chacun formulé pour ce qu'il divulgue réellement. Les cinq consentements sont au-dessus, sur la même carte.*

Chaque ligne est un interrupteur — *« Vous pouvez modifier vos choix de confidentialité à tout moment. »*

| Ligne | Ce qu'elle décide |
|---|---|
| **Accès à la localisation** | Trouver les stations-service à proximité grâce à votre localisation. Désactivé : chercher par code postal |
| **Rapports d'erreurs** | Envoyer des rapports de plantage anonymes pour améliorer l'application. Désactivé par défaut — rien n'est jamais envoyé sans |
| **Synchronisation cloud** | Synchroniser les favoris et alertes entre appareils — le consentement derrière TankSync |
| **Décodage VIN en ligne** | Décoder le VIN via le service public gratuit de la NHTSA. Désactivé : saisir les données du véhicule vous-même |
| **Synchroniser les trajets enregistrés** | Sauvegarder les trajets OBD2 + GPS dans TankSync. Grisé tant que *Synchronisation cloud* est désactivée |
| **Charger les tuiles de carte via le proxy Sparkilo** | Activé : la zone de carte affichée et votre adresse IP parviennent au serveur UE du développeur, qui récupère les tuiles auprès d'OpenStreetMap. Désactivé : les tuiles sont chargées directement depuis tile.openstreetmap.org, qui voit alors votre IP |
| **Charger les logos des marques depuis Internet** | Désactivé par défaut : des logos génériques intégrés sont affichés. Activé : les logos sont récupérés depuis logo.clearbit.com, qui voit votre adresse IP |

Les deux contrôles réseau portent un bouton d'information (*En savoir plus*) avec l'explication complète. Le pied de carte note *Consentement donné le … · version … de la politique* — la piste d'audit exigée par le RGPD — et renvoie vers la **Politique de confidentialité** dans votre langue. Retirer un consentement arrête immédiatement le traitement correspondant ; les traitements antérieurs restent licites.

---

## Données sur cet appareil

*Le stockage, détaillé : une barre par catégorie, puis une ligne par catégorie avec sa taille, son compteur et un point à la couleur de la barre. Les catégories vides sont grisées, pas masquées.*

Les lignes sous **Utilisation du stockage sur cet appareil** : **Favoris** · **Notes des stations** · **Profils de recherche** · **Alertes de prix** · **Stations avec historique des prix** · **Stations ignorées** · **Utilisateurs bloqués** · **Itinéraires enregistrés** · **Cache** · **Paramètres** (*Clé API, profil actif*) · **Total**.

Tout réside dans des **bases Hive chiffrées** ; la clé est dans l'Android Keystore / le Trousseau iOS.

| Boîte | Contenu |
|---|---|
| `settings` | Configuration, pays, langue, unités |
| `profiles` | Vos profils de recherche |
| `favorites` | Stations enregistrées avec toutes leurs données |
| `cache` | Réponses d'API et itinéraires en cache |
| `priceHistory` | Les relevés de prix locaux sur 30 jours |
| `price_snapshots` | Instantanés pour l'usage hors ligne et le widget |
| `alerts` | Vos règles d'alerte |
| `service_reminders` | Rappels d'entretien |
| `obd2Baselines` | Baselines de consommation par véhicule |
| `obd2TripHistory` | Trajets : route, vitesse, capteurs |
| `obd2_supported_pids` / `obd2_negotiated_protocol` | Caches des capacités de l'adaptateur |

Les clés API, le jeton GitHub et la session TankSync vivent dans le coffre matériel, pas dans Hive.

### Détails du cache

*La tuile **Détails du cache** se déplie sur la durée de vie de chaque classe en cache — recherches 5 min, détails station 15 min, requêtes de prix 5 min, données favoris 30 min, recherches de ville 30 min, géocodage de code postal 24 h — et sur le bouton **Vider le cache**.*

Le cache stocke les réponses API pour un chargement plus rapide et l'accès hors ligne. Le vider supprime uniquement les résultats et prix en cache — profils, favoris et réglages sont conservés ; les recherches suivantes sont plus lentes, rien n'est perdu. Le bouton affiche *Le cache est vide* et reste inactif quand il n'y a rien à vider.

### Utilisateurs bloqués

**Utilisateurs bloqués** est la seule ligne tactile : elle ouvre la liste des comptes que vous avez bloqués, chacun avec un bouton **Débloquer**. Le contenu partagé par ces utilisateurs est masqué sur cet appareil ; le blocage est local — il ne signale pas le compte.

---

## Autorisations

| Autorisation | Pourquoi | Refusable ? |
|---|---|---|
| **Position** *(pendant l'utilisation)* | Recherche à proximité, départ d'itinéraire, enregistrement | Oui — utiliser un code postal |
| **Position** *(« Toujours autoriser »)* | **Uniquement** l'enregistrement automatique OBD2, pour que la route continue écran éteint | Oui — démarrer les trajets à la main |
| **Recherche + connexion Bluetooth** | Appairage de l'adaptateur | Oui — l'OBD2 est facultatif |
| **Notifications** | Alertes de prix | Oui — les alertes ne partiront pas |
| **Caméra** | OCR sur appareil des pompes, tickets et QR | Oui — saisir à la main |
| **Internet** | Appels de prix et de carte | Requis |

Jusqu'à Android 11, le système exige la **position** pour tout balayage Bluetooth — une règle de plateforme, pas un choix de traçage. Toute autorisation se révoque ensuite dans les réglages système ; la fonction concernée s'arrête simplement.

---

## Synchronisation et compte

*Accessible depuis la tuile Confidentialité et données et directement depuis la racine des Réglages. L'écran fait aussi remonter les problèmes — ici un schéma auto-hébergé obsolète qui, de ce fait, échoue silencieusement à synchroniser certaines tables.*

Sur activation. *Désactivée* signifie que rien n'est stocké sur aucun serveur, nulle part. La carte de synthèse en haut énonce les faits :

| Ligne | Valeur |
|---|---|
| **État** | *Connectée* ou *Désactivée* |
| **Mode de synchronisation** | *Sparkilo Community — serveur UE du développeur* · *Groupe partagé — une base de données que vous avez rejointe* · *Auto-hébergé — votre propre Supabase* |
| **Compte** | *Compte anonyme, lié à cet appareil* ou *Compte e-mail : …* |
| **Identifiant utilisateur** | Votre UUID, avec un bouton de copie — citez-le dans une demande d'assistance |
| **Hôte de la base de données** | Le nom d'hôte de la base vers laquelle vous synchronisez ; la clé n'est jamais affichée |
| **Partager les profils de véhicules appris** | Téléverser les baselines de consommation par véhicule pour qu'un second appareil puisse les réutiliser |

### Trois formes de déploiement

1. **Sparkilo Community** — la base partagée exploitée par le développeur (Supabase, UE/Francfort). Votre compte est un UUID aléatoire ; vous pouvez lier une adresse e-mail pour y accéder depuis un autre appareil. Les signalements communautaires et les notes partagées publiquement sont lisibles par tout utilisateur connecté.
2. **Votre projet Supabase** — le schéma SQL et les Edge Functions sont dans le dépôt. Vous êtes responsable de traitement et gardez la pleine propriété.
3. **La base d'un groupe** — connectez-vous au projet de proches. Cette personne est responsable de traitement.

### Mise en place

**Synchronisation et compte → Configurer la synchronisation cloud.** Pour Community, scannez le QR du wiki ou collez l'URL et la clé anon ; pour un projet propre ou de groupe, collez l'URL du projet et la clé anon. Les deux sont conservées dans le coffre matériel, et les points d'accès en HTTP simple sont refusés d'emblée.

> **Auto-hébergeurs :** après une mise à jour, l'écran peut avertir que votre **schéma est obsolète**. Rejouez le SQL d'installation proposé — sinon la synchronisation des nouvelles tables échoue **en silence**, ce qui est bien pire qu'une erreur visible.

### Actions une fois connecté

- **Passer à l'e-mail** — conserver les données, se connecter depuis d'autres appareils ; l'UUID reste le même. **Passer en anonyme** fait l'inverse.
- **Consentements** — un renvoi vers *Vos choix* : les consentements Synchronisation cloud et trajets se trouvent là-bas, pas ici.
- **Voir mes données** — l'écran *Transparence des données* liste les lignes que le serveur détient pour vous ; son bouton **Oublier tous les trajets synchronisés** ne nettoie que les lignes de trajets.
- **Lier un appareil** — amener un second téléphone sur le même compte.
- **Supprimer les données synchronisées** — choisissez *Trajets*, *Véhicules*, *Pleins* ou *Tout* à retirer de la base de synchronisation ; les copies locales restent.
- **Partager la base de données** — un QR pour que des proches rejoignent votre propre base ou celle d'un groupe (non proposé sur Community).
- **Déconnecter** — arrêter la synchronisation ; les données locales sont conservées.
- **Supprimer le compte** — supprimer définitivement toutes les données serveur, puis l'identité du compte elle-même, e-mail lié compris. Proposé pour votre propre base et celle d'un groupe ; sur Community, utilisez *Supprimer les données synchronisées → Tout* ou la zone dangereuse décrite plus bas.

### Ce qui se synchronise

Favoris · alertes de prix · stations ignorées · notes (avec un indicateur de confidentialité par note : locale / privée synchronisée / partagée publiquement) · itinéraires · véhicules VIN et identifiant d'adaptateur compris · pleins et journaux de recharge · baselines de consommation · signalements communautaires et de contenu que vous soumettez.

**Les trajets sont à part.** Leur synchronisation reste facultative *même après* l'activation de la Synchronisation cloud — l'interrupteur *Synchroniser les trajets enregistrés* reste grisé jusque-là. Côté serveur, les résumés de trajet restent jusqu'à suppression ; les échantillons GPS détaillés sont purgés après 90 jours.

Chaque table est protégée par sécurité au niveau ligne : un compte ne peut lire ou supprimer que ses propres lignes. Les notes partagées et les signalements communautaires sont les seules lignes visibles des autres utilisateurs connectés.

### Conflits

**Le local gagne toujours.** La synchronisation ajoute et met à jour, mais ne supprime jamais en silence — seule votre suppression explicite déclenche une suppression serveur, qui se propage ensuite à vos autres appareils.

---

## Exporter ou supprimer

Un bouton, une feuille de format, une zone rouge. **Exporter mes données** ouvre *Choisir un format* :

| Format | Indication dans la feuille | Ce que vous obtenez |
|---|---|---|
| **Archive ZIP** | *Tout, y compris les pièces jointes — pour une sauvegarde complète* | `sparkilo-my-data-<date>.zip` : un JSON lisible par machine par catégorie — favoris, alertes, profils, itinéraires, historique des prix, véhicules, pleins, trajets avec échantillons GPS et un GPX par trajet, baselines, rappels d'entretien, journaux de recharge, succès et votre trace de consentement — plus chaque table serveur si TankSync est connecté |
| **JSON** | *Lisible par machine — pour un autre logiciel* | `tankstellen-data.json` : les catégories de l'appareil en un fichier à plat, également copié dans le presse-papiers |
| **CSV** | *Tableur — une table par catégorie* | `tankstellen-data.csv` : un bloc `# table` par catégorie — favoris, alertes, historique des prix et le reste — également copié dans le presse-papiers |

Tous les exports atterrissent dans le dossier **Téléchargements public** (*Enregistré dans le dossier Téléchargements*), pour que n'importe quel gestionnaire de fichiers les trouve.

**Journal d'erreurs** indique combien de traces expurgées l'application détient (*Aucune entrée* … *n entrées*). **Enregistrer** les écrit dans les Téléchargements pour un rapport de bug — sans e-mails, coordonnées, clés ni jetons, et rien n'est jamais envoyé automatiquement ; **Effacer** vide le journal.

**Zone dangereuse** — *Supprime définitivement tout ce que l'application stocke sur cet appareil. Avec la synchronisation activée, vos données sur le serveur TankSync sont aussi effacées.* **Supprimer toutes mes données** demande confirmation et liste ce qui disparaît : favoris et données de stations, profils de recherche, alertes de prix, historique des prix, données en cache, votre clé API, tous les paramètres de l'application. Avec TankSync connecté, l'application efface d'abord vos lignes serveur ; si une table n'a pas pu être effacée, elle **vous dit laquelle** au lieu de proclamer le succès. L'application revient ensuite à la configuration de premier lancement. Irréversible.

Pour un instantané restaurable plutôt qu'un export de données, voyez **Réglages → Sauvegarde et restauration** — voir Référence des réglages.

---

## Vos droits au titre du RGPD

Chaque droit des articles 15 à 22 a un bouton. Aucune demande d'assistance nécessaire.

- **Accès** — *Données sur cet appareil* liste chaque catégorie sur l'appareil ; *Voir mes données* liste chaque ligne de votre base TankSync.
- **Portabilité** — *Exporter mes données* en archive ZIP.
- **Rectification** — modifiez n'importe quelle entrée sur place ; la modification se synchronise si TankSync est actif.
- **Effacement**
  - *Appareil :* **Exporter ou supprimer → Supprimer toutes mes données**.
  - *Serveur :* **Synchronisation et compte → Supprimer le compte** efface chaque ligne vous appartenant **en une transaction** — favoris, alertes, stations ignorées, signalements de prix et de contenu, véhicules, pleins, itinéraires, baselines, notes, trajets, partages de trajets donnés et reçus, réglages de synchronisation, traces de suppression et votre ligne utilisateur — puis l'identité du compte elle-même, e-mail lié compris. Si une table n'a pas pu être effacée, l'application **vous dit laquelle** au lieu de proclamer le succès.
  - *Éléments isolés :* tout est supprimable individuellement ; **Supprimer les données synchronisées** retire trajets, véhicules ou pleins du serveur, et **Oublier tous les trajets synchronisés** ne nettoie que les lignes de trajets.
- **Retrait du consentement** — Confidentialité et données → Vos choix ; le traitement cesse immédiatement.
- **Limitation / opposition** — désactivez TankSync, la synchronisation des trajets, le proxy de tuiles ou les diagnostics ; révoquez les autorisations dans les réglages système.
- **Réclamation** — auprès d'une autorité de contrôle, notamment celle de votre résidence, de votre lieu de travail ou du lieu de la violation supposée. Le développeur apprécierait de pouvoir corriger d'abord : [fdittgen@gmail.com](mailto:fdittgen@gmail.com).

Si vous ne pouvez plus ouvrir l'application, demandez la suppression par e-mail depuis l'adresse liée au compte. **Un compte anonyme jamais lié à un e-mail ne peut être identifié par personne — y compris le développeur — sans l'appareil qui l'a créé.** C'est le prix de ne pas vous demander de vous inscrire.

Texte intégral : **[Politique de confidentialité v3, 29 août 2026](https://fdittgen-png.github.io/tankstellen/privacy-policy/fr/)**, disponible dans les 23 langues de l'application ([Deutsch](https://fdittgen-png.github.io/tankstellen/privacy-policy/de/), [English](https://fdittgen-png.github.io/tankstellen/privacy-policy/), …). L'application retient la version à laquelle vous avez consenti et la réaffiche à chaque changement.

---

**Voir aussi :** Référence des réglages · Comment fonctionne Sparkilo → Où vivent vos données
**Suite :** Dépannage et FAQ →

---

# Référence des réglages

Chaque écran de l'arborescence des réglages et — plus utile — **ce que chaque interrupteur vous coûte** en batterie, données, précision ou vie privée.

---

## La forme de l'ensemble

Les réglages sont un **arbre à deux niveaux** : une racine de tuiles thématiques, un écran par thème, et une recherche par mot-clé sur l'ensemble.

*Tapez « rayon », « OBD2 » ou « thème » dans le champ de recherche et la tuile correspondante remonte — inutile de retenir quel thème possède un paramètre.*

*Douze thèmes au total. Pour y accéder : l'engrenage en haut à droite des écrans principaux.*

Trois règles de conception rendent l'arbre prévisible :

1. **Un domicile par paramètre.** Rien n'apparaît deux fois ; les renvois pointent vers l'unique propriétaire.
2. **Étiquettes de portée.** Une tuile marquée *ce profil*, *tous les profils* ou *ce véhicule* vous dit d'avance jusqu'où va une modification.
3. **États vides honnêtes.** Une section dont la fonction est éteinte le dit et pointe vers l'interrupteur, au lieu de se cacher.

---

## Profils et région

*Pays, langue, carburant, rayon de recherche, itinéraires · portée : ce profil*

*Le carburant préféré est dérivé du véhicule par défaut. Pour le choisir directement, retirez le véhicule du profil.*

| Réglage | Impact |
|---|---|
| **Nom du profil** | Cosmétique, mais c'est ce qu'affiche la puce de profil |
| **Carburant préféré** | Le prix en une sur chaque fiche ; le défaut des alertes ; ce que la recherche d'itinéraire optimise |
| **Rayon par défaut** | Plus grand = plus de résultats et recherches plus lentes |

*Valeurs par défaut de l'itinéraire. **Candidates par point d'échantillonnage** échange de la minutie contre de la vitesse sur les longs corridors.*

*Trois choses distinctes à connaître.*

- **Éviter les autoroutes** change l'itinéraire calculé lui-même : les aires d'autoroute ne sont alors plus candidates du tout — en général une économie, puisque le carburant d'autoroute est le plus cher de tout corridor.
- **Notes des stations** — *Local* (cet appareil seulement), *Privé* (synchronisé sur votre compte) ou *Partagé* (visible des autres utilisateurs). C'est un choix de confidentialité, pas de stockage.
- **Écran d'accueil** — ce sur quoi l'application s'ouvre : À proximité, Station la plus proche, Favoris ou Carte.

*Le rayon de l'overlay et la règle **la plus proche vs la moins chère du rayon** vivent dans le profil : un profil « trajet quotidien » et un profil « vacances » peuvent donc se comporter différemment.*

*Le pays décide du fournisseur de données. En changer vide les données de stations en cache.*

*Un **code postal de domicile** permet des recherches de zone sans aucun GPS — la façon la plus propre d'utiliser l'application si vous ne voulez jamais partager votre position.*

---

## Véhicules et OBD2

*Vos voitures, capacité du réservoir, appairage · portée : ce véhicule*

*Les adaptateurs s'appairent par véhicule : la tuile adaptateur vous envoie donc dans un véhicule plutôt que sur un écran d'appairage global.*

Le traitement complet — VIN, capacité, flex-fuel, modes de calibration, baseline, seuils d'enregistrement automatique, rappels d'entretien — est dans Véhicules et OBD2.

---

## Conduite et consommation

*Coaching, récompenses, radar, dépannage · portée : mixte*

*Les deux premières entrées sont celles que vous ajusterez vraiment.*

| Réglage | Impact |
|---|---|
| **Fenêtre de consommation en direct** (3/5/10/30 s) | Plus longue = plus stable et plus lisible en conduisant ; plus courte = assez réactive pour apprendre ce que coûte la pédale |
| **Overlay à l'approche d'une station** | Rayon, mode de prix, plancher d'interrogation et épinglage d'écran pour le profil actif |
| **Coaching éco en temps réel** | Vibration légère + conseil à l'écran en accélération forte à vitesse de croisière |
| **Coaching vocal de conduite** | Le même conseil lu à voix haute — les yeux restent sur la route |
| **Glide-coach bêta** | Retour haptique avant un feu rouge à partir des feux OpenStreetMap. **Désactivé par défaut — risque de distraction**, et il lui faut du réseau |

*Récompenses et dépannage.*

- **Cartes de fidélité** — remises au litre appliquées dans les comparaisons de prix, si bien qu'une station nominalement plus chère peut à juste titre se classer moins chère pour vous.
- **Afficher les succès et scores** — désactivé, tous les badges, scores et trophées disparaissent de l'application. Rien ne cesse d'être mesuré ; c'est l'affichage qui s'arrête.
- **Journalisation de débogage OBD2** — enregistre chaque session (connexion, poignée de main, pertes de données, reconnexions) dans un journal XML exportable. **Désactivée par défaut** : elle écrit en continu et ne vaut la peine que pendant la chasse à un problème d'adaptateur.

---

## Prix et alertes

*Alertes, annonces vocales, historique, signalements communautaires*

*Le bloc grisé des annonces vocales est un état vide honnête : il nomme les deux interrupteurs nécessaires et où ils se trouvent.*

| Réglage | Impact |
|---|---|
| **Alertes de prix** | Ouvre la liste ; la fonctionnalité elle-même est un interrupteur sous Fonctions et mode d'utilisation |
| **Historique des prix** | Enregistrement local sur 30 jours. Désactivé = pas de graphiques, pas de « meilleur moment » |
| **Prédiction de prix TFLite** | Modèle sur l'appareil ; caractéristiques et prédictions ne quittent jamais le téléphone |
| **Signalements de prix communautaires** | Nécessite TankSync ; vos signalements sont visibles des autres utilisateurs connectés |
| **Scanner le QR de paiement** | Ajoute le lecteur de QR au détail des stations |

---

## Unités et affichage

*Thème, unité de distance, unité de consommation, widget · portée : mixte*

*L'**unité de consommation** se propage partout d'un coup — bandeau en direct, vignette en incrustation, moyennes de trajet, statistiques, widget.*

- **Unité de distance** suit par défaut le pays du profil actif (km ou miles).
- **Unité de consommation** : *Automatique* (mpg au Royaume-Uni et aux États-Unis, L/100 km ailleurs), ou explicitement L/100 km, km/L ou mpg.

*Les choix de widget portent l'étiquette **ce profil** et s'appliquent à tous les widgets installés affichant ce profil, à la prochaine actualisation.*

**Variante de contenu** — *prix actuel uniquement*, ou *prédictif : meilleur moment pour faire le plein* (nécessite la prédiction TFLite).

---

## Fonctions et mode d'utilisation

*Préréglages et chaque interrupteur individuel*

*Choisir un préréglage **écrase** chaque interrupteur individuel. Si vous avez un réglage à la main, restez en Personnalisé.*

Les dépendances sont appliquées, pas cachées : un interrupteur dont le prérequis est éteint reste désactivé et nomme ce prérequis.

*Recherche et carte — y compris le fait que les stations et les bornes apparaissent ou non.*

*Prix et alertes. L'historique est la fonction parente de la prédiction qui le suit.*

*Le radar, ses annonces vocales et l'interrupteur principal **Retour vocal** — désactivé, l'application n'ouvre jamais de moteur de synthèse.*

*Le sélecteur **Désactivé / Carburant / Carburant + Trajets** est la forme compacte de toute la pile consommation.*

| Interrupteur | Impact |
|---|---|
| **Analyse de consommation** | L'onglet d'analyse des pleins et trajets |
| **Gamification** | Scores de conduite et badges gagnés |
| **Éco-coach haptique** | Retour vibratoire en temps réel pendant la conduite |
| **Glide-coach** | Conseils éco depuis les feux OpenStreetMap — nécessite du réseau |
| **Trace GPS des trajets** | Conserve les points de route de chaque trajet. Désactivé = base plus petite, pas de cartes de trajet |
| **Enregistrement automatique** | Démarre un trajet quand l'adaptateur appairé se connecte à un véhicule en mouvement |

*Deux interrupteurs ici changent la qualité des données plutôt que l'interface.*

- **PID OEM expérimentaux** — lit le niveau exact du réservoir en litres via des PID constructeur sur adaptateurs compatibles. Meilleures données de réservoir là où ça marche ; sans effet ailleurs.
- **Exiger OBD2 pour l'enregistrement des trajets** — **désactivé**, les trajets s'enregistrent au GPS seul. Le coaching est réduit (pas de L/100 km instantanée, moins de signaux moteur) mais rien n'est bloqué.
- **Synchronisation des références** — téléverse les baselines de consommation par véhicule pour qu'un second appareil les réutilise. Nécessite TankSync.

*Saisie et scan. La reconnaissance est sur l'appareil ; ces interrupteurs décident seulement de l'existence des raccourcis.*

*Développeur et expérimental — à laisser désactivé sauf si vous signalez des bugs.*

---

## Sources de données et position

*Clés API, GPS, changement automatique de profil*

*Une croix rouge sur la clé de prix carburants est la raison habituelle d'une recherche allemande vide.*

| Réglage | Impact |
|---|---|
| **Prix carburants (Tankerkoenig)** | Nécessaire pour l'Allemagne seulement. Gratuite, par utilisateur, dans le coffre matériel |
| **Recharge EV (OpenChargeMap)** | Facultative — remplace la clé partagée par votre propre quota |
| **Mise à jour automatique** | Rafraîchit la position GPS avant chaque recherche. Désactivé = recherches plus rapides, position peut-être obsolète |
| **Changement automatique de profil** | Bascule le profil au passage d'une frontière, pour que fournisseur et carburant soient corrects automatiquement |

---

## Synchronisation et compte

*Cet écran fait aussi remonter les problèmes — ici un schéma TankSync auto-hébergé obsolète qui, de ce fait, échoue silencieusement à synchroniser certaines tables.*

Traité en détail dans Confidentialité, données et sync → TankSync. L'essentiel :

- **Sparkilo Community / votre propre base / la base d'un groupe** — trois formes de déploiement avec trois responsables de traitement différents.
- **Anonyme → e-mail** — *Passer à l'e-mail* conserve vos données et votre compte et ajoute un moyen de vous connecter depuis un autre appareil. Un compte anonyme n'existe que sur l'appareil qui l'a créé.
- **Schéma obsolète** — après une mise à jour, les auto-hébergeurs doivent rejouer le SQL d'installation, sinon les nouvelles tables échouent en silence.

---

## Confidentialité et données

*Deux choix de confidentialité liés au réseau, chacun formulé pour ce qu'il divulgue réellement.*

- **Charger les tuiles via le proxy Sparkilo** — *activé* : le serveur UE du développeur voit la zone de carte et votre IP et récupère les tuiles pour vous. *Désactivé* : les tuiles viennent de tile.openstreetmap.org, qui voit alors votre IP. Aucune option ne signifie « pas de réseau » ; vous choisissez par qui être vu. La version F-Droid n'utilise jamais le proxy.
- **Charger les logos des marques depuis Internet** — *désactivé* par défaut ; des logos génériques embarqués sont utilisés. Activé, ils viennent de logo.clearbit.com, qui voit votre IP.

*Le stockage, détaillé. Le cache est presque toujours la plus grosse part et la seule qu'on peut jeter sans risque.*

*Gestion du cache, avec la durée de vie de chaque classe : recherches 5 min, détails station 15 min, requêtes de prix 5 min, données favoris 30 min, recherches de ville 30 min, géocodage de code postal 24 h.*

*Vider le cache supprime uniquement les résultats et prix en cache — profils, favoris et réglages sont conservés. Les recherches suivantes seront plus lentes ; rien n'est perdu.*

---

## Sauvegarde et restauration

*Un ZIP complet avec véhicules, pleins, trajets et journaux de recharge.*

**Exporter la sauvegarde** écrit le ZIP dans vos Téléchargements. **Restaurer la sauvegarde** propose *fusionner* ou *remplacer* — fusionner conserve ce qui est sur l'appareil et ajoute ce qui manque ; remplacer efface d'abord. À utiliser avant un changement de téléphone ou une réinitialisation. TankSync n'est pas une sauvegarde : il réplique des catégories choisies, pas tout.

---

## Avancé et développeur

*Le jeton GitHub est facultatif — sans lui, un retour de scan raté se partage manuellement au lieu d'ouvrir un ticket automatiquement.*

L'entrée **Outils de développement** n'apparaît qu'avec le mode développeur activé (Fonctions et mode d'utilisation → Développeur et expérimental).

*Pour un utilisateur ordinaire, le journal d'erreurs est la partie utile : **Enregistrer le journal d'erreurs** écrit des traces expurgées dans les Téléchargements, à joindre à un rapport de bug.*

*La trace de démarrage est une cascade des phases d'initialisation — c'est ainsi qu'un lancement lent se diagnostique au lieu de se deviner.*

***Tester l'overlay d'approche** pousse un état synthétique pendant 30 s pour vérifier l'affichage de prix en incrustation sans aller rouler.*

---

## À propos

***Version et numéro de build** — citez les deux dans tout rapport de bug, et vérifiez-les d'abord quand un correctif « n'a pas marché » (le déploiement du store ne vous a peut-être pas encore atteint).*

*L'application est gratuite, open source et sans publicité. Les attributions des données de prix et de carte figurent en bas, comme les licences l'exigent.*

---

**Voir aussi :** Comment fonctionne Sparkilo · Confidentialité, données et sync
**Suite :** Confidentialité, données et sync →

---

# Dépannage et FAQ

Classé approximativement par fréquence réelle.

---

## Avant tout : vérifiez votre version

*Réglages → À propos. Citez **les deux** dans tout rapport.*

Une grande part des « ça ne marche toujours pas » vient d'un déploiement de store qui n'a pas encore atteint l'appareil. Si le numéro de build est antérieur à la version contenant le correctif, il n'y a rien à déboguer.

---

## « Aucun prix trouvé »

1. **Vérifiez le pays dans votre profil.** Un profil allemand appelle l'API allemande ; en France il ne trouvera rien. Réglages → Profils et région → Région.
2. **Allemagne : la clé API est-elle définie ?** Réglages → Sources de données et position — une croix rouge sur *Prix carburants (Tankerkoenig)* est la réponse.
3. **Êtes-vous hors ligne ?** Les prix en direct exigent un appel réseau. Les prix en cache restent affichés, marqués obsolètes.
4. **Panne du fournisseur.** Les services publics d'open data tombent parfois. Réessayez dans quelques minutes.
5. **Cache obsolète.** Tirez pour actualiser, ou touchez l'icône d'actualisation.

---

## Allemagne : « Clé API manquante » ou « Clé invalide »

- Obtenez une clé gratuite sur [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/) ; c'est un UUID.
- Collez-la dans **Réglages → Sources de données et position → Prix carburants (Tankerkoenig)**.
- Toujours en échec ? La clé peut être limitée en débit. Les clés sont personnelles — ne les publiez jamais.

---

## Je ne trouve pas le bouton de recherche

Il n'y en a qu'un : le bouton vert surélevé au milieu de la barre du bas. Depuis n'importe quel onglet il ouvre la feuille de critères ; dans la feuille, un second appui lance la recherche. S'il paraît grisé, vous êtes en **mode itinéraire sans destination**.

---

## La position est « inconnue » ou le GPS n'accroche pas

- La localisation système doit être activée, avec **Pendant l'utilisation** accordé à l'application.
- Le GPS n'accroche pas à l'intérieur. Sortez, ou définissez un **code postal de domicile** dans le profil et cherchez par zone.
- « Position approximative seulement » — activez la position précise dans les autorisations système.

---

## Le calcul d'itinéraire est lent ou échoue

- OSRM est un service public gratuit et parfois lent.
- Un corridor multi-pays **diffuse des résultats partiels** ; le bandeau nomme les fournisseurs encore attendus, et vous pouvez toucher un résultat avant l'arrivée des autres.
- Réessayez — la polyligne est mise en cache, la seconde tentative est en général immédiate.

---

## L'adaptateur OBD2 ne se connecte pas

**Rien n'est trouvé au balayage**

- Le contact doit être **mis** (accessoires ou marche). Moteur tournant convient, contact coupé non.
- La LED de l'adaptateur doit être allumée fixe. Clignotante ou éteinte → rebranchez.
- Bluetooth activé sur le téléphone.
- Android 12+ : accordez **Recherche Bluetooth** et **Connexion Bluetooth**.
- Jusqu'à Android 11 : le système exige la **position** pour énumérer les appareils Bluetooth. Règle de plateforme, pas de traçage.

**Trouvé, mais la connexion échoue**

- *« Ne répond pas »* — clone bas de gamme. Attendez 30 s et réessayez ; démarrer brièvement le moteur aide souvent.
- *« Échec d'initialisation du protocole »* — puce ELM327 contrefaite. Essayez un autre modèle ; le vLinker FS est l'option bon marché fiable.
- *« Autorisation refusée »* — ré-accordez dans les réglages système ; certains Android oublient les droits Bluetooth après un redémarrage.

**Se connecte puis lâche en route**

Utilisez **Réinitialiser la connexion** dans la carte adaptateur du véhicule — elle relance la poignée de main sans oublier l'appairage. Si cela persiste, activez **Réglages → Conduite et consommation → Journalisation de débogage OBD2**, faites un trajet, exportez le journal XML et joignez-le à un ticket. Désactivez ensuite la journalisation.

**Le compteur affiche 0 ou une valeur fausse**

Votre voiture ne publie peut-être pas le PID A6. L'application réessaie avec le PID 31 et le mode 22 constructeur. Certaines européennes d'avant 2008 ne publient aucun compteur en OBD2 — saisissez-le alors à chaque plein.

---

## L'enregistrement automatique ne s'est pas déclenché

Il lui faut tout ceci :

1. Un adaptateur **appairé à un véhicule**.
2. **Enregistrement automatique** activé pour ce véhicule.
3. L'autorisation de position **« Toujours autoriser »**.
4. Bluetooth activé, et aucune optimisation de batterie qui tue l'application.

Vérifiez aussi le **seuil de vitesse de départ** dans l'éditeur de véhicule — une sortie de parking au pas peut ne jamais l'atteindre.

> **iOS :** le réveil système nécessaire au « se connecter dès que l'adaptateur s'allume » n'existe pas encore ([#1542](https://github.com/fdittgen-png/tankstellen/issues/1542)). Sur iOS, démarrez les trajets à la main.

---

## Ma consommation semble fausse

Procédez dans cet ordre :

1. **Ouvrez le trajet et lisez la carte de santé de la communication OBD2.** Si la couverture est nettement sous 100 %, les trous ont été comblés par des estimations GPS et la moyenne du trajet est un mélange, pas une mesure.
2. **Regardez le rapport de plein dans l'onglet Trajets.** S'il indique que les estimations sont *n* % au-dessus ou en dessous de la vérité de la pompe, l'application le sait déjà et vient de se corriger — attendez-vous à un mouvement sur les prochains trajets.
3. **Vérifiez la capacité du réservoir** sur le véhicule. Une capacité fausse produit des autonomies crédibles mais erronées pendant des mois.
4. **Vérifiez vos relevés de compteur.** La consommation, c'est litres ÷ kilomètres, et les kilomètres viennent entièrement de votre saisie.
5. **Vérifiez que vous avez coché « Plein complet ».** Seules les fenêtres plein à plein peuvent calibrer quoi que ce soit.
6. **Regardez le badge de précision** dans l'onglet Carburant. *Faible* signifie que rien n'a encore ancré le modèle — le chiffre est une sortie de modèle, et il le dit.

Contexte : Comment fonctionne Sparkilo → Comment un litre devient un chiffre.

---

## « Nous avons trouvé un écart de X litres »

Vous avez versé plus que vos trajets enregistrés ne l'expliquent. Répondez aux deux questions de la réconciliation : un plein manquant ou mal saisi reçoit une **entrée de correction**, un trajet non enregistré reçoit un **trajet virtuel**. Les deux restent modifiables. Laisser l'écart en suspens biaise le calibrage, deux appuis valent donc la peine. Voir Carnet de pleins et consommation.

---

## La vignette en incrustation n'affiche pas de prix

L'overlay d'approche ne se déclenche que pendant **l'enregistrement d'un trajet** *et* dans le rayon d'approche. Pour vérifier l'affichage sans rouler : **Réglages → Outils de développement → Tester l'overlay d'approche** pousse un état synthétique pendant 30 secondes.

---

## Les notifications d'alerte n'arrivent pas

- Les notifications système sont-elles autorisées pour l'application ?
- Économiseur de batterie : les modes agressifs d'Android tuent le travail de fond. Passez l'application en **non restreinte**.
- Le téléphone était peut-être hors ligne au créneau prévu ; la vérification reprendra au prochain créneau réseau.
- Le prix n'a peut-être tout simplement pas franchi le seuil.
- L'horodatage **Dernière vérification** en bas de l'écran des alertes dit si la tâche tourne. Horodatage ancien + zéro déclenchement = le système la tue.

---

## Le widget d'écran d'accueil est figé

- Android limite les actualisations de widget à environ une toutes les 30 minutes ; c'est une règle système.
- Touchez l'**icône d'actualisation sur le widget** — elle recharge les prix sans ouvrir l'application.
- L'apparence et la variante de contenu se règlent par profil sous **Réglages → Unités et affichage**.

---

## La carte affiche des tuiles grises ou vides

- Le plus souvent une connexion faible ; balayez pour rafraîchir.
- Si cela persiste, les serveurs de tuiles limitent peut-être le débit — réessayez dans quelques minutes.
- Essayez de basculer **Réglages → Confidentialité et données → Charger les tuiles via le proxy Sparkilo** ; les deux chemins échouent indépendamment.

---

## Le scan de pompe ou de ticket ne lit rien

- La version **F-Droid** n'a aucun scan — la reconnaissance de texte sur appareil n'existe que dans les versions Play / App Store. Saisissez le plein à la main.
- Le reflet sur l'afficheur de pompe est la cause la plus fréquente. Faites de l'ombre, placez-vous bien en face, remplissez le cadre avec les chiffres.
- S'il lit les libellés mais pas les chiffres, utilisez **Signaler une erreur de scan** pour que le recadrage serve à améliorer la reconnaissance.

---

## L'application met longtemps à démarrer

Activez **Trace d'initialisation au démarrage** (Fonctions et mode d'utilisation → Développeur et expérimental), redémarrez, puis ouvrez les **Outils de développement**. La cascade nomme la phase lente ; exportez-la et joignez-la à un ticket.

*Chaque barre est une phase d'initialisation avec sa durée — un démarrage lent cesse d'être une supposition.*

---

## L'application plante au lancement

- Videz le cache depuis les réglages d'application de l'appareil.
- Si cela persiste, ouvrez un ticket avec la version d'Android, le modèle du téléphone, la version **et le numéro de build** de Réglages → À propos, et le journal d'erreurs enregistré (l'application le propose au lancement suivant ; le fichier va dans les Téléchargements).

---

## Comment sauvegarder mes données ?

**Réglages → Sauvegarde et restauration → Exporter la sauvegarde** écrit un ZIP dans les Téléchargements ; la restauration propose fusionner ou remplacer. Pour un export de données lisible par machine, utilisez plutôt **Confidentialité et données → Exporter ou supprimer → Exporter mes données → Archive ZIP**.

TankSync n'est **pas** une sauvegarde — il réplique des catégories choisies, et les trajets seulement si vous avez aussi activé leur synchronisation.

---

## Comment tout supprimer ?

- **Appareil :** Confidentialité et données → Exporter ou supprimer → **Supprimer toutes mes données**. Irréversible.
- **Serveur (TankSync) :** supprimez d'abord le côté serveur — Synchronisation et compte → Transparence des données → **Supprimer le compte** retire chaque ligne vous appartenant en une transaction et nomme toute table qui n'a pas pu être effacée.

Détails : Confidentialité, données et sync → Vos droits.

---

## Puis-je utiliser l'application hors ligne ?

En partie. Les favoris affichent leurs derniers prix connus, les tuiles récemment consultées sont en cache, et pleins comme trajets sont entièrement locaux. Découvrir de nouvelles stations exige un appel réseau.

---

## Où est passé l'onglet Carburant ou Trajets ?

Ils appartiennent aux modes **Moyen** et **Complet**. Si l'un a disparu, un préréglage ou un interrupteur l'a désactivé : Réglages → Fonctions et mode d'utilisation → Conso.

---

## Plus d'aide

- **Bugs :** [github.com/fdittgen-png/tankstellen/issues](https://github.com/fdittgen-png/tankstellen/issues) — utilisez le modèle Bug Report et joignez le journal d'erreurs enregistré.
- **Idées :** le modèle Feature Request, ou d'abord les [Discussions](https://github.com/fdittgen-png/tankstellen/discussions).
- **Questions de confidentialité :** la [politique de confidentialité](https://fdittgen-png.github.io/tankstellen/privacy-policy/fr/), ou fdittgen@gmail.com.

---

**Retour à :** l'accueil du guide
