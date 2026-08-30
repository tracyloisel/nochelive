# Noche Live — refonte programmée / Player / Watch

## Statut du document

- **Type :** spécification produit, UX et architecture cible
- **Périmètre :** création, inscription, lobby, jeu, Watch et clôture
- **Décision principale :** la Noche Live n'a plus de présentateur et ne crée pas un nouveau type de quiz
- **UI Player :** le quiz `/jugar` existant, sans nouveau thème
- **Compétition :** `WardTeam` existantes de la rama, classées par somme brute des points de leurs membres

---

## 1. Décision produit

Une Noche Live est un quiz programmé : un administrateur choisit une rama, un pack
de quiz et une date de lancement. Le titre et l'illustration viennent du pack. La
Noche ouvre automatiquement son lobby 30 minutes avant le départ, démarre à l'heure
prévue et se ferme automatiquement une heure plus tard.

Avant le lobby, les joueurs peuvent déjà s'inscrire, voir les autres inscrits et
consulter les chapitres bibliques à lire. Dans le lobby, ils choisissent l'une des
équipes déjà créées dans la rama. Une équipe ne se crée, ne se renomme et ne s'archive
jamais depuis une Noche Live. Pendant l'heure de jeu, les inscriptions restent
ouvertes : un retardataire arrive sur Watch, s'inscrit, choisit son équipe existante
et commence immédiatement le quiz.

La page publique de la Noche change avec l'horloge :

| Plage | Mode de la page publique | Action principale |
|---|---|---|
| avant T−30 min | `scheduled` | S'inscrire et préparer les lectures |
| de T−30 min à T0 | `lobby` | Choisir son équipe de rama, puis attendre le départ |
| de T0 à T+60 min | `playing` / Watch | Regarder la course ou entrer dans le quiz |
| après T+60 min | `finished` / Watch final | Consulter le résultat final des équipes |

Il n'existe plus de rôle public Host. La création et la programmation appartiennent
à l'administration. Il n'existe plus non plus de rôle Presenter, de régie de manches
ou de commande question par question.

---

## 2. Principes non négociables

### 2.1 Le Player reste le quiz existant

Le joueur utilise exactement l'expérience `/jugar` déjà en production :

- même carte de question ;
- mêmes réponses, feedbacks, score et progression ;
- mêmes thèmes Celestial Light/Dark déterminés par le pack ;
- même écran de score final ;
- aucune navigation `Quiz / Classement / Discussion` ajoutée dans le quiz.

Trois intégrations seulement sont nécessaires :

1. les événements Live arrivent dans la tuile Défi existante `.duel-quiz-rail` ;
2. l'écran de score final reçoit un bouton `Retour à la Noche Live` ;
3. un run interrompu par T+60 affiche la variante `Temps écoulé` avec score partiel.

### 2.2 Watch est aussi la porte d'entrée

Pendant la plage Live, Watch n'est pas une impasse réservée aux spectateurs. Son CTA
dépend de l'identité du visiteur :

| État du visiteur | CTA Watch |
|---|---|
| non inscrit | `S'inscrire et jouer` |
| inscrit sans équipe | `Choisir une équipe` |
| inscrit avec équipe, quiz non démarré | `Commencer le quiz` |
| quiz en cours | `Continuer le quiz` |
| quiz terminé | aucun CTA de démarrage ; score personnel et Watch restent accessibles |
| Noche fermée | aucune inscription ni réponse ; résultat final seulement |

Le parcours `S'inscrire et jouer` ouvre un flow court : identité `Person`, choix parmi
les `WardTeam` de la rama, puis lancement immédiat du `QuizRun`. Les champs ne doivent
pas envahir Watch : un seul CTA ouvre une sheet ou un écran dédié.

### 2.3 Le classement est un classement d'équipes

Le score d'une équipe est volontairement simple :

```text
score_equipe = SUM(score_courant_des_quiz_runs_de_ses_membres)
```

Il n'y a ni moyenne, ni multiplicateur, ni normalisation selon la taille de l'équipe,
ni plafond par joueur. Une équipe plus nombreuse peut donc totaliser davantage de
points. C'est une règle produit assumée, visible dans l'aide du classement.

La liste des équipes n'est pas fabriquée pour optimiser une Noche : elle vient du
domaine communautaire `WardTeam` et existe avant l'événement. Les écarts de taille
entre ces équipes persistantes sont acceptés par la règle de somme brute.

