# M102 — Défis Celestial arena

Reviewed: 2026-08-28
Slice: `/desafios` challenge board
Tests: `bin/rails test test/controllers/street_challenges_controller_test.rb` — 19 runs, 149 assertions, 0 failures
Responsive test: `bin/rails test test/system/street_quiz_visual_test.rb -i '/defis.*stake/'` — 1 run, 18 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — existing localized keys reused; no new copy

## Feeling

Anticipation, friendly rivalry and belonging: this is the place where a parish player picks a face and starts a contest, not a social dashboard.

## 1 — Game experience

The page now opens with one loop: choose an opponent → launch the ten-question duel → see the parish rivalry and active stakes → want the next result. The parish score has moved ahead of secondary lists in the visual order.

## 2 — UI design

The two-second verb is the single gold `Lancer un défi` action. The responsive board remains one column on phone, uses paired social panels on portrait tablet, and becomes a readable arena plus supporting rail in landscape/desktop. Targets remain large, rival rows keep a 14px minimum, horizontal overflow is absent from 320px through 1440px, short landscape reduces hero height, and reduced motion removes the sheen.

## 3 — Art direction

Celestial Light follows the friendly challenge moment. The new portrait environment uses converging marble paths, a central arena, pale sky depth and gold metal. The UI remains translucent enough to reveal the world while ink copy stays readable.

## Theme engine

N/A — this is the challenge board, not hub `/`.

## Four seats

N/A — asynchronous street duel. The screen answers who I am, who I can challenge, what is active, and how my parish is doing.

## Tension

The face-off hero creates anticipation; the live parish meter and active-duel rail carry the result and next-want phases without pretending this is a Friday live round.

## Finale

N/A.

## Languages

Existing `street.duel_*` and `street.stake_*` keys are reused in es, pt-BR, fr and en; no locale parity changed.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## Responsive follow-up — iPad + desktop

- iPad portrait keeps the full-width face-off, then shows active duels and rivals in two-column rails so the social loop is shorter without shrinking touch targets.
- iPad landscape and desktop become a two-column arena: the challenge verb faces active duels, while parish rivalry and recent results occupy supporting panels below.
- An empty active-duel state uses the parish rivalry to balance the hero; a populated state aligns the hero to the live-duel rail so neither column forces a false full-height monument.
- Short landscape viewports show one readable active duel per horizontal snap instead of compressing two scorecards together.
- HUD and bottom navigation share the arena's 76rem maximum width. Long parish names wrap; no horizontal layout overflow appears at 804×1436, 1024×768, or 1440×900.

## What works

- One immediate gold verb and a real face-off.
- Parish rivalry is visible before secondary player browsing.
- New artwork gives the screen a unique Noche Live world on phone and desktop.
- Responsive evidence checked at 320×568, 390×844, 768×1024, 1024×768 and 1440×900.

## What feels weak

- The challenge board currently reuses the latest completed pack rather than offering pack choice inline; that is a future product slice, not a visual blocker.

## Required before approval

- None.

## Night director

Yes: the first screen already creates a named opponent-shaped desire, while the parish meter supplies a broader social stake.
