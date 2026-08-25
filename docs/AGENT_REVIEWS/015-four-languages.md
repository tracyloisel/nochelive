# M15 — Four languages mid-quiz

Reviewed: 2026-08-25
Slice: es / pt-BR / fr / en, language switcher, presenter assigns a person's language
Tests: `bin/rails test`
Gate: `.cursor/skills/noche-night/SKILL.md` and `.cursor/skills/noche-i18n/SKILL.md`

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Own language from the switcher; set someone else's on Lista / ficha |
| Equipo en sala | Same verbs (buzz, shout, freeze) in their language, mid-round |
| Jugador en casa | Same, including Jonah path and the slam wait |
| Espectador | TV copy follows that spectator's locale; shared watch stream uses presenter locale |

## Tension

Unchanged curve. Copy is the night in four mouths, not a CMS overlay. Language control sits beside mute on a live round — not a gold CTA, not a Stories costume.

## Finale

Burger layers, host lines, and the crown slam translate. Swing math is untouched. A trailing team can still steal.

## Verdict

PASS WITH NOTES

noche-i18n: PASS WITH NOTES
- es: source of truth, vosotros kept.
- pt-BR: ala / equipe / vocês. Watch the remaining hidden shout bodies (`¡Ya!`).
- fr: vous in the room, tu on join and Jonah. Manche not ronde.
- en: family night, not contestants.

## What works

- Each play phone re-renders in its `players.locale` after `Locales::Set`.
- Presenter can assign language without taking that person's seat — Lista (players and Solo ver) and ficha.
- Game YAML stays Spanish; lookups fall back, other locales live in `games.*.yml`.

## What feels weak

- Pulse cheer labels are baked at send time, so a mixed-language sofa may see one tongue on that flash.
- Hidden scavenger/category bodies stay Spanish protocol.

## Required before approval

- None for this slice. Native pass on the four locale files before adding a new round.

## Night director

Would I play another round? Yes — the sofa can keep up when cousin's phone is in French.
