# Tabby — Cahier des charges fonctionnel

## 1. Vision du projet

Tabby est une application de partage de dépenses (équivalent fonctionnel de Tricount) enrichie d'analyses de dépenses visuelles. Projet personnel pour commencer (usage entre toi et ta copine, extensible à d'autres groupes : amis, collègues), **sans volet SaaS/monétisation** à ce stade.

Ton visuel : fun et moderne, **sans aucune gamification** (pas de badges, points, ou barres de progression ludiques).

## 2. Identité de marque

- **Nom** : Tabby.
- **Splash screen** : fond jaune moutarde chaud, rubans ondulés en dégradé de la même teinte, logotype blanc arrondi façon lettrage dessiné à la main.
- Voir le document séparé **Direction artistique** pour la palette complète, la typographie et les règles de style.

## 3. Utilisateurs et contexte d'usage

- Deux utilisateurs initiaux : toi et ta copine, chacun sur un téléphone Android.
- Extensible à d'autres groupes (amis, collègues) sans limite de nombre de groupes par utilisateur.
- Usage 100% connecté : aucune fonctionnalité hors-ligne prévue.

## 4. Navigation générale

Barre de navigation basse à 5 entrées :

| Icône | Label | Rôle |
|---|---|---|
| 🏠 | Home | Liste des groupes et de leurs soldes |
| 🐷 | Budget | Statistiques de dépenses |
| ➕ | Add | Action principale — ajouter une dépense |
| 🗂️ | Cards | Portefeuille de cartes de fidélité |
| 👤 | Profile | Groupes, catégories, paramètres |

## 5. Écrans et parcours détaillés

### 5.1 Home
**Affichage**
- Liste scrollable de cartes-groupes (ex. "Couple", "Amis"), chacune avec :
  - stack d'avatars superposés des membres du groupe,
  - nom du groupe,
  - solde : *"You owe X€"* (rouge) si l'utilisateur est débiteur, *"You are owed X€"* (vert) si créditeur, ou état neutre si soldé,
  - bouton *"+ Add expense"* propre au groupe.
- Bouton *"+ Add group"* sous la liste.
- Scroll simple si la liste dépasse l'écran.

**Actions possibles**
- Taper une carte-groupe → écran de détail du groupe *(à spécifier — voir section 8, point ouvert n°2)*.
- Taper *"+ Add expense"* sur une carte → ouvre Add avec le groupe pré-rempli.
- Taper *"+ Add group"* → flow de création de groupe.
- Pull-to-refresh pour resynchroniser (pas de cache local).

### 5.2 Budget (statistiques)
**Affichage**
- Sélecteur de période : mois en cours / année, navigation ← →.
- Sélecteur de portée : toggle "groupe actif" (défaut) / "tous les groupes" (vue consolidée) — *voir point ouvert n°1*.
- Camembert des dépenses par catégorie, couleurs distinctes par catégorie.
- Liste ordonnée en dessous : catégorie, icône, montant, % du total, triée décroissant.
- Barres de budget par catégorie avec indicateur vert/orange/rouge selon seuil de dépassement.

**Actions possibles**
- Changer période/portée → recalcul instantané de l'affichage.
- Taper une part du camembert ou une ligne de la liste → filtre les dépenses de cette catégorie pour la période affichée.
- Taper une barre de budget → écran d'édition de ce budget.
- *"+ Définir un budget"* si une catégorie a des dépenses mais pas encore de budget associé.

### 5.3 Add (ajout de dépense)
**Affichage**
- Montant en gros, clavier numérique ouvert par défaut à l'arrivée sur l'écran.
- Champ nom de la dépense.
- Sélecteur de catégorie horizontal scrollable (icônes), dernière catégorie utilisée pré-sélectionnée, bouton *"+"* en fin de liste pour créer une catégorie à la volée.
- Groupe concerné, pré-rempli selon le point d'entrée (Home générique = dernier groupe actif ; carte d'un groupe précis = ce groupe).
- Sélecteur "Qui a payé" (avatars des membres, soi-même par défaut).
- Bloc répartition : égale par défaut entre les membres du groupe ; section "répartition personnalisée" repliée par défaut (montants ou % par personne).
- Champ date, aujourd'hui par défaut.
- Toggle *"Répéter chaque mois"*.
- Bouton *"Ajouter"* sticky en bas d'écran.

