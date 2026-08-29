# M127 — Le quiz Street retrouve ordre, silence et harmonie

Reviewed: 2026-08-29  
Slice: art d’entrée → question → réponse → vérité → récompense → action suivante → cérémonie  
Tests: JavaScript 24 / 24 ; Rails 82 / 2 609 assertions ; navigateur 4 / 4 530 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Sound: `.agents/skills/noche-sfx/SKILL.md`  
Copy: N/A — aucun texte joueur n’a changé

## Feeling

Le joueur doit sentir un jeu qui respire et qui sait exactement ce qu’il veut lui faire
regarder : d’abord la vérité, ensuite le feedback, puis la récompense, enfin l’envie de
continuer. Le son confirme cette progression sans interrompre, punir ni surprendre.

## 1 — Game experience

Le quiz Street possède maintenant une timeline explicite par état. Une question révèle
le dock en un seul mouvement puis déverrouille le choix. Un résultat montre le verdict,
les barres, le gain de score et seulement ensuite les actions. La cérémonie joue une
seule fanfare puis révèle score, coffre et contenu dans cet ordre.

Les doubles activations sont absorbées. Les swipes arrière/avant appartiennent au quiz
lui-même ; le gros contrôleur `story`, qui ne faisait que déléguer le geste, a quitté
`/jugar`. Tous les timers, frames, écouteurs et animations numériques sont possédés par
un `EffectScope` et sont annulés au remplacement Turbo.

## 2 — UI design

Le verbe en deux secondes reste `répondre`, puis `continuer`. Les choix n’entrent plus
en cascade et le résultat n’affiche plus le CTA avant le score. Les animations continues
du streak, des étincelles, du bouton Suivant et du timer ont disparu de l’overlay. Le
loader Street conserve ses trois formes attendues, mais les déplace par transform à
opacité constante au lieu de clignoter.

Les états `feedback`, `reward`, `actions`, `chest` et `content` sont explicites. Avec
`prefers-reduced-motion`, le même état final est rendu immédiatement, sans contenu caché
ni action bloquée.

## 3 — Art direction

L’illustration biblique reste le premier plan émotionnel. Les mouvements courts sont
limités à opacity/transform sur le trajet principal ; la chorégraphie ne recouvre plus
l’image de pulsations permanentes. La cérémonie garde le cercle d’or, le coffre et la
montée de score, mais abandonne la pluie de flammes et ses whooshes répétés.

## Theme engine

N/A — surface Street. Celestial Light/Dark continue de venir de l’illustration et du
chrome existants, sans toggle ni deuxième markup.

## Four seats

N/A — boucle Street individuelle et asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Qui suis-je | Lire mon niveau, mon score et ma série dans un HUD stable |
| Où suis-je | Reconnaître le monde biblique avant que la question n’entre |
| Que faire | Choisir, comprendre le verdict, puis lire ou continuer |
| Autour de moi | Retrouver le classement et les défis seulement après la récompense finale |

## Tension

La tension vient du compte à rebours et de la progression réelle, jamais d’un clignotement.
Les zones `warn` et `hot` restent visibles, mais ne pulsent plus à l’infini. Le retour
d’arrière-plan coupe le bed et le stinger Street ; aucune musique ne reprend sans une
nouvelle interaction du joueur.

## Finale

Le score final monte une fois, le coffre s’ouvre une fois et une seule fanfare accompagne
la cérémonie. Les anciens `fire_whoosh`, `score_transfer`, `crown_chime` et `chest` ne
sont plus joués ni préchargés sur `/jugar`. Le bonus de série reste lisible dans le calcul
du score, sans attributs DOM hérités de l’ancien effet de flammes.

## Languages

N/A — aucune copie ni clé i18n déplacée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.8 |
| Clarté | 9.5 |
| Impact visuel | 9.0 |
| Feedback | 9.5 |
| Progression | 9.2 |
| Social | 8.4 |
| Immersion | 9.3 |
| Accessibilité | 9.4 |
| Cohérence NocheLive | 9.3 |
| Envie de continuer | 9.2 |

## Verdict

PASS — prêt pour livraison après le smoke test physique habituel. Noche Live n’est pas
couvert par ce chantier et ses six fichiers audio partagés ont été restaurés à l’identique.

## What works

- un propriétaire de timeline pour la question/résultat et un pour la cérémonie ;
- aucun timer ou frame nu dans les contrôleurs Street du quiz ;
- zéro animation infinie calculée dans `#street_quiz` pendant l’audit navigateur ;
- un seul groupe d’entrée pour les choix et une seule animation de barres ;
- un seul cue de cérémonie, au lieu d’une fanfare, plusieurs whooshes et un coffre ;
- cues Street isolés : miss à gain `0.17`, réussite à `0.42`, finale à `0.48` ;
- manifeste réduit de sept à cinq cues réellement possibles pendant la session ;
- le trajet `/jugar` ne charge plus les contrôleurs `story` et `sheet` inutiles ;
- swipe, double activation, Turbo, timer, mouvement réduit et quatre tailles de cérémonie
  sont couverts en navigateur.

## What feels weak

- aucun profil Performance enregistré sur un téléphone Android bas de gamme réel : le
  gain d’architecture est démontré, pas un chiffre FPS physique ;
- l’écoute sur haut-parleur de téléphone et avec bruit ambiant reste à valider humainement ;
- le loader animé doit encore être observé sous une vraie latence 2G/3G, malgré son état
  lent/offline déterministe.

## Required before production approval

- Smoke test sur un Android d’entrée de gamme et un iPhone : dix questions, arrière-plan,
  retour, mute, double appui et cérémonie.
- Écoute humaine des deux nouveaux fichiers Street sur haut-parleur : le miss ne doit pas
  dominer le bon résultat et la fanfare doit mourir naturellement.

## Evidence

- `street_wrong_soft.mp3` : 1,50 s, 31 453 octets, dernière tranche de 80 ms à -35,4 dB
  moyen / -20,9 dB max ;
- `street_royal_fanfare.mp3` : 4,00 s, 78 298 octets, dernière tranche à -40,7 dB moyen /
  -27,5 dB max ;
- captures inspectées : question et erreur en 390 × 844, cérémonie en desktop ; la suite
  couvre aussi 320, 360, portrait haut, iPad, paysage court, 1280 et 1920 ;
- JavaScript : 24 tests verts ; Rails ciblé : 82 tests, 2 609 assertions ; navigateur :
  flux complet 4 452, cérémonie 66, mouvement réduit 8, double activation 4 assertions ;
- vérifications de syntaxe JavaScript/Ruby et `git diff --check` vertes.

## Night director

Oui. Le jeu ne cherche plus à attirer le regard partout à la fois. Chaque moment cède la
place au suivant, le silence entre les cues a une fonction, et la cérémonie paraît plus
grande précisément parce qu’elle ne crie qu’une fois.
