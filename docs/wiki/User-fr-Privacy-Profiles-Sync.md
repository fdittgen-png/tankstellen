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

<img src="guide/privacy-and-data-1.jpg" width="340" alt="Contrôles de confidentialité : proxy de tuiles et chargement des logos de marque">

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

<img src="guide/privacy-and-data-2.jpg" width="340" alt="Utilisation du stockage détaillée par catégorie avec les tailles">

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

<img src="guide/privacy-and-data-3.jpg" width="340" alt="Durées de cache par catégorie et action Vider le cache">

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

<img src="guide/sync-and-account.jpg" width="340" alt="Synchronisation et compte avec l'état TankSync, un avertissement de schéma obsolète et l'entrée Consentements">

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

Pour un instantané restaurable plutôt qu'un export de données, voyez **Réglages → Sauvegarde et restauration** — voir [Référence des réglages](User-fr-Settings-Reference#sauvegarde-et-restauration).

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

**Voir aussi :** [Référence des réglages](User-fr-Settings-Reference) · [Comment fonctionne Sparkilo → Où vivent vos données](User-fr-How-It-Works#où-vivent-vos-données)
**Suite :** [Dépannage et FAQ →](User-fr-Troubleshooting-FAQ)