**Actions possibles**
- Saisir/modifier chaque champ.
- Créer une catégorie sans quitter l'écran.
- Activer la répartition personnalisée et ajuster montants/% par membre.
- Activer la récurrence directement depuis cet écran (pas d'écran séparé pour créer une dépense récurrente).
- Valider → retour sur Home, dépense visible immédiatement en tête de liste, confirmation visuelle discrète (pas de type gamifié).

### 5.4 Cards (cartes de fidélité)
**Affichage**
- Grille/liste de cartes enregistrées, logo/couleur de l'enseigne, effet stack.
- État vide au premier lancement avec illustration + invitation à ajouter une carte.

**Actions possibles**
- Ajouter une carte : scan code-barres/QR via l'appareil photo, ou saisie manuelle du numéro.
- Taper une carte → affichage plein écran, luminosité poussée pour scan en caisse.
- Réorganiser (drag & drop) et supprimer une carte.

Fonctionnalité indépendante du partage de dépenses — propre à l'utilisateur, sans notion de groupe.

### 5.5 Profile
**Affichage**
- Avatar, nom, email de l'utilisateur.
- Liste des groupes dont il est membre, avec leurs membres respectifs.
- Liste des catégories (par défaut + personnalisées).
- Paramètres (devise, thème clair/sombre).

**Actions possibles**
- Créer un nouveau groupe, inviter un membre, quitter ou renommer un groupe.
- Créer / modifier / supprimer / réordonner une catégorie (nom, icône, couleur).
- Éditer son profil.
- Se déconnecter.

## 6. Fonctionnalités clés — récapitulatif

- Création et gestion de plusieurs groupes de partage.
- Synchronisation en temps réel via le serveur, aucun mode hors-ligne.
- Ajout de dépense : montant, nom, catégorie, payeur, répartition (égale ou personnalisée).
- Catégories par défaut (loyer, courses, etc.) + catégories personnalisées (ex. "Chien").
- Dépenses récurrentes (ex. loyer), créées via un toggle dans Add.
- Budgets par catégorie avec indicateur visuel de dépassement.
- Statistiques mensuelles/annuelles : camembert + liste triée par %.
- Portefeuille de cartes de fidélité, indépendant du partage de dépenses.

## 7. Hors périmètre (pour cette phase)

- Aucune fonctionnalité de paiement réel (pas d'intégration bancaire, pas de transfert d'argent) — l'app calcule qui doit quoi, le règlement reste manuel entre les personnes.
- Aucun mode hors-ligne / cache local.
- Aucune monétisation, aucun compte payant, aucune publicité.
- Pas d'auth sociale (Google/Apple Sign-in) prévue à ce stade — voir point ouvert n°3.

## 8. Points ouverts

1. **Portée des stats sur Budget** — proposition : groupe actif par défaut, bascule vers vue globale. À valider à l'usage.
2. **Écran de détail d'un groupe** (au tap sur une carte-groupe depuis Home) — contenu et actions non encore spécifiés (probable : historique complet des dépenses du groupe, liste des membres, accès aux réglages du groupe).
3. **Mécanisme d'invitation à un groupe** — lien à usage unique, code à 6 chiffres, ou QR code à trancher (voir Cahier technique, section Auth).
4. **Répartition personnalisée dans Add** — repliée par défaut ; fréquence d'usage réelle à observer pour décider si elle doit être plus visible.
5. **Monétisation / SaaS** — explicitement hors périmètre pour cette phase, à reconsidérer plus tard si le projet évolue au-delà de l'usage personnel.
