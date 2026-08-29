# Moteur de défis Street multi-duels — plan produit et technique

Statut : implémentation, cutover destructif local et QA de référence réalisés  
Date : 2026-08-29  
Périmètre : acquisition par défi, duels asynchrones Street, `/jugar`, cérémonie, Hub et notifications  
Référence de qualité : `.agents/skills/noche-conseil/SKILL.md`

## 1. Vision

Le défi n'est pas une variante du quiz et un quiz n'appartient pas à un seul duel.

> Un duel est le nom technique d'un défi actif entre deux personnes. Un run terminé
> est une performance universelle qui peut alimenter plusieurs défis à la fois.

Le joueur peut simultanément :

- prendre une revanche amicale avec Carmen ;
- proposer son score à Pili ;
- attendre la réponse de Lucía ;
- apprendre en parallèle avec Miguel ;
- recevoir plusieurs nouveaux défis ;
- jouer le même pack qu'un ami ou un pack différent.

Le moteur doit rendre cette émulation amicale perceptible pendant le quiz et joyeuse
à sa sortie, sans transformer la question en dashboard ni donner l'impression d'un
combat.

Il doit également fermer une boucle virale complète :

```text
score fier
→ invitation personnelle
→ ouverture sur un nouvel appareil
→ première question sans détour
→ résultat social
→ nouveau joueur qui lance son propre défi
```

La revanche et les duels multiples créent de la rétention. La viralité n'existe que
si un destinataire extérieur devient joueur puis expéditeur avec assez peu de friction
pour que cette boucle se reproduise.

Références de design :

- **Words With Friends** pour la gestion claire de nombreuses parties asynchrones ;
- **Trivia Crack** pour la grammaire du quiz social ;
- **Duolingo Friends Quests** pour l'encouragement, la camaraderie et le retour doux.

Noche Live ne copie aucun de ces jeux. Il combine leur structure avec son **Campus
des Écritures**, une forêt elfique lumineuse, son aventure biblique et sa signature or.

### 1.1 Contrat émotionnel et vocabulaire

Le domaine Ruby et PostgreSQL peut conserver les concepts `DuelInvitation` et
`StreetDuel`, car ils décrivent proprement la mécanique. Le joueur, lui, ne doit
jamais entrer dans une arène.

Vocabulaire joueur :

- **Campus des Écritures** pour l'espace social ;
- **défi biblique** ou **défi amical** pour l'action ;
- **ami**, **invitation**, **a marqué 87**, **réponse attendue** ;
- **revanche amicale** seulement lorsque la relation précédente est déjà comprise.

Vocabulaire interdit dans les écrans : `arène`, `combat`, `frapper`, `écraser`,
`adversaire`, `rivalité`, `score à battre`. Le score reste comparable et le résultat
reste honnête, mais la mise en scène cherche : curiosité → complicité → effort →
encouragement → envie d'apprendre encore.

### 1.2 Contrat artistique « UI-safe »

Le décor de référence est un campus biblique construit dans une forêt elfique :
arbres anciens, passerelles en bois sculpté, pavillons d'étude, lumière céleste,
livres ouverts et groupes humains souriants. Aucun personnage n'est un elfe ;
l'adjectif décrit le paysage, pas les joueurs.

Une image spectaculaire mais recouverte par l'UI est invalide. Chaque artwork de
défi doit respecter dès sa génération :

- `0–10 %` de hauteur : calme, réservé au HUD ;
- `18–36 %` : visages amicaux lisibles, placés dans les tiers latéraux ;
- `28–62 %` au centre : corridor peu détaillé pour score, question et transitions ;
- `58–100 %` : zone sacrifiable, aucun visage, regard, main ou livre indispensable ;
- les regards relient les personnes entre elles ou accueillent le joueur, jamais une
  pose d'affrontement.

Le fond universel unique est interdit si les zones UI diffèrent. La cérémonie,
l'invitation froide et l'identité légère reçoivent chacune un cadrage ou une variante
validée. Le manifeste média stocke le point focal et l'`object-position` par surface ;
le recadrage CSS affine une composition correcte, il ne sauve pas une composition
incorrecte. Les captures 320, 390 et 430 px vérifient que chaque visage prioritaire
reste visible.

## 2. Décisions acquises

### 2.1 Les scores bruts sont comparables

Un score de `87` obtenu sur un pack peut être comparé à un score de `87` obtenu sur
un autre pack. Il n'existe donc :

- ni normalisation par pack ;
- ni coefficient de difficulté ;
- ni obligation de jouer le même pack ;
- ni rotation forcée de pack pendant une revanche.

Le pack reste important pour l'aventure, le décor et la mémoire du run, mais il ne
fait pas partie de la règle compétitive du duel.

### 2.2 Un joueur peut avoir N duels actifs

Il n'existe pas de `current_duel` produit. Les écrans et services manipulent toujours
une collection de défis actifs.

L'interface peut élire un **duel focal** pour raconter le moment, mais ce duel n'est
qu'une projection visuelle temporaire. Il n'a aucune exclusivité en base.

### 2.3 Un run peut servir plusieurs duels

À la fin d'un run, son score est proposé à tous les duels éligibles du joueur. Le
même `QuizRun` peut être référencé par plusieurs `StreetDuel`.

Exemple :

```text
RUN TERMINÉ : 87

Carmen     91  → défaite
Pili       76  → victoire
Lucía       …  → score posé, réponse attendue
Miguel     87  → égalité
Noa         …  → score posé, réponse attendue
```

### 2.4 PostgreSQL décide

Le navigateur ne décide jamais :

- quels duels sont éligibles ;
- quel run est engagé ;
- qui a gagné ;
- si une revanche existe ;
- si un résultat a déjà été appliqué.

Le serveur verrouille, écrit et résout. Turbo Streams et les notifications ne font
que distribuer cet état.

### 2.5 Une invitation n'est pas encore un duel

Un lien partagé à une personne encore inconnue n'est pas un défi actif. Il ne
doit pas créer un `StreetDuel` orphelin avec `opponent_person_id = nil`.

Le domaine sépare donc :

- `DuelInvitation`, enveloppe d'acquisition nommée ou partageable, réclamable une fois ;
- `StreetDuel`, compétition réelle entre deux personnes identifiées après acceptation.

Cette frontière garde la table des duels honnête, permet les accusés adaptés au canal
et empêche les liens jamais ouverts de polluer le Campus.

### 2.6 Partage pour acquérir, Push pour faire revenir

Un destinataire froid ne possède ni permission Push, ni installation, ni forcément
une ficha. Le premier contact repose donc sur un lien HTTPS partageable qui fonctionne
dans un navigateur ordinaire et les navigateurs intégrés de messagerie.

Le Push n'intervient qu'après une valeur vécue et une permission explicite. Il sert à
faire revenir un joueur connu ; il n'est jamais une dépendance du premier défi.

## 3. Règles produit proposées

Ces règles forment la base du plan. Les règles 3.1 à 3.4 sont figées au premier slice
de domaine ; les règles 3.5 à 3.7 le sont au gate viral avant migration de données.

### 3.1 Le prochain score est engagé, pas le meilleur score futur

Règle recommandée :

> Le premier run terminé après l'activation du duel verrouille la performance du
> joueur pour ce duel.

Un joueur ne peut pas rejouer indéfiniment pour remplacer un mauvais score. Une
revanche ouvre un nouveau duel ; elle ne réécrit pas l'ancien résultat.

Cette règle protège la tension, l'équité et la valeur émotionnelle d'une tentative.

### 3.2 Un seul duel actif par paire

Deux personnes peuvent avoir un historique illimité, mais au maximum un duel actif
entre elles. Une demande répétée ouvre le duel existant au lieu de créer des doublons.

Une revanche crée une nouvelle invitation reliée au duel terminé précédent, sans
choisir ni imposer de pack. Son acceptation crée le nouveau duel.

### 3.3 Frontière d'éligibilité d'un run

Règle recommandée : un duel compte pour un run si le duel était accepté avant
`QuizRun.opened_at`.

Conséquences :

- le joueur sait au départ combien de duels son run engage ;
- un défi reçu au milieu d'une question ne détourne pas silencieusement ce run ;
- le nouveau défi attend le prochain run ;
- un défi envoyé explicitement depuis une cérémonie peut attacher le run qui vient
  de finir, car le joueur choisit alors cette performance en connaissance de cause.

