# Référence des réglages

Chaque écran de l'arborescence des réglages et — plus utile — **ce que chaque interrupteur vous coûte** en batterie, données, précision ou vie privée.

---

## La forme de l'ensemble

Les réglages sont un **arbre à deux niveaux** : une racine de tuiles thématiques, un écran par thème, et une recherche par mot-clé sur l'ensemble.

<img src="guide/settings-root-1.jpg" width="340" alt="Racine des réglages, moitié haute : champ de recherche et les six premières tuiles">

*Tapez « rayon », « OBD2 » ou « thème » dans le champ de recherche et la tuile correspondante remonte — inutile de retenir quel thème possède un paramètre.*

<img src="guide/settings-root-2.jpg" width="340" alt="Racine des réglages, moitié basse : fonctions, sources de données, synchronisation, confidentialité, sauvegarde, avancé">

*Douze thèmes au total. Pour y accéder : l'engrenage en haut à droite des écrans principaux.*

Trois règles de conception rendent l'arbre prévisible :

1. **Un domicile par paramètre.** Rien n'apparaît deux fois ; les renvois pointent vers l'unique propriétaire.
2. **Étiquettes de portée.** Une tuile marquée *ce profil*, *tous les profils* ou *ce véhicule* vous dit d'avance jusqu'où va une modification.
3. **États vides honnêtes.** Une section dont la fonction est éteinte le dit et pointe vers l'interrupteur, au lieu de se cacher.

---

## Profils et région

*Pays, langue, carburant, rayon de recherche, itinéraires · portée : ce profil*

<img src="guide/profile-edit-1.jpg" width="340" alt="Éditeur de profil : nom, carburant préféré, rayon par défaut">

*Le carburant préféré est dérivé du véhicule par défaut. Pour le choisir directement, retirez le véhicule du profil.*

| Réglage | Impact |
|---|---|
| **Nom du profil** | Cosmétique, mais c'est ce qu'affiche la puce de profil |
| **Carburant préféré** | Le prix en une sur chaque fiche ; le défaut des alertes ; ce que la recherche d'itinéraire optimise |
| **Rayon par défaut** | Plus grand = plus de résultats et recherches plus lentes |

<img src="guide/profile-edit-2.jpg" width="340" alt="Planification d'itinéraire : segment, détour maximal, économie minimale, choix par segment, candidates">

*Valeurs par défaut de l'itinéraire. **Candidates par point d'échantillonnage** échange de la minutie contre de la vitesse sur les longs corridors.*

<img src="guide/profile-edit-3.jpg" width="340" alt="Affichage et stations, visibilité des notes, écran d'accueil, rayon de l'overlay d'approche">

*Trois choses distinctes à connaître.*

- **Éviter les autoroutes** change l'itinéraire calculé lui-même : les aires d'autoroute ne sont alors plus candidates du tout — en général une économie, puisque le carburant d'autoroute est le plus cher de tout corridor.
- **Notes des stations** — *Local* (cet appareil seulement), *Privé* (synchronisé sur votre compte) ou *Partagé* (visible des autres utilisateurs). C'est un choix de confidentialité, pas de stockage.
- **Écran d'accueil** — ce sur quoi l'application s'ouvre : À proximité, Station la plus proche, Favoris ou Carte.

<img src="guide/profile-edit-4.jpg" width="340" alt="Rayon et mode de prix de l'overlay d'approche, véhicule par défaut, région">

*Le rayon de l'overlay et la règle **la plus proche vs la moins chère du rayon** vivent dans le profil : un profil « trajet quotidien » et un profil « vacances » peuvent donc se comporter différemment.*

<img src="guide/profile-edit-5.jpg" width="340" alt="Région : puces de pays et de langue">

*Le pays décide du fournisseur de données. En changer vide les données de stations en cache.*

<img src="guide/profile-edit-6.jpg" width="340" alt="Puces de langue et champ du code postal du domicile">

*Un **code postal de domicile** permet des recherches de zone sans aucun GPS — la façon la plus propre d'utiliser l'application si vous ne voulez jamais partager votre position.*

---

## Véhicules et OBD2

*Vos voitures, capacité du réservoir, appairage · portée : ce véhicule*

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Écran Véhicules et OBD2">

*Les adaptateurs s'appairent par véhicule : la tuile adaptateur vous envoie donc dans un véhicule plutôt que sur un écran d'appairage global.*

Le traitement complet — VIN, capacité, flex-fuel, modes de calibration, baseline, seuils d'enregistrement automatique, rappels d'entretien — est dans [Véhicules et OBD2](User-fr-Vehicles-And-OBD2).

