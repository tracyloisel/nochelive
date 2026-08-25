# M16 — Rama profile home

Reviewed: 2026-08-25
Slice: worldwide congregation directory; first unit Rama Benidorm; Instagram-like profile; night unchanged
Tests: `bin/rails test` — 381 runs, 2303 assertions, 0 failures. Line coverage 96.71%.
Gate: `.cursor/skills/noche-night/SKILL.md` and `.cursor/skills/noche-i18n/SKILL.md`

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Same gold next on stage. Host opens a night from the rama profile (one gold **Abrir la noche** when nothing is live). |
| Equipo en sala | Unchanged — buzz, shout, freeze, hunt. The door is the rama, not a global night catalogue. |
| Jugador en casa | Unchanged remote A/B. **Entrar** on a live rama profile still goes to the name screen. |
| Espectador | Opt-in **Solo ver** as a quiet link on the live profile, never a second gold. |

## Tension

Unchanged curve. This slice is the street outside the chapel: find your rama, walk in. No new rounds, no new SFX.

## Finale

Untouched. A trailing team can still steal on the crown slam.

## Languages

Copy read in **es**, **pt-BR**, **en**, **fr**; parity test green.

noche-i18n: PASS
- es: *rama*, *capilla*, *¿Dónde está tu rama?*
- pt-BR: *ala* (not ramo), *capela*, *Onde fica a sua ala?*
- fr: *paroisse* (not branche), *chapelle*, thin space before ?
- en: *ward*, *meetinghouse* (never temple)

## Verdict

PASS WITH NOTES

## What works

- Empty search still shows Benidorm (up to 6). A query filters; it does not dump the planet.
- Profile has one gold CTA. Chapel pin is Alfonso Puchades 27, Maps link, no embed.
- `noche_ward` remembers the congregation. `noche_ward_host` opens fichas / create. Night presenter token no longer opens the desk.

## What feels weak

- No GPS “near me”. Other unidades are added one create at a time. Church meetinghouse import is later.
- A host with a live night opens another night from a quiet link, not gold.

## Required before approval

- None.

## Evidence (optional)

UI: home is search + posters. Profile is emblem / pin / grid.

## Night director

Would I play another round? Yes — the night is the same. The street now has a real chapel on it.