### 3.4 Les deux joueurs peuvent avancer dans n'importe quel ordre

Chaque côté engage sa prochaine performance éligible. Le duel se résout dès que les
deux côtés possèdent un score verrouillé.

Il n'existe pas de tour obligatoire :

- le challenger peut jouer en premier ;
- l'autre personne peut jouer en premier ;
- les deux peuvent finir presque simultanément ;
- plusieurs duels peuvent être résolus par le même run.

### 3.5 Un lien partagé réserve une seule place

Le MVP conserve le défi individuel : une invitation externe crée au maximum un
duel. La première réclamation valide et verrouillée gagne la place.

Si le lien a été transféré, déjà pris ou a expiré, l'écran n'aboutit jamais à une
impasse. Il explique sobrement l'état puis propose au visiteur de jouer et de lancer
son propre défi. Un futur mode de groupe devra être un produit explicite ; un même
token ne multiplie pas silencieusement les destinataires.

### 3.6 Le parcours froid ne traverse pas le Hub

Une ouverture externe doit montrer avant toute navigation :

```text
Carmen a marqué 87
Choisis le parcours qui te plaît
[ Apprendre avec elle ]
```

Après le CTA, aucune sélection de paroisse, installation, permission Push, boîte de
défis ou catalogue de packs ne précède la première question. Si une identité est
nécessaire, elle tient dans une étape légère et reprend automatiquement l'invitation.

Le moteur choisit un pack jouable par défaut ; « changer de pack » reste secondaire.
La liberté de pack ne devient pas une décision administrative imposée au nouvel arrivé.

### 3.7 La propagation suit le résultat

Une revanche prolonge une paire mais ne crée pas une nouvelle branche. Après son
premier résultat, un joueur acquis voit une prochaine envie claire : défier à son tour
une personne avec sa performance.

La projection serveur choisit un seul CTA or selon le contexte :

- nouvel invité ayant fini : `Défier quelqu'un` ;
- joueur dans une relation de défi établie : revanche ou prochain run pertinent ;
- les autres actions restent secondaires, jamais deux boutons or concurrents.

## 4. Cycles de vie

### 4.1 Invitation

```text
open → claimed          # crée le duel dans la même transaction
open → declined | expired | revoked

jalons externes : created_at → share_handoff_at → human_opened_at → claimed_at
jalons nommés   : created_at → delivered_at → seen_at → claimed_at
```

Une invitation nommée peut en plus recevoir `delivered_at` et `seen_at` via Noche.
Une invitation externe ne les invente jamais : la réussite de `navigator.share()`
signifie seulement que le système a pris en charge le partage. Les jalons sont des
accusés monotones et peuvent recevoir plusieurs événements diagnostics ; ils ne sont
pas les états métier de l'invitation.

### 4.2 Duel actif

```text
active
  → one_scored
  → resolved

active/one_scored → expired
resolved → rematch (nouvelle invitation reliée)
```

Les libellés d'interface restent des projections humaines :

| État serveur | Vue expéditeur | Vue ami invité |
|---|---|---|
| invitation nommée | Envoyé · reçu · vu | Accepter ou refuser |
| invitation externe | Partage prêt · lien ouvert · réclamé | Jouer maintenant |
| `active`, aucun score | Ton prochain run compte | Ton prochain run compte |
| `one_scored`, moi | Score posé · attend sa réponse | Ton prochain parcours compte |
| `one_scored`, autre | À toi de jouer | Attend ta réponse |
| `resolved` | Victoire, défaite ou égalité | Victoire, défaite ou égalité |
| invitation refusée | Défi refusé | Refusé |
| invitation/duel expiré | Expiré | Expiré |

Les accusés sont monotones. Ils enrichissent l'invitation ou le duel, mais ne
remplacent jamais leur cycle métier.

## 5. Modèle de données cible

### 5.1 `DuelInvitation`

L'invitation est l'autorité du passage entre partage et défi actif :

```text
challenger_person_id
recipient_person_id       nullable pour un lien externe
challenger_run_id         nullable
challenger_score          nullable, snapshot si défi depuis une cérémonie
acquisition_parent_invitation_id nullable, l'invitation ayant acquis l'expéditeur
rematch_of_duel_id        nullable
claimed_by_person_id      nullable
street_duel_id            nullable, écrit une seule fois
token_digest              unique, le token brut n'est pas stocké
status                    open | claimed | declined | expired | revoked
source / channel
share_handoff_at
human_opened_at
delivered_at / seen_at    uniquement pour un destinataire Noche nommé
claimed_at / declined_at / expires_at / revoked_at
created_at / updated_at
```

Principes :

- le token est opaque, signé ou comparé par digest, expirant et réclamable une fois ;
- les crawlers d'aperçu peuvent lire les métadonnées sans produire `human_opened` ;
- une ouverture humaine est attribuée par un signal après rendu visible, pas par le
  simple `GET` serveur ;
- la réclamation verrouille l'invitation et crée le duel dans une transaction ;
- un destinataire nommé ne peut être remplacé par une autre personne ;
- l'invitation ne possède jamais de `pack_id` compétitif ; le run conserve son pack ;
- refus, expiration et révocation restent hors du Campus des défis actifs.

### 5.2 `StreetDuel`

Le duel reste l'autorité de la relation :

```text
challenger_person_id
opponent_person_id
challenger_run_id      nullable
opponent_run_id        nullable
challenger_score       nullable, snapshot immuable
opponent_score         nullable, snapshot immuable
status                 active | one_scored | resolved | expired | archived
accepted_at
resolved_at
expires_at
rematch_of_id          nullable
origin_invitation_id
created_at / updated_at
```

Principes :

- les deux personnes sont obligatoires dès la création ;
- `pack_id` ne contraint plus le duel et doit être déprécié puis retiré ;
- les packs restent accessibles via les deux `QuizRun` pour l'affichage historique ;
- plusieurs duels peuvent référencer le même `QuizRun` ;
- une fois écrit sur un côté, le run et le score ne changent plus ;
- le résultat se déduit des deux snapshots bruts ;
- une contrainte empêche deux duels actifs pour la même paire non ordonnée.

### 5.3 `QuizRun`

`QuizRun` reste l'autorité de la performance personnelle :

- pack joué ;
- score brut ;
- réponses ;
- instant d'ouverture et de fin ;
- personne et appareil.

Le lien singulier `quiz_runs.street_duel_id` ne doit plus déterminer l'appartenance
du run. Il sera déprécié après migration, car il encode à tort « un run = un duel ».

### 5.4 Pourquoi conserver les snapshots de score

Le score du duel doit rester stable même si un run historique est archivé ou si le
calcul interne du quiz évolue. `challenger_score` et `opponent_score` représentent le
contrat compétitif figé ; les références de run conservent la preuve et le contexte.

## 6. Services métier

### 6.1 Créer une invitation

`Quizzes::DuelInvitationCreate.call` doit :

1. valider l'expéditeur, le destinataire éventuel et le périmètre social ;
2. réutiliser l'éventuel duel actif de la paire ;
3. créer une invitation nommée ou externe sans démarrer ni imposer un pack ;
4. attacher facultativement un run déjà terminé si l'envoi vient explicitement de
   sa cérémonie ;
5. produire un lien HTTPS absolu stable et ses métadonnées de partage ;
6. pour un destinataire nommé, émettre le signal temps réel puis le Push de secours ;
7. retourner une projection, jamais rediriger implicitement vers un pack précis.

Créer l'invitation ne crée ni `StreetDuel`, ni `QuizRun`. Un partage annulé peut laisser
une invitation courte durée, mais ne compte jamais comme un envoi réussi.

### 6.2 Ouvrir une invitation externe

`Quizzes::DuelInvitationScreen.call(token:, person:, source:)` doit :

1. résoudre le token sans exposer sa valeur stockée ;
2. rendre score, challenger et promesse avant toute création de profil ;
3. servir les balises Open Graph sans faire avancer l'état ;
4. distinguer disponible, déjà réclamée, expirée et révoquée ;
5. attribuer la source sans confondre crawler, rendu serveur et humain visible ;
6. conserver un jeton de reprise signé si une identité légère est nécessaire.

### 6.3 Réclamer ou accepter

`Quizzes::DuelInvitationClaim.call` verrouille l'invitation, vérifie la personne et
crée ou retrouve l'unique duel actif de la paire. Il n'appelle jamais `StartPack` dans
la transaction métier.

