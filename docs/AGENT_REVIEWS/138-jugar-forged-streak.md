# M138 — Une seule flamme porte toute la série

Reviewed: 2026-08-29  
Slice: bonne réponse → flamme ×5 → faute → flamme étouffée → envie de rallumer  
Tests: JavaScript 4 / 4 ; Rails ciblé 24 runs / 2 022 assertions ; navigateur 2 runs / 334 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Copy: N/A — aucune copie déplacée ; les traductions existantes es, pt-BR, en et fr sont réutilisées

## Feeling

Le ×5 doit être une flamme que l'on vient d'attiser, pas le dernier pictogramme d'une
frise de cinq flammes croissantes. À la faute, le joueur voit immédiatement cette même
flamme s'écraser vers une braise, sans effacer son exploit ni transformer la rupture en
punition longue. Le HUD et le payoff annoncent désormais exactement le même symbole.

## 1 — Game experience

La boucle reste brève : la réponse correcte déclenche le cri, le total et une seule flamme
de série ; quatre éclats égaux l'allument depuis des diagonales ; une faute après ×5
contracte le halo, étouffe la flamme et disperse les éclats en cendre ; le verbe de
reprise invite à rallumer dès la question suivante. La logique de score et de série ne
change pas.

Les anciennes recettes `combo-ignite` et `score-flight`, déclarées mais jamais exécutées
par le directeur de mouvement, sont supprimées. Le vol du score réellement visible reste
piloté par le contrôleur du quiz.

## 2 — UI design

Verbe à deux secondes : **répondre**, puis **reconstruire la série**.

- une seule flamme centrale porte `×N`, lisible jusqu'à deux chiffres ;
- le HUD du quiz reprend la même flamme avec la même notation `×N` ;
- les quatre éclats ont la même importance et ne dessinent aucune progression gauche-droite ;
- succès, rupture et mouvement réduit partagent le même markup en Celestial Light et Dark ;
- à la rupture, la silhouette refroidie, le halo contracté et la braise restent lisibles sans masquer `×N` ;
- à `prefers-reduced-motion`, tous les éléments arrivent directement dans leur état final.

## 3 — Art direction

La flamme SVG déjà connue du joueur devient le héros central : rouge, or, halo chaud et
éclats irréguliers. La composition reste cérémonielle, sous le livre et dans le faisceau,
avec des impulsions diagonales plutôt qu'une rangée d'icônes. À la rupture, la même
silhouette se comprime, se grise et laisse une braise, ce qui conserve la mémoire du ×5.

## Theme engine

N/A — slice Street. Les tokens et le markup restent communs ; les deux atmosphères ont
été vérifiées séparément.

## Four seats

| Seat | Verb tonight |
|---|---|
| Joueur Street | Répondre et attiser une série |
| Écran | Montrer le ×N gagné ou perdu sans ambiguïté |
| Autour de moi | Lire le cri et la rupture d'un coup d'œil |

## Tension

La tension vient du nombre exact porté par la flamme et de la possibilité de la perdre.
Le feedback reste court : il récompense le pic sans ralentir la prochaine question.

## Finale

N/A — ce slice ne modifie ni la dernière question ni le calcul final.

## Languages

N/A — aucune nouvelle copie. Les libellés de série et de rupture continuent d'utiliser
les locales existantes.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 9.5 |
| Impact visuel | 9 |
| Feedback | 9.5 |
| Progression | 8.5 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- le cas exact ×5 et sa perte utilisent la même flamme, donc la cause et la conséquence se lisent immédiatement ;
- le HUD et le feedback utilisent désormais la même silhouette et la même notation `×N` ;
- le rythme diagonal évite toute croissance convenue de gauche à droite ;
- le compteur demeure lisible en Light, Dark, portrait, tablette et paysage ;
- l'état sans animation est explicite et l'ancienne rangée de cinq flammes ne subsiste plus dans le code applicatif.

## What feels weak

- le son de rupture n'a pas changé : cette passe transforme le geste visuel, pas le mixage ;
- une validation sur appareil physique reste utile pour juger la sensation haptique et la luminosité réelle.

## Required before approval

- None.

## Evidence

- Captures Light et Dark à 390 × 844, 768 × 1024 et 1440 × 900 pour le succès ×5 et la rupture du ×5.
- Les tests navigateur vérifient centrage, quatre éclats répartis des deux côtés, absence de débordement, extinction et reconstruction à ×1.
- Les contrats CSS interdisent le retour de l'ancienne `.street-hit-flame` répétée et couvrent `prefers-reduced-motion`.
- Console navigateur et tests ciblés sans erreur.

## Night director

Oui : le ×5 ressemble maintenant à une flamme que j'ai attisée et que je peux perdre.
La braise donne immédiatement envie de rallumer la série, sans ajouter un écran ni
un délai avant la prochaine question.