Seuls comptent les `QuizRun` :

- rattachés à la Noche courante ;
- appartenant à un participant de l'équipe ;
- non invalidés administrativement.

Les scores intermédiaires des joueurs encore en course sont inclus. À la fermeture,
le total courant est figé, y compris pour les quiz non terminés.

### 2.4 Une compétition Live, pas une explosion de duels

Dire que « tous les inscrits sont en défi les uns contre les autres » décrit
l'expérience sociale. Techniquement, la Noche reste une compétition unique. Il ne
faut pas créer un duel pour chaque paire de joueurs : cela produirait O(n²) relations.

La tuile Défi est réutilisée comme composant d'affichage des événements en jeu, mais
le moteur et les modèles Duel ne deviennent pas la source de vérité de la Noche.

---

## 3. Expérience par phase

### 3.1 Avant T−30 : inscription et préparation

La page montre :

1. l'illustration, le titre et le nombre de questions du pack ;
2. la date et l'heure de lancement ;
3. un compte à rebours sobre ;
4. le CTA d'inscription ;
5. les joueurs déjà inscrits ;
6. les chapitres bibliques à lire.

La Noche ne possède pas d'illustration éditoriale séparée. L'artwork est toujours
celui du pack. Le titre affiché est également celui du pack, avec éventuellement un
libellé de contexte tel que la rama et la date.

La liste de lecture est calculée à partir des références scripturaires du pack :
références uniques, dans l'ordre du pack, regroupées par livre et chapitre. Elle ne
doit révéler ni la bonne réponse, ni le texte des questions, ni leur ordre exact.

À ce stade, l'inscription ne demande pas encore une équipe. Le participant pourra
la choisir lorsque le lobby ouvrira.

### 3.2 De T−30 à T0 : lobby d'équipes

Le lobby s'ouvre automatiquement. Il conserve le titre et l'artwork du pack et rend
prioritaires :

- le compte à rebours serveur ;
- la liste des équipes de la rama ;
- le nombre de membres par équipe ;
- `Rejoindre` pour une équipe existante ;
- la présence des inscrits encore sans équipe.

La liste est strictement celle des `WardTeam` de la rama. `Créer une équipe` est
retiré du lobby ; la gestion des équipes reste dans son parcours communautaire hors
Noche Live. L'équipe habituelle de la `Person` peut être présélectionnée si elle
appartient à la bonne rama, mais le joueur confirme son choix avant de commencer.

Il n'y a pas de bouton Host `Lancer`. Le passage au jeu vient de `starts_at`. Les
clients connectés calculent l'affichage du countdown depuis l'heure serveur et se
réconcilient avec le serveur à chaque reconnexion.

### 3.3 De T0 à T+60 : quiz et Watch en temps réel

À l'heure de départ :

- un inscrit ayant une équipe peut entrer directement dans le quiz existant ;
- chaque joueur progresse à son propre rythme ;
- un nouveau visiteur voit Watch avec `S'inscrire et jouer` ;
- le retardataire choisit une `WardTeam` existante avant de démarrer ;
- aucune question courante globale n'est imposée aux Players ;
- la fermeture reste fixée à T+60, quelle que soit l'heure d'arrivée du joueur.

La composition recommandée de Watch est :

1. identité de la Noche, statut `EN DIRECT` et temps restant ;
2. CTA contextuel d'entrée ou de reprise ;
3. classement des équipes ;
4. complétion des questions ;
5. événements Live récents.

Sur téléphone et tablette, le CTA est un bouton actionnable. Sur un affichage TV,
le même emplacement devient un QR code et une URL courte : Watch reste la même route,
mais ne prétend pas qu'une télécommande est un moyen confortable de s'inscrire.

Le classement affiche au minimum : rang, nom de l'équipe, total de points, nombre de
membres et nombre de membres ayant terminé. Il peut déplier les meilleurs contributeurs
sans transformer l'écran principal en tableau analytique.

La complétion d'une question est exposée sous forme `answered_count / eligible_count`.
`eligible_count` correspond aux participants ayant démarré un quiz. Il peut augmenter
quand un retardataire commence ; l'interface affiche donc des comptes réels plutôt
qu'un pourcentage présenté comme irréversible.

