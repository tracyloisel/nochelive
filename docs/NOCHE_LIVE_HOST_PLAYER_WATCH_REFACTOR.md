# Noche Live — architecture définitive

## Décision

Noche Live est désormais une compétition automatique à durée configurée construite avec les
quiz existants de `/jugar`. Il n'existe plus de Host, de Presenter, de régie, de
manche globale, de thème Live ni d'illustration propre à la soirée.

Une Noche est définie par :

- une rama (`Ward`) ;
- une date de lancement (`starts_at`) ;
- une durée entière de 1 à 8 heures (`duration_hours`, 1 heure par défaut) ;
- une liste ordonnée, non vide et sans doublon de packs du catalogue `/jugar` ;
- les équipes persistantes de la rama, créées avant la soirée avec le MCP admin.

L'illustration et le titre viennent du premier pack avant le lancement. Pendant la
soirée, ils suivent le pack le plus avancé. La route publique canonique est toujours
`/s/:code` ; c'est l'heure serveur qui décide de ce qu'elle affiche.

## Cycle de vie

| Heure | Phase calculée | Expérience publique |
|---|---|---|
| avant T−30 min | `scheduled` | inscription, inscrits, lectures |
| T−30 à T0 | `lobby` | compte à rebours et choix d'une équipe existante |
| T0 à T+H | `playing` | Watch, inscription tardive et accès aux quiz |
| après T+H | `finished` | Watch final en lecture seule |

`GameSession#phase` est la source de vérité. Trois `Nights::LifecycleJob` sont
programmés pour T−30, T0 et T+H, où H est `duration_hours`. Chaque requête publique appelle également
`Nights::Reconcile` : un job retardé ou perdu ne peut donc pas laisser une Noche dans
un ancien état.

La fermeture est idempotente. `Nights::Close` verrouille la Noche, marque les runs
ouverts `expired`, conserve leur score partiel, fige la somme de chaque équipe dans
`teams.cached_score`, passe la session à `finished` et diffuse le Watch final. La
fermeture anticipée du MCP utilise exactement ce même chemin.

## Parcours joueur

### Avant le lobby

Le visiteur peut s'inscrire sans choisir d'équipe. Il voit les autres inscrits et
les chapitres dédupliqués de tous les packs, sans question ni réponse révélée.

### Lobby

Le joueur choisit une équipe dans le snapshot des `WardTeam` de la rama. Aucune
équipe n'est créée, renommée ou supprimée dans une Noche. Une fois le premier quiz
commencé, ce choix est verrouillé afin qu'un score ne puisse pas changer d'équipe.

### Pendant le Live

Un retardataire peut encore s'inscrire depuis Watch, choisir son équipe et commencer
le premier pack. Chaque joueur avance à son rythme dans la même liste ordonnée. Le
Player est le rendu `/jugar` normal : mêmes questions, thèmes, feedbacks, score,
streak, sons et écran final.

À la fin d'un pack :

- s'il reste un pack, `Jouer au quiz suivant` crée le prochain `QuizRun` Live ;
- sinon, ou si le joueur veut regarder la course, `Revenir à la Noche Live` retourne
  vers `/s/:code`.

Le domaine Street et le domaine Live sont séparés par `QuizRun.street` et
`QuizRun.live`. Les classements, séries, profils et défis permanents ne comptent que
les runs Street ; une performance Live ne modifie donc jamais l'aventure normale.

## Watch

Watch est une projection, pas un second jeu. Elle affiche :

1. le statut et le temps restant ;
2. le CTA adapté à l'identité (`S'inscrire`, `Choisir mon équipe`, `Jouer`) ;
3. le classement des équipes ;
4. la complétion question par question ;
5. le journal des événements récents ;
6. sur grand écran, un QR code vers la route canonique.

Le score d'équipe n'a volontairement aucune pondération :

```text
score_equipe = SUM(quiz_runs.score) GROUP BY team_id
```

La complétion d'une question est `answered / eligible`. `eligible` est le nombre de
joueurs ayant effectivement atteint le pack concerné. L'arrivée tardive d'un joueur
n'abaisse donc pas artificiellement la progression des packs qu'il n'a pas encore
commencés. Avec plusieurs packs, les lignes sont nommées `Q1.1`, `Q1.2`, …,
`Q2.1` ; avec un seul pack, `Q1`, `Q2`, …

## Données

La refonte réutilise volontairement le modèle existant, sans couche de compatibilité :

```text
GameSession
  ward_id
  code
  quiz_pack_ids[]
  starts_at
  duration_hours          entier de 1 à 8, 1 par défaut
  ends_at                 toujours starts_at + duration_hours
  status
  closed_at / cancelled_at