Après acceptation :

- si un run éligible est déjà explicitement fourni, il peut être engagé ;
- sinon le prochain run terminé comptera ;
- un joueur Noche connu peut revenir au Hub ou choisir « Jouer » ;
- un destinataire froid continue directement vers un pack jouable et la première
  question, sans détour par le Hub ;
- aucun pack n'est sélectionné au nom du duel.

### 6.4 Fan-out d'un run terminé

Nouveau service central :

```ruby
Quizzes::DuelRunFanout.call(run:)
```

Responsabilités :

1. refuser un run non terminé ou sans personne ;
2. sélectionner tous les duels actifs éligibles de la personne ;
3. verrouiller les lignes dans un ordre stable ;
4. remplir uniquement le côté encore vide ;
5. copier le score brut et référencer le même run ;
6. résoudre chaque duel qui possède alors deux scores ;
7. appliquer les deltas sociaux une seule fois ;
8. produire une collection d'impacts pour la cérémonie ;
9. diffuser les changements après commit ;
10. rester idempotent lors d'un retry ou d'un double callback.

Pseudo-code :

```text
finish run 87 for Pili
  lock all eligible active duels involving Pili
  for each duel where Pili has no committed run
    commit run + score 87 on Pili's side
    if other side already committed
      resolve duel
    else
      mark score waiting
  commit transaction
  broadcast one aggregate update + per-friend receipts
  return impacts[]
```

### 6.5 Résolution

`Quizzes::ChallengeResolve` devient une opération interne appelée par le fan-out.
Elle ne recherche plus un duel unique depuis `run.street_duel_id`.

La comparaison reste directe :

```text
mine > theirs  → victoire
mine < theirs  → défaite
mine == theirs → égalité
```

### 6.6 Projection du Campus

Nouveau service de lecture :

```ruby
Quizzes::DuelCampus.call(person:, run: nil)
```

Il produit :

- nombre de duels actifs ;
- duels éligibles pour le run courant ;
- ami focal ;
- amis visibles dans le rail ;
- événements récents à révéler ;
- résultats non vus ;
- victoires, défaites, égalités et attentes générées par un run fini.

Cette projection est la seule entrée des vues. Les partials ne recomposent pas les
règles à partir de requêtes dispersées.

## 7. Expérience pendant `/jugar`

### 7.1 Avant la première question

Si le run engage des duels, une entrée courte annonce :

```text
TON SCORE COMPTERA POUR 5 DÉFIS AMICAUX
```

Les portraits apparaissent brièvement puis se replient. Aucun écran d'acceptation,
aucune liste et aucune redirection ne coupe le lancement du quiz.

### 7.2 Rail du Campus

Le ruban de duel unique devient un rail compact :

```text
✦ 5 DÉFIS    [Carmen] [Pili] [Lucía] [+2]
```

Contraintes :

- au plus trois portraits nommés et un compteur `+N` ;
- aucune interaction nécessaire pendant la question ;
- même composant en Celestial Light et Dark ;
- contraste local sur le still, jamais de grand voile laiteux ;
- aucune collision avec HUD, timer, question ou actions ;
- texte auxiliaire ≥ `--type-min` et aucune cible tactile sous 44 px lorsqu'elle est
  interactive.

### 7.3 Duel focal

Le moteur élit le moment le plus intéressant selon cet ordre :

1. ami dont le score vient d'être rejoint ou dépassé ;
2. ami qui vient de passer devant ;
3. marge la plus faible ;
4. revanche active ;
5. nouveau défi ou nouvel accusé ;
6. ami ayant déjà posé un score ;
7. attente la plus ancienne.

Le duel focal peut changer sans modifier l'état métier.

### 7.4 Micro-événements

Les révélations apparaissent seulement à des respirations sûres, après une réponse
ou pendant la transition vers la question suivante :

- `TU REJOINS CARMEN À 87` ;
- `PILI EST À 3 POINTS` ;
- `REVANCHE AMICALE EN COURS` ;
- `3 AMIS ATTENDENT TON SCORE` ;
- `LUCÍA A TERMINÉ SON PARCOURS`.

Garde-fous :

- jamais plus d'une révélation par transition ;
- aucune interruption pendant la lecture ou le choix ;
- priorité à la réponse, au score et à la progression du quiz ;
- mouvement réduit respecté ;
- SFX nommé et haptique uniquement sur rapprochement ou résultat important ;
- aucune cacophonie pour cinq duels résolus simultanément.

### 7.5 Défis reçus pendant un run

Les nouveaux défis sont agrégés :

```text
3 NOUVEAUX DÉFIS
Ils compteront pour ton prochain run.
```

Ils ne s'attachent pas rétroactivement au run en cours. Le détail attend la sortie
du quiz ou l'ouverture volontaire du Campus.

## 8. Sortie du quiz

### 8.1 Deux temps, deux émotions

La sortie ne doit pas enterrer les duels sous le coffre ni noyer la réussite du run
dans une liste sociale.

Le flow recommandé :

```text
1. CÉRÉMONIE DU RUN
   score personnel → étoiles → feu → coffre → progression

2. VIE DU CAMPUS
   résultats multiples → attentes → amis → prochaine envie
```

Le deuxième temps existe seulement si le run a affecté au moins un duel ou si un
résultat non vu attend le joueur.

### 8.2 Écran dédié « État du Campus »

Le Campus est une étape dédiée du même overlay de cérémonie, ou une route dédiée
reconstructible après refresh. Elle ne doit pas être un encart sous la ligne de
flottaison.

Héros :

```text
TON SCORE REJOINT LE CAMPUS

2 amis derrière · 1 ami devant · 1 même score · 2 réponses attendues
```

Puis les défis amicaux sont révélés un par un :

```text
Carmen      87 — 91     CARMEN EST DEVANT
Pili        87 — 76     TU ES DEVANT
Lucía       87 — …      ON ATTEND LUCÍA
Miguel      87 — 87     MÊME SCORE
```

Chaque ligne contient :

- portraits et noms ;
- deux scores bruts ;
- résultat ou attente ;
- série face-à-face si elle change ;
- libellé revanche lorsque pertinent ;
- action secondaire de détail.

Une seule action primaire en or termine l'écran. Les revanches individuelles ne
deviennent pas N boutons dorés concurrents.

### 8.3 Ordre des révélations

1. retournement ou marge la plus faible ;
2. revanche résolue ;
3. mêmes scores ;
4. amis que le joueur devance ;
5. amis qui devancent le joueur ;
6. scores en attente.

Être derrière n'est jamais punitif : l'écran félicite l'effort et ouvre une prochaine
envie claire.

### 8.4 Refresh et retour ultérieur

L'écran doit être reconstructible depuis la base :

- un refresh ne rejoue pas les gains ;
- une révélation déjà vue peut être rendue sans animation longue ;
- les résultats non vus restent accessibles depuis le Hub ;
- le joueur peut ouvrir l'historique d'un défi précis.

## 9. Hub et boîte des défis

Le Hub ne choisit plus arbitrairement un duel unique. Il affiche une synthèse :

```text
CAMPUS DES ÉCRITURES
5 défis actifs · 2 nouvelles réponses
```

Ordre de priorité dans la boîte :

1. action requise : accepter ou jouer ;
2. résultat nouveau ;
3. ami ayant posé son score ;
4. mon score posé, réponse attendue ;
5. défis actifs sans score ;
6. historique terminé.

Chaque ligne doit répondre en moins de deux secondes :

- avec qui ;
- quel est l'état ;
- qui doit agir ;
- quel score est engagé ;
- quelle est l'unique action utile.

Ce n'est pas un tableau administratif. Le Campus garde portraits souriants, liens
visuels entre amis, bois sculpté, lumière dans les feuilles, métal or et profondeur de
scène.

## 10. Notifications et accusés

### 10.1 Agrégation

Une seule invitation peut être nommée : `Carmen t'invite à un défi biblique`.

Plusieurs événements proches sont agrégés :

- `3 nouveaux défis` ;
- `2 amis ont répondu` ;
- `Ton score rejoint 3 défis`.

Le système ne doit jamais empiler N grandes cartes au-dessus du jeu.

### 10.2 États de réception

Les accusés restent utiles, mais leur vocabulaire dépend du canal :

```text
invitation Noche nommée : envoyé → reçu → vu → accepté
lien externe             : partage prêt → lien ouvert → réclamé
```