### 3.4 Après T+60 : Watch final

À `ends_at`, la Noche se ferme automatiquement et de façon idempotente :

- toute nouvelle inscription est refusée ;
- toute nouvelle réponse est refusée ;
- les scores courants sont figés ;
- le classement final des équipes est persisté ;
- les clients passent à Watch final ;
- les joueurs terminés conservent leur écran de score personnel et le bouton retour.

Un joueur encore en cours passe sur une variante terminale explicite :
`Temps écoulé · X points pour Équipe`, puis `Voir le résultat des équipes`. Son run
est marqué `expired`, son score partiel compte dans le total final et il ne réapparaît
pas comme un quiz ouvert dans l'aventure normale.

La session ne se ferme pas plus tôt lorsque tous les joueurs présents ont terminé :
un nouveau joueur est autorisé à arriver jusqu'à `ends_at`.

---

## 4. Notifications en temps réel

### 4.1 Dans le quiz Player

Les événements utilisent la tuile Défi existante :

- emplacement dans la safe zone supérieure, sans recouvrir question ni réponses ;
- un seul conteneur de tuile visible à la fois ;
- en cadence normale, expansion courte puis état compact ;
- en cadence dense, le conteneur reste en place et son contenu se transforme ;
- variante Light/Dark héritée du quiz ;
- `aria-live`, réduction de mouvement, déduplication et haptique déjà supportées.

Le moteur ne fixe pas un cooldown arbitraire. Il doit pouvoir alimenter la tuile
jusqu'à un nouvel événement toutes les deux secondes lorsque la partie le justifie.
Pour que cette cadence reste fluide :

- l'arrivée visuelle d'une tuile ne redémarre pas complètement à chaque événement ;
- le nouvel événement remplace le contenu courant sans constituer de backlog ;
- une transition termine avant l'événement suivant ;
- la tuile ne capte jamais les interactions destinées à la question ;
- les événements obsolètes ne sont pas rejoués après une reconnexion ;
- l'annonce pour les technologies d'assistance peut être synthétisée séparément de
  la cadence visuelle afin de ne pas saturer `aria-live`.

Le son et l'haptique font partie de la grammaire d'événement, pas d'une limite de
fréquence globale : leur activation est définie par type d'événement et validée sur
une séquence dense réelle.

Exemples utiles :

- `L'équipe Nazareth prend la tête` ;
- `Carmen enchaîne 5 bonnes réponses` ;
- `L'équipe Béthel n'est plus qu'à 20 points` ;
- `12 joueurs viennent de répondre à la question 6` ;
- `Tracy vient de terminer`.

Il ne faut pas créer en parallèle un second fil Player ou une pile de toasts.

### 4.2 Dans Watch

Watch reçoit le même journal d'événements, mais l'affiche dans un flux adapté à son
viewport. La TV peut garder trois ou quatre événements récents ; le mobile en montre
un résumé compact sous le classement. Les événements ne remplacent jamais le score
d'équipe comme information principale.

Le moteur publie des événements sémantiques, pas une phrase pré-rendue. Le texte final
est localisé côté présentation.

---

## 5. Modèle de données cible

### 5.1 `LiveSession`

```text
LiveSession
  id
  public_code             unique, non devinable
  ward_id                 rama propriétaire
  pack_id                 pack joué
  starts_at               instant de lancement
  ends_at                 starts_at + 1 heure
  status                  scheduled | lobby | playing | finished | cancelled
  created_by_id           administrateur
  finished_at
  cancelled_at
  final_projection_json   snapshot final obligatoire après fermeture
  created_at
  updated_at
```

Invariants :

- `pack_id`, `ward_id` et `starts_at` sont obligatoires ;
- `ends_at` est généré depuis `starts_at`, pas saisi librement ;
- aucun champ d'illustration : l'artwork vient du pack ;
- le pack et la rama deviennent immuables à l'ouverture du lobby ;
- les transitions reposent sur l'horloge serveur ;
- un statut en retard doit être corrigé par réconciliation à la lecture ou à l'écriture ;
- `cancelled` est une dérogation administrative terminale, pas une phase de l'horloge ;
- une session `finished` doit posséder son snapshot final immuable.

### 5.2 `LiveParticipant`

