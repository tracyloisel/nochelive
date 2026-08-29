# M135 — La course amicale motive puis rend l'écran au jeu

Reviewed: 2026-08-29  
Slice: signal social Street → lecture → rappel compact → événement réel  
Tests: JavaScript 25 / 25 ; Rails ciblé 11 runs / 47 assertions ; navigateur 1 run / 102 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Copy: N/A — aucune chaîne modifiée

## Feeling

Le joueur doit sentir qu'un ami existe dans sa partie et qu'un objectif l'appelle, sans
avoir l'impression qu'une bannière publicitaire occupe son écran. La course amicale est
un petit événement attendu, puis une présence discrète qui laisse la question respirer.

## 1 — Game experience

La tuile complète apparaît une fois au début d'une partie. Elle entre depuis son centre,
reste lisible trois secondes, puis se replie en rappel compact. Une visite ou un rendu
Turbo ordinaire ne relance pas la séquence. Un changement social réel — dépassement,
égalité, progression adverse ou résultat officiel — possède une signature liée au duel
et aux scores et peut donc rouvrir la notification une fois.

Les événements de réponse attendent 420 ms avant l'entrée afin de laisser la vérité de
la question démarrer en premier. Aucun nouveau son n'est ajouté et le haptique existant
ne se déclenche qu'à la première présentation d'un événement.

## 2 — UI design

Verbe à deux secondes : **voir l'objectif, puis répondre**.

- état complet : avatar, nature du signal, phrase motivante, scores et compteur ;
- entrée : apparition centrale à petite échelle, léger dépassement, stabilisation ;
- état compact : avatar et phrase motivante sur une seule ligne ;
- hauteur courte : état compact dès le départ afin de protéger le timer et la question ;
- mouvement réduit : état compact immédiat, sans animation résiduelle ;
- accessibilité : la présence ordinaire n'annonce rien ; seuls les événements passent
  dans une région `aria-live="polite"`.

## 3 — Art direction

Le verre vert et le filet doré restent la signature sociale commune aux mondes
Celestial Light et Dark. Le ressort est court et chaleureux, pas une alerte rouge ni une
fenêtre système. Le halo de dépassement reste borné à l'arrivée et ne tourne jamais en
continu. L'illustration biblique reprend immédiatement la majorité de la composition.

## Theme engine

N/A — surface Street. Light/Dark reste déterminé par l'illustration ; la tuile conserve
la même anatomie et adapte seulement son contraste au chrome existant.

## Four seats

N/A — boucle Street individuelle et asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Qui suis-je | Lire mon objectif face à un ami |
| Où suis-je | Rester dans l'illustration et la question du pack |
| Que faire | Répondre après avoir compris l'écart |
| Autour de moi | Voir un événement réel sans subir une bannière permanente |

## Tension

La tuile crée une pointe sociale, puis cède la place au timer et au choix. Elle revient
uniquement quand la course change réellement. La tension sonore du quiz n'est ni coupée,
ni doublée, ni surprise par cette couche sociale.

## Finale

La finale n'est pas modifiée. Le résultat officiel du duel garde cependant le droit de
rouvrir la notification avec sa signature finale.

## Languages

N/A — les phrases existantes sont réutilisées sans ajout ni modification.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.1 |
| Clarté | 9.6 |
| Impact visuel | 9.2 |
| Feedback | 9.3 |
| Progression | 9.1 |
| Social | 9.7 |
| Immersion | 9.3 |
| Accessibilité | 9.6 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.4 |

## Verdict

PASS WITH NOTES — prêt côté implémentation et navigateur ; la sensation du ressort et
du haptique reste à confirmer sur un téléphone physique avant production.

## What works

- la tuile complète devient un événement borné, jamais une animation permanente ;
- le rappel compact libère visiblement l'image, le timer et la question ;
- la mémoire de session empêche les replays dus aux remplacements Turbo ;
- les événements ont une signature de score et ne sont pas étouffés par la mémoire ;
- aucun `setTimeout` nu : le cycle appartient à `EffectScope` et se nettoie au disconnect ;
- Light, Dark, 390×844, 768×1024 et 1440×900 sont sans collision ni erreur console ;
- le mode mouvement réduit atteint directement le même état final.

## What feels weak

- le texte compact peut être tronqué sur tablette si le nom ou la traduction est très
  long ; l'objectif principal reste toutefois visible et le lien conserve son libellé
  accessible complet ;
- le haptique dépend encore des capacités du navigateur et du téléphone.

## Required before production approval

- Valider sur un iPhone et un Android d'entrée de gamme que l'entrée semble surgir du
  centre sans flash initial, et que le repli ne détourne pas le toucher d'une réponse.

## Evidence

- captures : complet Light 390×844 ; compact Light/Dark 390×844 ; Dark 768×1024 et
  1440×900 ; mouvement réduit 390×844 ;
- navigateur : ordre HUD → course → timer → feuille vérifié dans chaque viewport ;
- navigateur : largeur et hauteur compactes strictement inférieures à l'état complet ;
- `aria-live` off au repos, polite pour un dépassement ;
- JavaScript 25 tests verts, Rails métier ciblé 11 tests verts, `git diff --check` vert.

## Night director

Oui. L'ami donne maintenant une raison de pousser le score, puis s'efface assez pour que
la question redevienne le jeu. Le signal social nourrit la boucle au lieu de la recouvrir.
