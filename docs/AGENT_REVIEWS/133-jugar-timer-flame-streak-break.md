# M133 — Le timer tient sa place et la série brûle vraiment

> La direction « flammes croissantes » de cette revue historique est remplacée par
> [M138](138-jugar-forged-streak.md). Les constats timer, son et logique de série restent valides.

Reviewed: 2026-08-29  
Slice: question Street → tension → bonne réponse → série → rupture → envie de repartir  
Tests: JavaScript 24 / 24 ; Rails ciblé 80 runs / 850 assertions ; navigateur 4 runs / 4 690 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Sound: `.agents/skills/noche-sfx/SKILL.md`  
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr présents et parité validée

## Feeling

Le joueur doit sentir une pulsation continue pendant la question, la joie physique de
voir sa flamme grandir, puis un vrai manque quand sa série s'éteint. La rupture ne doit
jamais ressembler à un bug silencieux : elle doit donner envie de rallumer immédiatement.

## 1 — Game experience

Chaque question de `/jugar` utilise désormais le même lit `timer_tension`, pas seulement
les cartes chronométrées. La musique commence avec la phase jouable, s'arrête dès le
choix et ne revient pas sur le résultat. Le timer visible reste réservé aux questions
réellement chronométrées et son décompte attend la fin de l'aperçu artistique.

La série est calculée depuis les réponses réelles. Une faute après une ou plusieurs
bonnes réponses conserve le nombre perdu comme donnée de feedback, remet correctement
la série courante à zéro, éteint les flammes, joue un impact feu unique et affiche le
verbe de reprise. Une faute hors série garde le cue doux ordinaire.

## 2 — UI design

Verbe à deux secondes : **répondre**, puis **rallumer la série**.

- le timer possède un rail en flux entre la course amicale et la feuille de réponse ;
- aucun positionnement global ne peut plus le cacher sous le Défi social ;
- l'ancien composant structuré points / séparateurs / rail / losanges est supprimé ;
- cinq flammes grandissent réellement et représentent honnêtement les séries 1 à 5 ;
- au-delà de cinq, la rangée pleine change d'intensité tandis que le nombre exact reste affiché ;
- les flammes futures restent lisibles comme promesse, sans concurrencer celle allumée ;
- à la rupture, la flamme gagnée tombe en braise et « Rallume-la ! » devient la prochaine
  intention ;
- Light et Dark utilisent la même anatomie et `prefers-reduced-motion` atteint le même
  état final sans boom animé.

## 3 — Art direction

Le résultat abandonne la géométrie de tableau de bord. Le feu devient le seul signe de
progression : petit au premier succès, plus grand à chaque jalon, avec un boom court à
l'allumage. L'image biblique garde la majorité de l'écran et le halo sombre derrière le
feedback sert uniquement la lisibilité. La rupture utilise une braise grisée, jamais une
explosion punitive ou horrifique.

## Theme engine

N/A — surface Street. Celestial Light/Dark continue d'être déterminé par l'illustration,
sans toggle ni duplication de markup.

## Four seats

N/A — boucle Street individuelle et asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Qui suis-je | Lire ma série réelle dans le HUD et dans les flammes |
| Où suis-je | Garder l'illustration biblique comme monde principal |
| Que faire | Répondre sous tension, puis rallumer après une rupture |
| Autour de moi | Voir la course amicale avant le timer, sans collision |

## Tension

La tension est sonore pendant toutes les questions et visuelle seulement lorsqu'un temps
limite existe. Elle tombe exactement au choix. Le succès allume la prochaine flamme ; la
faute en série crée un creux court et audible, puis rend immédiatement l'objectif suivant.

## Finale

La finale n'est pas modifiée. La série continue d'alimenter le score réel et la cérémonie
existante, sans réintroduire de sons empilés ni modifier Noche Live.

## Languages

Les trois nouvelles intentions sont présentes et natives en **es**, **pt-BR**, **en** et
**fr** : série rompue, invitation à la rallumer, annonce accessible avec le nombre perdu.
La parité automatisée est verte. La direction française est approuvée dans le fil ; les
traductions restent une proposition locale, non déployée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.4 |
| Clarté | 9.6 |
| Impact visuel | 9.2 |
| Feedback | 9.7 |
| Progression | 9.5 |
| Social | 8.5 |
| Immersion | 9.4 |
| Accessibilité | 9.2 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.6 |

## Verdict

PASS WITH NOTES — prêt côté implémentation et navigateur ; contrôle physique audio et
haptique encore souhaitable avant mise en production.

## What works

- timer au-dessus de la feuille sur mobile, tablette et desktop, y compris sous la course ;
- même lit de tension sur chaque question Street, relâché avant tout cue de résultat ;
- une seule conséquence audiovisuelle par verdict ;
- série perdue exacte, sans état parallèle ni multiplication de score ;
- hiérarchie festive et simple : cri, série, flammes, action suivante ;
- aucun ancien rail, losange, score central ou contrôleur dédié conservé sur le chemin ;
- zéro débordement horizontal et zéro erreur navigateur sévère sur les captures dédiées.

## What feels weak

- la vibration dépend de `navigator.vibrate` et restera absente sur les appareils qui ne
  l'exposent pas ; le son et le visuel portent donc toujours le feedback principal ;
- l'écoute sur haut-parleur de téléphone en environnement bruyant reste à valider ;
- la sensation du boom des flammes ne peut pas être jugée entièrement sur une capture.

## Required before production approval

- Jouer une série de trois puis la perdre sur un iPhone et un Android d'entrée de gamme,
  son activé puis coupé, pour valider impact, absence de chevauchement et reprise ;
- écouter `dramatic_fire` sur haut-parleur : il doit marquer la perte sans dominer le
  prochain écran.

## Evidence

- matrice principale : 320×568, 360×640, 390×844, 430×932, 768×1024, 844×390,
  1024×768 et 1440×900 ;
- captures dédiées Light/Dark : 390×844, 768×1024 et 1440×900 pour succès et rupture ;
- navigateur : flux complet 4 452 assertions, timer/course 63, flammes/rupture 175 ;
- Rails ciblé : logique de série, helper audio, contrôleurs, manifeste et i18n ;
- JavaScript : 24 tests verts, dont ordre de timeline et gain rupture > faute ordinaire ;
- `dramatic_fire.mp3` : 1,8 s, niveau moyen source -18,8 dB, joué à gain 0,38 ;
- `timer_tension.mp3` : 30 s, joué comme bed à gain 0,32 puis fondu à la réponse ;
- `git diff --check` vert.

## Night director

Oui. La question a maintenant un pouls, la bonne réponse allume une promesse visible et
la faute en série fait enfin quelque chose. Le silence qui suit n'est plus un oubli : il
ouvre l'espace exact pour vouloir reprendre le strike.