```text
LiveParticipant
  id
  live_session_id
  person_id
  ward_team_id            nullable avant le choix d'équipe
  display_name_snapshot
  registered_at
  started_at
  finished_at
  expired_at
  last_seen_at
  created_at
  updated_at
```

Contraintes :

- unicité `(live_session_id, person_id)` ;
- la `Person` et la `WardTeam` doivent appartenir à la rama de la session ;
- `display_name_snapshot` est la seule identité personnelle requise dans les
  projections publiques ;
- un participant possède au plus un `QuizRun` dans la session.

Règle d'intégrité recommandée : l'équipe devient immuable dès `started_at`. Changer
d'équipe après avoir commencé déplacerait artificiellement des points déjà gagnés.
Avant le premier lancement, le joueur peut encore corriger son choix.

### 5.3 Contexte Live de `QuizRun`

```text
QuizRun
  live_session_id         nullable pour les runs normaux
  live_participant_id     nullable, unique lorsqu'il est présent
  status                  open | finished | expired
  expired_at              renseigné à la fermeture si le quiz est inachevé
```

Le Live réutilise le moteur de question, de réponse, de score, de série et de
feedback. Il ne réutilise pas aveuglément les effets de bord du parcours normal.

Invariants :

- un run Live référence directement sa session et son participant ;
- son `pack_id` est celui de la session ;
- `QuizRun.ends_at` reste exclusivement l'horloge de la question courante ;
- `LiveSession.ends_at` est exclusivement l'horloge de fermeture de la Noche ;
- un run Live ignore le verrouillage d'aventure du pack choisi par l'administrateur ;
- par défaut, il n'alimente pas le déverrouillage des packs, le classement permanent,
  les duels ordinaires ou `DuelRunFanout` ;
- les services du jeu normal filtrent `live_session_id IS NULL` ;
- les services Live filtrent toujours le `live_session_id` attendu ;
- à T+60, un run encore `open` devient `expired` sans perdre son score courant.

### 5.4 Réutilisation de `WardTeam`

Aucun modèle `LiveTeam` n'est créé. La liste affichée vient de :

```text
WardTeam.where(ward_id: live_session.ward_id)
```

Règles :

- les équipes sont créées et administrées hors Noche Live ;
- le lobby et Watch ne proposent aucune création, suppression ou édition d'équipe ;
- la sélection Live snapshotte `ward_team_id` sur `LiveParticipant` ;
- l'équipe habituelle `Person.last_ward_team_id` peut être proposée par défaut ;
- la sélection confirmée peut mettre à jour cette équipe habituelle ;
- le total Live est dérivé des `QuizRun` des participants, puis figé au final ;
- aucune normalisation ne corrige les différences de taille entre `WardTeam`.

### 5.5 `LiveEvent`

```text
LiveEvent
  id
  live_session_id
  event_type
  actor_participant_id    nullable
  ward_team_id            nullable
  payload_json
  occurred_at
  dedupe_key              unique dans la session
```

Le journal sert à Watch, à la tuile Player et à la reconnexion. Il ne contient pas de
réponse correcte ni de donnée privée d'un autre joueur.

---

## 6. Machine d'état automatique

```text
création
   │
   ▼
scheduled ── starts_at - 30 min ──> lobby ── starts_at ──> playing
                                                              │
                                                              │ ends_at
                                                              ▼
                                                          finished

scheduled / lobby / playing ── arrêt administratif ──> cancelled
```

La source de vérité est le temps :

- `scheduled` si `now < starts_at - 30 minutes` ;
- `lobby` si `starts_at - 30 minutes <= now < starts_at` ;
- `playing` si `starts_at <= now < ends_at` ;
- `finished` si `now >= ends_at` ;
- `cancelled` si un administrateur a déclenché l'arrêt d'urgence, quelle que soit
  l'heure théorique.

Deux mécanismes complémentaires sont nécessaires :

1. des jobs planifiés pour diffuser les transitions sans requête utilisateur ;
2. `Lives::ReconcileState` sur les lectures et écritures sensibles pour réparer un
   job retardé ou manqué.

Chaque transition verrouille la session, vérifie l'état attendu et peut être rejouée
sans double broadcast, double snapshot ou double création de run.

---

## 7. Services applicatifs

### 7.1 Administration et cycle de vie

