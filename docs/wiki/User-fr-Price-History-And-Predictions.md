# Historique et prévisions de prix

L'application construit une image **privée et locale** de la façon dont les prix bougent autour de vous, et en tire une recommandation honnête.

---

## Ce qui est enregistré, et où

Chaque fois qu'un prix de station passe par l'application — une recherche, un rafraîchissement des favoris ou une vérification d'alerte en arrière-plan — l'application écrit **sur votre téléphone** un relevé : station, carburant, prix, horodatage. Rien n'est envoyé, et les données de personne d'autre ne sont téléchargées.

- **Dédoublonné à un relevé par station et par heure.** Cinq recherches en dix minutes donnent une entrée.
- **Conservé 30 jours.** Les relevés plus anciens sont supprimés automatiquement.
- **Activé par** *Fonctions et mode d'utilisation → Prix et alertes → Historique des prix*. Désactivé, aucun relevé n'est écrit.

<img src="guide/prices-and-alerts-settings.jpg" width="340" alt="Prix et alertes : historique, prédiction TFLite, signalements communautaires, QR de paiement">

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

**Voir aussi :** [Favoris et alertes](User-fr-Favorites-And-Alerts) · [Trouver des stations → La fraîcheur](User-fr-Finding-Stations#la-fraîcheur-plus-importante-que-le-prix)
**Suite :** [Référence des réglages →](User-fr-Settings-Reference)
