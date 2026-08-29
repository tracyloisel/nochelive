# M145 — Défier un rival depuis la Cour des Couronnes

Reviewed: 2026-08-29
Slice: `/liga`, lecture du rival puis invitation de défi
Tests: UI/leaderboard — 77 runs, 535 assertions, 0 failures; invitation — 15 runs, 161 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — destination Liga en Celestial Light, pas le Hub `/`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr présents et relus

## Feeling

Compétition lisible et envie de provoquer un rival précis : je comprends qui je défie, ce qui le situe dans la Cour et ce que mon action va déclencher.

## 1 — Game experience

La boucle est directe : repérer un rival dans le classement → lire son rang, ses couronnes et son pack ouvert → envoyer une invitation à jouer par notification → attendre sa réponse. Les explications génériques et les règles sans effet immédiat ont été retirées. L’envoi réel reste une action explicite sur « Défier » et n’est pas déclenché par l’ouverture de la modale.

## 2 — UI design

Le verbe à deux secondes est « DÉFIER ». La modale ne répète plus le joueur courant et nomme le rival à trois endroits utiles : titre, profil et message de notification. Le titre emploie une seule police d’affichage et des capitales réelles. Le profil regroupe rang, couronnes, pack ouvert et progression éventuelle. Le message de notification occupe toute la largeur et reprend exactement la couleur du bouton « Annuler ». Les états idle, loading, success et failure restent présents ; fermer et annuler gardent une cible de 44 px minimum.

## 3 — Art direction

Le verre ivoire translucide est centré dans la Cour, avec une profondeur douce et une hiérarchie or/navy. L’aigle remplace les épées dans l’action principale et fonctionne comme sceau de défi. L’or reste concentré sur le titre, les couronnes et le CTA, tandis que le texte explicatif reste calme.

## Theme engine

N/A — aucun changement du Hub `/`. La modale consomme les tokens Celestial Light existants de la Liga et ne crée ni toggle ni variante de markup.

## Four seats

Street — qui : le rival nommé ; où : Cour des Couronnes ; quoi maintenant : consulter son profil puis le défier ; autour de moi : le classement de la communauté, conservé en arrière-plan.

## Tension

Le classement donne la distance sociale et compétitive. Le profil transforme une ligne abstraite en adversaire concret ; l’invitation crée le prochain battement sans ajouter de règles parasites.

## Finale

N/A — cette tranche amorce un duel et ne modifie ni score, ni dernière manche, ni cérémonie.

## Languages

Les quatre locales es, pt-BR, en et fr nomment l’action de défi, le profil du rival, le pack ouvert et l’invitation à jouer par notification. La formulation française finale a été explicitement dirigée par la partie prenante dans cette session.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8 |
| Social | 10 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- « Inviter » est remplacé par le verbe joueur « Défier » dans le classement et la modale.
- La modale est centrée, glass-transparent et sans débordement.
- Le rival est nommé avant ses données ; le joueur courant et « Toi » ont disparu.
- Le profil affiche honnêtement le pack ouvert et sa progression, ou « Aucun pack en cours ».
- Le message indique l’envoi d’une invitation à jouer par notification, sans pictogramme de cloche.
- L’aigle signe le CTA sans ajouter une deuxième métaphore de combat.

## What feels weak

- Sur les noms longs, le titre peut passer sur deux lignes en mobile ; le bloc reste centré et conserve sa hiérarchie.

## Required before approval

- None.

## Evidence

- Rendus inspectés à 390 × 844, 768 × 1024 et 1280 × 720, ainsi que la capture fournie à 714 px de large.
- Modale centrée à 0 px d’écart sur les deux axes, sans overflow ; fermeture 44 × 44 px, CTA 58 px de haut.
- Profil avec pack réel validé sur « Test Feu » : « Femmes de la Bible », question 3/10.
- Message mesuré en pleine largeur, sans SVG, et couleur calculée identique à « Annuler ».
- Console fraîche : 0 warning, 0 error.
- `street_challenges_controller_test` + `duel_invitation_create_test` : 15 runs, 161 assertions, green.

## Night director

Oui. Je vois immédiatement qui est devant moi, ce qu’il joue et ce que « Défier » va provoquer ; j’ai envie d’envoyer l’invitation.