| Service | Responsabilité |
|---|---|
| `Lives::Create` | Valider rama, pack et date ; fixer `ends_at` ; programmer les jobs |
| `Lives::Reschedule` | Modifier la date avant l'ouverture du lobby et reprogrammer les jobs |
| `Lives::OpenLobby` | Passer en lobby et diffuser l'ouverture des équipes |
| `Lives::Start` | Passer en jeu à `starts_at` et diffuser le GO |
| `Lives::Close` | Expirer les runs inachevés, figer les scores et publier le résultat final |
| `Lives::Cancel` | Arrêt administratif d'urgence, distinct de la fermeture normale |
| `Lives::ReconcileState` | Appliquer les transitions manquées à partir de l'horloge |
| `Lives::ReadingList` | Extraire les références uniques du pack sans dévoiler le quiz |

### 7.2 Inscription, équipe et quiz

| Service | Responsabilité |
|---|---|
| `Lives::Register` | Créer ou retrouver une `Person`, puis inscrire de façon idempotente avant `ends_at` |
| `Lives::AvailableTeams` | Lister uniquement les `WardTeam` déjà présentes dans la rama |
| `Lives::SelectTeam` | Snapshotter une `WardTeam` existante avant le premier démarrage |
| `Lives::StartRun` | Créer ou reprendre un `QuizRun` explicitement isolé dans la session |
| `Lives::SubmitAnswer` | Déléguer au moteur de quiz existant et refuser après `ends_at` |
| `Lives::FinishParticipant` | Marquer l'arrivée sans fermer la session |
| `Lives::TouchPresence` | Mettre à jour la présence sans toucher au score |

`Lives::StartRun` ne clone pas le quiz et ne crée pas un moteur Live parallèle. Il
réutilise les primitives de question/réponse de `/jugar`, mais ne passe pas par les
politiques Street de verrouillage, de déverrouillage, de duel ou de leaderboard.

### 7.3 Projection Watch et événements

| Service | Responsabilité |
|---|---|
| `Lives::TeamLeaderboard` | Agréger `SUM(quiz_runs.score)` par équipe |
| `Lives::CompletionProjection` | Compter les réponses par position du pack |
| `Lives::EventDetector` | Transformer les changements significatifs en `LiveEvent` |
| `Lives::PlayerEventStream` | Livrer la séquence de tuiles sans backlog, y compris en cadence dense |
| `Lives::Projection` | Construire le payload public Watch |
| `Lives::BroadcastProjection` | Diffuser une projection coalescée et versionnée |

---

## 8. Projection Watch

Exemple de contrat :

```json
{
  "version": 148,
  "session": {
    "status": "playing",
    "starts_at": "2026-08-29T20:00:00+02:00",
    "ends_at": "2026-08-29T21:00:00+02:00",
    "seconds_remaining": 2186,
    "registration_open": true
  },
  "pack": {
    "title": "Rois et Prophètes",
    "artwork_url": "/packs/rois-et-prophetes/hero.webp",
    "question_count": 10
  },
  "viewer": {
    "state": "unregistered",
    "cta": "register_and_play"
  },
  "team_leaderboard": [
    {
      "rank": 1,
      "ward_team_id": 4,
      "name": "Nazareth",
      "score": 284,
      "member_count": 5,
      "finished_count": 2
    },
    {
      "rank": 2,
      "ward_team_id": 7,
      "name": "Béthel",
      "score": 251,
      "member_count": 4,
      "finished_count": 3
    }
  ],
  "question_completion": [
    { "position": 1, "answered_count": 9, "eligible_count": 9 },
    { "position": 2, "answered_count": 8, "eligible_count": 9 },
    { "position": 3, "answered_count": 6, "eligible_count": 9 }
  ],
  "latest_events": [
    {
      "id": 902,
      "type": "team_took_lead",
      "ward_team_id": 4,
      "occurred_at": "2026-08-29T20:23:11+02:00"
    }
  ]
}
```

Règles de classement :

1. score décroissant ;
2. les égalités partagent le même rang affiché ;
3. un ordre secondaire stable par nom normalisé puis identifiant évite le flicker ;
4. aucun départage caché ne modifie le total ;
5. le snapshot final conserve les mêmes règles.

Le bloc `viewer` est privé ou calculé séparément du cache public. Le classement,
la complétion et les événements restent cacheables pour tous les watchers.

---

## 9. Routes cibles

