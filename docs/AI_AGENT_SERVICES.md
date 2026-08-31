# Services Noche Live pour les agents IA

> Statut : note de conception — à reprendre ultérieurement
> Dernière mise à jour : 28 août 2026

## Opportunité

La couche de découverte (`/llms.txt`, pages Markdown et métadonnées publiques) permet déjà à un agent IA de comprendre Noche Live. L’étape suivante consisterait à lui rendre de vrais services structurés.

Le service le plus différenciant serait un **copilote de soirée Noche Live**. Il ne se contenterait pas de retrouver des versets : il transformerait l’intention d’un utilisateur en expérience prête à jouer.

Exemple de demande :

> Prépare une soirée de 45 minutes pour 18 jeunes de 12 à 16 ans, en français, sur le courage.

## Boucle principale proposée

`intention → proposition de soirée → aperçu → confirmation → lien de lancement`

Cette boucle préserve le rôle de l’agent comme assistant tout en laissant la décision et le contrôle à l’utilisateur.

### 1. `recommend_game_night`

Proposer un thème, les jeux, leur ordre, la durée, la difficulté et les transitions selon :

- l’âge des participants ;
- la taille du groupe ;
- la langue ;
- le temps disponible ;
- le thème biblique ou humain ;
- le contexte : famille, jeunes, paroisse ou distance.

### 2. `create_game_night_draft`

Préparer une soirée modifiable sans la publier, inviter qui que ce soit ni créer de session active.

### 3. `preview_game_night`

Retourner un déroulé compréhensible par l’utilisateur : chronologie, jeux, objectifs, matériel éventuel et lien de prévisualisation.

### 4. `launch_game_night`

Créer la session uniquement après une confirmation humaine explicite.

### 5. `get_live_state`

Fournir la projection Watch de la soirée : phase dérivée de l'heure, classement
des équipes, complétion des questions et événements sémantiques récents.

### 6. `suggest_next_move`

Proposer une action d'organisation hors moteur de jeu — partager le lien,
préparer les lectures ou rappeler l'heure — sans contrôler la progression des quiz.

## Autres services possibles

### Contenu public

- `search_scriptures` : retrouver un passage par référence, personnage, événement ou thème, avec citation de la source.
- `recommend_quiz` : choisir un quiz selon l’âge, le niveau, la langue et le temps disponible.
- `build_activity_plan` : composer une activité chrétienne avec objectif, déroulé, matériel et durée.
- `find_church` : retrouver une assemblée ou une chapelle à partir des informations publiques disponibles.

### Expérience personnalisée

- `recommend_next_study` : proposer le prochain parcours à partir de la progression que le joueur a autorisé l’agent à consulter.
- `summarize_game_night` : produire un compte rendu de soirée sans divulguer de données personnelles.
- `draft_invitation` : préparer une invitation WhatsApp dans la bonne langue, sans l’envoyer.
- `translate_live` : localiser les notifications sémantiques destinées aux participants.

## Interfaces techniques envisagées

Deux interfaces complémentaires pourraient être proposées :

- une API HTTP documentée avec OpenAPI, utilisable par toute intégration ;
- un serveur MCP exposant des outils nommés clairement pour les agents compatibles.

Les deux interfaces devraient partager les mêmes contrats métier, règles d’autorisation et journaux d’audit. Les liens profonds vers Noche Live assureraient le passage de relais à l’utilisateur pour la prévisualisation, la confirmation et le lancement.

## Garde-fous

### Lecture publique

Un agent peut consulter sans authentification les informations déjà publiques et indexables.

### Accès privé limité

La progression, les groupes, les sessions et les profils exigent une autorisation explicite, limitée par portée et révocable.

### Confirmation avant mutation

Un agent peut préparer un brouillon automatiquement. Il ne doit pas, sans confirmation humaine :

- créer ou lancer une session ;
- inviter une personne ou envoyer un message ;
- accepter un défi ;
- modifier un profil ou une progression ;
- contrôler une soirée en direct.

### Sécurité opérationnelle

Les actions mutantes devraient utiliser des clés d’idempotence, des permissions précises, une durée d’autorisation courte et un journal indiquant qui a demandé, confirmé et exécuté chaque action.

### Fidélité du contenu

Les réponses bibliques ou doctrinales doivent citer leurs sources, distinguer le texte de son explication et éviter de présenter une génération de l’agent comme une position officielle.

## Première verticale recommandée

Commencer par trois outils :

1. `recommend_game_night` ;
2. `create_game_night_draft` ;
3. `preview_game_night`.

Cette première verticale apporte déjà une forte valeur sans donner à l’agent de pouvoir direct sur une session ou sur des personnes. `launch_game_night` pourrait venir ensuite, après validation du modèle d’autorisation et de confirmation.

## Question à reprendre

Avant l’implémentation, préciser :

- le premier type d’agent visé ;
- les données nécessaires à une recommandation de qualité ;
- le contrat d’entrée et de sortie de chaque outil ;
- le parcours exact de confirmation humaine ;
- les permissions et durées de jetons ;
- les métriques permettant de juger la valeur du copilote.