---

## Conduite et consommation

*Coaching, récompenses, radar, dépannage · portée : mixte*

<img src="guide/driving-and-consumption-1.jpg" width="340" alt="Fenêtre de consommation en direct, overlay d'approche, mes véhicules, interrupteurs de coaching">

*Les deux premières entrées sont celles que vous ajusterez vraiment.*

| Réglage | Impact |
|---|---|
| **Fenêtre de consommation en direct** (3/5/10/30 s) | Plus longue = plus stable et plus lisible en conduisant ; plus courte = assez réactive pour apprendre ce que coûte la pédale |
| **Overlay à l'approche d'une station** | Rayon, mode de prix, plancher d'interrogation et épinglage d'écran pour le profil actif |
| **Coaching éco en temps réel** | Vibration légère + conseil à l'écran en accélération forte à vitesse de croisière |
| **Coaching vocal de conduite** | Le même conseil lu à voix haute — les yeux restent sur la route |
| **Glide-coach bêta** | Retour haptique avant un feu rouge à partir des feux OpenStreetMap. **Désactivé par défaut — risque de distraction**, et il lui faut du réseau |

<img src="guide/driving-and-consumption-2.jpg" width="340" alt="Coaching, cartes de fidélité, succès, journalisation de débogage OBD2">

*Récompenses et dépannage.*

- **Cartes de fidélité** — remises au litre appliquées dans les comparaisons de prix, si bien qu'une station nominalement plus chère peut à juste titre se classer moins chère pour vous.
- **Afficher les succès et scores** — désactivé, tous les badges, scores et trophées disparaissent de l'application. Rien ne cesse d'être mesuré ; c'est l'affichage qui s'arrête.
- **Journalisation de débogage OBD2** — enregistre chaque session (connexion, poignée de main, pertes de données, reconnexions) dans un journal XML exportable. **Désactivée par défaut** : elle écrit en continu et ne vaut la peine que pendant la chasse à un problème d'adaptateur.

---

## Prix et alertes

*Alertes, annonces vocales, historique, signalements communautaires*

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Prix et alertes : entrée alertes, note sur les annonces vocales, fonctions de prix">

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

<img src="guide/units-and-display-1.jpg" width="340" alt="Thème, unité de distance et unité de consommation">

*L'**unité de consommation** se propage partout d'un coup — bandeau en direct, vignette en incrustation, moyennes de trajet, statistiques, widget.*

- **Unité de distance** suit par défaut le pays du profil actif (km ou miles).
- **Unité de consommation** : *Automatique* (mpg au Royaume-Uni et aux États-Unis, L/100 km ailleurs), ou explicitement L/100 km, km/L ou mpg.

<img src="guide/units-and-display-2.jpg" width="340" alt="Widget d'écran d'accueil : schéma de couleurs et variante de contenu">

*Les choix de widget portent l'étiquette **ce profil** et s'appliquent à tous les widgets installés affichant ce profil, à la prochaine actualisation.*

**Variante de contenu** — *prix actuel uniquement*, ou *prédictif : meilleur moment pour faire le plein* (nécessite la prédiction TFLite).

---

## Fonctions et mode d'utilisation

*Préréglages et chaque interrupteur individuel*

<img src="guide/features-and-mode-1.jpg" width="340" alt="Préréglages Basique, Moyen, Complet et l'état Personnalisé">

*Choisir un préréglage **écrase** chaque interrupteur individuel. Si vous avez un réglage à la main, restez en Personnalisé.*

Les dépendances sont appliquées, pas cachées : un interrupteur dont le prérequis est éteint reste désactivé et nomme ce prérequis.

<img src="guide/features-and-mode-2.jpg" width="340" alt="Groupe Recherche et carte : itinéraires, recharge VE, afficher stations, afficher bornes, calculateur">

*Recherche et carte — y compris le fait que les stations et les bornes apparaissent ou non.*

<img src="guide/features-and-mode-3.jpg" width="340" alt="Groupe Prix et alertes : alertes, historique, prédiction TFLite, QR de paiement, signalements">

*Prix et alertes. L'historique est la fonction parente de la prédiction qui le suit.*

<img src="guide/features-and-mode-4.jpg" width="340" alt="Groupe Radar de stations-service avec annonces vocales et l'interrupteur principal de synthèse vocale">

*Le radar, ses annonces vocales et l'interrupteur principal **Retour vocal** — désactivé, l'application n'ouvre jamais de moteur de synthèse.*

