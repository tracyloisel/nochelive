# M76 — Liga et Défis, même palais

Reviewed: 2026-08-27
Slice: stake rivalry → choose a live rival → isolated async match → visible result
Tests: `bin/rails test` — full-suite evidence recorded at handoff
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A — social routes share one court world, not the `/` theme engine
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr read and parity-tested

## Feeling

Competition, belonging and anticipation: my score belongs to a real ward rivalry, and one tap creates a match I want to finish.

## 1 — Game experience

The loop is rivalry pressure → choose a same-stake opponent → send with haptic/SFX → each player completes the same isolated 10-question pack → +12/−3/+1 result → rivalry and personal history invite a rematch. Empty states explain when the stake has only one listed ward.

## 2 — UI design

Liga answers rank and next action in two seconds. Défis gives the stake rivalry the hero position, then active matches and live-first rivals. Custom filter and challenge sheets avoid native selects. Sticky position, search focus, loading, sent, waiting, your-turn, victory and reduced-motion states are explicit.

## 3 — Art direction

Both screens inhabit one luminous celestial court. Marble glass, ink and metallic gold preserve Celestial Light readability. One master background uses controlled CSS crops.

## Theme engine

N/A.

## Four seats

Street: who = ficha and position; where = ward/stake court; what now = challenge or play; around me = live rivals, ward score and active matches.

## Tension

The stake lead creates pressure before the personal action. The active card breathes only when it is your turn. Result rewards are clear without stadium theatrics.

## Finale

N/A — isolated street social loop.

## Languages

PASS: Spanish remains the source; Portuguese says *ala*, French uses singular *tu*, English stays warm. Locale parity test covers all four.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8 |
| Social | 10 |
| Immersion | 9 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- One social world, two clear jobs: compare in Liga, act in Défis.
- Duel runs cannot leak into adventure progression or leaderboard totals.
- Same-stake boundary is enforced in create and accept services.

## What feels weak

- Stake comparison currently spotlights the first other listed ward; future stakes with many wards need a tournament rotation.

## Required before approval

- None.

## Evidence

Named cues: `duel_send`, `stake_gain`, `celestial_breath`, `correct_gold`, `wrong_soft`. Motion honors `prefers-reduced-motion`.

## Night director

Yes. The board creates a specific rival and a visible stake consequence, so finishing one match naturally suggests the next.