```text
GET    /s/:code                 page canonique selon l'heure et le visiteur
POST   /s/:code/register        inscription avant ends_at
POST   /s/:code/team            choix d'une WardTeam existante avant started_at
GET    /s/:code/play            entrée ou reprise dans /jugar
POST   /s/:code/answers         soumission via le moteur de quiz
POST   /s/:code/presence        heartbeat léger
GET    /s/:code/watch           redirection vers l'URL canonique

GET    /admin/live_sessions/new
POST   /admin/live_sessions
PATCH  /admin/live_sessions/:id
POST   /admin/live_sessions/:id/cancel
```

La création et l'administration des `WardTeam` utilisent leurs routes communautaires
existantes, hors de `/s/:code`. Aucune route Live ne crée une équipe.

L'URL partagée reste toujours `/s/:code`. Elle ne change pas au démarrage : c'est
son contenu qui passe automatiquement en Watch. Le bouton de l'écran de score final
renvoie vers cette même URL.

---

## 10. Temps réel, cache et charge

### 10.1 Streams

- un stream public par session pour la projection Watch ;
- un stream privé par participant pour résultat, erreur et tuile d'événement ;
- aucun stream Host ou Presenter ;
- aucune réponse correcte dans le stream public.

### 10.2 Chemin chaud d'une réponse

Dans une transaction courte :

1. réconcilier le statut et vérifier `now < ends_at` ;
2. verrouiller et mettre à jour un seul `QuizRun` ;
3. persister le résultat de la réponse ;
4. publier un job après commit.

Hors transaction :

1. recalculer l'équipe touchée et la question touchée ;
2. détecter les événements significatifs ;
3. coalescer les mises à jour arrivées dans une courte fenêtre ;
4. diffuser une projection versionnée.

Il ne faut pas remplacer une frame par joueur après chaque réponse. Une projection
publique agrégée et un message privé éventuel suffisent.

La coalescence concerne la projection Watch coûteuse, pas l'obligation de ralentir
les événements Player. Les événements sémantiques peuvent être livrés toutes les deux
secondes ; le composant stable décide comment transformer son contenu sans backlog.

### 10.3 Index minimaux

```text
live_sessions(public_code) UNIQUE
live_sessions(status, starts_at)
live_sessions(status, ends_at)
live_participants(live_session_id, person_id) UNIQUE
live_participants(live_session_id, ward_team_id)
quiz_runs(live_participant_id) UNIQUE WHERE live_participant_id IS NOT NULL
quiz_runs(live_session_id, status)
live_events(live_session_id, id)
live_events(live_session_id, dedupe_key) UNIQUE
```

---

## 11. Sécurité et intégrité

- l'administration utilise l'authentification admin existante ;
- le code public permet de consulter la Noche, pas de l'administrer ;
- l'inscription utilise l'identité `Person` existante et son mécanisme de device ;
- les actions d'équipe vérifient participant, rama et existence préalable de la `WardTeam` ;
- aucun endpoint Live ne permet de créer, renommer ou supprimer une équipe ;
- toute écriture Live vérifie `ends_at` côté serveur ;
- le client ne décide jamais qu'une session est encore ouverte ;
- le score d'équipe est calculé côté serveur ;
- les réponses correctes et détails privés ne sortent jamais dans Watch ;
- les noms publics utilisent le snapshot autorisé du participant, avec la politique
  de confidentialité et de modération déjà applicable aux profils ;
- les services d'inscription, de création de run et de clôture sont idempotents.

Les contrôles d'interface après T+60 ne suffisent pas : les endpoints de réponse et
d'équipe doivent eux-mêmes refuser l'écriture après réconciliation.

---

## 12. Migration depuis l'ancien Live

| Ancien concept | Décision | Cible |
|---|---|---|
| Presenter / régie | supprimer du nouveau chemin | transitions automatiques |
| Host public | supprimer | administration authentifiée avant l'événement |
| lancement manuel | supprimer | `starts_at` |
| clôture manuelle normale | supprimer | `ends_at = starts_at + 1 heure` |
| illustration Live | supprimer | illustration du pack |
| manches Live spécialisées | ne pas réutiliser | `QuizRun` existant avec contexte Live |
| score manuel / `ScoreEvent` | ne pas réutiliser | score courant du `QuizRun` |
| anciennes équipes de manches | ne pas réutiliser comme source sociale | `WardTeam` persistante de la rama |
| création d'équipe dans la Noche | supprimer | gestion communautaire hors Live |
| Audience interactive | hors MVP | Watch lisible et CTA d'entrée |
| Player salle / maison | supprimer | un seul type de participant |

