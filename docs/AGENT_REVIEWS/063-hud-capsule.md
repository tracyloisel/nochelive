# 063 — Street HUD capsule everywhere

Reviewed: 2026-08-27
Slice: one player HUD capsule (quiz anatomy) as a ViewComponent, including guest invite to create a ficha in the rama
Tests: `bin/rails test`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Feeling

Pride of identity when you have a ficha. Belonging when you don’t: the empty HUD is an invitation into your rama, not a blank guest chip. Curiosity for the pack rail. The header is the same object on hub, jugar, and the rest of the street/paper app — one Noche Live face.

## 1 — Game experience

The Hub ficha (two-row XP card + mini morph) was a dashboard of stats. The job of the header is **who I am, where I am in the pack, what I’m winning**. Same loop as `/jugar`: glance → act → payoff in the crown/fire pills.

Guest is not “continue as nobody.” The capsule says create your card **in your rama / ala / ward / paroisse** and the gold pill opens the real wizard (`/?ficha=1`). No invented profile.

Live night seats keep their own chrome (ticks, timer, Buzz). Street HUD does not land on `#night_play` / presenter stage / TV.

## 2 — UI design

2-second verb: avatar + name, or **Crear** for a guest. Anatomy matches jugar: glass capsule, gold hairline, level disc, pack `n / 10` + compact dots, crown + fire, hamburger in the menu slot.

States: signed-in idle, guest invite, quiz combo tiers (spark → legend), rank-up burst on the capsule, pressed CTA. Tokens: `--quiz-*` mapped from hub `--surface-glass` / `--text-on-glass` / `--border-gold` so Light and Dark stay one markup.

Dropped the sticky mini morph. The capsule is already compact; it sticks.

## 3 — Art direction

Celestial glass on the artwork, gold as metal (level disc, dots, CTA fill with dark type — never gold words on cream). Same capsule in Light (ink) and Dark (cream). Hub theme engine unchanged: tokens + backdrop, no toggle.

## Theme engine (hub `/`)

Same Home. HUD consumes hub semantic tokens. Scenes A/B/C still one Hub.

## Four seats

N/A street — who / where / what now / around me. The HUD answers **who** and **where in the pack**. Jouer remains the gold verb. Live card and dock unchanged.

## Tension

Street loop. Visible pack rail on the hub so progress is not a buried XP bar.

## Finale

Unchanged.

## Languages

es: Crea tu ficha / En tu rama / Crear
pt-BR: Crie sua ficha / Na sua ala / Criar
en: Create your card / In your ward / Create
fr: Crée ta fiche / Dans ta paroisse / Créer

noche-i18n: PASS — street tú / você / tu; ala not ramo; paroisse not rama.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 8 |
| Progression | 9 |
| Social | 8 |
| Immersion | 8 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- One `Hud::BarComponent` + `Huds::Present` on hub, jugar overlay, and chrome_menu (paper / map / liga).
- Guest invite is honest and opens the rama wizard.
- Quiz overlay still owns combo + score fly targets.

## What feels weak

- Hub mockup still painted an XP ficha; product follows the jugar capsule (charter + this ask).
- Presenter wait (paper hall) also wears the street HUD — same chrome, slightly less “desk.”
- First-visit rama wizard keeps the circular face seal; the capsule returns once you are on the Hub (ficha or guest invite).

## Required before approval

- None.
