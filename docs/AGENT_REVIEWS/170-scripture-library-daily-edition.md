# M170 — Bibliothèque vivante du jour

Reviewed: 2026-08-31
Slice: une couverture éditoriale quotidienne, puis la continuité personnelle et la semaine fusionnée
Tests: contrat éditorial, publication immuable, médias, intégration et QA visuelle — 79 runs, 758 assertions, 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: Conseil d’expédition — Experience Gate PASS 7/7
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md` — Art Gate PASS
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr validés

## Feeling

Ouvrir la Bibliothèque doit provoquer une curiosité immédiate : « Qu’est-ce que
les Écritures vont me montrer aujourd’hui que je n’avais jamais remarqué ? ».
La page n’est plus un catalogue de fonctions. Elle est une édition du jour qui
donne une raison de revenir demain, sans fabriquer de streak ni culpabiliser le
lecteur.

## 1 — Game experience

La boucle est `une porte s’ouvre → une tension apparaît → je lis → une autre
histoire m’attend demain`. Six jours conduisent aux six vraies portes de
l’expédition. Le septième ne fabrique pas un pack : il remet les six images en
présence et ouvre la destination hebdomadaire fusionnée pour la contemplation.

La date locale `Europe/Madrid` sélectionne exactement un édito. Le contrat de
publication refuse toute semaine qui n’en contient pas exactement sept, toute
date dupliquée, toute référence inconnue, tout pack étranger ou tout gate qui ne
couvre pas la révision courante.

## 2 — UI design

Verbe en deux secondes : `Lire le Psaume`. La hiérarchie est désormais :
Découverte du jour, Reprendre si une lecture réelle existe, Cette semaine,
recommandation causale du quiz si elle existe, pensées réelles de la Rama, puis
outils de récupération. Pas de donnée personnelle signifie pas de tuile.

Come Follow Me et l’expédition partagent une seule grande destination. Les
signets, les Écritures et le programme annuel restent sobres en bas de page. La
recherche, les deep links, Turbo, le clavier et le lecteur conservent leurs
routes. La surface possède sa feuille dédiée `surfaces/library.css`, chargée
uniquement pour la Bibliothèque.

## 3 — Art direction

Sept couvertures ont chacune trois compositions dessinées pour téléphone,
tablette et desktop : 21 masters, mais une seule image responsive chargée par
visite. Tous les noms de masters contiennent leur référence biblique. Le bleu
Celestial Dark de la Bibliothèque reste l’atmosphère ; l’or marque la question
et l’action.

Les images restent contemporaines et symboliques. Elles ne transforment pas une
incertitude historique en scène factuelle. Le master tablette du Psaume 119 a
exactement quatre marque-pages à gauche ; ce détail visuel ne prétend ni compter
les 22 strophes ni représenter l’alphabet hébreu.

## Theme engine

N/A pour le Hub. La Bibliothèque conserve un seul arbre de rendu et une feuille
de surface sémantique ; il n’existe ni thème utilisateur ni deuxième page pour
les éditos.

## Four seats

| Seat | Verb aujourd’hui |
|---|---|
| Visiteur | Découvre l’histoire du jour sans compte |
| Lecteur qui revient | Reprend seulement une lecture réellement commencée |
| Membre de la Rama | Lit et rejoint de vraies pensées sur le même corpus |
| Conseil éditorial | Livre sept révisions datées, vérifiées et immuables |

## Tension

Chaque couverture commence par une image et une question avant l’explication.
La tension change chaque jour sans inventer un arc historique commun : fumée,
siège vide, dernier vers, maison, chant refusé, deux pages maintenues ouvertes.
La semaine reste une constellation, pas une narration forcée.

## Finale

Le dimanche demande quelle porte suit encore le lecteur. Il ne distribue ni
badge ni score et ne simule pas un septième contenu. Son CTA revient aux six
portes de la semaine.

## Languages

Les 196 champs parlés des sept éditos sont naturels en espagnol, portugais
brésilien, anglais et français. Human Voice Gate : PASS 196/196. Truth Gate :
PASS 441/441, historique, exégèse, canon et couverture, sans objection ouverte.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9 |
| Clarté | 10 |
| Impact visuel | 10 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 10 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 10 |

## Verdict

PASS

## What works

- La Bibliothèque répond d’abord à l’envie d’ouvrir les Écritures maintenant.
- L’édito public reste excellent sans connexion ; les blocs personnels ne sont
  jamais simulés.
- Une seule version publiée porte les 7 jours et son digest protège la copie
  exacte validée par le Conseil.
- La relance du publisher est idempotente et ne crée pas de version 5.

## What feels weak

- Cette première édition est configurée pour une semaine précise ; les semaines
  suivantes demandent encore un nouveau payload du Conseil.
- Le signal social dépend honnêtement de l’activité réelle de la Rama et peut
  donc être absent.

## Required before approval

- None.

## Evidence

- Publication locale : StudyUnit 50, StudyQuizVersion 10, version 4.
- Digest publié : `2de6bb18dac0903c16f38c25e93c2fa67116c8361f67cd56223bf32bc389098c`.
- Contrôle réel sans preview : un édito `psalms-2026-08-31-day-1-ps102`, une
  image chargée, feuille Library dédiée, aucune erreur console.
- QA responsive : 390×844, 768×1024 et 1440×900.

## Night director

Oui. J’ai une question à porter dans le Psaume aujourd’hui et une raison claire
de revenir demain. La page ne me demande jamais d’entretenir une série : elle me
promet simplement une autre porte.
