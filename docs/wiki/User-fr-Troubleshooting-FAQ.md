# Dépannage et FAQ

Classé approximativement par fréquence réelle.

---

## Avant tout : vérifiez votre version

<img src="guide/about-1.jpg" width="340" alt="Écran À propos affichant la version et le numéro de build">

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

Contexte : [Comment fonctionne Sparkilo → Comment un litre devient un chiffre](User-fr-How-It-Works#comment-un-litre-devient-un-chiffre).

---

## « Nous avons trouvé un écart de X litres »

Vous avez versé plus que vos trajets enregistrés ne l'expliquent. Répondez aux deux questions de la réconciliation : un plein manquant ou mal saisi reçoit une **entrée de correction**, un trajet non enregistré reçoit un **trajet virtuel**. Les deux restent modifiables. Laisser l'écart en suspens biaise le calibrage, deux appuis valent donc la peine. Voir [Carnet de pleins et consommation](User-fr-Fuel-And-Consumption#quand-les-comptes-ne-tombent-pas-juste).

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

<img src="guide/developer-tools-2.jpg" width="340" alt="Trace d'initialisation au démarrage en cascade avec les durées par phase">

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

Détails : [Confidentialité, données et sync → Vos droits](User-fr-Privacy-Profiles-Sync#vos-droits-au-titre-du-rgpd).

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

**Retour à :** [l'accueil du guide](User-fr-Home)
