# M128 — Le Campus explique ses nombres et donne envie d’entrer

Reviewed: 2026-08-29  
Slice: Hub `/` — tuile Campus des Écritures → trois états nommés → `/desafios`  
Tests: 38 tests / 882 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`  
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr présents et relus

## Feeling

Appartenance et envie d’agir : « voici mon Campus, je vois ce qui m’attend et je sais
où entrer ». Le joueur ne doit plus décoder une ligne de données ni deviner ce que
signifie un badge isolé.

## 1 — Game experience

La tuile devient une micro-boucle sociale : voir une invitation → comprendre que
c’est à moi → ouvrir le Campus → accepter ou jouer → revenir découvrir le résultat.
L’information qui appelle une action, `invitations à accepter`, passe en premier et
reçoit l’accent or. Les défis actifs et les résultats non vus complètent la boucle.

Le badge agrégé `incoming + results` est supprimé : il mélangeait deux états et
n’offrait aucun verbe. Les valeurs restent honnêtes et viennent de
`Quizzes::DuelCampus::Counts` ; aucune urgence, récompense ou activité n’est inventée.

## 2 — UI design

Le lieu et le sujet sont désormais séparés : `Campus des Écritures` puis `Tes défis`.
Chaque nombre possède une carte vitrée, une icône secondaire et un libellé complet :

- invitations à accepter ;
- défis en cours ;
- résultats à découvrir.

Les chiffres utilisent la fonte d’affichage à 34 px minimum ; les libellés restent à
14 px minimum. Le CTA calme `Ouvrir le Campus` rappelle que toute la tuile est
interactive sans devenir un deuxième bouton or sur le Hub.

États couverts : vide, activité, entrée dans le viewport, prêt, pressed/hover,
départ vers le Campus et mouvement réduit. Loading/error restent ceux de la
navigation partagée ; locked/completed/live ne s’appliquent pas à ce résumé.

## Plan d’animation et de transition

1. **Entrée dans le viewport** — rien ne joue hors écran. Dès que 28 % de la tuile
   devient visible, le titre puis les trois cartes et le CTA montent de 10 px et se
   révèlent via la recette partagée `list-enter` (420 ms, stagger 55 ms).
2. **Comptage** — les valeurs partent de zéro avec 90 ms de respiration puis 75 ms
   entre chaque compteur ; durée 520 ms, fin exacte sur la valeur serveur.
3. **Priorité** — la carte invitation reçoit une seule passe lumineuse or de 720 ms.
   Aucun halo ni compteur ne boucle.
4. **Press / hover** — l’artwork avance de 1,8 à 2,5 % et la flèche se décale de 3 px.
5. **Changement de lieu** — le clic marque l’état `departing`, puis la transition
   `street-world` déjà partagée relie le Hub à `/desafios` sans écran intermédiaire.
6. **Mouvement réduit** — aucun comptage, transform ou shimmer ; les valeurs finales
   sont affichées immédiatement.

## 3 — Art direction

Univers : Campus des Écritures, lumière naturelle, livres ouverts, feuillage et or.
Composition : les visages restent dans la moitié haute ; un scrim local protège le
titre, puis les trois nombres forment un petit HUD de course dans la moitié basse.
L’or est réservé à l’invitation prioritaire, aux filets et au CTA outline ; les mots
restent crème sur le décor sombre.

Le composant conserve le même markup dans les mondes Light et Dark du Hub. L’art
Campus reste son monde local tandis que la bordure, l’ombre et le contexte autour de
la tuile suivent les tokens de l’atmosphère parente.

## Theme engine

PASS — une seule tuile, aucune duplication Light/Dark, aucun toggle utilisateur.
Les six captures de référence montrent le même ordre et les mêmes dimensions sous
les deux atmosphères.

## Four seats

N/A — boucle Street asynchrone.

| Place | Verbe maintenant |
|---|---|
| Moi | Accepter l’invitation prioritaire ou ouvrir mes défis |
| Mon rival | Continuer son parcours actif |
| Autour de moi | Faire apparaître un nouveau résultat social |
| Prochaine envie | Revenir découvrir qui est passé devant |

## Tension

La tension est uniquement sociale et factuelle : deux invitations m’attendent,
quatre courses continuent et quatre résultats ne sont pas vus. L’ordre et l’accent
or transforment ces faits en prochaine action sans compte à rebours artificiel.

## Finale

Inchangée : les scores, les questions et la finale des packs ne sont pas touchés.

## Languages

Les nouvelles clés existent dans les quatre locales sans fallback :

- es : `Campus de las Escrituras`, `invitaciones por aceptar` ;
- pt-BR : `Campus das Escrituras`, `convites para aceitar` ;
- fr : `Campus des Écritures`, `invitations à accepter` ;
- en : `Scripture Campus`, `invites waiting for you`.

Le besoin éditorial est approuvé par la demande stakeholder : nombres grands,
signification explicite et transition. Les formulations exactes ci-dessus restent
une proposition locale à valider avant déploiement ; aucun déploiement n’a été fait.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.8 |
| Clarté | 9.8 |
| Impact visuel | 9.4 |
| Feedback | 9.2 |
| Progression | 9.0 |
| Social | 9.5 |
| Immersion | 9.4 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9.6 |
| Envie de continuer | 9.3 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée ; validation éditoriale des
quatre formulations finales requise avant production.

## What works

- les trois nombres se comprennent sans contexte préalable ;
- le chiffre d’action est prioritaire sans faire clignoter la tuile ;
- le titre est lisible sur le décor aux six références ;
- l’animation commence réellement dans le viewport et ne rejoue pas au scroll ;
- le mode mouvement réduit conserve exactement la même information ;
- aucun overflow, clipping ni log navigateur error/warn.

## What feels weak

- le rendu sur téléphone physique en plein soleil reste à contrôler ;
- la formulation anglaise privilégie le naturel plutôt que la symétrie littérale ;
- la transition de navigation dépend du support View Transitions du navigateur et
  se dégrade en navigation immédiate quand il manque.

## Required before production approval

- validation éditoriale explicite des quatre formulations finales ;
- contrôle tactile sur un iPhone et un Android physiques.

## Evidence

- captures inspectées : 390×844, 768×1024, 1440×900 en Celestial Light et Dark ;
- capture mouvement réduit : 390×844 Light ;
- données réalistes de la demande : 4 défis, 2 invitations, 4 résultats ;
- taille minimale mesurée : nombres 34 px, libellés 14 px, CTA 44 px ;
- interaction exercée dans le navigateur : waiting → ready → `/desafios` ;
- console navigateur : 0 error, 0 warning ;
- tests ciblés combinés : 38 / 882, verts, dont le test visuel 1 / 119.

## Night director

Oui. Le joueur ne voit plus trois fragments de base de données : il voit d’abord ce
qui l’attend, puis les courses en mouvement, puis les résultats à découvrir. La
prochaine envie est sociale et immédiate.