Team
  game_session_id
  ward_team_id            snapshot d'une WardTeam persistante
  name / emblem
  cached_score            résultat figé à la fermeture

Player
  game_session_id
  person_id optionnel
  name / avatar_key / locale / client_token

QuizRun
  game_session_id / player_id / team_id
  live_sequence_position
  pack_id / score / status / expired_at

LiveEvent
  game_session_id
  kind
  payload JSON localisable
  dedupe_key unique dans la Noche
  occurred_at
```

La contrainte unique `(game_session_id, player_id, live_sequence_position)` empêche
de créer deux fois le même pack pour un joueur. Les événements possèdent également
une clé de déduplication : les retries HTTP et jobs restent sûrs.

## Temps réel

Les événements sont sémantiques : `join`, `team_join`, `quiz_start`, `correct`,
`streak`, `lead_change`, `quiz_finish`, `night_open`, `night_close`. Le texte n'est
jamais stocké ; chaque client le localise en espagnol, français, anglais ou portugais.

Dans le Player, la dernière information remplace le contenu de la tuile Défi
existante `#live_event_tile`. Elle ne crée ni toast supplémentaire ni file visuelle
qui pourrait recouvrir le quiz. Dans Watch, les mêmes événements alimentent le
journal et déclenchent un remplacement de la projection.

Une réponse correcte peut produire plusieurs faits (`correct`, palier de série,
changement de tête), mais `Nights::Events.after_answer` ne programme qu'un seul
`Nights::BroadcastJob`. `Nights::Broadcast` calcule la projection une fois, la
réutilise pour toutes les locales et ne refait pas une requête par tuile ou par
langue.

## MCP admin

Le MCP expose quatre outils dédiés :

- `create_ward_team(ward_code, name, emblem)` ;
- `create_noche_live(ward_code, starts_at, quiz_ids[], duration_hours?)` ;
- `edit_noche_live(ward_code, session_code, starts_at?, quiz_ids[]?, duration_hours?)` ;
- `finish_noche_live(ward_code, session_code)`.

La création snapshotte toutes les équipes existantes de la rama. La modification
n'est permise qu'avant `starts_at`. `finish_noche_live` est idempotent et ne simule
aucune étape de présentation : il ferme immédiatement la soirée.

## Responsive, animation et performance

### Composition

- téléphone : une colonne, CTA pleine largeur, classement puis progression puis
  événements ;
- tablette : grille deux colonnes, événements sur toute la largeur ;
- desktop/TV : trois colonnes et QR code persistant ;
- paysage bas : hero plein viewport et typographie réduite ;
- toutes tailles : safe areas iOS, cibles tactiles et texte tronqué sans débordement.

### Mouvement

- compte à rebours : mise à jour alignée sur la seconde, sans boucle par frame ;
- statut Live : respiration lente du point rouge ;
- événement Watch : entrée verticale courte ;
- progression : transition de largeur de 500 ms ;
- tuile Player : transformation du contenu dans un conteneur stable ;
- changement de phase : rechargement canonique à l'échéance serveur ;
- `prefers-reduced-motion` : respiration, entrée et transition désactivées.

Les animations se limitent à `transform`, `opacity` et à la largeur des petites
barres de progression. Aucun filtre animé, canvas, polling à haute fréquence ou
nouvelle image raster n'est nécessaire. Les artworks optimisés des packs et les
icônes SVG internes sont réutilisés.

### Requêtes

`Nights::Projection` utilise des agrégats SQL pour les scores, membres, runs éligibles
et réponses. Elle ne charge jamais toutes les réponses pour les compter. Les index
Live couvrent le cycle de vie, la séquence par joueur, l'agrégation par équipe et la
timeline. Un broadcast calcule la projection une seule fois pour les quatre locales.

## Legacy supprimé

La refonte est destructive par choix produit. Ont été retirés :

- les routes et contrôleurs Host, Presenter, Public Watch et ancien GameSession ;
- les claims Presenter, rosters, gates, commandes de rounds et assignations de rôles ;
- les modèles/services de rounds, buzzers, votes, audience, réactions, scores,
  récompenses et mini-jeux de l'ancienne Noche ;
- les vues, contrôleurs Stimulus, tests, locales et styles correspondants ;
- les colonnes `role`, `location`, tokens Presenter, poster, thème, délai de broadcast
  et statistiques historiques de l'ancien système ;
- les tables de jeu legacy, supprimées par migration irréversible.

Il n'existe ni adaptateur, ni double écriture, ni lecture d'historique. Le seul
contrat Noche Live supporté est celui décrit dans ce document.
