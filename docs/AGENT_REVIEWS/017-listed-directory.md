# M17 — Listed directory (Rama Benidorm)

Reviewed: 2026-08-25
Slice: hosted home shows listed unidades only; how-to add a rama; night unchanged
Tests: `bin/rails test` — 385 runs, 2358 assertions, 0 failures. Line coverage 96.65%.
Gate: `.cursor/skills/noche-night/SKILL.md` and `.cursor/skills/noche-i18n/SKILL.md`

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage. |
| Equipo en sala | Unchanged. The street outside still opens on Rama Benidorm. |
| Jugador en casa | Unchanged remote A/B. |
| Espectador | Unchanged *Solo ver*. |

## Tension

Unchanged curve. No new rounds, no new SFX.

## Finale

Untouched.

## Languages

Copy read in **es**, **pt-BR**, **en**, **fr**; parity test green.

noche-i18n: PASS
- es: *rama*, *líder de la obra misional escribe a Rama Benidorm*
- pt-BR: *ala*, *líder da obra missionária* (not ramo)
- fr: *paroisse*, *responsable de l’œuvre missionnaire*, thin space before :
- en: *ward*, *mission leader writes to* — no fake email

## Verdict

PASS

## What works

- Empty search still shows Benidorm. `listed` hides fixture `blank` and self-serve creates.
- Quiet *Crear una rama* opens the how-to page. `Wards::Create` stays for self-host; new unidades are unlisted while Benidorm is listed.
- One gold CTA on the how-to page: see Rama Benidorm. GitHub is a quiet door.

## What feels weak

- No public email for the mission leader — on purpose. Write to Rama Benidorm, in the room.

## Required before approval

- None.

## Night director

Would I play another round? Yes — the night did not move.
