# M125 — Défis lisibles, urgents et ancrés dans les packs

Reviewed: 2026-08-29  
Slice: `/desafios` — prochain pack → course aux points → activité du rival → résultat  
Tests: 13 tests / 117 assertions + 4 tests visuels / 40 assertions + contrôle français / 7 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Copy: `.agents/skills/noche-i18n/SKILL.md` — 186 clés `duel_campus` à parité en es, pt-BR, en et fr

## Feeling

Compétition amicale et urgence lisible : « je sais quel pack jouer, combien de points
sont en jeu et ce que fait mon rival maintenant ».

## 1 — Game experience

La page ouvre désormais sur une boucle complète : prochain pack nommé → points et
progression visibles → score à battre ou rival en train de jouer → CTA compact →
résultat et prochaine envie. Les échéances viennent du vrai `expires_at`. Le statut
« joue maintenant » exige à la fois un run ouvert et une présence réelle ; un run
ouvert hors ligne est annoncé plus sobrement comme pack en cours.

L’état sans défi ne gaspille plus le premier écran dans un panneau vide. Il conduit
directement au pack suivant puis aux rivaux, qui affichent leurs points et leur pack
ouvert lorsqu’il existe.

## 2 — UI design

Le verbe en deux secondes est `Jouer ce pack`. L’or lui est réservé. Recherche,
invitation et partage restent secondaires. Les actions mesurent 44–46 px de haut au
lieu des anciens grands blocs. Le pack prioritaire donne le titre, la question sur 10,
les points disponibles, la finale à 25 points et une barre de progression.

États vérifiés : sans défi, défi prêt, à toi, rival live, rival hors ligne avec pack
ouvert, score posé, invitation, résultat, mouvement réduit. Les erreurs continuent de
passer par les flashes serveur ; aucun nouveau permission flow n’est introduit.

## 3 — Art direction

La composition revient au monde Celestial Light de la cour céleste partagé avec la
Liga. Le titre reste en encre sur verre ivoire, le décor reste visible et l’or sert de
métal, de filet et d’unique CTA. Les composants utilisent les tokens sémantiques
`--paper`, `--ink`, `--navy`, `--line`, `--gold` et le métal du temple.

Celestial Dark est N/A pour cette surface : le moment social et son artwork sont
explicitement Light, sans toggle utilisateur.

## Theme engine

N/A — `/desafios` n’est pas le Hub `/`.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Jouer le prochain pack et poser un score |
| Mon rival | Continuer son pack ; son activité réelle devient visible |
| Autour de moi | Choisir un rival en lisant points et pack ouvert |
| Prochaine envie | Passer devant, attendre la réponse ou ouvrir le résultat |

## Tension

La tension vient de faits : 103 points disponibles, finale à 25 points, score cible,
progression `6/10`, présence live et nombre de jours restants. Aucun faux compte à
rebours ni activité simulée.

## Finale

Le pack garde sa courbe existante de dix questions et sa dernière question à 25
points. Cette slice ne modifie pas le calcul du score ni la cérémonie.

## Languages

Les quatre YAML se chargent et les 186 clés `duel_campus` sont à parité. La capture
française vérifie `Défis`, `Prochain pack`, `Rois`, `103 pts + série`, `Question 1/10`
et un CTA de 46 px. `noche-i18n`: PASS — es, pt-BR, fr et en restent natifs et courts.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.5 |
| Clarté | 9.4 |
| Impact visuel | 8.8 |
| Feedback | 8.6 |
| Progression | 9.2 |
| Social | 9.2 |
| Immersion | 8.7 |
| Accessibilité | 9.1 |
| Cohérence NocheLive | 9.1 |
| Envie de continuer | 9.2 |

## Verdict

PASS WITH NOTES — livraison locale, non déployée.

## What works

- le pack et les points précèdent enfin les boutons ;
- l’état actif nomme les deux packs et les deux scores ;
- l’activité du rival est honnête et triée live-first ;
- l’absence de défi montre immédiatement les rivaux au lieu d’un grand état vide ;
- les actions secondaires sont compactes et la lecture tient de 390 à 1440 px ;
- aucune erreur console ni traduction manquante dans les parcours inspectés.

## What feels weak

- la preuve live dépend de la fenêtre de présence de 45 secondes, volontairement
  stricte ;
- aucun SFX n’a été ajouté : cette page de sélection reste calme et laisse le payoff
  au quiz et au résultat ;
- l’iOS et l’Android physiques ne sont pas couverts par cette passe locale.

## Required before production approval

- Faire valider éditorialement les formulations finales de cette proposition dans les
  quatre langues. Aucun message sortant ou Push n’a été modifié ni activé.
- Vérifier à deux appareils réels le passage rival live → score posé → résultat.

## Evidence

- captures inspectées : 390×844, 768×1024, 1440×900, défi actif 390, français 390,
  mouvement réduit 390 ;
- aucune troncature, aucun overflow horizontal, CTA principal mesuré à 46 px ;
- console navigateur : 0 entrée `SEVERE` sur les vues de référence et active ;
- interaction française `Jouer ce pack` exercée jusqu’à `#street_quiz` ;
- tests Rails ciblés : 13 / 117, verts ; tests visuels : 4 / 40, verts ; français :
  1 / 7, vert ; parité i18n : 186 clés dans chaque langue.

## Night director

Oui. Avant de toucher le CTA, je sais déjà ce que je vais jouer, ce que cela vaut et
qui je peux dépasser. Le pack suivant a maintenant une vraie raison d’exister.