`share_handoff` n'est jamais présenté comme `reçu`. Un rendu Open Graph ou un `GET`
serveur n'est jamais présenté comme `vu`. Les accusés vivent dans la boîte du Campus
et le détail de l'invitation ; le HUD du quiz n'affiche qu'un événement agrégé lorsque
cela mérite l'attention.

### 10.3 Priorité des canaux

1. signal temps réel si l'app est active ;
2. accusé de réception du signal ;
3. Push de secours si aucun accusé n'arrive ;
4. rappel unique si le duel reste réellement actionnable ;
5. aucune relance après refus, expiration ou score engagé.

## 11. Contrat de viralité

### 11.1 Deux portes d'entrée, un seul défi

Le moteur supporte deux acquisitions sans dupliquer le domaine :

| Entrée | Destinataire | Canal initial | Preuve disponible |
|---|---|---|---|
| défi Noche nommé | personne connue | temps réel puis Push | reçu, vu, accepté |
| défi externe | personne inconnue | partage natif, copie ou QR | handoff, ouverture humaine, claim |

Les deux produisent le même `StreetDuel` seulement après acceptation. Le quiz, le
fan-out et le Campus ignorent ensuite le canal d'origine, sauf pour choisir la prochaine
envie et mesurer l'acquisition.

### 11.2 Artefact de partage

Chaque invitation externe possède un contrat de présentation testable :

- URL HTTPS absolue, canonique, stable pendant sa durée de vie ;
- titre contenant le prénom du challenger et le score lorsqu'il existe ;
- promesse explicite : score comparable sur le pack de son choix ;
- image Open Graph légère, lisible dans WhatsApp/iMessage, sans donnée spirituelle
  sensible ni score inventé ;
- texte natif validé en es, pt-BR, en et fr ;
- fallback copie puis QR, sans masquer un échec derrière un faux succès ;
- source d'attribution bornée et signée, jamais une redirection ouverte.

Le message vend l'affrontement, pas Noche Live : `Carmen a marqué 87. Tu la bats ?`
Le nom du produit et le lien apportent la confiance sans devenir la phrase principale.

### 11.3 Budget de friction du destinataire froid

De l'ouverture humaine à la première question :

- un écran de promesse ;
- au plus deux décisions explicites, CTA compris ;
- aucune installation, permission Push ou sélection de paroisse ;
- aucune arrivée au Hub ;
- identité légère inline si indispensable, avec reprise automatique du token ;
- pack par défaut immédiatement jouable, changement secondaire ;
- score, ami et promesse toujours visibles avant l'action.

La médiane `human_opened → first_question_started` et son p90 sont des métriques de
sortie. Le spectacle ne peut jamais retarder artificiellement le CTA ou la question.

### 11.4 Propagation et prochaine envie

Le résultat d'un joueur acquis ferme puis rouvre la boucle :

```text
j'ai répondu
→ je découvre si j'ai battu Carmen
→ ma performance devient partageable
→ je défie quelqu'un à mon tour
```

Le CTA de propagation réutilise le run fini ; il ne démarre pas un pack et ne crée
pas un duel avant claim. La revanche reste visible comme relation secondaire quand
le CTA or est réservé à la propagation.

### 11.5 Démarrage à froid et densité sociale

Une Campus vide ne doit pas ressembler à une boîte administrative vide. Elle propose
un seul verbe adapté au contexte :

- partager son score récent ;
- scanner ou montrer un QR en présence ;
- défier une personne Noche récemment croisée dans le périmètre autorisé ;
- relancer un ancien défi sans créer de doublon.

Le MVP n'importe pas silencieusement le carnet d'adresses. WhatsApp, le partage natif,
le QR et les personnes déjà connues suffisent pour tester la densité sans dette de
consentement supplémentaire.

### 11.6 Confiance, sécurité et anti-spam

- plafond d'invitations actives et de relances par expéditeur/destinataire/période ;
- déduplication des invitations nommées et réutilisation du duel actif ;
- refus, blocage, mise en sourdine et révocation accessibles ;
- aucun rappel après refus, blocage, claim, expiration ou score engagé ;
- tokens non devinables, expirants, comparés par digest et réclamés atomiquement ;
- limitation des tentatives et journalisation des claims concurrents ;
- aucune récompense fondée sur le volume brut d'invitations ;
- récompenses sociales éventuelles uniquement après une interaction réciproque réelle ;
- suivi des refus, blocages et désabonnements comme garde-fous produit.

### 11.7 North star et coefficient viral

La north star du moteur est :

> proportion de destinataires acquis qui terminent leur premier duel puis lancent
> au moins une invitation attribuable dans les 24 heures.

Le coefficient est calculé par cohorte, jamais à partir du nombre brut de liens :

```text
K = invitations avec handoff par nouveau joueur activé
    × taux d'ouverture humaine unique
    × taux de démarrage de la première question
    × taux de complétion
```

Le temps médian entre deux générations d'expéditeurs est suivi avec `K`. Une boucle
positive mais trop lente peut échouer en production malgré une conversion correcte.

## 12. Direction artistique, mouvement et son

La chorégraphie détaillée, les classes d'état, les tokens de durée, les transitions
entre écrans et le contrat `prefers-reduced-motion` sont spécifiés dans
[STREET_MULTI_DUEL_MOTION_PLAN.md](STREET_MULTI_DUEL_MOTION_PLAN.md).

### 12.1 Émotion

- entrée : anticipation ;
- dépassement : surprise et fierté ;
- score posé : tension ;
- révélation multiple : puissance ;
- revanche : envie immédiate de revenir ;
- ouverture froide : défi personnel, jamais publicité ;
- propagation : fierté de transformer son score en invitation.

### 12.2 Composition

- le quiz conserve le still et sa question comme héros ;
- le rail du Campus est un halo social secondaire ;
- l'écran final devient une cour de tournoi, pas une liste blanche ;
- l'or marque le score, le vainqueur et l'unique CTA ;
- les titres restent en encre sur Light et crème sur Dark.

### 12.3 Mouvement

- entrée brève des portraits au début du run ;
- dépassement latéral ou passage de couronne ;
- résultats révélés séquentiellement, maximum 2,5 secondes avant contrôle joueur ;
- mode réduit : apparition directe et changement de contraste sans translation ;
- aucune animation bloquante avant la lecture du résultat.

### 12.4 Son

Créer ou réutiliser des cues nommés :

- `duel_campus_enter` ;
- `duel_overtake` ;
- `duel_score_locked` ;
- `duel_multi_resolve` ;
- `duel_rematch`.

Une résolution multiple joue un seul cue orchestré, jamais un son par duel.

### 12.5 Gate de mockups avant développement

Aucun développement d'interface ne commence avant validation des écrans maîtres,
des états de composants et des storyboards de mouvement ci-dessous. Les feuilles de
partage iOS/Android appartiennent au système : Noche ne les redessine pas. Les mockups
couvrent le moment avant leur ouverture, l'aperçu du lien et le retour dans le jeu.

#### Écrans maîtres

