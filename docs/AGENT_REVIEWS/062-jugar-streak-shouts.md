# 062 — Street jugar: streak shouts on the still

Reviewed: 2026-08-27
Slice: `/jugar` overlay payoff voice. One shout on the painting at 2 / 3 / 5 / 10. Chip « En feu » gone. Score métier unchanged (no multiplier).
Tests: `Quizzes::HitStreak` shout_key + jugar overlay + helper + i18n
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A (jugar, pas `/`)
Copy: `.cursor/skills/noche-i18n/SKILL.md` — `quiz.streak_two|three|five|ten` es / pt-BR / en / fr. `quiz.on_fire` retiré.

## Feeling

Fierté qui **monte**. Surprise à chaque palier. Joie d’un cri que toute la famille peut reprendre. Accomplissement à dix. Pas « lire un chip sous Super ».

Si la réponse était seulement « afficher la combo » → VETO. Ici le joueur **entend** qu’il protège une série.

## 1 — Game experience

Boucle : tap → cri sur la scène ( Super / Dos seguidas / En llamas / Imparable / Diez de diez ) +N vole vers 👑 → 🔥 reste au Suivant. Miss → Presque + 🔥0.

Paliers : 2 (voix), 3 (`fire_whoosh` + haptic blaze), 5 (whoosh + blaze), 10 (`chest` + haptic legend + voile `level`). Entre les paliers, Super! + flamme HUD. Pas de `dramatic_fire` dans `HIT_CUES`. Points = somme réelle.

## 2 — UI design

Une voix : `.street-praise-line` remplace Super. HUD 🔥n inchangé (chiffre, pas STRIKE). Light / Dark : crème + scrim local sur la peinture, jamais or sur papier ivoire. États : glow / hot / blaze / legend sur le cri ; HUD `is-shout` au palier.

## 3 — Art direction

Le décor porte le cri. Feu (`--fire`) à 3 et 5, or volumétrique à 10. Type display, pas caps stade. Voile or 0,55s puis le mot reste.

## Theme engine

N/A.

## Four seats

Street — un siège (tú). N/A live.

## Tension

La série à ne pas casser. Le 10 est la légende du pack, pas la cérémonie (fanfare inchangée).

## Finale

N/A. Q10 légende ≠ royal_fanfare.

## Languages

noche-i18n: PASS

- es: ¡Dos seguidas! / ¡En llamas! / ¡Imparable! / ¡Diez de diez!
- pt-BR: Duas seguidas! / Pegando fogo! / Imparável! / Dez de dez!
- en: Two in a row! / On fire! / Unstoppable! / That's ten!
- fr: Deux d’affilée ! / En feu ! / Imparable ! / Sans faute ! (espace fine)

Aucun STRIKE. Tú / você / you / tu.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.7 |
| Clarté | 8.8 |
| Impact visuel | 8.5 |
| Feedback | 8.8 |
| Progression | 8.6 |
| Social | 8.0 |
| Immersion | 8.5 |
| Accessibilité | 8.3 |
| Cohérence NocheLive | 8.7 |
| Envie de continuer | 8.7 |

## Verdict

**PASS** — un cri de famille sur le tableau, paliers entendus, métier intact.

## What works

- Un mot, pas un chip sous Super.
- 🔥 survit au Suivant ; miss = Presque.
- 10 = chest + voile or + « diez de diez », score non multiplié.

## What feels weak

- Q4 / Q6–9 restent Super! (volontaire : la flamme HUD porte le continu).
- Sheet 4 choix encore haute (hors slice).

## Required before approval

- None.

## Evidence (optional)

Play `/jugar` 390×844 : 🔥2 / 🔥3 / 🔥5 / 🔥10, un cri, +N vole, miss → Presque.

## Night director

Je rejoue le pack pour protéger la série — le 10 est un vrai slam, pas un label.