<img src="guide/features-and-mode-5.jpg" width="340" alt="Groupe Conso : sélecteur de mode plus analyse, gamification, éco-coach haptique, glide-coach, trace GPS, enregistrement automatique">

*Le sélecteur **Désactivé / Carburant / Carburant + Trajets** est la forme compacte de toute la pile consommation.*

| Interrupteur | Impact |
|---|---|
| **Analyse de consommation** | L'onglet d'analyse des pleins et trajets |
| **Gamification** | Scores de conduite et badges gagnés |
| **Éco-coach haptique** | Retour vibratoire en temps réel pendant la conduite |
| **Glide-coach** | Conseils éco depuis les feux OpenStreetMap — nécessite du réseau |
| **Trace GPS des trajets** | Conserve les points de route de chaque trajet. Désactivé = base plus petite, pas de cartes de trajet |
| **Enregistrement automatique** | Démarre un trajet quand l'adaptateur appairé se connecte à un véhicule en mouvement |

<img src="guide/features-and-mode-6.jpg" width="340" alt="PID OEM expérimentaux, exiger OBD2, tableau de bord carbone, TankSync, synchronisation des références">

*Deux interrupteurs ici changent la qualité des données plutôt que l'interface.*

- **PID OEM expérimentaux** — lit le niveau exact du réservoir en litres via des PID constructeur sur adaptateurs compatibles. Meilleures données de réservoir là où ça marche ; sans effet ailleurs.
- **Exiger OBD2 pour l'enregistrement des trajets** — **désactivé**, les trajets s'enregistrent au GPS seul. Le coaching est réduit (pas de L/100 km instantanée, moins de signaux moteur) mais rien n'est bloqué.
- **Synchronisation des références** — téléverse les baselines de consommation par véhicule pour qu'un second appareil les réutilise. Nécessite TankSync.

<img src="guide/features-and-mode-7.jpg" width="340" alt="Saisie et scan : cartes de fidélité, OCR de ticket, partager un ticket pour l'importer">

*Saisie et scan. La reconnaissance est sur l'appareil ; ces interrupteurs décident seulement de l'existence des raccourcis.*

<img src="guide/features-and-mode-8.jpg" width="340" alt="Développeur et expérimental : retour via PAT GitHub, mode développeur, trace de démarrage">

*Développeur et expérimental — à laisser désactivé sauf si vous signalez des bugs.*

---

## Sources de données et position

*Clés API, GPS, changement automatique de profil*

<img src="guide/data-sources-location.jpg" width="340" alt="Champs de clés API et bloc de localisation">

*Une croix rouge sur la clé de prix carburants est la raison habituelle d'une recherche allemande vide.*

| Réglage | Impact |
|---|---|
| **Prix carburants (Tankerkoenig)** | Nécessaire pour l'Allemagne seulement. Gratuite, par utilisateur, dans le coffre matériel |
| **Recharge EV (OpenChargeMap)** | Facultative — remplace la clé partagée par votre propre quota |
| **Mise à jour automatique** | Rafraîchit la position GPS avant chaque recherche. Désactivé = recherches plus rapides, position peut-être obsolète |
| **Changement automatique de profil** | Bascule le profil au passage d'une frontière, pour que fournisseur et carburant soient corrects automatiquement |

---

## Synchronisation et compte

<img src="guide/sync-and-account.jpg" width="340" alt="État TankSync, avertissement de schéma obsolète, passer à l'e-mail, consentements, voir mes données">

*Cet écran fait aussi remonter les problèmes — ici un schéma TankSync auto-hébergé obsolète qui, de ce fait, échoue silencieusement à synchroniser certaines tables.*