Ne pas convertir automatiquement les anciennes Noche riches en mimes, buzz, votes ou
manches. Elles restent lisibles dans le chemin historique pendant la transition. Le
nouveau modèle s'applique aux Noche programmées créées après bascule.

---

## 13. Ordre d'implémentation

### Tranche 0 — fondations de domaine

- ajouter le contexte Live nullable sur `QuizRun` ;
- exclure les runs Live des parcours Street, duels et classements permanents ;
- ajouter `expired` et sa variante de résultat partiel ;
- définir `LiveParticipant` avec `Person` et snapshot de `WardTeam` ;
- définir le snapshot final obligatoire et l'arrêt `cancelled`.

**Sortie :** un run Live peut exister sans modifier l'aventure ou les duels normaux.

### Tranche A — tranche verticale jouable

- créer une session simple depuis l'administration ;
- inscrire une `Person` ;
- lister et sélectionner une `WardTeam` existante ;
- jouer au moins une question dans le vrai `/jugar` ;
- additionner le score dans Watch ;
- fermer la session et afficher le score partiel ou final.

**Sortie :** le chemin réel inscription → équipe → réponse → Watch → fermeture est
validé avant de construire le reste.

### Tranche B — programmation et préparation

- `LiveSession`, statuts, jobs et réconciliation ;
- création admin avec rama, pack et date ;
- artwork et titre dérivés du pack ;
- `Lives::ReadingList` ;
- page `scheduled` et inscription anticipée.

**Sortie :** un joueur s'inscrit avant la date, voit les inscrits et les lectures.

### Tranche C — lobby et arrivée tardive

- ouverture automatique à T−30 ;
- choix parmi les `WardTeam` de la rama, sans création ;
- countdown serveur ;
- CTA Watch contextuel ;
- inscription et sélection d'équipe encore possibles pendant le Live ;
- QR d'inscription sur Watch TV ;
- bouton `Retour à la Noche Live` sur le score final.

**Sortie :** un retardataire peut s'inscrire, sélectionner son équipe et jouer avant
T+60 sans que l'heure de fermeture se décale.

### Tranche D — Watch et flux dense d'événements

- somme des scores par équipe ;
- complétion par question ;
- `LiveEvent` et détection ;
- tuile Défi Player stable, capable d'un remplacement toutes les deux secondes ;
- séparation entre cadence visuelle et annonces d'accessibilité ;
- Watch responsive et projection coalescée.

**Sortie :** le classement d'équipes, la progression et les événements vivent en direct.

### Tranche E — clôture automatique

- `Lives::Close` à T+60 ;
- refus serveur des écritures tardives ;
- expiration des runs inachevés et écran `Temps écoulé` ;
- snapshot final obligatoire ;
- arrêt administratif `cancelled` ;
- reconnexion et rattrapage d'un job manqué.

**Sortie :** la Noche se ferme exactement après une heure sans intervention humaine.

---

## 14. Stratégie de tests

### Modèle et services

- `ends_at` vaut exactement `starts_at + 1 heure` ;
- pack et rama obligatoires ;
- aucun artwork Live séparé ;
- références de lecture uniques sans fuite de réponse ;
- transitions T−30, T0 et T+60 ;
- réconciliation idempotente après job manqué ;
- arrêt administratif idempotent vers `cancelled` ;
- snapshot final obligatoire pour une session `finished`.

### Inscription et équipes

- inscription avant le lobby ;
- inscription à T+59 autorisée ;
- inscription à `ends_at` refusée ;
- seules les `WardTeam` préexistantes de la rama sont affichées ;
- aucune équipe ne peut être créée, renommée ou supprimée via une route Live ;
- choix d'équipe en lobby et pendant le Live ;
- impossibilité de choisir une `WardTeam` d'une autre rama ;
- équipe habituelle valide présélectionnée ;
- changement d'équipe refusé après `started_at` ;
- choix snapshoté même si le profil change ensuite ;
- double inscription et double démarrage idempotents.

### Isolation du quiz Live

