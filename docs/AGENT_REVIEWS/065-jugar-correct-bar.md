# 065 — Street jugar: gold hit bar, not mint poll

Reviewed: 2026-08-27
Slice: `/jugar` overlay settled **correct** row — border + wash. Tick stays the hit mark. Score métier unchanged.
Tests: `test/integration/ui_chrome_test.rb` pins overlay is-correct gold; no `#3d9a5c` / `#6fde95`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A (jugar, pas `/`)
Copy: N/A

## Feeling

Fierté. La bonne réponse **brille comme le bijou de la question** (liseré or, lavis champagne), pas comme un formulaire « success green ». La coche olive dit hit ; la foule (%) reste un lavis, pas un bloc menthe.

Si la réponse était seulement « colorer la barre en vert » → VETO.

## 1 — Game experience

Boucle inchangée : tap → résultat → SFX/haptic → % qui pousse → Suivant. Le polish est le **payoff visuel** du hit : même famille que le choix posé, or signature, pas un second système de couleur. Miss (croix feu, lavis discret) non touché. Points = somme réelle.

## 2 — UI design

2 secondes : coche à gauche = vrai ; or = clé. Light : ivoire + or (`--gold`), coche `--quiz-hit` `#2f6f45`. Dark : verre nuit + or, coche olive crème `#c8d9a8`. Stroke du picto forcé (le street `#17a34a` ne gagne plus). Bordure = pastille posée (or + halo), pas liseré forêt. Fill = dégradé or qui s’estompe au %, pas dalle `#3d9a5c`.

## 3 — Art direction

Le décor Light (temple / Rois) reste ivoire ; l’or est métal, pas un vert Bootstrap. Dark : or volumétrique, jamais menthe néon. La coche est émail olive-or, pas pastille `#6fde95`.

## Theme engine

N/A.

## Four seats

Street — un siège (tú). N/A live.

## Tension

N/A. Un hit plus précieux, pas plus de points.

## Finale

N/A.

## Languages

N/A.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.2 |
| Clarté | 8.6 |
| Impact visuel | 8.5 |
| Feedback | 8.5 |
| Progression | 8.0 |
| Social | 8.0 |
| Immersion | 8.4 |
| Accessibilité | 8.3 |
| Cohérence NocheLive | 8.7 |
| Envie de continuer | 8.3 |

## Verdict

**PASS** — hit or Noche, coche olive, plus de poll menthe.

## What works

- Bordure or alignée sur `.choice-btn.is-picked`.
- Lavis or adouci au bord du %.
- Coche Light/Dark lisible ; `#17a34a` overlay-overridden.

## What feels weak

- Miss Light `#f0a090` encore un peu « Dark-on-cream » (hors slice).
- Le % 83 % dur reste un chiffre ; le fade CSS n’est pas un blur.

## Required before approval

- None.

## Evidence

UI: overlay `/jugar` Light (Salomon / Rois) + Dark tokens.

## Night director

Je relis le hit comme la même pastille, révélée. Oui, encore une question.
