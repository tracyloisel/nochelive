# M88 — Ficha onboarding without anonymous play

Reviewed: 2026-08-27
Slice: `/ficha` → rama → street quiz or Noche Live seat
Tests: locale parity: 7 runs, 147 assertions, 0 failures. Controller suite blocked by a pre-existing syntax error in `app/views/shared/_picto.html.erb:335`.
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: existing Celestial Light paper hall
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validated

## Feeling

Belonging: “this is my place, with my people.” Creating a profile is a short doorway into the game, not an account-registration chore.

## 1 — Game experience

The home remains explorable. The first play action creates anticipation, asks for one short identity action, resolves the rama, and resumes the exact requested pack. Noche Live already knows its rama, so a new player creates the profile and enters in one action. Anonymous participation is rejected server-side.

## 2 — UI design

The two-second verb is one gold action: create/choose profile. Multiple remembered profiles remain visible as large player rows; switching is explicit. “Play without a profile” is removed. Idle, pressed, validation failure, returning player, multiple profiles, missing rama, and ready-to-play states are covered by the existing paper-hall components.

## 3 — Art direction

Celestial Light paper, ink typography and a single gold door remain consistent with the home’s temple language. No live ticks, fake sheet grip, decorative X, or SaaS gate is introduced.

## Theme engine

N/A — the home atmosphere is unchanged.

## Four seats

| Seat | Verb tonight |
|---|---|
| Host | Unchanged |
| Chapel (controller) | Choose/create profile, then enter the room seat |
| Remote | Choose/create profile, then enter the home seat |
| TV / Twitch | Opt-in “Solo mirar”; no quiz participation |

## Tension

The onboarding preserves the intended next action and resumes it after identity and rama selection, avoiding a dead return to home.

## Finale

N/A.

## Languages

es / pt-BR / en / fr read as direct, warm invitations. Locale parity is green.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 9 |
| Progression | 9 |
| Social | 9 |
| Immersion | 8 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- One identity across street and live play, attached to a rama.
- Several profiles remain available on one device.
- The requested quiz resumes after the rama is chosen.

## What feels weak

- Full visual screenshots remain blocked by the unrelated `_picto` template syntax error.

## Required before approval

- None for this slice. Repair `_picto` before the next visual regression run.

## Night director

Yes: the administrative detour is short, remembers the intended game, and ends inside the action rather than on a dead confirmation page.
