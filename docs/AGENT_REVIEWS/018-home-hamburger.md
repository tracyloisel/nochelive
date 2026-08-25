# M18 — Home hamburger

Reviewed: 2026-08-25
Slice: home still-first; search and add-rama in the hamburger; night unchanged
Tests: `bin/rails test` — 385 runs, 2388 assertions, 0 failures. Line coverage 96.65%.
Gate: `.cursor/skills/noche-ui/SKILL.md` and `.cursor/skills/noche-i18n/SKILL.md`

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage. Night code + Soy el presentador stay inside the hamburger’s night-code disclosure, not as gold on home. |
| Equipo en sala | Unchanged. The street still opens on Rama Benidorm without typing. |
| Jugador en casa | Unchanged remote A/B. Tapping Benidorm still goes to the rama, then Entrar if live. |
| Espectador | Unchanged *Solo ver* on the live profile and in the night-code disclosure. |

## Tension

Unchanged curve. No new rounds, no new SFX.

## Finale

Untouched.

## Languages

Copy read in **es**, **pt-BR**, **en**, **fr**; parity test in this change.

noche-i18n: PASS
- es: *Buscar una rama*, *Cómo añadir tu rama*, *Menú*
- pt-BR: *Buscar uma ala* (not ramo), *Como incluir a sua ala*
- fr: *Chercher une paroisse* (not branche), *Comment ajouter votre paroisse*
- en: *Find a ward*, *How to add your ward* — not “create a parish”

## Verdict

PASS

## What works

- Reyes y Profetas is the welcome (sheet `mid`). Search is not the first sheet.
- Hamburger is shared `details` chrome (same pattern as language / presenter Más). Search opens as a nested disclosure, then filters the mosaic.
- Add-rama is menu-only, wording matches `/ramas/anadir`.

## What feels weak

- Two taps to type a place (menu, then Chercher). Empty home still shows Benidorm.

## Required before approval

- None.

## Night director

Would I play another round? Yes — the night is the same. The painting is the door again.