| ID | Écran à mockuper | Décision à valider | Variantes obligatoires |
|---|---|---|---|
| M01 | Cérémonie expéditeur · transformer le score en défi | le score est fier et partageable, un seul CTA or | run avec 0, 1 et N défis impactés |
| M02 | Préparation du partage | texte, destinataire libre, partage natif, copie et QR | Web Share disponible/absent |
| M03 | Aperçu du lien dans WhatsApp/iMessage | confiance, prénom, score, promesse et artwork lisibles | es, pt-BR, en, fr ; score présent/absent |
| M04 | Landing froide · invitation disponible | comprendre ami, score et `Relever le défi` sans scroll | aucun compte, 390×844, Light/Dark depuis artwork |
| M05 | Identité légère inline | créer une ficha sans perdre l'enjeu ni le token | clavier ouvert, validation, erreur et retour |
| M06 | Invitation nommée pour joueur Noche | accepter/refuser sans dupliquer la landing froide | nouveau défi et revanche |
| M07 | Invitation indisponible | éviter l'écran mort | prise, expirée, révoquée, bloquée, erreur réseau |
| M08 | Hub · Campus vide | donner envie du premier défi sans dashboard | score récent disponible/absent |
| M09 | Hub · synthèse du Campus | comprendre `5 défis actifs · 2 réponses` en deux secondes | 1, 5 et 10 défis |
| M10 | Boîte des défis | priorité d'action, séparation invitation/duel/résultat | nommé/externe, lu/non lu, attente/résolu |
| M11 | Détail d'un défi amical | histoire, scores, accusés et unique action utile | actif, attente, résultat, revanche |
| M12 | Entrée `/jugar` avec N défis | anticipation brève avant la question | 1, 5 et 10 défis ; `+N` |
| M13 | Question avec rail replié | camaraderie perceptible sans voler le QCM | ami focal, aucun défi focal, petit écran |
| M14 | Réponse réglée + croisement de scores | faire sentir le rapprochement pendant une respiration sûre | rejoint/passe devant/ami devant/même score |
| M15 | Nouveau défi reçu pendant le run | signal agrégé au-dessus du dock | un défi, trois défis, dock et clavier/safe area |
| M16 | Changement d'ami focal | hiérarchie entre focal et autres amis | score arrivé, ami prioritaire, `+N` |
| M17 | Cérémonie personnelle | célébrer le run avant l'impact social | accomplissement sobre, score faible/fort |
| M18 | Entrée de l'écran « État du Campus » | score commun, résumé et contrôle immédiat | un résultat et résultats non vus |
| M19 | Campus multi-résultats | rendre 5 impacts lisibles sans dashboard ni scroll initial | devant, derrière, même score et attente mêlés |
| M20 | Planche des états de résultat | grammaire cohérente et non punitive | devant, derrière, même score, attente, déjà vu |
| M21 | Résultat d'un joueur nouvellement acquis | propagation comme prochain désir | CTA or `Inviter un ami`, revanche secondaire |
| M22 | Résultat d'un défi établi | revanche amicale ou prochain run comme prochain désir | devant/derrière/même score ; même/autre pack libre |
| M23 | Signal temps réel et Push de secours | visibilité au-dessus du dock et confidentialité | app active, arrière-plan, notification agrégée |
| M24 | Timeline d'accusés | honnêteté du canal | Noche : envoyé/reçu/vu/accepté ; externe : handoff/ouvert/claim |
| M25 | Contrôles de confiance | refuser sans culpabilité et stopper le spam | refuser, bloquer, sourdine, révoquer, limite atteinte |

#### Artworks à valider avant le chrome

Le chrome ne peut pas valider seul une direction artistique. Pour chaque écran maître
qui montre un décor, la revue reçoit : artwork nu, overlay des safe zones, puis chrome
final à 320, 390 et 430 px.

- A01 · master forêt elfique du Campus, sans UI ;
- A02 · cérémonie : visages hauts latéraux, score libre au centre ;
- A03 · invitation froide : amis lisibles avant le premier CTA, corridor central libre ;
- A04 · identité légère : groupe visible au-dessus de la sheet, aucun visage dessous ;
- A05 · question : recadrage par pack, l'art biblique reste le héros et le Campus un
  halo social secondaire.

Chaque fichier porte ses coordonnées focales et sa zone sacrifiable. Un simple
`background-position` différent n'est pas accepté comme solution si un visage reste
derrière le HUD, le médaillon ou la sheet.

#### Feuille de composants et états

Les écrans ne suffisent pas. Une planche unique valide avant CSS :

- héros d'invitation : portraits, symbole de lien, score métal, promesse et badge de canal ;
- portrait ami : focal, ahead, behind, same-score, waiting, unread et blocked ;
- rail du Campus : expanded, collapsed, hidden, `+N` et aucun défi ;
- ligne résultat : ahead, behind, same-score, waiting, seen/unseen ;
- timeline d'accusés nommée et externe ;
- CTA contextuel : relever, voir le Campus, inviter un ami, revanche amicale, état loading/disabled ;
- partage : idle, press, pending, handoff natif, copié, annulé, erreur ;
- QR et URL de secours ;
- signal au-dessus du dock : seul, agrégé et dismiss ;
- états skeleton, offline, retry, taken, expired, revoked et rate-limited ;
- contrôles refuser, bloquer, sourdine et révocation ;
- live regions et libellés accessibles associés aux changements visuels.

#### Storyboards de mouvement à valider

Chaque storyboard montre départ, battement clé, état final et version mouvement réduit :

1. ouverture froide de l'invitation ;
2. claim → identité légère → première question ;
3. entrée du run avec 1, 5 et 10 duels ;
4. défi entrant agrégé et changement d'ami focal ;
5. rapprochement / ami qui pose son score ;
6. cérémonie personnelle → état du Campus ;
7. révélation multi-résultats avec skip ;
8. résultat acquis → CTA de propagation ;
9. retour d'une feuille de partage : handoff, copie, annulation, erreur ;
10. progression d'accusés nommée/externe et invitation prise/expirée.

#### Matrice de validation visuelle

- tous les écrans maîtres : 390×844 et contenu critique au-dessus du dock ;
- M04, M09, M13, M19 et M21 : iPad portrait/paysage et desktop centré ;
- M03, M04, M10, M19 et M21 : quatre langues avec cas de texte long ;
- M04, M13, M19 et M21 : taille de texte augmentée, contraste et usage à une main ;
- tous les storyboards : mouvement normal et `prefers-reduced-motion` ;
- Light/Dark proviennent de l'artwork, jamais d'un toggle utilisateur ;
- une seule action or par écran et verbe compris en moins de deux secondes.

Le gate est validé lorsque le parcours cliquable M01 → M04 → M05 → M12 → M17 →
M18 → M21 fonctionne sans explication orale, puis lorsque composants et dix
storyboards sont approuvés. Les variantes secondaires peuvent ensuite être dérivées
pendant l'implémentation sans changer la hiérarchie validée.

## 13. Migration depuis l'implémentation actuelle

L'implémentation actuelle contient plusieurs hypothèses désormais invalides. Elles
doivent être retirées explicitement, pas contournées par de nouveaux cas spéciaux.

### 13.1 Stratégie de remplacement net

Il n'y aura pas deux moteurs de défi, pas de feature flag permanent, pas de double
écriture et pas de branche `legacy` conservée « au cas où ».

Chaque slice doit respecter cette règle :

```text
nouveau comportement testé
→ remplacement des appels
→ suppression du code remplacé
→ suppression des specs devenues fausses
→ suite complète verte
```

Le code legacy est supprimé dans le même changement que son remplacement. Il n'est
pas supprimé seul avant que le nouveau chemin soit fonctionnel, car la branche
principale doit rester jouable à chaque étape.

Une colonne historique peut survivre un déploiement supplémentaire pour permettre
une migration PostgreSQL sûre. Aucun code applicatif mort ne doit cependant continuer
à la lire ou à l'écrire.

Règle permanente de maintenance : toute intervention dans ce domaine inclut un audit
du voisinage modifié. Lorsqu'un chemin est confirmé sans appelant de production, il
est supprimé dans la même slice avec toute sa chaîne morte — Ruby, ERB, Stimulus,
CSS, clés i18n, fixtures et specs. Cet audit reste borné au domaine touché afin de ne
pas mélanger un grand nettoyage opportuniste à une livraison fonctionnelle. La preuve
de sortie est constituée de recherches de références vides, des tests du successeur,
de la compilation des assets et, pour une surface UI, d'un contrôle navigateur.

### 13.2 Manifeste de suppression du code legacy

- supprimer `app/services/quizzes/challenge_pack.rb` ;
- supprimer toute validation interdisant une revanche sur le même pack ;
- supprimer les paramètres `pack_id` et `pack` du contrat HTTP d'une revanche ;
- supprimer les branches de compatibilité `source=result-rematch` ;
- supprimer les copies `Nouveau pack`, `Prochain pack` et leurs quatre traductions ;
- remplacer `ChallengeCreate` et `ChallengeAccept` par les services d'invitation puis
  supprimer leurs chemins mono-duel ;
- retirer `StartPack` de la création et de l'acceptation métier ;
- supprimer la création de `StreetDuel` avec `opponent_person_id` nul après migration vers
  `DuelInvitation` ;
- retirer `pending`, `challenger_done`, `opponent_done`, `declined` et les autres états
  qui mélangent invitation et duel après leur traduction vers le nouveau cycle ;
- remplacer `invite_share_completed` par l'événement honnête `invite_share_handoff`,
  migrer l'historique utile puis supprimer l'ancien nom et ses assertions ;
- supprimer tout code qui transforme une feuille de partage réussie en `delivered_at` ;
- remplacer le token brut de `StreetDuel` et la session `pending_duel_token` par le
  token d'invitation digéré et une reprise signée, puis supprimer les anciens chemins ;
