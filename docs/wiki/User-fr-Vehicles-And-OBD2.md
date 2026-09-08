# Véhicules et OBD2

Tout ce que l'application sait de *votre voiture*. C'est cette page qui décide si les chiffres de consommation de toutes les autres sont dignes de confiance.

---

## Pourquoi l'application a besoin d'un véhicule

Sans véhicule, Sparkilo est un chercheur de prix. Avec, elle peut convertir litres et kilomètres en *votre* coût au kilomètre, estimer l'autonomie et — avec un adaptateur — modéliser le débit de carburant instantané.

<img src="guide/vehicles-and-obd2.jpg" width="340" alt="Écran Véhicules et OBD2 avec les tuiles Mes véhicules et Adaptateur OBD2">

*Réglages → Véhicules et OBD2. Notez l'étiquette de portée sur la tuile adaptateur : les adaptateurs s'appairent **par véhicule**, pas par téléphone.*

<img src="guide/my-vehicles.jpg" width="340" alt="Liste des véhicules avec un véhicule actif">

*La coche verte marque le véhicule actif — celui auquel les nouveaux pleins et trajets sont attribués.*

---

## Identité et motorisation

<img src="guide/vehicle-edit-1.jpg" width="340" alt="Éditeur de véhicule : nom, VIN facultatif, lire le VIN depuis la voiture, sélecteur de motorisation">

*Nommez-le comme vous le reconnaîtrez. Le VIN est facultatif.*

### Le VIN, et ce qu'il apporte

Saisir (ou lire) le VIN permet à l'application de retrouver cylindrée, nombre de cylindres, puissance et type de carburant, qui sont les entrées du modèle de consommation. **Lire le VIN depuis la voiture** le récupère en une seconde via OBD2.

Le décodage en ligne du VIN fait l'objet d'un **consentement distinct** — l'application demande avant d'envoyer quoi que ce soit, et le décodage hors ligne partiel fonctionne même si vous refusez. Un VIN est une donnée personnelle ; traitez-le comme tel.

### Motorisation

**Thermique / Hybride / Électrique** change les champs qui suivent. Thermique demande la capacité du réservoir, la puissance et le carburant préféré ; électrique demande la batterie et les connecteurs.

---

## Capacité, puissance et flex-fuel

<img src="guide/vehicle-edit-2.jpg" width="340" alt="Bloc thermique : capacité du réservoir, puissance moteur, carburant préféré, interrupteur multi-carburant, adaptateur appairé">

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

<img src="guide/vehicle-edit-3.jpg" width="340" alt="Calibrage de la baseline : adaptateur appairé, progression 210/270, avertissement de situations manquantes et barres par situation">

*210 échantillons sur 270. Deux situations de conduite sont encore vides, et l'application le dit plutôt que de feindre la complétude.*

Chaque échantillon OBD2 est rangé dans une situation de conduite : **ralenti, stop & go, urbain, autoroute, décélération, côte / chargé, démarrage à froid, charge soutenue / remorquage, roue libre**. Les moyennes par situation forment la baseline du véhicule — le modèle qui produit un L/100 km plausible quand l'adaptateur est absent ou qu'un PID cesse de répondre.

<img src="guide/vehicle-edit-4.jpg" width="340" alt="Barres d'échantillons par situation, réinitialisation de la baseline et sélecteur de mode de calibration">

*Les situations à zéro échantillon sont celles qui retomberont sur des valeurs par défaut. Ici deux : décélération et remorquage.*

### Basé sur les règles ou flou

<img src="guide/vehicle-edit-5.jpg" width="340" alt="Mode de calibration basé sur les règles ou flou, actions de réinitialisation et rappels d'entretien">

*Le mode flou est le défaut, et le meilleur choix pour presque tout le monde.*

- **Basé sur les règles** attribue chaque échantillon à exactement une situation. Prévisible, mais il bascule d'un échantillon à l'autre entre « urbain » et « autoroute » quand vous roulez près de la frontière — vers 60 km/h par exemple.
- **Flou** répartit chaque échantillon sur toutes les situations selon son degré d'appartenance. Lisse précisément là où le mode règles saute, au prix d'être plus difficile à suivre échantillon par échantillon.

### Les boutons de réinitialisation — et ce qu'ils font vraiment

- **Réinitialiser le rendement volumétrique** jette le η_v appris et rétablit la valeur par défaut 0,85. η_v est un paramètre du modèle speed-density qui estime le débit d'air en l'absence de débitmètre. Ne le réinitialisez qu'après une intervention mécanique ; un chiffre qui semble bizarre relève plus souvent d'un problème de couverture. Les voitures qui publient le débit directement (PID 5E) ne l'utilisent pas du tout.
- **Réinitialiser depuis la base de véhicules** recharge cylindrée, puissance et valeurs par défaut du catalogue intégré, en écartant vos saisies manuelles.
- **Réinitialiser la baseline par situation** (dans la carte de baseline) efface chaque échantillon appris et vous ramène aux valeurs de départ à froid jusqu'à ce que de nouveaux trajets remplissent le profil.

Aucun de ces boutons ne touche au **gain pompe**, appris à partir des fenêtres de plein à plein et vivant en dehors du modèle OBD2 — voir [Comment fonctionne Sparkilo → Comment un litre devient un chiffre](User-fr-How-It-Works#comment-un-litre-devient-un-chiffre).

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

<img src="guide/full/vehicle-edit.jpg" width="420" alt="Éditeur de véhicule complet assemblé à partir de cinq captures">

</details>

---

**Voir aussi :** [Trajets et éco-coaching](User-fr-Trips-And-Coaching) · [Dépannage → OBD2](User-fr-Troubleshooting-FAQ#ladaptateur-obd2-ne-se-connecte-pas)
**Suite :** [Carnet de pleins et consommation →](User-fr-Fuel-And-Consumption)