- démarrage possible même si le pack est verrouillé dans l'aventure personnelle ;
- run Live absent de `Quizzes::World` et des classements permanents ;
- fin Live sans `DuelRunFanout` ni déverrouillage du pack suivant ;
- tallies et classements Live filtrés par `live_session_id` ;
- `QuizRun.ends_at` continue à piloter seulement la question ;
- un run Street du même pack peut coexister sans être repris par la Noche.

### Score et Watch

- total d'équipe égal à la somme exacte de ses joueurs ;
- joueur non terminé inclus avec son score courant ;
- aucune moyenne ou normalisation ;
- mise à jour après chaque réponse validée ;
- égalités de score et ordre d'affichage stable ;
- late join pris en compte dans la complétion après démarrage ;
- état du CTA pour chaque état visiteur ;
- Watch public ne fuit aucune réponse correcte.

### Quiz et clôture

- Player réutilise le moteur et les vues `/jugar` ;
- deux joueurs progressent indépendamment ;
- arrivée tardive ne décale pas `ends_at` ;
- réponse à T+60 refusée côté serveur ;
- run inachevé passé à `expired` et score courant figé au résultat final ;
- écran `Temps écoulé` avec score partiel, équipe et retour Watch ;
- fin de tous les joueurs présents ne ferme pas la Noche plus tôt ;
- bouton de score final renvoie à la page canonique en Watch.

### Temps réel et accessibilité

- événement dédupliqué par `dedupe_key` ;
- projections reçues hors ordre ignorées par `version` ;
- un seul conteneur de tuile Défi Player à la fois ;
- séquence de 30 événements en 60 secondes sans backlog ni blocage des réponses ;
- dernier événement visible au plus tard au cycle d'affichage suivant ;
- transformations visuelles stables sans remontage complet du composant ;
- annonces `aria-live` synthétisées sans imposer la cadence visuelle ;
- mode réduction de mouvement ;
- reconnexion Watch récupère la projection courante et les derniers événements.

---

## 15. Critères d'acceptation

- une Noche est créée avec rama, pack et date, sans illustration propre ;
- elle ouvre son lobby 30 minutes avant le départ ;
- elle démarre à l'heure et se ferme automatiquement une heure plus tard ;
- avant le lobby, un joueur peut s'inscrire, voir les inscrits et les lectures ;
- en lobby, il choisit l'une des `WardTeam` déjà créées dans la rama ;
- aucune équipe ne se crée ou ne s'édite depuis la Noche Live ;
- pendant le Live, un nouveau joueur peut encore s'inscrire et choisir son équipe ;
- Watch expose un CTA clair pour entrer ou reprendre le quiz ;
- Watch TV expose un QR d'entrée plutôt qu'un faux bouton ;
- le Player est le quiz existant et avance à son rythme ;
- les notifications Player utilisent la tuile Défi existante, y compris à une cadence
  pouvant atteindre un nouvel événement toutes les deux secondes ;
- Watch montre événements, classement des équipes et complétion des questions ;
- le score d'équipe est la somme brute des scores de ses membres ;
- l'écran de score final permet de revenir à Watch ;
- un quiz interrompu à T+60 affiche son score partiel puis permet de revenir à Watch ;
- un run Live ne modifie pas l'aventure, les duels ou les classements permanents ;
- après T+60, aucune inscription, mutation d'équipe ou réponse n'est acceptée ;
- un administrateur peut annuler une session en urgence sans devenir présentateur ;
- aucun rôle Presenter ou Host public n'est nécessaire.

---

## 16. Décisions éditoriales et d'exploitation restantes

Le modèle produit est verrouillé. Restent à approuver avant mise en production :

1. le catalogue exact des événements, leur texte dans les quatre langues et les types
   qui déclenchent son ou haptique ;
2. la visibilité éventuelle du détail des membres derrière une `WardTeam` dans Watch ;
3. la politique de noms publics et de protection des mineurs ;
4. la fenêtre de grâce transactionnelle pour une réponse reçue avant `ends_at` mais
   validée juste après ;
5. qui possède le droit administratif d'annuler une session et comment l'action est
   auditée.

Ne sont plus ouverts : équipes `WardTeam` créées hors Live, somme brute, inscription
tardive, isolation des `QuizRun`, état `expired`, absence de présentateur, cadence
visuelle pouvant atteindre deux secondes et clôture automatique à une heure.