- supprimer la sélection d'un duel unique dans `StreetQuiz` et l'overlay `/jugar` ;
- supprimer `_street_duel_ribbon.html.erb` après introduction du rail du Campus ;
- remplacer `_duel_result.html.erb` par le résultat du Campus multi-duels, puis supprimer
  le partial mono-duel ;
- supprimer la recherche de résolution par un unique `QuizRun.street_duel_id` ;
- supprimer les helpers, scopes et branches de contrôleur devenus sans appel ;
- supprimer les règles CSS `.street-duel-*` remplacées, y compris les doublons et le
  bloc de verrouillage final de cascade ;
- supprimer les contrôleurs Stimulus mono-duel remplacés par l'orchestrateur du Campus ;
- retirer les colonnes `street_duels.pack_id` et `quiz_runs.street_duel_id` après le
  cutover de données, sans laisser de lecture de compatibilité dans l'application ;
- retirer de `StreetDuel` les colonnes d'accusé déplacées vers `DuelInvitation` après
  migration et vérification des anciens liens.

### 13.3 À conserver et généraliser

- destinataire nommé ;
- landing de défi sur nouvel appareil et création de ficha légère ;
- partage natif, copie, URL absolue et attribution de source ;
- funnel `ViralEvent`, statistiques d'acquisition et continuité après fusion de ficha ;
- accusés envoyé/reçu/vu/accepté pour une invitation Noche nommée ;
- ouverture humaine/claim pour une invitation externe, sans faux accusé de livraison ;
- signal au-dessus du dock et fallback Push ;
- filiation `rematch_of_id` ;
- snapshots de scores ;
- Turbo Streams par personne ;
- états victoire/défaite/égalité ;
- tokens Light/Dark, mouvement réduit et SFX nommés.

### 13.4 Suppression et réécriture des specs legacy

Les tests ne doivent pas documenter simultanément deux comportements incompatibles.

À supprimer :

- `test/services/quizzes/challenge_pack_test.rb` ;
- les specs qui exigent un pack identique pour les deux joueurs ;
- les specs qui exigent un pack différent pour une revanche ;
- les specs qui supposent un seul duel par run ;
- les specs qui attendent le démarrage automatique d'un pack à l'acceptation ;
- les assertions de ruban mono-duel et de carte résultat unique ;
- les fixtures créées uniquement pour les statuts ou associations supprimés ;
- les captures visuelles qui représentent l'ancien ruban ou le CTA « nouveau pack ».

Ne sont jamais supprimés comme « legacy » sans remplacement équivalent :

- les tests d'ouverture d'un lien partagé sur un nouvel appareil ;
- les tests du score de l'ami avant création de ficha ;
- les tests d'attribution source → ouverture → inscription → complétion → retour J+7 ;
- les fallbacks partage natif/copie et l'annulation non comptée comme handoff ;
- les tests de conservation d'attribution lors d'une fusion de personnes.

À réécrire :

- création, ouverture et claim autour de `DuelInvitation` ;
- concurrence de deux claims, lien pris/expiré/révoqué et reprise après ficha légère ;
- distinction crawler/rendu serveur/ouverture humaine ;
- partage externe mesuré comme handoff et jamais comme livraison ;
- fin de run autour du fan-out vers N duels ;
- cérémonie autour d'une collection d'impacts ;
- notifications autour d'événements agrégés ;
- tests navigateur autour du rail, de l'écran du Campus et des transitions réduites.

Règles de propreté :

- aucun test `skip` pour maintenir artificiellement le legacy ;
- aucun fichier renommé `_legacy_test.rb` ;
- aucun helper de fixture conservé sans appel ;
- aucun sélecteur CSS mort uniquement pour faire passer une ancienne capture ;
- après chaque slice, rechercher les constantes, routes, clés i18n, partials, classes
  Stimulus et sélecteurs supprimés ; zéro référence restante est le critère de sortie.

### 13.5 Migration de données

1. créer `duel_invitations` et les index d'unicité/expiration sans changer les lectures ;
2. convertir les défis sans `opponent_person_id` et les défis nommés non acceptés en invitations,
   en préservant token, score, run, source et timestamps exploitables ;
3. conserver les URLs historiques via un résolveur qui pointe vers l'invitation migrée,
   sans maintenir l'ancien moteur métier ;
4. backfiller les snapshots manquants depuis les runs finis ;
5. calculer une clé de paire non ordonnée pour l'unicité active ;
6. détecter et résoudre les doublons actifs avant l'ajout de la contrainte ;
7. rendre les deux personnes obligatoires sur chaque nouveau `StreetDuel` ;
8. permettre à plusieurs duels de référencer le même `QuizRun` ;
9. migrer `invite_share_completed` vers `invite_share_handoff` sans réinterpréter
   rétroactivement un handoff comme une livraison ;
10. déployer le nouveau code sans lecture métier de `street_duels.pack_id`, du token
    brut historique ni de `quiz_runs.street_duel_id` ;
11. vérifier en production les anciens liens, les claims et l'attribution ;
12. supprimer les colonnes et états historiques dans la migration de contraction ;
13. conserver les invitations utiles à l'attribution selon une durée de rétention
    documentée, puis anonymiser les propriétés qui ne sont plus nécessaires.

Le déploiement peut être expand/contract au niveau du schéma pour ne pas casser une
instance encore en vol. Le code effectue un cutover unique : aucune double lecture,
aucune double écriture et aucun moteur de secours.

## 14. Plan d'exécution

### Phase −1 — Viral Growth Contract

- figer les règles 3.5 à 3.7 et le budget de friction 11.3 ;
- produire et faire valider le gate de mockups 12.5 avant tout développement UI ;
- écrire les deux parcours complets : destinataire Noche nommé et destinataire froid ;
- décider les sémantiques handoff/ouverture/claim et le comportement pris/expiré ;
- figer l'artefact de partage dans les quatre langues ;
- définir les événements, identifiants de cohorte, garde-fous et requêtes de `K` ;
- faire un test chronométré sur deux téléphones via WhatsApp avant le domaine final.

**Sortie :** un lien de prototype mène un nouveau destinataire au premier verbe sans
Hub, installation, Push ou faux accusé, et le funnel est calculable de bout en bout.

### Phase 0 — Contrat et sécurité de migration

- figer les règles 3.1 à 3.4 ;
- écrire les tests de comportement avant modification ;
- classifier chaque élément existant : legacy mono-duel à supprimer, invariant viral
  à généraliser ou historique de données à migrer ;
- documenter les anciennes hypothèses comme superseded ;
- dresser l'inventaire exact du code et des specs à supprimer ou réécrire ;
- préparer les migrations PostgreSQL expand/contract sans chemin applicatif double.

**Sortie :** les tests décrivent invitations, N duels, packs différents, run partagé
et les invariants viraux qui ne doivent pas disparaître.

### Phase 1 — Invitations et domaine multi-duels

- créer `DuelInvitation`, ses tokens digérés et son claim transactionnel ;
- migrer invitations externes, invitations nommées et anciens liens ;
- rendre les deux personnes obligatoires sur un nouveau `StreetDuel` ;
- retirer le pack du contrat de création/acceptation ;
- créer `DuelRunFanout` ;
- rendre `ChallengeResolve` multi-duels et idempotent ;
- ajouter l'unicité active par paire ;
- préserver historique, attribution et revanches ;
- supprimer `ChallengePack`, les branches pack et états invitation du duel legacy.

**Sortie :** le claim crée un seul défi actif réel et un run peut résoudre plusieurs
duels concurrents en une transaction.

### Phase 2 — Projection du Campus

- créer `DuelCampus` ;
- centraliser ordre, duel focal, compteurs, événements et prochaine envie ;
- exposer une représentation stable à Turbo et aux vues ;
- séparer invitations, duels actifs et résultats non vus.

**Sortie :** Hub, quiz et cérémonie lisent la même vérité projetée sans confondre une
invitation partagée avec un duel actif.

### Phase 3 — Acquisition froide et partage

- construire la landing ami/score/CTA et les états pris/expiré/révoqué ;
- préserver l'invitation à travers la ficha légère puis ouvrir directement `/jugar` ;
- choisir un pack jouable par défaut sans imposer le pack du challenger ;
- générer URL, Open Graph, texte natif, copie et QR ;
- exclure les crawlers de `human_opened` et renommer le succès en `share_handoff` ;
- vérifier WhatsApp/iMessage et leurs navigateurs intégrés sur appareils physiques ;
- supprimer l'ancienne landing et ses chemins mono-duel après parité fonctionnelle.