Traité en détail dans [Confidentialité, données et sync → TankSync](User-fr-Privacy-Profiles-Sync#tanksync-synchronisation-cloud-facultative). L'essentiel :

- **Sparkilo Community / votre propre base / la base d'un groupe** — trois formes de déploiement avec trois responsables de traitement différents.
- **Anonyme → e-mail** — *Passer à l'e-mail* conserve vos données et votre compte et ajoute un moyen de vous connecter depuis un autre appareil. Un compte anonyme n'existe que sur l'appareil qui l'a créé.
- **Schéma obsolète** — après une mise à jour, les auto-hébergeurs doivent rejouer le SQL d'installation, sinon les nouvelles tables échouent en silence.

---

## Confidentialité et données

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Contrôles de confidentialité : proxy de tuiles et chargement des logos de marque">

*Deux choix de confidentialité liés au réseau, chacun formulé pour ce qu'il divulgue réellement.*

- **Charger les tuiles via le proxy Sparkilo** — *activé* : le serveur UE du développeur voit la zone de carte et votre IP et récupère les tuiles pour vous. *Désactivé* : les tuiles viennent de tile.openstreetmap.org, qui voit alors votre IP. Aucune option ne signifie « pas de réseau » ; vous choisissez par qui être vu. La version F-Droid n'utilise jamais le proxy.
- **Charger les logos des marques depuis Internet** — *désactivé* par défaut ; des logos génériques embarqués sont utilisés. Activé, ils viennent de logo.clearbit.com, qui voit votre IP.

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Utilisation du stockage détaillée par catégorie avec les tailles">

*Le stockage, détaillé. Le cache est presque toujours la plus grosse part et la seule qu'on peut jeter sans risque.*

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Durées de cache par catégorie et action Vider le cache">

*Gestion du cache, avec la durée de vie de chaque classe : recherches 5 min, détails station 15 min, requêtes de prix 5 min, données favoris 30 min, recherches de ville 30 min, géocodage de code postal 24 h.*

<img src="guide/cache-clear-dialog.jpg" width="340" alt="Boîte de dialogue de confirmation du vidage du cache">

*Vider le cache supprime uniquement les résultats et prix en cache — profils, favoris et réglages sont conservés. Les recherches suivantes seront plus lentes ; rien n'est perdu.*

---

## Sauvegarde et restauration

<img src="guide/backup-restore.jpg" width="340" alt="Entrées Exporter la sauvegarde et Restaurer la sauvegarde">

*Un ZIP complet avec véhicules, pleins, trajets et journaux de recharge.*

**Exporter la sauvegarde** écrit le ZIP dans vos Téléchargements. **Restaurer la sauvegarde** propose *fusionner* ou *remplacer* — fusionner conserve ce qui est sur l'appareil et ajoute ce qui manque ; remplacer efface d'abord. À utiliser avant un changement de téléphone ou une réinitialisation. TankSync n'est pas une sauvegarde : il réplique des catégories choisies, pas tout.

---

## Avancé et développeur

<img src="guide/advanced-developer.jpg" width="340" alt="Champ du jeton PAT GitHub et entrée Outils de développement">

*Le jeton GitHub est facultatif — sans lui, un retour de scan raté se partage manuellement au lieu d'ouvrir un ticket automatiquement.*

L'entrée **Outils de développement** n'apparaît qu'avec le mode développeur activé (Fonctions et mode d'utilisation → Développeur et expérimental).

<img src="guide/developer-tools-1.jpg" width="340" alt="Outils de développement : journal d'erreurs, notification de test, pipeline d'alerte de test, diagnostics, testeur OCR, vider les caches">

*Pour un utilisateur ordinaire, le journal d'erreurs est la partie utile : **Enregistrer le journal d'erreurs** écrit des traces expurgées dans les Téléchargements, à joindre à un rapport de bug.*

<img src="guide/developer-tools-2.jpg" width="340" alt="Copier les diagnostics, exporter la trace d'accès aux données, trace d'initialisation au démarrage">

*La trace de démarrage est une cascade des phases d'initialisation — c'est ainsi qu'un lancement lent se diagnostique au lieu de se deviner.*

<img src="guide/developer-tools-3.jpg" width="340" alt="Tester l'overlay d'approche et infos de build avec version et canal">

***Tester l'overlay d'approche** pousse un état synthétique pendant 30 s pour vérifier l'affichage de prix en incrustation sans aller rouler.*

---

## À propos

<img src="guide/about-1.jpg" width="340" alt="À propos : version et numéro de build, auteur, licence, politique de confidentialité, GitHub, signaler un bug">

***Version et numéro de build** — citez les deux dans tout rapport de bug, et vérifiez-les d'abord quand un correctif « n'a pas marché » (le déploiement du store ne vous a peut-être pas encore atteint).*

<img src="guide/about-2.jpg" width="340" alt="À propos : liens de soutien et attributions de données">

*L'application est gratuite, open source et sans publicité. Les attributions des données de prix et de carte figurent en bas, comme les licences l'exigent.*

---

**Voir aussi :** [Comment fonctionne Sparkilo](User-fr-How-It-Works) · [Confidentialité, données et sync](User-fr-Privacy-Profiles-Sync)
**Suite :** [Confidentialité, données et sync →](User-fr-Privacy-Profiles-Sync)