**Sortie :** un destinataire sans session voit l'enjeu, réclame le défi et atteint la
première question avec au plus deux décisions explicites.

### Phase 4 — Campus pendant le quiz

- remplacer le ruban singulier par le rail multi-duels ;
- annoncer le nombre de duels engagés ;
- ajouter dépassements et attentes aux respirations sûres ;
- agréger les défis reçus pendant le run ;
- vérifier absence de collision à 390, 768, 1 024 et 1 440 px ;
- supprimer ruban, contrôleur, CSS et captures mono-duel.

**Sortie :** le joueur ressent la compétition sans perdre la question.

### Phase 5 — Sortie, Campus et propagation

- séparer cérémonie personnelle et impact social ;
- construire le résumé multi-résultats et révéler par importance émotionnelle ;
- choisir le CTA or via `next_desire` : propagation pour un nouvel acquis, revanche
  ou prochain run pour un défi établi ;
- réutiliser le run fini pour l'invitation sortante sans créer un duel prématuré ;
- rendre l'écran reconstructible après refresh ;
- supprimer le résultat mono-duel et toutes ses assertions visuelles.

**Sortie :** aucun résultat n'est sous la ligne de flottaison et un nouveau joueur peut
relancer la boucle virale depuis sa fierté, pas depuis un menu.

### Phase 6 — Hub, notifications et confiance

- remplacer la tuile mono-duel par la synthèse du Campus ;
- donner un verbe désirable à l'état vide ;
- trier invitations et duels selon l'action requise ;
- agréger signaux et Push ;
- conserver les accusés exacts par canal ;
- ajouter limites, refus, blocage, révocation, sourdine et relance unique ;
- vérifier appareils partagés et changements de ficha.

**Sortie :** N duels restent compréhensibles sans spam et aucun handoff externe n'est
présenté comme une livraison.

### Phase 7 — Instrumentation et pilote viral

- valider le funnel par une A/A avant d'interpréter les conversions ;
- déployer par cohortes denses de joueurs qui se connaissent ;
- comparer source, OS, langue, nouveau/existant et pack d'entrée ;
- tester copie, preview, CTA, identité légère et moment de propagation ;
- suivre `K`, temps de cycle, refus, blocages et désabonnements ;
- conserver un groupe témoin lorsque l'expérience le permet ;
- ne généraliser qu'après identification du principal point de chute.

**Sortie :** le pilote distingue un problème de partage, d'ouverture, de démarrage,
de complétion ou de propagation au lieu de conclure seulement « la viralité échoue ».

### Phase 8 — Spectacle et validation terrain

- finaliser VFX, haptique et cues sonores ;
- valider es, pt-BR, en et fr ;
- tester Light et Dark depuis les artworks ;
- jouer avec deux, cinq puis dix duels actifs ;
- tester deux téléphones physiques : premier plan, arrière-plan et écran verrouillé ;
- effectuer la revue Conseil complète, aucun score sous 8/10 ;
- exécuter un audit final de références mortes dans Ruby, ERB, Stimulus, CSS, i18n,
  routes, fixtures, tests et documentation.

**Sortie :** boucle jouable, lisible, robuste, mesurable et désirable sur appareils réels.

## 15. Matrice de tests obligatoire

### Invitation et acquisition

- créer une invitation externe ne crée ni duel ni run ;
- créer une invitation nommée respecte le périmètre social ;
- token falsifié, expiré ou révoqué refusé sans fuite d'information ;
- deux claims simultanés créent exactement un duel et un seul gagnant ;
- le destinataire nommé ne peut pas être remplacé par une autre personne ;
- un lien pris ou expiré propose une prochaine action et jamais un écran mort ;
- un crawler Open Graph rend titre/image sans `human_opened`, `seen_at` ni claim ;
- un navigateur visible enregistre au plus une ouverture humaine attribuée ;
- une fiche légère reprend le token et mène directement à la première question ;
- aucun Hub, choix de paroisse, installation ou permission Push dans le parcours froid ;
- partage annulé : aucun `share_handoff` ; partage natif/copie réussis : un seul handoff ;
- le handoff externe ne produit jamais `delivered_at` ou `seen_at` ;
- URL et aperçu contiennent le bon prénom, le bon score et aucune donnée sensible ;
- fallback copie et QR fonctionnent sans Web Share API ;
- l'ancien lien migré ouvre la nouvelle invitation sans appeler le moteur legacy ;
- après le premier résultat acquis, le CTA de propagation crée une invitation avec le
  run fini et aucun duel prématuré.

### Domaine

- un run sans duel ne change rien ;
- un run alimente un duel ;
- un run alimente cinq duels ;
- les cinq duels peuvent concerner des packs identiques ou différents ;
- le même `QuizRun` est référencé par plusieurs duels ;
- un côté déjà rempli n'est jamais remplacé ;
- deux fins simultanées résolvent une seule fois ;
- un retry du job ne double ni delta, ni récompense, ni notification ;
- une revanche accepte le même pack ou un pack différent ;
- un nouveau défi reçu en milieu de run attend le run suivant ;
- un défi créé depuis la cérémonie peut engager explicitement le run fini ;
- une paire ne possède qu'un duel actif ;
- expiration et archive excluent le fan-out ; le refus reste un état d'invitation.

### Projection et UI

- duel focal déterministe ;
- trois portraits maximum puis `+N` ;
- événements agrégés lorsque plusieurs duels changent ;
- aucun débordement horizontal ;
- aucune collision HUD/timer/question/dock ;
- résultats visibles sans scroll initial dans l'étape du Campus ;
- une seule action primaire ;
- landing froide compréhensible en moins de deux secondes ;
- ami, score et `Relever le défi` visibles sans scroll à 390×844 ;
- état vide du Campus avec un verbe social, sans dashboard ;
- état mouvement réduit complet ;
- contraste AA minimum et texte auxiliaire au plancher Noche ;
- parité es, pt-BR, en et fr.

### Notifications

- signal temps réel accusé : aucun Push de secours ;
- signal non accusé : un seul Push ;
- plusieurs défis : notification agrégée ;
- aucun rappel après score engagé ;
- refus, blocage et sourdine annulent toute relance ;
- clic profond vers l'invitation, le Campus ou le duel exact ;
- Push absent du parcours d'acquisition froide.

### Système

- scénario avec cinq amis et trois résultats en une cérémonie ;
- revanche sur le même pack ;
- revanche sur un autre pack ;
- refresh avant et après la révélation ;
- deux fichas homonymes sur un appareil partagé ;
- WhatsApp et iMessage : application installée/non installée, navigateur intégré puis
  navigateur système, cookies autorisés/refusés et navigation privée ;
- préchargement Open Graph puis véritable ouverture sur un autre appareil ;
- lien transféré après claim et lien ouvert simultanément sur deux appareils ;
- reprise hors ligne puis synchronisation ;
- captures 390×844, iPad portrait/paysage et desktop.

## 16. Observabilité produit

### 16.1 Taxonomie d'événements

```text
invite_prompt_seen
duel_invitation_created
invite_share_opened
invite_share_handoff
invite_link_rendered          # diagnostic, inclut crawlers, jamais conversion
invite_human_opened
invite_claimed
invitee_profile_created
first_question_started
duel_result_viewed
invitee_first_outbound_invite
pair_returned_d7

named_invite_delivered
named_invite_seen
duel_activated
duel_run_committed
duel_resolved
duel_campus_viewed
duel_rematch_started
multi_duel_run_completed
```

`invite_share_handoff` signifie uniquement que la feuille native ou la copie a réussi.
Il ne signifie ni message envoyé, ni reçu, ni lu. `invite_human_opened` nécessite un
document visible et une déduplication ; `invite_link_rendered` sert à mesurer les bots
et préchargements sans entrer dans le funnel humain.

Chaque événement viral porte au minimum :

- `invitation_id`, génération et `acquisition_parent_invitation_id` ;
- personne lorsqu'elle est connue, sinon digest d'appareil pseudonyme et borné ;
- source, canal, locale, plateforme et nouveau/existant ;
- timestamps serveur et client nécessaires au diagnostic, sans contenu du message ni
  identifiant brut du destinataire externe ;
- version de l'expérience et variante de test.

### 16.2 Funnel et métriques

Acquisition :

- prompt → ouverture de partage → handoff ;
- handoff → ouverture humaine unique ;
- ouverture humaine → claim ;
- claim → première question, médiane et p90 ;
- première question → complétion ;
- complétion → résultat vu ;
- résultat vu → première invitation sortante sous 24 h ;
- coût en refus, blocages, sourdines et désabonnements.

Coefficient viral :

```text
activation = destinataire ayant terminé son premier duel

K = nombre moyen de handoffs uniques produits par un nouvel activé
    × probabilité qu'un handoff produise un nouvel activé
```

Suivre aussi le temps médian et p90 entre l'activation d'une génération et celle de
la suivante. `K` est segmenté par source, canal, OS, langue, paroisse, variante,
nouveau/existant et présence ou non d'un score déjà posé.

Engagement et rétention :

- taux d'acceptation ;
- délai invitation → acceptation ;
- délai acceptation → premier score ;
- nombre moyen de duels impactés par run ;
- distribution 1 / 2–3 / 4–6 / 7+ duels actifs ;
- taux de consultation de l'écran du Campus ;
- taux de revanche après victoire et après défaite ;
- temps écran du Campus → prochain run ;
- taux de Push de secours évité par accusé temps réel.

### 16.3 Lecture des échecs en production

| Symptôme | Hypothèse prioritaire |
|---|---|
| handoffs élevés, ouvertures humaines faibles | texte, aperçu, confiance ou canal |
| ouvertures élevées, claims faibles | promesse ou CTA de landing |
| claims élevés, premières questions faibles | friction ficha/pack/Hub |
| débuts élevés, complétions faibles | durée, difficulté ou tension du quiz |
| complétions élevées, propagation faible | résultat sans fierté ni prochaine envie |
| conversion forte seulement entre membres existants | rétention sociale, pas acquisition |
| ouvertures anormalement élevées sans activité | crawlers comptés comme humains |
| blocages/désabonnements en hausse | fréquence ou ciblage abusif |

### 16.4 Qualité de mesure et expérimentation

- valider les décomptes par une A/A et des parcours synthétiques avant tout A/B ;
- dédupliquer par invitation et étape sans effacer les tentatives utiles au diagnostic ;
- documenter fenêtre d'attribution, fuseau, rétention et règles de nouveau joueur ;
- vérifier la continuité après création/fusion de ficha et changement d'appareil ;
- conserver un dictionnaire d'événements versionné et supprimer les anciens noms après
  migration, sans double émission permanente ;
- déployer les variantes sur des cohortes denses et suffisamment comparables ;
- ne jamais optimiser le volume d'invitations sans ses garde-fous de confiance.

Les métriques mesurent acquisition, désir de rejouer et clarté sociale, pas seulement
le nombre de lignes ou de feuilles de partage ouvertes.

## 17. Hors périmètre

- matchmaking public contre des inconnus ;
- mises, monnaie payante ou perte de progression ;
- équilibrage par pack ;
- duel synchrone avec présence obligatoire ;
- chat libre entre joueurs ;
- mode de défi de groupe où un lien crée plusieurs duels ;
- import silencieux ou synchronisation complète du carnet d'adresses ;
- récompense monétaire ou progression achetée par volume d'invitations ;
- classement global fondé uniquement sur le nombre de défis envoyés ;
- remplacement de la progression Street ou de la Noche Live du vendredi.

## 18. Critères d'acceptation finaux

### 18.1 Livraison produit et technique

La refonte est livrable seulement si :

- une invitation non réclamée n'est jamais comptée comme duel actif ;
- deux claims concurrents ne peuvent créer qu'un seul duel ;
- un destinataire froid voit ami, score, promesse et CTA sans scroll ;
- il atteint la première question avec au plus deux décisions, sans Hub, paroisse,
  installation ou Push ;
- un crawler de preview ne produit aucun accusé humain ;
- un handoff externe n'est jamais présenté comme reçu ou lu ;
- les liens pris, expirés ou révoqués n'aboutissent jamais à un écran mort ;
- un joueur peut comprendre ses cinq duels actifs en moins de deux secondes ;
- un même run résout correctement plusieurs duels sur des packs différents ;
- aucune revanche n'impose un pack ;
- le quiz raconte la compétition sans gêner la lecture ni le choix ;
- la sortie révèle toutes les conséquences sociales avant de rendre le contrôle ;
- un résultat non vu reste reconstructible et accessible ;
- le premier résultat d'un joueur acquis propose une propagation avec un seul CTA or ;
- les notifications sont agrégées et ne se cachent jamais sous le dock ;
- les états reçu/vu/accepté restent honnêtes ;
- refresh, retry et concurrence ne dupliquent aucun résultat ;
- le funnel complet jusqu'à `invitee_first_outbound_invite` est attribuable et vérifié
  par un parcours synthétique ;
- les quatre langues, Light/Dark, mouvement réduit et appareils physiques passent ;
- la revue Noche Conseil obtient au moins 8/10 dans les dix dimensions ;
- aucun service, partial, contrôleur Stimulus, sélecteur CSS, clé i18n, route, fixture
  ou spec mono-duel remplacé ne subsiste dans la codebase.

### 18.2 Validation de viralité en production

La qualité du code ne suffit pas à déclarer la viralité réussie. Avant le pilote, le
produit fige ses seuils de conversion, de temps de cycle et de garde-fous. Le pilote
n'est conclu qu'après :

- validation A/A de la mesure ;
- lecture du funnel par canal, OS, langue et nouveau/existant ;
- identification chiffrée du principal point de chute ;
- absence de dégradation inacceptable des refus, blocages et désabonnements ;
- mesure de `K` et du temps de génération avec un intervalle de confiance documenté.

Une viralité autonome signifie `K ≥ 1` sans franchir les garde-fous de confiance. Si
`K < 1`, le moteur peut rester un excellent système de rétention sociale, mais le plan
ne doit pas le qualifier de viral sans source d'acquisition complémentaire.

## 19. Résumé exécutable

```text
Une performance fière devient une invitation personnelle.
Le lien externe montre l'enjeu sans Push, installation ni Hub.
La première réclamation valide crée un défi actif entre deux personnes.
Le prochain run éligible engage son score brut dans tous les défis actifs.
Le serveur résout ce qui peut l'être en une transaction.
Le quiz met en scène un ami focal sans cacher les autres.
La cérémonie célèbre d'abord le run, puis révèle sa vie sociale sur le Campus.
La revanche relance une personne ; la propagation ouvre une nouvelle branche.
Le funnel distingue partage, ouverture humaine, jeu, résultat et nouvel expéditeur.
```

## 20. État d’implémentation au 29 août 2026

Réalisé :

- séparation persistée `DuelInvitation` / `StreetDuel` / `QuizRun` ;
- claim transactionnel avec ordre de verrous stable, paire active unique, expiration
  des paires périmées et fan-out d’un run vers N défis ;
- revanche liée au résultat sans `pack_id` ;
- Campus, landing froide, détail du défi, rail de quiz et impact de cérémonie ;
- accusés externes et nommés honnêtes, Turbo Stream et Push de secours ;
- funnel versionné, vue Campus, résultat vu, propagation et retour D7 ;
- trois artworks UI-safe, CSS dédié, mouvement réduit et fail-closed ;
- suppression des services, partials, contrôleurs, specs, clés i18n et styles legacy ;
- contrat d’architecture empêchant leur réintroduction.

Cutover local validé : 29 invitations migrées et 19 défis conservés, sans paire active
dupliquée, sans défi orphelin et sans référence d’exécution incohérente. Les anciennes
colonnes mono-duel ont été retirées ; les références vers les runs utilisent
`ON DELETE SET NULL`.

Validation de référence terminée : suite Rails complète à 981 tests et 15 175
assertions, Service Worker 6/6, captures Campus en 390×844, 768×1024 et 1440×900,
landing froide, destinataire connu, notification, résultat et mouvement réduit. La QA
navigateur a détecté puis fait corriger le dernier chevauchement du CTA d’invitation :
la zone d’action mesurée conserve désormais 27,7 px avant le dock à 390×844.

Le gate restant concerne le pilote de production, pas le cutover local : parcours réel
à deux appareils iOS/Android, Push livré → vu → accepté → résultat, puis validation A/A
et lecture des métriques virales définies en section 18.2.
